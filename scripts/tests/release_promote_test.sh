#!/usr/bin/env bash
# scripts/release_promote.py 의 회귀 테스트. 가짜 스토어 CLI(scripts/tests/fake-store)로 App Store Connect·Google Play 를 흉내 내고,
# 릴리스 태그는 임시 bare 저장소로 만든다.
# 실행: scripts/tests/release_promote_test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../release_promote.py"
export PATH="$HERE/fake-store:$PATH"

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok   $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
unset CM_BUILD_ID

# google-play CLI 의 언어 목록 대역. 실제 패키지가 없는 환경에서도 언어 검증 경로를 탄다.
FAKE_PY="$ROOT/py/codemagic/google/resources/google_play"
mkdir -p "$FAKE_PY"
touch "$ROOT/py/codemagic/__init__.py" "$ROOT/py/codemagic/google/__init__.py" "$ROOT/py/codemagic/google/resources/__init__.py"
printf 'import enum\nclass Language(enum.Enum):\n    KO = "ko-KR"\n    EN = "en-US"\n    JA = "ja-JP"\n' > "$FAKE_PY/__init__.py"
mkdir -p "$ROOT/py/codemagic/models"
printf 'import contextlib\nclass ResourceEnumMeta:\n    @staticmethod\n    def without_graceful_fallback():\n        return contextlib.nullcontext()\n' > "$ROOT/py/codemagic/models/enums.py"

