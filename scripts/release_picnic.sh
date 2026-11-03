#!/usr/bin/env bash

# picnic_app 신규 바이너리 릴리스의 기계적 단계(버전 계산·범프·태그 사전검증)를 맡는다.
# 절차와 승인 게이트는 .claude/skills/picnic-release/SKILL.md 가 소유한다.
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
  # 가져오기에 실패하면 낡은 origin/main 으로 계산하지 않는다.
  git fetch -q origin main --tags || die "origin main 을 가져오지 못했다"
  git show "origin/main:$PUBSPEC" | sed -n 's/^version:[[:space:]]*//p'
}

# 원격 릴리스 태그 이름. 스테이징 태그도 같은 앱으로 업로드돼 스토어 빌드 번호를 쓰므로 함께 본다.
release_tags() {
  local raw
  raw=$(git ls-remote --tags origin 'refs/tags/picnic-v*' 'refs/tags/picnic-staging-v*') \
    || die "원격 릴리스 태그를 읽지 못했다"
  awk 'NF { sub(/.*refs\/tags\//, ""); sub(/\^\{\}$/, ""); print }' <<<"$raw" | sort -u
}

# release_tags 결과($1) 중 버전($2)에 붙은 태그(접미사 포함).
tags_for_version() {
  awk -v v="$2" '{ t = $0; sub(/^picnic-(staging-)?v/, "", t); sub(/-.*/, "", t) } t == v' <<<"$1"
}

# release_tags 결과($1)의 최대 빌드 번호. $2(MmPP)를 주면 그 접두의 번호만 본다. 태그가 없으면 0.
max_tagged_build() {
  awk -v p="${2:-}" 'match($0, /\+[0-9][0-9][0-9][0-9][0-9][0-9]/) {
      b = substr($0, RSTART + 1, 6)
      if ((p == "" || index(b, p) == 1) && b + 0 > max) max = b + 0
    }
    END { print max + 0 }' <<<"$1"
}

cmd_next() {
  local kind="${1:?patch|build}" ver tags parsed M m P BB tagmax
  ver=$(main_version)
  tags=$(release_tags)
  # 태그되지 않은 main 버전은 아직 빌드된 적이 없다. 여기서 다음 버전을 계산하면 그 번호를 건너뛴다.
  [ -n "$(tags_for_version "$tags" "$ver")" ] \
    || die "origin/main 의 $ver 은 아직 태그되지 않았다 — 범프하지 말고 tag 로 진행한다(다른 버전이 필요하면 bump 에 직접 지정)"
  parsed=$(parse "$ver")
  read -r M m P BB <<<"$parsed"
  case "$kind" in
    build)
      # 범프 없이 태그만 나간 번호(스테이징 포함)도 재사용하지 않도록 같은 버전의 최대 순번도 본다.
      tagmax=$(max_tagged_build "$tags" "$(printf '%d%d%02d' "$M" "$m" "$P")")
      [ $((tagmax % 100)) -gt "$BB" ] && BB=$((tagmax % 100))
      BB=$((BB + 1)) ;;
    patch) P=$((P + 1)); BB=1 ;;
    *) die "알 수 없는 종류: $kind (patch|build — 그 외는 bump 에 버전을 직접 지정)" ;;
  esac
  [ "$P" -le 99 ] && [ "$BB" -le 99 ] \
    || die "MmPPBB 범위 초과 — 새 체계로 마이그레이션이 필요하다"
  fmt "$M" "$m" "$P" "$BB"
}

cmd_bump() {
  local new="${1:?새 버전}" cur tags floor
  parse "$new" >/dev/null
  cur=$(main_version)
  # 낡은 브랜치에서 범프하면 최신 main 의 변경이 빠진 채 릴리스된다.
  git merge-base --is-ancestor origin/main HEAD \
    || die "현재 브랜치가 최신 origin/main($(git rev-parse --short origin/main)) 위에 있지 않다 — origin/main 에서 새 브랜치를 만들어라"
  [ "$new" != "$cur" ] || die "origin/main 이 이미 $cur 이다"
  # 스토어 빌드 번호는 태그로만 나간다. 태그되지 않은 main 버전은 나간 적이 없으므로 기준에서 빠지고,
  # 그보다 낮은 번호로 바로잡을 수 있다(실패한 빌드를 다시 내야 하는데 patch 범프가 먼저 머지된 경우).
  tags=$(release_tags)
  floor=$(max_tagged_build "$tags")
  [ "${new#*+}" -gt "$floor" ] || die "빌드 번호는 원격 릴리스 태그의 최댓값($floor)보다 커야 한다"
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
  local ver target tag tags floor others
  ver=$(main_version)
  parse "$ver" >/dev/null
  target=$(git rev-parse origin/main)
  tag="picnic-v${ver}${suffix}"
  tags=$(release_tags)

  [ -z "$(git tag --list "$tag")" ] || die "로컬에 이미 있는 태그: $tag"
  # 원격은 위에서 한 번만 읽는다. 다시 조회하면 그 실패가 빈 결과로 보여 검사를 통과한다.
  if grep -Fqx -- "$tag" <<<"$tags"; then die "원격에 이미 있는 태그: $tag"; fi
  # 같은 버전이 다른 접미사나 스테이징 태그로 이미 나갔다면 스토어가 빌드 번호를 거부한다.
  others=$(tags_for_version "$tags" "$ver")
  [ -z "$others" ] || die "버전 $ver 은 이미 태그됐다 — 빌드 순번을 올려라: ${others//$'\n'/ }"
  floor=$(max_tagged_build "$tags")
  [ "${ver#*+}" -gt "$floor" ] || die "빌드 번호 ${ver#*+} 이 원격 릴리스 태그의 최댓값($floor) 이하다 — bump 로 올려라"
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
  # Codemagic API 와 같은 열(워크플로 ID, 상태, 시작, 끝, URL)과 최신순으로 맞춘다. 끝난 체크는 결론을
  # Codemagic 상태 이름으로 바꾸고, 진행 중인 체크는 GitHub 상태를 그대로 둔다.
  gh api "repos/:owner/:repo/commits/$sha/check-runs" \
    --jq '.check_runs | map(select(.name | startswith("Picnic App"))) | sort_by(.started_at // "") | reverse | .[]
      | [({"Picnic App - iOS": "picnic-app-ios", "Picnic App - Android": "picnic-app-android"}[.name] // .name),
         (if .status == "completed"
          then ({"success": "finished", "failure": "failed", "cancelled": "canceled", "timed_out": "timeout"}[.conclusion] // .conclusion)
          else .status end),
         (.started_at // "-"), (.completed_at // "-"), .details_url] | @tsv'
}

cmd="${1:?next|bump|tag|status}"; shift
case "$cmd" in
  next|bump|tag|status) "cmd_$cmd" "$@" ;;
  *) die "알 수 없는 명령: $cmd" ;;
esac
