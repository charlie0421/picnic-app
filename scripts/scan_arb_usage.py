#!/usr/bin/env python3
import os
import re
import json
from pathlib import Path


def collect_arb_keys(arb_dir: Path) -> dict[str, set[str]]:
    per_file: dict[str, set[str]] = {}
    for p in sorted(arb_dir.glob("*.arb")):
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        keys = {k for k in data.keys() if not k.startswith("@") and k != "@@locale"}
        per_file[p.name] = keys
    return per_file


def collect_used_keys(code_dirs: list[Path]) -> set[str]:
    used: set[str] = set()
    # Common patterns
    pat_app_loc = re.compile(r"AppLocalizations\\.of\\([^)]*\\)\\.(\\w+)")
    pat_l10n_ext = re.compile(r"\\.l10n\\.(\\w+)")
    # Allow: localized.text('key') pattern if exists (conservative)
    pat_string_lookup = re.compile(r"localized(Text)?\\(\\s*'([A-Za-z0-9_]+)'\\s*\\)")

    for base in code_dirs:
        for dirpath, _, files in os.walk(base):
            for fn in files:
                if not fn.endswith(".dart"):
                    continue
                fp = Path(dirpath) / fn
                try:
                    s = fp.read_text(encoding="utf-8")
                except Exception:
                    continue
                used.update(m.group(1) for m in pat_app_loc.finditer(s))
                used.update(m.group(1) for m in pat_l10n_ext.finditer(s))
                for m in pat_string_lookup.finditer(s):
                    used.add(m.group(2))
    return used


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    arb_dir = repo_root / "picnic_lib" / "lib" / "l10n"
    code_dirs = [
        repo_root / "picnic_lib" / "lib",
        repo_root / "picnic_app" / "lib",
        repo_root / "ttja_app" / "lib",
    ]

    per_file = collect_arb_keys(arb_dir)
    all_keys = set().union(*per_file.values()) if per_file else set()
    used_keys = collect_used_keys(code_dirs)
    unused_keys = sorted(k for k in all_keys if k not in used_keys)

    report = {
        "totals": {
            "arb_files": sorted(per_file.keys()),
            "total_arb_keys": len(all_keys),
            "total_used_keys": len(used_keys),
            "total_unused_keys": len(unused_keys),
        },
        "sample_unused": unused_keys[:100],
    }

    reports_dir = repo_root / "scripts" / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    out_path = reports_dir / "arb-unused-report.json"
    out_path.write_text(json.dumps({
        **report,
        "all_unused": unused_keys,
    }, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(str(out_path))


if __name__ == "__main__":
    main()


