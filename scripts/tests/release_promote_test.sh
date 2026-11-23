#!/usr/bin/env bash
# scripts/release_promote.py 의 회귀 테스트. 가짜 스토어 CLI·git(scripts/tests/fake-store)로 App Store Connect·Google Play 를 흉내 낸다.
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

# fresh → 정상 상태의 가짜 스토어. 각 테스트가 필요한 파일만 덮어쓴다.
fresh() {
  D=$(mktemp -d "$ROOT/s.XXXX"); export FAKE_STORE_DIR="$D"
  unset FAKE_IOS_SUBMIT_FAIL FAKE_ANDROID_FAIL
  printf 'aaa\trefs/tags/picnic-v1.3.6+130607-skip-tests\nbbb\trefs/tags/picnic-v1.3.7+130701-skip-tests\nccc\trefs/tags/picnic-v1.3.7+130701-skip-tests^{}\n' > "$D/tags.txt"
  echo '[{"id": "1234567890", "type": "apps", "attributes": {"bundleId": "io.iconcasting.picnic.app"}}]' > "$D/apps.json"
  echo '[{"id": "build-130701", "type": "builds", "attributes": {"version": "130701", "processingState": "VALID", "expired": false}}]' > "$D/builds.json"
  cat > "$D/versions.json" <<'J'
[{"id": "ver-136", "type": "appStoreVersions", "attributes": {"versionString": "1.3.6", "appStoreState": "READY_FOR_SALE"}},
 {"id": "ver-135", "type": "appStoreVersions", "attributes": {"versionString": "1.3.5", "appStoreState": "REPLACED_WITH_NEW_VERSION"}}]
J
  echo '[{"id": "l1", "attributes": {"locale": "ko"}}, {"id": "l2", "attributes": {"locale": "en-US"}}, {"id": "l3", "attributes": {"locale": "ja"}}]' > "$D/localizations.json"
  echo '{"track": "internal", "releases": [{"status": "completed", "versionCodes": ["130701"]}]}' > "$D/internal.json"
  echo '{"track": "production", "releases": [{"status": "completed", "versionCodes": ["130607"], "releaseNotes": [{"language": "ko-KR", "text": "x"}]}]}' > "$D/production.json"
  cat > "$D/notes.json" <<'J'
{"version": "1.3.7+130701",
 "ios": {"ko": "버그 수정", "en-US": "Bug fixes", "ja": "不具合修正"},
 "android": {"ko-KR": "버그 수정", "en-US": "Bug fixes"}}
J
}
run() { python3 "$SCRIPT" --version 1.3.7+130701 --notes "$D/notes.json" "$@" 2>&1; }
calls() { cat "$D/calls.log" 2>/dev/null; }
wrote() { grep -Eq 'submit-to-app-store|set-release' "$D/calls.log" 2>/dev/null; }

echo "1. check 는 모든 확인을 하고 스토어에 쓰지 않는다"
fresh
out=$(run --mode check); rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "no store writes" '! wrote'
check "reads both stores" 'grep -q "builds list" <<<"$(calls)" && grep -q "tracks get" <<<"$(calls)"'
check "reports iOS locales" 'grep -q "en-US, ja, ko" <<<"$out"'

echo "2. submit 은 iOS 를 승인 즉시·단계적 출시로 제출하고 Android 를 100% 로 설정한다"
fresh
out=$(run --mode submit); rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "iOS submit flags" 'grep -q "submit-to-app-store build-130701 --platform IOS --version-string 1.3.7 --release-type AFTER_APPROVAL --phased-release" <<<"$(calls)"'
check "iOS whats_new per locale" '[ "$(jq -c "map(.locale)" "$D/submitted_ios.json")" = "[\"en-US\",\"ja\",\"ko\"]" ] && [ "$(jq -r ".[] | select(.locale==\"ko\").whats_new" "$D/submitted_ios.json")" = "버그 수정" ]'
check "Android production 130701 without fraction" 'grep -q "set-release -p io.iconcasting.picnic.app -t production -c 130701" <<<"$(calls)" && ! grep -q -- "--rollout-fraction" <<<"$(calls)"'
check "Android notes" '[ "$(jq -c "map(.language)" "$D/submitted_android.json")" = "[\"en-US\",\"ko-KR\"]" ]'

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

