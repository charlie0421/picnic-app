#!/usr/bin/env bash

# picnic_app 프로덕션 버전 운영 — 배포율 조회와 강제 업데이트 기준 변경.
# 절차와 승인 게이트는 .claude/skills/picnic-adoption, picnic-force-update 가 소유한다.
#
#   adoption [--days N]        최근 N일(기본 7) 활성 기기의 버전 분포 (public.devices)
#   force show                 public.version 의 현재 version / force_version / url
#   force set <M.m.P> [--apply]  iOS·Android 의 version 과 force_version 을 <M.m.P> 로.
#                              기본 dry-run. --apply 가 있어야 실제로 쓴다
#
# 프로덕션 접근은 `supabase db query --linked` (Management API). 이 워크트리가
# PROD(xtijtefcycoeqludlngc)에 링크돼 있어야 한다: supabase link --project-ref xtijtefcycoeqludlngc

set -euo pipefail

PROD_REF=xtijtefcycoeqludlngc
cd "$(git rev-parse --show-toplevel)"

die() { echo "app_version_ops: $*" >&2; exit 1; }

require_prod_link() {
  local ref
  ref=$(cat supabase/.temp/project-ref 2>/dev/null || true)
  [ "$ref" = "$PROD_REF" ] || die "프로덕션에 링크돼 있지 않다(현재: '${ref:-없음}'). supabase link --project-ref $PROD_REF"
}

# Management API 는 502/504 를 자주 낸다. 같은 조회를 최대 4번, 20초 간격으로 다시 시도한다.
# 읽기 전용이다 — 쓰기는 query_once 를 쓴다(서버에서 이미 적용된 UPDATE 를 응답 실패 뒤 재실행하지 않기 위해).
query() {
  local fmt="$1" sql="$2" out i
  for i in 1 2 3 4; do
    if out=$(supabase db query --linked -o "$fmt" "$sql" 2>&1); then
      printf '%s\n' "$out" | grep -v -E 'new version of Supabase CLI|recommend updating|Initialising login role'
      return 0
    fi
    printf '%s\n' "$out" | grep -q -E '50[234]' || { printf '%s\n' "$out" >&2; return 1; }
    [ "$i" -lt 4 ] && sleep 20
  done
  printf '%s\n' "$out" >&2
  return 1
}

# 재시도 없는 단발 실행. 실패해도 여기서 죽지 않고 호출자가 재조회로 판정한다.
query_once() {
  local fmt="$1" sql="$2" out
  if out=$(supabase db query --linked -o "$fmt" "$sql" 2>&1); then
    printf '%s\n' "$out" | grep -v -E 'new version of Supabase CLI|recommend updating|Initialising login role'
    return 0
  fi
  printf '%s\n' "$out" >&2
  return 1
}

# 'M.m.P' 처럼 숫자 세그먼트만 있는 app_version 만 int[] 로 비교한다. 그 외('1.3.5-beta', '')는
# 캐스트가 실패해 조회 전체가 죽으므로 별도 그룹으로 센다.
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

cmd_adoption() {
  local days=7
  while [ $# -gt 0 ]; do
    case "$1" in
      --days) days="${2:?일수}"; shift 2 ;;
      *) die "알 수 없는 옵션: $1" ;;
    esac
  done
  [[ "$days" =~ ^[0-9]+$ ]] || die "--days 는 정수: $days"
  require_prod_link

  echo "## 최근 ${days}일 활성 기기 — 표시 버전별 (플랫폼 합산)"
  query table "
    with active as (
      select coalesce(device_info->>'platform','?') as platform,
             case when app_version ~ '$SEMVER_RE' then app_version
                  else '(invalid: ' || coalesce(app_version,'null') || ')' end as app_version,
             case when app_version ~ '$SEMVER_RE' then string_to_array(app_version, '.')::int[] end as ver_key
      from public.devices
      where last_seen >= now() - interval '${days} days'
    )
    select app_version,
           count(*) as devices,
           round(100.0 * count(*) / sum(count(*)) over (), 1) as pct,
           count(*) filter (where platform = 'ios') as ios,
           count(*) filter (where platform = 'android') as android
    from active
    group by app_version, ver_key
    order by ver_key desc nulls last"

  echo
  echo "## 최근 ${days}일 활성 기기 — 플랫폼 × 빌드 번호 (상위 15)"
  query table "
    select coalesce(device_info->>'platform','?') as platform, app_version, app_build_number,
           count(*) as devices,
           count(*) filter (where last_seen >= now() - interval '1 day') as active_1d
    from public.devices
    where last_seen >= now() - interval '${days} days'
    group by 1,2,3
    order by devices desc
    limit 15"

  echo
  echo "## 현재 강업 기준 (public.version)"
  query table "
    select ios->>'version' as ios_latest, ios->>'force_version' as ios_force,
           android->>'version' as android_latest, android->>'force_version' as android_force,
           updated_at
    from public.version where deleted_at is null"
}

