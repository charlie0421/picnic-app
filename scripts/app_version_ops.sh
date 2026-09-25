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
      select coalesce(device_info->>'platform','?') as platform, app_version, app_build_number
      from public.devices
      where last_seen >= now() - interval '${days} days'
    )
    select app_version,
           count(*) as devices,
           round(100.0 * count(*) / sum(count(*)) over (), 1) as pct,
           count(*) filter (where platform = 'ios') as ios,
           count(*) filter (where platform = 'android') as android
    from active
    group by app_version
    order by string_to_array(coalesce(app_version,'0'), '.')::int[] desc"

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
      [ "${1:-}" = "--apply" ] && apply=1
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
          and app_version is not null
          and string_to_array(app_version,'.')::int[] < string_to_array('$ver','.')::int[]
        group by 1 order by 1"

      local sql
      sql="update public.version
             set ios = (ios::jsonb || jsonb_build_object('version','$ver','force_version','$ver'))::json,
                 android = (android::jsonb || jsonb_build_object('version','$ver','force_version','$ver'))::json,
                 updated_at = now()
           where deleted_at is null"
      echo
      echo "## 실행할 SQL"; echo "$sql"
      if [ "$apply" -eq 0 ]; then
        echo; echo "(dry-run) 사용자 승인 후 --apply 로 다시 실행"
        return
      fi
      query json "$sql" >/dev/null
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
