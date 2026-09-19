#!/usr/bin/env bash

# picnic_app 신규 바이너리 릴리스의 기계적 단계(버전 계산·범프·태그 사전검증)를 맡는다.
# 절차와 승인 게이트는 .claude/skills/releasing-picnic-app/SKILL.md 가 소유한다.
#
#   next <patch|build>               origin/main 기준 다음 전체 버전을 출력 (minor·major 는 bump 에 직접 지정)
#   bump <M.m.P+MmPPBB>              picnic_app/pubspec.yaml 의 version 을 교체
#   tag [--skip-tests] [--push]      origin/main 에 붙일 태그를 검증. --push 가 있어야 실제 생성·푸시
#   status <tag>                     태그 커밋의 Codemagic 체크 상태

set -euo pipefail

PUBSPEC=picnic_app/pubspec.yaml
cd "$(git rev-parse --show-toplevel)"

die() { echo "release_picnic: $*" >&2; exit 1; }

# "1.3.5+130501" → M m P BB (공백 구분). 형식·MmPPBB 일관성이 어긋나면 실패한다.
parse() {
  local v="$1" M m P build
  [[ "$v" =~ ^([0-9])\.([0-9])\.([0-9]{1,2})\+([0-9]{6})$ ]] || die "버전 형식 오류: '$v' (M.m.P+MmPPBB)"
  M=${BASH_REMATCH[1]} m=${BASH_REMATCH[2]} P=$((10#${BASH_REMATCH[3]})) build=${BASH_REMATCH[4]}
  local prefix
  prefix=$(printf '%d%d%02d' "$M" "$m" "$P")
  [ "${build:0:4}" = "$prefix" ] || die "빌드 번호 $build 가 $M.$m.$P 의 접두 $prefix 와 다르다"
  local BB=$((10#${build:4:2}))
  [ "$BB" -ge 1 ] || die "빌드 순번은 01 부터다: $build"
  echo "$M $m $P $BB"
}

fmt() { printf '%d.%d.%d+%d%d%02d%02d\n' "$1" "$2" "$3" "$1" "$2" "$3" "$4"; }

main_version() {
  git fetch -q origin main --tags
  git show "origin/main:$PUBSPEC" | sed -n 's/^version:[[:space:]]*//p'
}

cmd_next() {
  local kind="${1:?patch|build}" M m P BB
  read -r M m P BB <<<"$(parse "$(main_version)")"
  case "$kind" in
    build)
      # 범프 없이 태그만 나간 적이 있어도 번호를 재사용하지 않도록 원격 태그의 최대 순번도 본다.
      local prefix tagmax
      prefix=$(printf 'picnic-v%d.%d.%d+%d%d%02d' "$M" "$m" "$P" "$M" "$m" "$P")
      tagmax=$(git ls-remote --tags origin "refs/tags/${prefix}*" \
        | sed -n "s#.*refs/tags/${prefix//+/\\+}\([0-9][0-9]\).*#\1#p" | sort -n | tail -1)
      [ -n "$tagmax" ] && [ "$((10#$tagmax))" -gt "$BB" ] && BB=$((10#$tagmax))
      BB=$((BB + 1)) ;;
    patch) P=$((P + 1)); BB=1 ;;
    *) die "알 수 없는 종류: $kind (patch|build — 그 외는 bump 에 버전을 직접 지정)" ;;
  esac
  [ "$P" -le 99 ] && [ "$BB" -le 99 ] \
    || die "MmPPBB 범위 초과 — 새 체계로 마이그레이션이 필요하다"
  fmt "$M" "$m" "$P" "$BB"
}

cmd_bump() {
  local new="${1:?새 버전}" cur
  parse "$new" >/dev/null
  cur=$(main_version)
  [ "${new#*+}" -gt "${cur#*+}" ] || die "빌드 번호는 origin/main($cur) 보다 커야 한다"
  sed -i '' "s/^version:.*/version: $new/" "$PUBSPEC"
  echo "$cur → $new"
}

cmd_tag() {
  local suffix="" push=0
  for a in "$@"; do
    case "$a" in
      --skip-tests) suffix="-skip-tests" ;;
      --push) push=1 ;;
      *) die "알 수 없는 옵션: $a" ;;
    esac
  done
  local ver target tag others
  ver=$(main_version)
  parse "$ver" >/dev/null
  target=$(git rev-parse origin/main)
  tag="picnic-v${ver}${suffix}"

  [ -z "$(git tag --list "$tag")" ] || die "로컬에 이미 있는 태그: $tag"
  [ -z "$(git ls-remote --tags origin "refs/tags/$tag")" ] || die "원격에 이미 있는 태그: $tag"
  # 같은 버전이 다른 접미사로 이미 나갔다면 스토어가 빌드 번호를 거부한다.
  others=$(git ls-remote --tags origin "refs/tags/picnic-v${ver}*" | grep -v '\^{}' || true)
  [ -z "$others" ] || die "버전 $ver 은 이미 태그됐다 — 빌드 순번을 올려라: $others"
  # resolve_release_tag.sh 는 커밋당 릴리스 태그 1개만 허용한다(Codemagic Rebuild).
  others=$(git tag --points-at "$target" --list 'picnic-v*' 'picnic-staging-v*')
  [ -z "$others" ] || die "대상 커밋에 이미 릴리스 태그가 있다: $others"
  bash scripts/release_test_mode.sh "$tag" >/dev/null

  echo "tag:     $tag"
  echo "version: $ver"
  echo "commit:  $target  $(git log -1 --format=%s "$target")"
  if [ "$push" -eq 0 ]; then
    echo "(dry-run) 사용자 승인 후 --push 로 다시 실행"
    return
  fi
  git tag -a "$tag" "$target" -m "Release $ver"
  git push origin "$tag"
  git ls-remote --tags origin "refs/tags/$tag*"
}

cmd_status() {
  local tag="${1:?tag}" cfg="$HOME/.config/picnic/codemagic.env" sha
  # GitHub 체크는 빌드가 시작돼야 생긴다. 동시 빌드 1개라 Android 는 iOS 뒤에서 queued 로
  # 대기하므로, 토큰이 있으면 Codemagic API 를 본다(scripts/trigger_patch.sh 와 같은 설정 파일).
  if [ -f "$cfg" ]; then
    # shellcheck disable=SC1090
    source "$cfg"
    curl -fsS -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
      "https://api.codemagic.io/builds?appId=$CODEMAGIC_APP_ID&limit=20" \
      | jq -r --arg tag "$tag" '.builds[] | select(.tag == $tag)
          | [.fileWorkflowId, .status, (.startedAt // "-"), (.finishedAt // "-"),
             "https://codemagic.io/app/\(.appId)/build/\(._id)"] | @tsv'
    return
  fi
  sha=$(git ls-remote --tags origin "refs/tags/$tag^{}" | cut -f1)
  [ -n "$sha" ] || die "원격에 없는 태그: $tag"
  gh api "repos/:owner/:repo/commits/$sha/check-runs" \
    --jq '.check_runs[] | select(.name | startswith("Picnic App")) | [.name, .status, .conclusion // "-", .details_url] | @tsv'
}

cmd="${1:?next|bump|tag|status}"; shift
case "$cmd" in
  next|bump|tag|status) "cmd_$cmd" "$@" ;;
  *) die "알 수 없는 명령: $cmd" ;;
esac