cmd_force() {
  local sub="${1:?show|set}"; shift
  require_prod_link
  case "$sub" in
    show)
      query table "
        select id, ios::text, android::text, updated_at
        from public.version where deleted_at is null" ;;
    set)
      local ver="${1:?M.m.P}" apply=0; shift
      [ "${1:-}" = "--apply" ] && { apply=1; shift; }
      [ $# -eq 0 ] || die "알 수 없는 인자: $*"
      [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "표시 버전 형식은 M.m.P (빌드 번호 없이): $ver"

      # 대상보다 높은 force_version 으로는 내리지 않는다 — 이미 막힌 사용자가 다시 열린다.
      local cur
      cur=$(query json "select ios->>'force_version' as i, android->>'force_version' as a from public.version where deleted_at is null" \
        | jq -r '.rows[0] | "\(.i) \(.a)"')
      echo "현재 force_version: ios=${cur% *} android=${cur#* }"
      for c in $cur; do
        [ "$(printf '%s\n%s\n' "$c" "$ver" | sort -V | tail -1)" = "$ver" ] \
          || die "현재 force_version $c 가 대상 $ver 보다 높다 — 내리지 않는다"
      done

      # 7일 활성 기기 중 대상 미만 = 이 변경으로 막히는 기기 수.
      echo "## $ver 미만이라 막히게 될 7일 활성 기기"
      query table "
        select coalesce(device_info->>'platform','?') as platform, count(*) as blocked_devices
        from public.devices
        where last_seen >= now() - interval '7 days'
          and app_version ~ '$SEMVER_RE'
          and string_to_array(app_version,'.')::int[] < string_to_array('$ver','.')::int[]
        group by 1 order by 1"

      # WHERE 에 "현재 기준 ≤ 대상" 을 넣어, 위의 확인과 이 UPDATE 사이에 다른 운영자가 더 높은
      # 기준을 넣었어도 여기서 내려가지 않게 한다. RETURNING 으로 실제 갱신 여부를 본다.
      local sql
      sql="update public.version
             set ios = (ios::jsonb || jsonb_build_object('version','$ver','force_version','$ver'))::json,
                 android = (android::jsonb || jsonb_build_object('version','$ver','force_version','$ver'))::json,
                 updated_at = now()
           where deleted_at is null
             and string_to_array(ios->>'force_version','.')::int[] <= string_to_array('$ver','.')::int[]
             and string_to_array(android->>'force_version','.')::int[] <= string_to_array('$ver','.')::int[]
           returning id"
      echo
      echo "## 실행할 SQL"; echo "$sql"
      if [ "$apply" -eq 0 ]; then
        echo; echo "(dry-run) 사용자 승인 후 --apply 로 다시 실행"
        return
      fi
      # 응답이 502/504 로 끊겨도 UPDATE 는 이미 서버에 적용됐을 수 있다. 재실행하지 않고 재조회로 판정한다.
      local updated
      if updated=$(query_once json "$sql"); then
        [ "$(printf '%s' "$updated" | jq '.rows | length')" -eq 1 ] \
          || die "갱신된 행이 없다 — 그 사이 force_version 이 $ver 보다 높아졌을 수 있다. force show 로 확인하라"
      else
        echo "UPDATE 응답 실패 — 재실행하지 않고 현재 값을 재조회한다" >&2
      fi
      echo; echo "## 적용 후"
      query table "select ios::text, android::text, updated_at from public.version where deleted_at is null"
      query json "select ios->>'force_version' as i, android->>'force_version' as a from public.version where deleted_at is null" \
        | jq -e --arg v "$ver" '.rows[0] | .i == $v and .a == $v' >/dev/null || die "적용 후 검증 실패 — force_version 이 $ver 가 아니다"
      echo "검증: ios·android force_version = $ver" ;;
    *) die "알 수 없는 하위 명령: $sub (show|set)" ;;
  esac
}

cmd="${1:?adoption|force}"; shift
case "$cmd" in
  adoption|force) "cmd_$cmd" "$@" ;;
  *) die "알 수 없는 명령: $cmd" ;;
esac
