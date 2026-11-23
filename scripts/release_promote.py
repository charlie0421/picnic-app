#!/usr/bin/env python3
"""picnic_app 출시 단계: 이미 업로드된 빌드를 스토어에 내보낸다.

Codemagic 워크플로 `picnic-app-promote` 가 실행한다. 로컬에서는 `scripts/release_picnic.sh promote` 로 시작한다.
절차와 승인 게이트는 .claude/skills/picnic-release/SKILL.md 가 소유한다.

  --mode check   읽기 전용. 대상 빌드·스토어 언어·현재 production 상태를 확인하고 출시 노트를 검증한다
  --mode submit  check 를 모두 통과한 뒤에만 쓴다
                 iOS: App Store 심사 제출(승인 즉시 출시, 7일 단계적 출시)
                 Android: production 트랙에 release 설정(기본 100%, --android-fraction 으로 단계적 배포)

스토어 인증은 Codemagic 이 주는 환경 변수를 codemagic-cli-tools 가 직접 읽는다. 이 스크립트는 비밀 값을 다루지 않는다.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional

APP_ID = "io.iconcasting.picnic.app"  # iOS 번들 ID 이자 Android 패키지 이름
NOTES_DIR = Path("docs/operations/release-notes")
IOS_RELEASE_TYPE = "AFTER_APPROVAL"
IOS_WHATS_NEW_MAX = 4000
ANDROID_NOTES_MAX = 500
# 다른 버전이 이 상태에 있으면 Apple 이 새 심사 제출을 받지 않거나, 받더라도 그 버전을 대체한다.
IOS_BLOCKING_STATES = {
    "WAITING_FOR_REVIEW",
    "IN_REVIEW",
    "PENDING_APPLE_RELEASE",
    "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_APP_STORE",
    "WAITING_FOR_EXPORT_COMPLIANCE",
}


class PromoteError(Exception):
    pass


def log(msg: str = "") -> None:
    print(msg, flush=True)


# ---------------------------------------------------------------- 입력 검증


@dataclass(frozen=True)
class Version:
    marketing: str  # 1.3.7
    build: str  # 130701
    full: str  # 1.3.7+130701


def parse_version(value: str) -> Version:
    m = re.fullmatch(r"([0-9])\.([0-9])\.([0-9]{1,2})\+([0-9]{6})", value or "")
    if not m:
        raise PromoteError(f"버전 형식 오류: {value!r} (M.m.P+MmPPBB)")
    major, minor, patch, build = int(m[1]), int(m[2]), int(m[3]), m[4]
    prefix = f"{major}{minor}{patch:02d}"
    if not build.startswith(prefix):
        raise PromoteError(f"빌드 번호 {build} 가 {major}.{minor}.{patch} 의 접두 {prefix} 와 다르다")
    if int(build[4:]) < 1:
        raise PromoteError(f"빌드 순번은 01 부터다: {build}")
    return Version(f"{major}.{minor}.{patch}", build, value)


def parse_fraction(value: Optional[str], platforms: set[str]) -> Optional[str]:
    if value is None or value == "":
        return None
    if "android" not in platforms:
        raise PromoteError("--android-fraction 은 Android 를 출시할 때만 쓴다")
    try:
        f = float(value)
    except ValueError:
        raise PromoteError(f"배포 비율 형식 오류: {value!r} (0 과 1 사이, 예: 0.1)") from None
    if not 0 < f < 1:
        raise PromoteError(f"배포 비율은 0 과 1 사이여야 한다: {value} (100% 는 비율을 생략한다)")
    return value


def platforms_of(value: str) -> set[str]:
    table = {"both": {"ios", "android"}, "ios": {"ios"}, "android": {"android"}}
    if value not in table:
        raise PromoteError(f"플랫폼 오류: {value!r} (both|ios|android)")
    return table[value]


def load_notes(path: Path, version: Version, platforms: set[str]) -> dict[str, dict[str, str]]:
    """출시 노트 파일을 읽고 선택한 플랫폼의 항목을 검증한다. 파일 형식:

    {"version": "1.3.7+130701",
     "ios": {"ko": "...", "en-US": "..."},          App Store Connect 로케일 → 새로운 기능
     "android": {"ko-KR": "...", "en-US": "..."}}  Google Play 언어 → 출시 노트
    """
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise PromoteError(f"출시 노트 파일이 없다: {path}") from None
    except json.JSONDecodeError as e:
        raise PromoteError(f"출시 노트 JSON 오류: {path}: {e}") from None
    if not isinstance(data, dict):
        raise PromoteError(f"출시 노트 최상위는 객체여야 한다: {path}")
    if data.get("version") != version.full:
        raise PromoteError(f"출시 노트 버전 {data.get('version')!r} 이 대상 {version.full} 과 다르다")
    limits = {"ios": IOS_WHATS_NEW_MAX, "android": ANDROID_NOTES_MAX}
    notes: dict[str, dict[str, str]] = {}
    for platform in sorted(platforms):
        entries = data.get(platform)
        if not isinstance(entries, dict) or not entries:
            raise PromoteError(f"출시 노트에 {platform} 항목이 없다")
        for locale, text in entries.items():
            if not isinstance(text, str) or not text.strip():
                raise PromoteError(f"{platform} {locale} 출시 노트가 비었다")
            if len(text) > limits[platform]:
                raise PromoteError(f"{platform} {locale} 출시 노트가 {limits[platform]}자를 넘는다 ({len(text)}자)")
        notes[platform] = {k: v.strip() for k, v in entries.items()}
    return notes


# ---------------------------------------------------------------- 외부 명령


def run(cmd: list[str]) -> str:
    log("$ " + " ".join(cmd))
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.stderr.strip():
        sys.stderr.write(proc.stderr)
    if proc.returncode != 0:
        raise PromoteError(f"명령 실패({proc.returncode}): {' '.join(cmd[:3])} …\n{proc.stdout[-2000:]}")
    return proc.stdout


def run_json(cmd: list[str]) -> Any:
    out = run(cmd + ["--json"])
    try:
        return json.loads(out) if out.strip() else []
    except json.JSONDecodeError:
        raise PromoteError(f"JSON 이 아닌 출력: {' '.join(cmd[:3])}\n{out[-1000:]}") from None


def attrs(resource: dict) -> dict:
    return resource.get("attributes") or {}


# ---------------------------------------------------------------- 빌드 출처 확인


def check_release_tag(version: Version) -> None:
    """프로덕션 태그로 빌드된 번호인지 본다. 스테이징 빌드도 같은 앱으로 업로드되므로 번호만으로는 구별되지 않는다."""
    out = run(["git", "ls-remote", "--tags", "origin", "refs/tags/picnic-v*", "refs/tags/picnic-staging-v*"])
    tags = {line.split("refs/tags/", 1)[1].removesuffix("^{}") for line in out.splitlines() if "refs/tags/" in line}
    production = {f"picnic-v{version.full}", f"picnic-v{version.full}-skip-tests"} & tags
    staging = {t for t in tags if t.startswith(f"picnic-staging-v{version.full}")}
    if staging:
        raise PromoteError(f"{version.full} 은 스테이징 태그로 빌드됐다 — 출시할 수 없다: {', '.join(sorted(staging))}")
    if not production:
        raise PromoteError(f"{version.full} 의 프로덕션 릴리스 태그(picnic-v{version.full}[-skip-tests])가 원격에 없다")
    log(f"릴리스 태그: {', '.join(sorted(production))}")


# ---------------------------------------------------------------- iOS


@dataclass
class IosPlan:
    build_id: str = ""
    live_version: str = ""
    locales: list[str] = field(default_factory=list)
    problems: list[str] = field(default_factory=list)


def ios_preflight(version: Version, notes: Optional[dict[str, str]]) -> IosPlan:
    plan = IosPlan()
    log("\n== iOS 확인")
    apps = run_json(["app-store-connect", "apps", "list", "--bundle-id-identifier", APP_ID, "--strict-match-identifier"])
    if len(apps) != 1:
        raise PromoteError(f"번들 ID {APP_ID} 의 앱이 {len(apps)}개다")
    app_id = apps[0]["id"]

    builds = run_json([
        "app-store-connect", "builds", "list", "--app-id", app_id,
        "--pre-release-version", version.marketing, "--build-version-number", version.build,
    ])
    usable = [b for b in builds if attrs(b).get("processingState") == "VALID" and not attrs(b).get("expired")]
    for b in builds:
        a = attrs(b)
        log(f"빌드 {a.get('version')}  id={b.get('id')}  processingState={a.get('processingState')}  expired={a.get('expired')}")
    if len(usable) != 1:
        plan.problems.append(f"제출할 수 있는 빌드(VALID, 만료 안 됨)가 {len(usable)}개다 — 빌드 {version.build} 처리 상태를 확인한다")
    else:
        plan.build_id = usable[0]["id"]

    versions = run_json(["app-store-connect", "apps", "app-store-versions", app_id, "--platform", "IOS"])
    live = None
    for v in versions:
        a = attrs(v)
        state = a.get("appStoreState") or a.get("appVersionState")
        if not state:
            raise PromoteError(f"App Store 버전 {a.get('versionString')} 의 상태를 읽지 못했다 — CLI 응답 형식이 바뀌었다")
        if state in IOS_BLOCKING_STATES:
            plan.problems.append(f"App Store 버전 {a.get('versionString')} 이 {state} 상태다 — 먼저 정리한다")
        if state == "READY_FOR_SALE":
            live = v
        if a.get("versionString") == version.marketing:
            log(f"App Store 버전 {version.marketing} 이 이미 있다: {state}")
            if state == "READY_FOR_SALE":
                plan.problems.append(f"{version.marketing} 은 이미 출시됐다")
    if live is None:
        raise PromoteError("출시 중인(READY_FOR_SALE) App Store 버전이 없어 언어 목록을 정할 수 없다")
    plan.live_version = attrs(live).get("versionString", "")
    localizations = run_json(["app-store-connect", "app-store-versions", "localizations", live["id"]])
    plan.locales = sorted(attrs(loc).get("locale") for loc in localizations if attrs(loc).get("locale"))
    log(f"출시 중 버전 {plan.live_version} 의 언어 {len(plan.locales)}개: {', '.join(plan.locales)}")

    # 새 버전은 출시 중 버전의 언어를 물려받고, Apple 은 그 모든 언어에 '새로운 기능' 을 요구한다.
    # 없는 언어를 넣으면 CLI 가 새 현지화를 만들어 스토어 페이지에 언어가 늘어난다.
    if notes is not None:
        missing = sorted(set(plan.locales) - set(notes))
        extra = sorted(set(notes) - set(plan.locales))
        if missing:
            plan.problems.append(f"iOS 출시 노트에 없는 스토어 언어: {', '.join(missing)}")
        if extra:
            plan.problems.append(f"스토어에 없는 iOS 출시 노트 언어: {', '.join(extra)}")
    return plan


def ios_submit(version: Version, plan: IosPlan, notes: dict[str, str], workdir: Path) -> None:
    log("\n== iOS 심사 제출")
    path = workdir / "ios_localizations.json"
    path.write_text(
        json.dumps([{"locale": k, "whats_new": v} for k, v in sorted(notes.items())], ensure_ascii=False),
        encoding="utf-8",
    )
    run([
        "app-store-connect", "builds", "submit-to-app-store", plan.build_id,
        "--platform", "IOS",
        "--version-string", version.marketing,
        "--release-type", IOS_RELEASE_TYPE,
        "--phased-release",
        "--app-store-version-localizations", f"@file:{path}",
        "--max-build-processing-wait", "0",
    ])
    log(f"iOS {version.full} 심사 제출 완료 — 승인되면 7일 단계적 출시가 자동으로 시작된다")


# ---------------------------------------------------------------- Android


@dataclass
class AndroidPlan:
    problems: list[str] = field(default_factory=list)
    note_languages: list[str] = field(default_factory=list)  # 직전 production 출시 노트의 언어. 템플릿 참고용


def describe_releases(track: dict) -> list[str]:
    lines = []
    for r in track.get("releases") or []:
        langs = ",".join(n.get("language", "?") for n in r.get("releaseNotes") or []) or "-"
        lines.append(
            f"  status={r.get('status')} versionCodes={','.join(r.get('versionCodes') or [])} "
            f"userFraction={r.get('userFraction', '-')} notes={langs}"
        )
    return lines or ["  (release 없음)"]


def android_preflight(version: Version) -> AndroidPlan:
    plan = AndroidPlan()
    log("\n== Android 확인")
    internal = run_json(["google-play", "tracks", "get", "-p", APP_ID, "-t", "internal"])
    log("internal:")
    for line in describe_releases(internal):
        log(line)
    if not any(version.build in (r.get("versionCodes") or []) for r in internal.get("releases") or []):
        plan.problems.append(f"internal 트랙에 버전 코드 {version.build} 가 없다")

    production = run_json(["google-play", "tracks", "get", "-p", APP_ID, "-t", "production"])
    log("production:")
    for line in describe_releases(production):
        log(line)
    for r in production.get("releases") or []:
        for n in r.get("releaseNotes") or []:
            if n.get("language") and n["language"] not in plan.note_languages:
                plan.note_languages.append(n["language"])
        codes = r.get("versionCodes") or []
        if version.build in codes and r.get("status") == "completed":
            plan.problems.append(f"production 에 {version.build} 가 이미 100% 출시됐다")
        if codes and max(int(c) for c in codes) > int(version.build):
            plan.problems.append(f"production 에 더 높은 버전 코드({','.join(codes)})가 있다")
    return plan


def android_submit(version: Version, notes: dict[str, str], fraction: Optional[str], workdir: Path) -> None:
    log("\n== Android production 설정")
    path = workdir / "android_release_notes.json"
    path.write_text(
        json.dumps([{"language": k, "text": v} for k, v in sorted(notes.items())], ensure_ascii=False),
        encoding="utf-8",
    )
    cmd = [
        "google-play", "tracks", "set-release",
        "-p", APP_ID, "-t", "production", "-c", version.build,
        "--release-notes", f"@file:{path}",
    ]
    if fraction:
        cmd += ["--rollout-fraction", fraction]
    run(cmd)
    log(f"Android {version.full} production 설정 완료 — 배포 비율 {float(fraction) * 100:g}%" if fraction
        else f"Android {version.full} production 설정 완료 — 100%")


# ---------------------------------------------------------------- 진입점


def notes_template(version: Version, ios: Optional[IosPlan], android: Optional[AndroidPlan]) -> str:
    return json.dumps(
        {
            "version": version.full,
            "ios": {loc: "" for loc in (ios.locales if ios else [])},
            "android": {lang: "" for lang in (android.note_languages if android else [])},
        },
        ensure_ascii=False,
        indent=2,
    )


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--version", required=True, help="M.m.P+MmPPBB")
    p.add_argument("--mode", choices=["check", "submit"], default="check")
    p.add_argument("--platforms", default="both", help="both|ios|android")
    p.add_argument("--android-fraction", default=None, help="0 과 1 사이. 생략하면 100%%")
    p.add_argument("--notes", default=None, help=f"출시 노트 JSON (기본: {NOTES_DIR}/<버전>.json)")
    args = p.parse_args(argv)

    done: list[str] = []  # 이미 스토어에 쓴 플랫폼. 중간 실패 때 다시 실행할 범위를 알려 준다
    try:
        version = parse_version(args.version)
        platforms = platforms_of(args.platforms)
        fraction = parse_fraction(args.android_fraction, platforms)
        notes_path = Path(args.notes) if args.notes else NOTES_DIR / f"{version.full}.json"
        submit = args.mode == "submit"
        log(f"대상 {version.full}  플랫폼 {','.join(sorted(platforms))}  모드 {args.mode}"
            + (f"  Android 비율 {fraction}" if fraction else ""))

        notes: Optional[dict[str, dict[str, str]]] = None
        if notes_path.exists() or submit:
            notes = load_notes(notes_path, version, platforms)
            log(f"출시 노트 {notes_path}: " + "  ".join(f"{k} {len(v)}개 언어" for k, v in notes.items()))
        else:
            log(f"출시 노트 {notes_path} 없음 — check 는 계속하고 아래에 템플릿을 출력한다")

        check_release_tag(version)
        ios_plan = ios_preflight(version, notes["ios"] if notes else None) if "ios" in platforms else None
        android_plan = android_preflight(version) if "android" in platforms else None

        problems = (ios_plan.problems if ios_plan else []) + (android_plan.problems if android_plan else [])
        if ios_plan and submit and not ios_plan.build_id:
            problems.append("제출할 iOS 빌드 ID 가 없다")
        if problems:
            log("\n== 출시 불가")
            for msg in problems:
                log(f"- {msg}")
            if not submit and notes is None:
                log("\n출시 노트 템플릿 (Android 언어는 직전 production 출시 노트 기준이다. Play Console 스토어 등록정보와 대조한다):")
                log(notes_template(version, ios_plan, android_plan))
            return 1

        if not submit:
            log("\n== check 통과 — 스토어에는 아무것도 쓰지 않았다")
            if notes is None:
                log("출시 노트 템플릿 (Android 언어는 직전 production 출시 노트 기준이다. Play Console 스토어 등록정보와 대조한다):")
                log(notes_template(version, ios_plan, android_plan))
            return 0

        assert notes is not None
        with tempfile.TemporaryDirectory() as tmp:
            workdir = Path(tmp)
            if ios_plan:
                ios_submit(version, ios_plan, notes["ios"], workdir)
                done.append("ios")
            if android_plan:
                android_submit(version, notes["android"], fraction, workdir)
                done.append("android")
        log("\n== 출시 명령 완료")
        return 0
    except PromoteError as e:
        log(f"\n출시 중단: {e}")
        if done:
            rest = sorted({"ios", "android"} & platforms_of(args.platforms) - set(done))
            log(f"이미 완료한 플랫폼: {', '.join(done)} — 다시 실행할 때는 남은 플랫폼({', '.join(rest)})만 지정한다")
        return 1


if __name__ == "__main__":
    sys.exit(main())
