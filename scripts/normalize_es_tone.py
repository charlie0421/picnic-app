#!/usr/bin/env python3
"""
Normalize Spanish tone in ARB by applying a small glossary for common UI phrases
and punctuation preferences.

Usage:
  python3 scripts/normalize_es_tone.py \
    --file "/absolute/path/to/app_es.arb"
"""

import argparse
import json
from pathlib import Path

GLOSSARY = {
    # Buttons / common actions
    "Confirmar": "Confirmar",
    "Confirm": "Confirmar",
    "Aceptar": "Aceptar",
    "Accept": "Aceptar",
    "Cancelar": "Cancelar",
    "Cancel": "Cancelar",
    "Guardar": "Guardar",
    "Save": "Guardar",
    "Actualizar": "Actualizar",
    "Update": "Actualizar",
    "Cerrar": "Cerrar",
    "Close": "Cerrar",
    "Eliminar": "Eliminar",
    "Delete": "Eliminar",
    "Enviar": "Enviar",
    "Submit": "Enviar",
    # Auth
    "Iniciar sesión": "Iniciar sesión",
    "Iniciar Sesión": "Iniciar sesión",
    "Inicia sesión": "Iniciar sesión",
    "Sign in": "Iniciar sesión",
    "Cerrar sesión": "Cerrar sesión",
    "Log out": "Cerrar sesión",
    # Misc nouns/labels
    "Ajustes": "Configuración",
    "Settings": "Configuración",
    "Notificaciones": "Notificaciones",
    "Idioma": "Idioma",
    "Versión": "Versión",
    # Short labels
    "Ver": "Ver",
    "Watch": "Ver",
}


def normalize_value(value: str) -> str:
    if not isinstance(value, str):
        return value
    # Apply glossary exact matches first
    new_value = GLOSSARY.get(value, value)
    # Light trimming / spacing rules
    new_value = new_value.replace("  ", " ").strip()
    # Consistent ellipsis
    new_value = new_value.replace("...", "…")
    return new_value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    args = parser.parse_args()

    arb_path = Path(args.file)
    if not arb_path.exists():
        print(f"[ERROR] Not found: {arb_path}")
        return 1

    data = json.loads(arb_path.read_text(encoding="utf-8"))
    changed = False

    for key, value in list(data.items()):
        if key.startswith('@'):
            continue
        if not isinstance(value, str):
            continue
        before = value
        after = normalize_value(value)
        if after != before:
            data[key] = after
            changed = True
            print(f"[FIX] {key}")

    if changed:
        arb_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"[DONE] Updated {arb_path.name}")
    else:
        print("[OK]  No tone changes needed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
