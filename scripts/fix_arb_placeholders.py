#!/usr/bin/env python3
"""
Scan ARB files and ensure that for any message containing placeholders like
{name} or ${name}, the corresponding metadata entry ("@key") includes a
"placeholders" field defining these placeholders. Existing metadata is preserved.

Additionally, synchronize placeholder "type" from the template ARB (usually the
English file) so that all locales match the template's types. This fixes
Flutter gen_l10n warnings about mismatched placeholder types (e.g., Object vs String).

Usage:
  python3 scripts/fix_arb_placeholders.py --path "/absolute/path/to/arb/dir"

Notes:
- Only keys whose values are strings are scanned.
- Keys that already include placeholders in metadata are not overwritten; missing
  placeholders are appended.
- Placeholder types are synchronized to match the template if available.
- Keys starting with '@' (metadata entries) are skipped during scan.
"""

import argparse
import json
import re
from pathlib import Path


PLACEHOLDER_REGEXES = [
    re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\}"),       # {name}
    re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}"),   # ${name}
]


def extract_placeholders(text: str) -> set[str]:
    names: set[str] = set()
    for rx in PLACEHOLDER_REGEXES:
        for m in rx.finditer(text):
            names.add(m.group(1))
    return names


def build_template_types(template_data: dict) -> dict[str, dict[str, str]]:
    """
    Create a mapping: key -> placeholderName -> type
    Example: { "compatibility_share_message": { "artistName": "String" } }
    """
    mapping: dict[str, dict[str, str]] = {}
    for key, value in template_data.items():
        if not key.startswith('@'):
            meta = template_data.get(f"@{key}")
            if isinstance(meta, dict):
                ph = meta.get("placeholders")
                if isinstance(ph, dict):
                    for name, spec in ph.items():
                        if isinstance(spec, dict):
                            t = spec.get("type")
                            if isinstance(t, str) and t:
                                mapping.setdefault(key, {})[name] = t
    return mapping


def fix_arb_file(path: Path, template_types: dict[str, dict[str, str]]) -> bool:
    changed = False
    try:
        content = path.read_text(encoding="utf-8")
        data = json.loads(content)
    except Exception as e:
        print(f"[WARN] Skipping {path}: {e}")
        return False

    # Iterate over message keys (exclude metadata starting with '@')
    for key, value in list(data.items()):
        if key.startswith('@'):
            continue
        if not isinstance(value, str):
            continue

        placeholders = extract_placeholders(value)
        if not placeholders:
            continue

        meta_key = f"@{key}"
        meta = data.get(meta_key)
        if meta is None:
            meta = {"description": data.get(meta_key, {}).get("description", f"Auto-generated metadata for key '{key}'.")}
            data[meta_key] = meta
            changed = True

        # Ensure placeholders map exists
        if "placeholders" not in meta or not isinstance(meta.get("placeholders"), dict):
            meta["placeholders"] = {}
            changed = True

        # Add any missing placeholders
        for name in sorted(placeholders):
            if name not in meta["placeholders"]:
                # Minimal definition is acceptable for Flutter gen_l10n
                meta["placeholders"][name] = {}
                changed = True

        # Remove placeholder metadata that no longer appears in the message
        extra = [n for n in list(meta["placeholders"].keys()) if n not in placeholders]
        if extra:
            for n in extra:
                del meta["placeholders"][n]
            changed = True

        # Synchronize placeholder types from template if known
        tmpl_for_key = template_types.get(key, {})
        for name, t in tmpl_for_key.items():
            # Only set when placeholder exists in this locale's message
            if name in placeholders:
                cur = meta["placeholders"].get(name)
                if not isinstance(cur, dict):
                    meta["placeholders"][name] = {"type": t}
                    changed = True
                else:
                    if cur.get("type") != t:
                        cur["type"] = t
                        changed = True

    if changed:
        # Preserve ordering by dumping with indent=2 to match typical ARB formatting
        new_content = json.dumps(data, ensure_ascii=False, indent=2)
        new_content += "\n"  # ensure trailing newline
        path.write_text(new_content, encoding="utf-8")
        print(f"[FIXED] {path}")
    else:
        print(f"[OK]    {path} (no changes)")

    return changed


def detect_template_file(arb_dir: Path) -> Path | None:
    """Attempt to detect template ARB file.
    Strategy:
    1) Look for l10n.yaml next to Flutter project (two levels up from arb dir or common locations)
       and parse a line like 'template-arb-file: app_en.arb'.
    2) Otherwise, prefer a file matching '*en.arb'.
    3) Otherwise, pick the file whose @@locale == 'en'.
    """
    # Try to locate l10n.yaml in project root or one-level up from arb dir
    candidates = [
        arb_dir.parent.parent / "l10n.yaml",
        arb_dir.parent / "l10n.yaml",
    ]
    for cfg in candidates:
        if cfg.exists():
            try:
                text = cfg.read_text(encoding="utf-8")
                m = re.search(r"^\s*template-arb-file\s*:\s*(.+)$", text, re.MULTILINE)
                if m:
                    fname = m.group(1).strip().strip('"').strip("'")
                    tpath = arb_dir / fname
                    if tpath.exists():
                        return tpath
            except Exception:
                pass

    # Prefer *en.arb by filename
    en_files = sorted(arb_dir.glob("*en*.arb"))
    for f in en_files:
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
            if data.get('@@locale') == 'en':
                return f
        except Exception:
            continue
    # Fallback to first en-like file
    if en_files:
        return en_files[0]
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", required=True, help="Directory containing .arb files")
    args = parser.parse_args()

    root = Path(args.path)
    if not root.exists() or not root.is_dir():
        print(f"[ERROR] Path not found or not a directory: {root}")
        return 1

    # Build template placeholder type map
    template_path = detect_template_file(root)
    template_types: dict[str, dict[str, str]] = {}
    if template_path and template_path.exists():
        try:
            template_data = json.loads(template_path.read_text(encoding="utf-8"))
            template_types = build_template_types(template_data)
            print(f"[INFO] Template detected: {template_path.name} ({len(template_types)} keys with typed placeholders)")
        except Exception as e:
            print(f"[WARN] Failed to read template ARB: {e}")

    total = 0
    modified = 0
    for arb_path in sorted(root.glob("*.arb")):
        total += 1
        if fix_arb_file(arb_path, template_types):
            modified += 1

    print(f"\nProcessed {total} ARB files; modified {modified}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


