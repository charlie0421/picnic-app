#!/usr/bin/env python3
import json
import re
from pathlib import Path


def apply_replacements(text: str, rules: list[tuple[str, str]]) -> str:
    # 순서대로 적용(긴 매핑 우선)
    for src, dst in rules:
        text = text.replace(src, dst)
    return text


def main() -> None:
    repo = Path(__file__).resolve().parents[2]
    l10n = repo / "picnic_lib" / "lib" / "l10n"
    tw_path = l10n / "app_zh_TW.arb"
    data = json.loads(tw_path.read_text(encoding="utf-8"))

    # 2차 번체 치환(서비스/네트워크 등 일반어). 규칙은 보수적으로 운용
    # 긴 문자열 먼저, 단어/자 빈도 높은 항목 위주
    mapping = [
        ("登录", "登入"),
        ("登錄", "登入"),
        ("确认", "確認"),
        ("取消", "取消"),
        ("评论", "評論"),
        ("结果", "結果"),
        ("数据", "資料"),
        ("搜索", "搜尋"),
        ("错误", "錯誤"),
        ("失败", "失敗"),
        ("设置", "設定"),
        ("分钟", "分鐘"),
        ("时间", "時間"),
        ("显示", "顯示"),
        ("隐藏", "隱藏"),
        ("购买", "購買"),
        ("收费", "收費"),
        ("用户", "用戶"),
        ("昵称", "暱稱"),
        ("风格", "風格"),
        ("兼容性", "相容性"),
        ("宫合", "宮合"),
        ("Goong-Hap", "宮合"),
        ("广告", "廣告"),
        ("用尽", "用盡"),
        ("推荐", "推薦"),
        ("图表", "圖表"),
        ("图库", "相簿"),
        ("等级", "等級"),
        ("目录", "目錄"),
    ]

    # 길이 순으로 정렬(긴 치환어 우선)
    mapping.sort(key=lambda x: len(x[0]), reverse=True)

    # 값 문자열만 치환(@메타와 @@locale 제외)
    for k, v in list(data.items()):
        if k.startswith("@") or k == "@@locale":
            continue
        if not isinstance(v, str):
            continue
        # 플레이스홀더 보존: {name} / __PLACEHOLDER__ 는 단순 replace 영향 없음
        new_v = apply_replacements(v, mapping)
        data[k] = new_v

    tw_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("zh_TW pass2 applied:", tw_path)


if __name__ == "__main__":
    main()


