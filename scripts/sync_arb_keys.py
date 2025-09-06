#!/usr/bin/env python3
"""
Sync ARB keys across locales using the English file as the template.

- Ensures every non-metadata key in `app_en.arb` exists in all other `*.arb`.
- If a key is missing in a locale, it is added with the English value prefixed with "[MISSING] ".
- Metadata entries ("@key") are copied over if the base key exists or was added.
  Existing metadata is preserved and only missing pieces are added.

Usage:
  python3 scripts/sync_arb_keys.py --path "/absolute/path/to/lib/l10n"
"""

import argparse
import json
from pathlib import Path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", required=True, help="Directory containing .arb files")
    parser.add_argument("--template", default="app_en.arb", help="Template ARB filename (default: app_en.arb)")
    args = parser.parse_args()

    arb_dir = Path(args.path)
    if not arb_dir.exists() or not arb_dir.is_dir():
        print(f"[ERROR] Path not found or not a directory: {arb_dir}")
        return 1

    template_path = arb_dir / args.template
    if not template_path.exists():
        print(f"[ERROR] Template ARB not found: {template_path}")
        return 1

    template = load_json(template_path)
    # Base keys from template (exclude metadata keys starting with '@')
    base_keys = [k for k in template.keys() if not k.startswith('@')]

    total_files = 0
    modified_files = 0
    for locale_path in sorted(arb_dir.glob("*.arb")):
        total_files += 1
        if locale_path.name == template_path.name:
            continue

        data = load_json(locale_path)
        changed = False

        # Ensure @@locale exists (best-effort)
        if "@@locale" not in data:
            # Infer from filename like app_es.arb -> es
            lang_guess = locale_path.stem.split('_')[-1]
            if len(lang_guess) in (2, 3):
                data["@@locale"] = lang_guess
                changed = True

        for key in base_keys:
            if key not in data:
                # Add missing key with marker
                data[key] = f"[MISSING] {template[key]}"
                changed = True

            meta_key = f"@{key}"
            tmpl_meta = template.get(meta_key)
            if tmpl_meta:
                cur_meta = data.get(meta_key)
                if not isinstance(cur_meta, dict):
                    data[meta_key] = tmpl_meta
                    changed = True
                else:
                    # Merge missing fields shallowly
                    for m_k, m_v in tmpl_meta.items():
                        if m_k not in cur_meta:
                            cur_meta[m_k] = m_v
                            changed = True

        if changed:
            write_json(locale_path, data)
            modified_files += 1
            print(f"[SYNC] Updated {locale_path.name}")
        else:
            print(f"[OK]   {locale_path.name}")

    print(f"\nProcessed {total_files} ARB files; modified {modified_files}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


