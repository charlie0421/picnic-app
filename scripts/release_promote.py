#!/usr/bin/env python3
"""picnic_app 출시 단계: 이미 업로드된 빌드를 스토어에 내보낸다.

Codemagic 워크플로 `picnic-app-promote` 가 실행한다. 로컬에서는 `scripts/release_picnic.sh promote` 로 시작한다.
절차와 승인 게이트는 .claude/skills/picnic-release/SKILL.md 가 소유한다.

  --mode check   읽기 전용. 빌드 출처·대상 빌드·스토어 상태·복사할 출시 노트를 확인한다
  --mode submit  check 를 모두 통과한 뒤에만 쓴다
                 iOS: App Store 심사 제출(승인되면 모든 사용자에게 즉시 출시, 단계적 출시 없음)
                 Android: production 트랙에 release 설정(100% 즉시. --android-fraction 은 요청이 있을 때만)
  --mode ios-release-now
                 이미 제출한 iOS 버전에 걸린 단계적 출시(아직 시작 전)를 해제해 즉시 출시로 바꾼다

출시 노트는 매번 같은 내용을 쓴다. 직전 출시본의 노트를 그대로 복사한다.
  iOS      출시 중 App Store 버전의 언어별 '새로운 기능'
  Android  production 트랙 release 의 언어별 출시 노트
문구를 바꾸려면 스토어 콘솔에서 한 번 고친다. 다음 출시부터 그 문구가 이어진다.

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
PUBSPEC = "picnic_app/pubspec.yaml"
IOS_RELEASE_TYPE = "AFTER_APPROVAL"
IOS_WHATS_NEW_MAX = 4000
ANDROID_NOTES_MAX = 500

# Apple 버전 상태. API 3.7 부터 appStoreState 는 폐기 예정이고 appVersionState 가 기준이다.
# 두 체계를 appVersionState 이름으로 맞춘다.
LEGACY_STATE = {
    "READY_FOR_SALE": "READY_FOR_DISTRIBUTION",
    "PROCESSING_FOR_APP_STORE": "PROCESSING_FOR_DISTRIBUTION",
    "PENDING_CONTRACT": "PENDING_DEVELOPER_RELEASE",
}
IOS_LIVE = "READY_FOR_DISTRIBUTION"
# 이 상태의 버전이 있으면 새 제출이 그 버전을 건드리거나 Apple 이 받지 않는다.
IOS_BLOCKING = {
    "WAITING_FOR_REVIEW",
    "IN_REVIEW",
    "ACCEPTED",
    "PENDING_APPLE_RELEASE",
    "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_DISTRIBUTION",
    "WAITING_FOR_EXPORT_COMPLIANCE",
}
# 편집 가능한 초안. CLI 는 이 중 가장 높은 버전을 골라 빌드·버전 문자열을 덮어쓴다.
IOS_EDITABLE = {
    "PREPARE_FOR_SUBMISSION",
    "READY_FOR_REVIEW",
    "DEVELOPER_REJECTED",
    "REJECTED",
    "METADATA_REJECTED",
    "INVALID_BINARY",
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


# ---------------------------------------------------------------- 외부 명령


def run(cmd: list[str], quiet: bool = False) -> str:
    if not quiet:
        log("$ " + " ".join(cmd))
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.stderr.strip() and not quiet:
        sys.stderr.write(proc.stderr)
    if proc.returncode != 0:
        raise PromoteError(f"명령 실패({proc.returncode}): {' '.join(cmd[:3])} …\n{proc.stdout[-2000:]}{proc.stderr[-1000:]}")
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


def tag_version(tag: str) -> Optional[str]:
    try:
        text = run(["git", "show", f"refs/tags/{tag}:{PUBSPEC}"], quiet=True)
    except PromoteError:
        return None
    m = re.search(r"^version:\s*(\S+)", text, re.MULTILINE)
    return m[1] if m else None


def check_release_tag(version: Version) -> None:
    """프로덕션 태그로 빌드된 번호인지 태그 커밋의 pubspec 으로 확인한다.

    스테이징 빌드도 같은 앱으로 업로드되고, 태그 이름에 빌드 번호가 없거나 pubspec 과 다른 태그가 있다
    (예: picnic-staging-v1.2.39 → 1.2.39+123901). 그래서 이름이 아니라 커밋 내용으로 대조한다.
    """
    # 태그 커밋의 pubspec 만 필요하다. 전체 이력은 받지 않는다.
    run(["git", "fetch", "--quiet", "--force", "--depth=1", "origin",
         "+refs/tags/picnic-v*:refs/tags/picnic-v*",
         "+refs/tags/picnic-staging-v*:refs/tags/picnic-staging-v*"])
    tags = run(["git", "for-each-ref", "--format=%(refname:short)",
                "refs/tags/picnic-v*", "refs/tags/picnic-staging-v*"], quiet=True).split()
    names = {f"picnic-v{version.full}", f"picnic-v{version.full}-skip-tests"}
    production, staging = [], []
    for tag in tags:
        if tag.startswith("picnic-staging-v"):
            v = tag_version(tag)
            if v is None or v.endswith(f"+{version.build}") or version.build in tag:
                staging.append(f"{tag}({v or 'pubspec 없음'})")
        elif tag in names:
            v = tag_version(tag)
            if v != version.full:
                raise PromoteError(f"{tag} 커밋의 pubspec 버전({v})이 {version.full} 과 다르다")
            production.append(tag)
    if staging:
        raise PromoteError(f"빌드 번호 {version.build} 를 쓴 스테이징 태그가 있다 — 출시할 수 없다: {', '.join(staging)}")
    if not production:
        raise PromoteError(f"{version.full} 의 프로덕션 릴리스 태그(picnic-v{version.full}[-skip-tests])가 원격에 없다")
    log(f"릴리스 태그: {', '.join(production)} (pubspec {version.full})")


# ---------------------------------------------------------------- iOS


def ios_state(version_resource: dict) -> str:
    a = attrs(version_resource)
    state = a.get("appVersionState") or a.get("appStoreState")
    if not state:
        raise PromoteError(f"App Store 버전 {a.get('versionString')} 의 상태를 읽지 못했다 — CLI 응답 형식이 바뀌었다")
    return LEGACY_STATE.get(state, state)


def version_key(value: str) -> tuple[int, ...]:
    """"1.3.6" → (1, 3, 6). 숫자가 아닌 조각은 0 으로 본다."""
    return tuple(int(x) if x.isdigit() else 0 for x in value.split("."))


def localizations_of(version_id: str) -> dict[str, str]:
    """로케일 → 새로운 기능. 값이 없으면 빈 문자열."""
    items = run_json(["app-store-connect", "app-store-versions", "localizations", version_id])
    out = {}
    for loc in items:
        a = attrs(loc)
        if a.get("locale"):
            out[a["locale"]] = (a.get("whatsNew") or "").strip()
    return out


def ios_app_id() -> str:
    apps = run_json(["app-store-connect", "apps", "list", "--bundle-id-identifier", APP_ID, "--strict-match-identifier"])
    if len(apps) != 1:
        raise PromoteError(f"번들 ID {APP_ID} 의 앱이 {len(apps)}개다")
    return apps[0]["id"]


@dataclass
class IosPlan:
    build_id: str = ""
    notes: dict[str, str] = field(default_factory=dict)
    problems: list[str] = field(default_factory=list)


def ios_preflight(version: Version) -> IosPlan:
    plan = IosPlan()
    log("\n== iOS 확인")
    app_id = ios_app_id()

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
    # appVersionState 는 지난 출시본도 모두 READY_FOR_DISTRIBUTION 이다(실측: 96개 전부). 그중 가장 높은 버전이 출시 중이다.
    released, drafts = [], []
    for v in versions:
        state, name = ios_state(v), attrs(v).get("versionString")
        if state in IOS_BLOCKING:
            log(f"App Store 버전 {name}: {state}")
            plan.problems.append(f"App Store 버전 {name} 이 {state} 상태다 — 먼저 정리한다")
        elif state in IOS_EDITABLE:
            log(f"App Store 버전 {name}: {state}")
            drafts.append(v)
        elif state == IOS_LIVE:
            released.append(v)
            if name == version.marketing:
                plan.problems.append(f"{version.marketing} 은 이미 출시됐다")
    if not released:
        raise PromoteError("출시된(READY_FOR_DISTRIBUTION) App Store 버전이 없어 출시 노트를 복사할 수 없다")
    live = max(released, key=lambda v: version_key(attrs(v).get("versionString", "")))
    log(f"App Store 버전 {len(versions)}개 중 출시본 {len(released)}개, 출시 중 {attrs(live).get('versionString')}")

    # 출시 노트: 출시 중 버전의 '새로운 기능' 을 그대로 쓴다. 새 버전은 이 언어들을 물려받고,
    # Apple 은 업데이트의 모든 언어에 '새로운 기능' 을 요구한다.
    live_name = attrs(live).get("versionString")
    plan.notes = localizations_of(live["id"])
    log(f"출시 중 버전 {live_name} 의 언어 {len(plan.notes)}개: {', '.join(sorted(plan.notes))}")
    empty = sorted(k for k, t in plan.notes.items() if not t)
    if not plan.notes:
        plan.problems.append(f"출시 중 버전 {live_name} 에 현지화가 없다")
    if empty:
        plan.problems.append(f"출시 중 버전 {live_name} 의 '새로운 기능' 이 빈 언어: {', '.join(empty)}")
    long = sorted(k for k, t in plan.notes.items() if len(t) > IOS_WHATS_NEW_MAX)
    if long:
        plan.problems.append(f"'새로운 기능' 이 {IOS_WHATS_NEW_MAX}자를 넘는 언어: {', '.join(long)}")

    # 초안: CLI 는 편집 가능한 버전 중 가장 높은 것을 재사용하고 기존 현지화를 남긴다.
    # 다른 버전의 초안을 이번 버전으로 바꾸거나, 초안에만 있는 언어의 미확인 문구를 제출하지 않게 막는다.
    for d in drafts:
        name = attrs(d).get("versionString")
        if name != version.marketing:
            plan.problems.append(f"다른 버전의 초안 {name}({ios_state(d)})이 있다 — CLI 가 그 초안을 덮어쓴다. App Store Connect 에서 정리한다")
            continue
        draft_locales = set(localizations_of(d["id"]))
        extra = sorted(draft_locales - set(plan.notes))
        if extra:
            plan.problems.append(f"{name} 초안에 출시 중 버전에 없는 언어가 있다: {', '.join(extra)}")
        log(f"{name} 초안({ios_state(d)})을 재사용한다")
    for locale, text in sorted(plan.notes.items()):
        log(f"  [{locale}] {text[:80]}{'…' if len(text) > 80 else ''}")
    return plan


def ios_submit(version: Version, plan: IosPlan, workdir: Path) -> None:
    log("\n== iOS 심사 제출")
    path = workdir / "ios_localizations.json"
    path.write_text(
        json.dumps([{"locale": k, "whats_new": v} for k, v in sorted(plan.notes.items())], ensure_ascii=False),
        encoding="utf-8",
    )
    run([
        "app-store-connect", "builds", "submit-to-app-store", plan.build_id,
        "--platform", "IOS",
        "--version-string", version.marketing,
        "--release-type", IOS_RELEASE_TYPE,
        "--no-phased-release",
        "--app-store-version-localizations", f"@file:{path}",
        "--max-build-processing-wait", "0",
    ])
    log(f"iOS {version.full} 심사 제출 완료 — 승인되면 모든 사용자에게 즉시 출시된다")


def ios_release_now(version: Version, submit: bool) -> None:
    """이미 제출한 버전의 단계적 출시를 해제한다. 시작 전(INACTIVE)일 때만 쓴다. check 모드는 상태만 본다."""
    log("\n== iOS 단계적 출시 해제")
    app_id = ios_app_id()
    versions = run_json(["app-store-connect", "apps", "app-store-versions", app_id, "--platform", "IOS"])
    targets = [v for v in versions if attrs(v).get("versionString") == version.marketing]
    if len(targets) != 1:
        raise PromoteError(f"App Store 버전 {version.marketing} 이 {len(targets)}개다")
    target = targets[0]
    state = ios_state(target)
    log(f"App Store 버전 {version.marketing}: {state}")
    if state == IOS_LIVE:
        raise PromoteError(f"{version.marketing} 은 이미 출시됐다 — 진행 중인 단계적 출시는 App Store Connect 에서 '모든 사용자에게 출시' 로 끝낸다")

    cmd = ["app-store-connect", "app-store-versions", "phased-release", target["id"], "--json"]
    log("$ " + " ".join(cmd))
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        # 설정이 없을 때 CLI 가 내는 정확한 문구만 '없음' 으로 본다. 다른 API·인증·통신 오류는 실패다.
        not_found = f"App Store Version Phased Release was not found for App Store Version {target['id']}"
        lines = [re.sub(r"\x1b\[[0-9;]*m", "", ln).strip() for ln in (proc.stdout + "\n" + proc.stderr).splitlines()]
        if not_found in lines:
            log("단계적 출시가 설정돼 있지 않다 — 이미 즉시 출시다")
            return
        raise PromoteError(f"단계적 출시 상태를 읽지 못했다\n{proc.stdout[-1000:]}{proc.stderr[-1000:]}")
    try:
        phased = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise PromoteError(f"JSON 이 아닌 출력: {proc.stdout[-500:]}") from None
    phased_state = attrs(phased).get("phasedReleaseState")
    log(f"단계적 출시 {phased.get('id')}: {phased_state}")
    if phased_state != "INACTIVE":
        # 시작된 단계적 출시를 끝내는 것은 즉시 전체 배포다. 이 스크립트는 하지 않는다.
        raise PromoteError(f"단계적 출시가 이미 {phased_state} 상태다 — App Store Connect 에서 처리한다")
    if not submit:
        log("check — 해제할 수 있다. 스토어에는 아무것도 쓰지 않았다")
        return
    run(["app-store-connect", "app-store-version-phased-releases", "cancel", phased["id"]])
    log(f"iOS {version.marketing} 단계적 출시 해제 완료 — 승인되면 모든 사용자에게 즉시 출시된다")


# ---------------------------------------------------------------- Android


@dataclass
class AndroidPlan:
    notes: list[dict[str, str]] = field(default_factory=list)  # [{"language", "text"}]
    problems: list[str] = field(default_factory=list)


def describe_releases(track: dict) -> list[str]:
    lines = []
    for r in track.get("releases") or []:
        langs = ",".join(n.get("language", "?") for n in r.get("releaseNotes") or []) or "-"
        lines.append(
            f"  status={r.get('status')} versionCodes={','.join(r.get('versionCodes') or [])} "
            f"userFraction={r.get('userFraction', '-')} notes={langs}"
        )
    return lines or ["  (release 없음)"]


def android_language_problems(notes: list[dict[str, str]]) -> list[str]:
    """google-play CLI 가 --release-notes 를 해석할 때 거부할 값을 쓰기 전에 잡는다.

    CLI 는 인자 해석 단계에서 언어를 자체 목록과 대조한다. 여기서 놓치면 iOS 만 제출된 채 멈춘다.
    """
    problems = [f"Android {n['language']} 출시 노트가 {ANDROID_NOTES_MAX}자를 넘는다" for n in notes if len(n["text"]) > ANDROID_NOTES_MAX]
    try:
        from codemagic.google.resources.google_play import Language  # type: ignore
        from codemagic.models.enums import ResourceEnumMeta  # type: ignore
    except ImportError:
        if os.environ.get("CM_BUILD_ID"):
            return problems + ["codemagic-cli-tools 를 불러오지 못해 Android 언어를 검증하지 못했다"]
        log("(codemagic-cli-tools 가 없어 Android 언어 코드 검증을 건너뛴다 — Codemagic 에서는 필수)")
        return problems
    # 평소 CLI 열거형은 모르는 값도 받아 주지만, 인자 해석 중에는 그 대체를 끄고 거부한다. 같은 조건으로 본다.
    with ResourceEnumMeta.without_graceful_fallback():
        for n in notes:
            try:
                Language(n["language"])
            except ValueError:
                problems.append(f"google-play CLI 가 받지 않는 Android 언어: {n['language']}")
    return problems


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
    latest = None  # 가장 높은 버전 코드의 release. 노트 유무와 관계없이 먼저 고른다
    for r in production.get("releases") or []:
        codes = r.get("versionCodes") or []
        if version.build in codes and r.get("status") == "completed":
            plan.problems.append(f"production 에 {version.build} 가 이미 100% 출시됐다")
        if codes and max(int(c) for c in codes) > int(version.build):
            plan.problems.append(f"production 에 더 높은 버전 코드({','.join(codes)})가 있다")
        if codes and (latest is None or max(int(c) for c in codes) > max(int(c) for c in latest["versionCodes"])):
            latest = r

    # 출시 노트: production 의 가장 높은 버전 release 의 노트를 그대로 쓴다.
    # 그 release 에 노트가 없으면 더 낮은 버전의 오래된 노트로 내려가지 않고 멈춘다.
    if latest is None or not latest.get("releaseNotes"):
        where = f"버전 {','.join(latest['versionCodes'])}" if latest else "production 트랙"
        plan.problems.append(f"{where} 에 복사할 출시 노트가 없다 — Play Console 에서 직전 release 의 노트를 확인한다")
        return plan
    source = latest
    plan.notes = [
        {"language": n.get("language", ""), "text": (n.get("text") or "").strip()}
        for n in source.get("releaseNotes") or []
    ]
    empty = sorted(n["language"] for n in plan.notes if not n["text"] or not n["language"])
    if empty:
        plan.problems.append(f"직전 production 출시 노트가 빈 언어: {', '.join(empty)}")
    plan.problems += android_language_problems(plan.notes)
    log(f"복사할 출시 노트: 버전 {','.join(source.get('versionCodes') or [])} 의 {len(plan.notes)}개 언어")
    for n in plan.notes:
        log(f"  [{n['language']}] {n['text'][:80]}{'…' if len(n['text']) > 80 else ''}")
    return plan


def android_submit(version: Version, plan: AndroidPlan, fraction: Optional[str], workdir: Path) -> None:
    log("\n== Android production 설정")
    path = workdir / "android_release_notes.json"
    path.write_text(json.dumps(plan.notes, ensure_ascii=False), encoding="utf-8")
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


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--version", required=True, help="M.m.P+MmPPBB")
    p.add_argument("--mode", choices=["check", "submit", "ios-release-now", "ios-release-now-check"], default="check")
    p.add_argument("--platforms", default="both", help="both|ios|android")
    p.add_argument("--android-fraction", default=None, help="0 과 1 사이. 생략하면 100%%")
    args = p.parse_args(argv)

    done: list[str] = []  # 이미 스토어에 쓴 플랫폼. 중간 실패 때 다시 실행할 범위를 알려 준다
    try:
        version = parse_version(args.version)
        platforms = platforms_of(args.platforms)
        fraction = parse_fraction(args.android_fraction, platforms)
        submit = args.mode == "submit"
        log(f"대상 {version.full}  플랫폼 {','.join(sorted(platforms))}  모드 {args.mode}"
            + (f"  Android 비율 {fraction}" if fraction else ""))
        if args.mode.startswith("ios-release-now"):
            if platforms != {"ios"} or fraction:
                raise PromoteError("ios-release-now 는 --platforms ios 로만 쓴다")
            ios_release_now(version, submit=args.mode == "ios-release-now")
            return 0

        check_release_tag(version)
        ios_plan = ios_preflight(version) if "ios" in platforms else None
        android_plan = android_preflight(version) if "android" in platforms else None

        # 빌드 ID 가 없으면 ios_preflight 가 이미 problems 에 넣었다.
        problems = (ios_plan.problems if ios_plan else []) + (android_plan.problems if android_plan else [])
        if problems:
            log("\n== 출시 불가")
            for msg in problems:
                log(f"- {msg}")
            return 1
        if not submit:
            log("\n== check 통과 — 스토어에는 아무것도 쓰지 않았다")
            return 0

        with tempfile.TemporaryDirectory() as tmp:
            workdir = Path(tmp)
            if ios_plan:
                ios_submit(version, ios_plan, workdir)
                done.append("ios")
            if android_plan:
                android_submit(version, android_plan, fraction, workdir)
                done.append("android")
        log("\n== 출시 명령 완료")
        return 0
    except PromoteError as e:
        log(f"\n출시 중단: {e}")
        if done:
            rest = sorted(platforms_of(args.platforms) - set(done))
            log(f"이미 완료한 플랫폼: {', '.join(done)} — 다시 실행할 때는 남은 플랫폼({', '.join(rest)})만 지정한다")
        return 1


if __name__ == "__main__":
    sys.exit(main())
