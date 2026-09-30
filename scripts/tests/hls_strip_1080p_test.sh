#!/usr/bin/env bash
# scripts/hls_strip_1080p.sh 의 회귀 테스트. 가짜 aws(scripts/tests/fake-aws)로 S3 를 흉내 낸다.
# 실행: scripts/tests/hls_strip_1080p_test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../hls_strip_1080p.sh"
export PATH="$HERE/fake-aws:$PATH"
export AWS_PROFILE=fake HLS_BUCKET=fake-bucket HLS_PREFIX=videos/output

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok   $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

MASTER_5='#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=5128000,RESOLUTION=1920x1080
X-1080p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=3128000,RESOLUTION=1280x720
X-720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=528000,RESOLUTION=426x240
X-240p.m3u8
'
MASTER_4='#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=3128000,RESOLUTION=1280x720
X-720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=528000,RESOLUTION=426x240
X-240p.m3u8
'

fresh() { # fresh <name> → 새 가짜 버킷, 전역 FAKE_S3_DIR/FAKE_S3_LOG 설정
  export FAKE_S3_DIR; FAKE_S3_DIR=$(mktemp -d); export FAKE_S3_LOG="$FAKE_S3_DIR.log"; : > "$FAKE_S3_LOG"
  unset FAKE_S3_LIST_FAIL FAKE_S3_HEAD_ERROR
}
put() { # put <id> <content> [ct] [cc]
  mkdir -p "$FAKE_S3_DIR/videos/output/$1"; printf '%s' "$2" > "$FAKE_S3_DIR/videos/output/$1/master.m3u8"
  printf '%s\n%s\n' "${3:-application/x-mpegURL}" "${4:-public, max-age=60}" > "$FAKE_S3_DIR/videos/output/$1/master.m3u8.meta"
}
obj() { cat "$FAKE_S3_DIR/videos/output/$1/$2"; }
meta() { sed -n "${3}p" "$FAKE_S3_DIR/videos/output/$1/$2.meta"; }
writes() { grep -c "^s3api put-object" "$FAKE_S3_LOG"; }

echo "1. 1080p 두 줄만 빠지고 나머지는 바이트 그대로(종단 개행 포함), 백업·메타 보존"
fresh; put a "$MASTER_5" "video/custom" "max-age=5"
"$SCRIPT" >/dev/null 2>&1; rc=$?
check "exit 0" '[ $rc -eq 0 ]'
check "master == 4-variant bytes" '[ "$(obj a master.m3u8 | od -c)" = "$(printf "%s" "$MASTER_4" | od -c)" ]'
check "backup == original bytes" '[ "$(obj a master.orig.m3u8 | od -c)" = "$(printf "%s" "$MASTER_5" | od -c)" ]'
check "content-type kept" '[ "$(meta a master.m3u8 1)" = "video/custom" ]'
check "cache-control kept" '[ "$(meta a master.m3u8 2)" = "max-age=5" ]'
check "backup meta kept" '[ "$(meta a master.orig.m3u8 2)" = "max-age=5" ]'

echo "2. 종단 개행이 없는 master 도 새 개행을 붙이지 않는다"
fresh; put b "${MASTER_5%$'\n'}"
"$SCRIPT" >/dev/null 2>&1
check "no trailing newline added" '[ "$(obj b master.m3u8 | tail -c1 | od -An -c | tr -d " ")" = "8" ]'

echo "3. 멱등: 두 번째 실행은 아무것도 쓰지 않고 백업을 덮지 않는다"
fresh; put c "$MASTER_5"; "$SCRIPT" >/dev/null 2>&1; n1=$(writes)
"$SCRIPT" >/dev/null 2>&1; n2=$(writes)
check "second run writes nothing" '[ "$n1" = "$n2" ]'

echo "4. 백업이 이미 있으면 절대 덮어쓰지 않는다(조건부 쓰기)"
fresh; put d "$MASTER_5"; mkdir -p "$FAKE_S3_DIR/videos/output/d"; printf 'ORIGINAL' > "$FAKE_S3_DIR/videos/output/d/master.orig.m3u8"; printf 'a\nb\n' > "$FAKE_S3_DIR/videos/output/d/master.orig.m3u8.meta"
"$SCRIPT" >/dev/null 2>&1
check "existing backup untouched" '[ "$(obj d master.orig.m3u8)" = "ORIGINAL" ]'
check "master still stripped" '[ "$(obj d master.m3u8)" = "$(printf "%s" "$MASTER_4")" ]'

