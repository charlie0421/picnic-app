#!/usr/bin/env bash
# scripts/release_picnic.sh 의 버전 가드 회귀 테스트. 임시 bare 저장소를 원격으로 써서 태그 상태를 흉내 낸다.
# 실행: scripts/tests/release_picnic_test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/.."

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok   $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
# 사용자 git 설정(서명·훅·기본 브랜치)이 결과를 바꾸지 않게 한다.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
REAL_GIT=$(command -v git); export REAL_GIT   # fake-git 이 넘겨줄 진짜 git

fresh() { # fresh <main 버전> [원격 태그...] → 새 원격과 작업 사본, 전역 W 설정. 태그는 main 직전 커밋에 붙는다
  local d t ver="$1"; shift
  d=$(mktemp -d "$ROOT/r.XXXX")
  git init -q --bare -b main "$d/origin.git"
  git init -q -b main "$d/w"
  W="$d/w"
  mkdir -p "$W/picnic_app" "$W/scripts"
  cp "$SRC/release_picnic.sh" "$SRC/release_test_mode.sh" "$W/scripts/"
  printf 'name: picnic_app\nversion: 0.0.0+000001\n' > "$W/picnic_app/pubspec.yaml"
  git -C "$W" add -A && git -C "$W" commit -qm old
  # 실제 릴리스 태그처럼 annotated 로 만든다(ls-remote 에 ^{} 줄이 함께 나온다).
  for t in "$@"; do git -C "$W" tag -a "$t" -m "$t"; done
  printf 'name: picnic_app\nversion: %s\n' "$ver" > "$W/picnic_app/pubspec.yaml"
  git -C "$W" commit -qam main
  git -C "$W" remote add origin "$d/origin.git"
  git -C "$W" push -q origin main --tags
}
run() { (cd "$W" && bash scripts/release_picnic.sh "$@") 2>&1; }
pubspec() { sed -n 's/^version:[[:space:]]*//p' "$W/picnic_app/pubspec.yaml"; }

echo "1. 태그된 main 에서 next 는 다음 버전을 계산한다"
fresh 1.3.5+130504 picnic-v1.3.5+130504-skip-tests
out=$(run next patch); rc=$?
check "next patch → 1.3.6+130601" '[ $rc -eq 0 ] && [ "$out" = "1.3.6+130601" ]'
out=$(run next build); rc=$?
check "next build → 1.3.5+130505" '[ $rc -eq 0 ] && [ "$out" = "1.3.5+130505" ]'

echo "2. 태그되지 않은 main 에서 next 는 멈추고 tag 로 안내한다"
fresh 1.3.6+130602 picnic-v1.3.6+130601
out=$(run next patch); rc=$?
check "next patch refuses" '[ $rc -ne 0 ]'
check "message points to tag" 'grep -q "아직 태그되지 않았다" <<<"$out" && grep -q "tag" <<<"$out"'
out=$(run next build); rc=$?
check "next build refuses" '[ $rc -ne 0 ]'

echo "3. 스테이징 태그로 나간 번호도 태그된 것으로 본다"
fresh 1.3.6+130602 picnic-v1.3.6+130601 picnic-staging-v1.3.6+130602
out=$(run next build); rc=$?
check "next build → 1.3.6+130603" '[ $rc -eq 0 ] && [ "$out" = "1.3.6+130603" ]'

echo "3b. 스테이징 태그가 더 큰 순번을 썼으면 그 다음 순번을 낸다"
fresh 1.3.6+130601 picnic-v1.3.6+130601 picnic-staging-v1.3.6+130603
out=$(run next build); rc=$?
check "next build → 1.3.6+130604" '[ $rc -eq 0 ] && [ "$out" = "1.3.6+130604" ]'

echo "4. 태그되지 않은 main 은 원격 태그 최댓값보다 크면 더 낮은 번호로 바로잡을 수 있다"
fresh 1.3.7+130701 picnic-v1.3.6+130601
out=$(run bump 1.3.6+130602); rc=$?
check "bump 1.3.6+130602 accepted" '[ $rc -eq 0 ]'
check "pubspec → 1.3.6+130602" '[ "$(pubspec)" = "1.3.6+130602" ]'

