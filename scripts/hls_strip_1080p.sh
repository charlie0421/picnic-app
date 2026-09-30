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
#   - <prefix>/<id>/master.m3u8 마다 같은 폴더에 master.orig.m3u8 백업을 만든다
#     (이미 있으면 덮어쓰지 않는다 — 최초 원본을 보존).
#   - RESOLUTION=1920x1080 인 #EXT-X-STREAM-INF 줄과 바로 다음 URI 줄을 뺀다.
#   - Content-Type 과 Cache-Control 은 원본 객체와 동일하게 다시 쓴다.
#   - 1080p 줄이 없는 master 는 건너뛴다(멱등).
#   - 세그먼트·변형 플레이리스트는 건드리지 않는다. CloudFront 캐시 60초.
#
# 사용:
#   scripts/hls_strip_1080p.sh --dry-run          # 바꿀 내용만 출력
#   scripts/hls_strip_1080p.sh                    # 실제 적용
#   scripts/hls_strip_1080p.sh --restore          # master.orig.m3u8 로 되돌림
#   scripts/hls_strip_1080p.sh --only <id> ...    # 특정 출력만
#
# 환경: AWS_PROFILE(기본 picnic), HLS_BUCKET(기본 picnic-prod-cdn),
#       HLS_PREFIX(기본 picnic/videos/output)
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
    --only) shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do ONLY+=("$1"); shift; done; continue ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
  shift
done

command -v aws >/dev/null || { echo "aws CLI 필요" >&2; exit 69; }
command -v jq >/dev/null || { echo "jq 필요" >&2; exit 69; }

# 1080p STREAM-INF 줄과 그 다음 URI 줄을 제거한다. 그 외는 그대로.
strip_1080p() {
  awk '
    skip { skip = 0; next }
    /^#EXT-X-STREAM-INF:/ && /RESOLUTION=1920x1080/ { skip = 1; next }
    { print }
  '
}

list_ids() {
  if [ ${#ONLY[@]} -gt 0 ]; then printf '%s\n' "${ONLY[@]}"; return; fi
  aws s3api list-objects-v2 --bucket "$BUCKET" --prefix "$PREFIX/" --delimiter / \
    --query 'CommonPrefixes[].Prefix' --output text | tr '\t' '\n' \
    | sed -E "s#^$PREFIX/##; s#/\$##"
}

changed=0; skipped=0; failed=0
for id in $(list_ids); do
  key="$PREFIX/$id/master.m3u8"
  orig="$PREFIX/$id/master.orig.m3u8"

  if $RESTORE; then
    if ! aws s3api head-object --bucket "$BUCKET" --key "$orig" >/dev/null 2>&1; then
      echo "[$id] 백업 없음, 건너뜀"; skipped=$((skipped+1)); continue
    fi
    if $DRY_RUN; then echo "[$id] (dry-run) $orig → $key"; changed=$((changed+1)); continue; fi
    aws s3 cp "s3://$BUCKET/$orig" "s3://$BUCKET/$key" \
      --content-type application/x-mpegURL --cache-control 'public, max-age=60' \
      --metadata-directive REPLACE --only-show-errors
    echo "[$id] 복원"; changed=$((changed+1)); continue
  fi

  meta=$(aws s3api head-object --bucket "$BUCKET" --key "$key" 2>/dev/null) || {
    echo "[$id] master.m3u8 없음, 건너뜀"; skipped=$((skipped+1)); continue; }
  ctype=$(jq -r '.ContentType // "application/x-mpegURL"' <<<"$meta")
  ccontrol=$(jq -r '.CacheControl // "public, max-age=60"' <<<"$meta")

  current=$(aws s3 cp "s3://$BUCKET/$key" - 2>/dev/null)
  if ! grep -q 'RESOLUTION=1920x1080' <<<"$current"; then
    echo "[$id] 1080p 없음, 건너뜀"; skipped=$((skipped+1)); continue
  fi
  next=$(strip_1080p <<<"$current")
  if ! grep -q '^#EXT-X-STREAM-INF:' <<<"$next"; then
    echo "[$id] 제거 후 변형이 남지 않아 중단" >&2; failed=$((failed+1)); continue
  fi

  if $DRY_RUN; then
    echo "[$id] (dry-run) $(grep -c '^#EXT-X-STREAM-INF:' <<<"$current") → $(grep -c '^#EXT-X-STREAM-INF:' <<<"$next") 변형, content-type=$ctype, cache-control=$ccontrol"
    diff <(echo "$current") <(echo "$next") | sed 's/^/    /' || true
    changed=$((changed+1)); continue
  fi

  # 백업은 최초 1회만. 이미 있으면 그대로 둔다.
  if ! aws s3api head-object --bucket "$BUCKET" --key "$orig" >/dev/null 2>&1; then
    aws s3 cp "s3://$BUCKET/$key" "s3://$BUCKET/$orig" \
      --content-type "$ctype" --cache-control "$ccontrol" \
      --metadata-directive REPLACE --only-show-errors
  fi
  printf '%s\n' "$next" | aws s3 cp - "s3://$BUCKET/$key" \
    --content-type "$ctype" --cache-control "$ccontrol" --only-show-errors
  echo "[$id] 적용 (백업: $orig)"; changed=$((changed+1))
done

echo "changed=$changed skipped=$skipped failed=$failed"
[ "$failed" -eq 0 ]