echo "5. iOS 출시 노트 언어가 스토어 언어와 다르면 어느 플랫폼에도 쓰지 않는다"
fresh
jq '.ios |= del(.ja)' "$D/notes.json" > "$D/n" && mv "$D/n" "$D/notes.json"
out=$(run --mode submit); rc=$?
check "missing locale refused" '[ $rc -ne 0 ] && ! wrote && grep -q "없는 스토어 언어: ja" <<<"$out"'
fresh
jq '.ios["de-DE"] = "x"' "$D/notes.json" > "$D/n" && mv "$D/n" "$D/notes.json"
out=$(run --mode submit); rc=$?
check "extra locale refused" '[ $rc -ne 0 ] && ! wrote && grep -q "de-DE" <<<"$out"'

echo "6. 출시 노트 자체의 결함"
fresh
jq '.version = "1.3.7+130702"' "$D/notes.json" > "$D/n" && mv "$D/n" "$D/notes.json"
out=$(run --mode submit); rc=$?
check "version mismatch refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jq '.android["en-US"] = "  "' "$D/notes.json" > "$D/n" && mv "$D/n" "$D/notes.json"
out=$(run --mode submit); rc=$?
check "blank note refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jq --arg t "$(printf 'a%.0s' $(seq 501))" '.android["en-US"] = $t' "$D/notes.json" > "$D/n" && mv "$D/n" "$D/notes.json"
out=$(run --mode submit); rc=$?
check "Android note over 500 chars refused" '[ $rc -ne 0 ] && ! wrote'
fresh
rm "$D/notes.json"
out=$(run --mode submit); rc=$?
check "submit without notes refused" '[ $rc -ne 0 ] && ! wrote'
out=$(run --mode check); rc=$?
check "check without notes passes and prints template" '[ $rc -eq 0 ] && grep -q "\"ja\": \"\"" <<<"$out" && grep -q "\"ko-KR\": \"\"" <<<"$out"'

echo "7. 빌드 출처: 프로덕션 태그가 없거나 스테이징 빌드면 거부한다"
fresh
printf 'aaa\trefs/tags/picnic-v1.3.6+130607-skip-tests\n' > "$D/tags.txt"
out=$(run --mode submit); rc=$?
check "untagged version refused" '[ $rc -ne 0 ] && ! wrote'
fresh
printf 'aaa\trefs/tags/picnic-v1.3.7+130701\nbbb\trefs/tags/picnic-staging-v1.3.7+130701\n' > "$D/tags.txt"
out=$(run --mode submit); rc=$?
check "staging-built version refused" '[ $rc -ne 0 ] && ! wrote && grep -q "스테이징" <<<"$out"'
fresh
printf 'aaa\trefs/tags/picnic-v1.3.7+130701\n' > "$D/tags.txt"
out=$(run --mode check); rc=$?
check "full-test tag accepted" '[ $rc -eq 0 ]'

echo "8. 스토어 상태 결함은 쓰기 전에 모두 잡는다"
fresh
echo '[{"id": "b", "attributes": {"version": "130701", "processingState": "PROCESSING", "expired": false}}]' > "$D/builds.json"
out=$(run --mode submit); rc=$?
check "unprocessed build refused" '[ $rc -ne 0 ] && ! wrote'
fresh
jq '. + [{"id": "ver-137", "attributes": {"versionString": "1.3.7", "appStoreState": "WAITING_FOR_REVIEW"}}]' "$D/versions.json" > "$D/v" && mv "$D/v" "$D/versions.json"
out=$(run --mode submit); rc=$?
check "version already in review refused" '[ $rc -ne 0 ] && ! wrote && grep -q "WAITING_FOR_REVIEW" <<<"$out"'
fresh
echo '[{"id": "v", "attributes": {"versionString": "1.3.6"}}]' > "$D/versions.json"
out=$(run --mode submit); rc=$?
check "unknown version state refused" '[ $rc -ne 0 ] && ! wrote'
fresh
echo '{"track": "internal", "releases": [{"status": "completed", "versionCodes": ["130607"]}]}' > "$D/internal.json"
out=$(run --mode submit); rc=$?
check "missing internal build refused before iOS submit" '[ $rc -ne 0 ] && ! wrote'
fresh
echo '{"track": "production", "releases": [{"status": "completed", "versionCodes": ["130701"]}]}' > "$D/production.json"
out=$(run --mode submit --platforms android); rc=$?
check "already 100% on production refused" '[ $rc -ne 0 ] && ! wrote'
fresh
echo '{"track": "production", "releases": [{"status": "inProgress", "userFraction": 0.1, "versionCodes": ["130701"]}]}' > "$D/production.json"
out=$(run --mode submit --platforms android); rc=$?
check "staged rollout can be raised to 100%" '[ $rc -eq 0 ] && grep -q "set-release" <<<"$(calls)"'

echo "9. 중간 실패는 이미 끝난 플랫폼과 남은 플랫폼을 알려 준다"
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
