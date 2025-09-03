#!/usr/bin/env python3
import json
import os
from pathlib import Path


def remove_unused_from_arb(arb_path: Path, unused_keys: set[str]) -> int:
    data = json.loads(arb_path.read_text(encoding="utf-8"))
    before = len([k for k in data.keys() if not k.startswith("@") and k != "@@locale"]) 
    changed = False

    for key in list(unused_keys):
        if key in data:
            del data[key]
            changed = True
        meta = "@" + key
        if meta in data:
            del data[meta]
            changed = True

    after = len([k for k in data.keys() if not k.startswith("@") and k != "@@locale"]) 
    removed = before - after
    if changed:
        arb_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return removed


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    arb_dir = repo / "picnic_lib" / "lib" / "l10n"
    report_path = repo / "scripts" / "reports" / "unused_keys.json"
    if not report_path.exists():
        raise SystemExit(f"unused_keys.json not found: {report_path}")

    unused_list = json.loads(report_path.read_text(encoding="utf-8")).get("unused", [])
    unused_keys = set(map(str, unused_list))

    removed_per_file: dict[str, int] = {}
    for arb in sorted(arb_dir.glob("*.arb")):
        removed = remove_unused_from_arb(arb, unused_keys)
        removed_per_file[arb.name] = removed

    print(json.dumps({"removed_per_file": removed_per_file}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()