echo "5. 원격 태그(스테이징 포함)의 최댓값 이하로는 범프하지 않는다"
fresh 1.3.7+130701 picnic-v1.3.6+130601 picnic-staging-v1.3.6+130602
out=$(run bump 1.3.6+130602); rc=$?
check "number taken by staging refused" '[ $rc -ne 0 ]'
out=$(run bump 1.3.6+130601); rc=$?
check "number taken by production refused" '[ $rc -ne 0 ]'
check "pubspec unchanged" '[ "$(pubspec)" = "1.3.7+130701" ]'

echo "6. 태그된 main 은 그보다 큰 번호만 받는다"
fresh 1.3.5+130504 picnic-v1.3.5+130504-skip-tests
out=$(run bump 1.3.5+130504); rc=$?
check "same number refused" '[ $rc -ne 0 ] && [ "$(pubspec)" = "1.3.5+130504" ]'
out=$(run bump 1.3.6+130601); rc=$?
check "next patch number accepted" '[ $rc -eq 0 ] && [ "$(pubspec)" = "1.3.6+130601" ]'

echo "7. main 과 같은 버전으로는 범프하지 않는다(태그되지 않았어도)"
fresh 1.3.6+130602 picnic-v1.3.6+130601
out=$(run bump 1.3.6+130602); rc=$?
check "same untagged version refused" '[ $rc -ne 0 ]'

echo "8. 원격을 읽지 못하면 범프하지 않는다"
fresh 1.3.7+130701 picnic-v1.3.6+130601
git -C "$W" remote set-url origin "$ROOT/missing.git"
out=$(run bump 1.3.6+130602); rc=$?
check "unreachable origin refused" '[ $rc -ne 0 ] && [ "$(pubspec)" = "1.3.7+130701" ]'
out=$(run next patch); rc=$?
check "next with unreachable origin refused" '[ $rc -ne 0 ]'

echo "9. tag dry-run 은 태그되지 않은 main 버전을 그대로 쓴다"
fresh 1.3.6+130602 picnic-v1.3.6+130601
out=$(run tag); rc=$?
check "dry-run passes" '[ $rc -eq 0 ]'
check "tag is picnic-v1.3.6+130602" 'grep -q "^tag:     picnic-v1.3.6+130602$" <<<"$out"'

echo "10. 스테이징 태그가 이미 쓴 버전은 운영 태그로 다시 내지 않는다"
fresh 1.3.6+130602 picnic-v1.3.6+130601 picnic-staging-v1.3.6+130602
out=$(run tag); rc=$?
check "dry-run refuses" '[ $rc -ne 0 ] && grep -q "이미 태그됐다" <<<"$out"'

echo "11. main 빌드 번호가 원격 태그 최댓값 이하면 태그하지 않는다"
fresh 1.3.6+130602 picnic-v1.3.6+130601 picnic-staging-v1.3.6+130605
out=$(run tag); rc=$?
check "dry-run refuses" '[ $rc -ne 0 ] && grep -q "최댓값(130605)" <<<"$out"'

echo "12. 원격 호출이 하나라도 실패하면 next·bump·tag 는 통과하지 않는다(fake-git 으로 하나씩 실패시킨다)"
fault_case() { # fault_case <주입 env> <main 버전> <태그> <명령...> — 주입했으면 실패, 주입하지 않았으면 통과해야 한다
  local inj=$1 ver=$2 tag=$3 st; shift 3
  fresh "$ver" "$tag"; st=$(mktemp -d "$ROOT/g.XXXX")
  out=$(cd "$W" && env PATH="$HERE/fake-git:$PATH" FAKE_GIT_STATE="$st" "$inj" bash scripts/release_picnic.sh "$@" 2>&1); rc=$?
  if [ -e "$st/injected" ]; then check "$* with $inj stops" '[ $rc -ne 0 ]'
  else check "$* with $inj (not reached) passes" '[ $rc -eq 0 ]'; fi
}
for inj in FAKE_GIT_FAIL_FETCH=1 FAKE_GIT_FAIL_LS_REMOTE_AT=1 FAKE_GIT_FAIL_LS_REMOTE_AT=2 FAKE_GIT_FAIL_LS_REMOTE_AT=3; do
  fault_case "$inj" 1.3.6+130601 picnic-v1.3.6+130601 next patch
  fault_case "$inj" 1.3.7+130701 picnic-v1.3.6+130601 bump 1.3.6+130602
  fault_case "$inj" 1.3.6+130602 picnic-v1.3.6+130601 tag
