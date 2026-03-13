#!/usr/bin/env python3
"""
Filter lcov.info to exclude untestable files using a fixed exclude list.

Usage:
  python3 scripts/filter_coverage.py [--exclude-list coverage/exclude_patterns.txt] [--input coverage/lcov.info] [--output coverage/lcov_filtered.info]

The exclude list is a fixed set of file paths (one per line) that are known
to be untestable (native plugins, generated code, platform-dependent, etc.).
New test/helper files do NOT affect the exclude list, preventing the
denominator-growth problem.

Generates:
  - Filtered lcov.info (excluding listed files)
  - Coverage summary to stdout
"""

import argparse
import re
import sys


def parse_lcov(path: str):
    with open(path) as f:
        content = f.read()

    entries = []
    for block in content.strip().split("end_of_record"):
        block = block.strip()
        if not block:
            continue
        sf = re.search(r"SF:(.*)", block)
        lf = re.search(r"LF:(\d+)", block)
        lh = re.search(r"LH:(\d+)", block)
        if not sf or not lf or not lh:
            continue
        entries.append({
            "filename": sf.group(1),
            "found": int(lf.group(1)),
            "hit": int(lh.group(1)),
            "raw": block + "\nend_of_record\n",
        })
    return entries


def load_exclude_list(path: str) -> set:
    """Load fixed exclude patterns file (one file path per line)."""
    excludes = set()
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    excludes.add(line)
    except FileNotFoundError:
        print(f"Warning: exclude list not found at {path}", file=sys.stderr)
    return excludes


def main():
    parser = argparse.ArgumentParser(description="Filter lcov.info using fixed exclude list")
    parser.add_argument("--exclude-list", default="coverage/exclude_patterns.txt",
                        help="Path to fixed exclude list (default: coverage/exclude_patterns.txt)")
    parser.add_argument("--input", default="coverage/lcov.info", help="Input lcov file")
    parser.add_argument("--output", default="coverage/lcov_filtered.info", help="Output filtered lcov file")
    args = parser.parse_args()

    entries = parse_lcov(args.input)
    excludes = load_exclude_list(args.exclude_list)

    total_found = sum(e["found"] for e in entries)
    total_hit = sum(e["hit"] for e in entries)

    included = []
    excluded = []
    for e in entries:
        if e["filename"] in excludes:
            excluded.append(e)
        else:
            included.append(e)

    filtered_found = sum(e["found"] for e in included)
    filtered_hit = sum(e["hit"] for e in included)

    # Write filtered lcov
    with open(args.output, "w") as f:
        for e in included:
            f.write(e["raw"])

    # Summary
    orig_pct = total_hit / total_found * 100 if total_found else 0
    filt_pct = filtered_hit / filtered_found * 100 if filtered_found else 0

    print(f"Original:  {total_hit}/{total_found} = {orig_pct:.1f}%  ({len(entries)} files)")
    print(f"Excluded:  {len(excluded)} files ({sum(e['found'] for e in excluded)} lines) [fixed list: {len(excludes)} patterns]")
    print(f"Filtered:  {filtered_hit}/{filtered_found} = {filt_pct:.1f}%  ({len(included)} files)")
    print(f"Target 80%: {int(filtered_found * 0.8)} lines needed ({int(filtered_found * 0.8) - filtered_hit} gap)")
    print(f"\nOutput: {args.output}")

    return 0 if filt_pct >= 80 else 1


if __name__ == "__main__":
    sys.exit(main())
