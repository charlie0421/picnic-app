#!/usr/bin/env python3
import json
from pathlib import Path


def restore_keys_from_backup(current_arb: Path, backup_arb: Path, keys: set[str]) -> dict:
    cur = json.loads(current_arb.read_text(encoding="utf-8"))
    bak = json.loads(backup_arb.read_text(encoding="utf-8"))
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
        current_arb.write_text(json.dumps(cur, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {"keys_added": added, "meta_added": meta_added}


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    reports = repo / "scripts" / "reports"
    used_keys_path = reports / "used_keys.txt"
    if not used_keys_path.exists():
        raise SystemExit("used_keys.txt not found. Run generate_unused_keys.py first.")
    used_keys = set(k.strip() for k in used_keys_path.read_text(encoding="utf-8").splitlines() if k.strip())

    arb_dir = repo / "picnic_lib" / "lib" / "l10n"
    en_arb = arb_dir / "app_en.arb"
    en_data = json.loads(en_arb.read_text(encoding="utf-8"))
    current_en_keys = set(k for k in en_data.keys() if not k.startswith("@") and k != "@@locale")
    missing = sorted(used_keys - current_en_keys)

    if not missing:
        print(json.dumps({"missing_used_keys": 0, "message": "No missing used keys in en."}, ensure_ascii=False))
        return

    # find latest backup
    backups_root = repo / "scripts" / "backups"
    backup_dirs = sorted([p for p in backups_root.glob("l10n-*") if p.is_dir()])
    if not backup_dirs:
        raise SystemExit("No backups found under scripts/backups")
    backup_dir = backup_dirs[-1]

    restored = {}
    for arb in sorted(arb_dir.glob("*.arb")):
        bak = backup_dir / arb.name
        if not bak.exists():
            continue
        stats = restore_keys_from_backup(arb, bak, set(missing))
        restored[arb.name] = stats

    print(json.dumps({
        "missing_used_keys": len(missing),
        "restored_per_file": restored,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()


