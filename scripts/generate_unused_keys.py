# /usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)

def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    rg = "/opt/homebrew/bin/rg"
    code_dirs = [
        repo / "picnic_lib" / "lib",
        repo / "picnic_app" / "lib",
        repo / "ttja_app" / "lib",
    ]
    en_arb = repo / "picnic_lib" / "lib" / "l10n" / "app_en.arb"
    reports = repo / "scripts" / "reports"
    reports.mkdir(parents=True, exist_ok=True)

    # Limit searches strictly to Dart files and collect getter names used in code
    type_flag = "--type"
    getter_app = run([rg, "-o", "-U", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                      r"AppLocalizations\.of\([^)]*\)\s*\.(\w+)", *map(str, code_dirs)])
    used_getters_app = {line.strip() for line in getter_app.splitlines() if line.strip()}
    # Common local variable name pattern: `final localizations = AppLocalizations.of(context);`
    getter_var = run([rg, "-o", "-U", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                      r"\blocalizations\.(\w+)\b", *map(str, code_dirs)])
    used_getters_var = {line.strip() for line in getter_var.splitlines() if line.strip()}

    # Optional pattern: ".l10n.key" (skip errors if none found)
    used2_keys = []
    try:
        getter_ext = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                          r"(?:\.l10n|context\.l10n)\.([A-Za-z0-9_]+)\b", *map(str, code_dirs)])
        used_getters_ext = {line.strip() for line in getter_ext.splitlines() if line.strip()}
    except Exception:
        used_getters_ext = set()

    # 3) Extract literal-like candidates from code and intersect with ARB keys to avoid false negatives
    literal_candidates: set[str] = set()
    try:
        # Collect simple quoted word tokens from Dart code only
        # Single quotes
        lit1 = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                    r"'([A-Za-z0-9_]+)'", *map(str, code_dirs)])
        literal_candidates.update([ln.strip() for ln in lit1.splitlines() if ln.strip()])
        # Double quotes
        lit2 = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                    r'"([A-Za-z0-9_]+)"', *map(str, code_dirs)])
        literal_candidates.update([ln.strip() for ln in lit2.splitlines() if ln.strip()])
        # localized('key') / localizedText('key') / tr('key')
        loc1 = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                    r"localized\(\s*'([A-Za-z0-9_]+)'\s*\)", *map(str, code_dirs)])
        literal_candidates.update([ln.strip() for ln in loc1.splitlines() if ln.strip()])
        loc2 = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                    r"localizedText\(\s*'([A-Za-z0-9_]+)'\s*\)", *map(str, code_dirs)])
        literal_candidates.update([ln.strip() for ln in loc2.splitlines() if ln.strip()])
        loc3 = run([rg, "-o", "-P", "--no-filename", "--replace", "$1", type_flag, "dart",
                    r"tr\(\s*'([A-Za-z0-9_]+)'\s*\)", *map(str, code_dirs)])
        literal_candidates.update([ln.strip() for ln in loc3.splitlines() if ln.strip()])
    except Exception:
        pass

    # Manual whitelist 제거: 정책상 화이트리스트 사용 안 함

    # Merge used sets (filtered to known ARB keys after loading them)
    # all en keys
    data = json.loads(en_arb.read_text(encoding="utf-8"))
    all_keys = sorted(k for k in data.keys() if not k.startswith("@") and k != "@@locale")
    (reports / "all_keys_en.txt").write_text("\n".join(all_keys) + "\n", encoding="utf-8")

    all_keys_set = set(all_keys)

    # Map snake_case ARB keys to generated lowerCamelCase getter names
    used_getters = used_getters_app | used_getters_var | used_getters_ext
    # In 이 프로젝트, getter 이름이 키와 동일한 snake_case임
    used_from_getters = {k for k in all_keys_set if k in used_getters}

    # Literal candidates may include raw keys in strings; intersect with ARB keys
    literal_filtered = {k for k in literal_candidates if k in all_keys_set}

    used_keys = sorted((used_from_getters | literal_filtered) & all_keys_set)
    (reports / "used_keys.txt").write_text("\n".join(used_keys) + "\n", encoding="utf-8")

    used_set = set(used_keys)
    unused = [k for k in all_keys if k not in used_set]
    (reports / "unused_keys.txt").write_text("\n".join(unused) + "\n", encoding="utf-8")
    (reports / "unused_keys.json").write_text(json.dumps({"unused": unused}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    summary = {
        "counts": {"used": len(used_keys), "all": len(all_keys), "unused": len(unused)},
        "sample_unused": unused[:50],
        "reports": {
            "used": str(reports / "used_keys.txt"),
            "unused_txt": str(reports / "unused_keys.txt"),
            "unused_json": str(reports / "unused_keys.json"),
        },
        "debug": {
            "getters_app": len(used_getters_app),
            "getters_var": len(used_getters_var),
            "getters_ext": len(used_getters_ext),
        }
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