done

echo "13. Codemagic 설정이 없으면 GitHub 체크를 Codemagic 과 같은 열로 보여 준다(fake-gh)"
fresh 1.3.6+130601 picnic-v1.3.6+130601
cat > "$ROOT/checks.json" <<'JSON'
{"check_runs":[
 {"name":"Picnic App - iOS","status":"completed","conclusion":"success","started_at":"2026-10-14T07:00:00Z","completed_at":"2026-10-14T07:20:00Z","details_url":"https://example.com/1"},
 {"name":"Picnic App - iOS","status":"completed","conclusion":"failure","started_at":"2026-10-14T08:02:47Z","completed_at":"2026-10-14T08:07:46Z","details_url":"https://example.com/2"},
 {"name":"Picnic App - Android","status":"in_progress","conclusion":null,"started_at":"2026-10-14T08:07:54Z","completed_at":null,"details_url":"https://example.com/3"},
 {"name":"Picnic App - iOS Patch (Shorebird)","status":"completed","conclusion":"success","started_at":"2026-10-14T06:00:00Z","completed_at":"2026-10-14T06:10:00Z","details_url":"https://example.com/4"},
 {"name":"Supabase Preview","status":"completed","conclusion":"skipped","started_at":"2026-10-14T08:00:00Z","completed_at":"2026-10-14T08:00:01Z","details_url":"https://example.com/5"}
]}
JSON
home=$(mktemp -d "$ROOT/h.XXXX")   # codemagic.env 가 없는 HOME
out=$(cd "$W" && env HOME="$home" PATH="$HERE/fake-gh:$PATH" FAKE_GH_JSON="$ROOT/checks.json" bash scripts/release_picnic.sh status picnic-v1.3.6+130601 2>&1); rc=$?
latest() { awk -F'\t' -v w="$1" '$1 == w { print $2; exit }' <<<"$out"; }
check "exit 0" '[ $rc -eq 0 ]'
check "latest iOS row is failed" '[ "$(latest picnic-app-ios)" = failed ]'
check "running Android row is in_progress" '[ "$(latest picnic-app-android)" = in_progress ]'
check "patch workflow keeps its name" '[ "$(latest "Picnic App - iOS Patch (Shorebird)")" = finished ]'
check "other checks dropped" '! grep -q "Supabase" <<<"$out"'

