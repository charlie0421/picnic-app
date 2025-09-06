#!/usr/bin/env python3
"""
Auto-translate ARB values for a target locale using deep-translator.

Behavior:
- For the target ARB (e.g., app_es.arb), find values that start with "[MISSING] ".
- Strip the marker and translate the remaining English text to the target language.
- Preserve ARB-style placeholders like {name}, ${count} by temporarily tokenizing them.

Usage:
  python3 scripts/auto_translate_arb.py \
    --file "/absolute/path/to/app_es.arb" \
    --src en \
    --dest es

Notes:
- Requires: deep-translator
  Install in venv: pip install deep-translator
"""

import argparse
import json
import re
from pathlib import Path

MISSING_PREFIX = "[MISSING] "

# {name} or ${name}
PLACEHOLDER_REGEXES = [
    re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\}"),
    re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}"),
]


def extract_placeholders(text: str) -> list[tuple[str, str]]:
    """Return list of (raw, token) pairs for unique placeholders in text."""
    found = []
    seen = set()
    for rx in PLACEHOLDER_REGEXES:
        for m in rx.finditer(text):
            raw = m.group(0)
            name = m.group(1)
            if raw not in seen:
                seen.add(raw)
                token = f"__PH__{name}__"
                found.append((raw, token))
    return found


def protect_placeholders(text: str) -> tuple[str, list[tuple[str, str]]]:
    pairs = extract_placeholders(text)
    protected = text
    for raw, token in pairs:
        protected = protected.replace(raw, token)
    return protected, pairs


def restore_placeholders(text: str, pairs: list[tuple[str, str]]) -> str:
    restored = text
    for raw, token in pairs:
        restored = restored.replace(token, raw)
    return restored


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, help="Target ARB file to translate (e.g., app_es.arb)")
    parser.add_argument("--src", default="en", help="Source language (default: en)")
    parser.add_argument("--dest", default="es", help="Destination language (default: es)")
    args = parser.parse_args()

    arb_path = Path(args.file)
    if not arb_path.exists():
        print(f"[ERROR] File not found: {arb_path}")
        return 1

    # Prefer GoogleTranslator; fallback to MyMemoryTranslator
    translator = None
    try:
        from deep_translator import GoogleTranslator
        translator = GoogleTranslator(source=args.src, target=args.dest)
        backend = "google"
    except Exception:
        try:
            from deep_translator import MyMemoryTranslator
            translator = MyMemoryTranslator(source=args.src, target=args.dest)
            backend = "mymemory"
        except Exception as e:
            print("[ERROR] deep-translator is not installed. Install with:\n  pip install deep-translator")
            return 1

    data = json.loads(arb_path.read_text(encoding="utf-8"))
    changed = False
    for key, value in list(data.items()):
        if key.startswith('@'):
            continue
        if not isinstance(value, str):
            continue
        if not value.startswith(MISSING_PREFIX):
            continue

        english_text = value[len(MISSING_PREFIX):]
        protected, pairs = protect_placeholders(english_text)
        try:
            translated = translator.translate(protected)
        except Exception as e:
            print(f"[WARN] Failed to translate key '{key}' via {backend}: {e}")
            continue

        restored = restore_placeholders(translated, pairs)
        if restored and restored != value:
            data[key] = restored
            changed = True
            print(f"[OK]   {key}")

    if changed:
        arb_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"[DONE] Updated {arb_path.name}")
    else:
        print("[OK]   No changes (nothing to translate)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


