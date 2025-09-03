#!/usr/bin/env python3
import json
from pathlib import Path


def main() -> None:
    repo = Path(__file__).resolve().parents[2]
    l10n = repo / "picnic_lib" / "lib" / "l10n"
    en = l10n / "app_en.arb"
    zh = l10n / "app_zh.arb"
    cn = l10n / "app_zh_CN.arb"
    tw = l10n / "app_zh_TW.arb"

    en_data = json.loads(en.read_text(encoding="utf-8"))
    zh_data = json.loads(zh.read_text(encoding="utf-8"))

    keys = [k for k in en_data.keys() if not k.startswith("@") and k != "@@locale"]

    def build(locale: str) -> dict:
        out = {"@@locale": locale}
        for k in keys:
            if k in zh_data:
                out[k] = zh_data[k]
            meta = f"@{k}"
            if meta in en_data:
                out[meta] = en_data[meta]
        return out

    cn_data = build("zh_CN")
    tw_data = build("zh_TW")

    cn.write_text(json.dumps(cn_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    tw.write_text(json.dumps(tw_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def count(d: dict) -> int:
        return len([k for k in d.keys() if not k.startswith("@") and k != "@@locale"])

    print("zh_CN keys:", count(cn_data))
    print("zh_TW keys:", count(tw_data))


if __name__ == "__main__":
    main()


