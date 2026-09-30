#!/usr/bin/env bash
# 자체숏폼 광고 HLS master.m3u8 에서 1080p 변형을 뺀다 (720p 상한).
#
# 왜: 19초 광고의 1080p(5.1Mbps) 첫 세그먼트가 2.6MB 라 1Mbps 이하 망에서
# 앱의 초기화 타임아웃 안에 못 들어와 "광고 로드 실패"가 난다(QnA 395).
# 앱은 서버가 준 URL 을 항상 <id>/master.m3u8 로 치환하므로, 설치된 앱에
# 효과가 있는 유일한 지렛대는 master.m3u8 의 내용이다. 트랜스코더 템플릿을
# 고칠 권한이 없을 때 새 영상이 올라올 때마다 이 스크립트를 한 번 돌린다.
#
# 동작:
#   - <prefix>/<id>/master.m3u8 마다 같은 폴더에 master.orig.m3u8 백업을 만든다.
#     백업은 If-None-Match:* 조건부 쓰기라 이미 있으면 절대 덮어쓰지 않는다.
#   - RESOLUTION=1920x1080 인 #EXT-X-STREAM-INF 줄과 바로 다음 URI 줄만 뺀다.
#     그 외 바이트(종단 개행 포함)는 그대로다. 파일 단위로 변환·업로드한다.
#   - Content-Type 과 Cache-Control 은 원본 객체 값을 그대로 다시 쓴다.
#   - #EXT-X-STREAM-INF 에 1080p 가 없는 master 는 건너뛴다(멱등).
#   - 세그먼트·변형 플레이리스트는 건드리지 않는다. CloudFront 캐시 60초.
#   - 조회 오류(404 아닌 head-object 실패, 목록 실패)는 failed 로 세고 쓰지 않는다.
#
# 사용:
#   scripts/hls_strip_1080p.sh --dry-run          # 바꿀 내용만 출력
#   scripts/hls_strip_1080p.sh                    # 실제 적용
#   scripts/hls_strip_1080p.sh --restore          # master.orig.m3u8 로 되돌림
#   scripts/hls_strip_1080p.sh --only <id> ...    # 특정 출력만 (ID 없으면 오류)
#
# 환경: AWS_PROFILE(기본 picnic), HLS_BUCKET(기본 picnic-prod-cdn),
#       HLS_PREFIX(기본 picnic/videos/output)
# 테스트: scripts/tests/hls_strip_1080p_test.sh (가짜 aws 로 S3 를 흉내 낸다)
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-picnic}"
BUCKET="${HLS_BUCKET:-picnic-prod-cdn}"
PREFIX="${HLS_PREFIX:-picnic/videos/output}"
DRY_RUN=false
RESTORE=false
ONLY=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --restore) RESTORE=true ;;
    --only)
      shift
      while [ $# -gt 0 ] && [[ "$1" != --* ]]; do ONLY+=("$1"); shift; done
      [ ${#ONLY[@]} -gt 0 ] || { echo "--only 뒤에 ID 가 하나 이상 필요하다" >&2; exit 64; }
      continue ;;
    -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
  shift
done

command -v aws >/dev/null || { echo "aws CLI 필요" >&2; exit 69; }
command -v jq >/dev/null || { echo "jq 필요" >&2; exit 69; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# ---- 순수 변환 -------------------------------------------------------------
# 1080p STREAM-INF 줄과 그 다음 URI 줄을 제거한다. 종단 개행은 입력을 따른다.
strip_1080p_file() { # <in> <out>
  awk '
    skip { skip = 0; next }
    /^#EXT-X-STREAM-INF:/ && /RESOLUTION=1920x1080/ { skip = 1; next }
    { print }
  ' "$1" > "$2"
  # awk 의 print 는 마지막 줄에도 개행을 붙인다. 원본이 종단 개행 없이 끝났으면
  # 출력에서도 마지막 개행 하나만 뗀다(그 밖의 바이트는 그대로).
  if [ -s "$1" ] && [ "$(tail -c1 "$1" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then
    perl -pi -e 'chomp if eof' "$2"
  fi
}
# #EXT-X-STREAM-INF 줄에 1080p 가 있는가 (I-FRAME 줄은 대상이 아니다).
has_1080p_variant() { grep -E '^#EXT-X-STREAM-INF:' "$1" | grep -q 'RESOLUTION=1920x1080'; }
count_variants() { grep -c '^#EXT-X-STREAM-INF:' "$1" || true; }

# ---- S3 래퍼 (모두 s3api, 파일 단위) -----------------------------------------
# head: 0=있음(메타를 stdout JSON), 44=없음(404), 1=그 밖의 오류
s3_head() { # <key>
  local out err rc
  out=$(aws s3api head-object --bucket "$BUCKET" --key "$1" 2>"$WORK/err") && { printf '%s' "$out"; return 0; }
  err=$(cat "$WORK/err")
  grep -qE '\(404\)|Not Found|NoSuchKey' <<<"$err" && return 44
  echo "  head-object 실패($1): $(head -1 <<<"$err")" >&2; return 1
}
s3_get() { aws s3api get-object --bucket "$BUCKET" --key "$1" "$2" >/dev/null; }
s3_put() { # <key> <file> <content-type> <cache-control> [--if-none-match]
  local extra=(); [ "${5:-}" = "--if-none-match" ] && extra=(--if-none-match '*')
  aws s3api put-object --bucket "$BUCKET" --key "$1" --body "$2" \
    --content-type "$3" --cache-control "$4" "${extra[@]}" >/dev/null
}
meta_ct() { jq -r '.ContentType // "application/x-mpegURL"' <<<"$1"; }
meta_cc() { jq -r '.CacheControl // "public, max-age=60"' <<<"$1"; }

list_ids() {
  if [ ${#ONLY[@]} -gt 0 ]; then printf '%s\n' "${ONLY[@]}"; return 0; fi
  local raw
  raw=$(aws s3api list-objects-v2 --bucket "$BUCKET" --prefix "$PREFIX/" --delimiter / \
    --query 'CommonPrefixes[].Prefix' --output text) || return 1
  tr '\t' '\n' <<<"$raw" | sed -E "s#^$PREFIX/##; s#/\$##" | grep -v '^None$' | grep -v '^$' || true
}

changed=0; skipped=0; failed=0

do_restore() { # <id>
  local id=$1 key="$PREFIX/$1/master.m3u8" orig="$PREFIX/$1/master.orig.m3u8" bmeta rc
  bmeta=$(s3_head "$orig") && rc=0 || rc=$?   # set -e 아래서 치환 실패로 죽지 않게
  if [ $rc -eq 1 ]; then failed=$((failed+1)); return; fi
  if [ $rc -eq 44 ]; then
    # 백업이 없다. master 의 상태를 확인하지 못하면 skipped 로 넘기지 않는다.
    local mrc
    s3_head "$key" >/dev/null && mrc=0 || mrc=$?
    if [ $mrc -eq 44 ]; then echo "[$id] 백업도 master 도 없음, 건너뜀"; skipped=$((skipped+1)); return; fi
    if [ $mrc -ne 0 ] || ! s3_get "$key" "$WORK/cur"; then
      echo "[$id] 백업이 없고 master 상태도 확인 못 함 — 실패로 보고" >&2; failed=$((failed+1)); return
    fi
    # 백업이 없는데 master 에 1080p 가 없으면 "수정됐는데 백업을 잃은" 상태다 — 실패로 보고.
    if ! has_1080p_variant "$WORK/cur"; then
      echo "[$id] 백업이 없는데 master 는 이미 수정본이다 — 복원 불가" >&2; failed=$((failed+1)); return
    fi
    echo "[$id] 백업 없음(손대지 않은 master), 건너뜀"; skipped=$((skipped+1)); return
  fi
  if $DRY_RUN; then echo "[$id] (dry-run) $orig → $key"; changed=$((changed+1)); return; fi
  s3_get "$orig" "$WORK/orig"
  s3_put "$key" "$WORK/orig" "$(meta_ct "$bmeta")" "$(meta_cc "$bmeta")"
  echo "[$id] 복원"; changed=$((changed+1))
}

do_strip() { # <id>
  local id=$1 key="$PREFIX/$1/master.m3u8" orig="$PREFIX/$1/master.orig.m3u8" meta rc ct cc before after
  meta=$(s3_head "$key") && rc=0 || rc=$?
  if [ $rc -eq 44 ]; then echo "[$id] master.m3u8 없음, 건너뜀"; skipped=$((skipped+1)); return; fi
  if [ $rc -ne 0 ]; then failed=$((failed+1)); return; fi
  ct=$(meta_ct "$meta"); cc=$(meta_cc "$meta")

  s3_get "$key" "$WORK/cur"
  if ! has_1080p_variant "$WORK/cur"; then echo "[$id] 1080p 없음, 건너뜀"; skipped=$((skipped+1)); return; fi
  strip_1080p_file "$WORK/cur" "$WORK/next"
  before=$(count_variants "$WORK/cur"); after=$(count_variants "$WORK/next")
  if [ "$after" -lt 1 ]; then echo "[$id] 제거 후 변형이 남지 않아 중단" >&2; failed=$((failed+1)); return; fi

  if $DRY_RUN; then
    echo "[$id] (dry-run) $before → $after 변형, content-type=$ct, cache-control=$cc"
    diff "$WORK/cur" "$WORK/next" | sed 's/^/    /' || true
    changed=$((changed+1)); return
  fi

  # 백업: 조건부 쓰기. 이미 있으면 PreconditionFailed 가 나고 그대로 둔다.
  # 그 밖의 실패(권한 등)는 master 를 건드리지 않고 failed 로 끝낸다.
  if ! s3_put "$orig" "$WORK/cur" "$ct" "$cc" --if-none-match 2>"$WORK/err"; then
    if ! grep -q 'PreconditionFailed' "$WORK/err"; then
      echo "[$id] 백업 실패: $(head -1 "$WORK/err")" >&2; failed=$((failed+1)); return
    fi
  fi
  s3_put "$key" "$WORK/next" "$ct" "$cc"
  echo "[$id] 적용 (백업: $orig)"; changed=$((changed+1))
}

ids=$(list_ids) || { echo "출력 목록 조회 실패 — 아무것도 하지 않음" >&2; exit 1; }
while IFS= read -r id; do
  [ -n "$id" ] || continue
  if $RESTORE; then do_restore "$id"; else do_strip "$id"; fi
done <<<"$ids"

echo "changed=$changed skipped=$skipped failed=$failed"
[ "$failed" -eq 0 ]