# tags <버전|- 태그>... → 새 원격과 작업 사본(W). "1.3.7+130701 picnic-v1.3.7+130701" 은 그 pubspec 버전의 커밋에 태그를 붙인다.
tags() {
  local d; d=$(mktemp -d "$ROOT/g.XXXX")
  git init -q --bare -b main "$d/origin.git"
  git init -q -b main "$d/w"; W="$d/w"
  mkdir -p "$W/picnic_app"
  while [ $# -gt 0 ]; do
    printf 'name: picnic_app\nversion: %s\n' "$1" > "$W/picnic_app/pubspec.yaml"
    git -C "$W" add -A && git -C "$W" commit -qm "$1" --allow-empty
    git -C "$W" tag -a "$2" -m "$2"; shift 2
  done
  git -C "$W" remote add origin "$d/origin.git"
  git -C "$W" push -q origin main --tags
  git -C "$W" tag -l | xargs git -C "$W" tag -d >/dev/null   # 스크립트가 원격에서 다시 받아야 한다
}

# fresh → 정상 상태의 가짜 스토어와 태그. 각 테스트가 필요한 파일만 덮어쓴다.
fresh() {
  D=$(mktemp -d "$ROOT/s.XXXX"); export FAKE_STORE_DIR="$D"
  unset FAKE_IOS_SUBMIT_FAIL FAKE_ANDROID_FAIL
  export PYTHONPATH="$ROOT/py"
  tags 1.3.6+130607 picnic-v1.3.6+130607-skip-tests 1.3.7+130701 picnic-v1.3.7+130701-skip-tests
  echo '[{"id": "1234567890", "type": "apps", "attributes": {"bundleId": "io.iconcasting.picnic.app"}}]' > "$D/apps.json"
  echo '[{"id": "build-130701", "type": "builds", "attributes": {"version": "130701", "processingState": "VALID", "expired": false}}]' > "$D/builds.json"
  cat > "$D/versions.json" <<'J'
[{"id": "ver-136", "type": "appStoreVersions", "attributes": {"versionString": "1.3.6", "appVersionState": "READY_FOR_DISTRIBUTION", "appStoreState": "READY_FOR_SALE"}},
 {"id": "ver-135", "type": "appStoreVersions", "attributes": {"versionString": "1.3.5", "appVersionState": "REPLACED_WITH_NEW_VERSION"}}]
J
  echo '[{"id": "l1", "attributes": {"locale": "ko", "whatsNew": "버그 수정 및 성능 개선"}}, {"id": "l2", "attributes": {"locale": "en-US", "whatsNew": "Bug fixes"}}, {"id": "l3", "attributes": {"locale": "ja", "whatsNew": "不具合修正"}}]' > "$D/loc-ver-136.json"
  echo '{"track": "internal", "releases": [{"status": "completed", "versionCodes": ["130701"]}]}' > "$D/internal.json"
  echo '{"track": "production", "releases": [{"status": "completed", "versionCodes": ["130607"], "releaseNotes": [{"language": "ko-KR", "text": "버그 수정 및 성능 개선"}, {"language": "en-US", "text": "Bug fixes"}]}]}' > "$D/production.json"
}
run() { (cd "$W" && python3 "$SCRIPT" --version 1.3.7+130701 "$@") 2>&1; }
calls() { cat "$D/calls.log" 2>/dev/null; }
wrote() { grep -Eq 'submit-to-app-store|set-release' "$D/calls.log" 2>/dev/null; }
jset() { jq "$2" "$D/$1" > "$D/.tmp" && mv "$D/.tmp" "$D/$1"; }

echo "1. check 는 모든 확인을 하고 스토어에 쓰지 않는다"
fresh
out=$(run --mode check); rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "no store writes" '! wrote'
check "reads both stores" 'grep -q "builds list" <<<"$(calls)" && grep -q "tracks get" <<<"$(calls)"'
check "shows notes to copy" 'grep -q "\[ko\] 버그 수정 및 성능 개선" <<<"$out" && grep -q "\[ko-KR\] 버그 수정 및 성능 개선" <<<"$out"'

echo "2. submit 은 직전 출시 노트를 복사해 iOS 를 승인 즉시·단계적 출시로 제출하고 Android 를 100% 로 설정한다"
fresh
out=$(run --mode submit); rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "iOS submit: release after approval, no phased release" 'grep -q "submit-to-app-store build-130701 --platform IOS --version-string 1.3.7 --release-type AFTER_APPROVAL --no-phased-release" <<<"$(calls)"'
check "iOS whats_new copied from live version" '[ "$(jq -c "map([.locale, .whats_new])" "$D/submitted_ios.json")" = "[[\"en-US\",\"Bug fixes\"],[\"ja\",\"不具合修正\"],[\"ko\",\"버그 수정 및 성능 개선\"]]" ]'
check "Android production 130701 without fraction" 'grep -q "set-release -p io.iconcasting.picnic.app -t production -c 130701" <<<"$(calls)" && ! grep -q -- "--rollout-fraction" <<<"$(calls)"'
check "Android notes copied from production" '[ "$(jq -c "map([.language, .text])" "$D/submitted_android.json")" = "[[\"ko-KR\",\"버그 수정 및 성능 개선\"],[\"en-US\",\"Bug fixes\"]]" ]'

echo "3. Android 배포 비율을 주면 단계적 배포로 설정한다"
fresh
out=$(run --mode submit --platforms android --android-fraction 0.1); rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "fraction passed" 'grep -q -- "--rollout-fraction 0.1" <<<"$(calls)"'
check "iOS untouched" '! grep -q "app-store-connect" <<<"$(calls)"'

echo "4. 배포 비율은 0 과 1 사이만 받고, iOS 단독 출시에는 받지 않는다"
fresh
out=$(run --mode submit --android-fraction 1.5); rc=$?
check "1.5 refused" '[ $rc -ne 0 ] && ! wrote'
out=$(run --mode submit --android-fraction 1); rc=$?
check "1 refused (100% omits fraction)" '[ $rc -ne 0 ] && ! wrote'
out=$(run --mode submit --platforms ios --android-fraction 0.1); rc=$?
check "iOS-only with fraction refused" '[ $rc -ne 0 ] && ! wrote'

echo "5. 복사할 출시 노트가 없으면 어느 플랫폼에도 쓰지 않는다"
fresh
jset loc-ver-136.json '(.[] | select(.attributes.locale == "ja") | .attributes.whatsNew) = null'
out=$(run --mode submit); rc=$?
check "empty iOS whatsNew refused" '[ $rc -ne 0 ] && ! wrote && grep -q "빈 언어: ja" <<<"$out"'
fresh
jset production.json '.releases[0] |= del(.releaseNotes)'
out=$(run --mode submit); rc=$?
check "no Android notes refused" '[ $rc -ne 0 ] && ! wrote && grep -q "복사할 출시 노트가 없다" <<<"$out"'
fresh
jset production.json '.releases[0].releaseNotes += [{"language": "ko", "text": "x"}]'
out=$(run --mode submit); rc=$?
check "Android language the CLI rejects is caught before iOS submit" '[ $rc -ne 0 ] && ! wrote && grep -q "받지 않는 Android 언어: ko$" <<<"$out"'
fresh
jq --arg t "$(printf 'a%.0s' $(seq 501))" '.releases[0].releaseNotes[1].text = $t' "$D/production.json" > "$D/.tmp" && mv "$D/.tmp" "$D/production.json"
out=$(run --mode submit); rc=$?
check "Android note over 500 chars refused" '[ $rc -ne 0 ] && ! wrote'
fresh
out=$(PYTHONPATH= CM_BUILD_ID=x run --mode submit); rc=$?
check "on Codemagic, missing CLI package blocks the release" '[ $rc -ne 0 ] && ! wrote'

fresh
echo '{"track": "production", "releases": [{"status": "inProgress", "userFraction": 0.5, "versionCodes": ["130607"], "releaseNotes": [{"language": "ko-KR", "text": "최신 노트"}]}, {"status": "completed", "versionCodes": ["130501"], "releaseNotes": [{"language": "ko-KR", "text": "옛 노트"}]}]}' > "$D/production.json"
out=$(run --mode submit); rc=$?
check "notes come from the highest version code release" '[ $rc -eq 0 ] && [ "$(jq -r ".[0].text" "$D/submitted_android.json")" = "최신 노트" ]'
for missing in 'del(.releaseNotes)' '.releaseNotes = []'; do
  fresh
  echo '{"track": "production", "releases": [{"status": "inProgress", "userFraction": 0.5, "versionCodes": ["130607"]}, {"status": "completed", "versionCodes": ["130501"], "releaseNotes": [{"language": "ko-KR", "text": "옛 노트"}]}]}' > "$D/production.json"
  jset production.json ".releases[0] |= ($missing)"
  out=$(run --mode submit); rc=$?
  check "highest release without notes ($missing) refused, no fallback to older notes" '[ $rc -ne 0 ] && ! wrote && grep -q "버전 130607 에 복사할 출시 노트가 없다" <<<"$out"'
done

echo "6. 빌드 출처: 태그 커밋의 pubspec 으로 프로덕션 빌드만 받는다"
fresh
tags 1.3.6+130607 picnic-v1.3.6+130607-skip-tests
out=$(run --mode submit); rc=$?
check "untagged version refused" '[ $rc -ne 0 ] && ! wrote'
fresh
tags 1.3.7+130701 picnic-staging-v1.3.7 1.3.7+130701 picnic-v1.3.7+130701-skip-tests
out=$(run --mode submit); rc=$?
check "staging tag without build number in its name refused" '[ $rc -ne 0 ] && ! wrote && grep -q "picnic-staging-v1.3.7(1.3.7+130701)" <<<"$out"'
fresh
tags 1.3.7+130701 picnic-staging-v1.3.7+130701
out=$(run --mode submit); rc=$?
check "staging-named version refused" '[ $rc -ne 0 ] && ! wrote && grep -q "스테이징" <<<"$out"'
fresh
tags 1.3.7+130700 picnic-v1.3.7+130701
out=$(run --mode submit); rc=$?
check "production tag whose pubspec differs refused" '[ $rc -ne 0 ] && ! wrote && grep -q "pubspec 버전(1.3.7+130700)" <<<"$out"'
fresh
tags 1.3.7+130701 picnic-v1.3.7+130701 1.3.8+130801 picnic-staging-v1.3.8
out=$(run --mode check); rc=$?
check "full-test tag accepted; unrelated staging tag ignored" '[ $rc -eq 0 ]'

echo "7. App Store 상태"
fresh
echo '[{"id": "b", "attributes": {"version": "130701", "processingState": "PROCESSING", "expired": false}}]' > "$D/builds.json"
out=$(run --mode submit); rc=$?
check "unprocessed build refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "WAITING_FOR_REVIEW"}}]'
out=$(run --mode submit); rc=$?
check "version waiting for review refused" '[ $rc -ne 0 ] && ! wrote && grep -q "WAITING_FOR_REVIEW" <<<"$out"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "PROCESSING_FOR_DISTRIBUTION"}}]'
out=$(run --mode submit); rc=$?
check "version processing for distribution refused" '[ $rc -ne 0 ] && ! wrote'
fresh
echo '[{"id": "v", "attributes": {"versionString": "1.3.6"}}]' > "$D/versions.json"
out=$(run --mode submit); rc=$?
check "unknown version state refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jset versions.json 'map(.attributes |= del(.appStoreState))'
out=$(run --mode check); rc=$?
check "appVersionState-only response finds the live version" '[ $rc -eq 0 ]'
fresh
jset versions.json 'map(.attributes |= (.appStoreState //= .appVersionState | del(.appVersionState)))'
out=$(run --mode check); rc=$?
check "legacy appStoreState-only response finds the live version" '[ $rc -eq 0 ]'

fresh
cat > "$D/versions.json" <<'J'
[{"id": "ver-136", "attributes": {"versionString": "1.3.6", "appVersionState": "READY_FOR_DISTRIBUTION"}},
 {"id": "ver-1310", "attributes": {"versionString": "1.3.10", "appVersionState": "READY_FOR_DISTRIBUTION"}},
 {"id": "ver-10", "attributes": {"versionString": "1.0", "appVersionState": "READY_FOR_DISTRIBUTION"}}]
J
echo '[{"attributes": {"locale": "ko", "whatsNew": "1.3.10 노트"}}]' > "$D/loc-ver-1310.json"
echo '[{"attributes": {"locale": "ko", "whatsNew": ""}}]' > "$D/loc-ver-10.json"
out=$(run --mode check); rc=$?
check "all past releases are READY_FOR_DISTRIBUTION: the highest version (numeric) is live" '[ $rc -eq 0 ] && grep -q "출시 중 1.3.10" <<<"$out" && grep -q "\[ko\] 1.3.10 노트" <<<"$out"'

echo "8. 편집 가능한 초안: 다른 버전 초안은 막고, 같은 버전 초안은 언어까지 확인한다"
fresh
jset versions.json '. + [{"id": "ver-140", "attributes": {"versionString": "1.4.0", "appVersionState": "PREPARE_FOR_SUBMISSION"}}]'
echo '[]' > "$D/loc-ver-140.json"
out=$(run --mode submit); rc=$?
check "other version draft refused" '[ $rc -ne 0 ] && ! wrote && grep -q "다른 버전의 초안 1.4.0" <<<"$out"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "PREPARE_FOR_SUBMISSION"}}]'
echo '[{"attributes": {"locale": "ko", "whatsNew": ""}}, {"attributes": {"locale": "de-DE", "whatsNew": "alt"}}]' > "$D/loc-ver-137.json"
out=$(run --mode submit); rc=$?
check "same version draft with extra locale refused" '[ $rc -ne 0 ] && ! wrote && grep -q "de-DE" <<<"$out"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "REJECTED"}}]'
echo '[{"attributes": {"locale": "ko", "whatsNew": ""}}, {"attributes": {"locale": "en-US"}}]' > "$D/loc-ver-137.json"
out=$(run --mode submit); rc=$?
check "same version draft with known locales is reused" '[ $rc -eq 0 ] && grep -q "submit-to-app-store" <<<"$(calls)"'

echo "9. Google Play 상태"
fresh
echo '{"track": "internal", "releases": [{"status": "completed", "versionCodes": ["130607"]}]}' > "$D/internal.json"
out=$(run --mode submit); rc=$?
check "missing internal build refused before iOS submit" '[ $rc -ne 0 ] && ! wrote'
fresh
jset production.json '.releases[0].versionCodes = ["130701"]'
out=$(run --mode submit --platforms android); rc=$?
check "already 100% on production refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jset production.json '.releases[0] += {"status": "inProgress", "userFraction": 0.1, "versionCodes": ["130701"]}'
out=$(run --mode submit --platforms android); rc=$?
check "staged rollout can be raised to 100%" '[ $rc -eq 0 ] && grep -q "set-release" <<<"$(calls)"'
fresh
jset production.json '.releases[0].versionCodes = ["130801"]'
out=$(run --mode submit --platforms android); rc=$?
check "higher version on production refused" '[ $rc -ne 0 ] && ! wrote'

echo "9b. ios-release-now: 제출한 버전의 시작 전 단계적 출시만 해제한다"
rn() { (cd "$W" && python3 "$SCRIPT" --version 1.3.7+130701 --platforms ios "$@") 2>&1; }
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "WAITING_FOR_REVIEW"}}]'
echo '{"id": "pr-137", "attributes": {"phasedReleaseState": "INACTIVE"}}' > "$D/phased-ver-137.json"
out=$(rn --mode ios-release-now-check); rc=$?
check "check mode reads but does not cancel" '[ $rc -eq 0 ] && ! grep -q "phased-releases cancel" <<<"$(calls)"'
out=$(rn --mode ios-release-now); rc=$?
check "inactive phased release is cancelled" '[ $rc -eq 0 ] && grep -q "app-store-version-phased-releases cancel pr-137" <<<"$(calls)"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "WAITING_FOR_REVIEW"}}]'
out=$(rn --mode ios-release-now); rc=$?
check "no phased release: nothing to do" '[ $rc -eq 0 ] && grep -q "이미 즉시 출시" <<<"$out" && ! grep -q "phased-releases cancel" <<<"$(calls)"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "WAITING_FOR_REVIEW"}}]'
echo '{"id": "pr-137", "attributes": {"phasedReleaseState": "ACTIVE"}}' > "$D/phased-ver-137.json"
out=$(rn --mode ios-release-now); rc=$?
check "started phased release is left to App Store Connect" '[ $rc -ne 0 ] && ! grep -q "phased-releases cancel" <<<"$(calls)"'
fresh
jset versions.json '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appVersionState": "READY_FOR_DISTRIBUTION"}}]'
out=$(rn --mode ios-release-now); rc=$?
check "released version refused" '[ $rc -ne 0 ] && ! grep -q "phased-releases cancel" <<<"$(calls)"'
fresh
out=$(rn --mode ios-release-now); rc=$?
check "missing version refused" '[ $rc -ne 0 ] && grep -q "0개" <<<"$out"'
out=$(cd "$W" && python3 "$SCRIPT" --version 1.3.7+130701 --platforms both --mode ios-release-now 2>&1); rc=$?
check "ios-release-now needs --platforms ios" '[ $rc -ne 0 ] && ! grep -q "phased-releases cancel" <<<"$(calls)"'

echo "10. 중간 실패는 이미 끝난 플랫폼과 남은 플랫폼을 알려 준다"
fresh
export FAKE_ANDROID_FAIL=1
out=$(run --mode submit); rc=$?
check "exit non-zero" '[ $rc -ne 0 ]'
check "names finished and remaining platforms" 'grep -q "이미 완료한 플랫폼: ios" <<<"$out" && grep -q "남은 플랫폼(android)" <<<"$out"'
fresh
export FAKE_IOS_SUBMIT_FAIL=1
out=$(run --mode submit); rc=$?
check "iOS failure stops before Android" '[ $rc -ne 0 ] && ! grep -q "set-release" <<<"$(calls)"'

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
