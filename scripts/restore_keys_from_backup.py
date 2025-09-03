#!/usr/bin/env python3
import json
import os
from pathlib import Path


def load_keys_list(path: Path) -> list[str]:
    return [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def restore_keys_into_arb(current: Path, backup: Path, keys: set[str]) -> dict:
    cur = json.loads(current.read_text(encoding="utf-8"))
    bak = json.loads(backup.read_text(encoding="utf-8"))

    added = 0
    meta_added = 0
    for k in keys:
        if k in bak and k not in cur:
            cur[k] = bak[k]
            added += 1
        mk = "@" + k
        if mk in bak and mk not in cur:
            cur[mk] = bak[mk]
            meta_added += 1

    if added or meta_added:
        # Keep pretty formatting
        current.write_text(json.dumps(cur, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    return {"keys_added": added, "meta_added": meta_added}


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    reports_dir = repo / "scripts" / "reports"
    used_keys_path = reports_dir / "used_keys.txt"
    unused_keys_path = reports_dir / "unused_keys.txt"
    if not used_keys_path.exists() or not unused_keys_path.exists():
        raise SystemExit("used_keys.txt or unused_keys.txt not found in scripts/reports")

    used = set(load_keys_list(used_keys_path))
    unused = set(load_keys_list(unused_keys_path))
    # Keys that were removed but actually used
    restore_keys = sorted(used.intersection(unused))

    if not restore_keys:
        print(json.dumps({"restored": 0, "message": "No overlapping keys to restore."}, ensure_ascii=False))
        return

    # Find latest backup directory under scripts/backups with prefix l10n-
    backups_root = repo / "scripts" / "backups"
    backup_dirs = sorted([p for p in backups_root.glob("l10n-*") if p.is_dir()])
    if not backup_dirs:
        raise SystemExit("No backups found under scripts/backups")
    latest_backup = backup_dirs[-1]

    arb_dir = repo / "picnic_lib" / "lib" / "l10n"
    results = {}
    for arb in sorted(arb_dir.glob("*.arb")):
        backup_file = latest_backup / arb.name
        if not backup_file.exists():
            continue
        stats = restore_keys_into_arb(arb, backup_file, set(restore_keys))
        results[arb.name] = stats

    print(json.dumps({
        "restore_keys_count": len(restore_keys),
        "restored_per_file": results,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()