echo "5. head-object 가 404 가 아닌 오류면 failed 로 세고 아무것도 쓰지 않는다"
fresh; put e "$MASTER_5"; export FAKE_S3_HEAD_ERROR=403
out=$("$SCRIPT" 2>&1); rc=$?
check "non-zero exit" '[ $rc -ne 0 ]'
check "no writes" '[ "$(writes)" = 0 ]'
check "reported as failed" 'grep -q "failed=1" <<<"$out"'
unset FAKE_S3_HEAD_ERROR

echo "6. --only 뒤에 ID 가 없으면 인자 오류로 끝나고 아무것도 하지 않는다"
fresh; put f "$MASTER_5"
"$SCRIPT" --only >/dev/null 2>&1; rc=$?
check "exit 64" '[ $rc -eq 64 ]'
check "no writes" '[ "$(writes)" = 0 ]'

echo "7. 목록 조회 실패는 성공으로 보이지 않는다"
fresh; export FAKE_S3_LIST_FAIL=1
out=$("$SCRIPT" 2>&1); rc=$?
check "non-zero exit" '[ $rc -ne 0 ]'
check "does not print changed=0 skipped=0 failed=0 as success" '! grep -q "changed=0 skipped=0 failed=0" <<<"$out"'
unset FAKE_S3_LIST_FAIL

echo "8. 1080p 가 I-FRAME 줄에만 있으면 건너뛴다"
fresh; put g '#EXTM3U
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=100,RESOLUTION=1920x1080,URI="if.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=3128000,RESOLUTION=1280x720
X-720p.m3u8
'
"$SCRIPT" >/dev/null 2>&1
check "no writes" '[ "$(writes)" = 0 ]'

echo "9. 제거 후 변형이 남지 않으면 거부한다"
fresh; put h '#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=5128000,RESOLUTION=1920x1080
X-1080p.m3u8
'
"$SCRIPT" >/dev/null 2>&1; rc=$?
check "non-zero exit" '[ $rc -ne 0 ]'
check "no writes" '[ "$(writes)" = 0 ]'

echo "10. --restore 는 백업의 메타로 되돌리고, 백업 없는 수정본은 failed 다"
fresh; put i "$MASTER_5" "video/custom" "max-age=5"; "$SCRIPT" >/dev/null 2>&1
printf 'text/plain\nmax-age=9\n' > "$FAKE_S3_DIR/videos/output/i/master.m3u8.meta"   # 현재 master 메타를 일부러 다르게
"$SCRIPT" --restore >/dev/null 2>&1; rc=$?
check "restore exit 0" '[ $rc -eq 0 ]'
check "restored bytes" '[ "$(obj i master.m3u8 | od -c)" = "$(printf "%s" "$MASTER_5" | od -c)" ]'
check "restored content-type from backup" '[ "$(meta i master.m3u8 1)" = "video/custom" ]'
check "restored cache-control from backup" '[ "$(meta i master.m3u8 2)" = "max-age=5" ]'
fresh; put j "$MASTER_4"   # 1080p 가 없는(수정된) master 인데 백업이 없다
out=$("$SCRIPT" --restore 2>&1); rc=$?
check "modified master without backup is failed" '[ $rc -ne 0 ] && grep -q "failed=1" <<<"$out"'
fresh; put k "$MASTER_5"   # 손대지 않은 master 는 백업이 없어도 skip
out=$("$SCRIPT" --restore 2>&1); rc=$?
check "untouched master without backup is skipped" '[ $rc -eq 0 ] && grep -q "skipped=1" <<<"$out"'

echo "11. --dry-run 은 쓰지 않는다"
fresh; put l "$MASTER_5"
"$SCRIPT" --dry-run >/dev/null 2>&1
check "no writes" '[ "$(writes)" = 0 ]'

echo; echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
