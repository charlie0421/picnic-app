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

echo; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
