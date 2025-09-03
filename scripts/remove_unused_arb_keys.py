#!/usr/bin/env python3
import os
import re
import json


def main() -> None:
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    arb_dir = os.path.join(repo_root, "picnic_lib", "lib", "l10n")
    code_dirs = [
        os.path.join(repo_root, "picnic_lib", "lib"),
        os.path.join(repo_root, "picnic_app", "lib"),
        os.path.join(repo_root, "ttja_app", "lib"),
    ]

    # 1) Collect ARB keys across all languages
    arb_files = [f for f in os.listdir(arb_dir) if f.endswith(".arb")]
    all_keys: set[str] = set()
    for fname in arb_files:
        path = os.path.join(arb_dir, fname)
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        for key in data.keys():
            if not key.startswith("@") and key != "@@locale":
                all_keys.add(key)

    # 2) Scan code for used keys
    used_keys: set[str] = set()
    pat1 = re.compile(r"AppLocalizations\\.of\\([^)]*\\)\\.(\\w+)")
    pat2 = re.compile(r"\\.l10n\\.(\\w+)")

    for root in code_dirs:
        for dirpath, _, files in os.walk(root):
            for fn in files:
                if not fn.endswith(".dart"):
                    continue
                p = os.path.join(dirpath, fn)
                try:
                    with open(p, encoding="utf-8") as fh:
                        s = fh.read()
                except Exception:
                    continue
                used_keys.update(m.group(1) for m in pat1.finditer(s))
                used_keys.update(m.group(1) for m in pat2.finditer(s))

    # 3) Compute unused keys
    unused = sorted(k for k in all_keys if k not in used_keys)
    summary = {
        "total_all_keys": len(all_keys),
        "total_used_keys": len(used_keys),
        "total_unused_keys": len(unused),
        "sample_unused": unused[:50],
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))

    # 4) Remove unused from each ARB (both key and its metadata)
    removed_counts: dict[str, int] = {}
    for fname in arb_files:
        path = os.path.join(arb_dir, fname)
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)

        before = len([k for k in data.keys() if not k.startswith("@") and k != "@@locale"]) 

        changed = False
        for k in unused:
            if k in data:
                del data[k]
                changed = True
            mk = "@" + k
            if mk in data:
                del data[mk]
                changed = True

        after = len([k for k in data.keys() if not k.startswith("@") and k != "@@locale"]) 
        removed_counts[fname] = before - after

        if changed:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(data, fh, ensure_ascii=False, indent=2)
                fh.write("\n")

    print(json.dumps({"removed_per_file": removed_counts}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()