echo "14. promote 는 태그 커밋의 pubspec 으로 프로덕션 빌드를 확인한 뒤 Codemagic picnic-app-promote 를 시작한다(fake-curl)"
cmhome=$(mktemp -d "$ROOT/h.XXXX"); mkdir -p "$cmhome/.config/picnic"
printf 'CODEMAGIC_API_TOKEN=tok\nCODEMAGIC_APP_ID=app1\n' > "$cmhome/.config/picnic/codemagic.env"
promote() { # promote <args...> → 전역 out, rc. 요청 기록은 $CM/requests.log
  CM=$(mktemp -d "$ROOT/cm.XXXX")
  out=$(cd "$W" && env HOME="$cmhome" PATH="$HERE/fake-curl:$PATH" FAKE_CM_DIR="$CM" PROMOTE_POLL_SECONDS=0 \
        ${FAKE_CM_STATUS:+FAKE_CM_STATUS=$FAKE_CM_STATUS} ${FAKE_CM_POST_FAIL:+FAKE_CM_POST_FAIL=1} \
        bash scripts/release_picnic.sh promote "$@" 2>&1); rc=$?
}
started() { [ -s "$CM/body.json" ]; }
fresh 1.3.7+130701 picnic-v1.3.7+130701-skip-tests   # fresh 는 태그를 main 직전 커밋(pubspec 0.0.0)에 붙인다
promote 1.3.7+130701
check "production tag whose pubspec differs refused" '[ $rc -ne 0 ] && ! started && grep -q "pubspec 버전(0.0.0+000001)" <<<"$out"'
tagged() { # tagged <main 버전> <태그...> → 태그를 main 커밋(그 pubspec)에 붙인 원격
  fresh "$1"; local v="$1"; shift
  for t in "$@"; do git -C "$W" tag -a "$t" -m "$t"; done
  git -C "$W" push -q origin --tags
}
tagged 1.3.7+130701 picnic-v1.3.7+130701-skip-tests
promote 1.3.7+130701
check "check starts" '[ $rc -eq 0 ] && started'
check "body: workflow, branch, check mode" '[ "$(jq -r "[.workflowId, .branch, .environment.variables.PROMOTE_MODE, .environment.variables.PROMOTE_VERSION, .environment.variables.PROMOTE_PLATFORMS] | join(\" \")" "$CM/body.json")" = "picnic-app-promote main check 1.3.7+130701 both" ]'
check "no empty fraction variable is sent" '[ "$(jq -c ".environment.variables | has(\"PROMOTE_ANDROID_FRACTION\")" "$CM/body.json")" = false ]'
check "shows promote log without colors" 'grep -qx "PROMOTE LOG" <<<"$out"'
check "token not printed" '! grep -q tok <<<"$out"'
check "build start is not retried, polling is" 'grep -q "^POST .* retry=no$" "$CM/requests.log" && grep -q "^GET .*/builds/b1 retry=yes$" "$CM/requests.log"'
promote 1.3.7+130701 --submit --platform android --fraction 0.2
check "submit starts" '[ $rc -eq 0 ] && started'
check "body: submit, android, fraction" '[ "$(jq -r "[.environment.variables.PROMOTE_MODE, .environment.variables.PROMOTE_PLATFORMS, .environment.variables.PROMOTE_ANDROID_FRACTION] | join(\" \")" "$CM/body.json")" = "submit android 0.2" ]'
FAKE_CM_POST_FAIL=1 promote 1.3.7+130701 --submit
check "failed start: one POST, asks to check Codemagic before rerunning" '[ $rc -ne 0 ] && [ "$(grep -c "^POST" "$CM/requests.log")" = 1 ] && grep -q "확인한다" <<<"$out"'
promote 1.3.8+130801
check "untagged version refused" '[ $rc -ne 0 ] && ! started'
tagged 1.3.7+130701 picnic-v1.3.7+130701 picnic-staging-v1.3.7
promote 1.3.7+130701
check "staging tag without build number in its name refused" '[ $rc -ne 0 ] && ! started && grep -q "picnic-staging-v1.3.7(1.3.7+130701)" <<<"$out"'
tagged 1.3.7+130701 picnic-staging-v1.3.7+130701
promote 1.3.7+130701
check "staging-built version refused" '[ $rc -ne 0 ] && ! started && grep -q "스테이징" <<<"$out"'
tagged 1.3.7+130701 picnic-v1.3.7+130701
promote 1.3.7+130701 --platform web
check "bad platform refused" '[ $rc -ne 0 ] && ! started'
promote 1.3.7+130701 --ios-release-now
check "--ios-release-now without --submit is a check on iOS" '[ $rc -eq 0 ] && [ "$(jq -r "[.environment.variables.PROMOTE_MODE, .environment.variables.PROMOTE_PLATFORMS] | join(\" \")" "$CM/body.json")" = "ios-release-now-check ios" ]'
promote 1.3.7+130701 --ios-release-now --submit
check "--ios-release-now --submit writes" '[ $rc -eq 0 ] && [ "$(jq -r .environment.variables.PROMOTE_MODE "$CM/body.json")" = ios-release-now ]'
promote 1.3.7+130701 --ios-release-now --fraction 0.1
check "--ios-release-now with --fraction refused" '[ $rc -ne 0 ] && ! started'
FAKE_CM_STATUS=failed promote 1.3.7+130701
check "failed build exits non-zero and still shows log" '[ $rc -ne 0 ] && grep -qx "PROMOTE LOG" <<<"$out"'

echo "15. codemagic.yaml 에 빈 문자열 변수가 없다(Codemagic 은 파일 전체를 무효로 본다)"
empty=$(python3 -c '
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
for w, c in d["workflows"].items():
    for k, v in ((c.get("environment") or {}).get("vars") or {}).items():
        if v in ("", None): print(w, k)
' "$SRC/../codemagic.yaml" 2>&1); rc=$?
check "no empty vars" '[ $rc -eq 0 ] && [ -z "$empty" ]'

echo; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
