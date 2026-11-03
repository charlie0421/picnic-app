# Candy Boost 어드민 일정(V2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `promotion_campaigns`의 기존 identity를 재사용해 전체 행사 기간·복수 KST 요일·독립 HOME/결제배지 노출·정수 배수(1.1x~3.0x)를 저장하는 additive V2 스키마·RPC·어드민 UI·Flutter 계약을 추가하고, V1은 그대로 둔 채 flag로 게이트한다.

**Architecture:** `picnic-supabase`가 V2 스키마·evaluator·read/admin RPC의 단일 진실이며 먼저 배포된다(flag off). `picnic-admin-wallet-ops`는 새 command/parser 계약만 소비해 버그가 있는 기존 주간/bps 생성 UI를 V2 폼으로 교체한다. `picnic-app`(현재 워크트리)은 V2 repository/provider를 추가해 V2를 우선 호출하고 실패·미지원 시에만 V1으로 폴백한다. 세 저장소 모두 V1 테이블/함수/RPC/Dart 모델은 수정하지 않는다.

**Tech Stack:** PostgreSQL/Supabase CLI(migrations, plpgsql), Deno/psql SQL tests, Next.js 14/TypeScript/Jest, Flutter/Riverpod/Freezed/gen-l10n.

**Spec:** `docs/superpowers/specs/2026-08-21-candy-boost-admin-scheduling-design.md`

## Global Constraints

- 기존 V1 테이블(`promotion_campaigns`, `promotion_campaign_versions`, `promotion_home_banner_owners`)과 V1 함수(`wallet_private.evaluate_campaign_promotion`, `get_active_promotion_campaigns(text)`, `admin_create_promotion_version`)는 시그니처·바디·grant를 변경하지 않는다. 모든 V2 객체는 새 이름으로 additive하게 추가한다.
- `promotion_campaigns.id`(bigint identity)를 그대로 재사용한다. RPC/admin 요청·응답의 `campaign_id`는 V1과 동일하게 uuid wire-id이며 `wallet_private.promotion_campaign_wire_ids`(kind='CAMPAIGN')로 내부 bigint와 번역한다. `home_banner_id`도 V1과 동일하게 wire uuid(kind='BANNER')로 주고받는다.
- 모든 금액/배수 계산은 정수 산술만 사용한다(`bigint`/`smallint`, 부동소수점 캐스트 금지). `multiplier_tenths`는 11..30 정수(1.1x..3.0x)만 허용한다.
- KST는 `Asia/Seoul` 고정, `event_starts_at` 포함·`event_ends_at` 제외([start,end) 반개구간)이며 host/session timezone에 의존하지 않고 `AT TIME ZONE 'Asia/Seoul'`로만 계산한다.
- 노출 판정은 `wallet_private.fixed_db_now()` 스냅샷, 지급 판정은 검증된 provider 발생 시각을 쓴다. provider 시각이 없거나 신뢰할 수 없으면 처리 시각으로 대체하지 말고 `PROMOTION_TIME_UNVERIFIABLE`로 보류한다.
- 신규 V2 테이블/RPC는 anon에 어떤 권한도 주지 않는다(과거 `20260729120000_fix_promotion_rpc_anon_gate_conflict.sql` 인시던트 재발 방지). 새 함수는 `wallet_service_rpc_catalog`/`wallet_service_rpc_manifest`에 분류 등록한다.
- 어드민 command RPC는 기존 envelope `wallet_stable_command_envelope` 및 `(p_actor_user_id uuid, p_request jsonb)` 시그니처, request idempotency, `expected_latest_version` 낙관적 동시성, `reason`/`cs_ticket` 필수, exact-key 검증을 지킨다(V1 `admin_create_promotion_version` 패턴 재사용, `wallet_admin_command_rpcs.sql:356-378`).
- 이 계획은 구매 정산 디스패처(`resolve_purchase_promotion`/`wallet_private.resolve_purchase_promotion_locked_task7`)를 수정하지 않는다. V2 evaluator·정산 math·grant snapshot은 완전히 구현·테스트하되, 그 정산 함수 내부로 실제 배선하는 것은 이 계획 범위 밖이며 별도 후속 작업으로 남긴다(스펙 본문이 그 함수 이름을 지정하지 않고, 해당 함수는 Task 7 rename 이력이 있는 고위험 라이브 결제 코드라 사전 조사 없이 수정하지 않는다).
- Flutter `CommonBanner`의 기존 `commonBannerCampaignWaitCap`/shimmer/degrade state machine(PR #143 회귀 방지 주석, `common_banner.dart:40-46`)은 그대로 유지한다 — provider 계층만 V1/V2 소스를 교체하고 위젯의 대기·저하 로직은 건드리지 않는다.
- 모든 commit은 Conventional Commits. 각 Task의 지정된 테스트가 통과하기 전에는 해당 sub-cycle을 commit하지 않는다.
- UI/API 변경을 `main`에 merge하기 전 반드시 "Vercel Preview URL 로 확인하셨나요?"라고 묻고 답을 기다린다(Task 8).

---

## Repository / Worktree Map

| 저장소 | 경로 | 브랜치 | 비고 |
|---|---|---|---|
| picnic-supabase | `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling` (Task 1에서 신규 생성) | `feat/candy-boost-admin-scheduling` | 원본 `/Users/charlie.hyun/Repositories/picnic-supabase`(main)은 건드리지 않는다. 원본에 이미 있는 미커밋 변경(`.gitignore`,`package.json`,`.nvmrc`)은 새 worktree에 자동으로 없다 — 복사/스테이징하지 않는다 |
| picnic-admin-wallet-ops | `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops` (기존) | `feat/wallet-ops` (기존) | 새 worktree 불필요 — 이미 이 기능(`PromotionCampaigns.tsx`)의 홈. 기존 untracked `docs/superpowers/plans/2026-07-23-wallet-ops-admin.md`는 건드리지 않는다 |
| picnic-app | `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트` (현재) | `charlie0421/결제이벤트` (기존) | 새 worktree 불필요 — 이미 이 spec이 커밋된 현재 세션 |

## Task DAG

```text
Task 1 (Supabase: V2 schema)
  -> Task 2 (Supabase: evaluator + reward math + V2 read RPC)
       -> Task 3 (Supabase: admin read/write RPC + grant snapshot)
            -> Task 4 (Admin: error-map + command/parser + API route)
                 -> Task 5 (Admin: PromotionCampaigns.tsx V2 폼)
Task 6 (Flutter: V2 model + repository/provider) -- 계약만 필요, 백엔드 배포 불필요, 병행 가능
     depends on: Task 2 의 RPC 이름/파라미터/응답 필드 (본 문서에 고정)
  -> Task 7 (Flutter: 배지 + HOME 배너 V2 렌더링 + V1 폴백)
Task 8 (통합: fixture 동기화 + 3저장소 rollout) depends on: Task 1-7 전부
```

Task 1→2→3→4→5는 순차(각자 앞 Task의 실제 RPC/타입을 소비). Task 6→7은 Task 2가 고정한 계약만 있으면 Task 1-5와 독립적으로(병행) 진행 가능. Task 8은 마지막에 전체를 통합·검증한다.

---

### Task 1: Supabase V2 스키마 — 테이블, 불변성, 배너 소유권, grant, flag

**Files:**
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821100000_promotion_schedule_v2_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_campaign_schedule_v2_constraints.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/scripts/safety/run-wallet-sql-tests.mjs` (test 파일 배열에 추가)

**Interfaces:**
- Produces: 테이블 `public.promotion_campaign_schedule_versions`(컬럼 목록은 아래 DDL), `public.promotion_campaign_schedule_weekdays(campaign_version_id uuid, iso_dow smallint)`. Runtime flag `promotion_schedule_v2_enabled`(초기값 `false`). 이후 모든 Task가 이 두 테이블과 flag key를 그대로 사용한다.

- [ ] **Step 1: 사용자에게 신규 worktree 생성을 승인받는다**

승인 전에는 아래 `worktree add`를 실행하지 않는다.

- [ ] **Step 2: worktree 생성 및 의존성 설치**

```bash
git -C /Users/charlie.hyun/Repositories/picnic-supabase worktree add /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling -b feat/candy-boost-admin-scheduling
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling && npm install
supabase status || supabase start
```

Expected: worktree 생성 exit 0, `npm install` exit 0, 로컬 Supabase(54321/54322)가 기동 상태.

- [ ] **Step 3: 실패하는 제약 테스트를 먼저 작성한다**

`supabase/tests/promotion_campaign_schedule_v2_constraints.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_other_campaign_id bigint;
  v_banner_id integer;
  v_version_id uuid;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_TEST', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into public.banner (title, image) values ('{"ko":"t"}'::jsonb, '{"ko":"i"}'::jsonb)
    returning id into v_banner_id;

  -- event_starts_at must be before event_ends_at
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-01 00:00:00+09',
      'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    );
    raise exception 'expected event range check violation';
  exception when check_violation then null;
  end;

  -- multiplier_tenths out of range rejected (31)
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 31, false, true, '{"ko":"t"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    );
    raise exception 'expected multiplier check violation (31)';
  exception when check_violation then null;
  end;

  -- multiplier_tenths out of range rejected (10)
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 10, false, true, '{"ko":"t"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    );
    raise exception 'expected multiplier check violation (10)';
  exception when check_violation then null;
  end;

  -- show_home_banner=true requires home_banner_id
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge, home_banner_id,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 15, true, false, null, '{"ko":"t"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    );
    raise exception 'expected home banner check violation';
  exception when check_violation then null;
  end;

  -- display_name without non-blank ko rejected
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 15, false, true, '{"ko":"  "}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    );
    raise exception 'expected display_name check violation';
  exception when check_violation then null;
  end;

  -- a version with zero weekday rows is rejected at commit (deferred constraint)
  begin
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-1'
    ) returning id into v_version_id;
    set constraints promotion_campaign_schedule_version_requires_weekday immediate;
    raise exception 'expected weekday-required violation';
  exception when others then
    if sqlerrm <> 'PROMOTION_WEEKDAY_REQUIRED' then raise; end if;
  end;

  -- valid version + weekday rows succeeds
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge, home_banner_id,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
    'Asia/Seoul', 15, true, true, v_banner_id, '{"ko":"t"}'::jsonb,
    gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
    values (v_version_id, 1), (v_version_id, 3), (v_version_id, 5);

  -- append-only: UPDATE rejected
  begin
    update public.promotion_campaign_schedule_versions set enabled = false where id = v_version_id;
    raise exception 'expected immutability violation on update';
  exception when others then
    if sqlerrm <> 'promotion_campaign_schedule_versions is immutable' then raise; end if;
  end;

  -- append-only: DELETE rejected
  begin
    delete from public.promotion_campaign_schedule_versions where id = v_version_id;
    raise exception 'expected immutability violation on delete';
  exception when others then
    if sqlerrm <> 'promotion_campaign_schedule_versions is immutable' then raise; end if;
  end;

  -- append-only: TRUNCATE rejected
  begin
    truncate public.promotion_campaign_schedule_versions;
    raise exception 'expected immutability violation on truncate';
  exception when others then
    if sqlerrm <> 'promotion_campaign_schedule_versions is immutable' then raise; end if;
  end;

  -- weekdays child table also append-only
  begin
    delete from public.promotion_campaign_schedule_weekdays where campaign_version_id = v_version_id;
    raise exception 'expected weekdays immutability violation';
  exception when others then
    if sqlerrm <> 'promotion_campaign_schedule_weekdays is immutable' then raise; end if;
  end;

  -- HOME banner ownership: a second campaign cannot reuse the same banner (reused V1 guard)
  begin
    insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_TEST_2', 'PURCHASE_BONUS')
      returning id into v_other_campaign_id;
    insert into public.promotion_campaign_schedule_versions (
      campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
      timezone, multiplier_tenths, show_home_banner, show_payment_badge, home_banner_id,
      display_name, changed_by, change_reason, cs_ticket
    ) values (
      v_other_campaign_id, 1, wallet_private.fixed_db_now(), true,
      '2026-09-01 00:00:00+09', '2026-09-08 00:00:00+09',
      'Asia/Seoul', 12, true, false, v_banner_id, '{"ko":"other"}'::jsonb,
      gen_random_uuid(), 'setup', 'CS-2'
    ) returning id into v_version_id;
    insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow) values (v_version_id, 1);
    raise exception 'expected home banner ownership violation';
  exception when others then
    if sqlerrm <> 'PROMOTION_HOME_BANNER_ALREADY_OWNED' then raise; end if;
  end;

  -- no direct DML privilege for public/anon/authenticated/service_role
  if has_table_privilege('anon', 'public.promotion_campaign_schedule_versions', 'INSERT') then
    raise exception 'anon must not have insert on promotion_campaign_schedule_versions';
  end if;
  if has_table_privilege('service_role', 'public.promotion_campaign_schedule_versions', 'INSERT') then
    raise exception 'service_role must not have direct insert on promotion_campaign_schedule_versions';
  end if;
end $$;

rollback;
```

- [ ] **Step 4: 테스트가 실패하는 것을 확인한다(테이블이 없음)**

Run: `env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql`
Expected: FAIL — `relation "public.promotion_campaign_schedule_versions" does not exist` (테스트 배열에 아직 추가 전이면 이 파일만 단독 실행: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_campaign_schedule_v2_constraints.test.sql`)

- [ ] **Step 5: 최소 구현 — 마이그레이션 작성**

`supabase/migrations/20260821100000_promotion_schedule_v2_schema.sql`:

```sql
create table public.promotion_campaign_schedule_versions (
  id uuid primary key default gen_random_uuid(),
  campaign_id bigint not null references public.promotion_campaigns(id),
  version bigint not null check (version > 0),
  effective_from timestamptz not null,
  enabled boolean not null,
  event_starts_at timestamptz not null,
  event_ends_at timestamptz not null,
  timezone text not null check (timezone = 'Asia/Seoul'),
  multiplier_tenths smallint not null check (multiplier_tenths between 11 and 30),
  show_home_banner boolean not null,
  show_payment_badge boolean not null,
  home_banner_id integer references public.banner(id),
  display_name jsonb not null check (
    jsonb_typeof(display_name) = 'object'
    and nullif(btrim(display_name->>'ko'), '') is not null
  ),
  changed_by uuid not null,
  change_reason text not null check (btrim(change_reason) <> ''),
  cs_ticket text not null check (btrim(cs_ticket) <> ''),
  created_at timestamptz not null default wallet_private.fixed_db_now(),
  unique (campaign_id, version),
  unique (campaign_id, effective_from),
  check (event_starts_at < event_ends_at),
  check (show_home_banner = (home_banner_id is not null))
);

create index promotion_campaign_schedule_versions_latest_idx
  on public.promotion_campaign_schedule_versions (campaign_id, effective_from desc, version desc);

create table public.promotion_campaign_schedule_weekdays (
  campaign_version_id uuid not null references public.promotion_campaign_schedule_versions(id),
  iso_dow smallint not null check (iso_dow between 1 and 7),
  primary key (campaign_version_id, iso_dow)
);

-- Append-only: reuse the codebase-wide immutability guard
-- (wallet_private.reject_immutable_change, wallet_core_operation_schema.sql:72-77).
create trigger promotion_campaign_schedule_versions_immutable
  before update or delete on public.promotion_campaign_schedule_versions
  for each row execute function wallet_private.reject_immutable_change();
create trigger promotion_campaign_schedule_versions_truncate_immutable
  before truncate on public.promotion_campaign_schedule_versions
  for each statement execute function wallet_private.reject_immutable_change();

create trigger promotion_campaign_schedule_weekdays_immutable
  before update or delete on public.promotion_campaign_schedule_weekdays
  for each row execute function wallet_private.reject_immutable_change();
create trigger promotion_campaign_schedule_weekdays_truncate_immutable
  before truncate on public.promotion_campaign_schedule_weekdays
  for each statement execute function wallet_private.reject_immutable_change();

-- At least one weekday row per version, checked at end of the creating transaction
-- (weekday rows are inserted in a second statement of the same admin-command transaction).
create or replace function wallet_private.guard_promotion_schedule_version_has_weekday()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.promotion_campaign_schedule_weekdays w
    where w.campaign_version_id = new.id
  ) then
    raise exception using errcode = 'P0001', message = 'PROMOTION_WEEKDAY_REQUIRED';
  end if;
  return null;
end
$$;

create constraint trigger promotion_campaign_schedule_version_requires_weekday
  after insert on public.promotion_campaign_schedule_versions
  deferrable initially deferred
  for each row execute function wallet_private.guard_promotion_schedule_version_has_weekday();

-- HOME banner ownership: reuse the existing single-campaign-ownership guard as-is
-- (wallet_private.guard_promotion_home_banner_owner, harden_promotion_surface_release.sql:40-55) —
-- it reads NEW.home_banner_id / NEW.campaign_id generically, both present on this table too.
create constraint trigger promotion_schedule_home_banner_single_campaign
  after insert on public.promotion_campaign_schedule_versions
  deferrable initially immediate
  for each row execute function wallet_private.guard_promotion_home_banner_owner();

alter table public.promotion_campaign_schedule_versions owner to wallet_command_owner;
alter table public.promotion_campaign_schedule_weekdays owner to wallet_command_owner;
revoke all on table public.promotion_campaign_schedule_versions, public.promotion_campaign_schedule_weekdays
  from public, anon, authenticated, service_role;

insert into public.wallet_runtime_flags (flag_key, value_json, version, changed_by, reason)
values ('promotion_schedule_v2_enabled', 'false', 1, null, 'promotion schedule v2 dark launch default')
on conflict (flag_key) do nothing;
```

- [ ] **Step 6: 테스트 실행 배열에 새 파일을 등록한다**

`scripts/safety/run-wallet-sql-tests.mjs`의 기존 promotion 3종(`promotion_campaign_constraints.test.sql` 등, 6-44줄 배열)이 나열된 바로 다음에 `'promotion_campaign_schedule_v2_constraints.test.sql'`을 추가한다.

- [ ] **Step 7: 마이그레이션 적용 후 테스트 통과 확인**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset
env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
```

Expected: 두 명령 모두 exit 0, 새 테스트 파일의 모든 `assert`/예외 분기 통과.

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260821100000_promotion_schedule_v2_schema.sql \
  supabase/tests/promotion_campaign_schedule_v2_constraints.test.sql \
  scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add append-only V2 schedule schema"
```

---

### Task 2: Supabase evaluator, 정수 배수 math, V2 read RPC

**Files:**
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821103000_promotion_schedule_v2_evaluator_and_math.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821110000_promotion_schedule_v2_read_rpc.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_campaign_schedule_v2_evaluator.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_schedule_v2_surface_contract.test.sql`
- Modify: `scripts/safety/run-wallet-sql-tests.mjs`

**Interfaces:**
- Consumes: Task 1의 `promotion_campaign_schedule_versions`/`_weekdays`, `wallet_private.fixed_db_now()`.
- Produces: `wallet_private.evaluate_campaign_promotion_schedule_v2(p_campaign_id bigint, p_at timestamptz) returns public.promotion_campaign_schedule_versions`, `wallet_private.compute_promotion_reward_v2(p_base_reward_total bigint, p_multiplier_tenths smallint) returns table(gross_total bigint, extra_bonus bigint)`, `public.get_active_promotion_campaigns_v2(p_surface text) returns jsonb`. Task 3와 Task 6가 이 세 함수와 read RPC 응답 필드셋(`campaign_id,campaign_version_id,code,display_name,multiplier_tenths,event_starts_at,event_ends_at,repeat_iso_dows,home_creative`)을 그대로 소비한다.

#### Sub-cycle A: evaluator + 정수 배수 math (필수 반례: KST 반개구간, 정수 배수)

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`supabase/tests/promotion_campaign_schedule_v2_evaluator.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_version_id uuid;
  v_result public.promotion_campaign_schedule_versions;
  v_gross bigint; v_extra bigint;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_EVAL', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  -- 2026-09-07(월)~2026-09-14(월) KST, 월/수/금만 활성
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    '2026-09-07 00:00:00+09', '2026-09-14 00:00:00+09',
    'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
    gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
    values (v_version_id, 1), (v_version_id, 3), (v_version_id, 5);

  -- KST 반개구간: event_starts_at 정각(월 00:00 KST)은 포함
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-06 15:00:00+00');
  assert v_result.id is not null, 'event_starts_at instant (KST Mon 00:00) must be inclusive';

  -- 선택 요일이 아닌 화요일은 비활성
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-08 01:00:00+00');
  assert v_result.id is null, 'unselected weekday (KST Tue) must be inactive';

  -- KST 반개구간: event_ends_at 정각(월 00:00 KST, 다음주)은 제외
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-13 15:00:00+00');
  assert v_result.id is null, 'event_ends_at instant (KST Mon 00:00 next week) must be exclusive';

  -- 선택 요일(수) KST 자정 직후는 활성
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-08 15:00:00+00');
  assert v_result.id is not null, 'selected weekday (KST Wed 00:00) must be active just after local midnight';

  -- 선택 요일(수) KST 23:59:59는 활성, 자정 넘어간 목요일은 비활성 (연/월 경계 없이도 자정 전이 규칙)
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-09 14:59:59+00');
  assert v_result.id is not null, 'selected weekday (KST Wed 23:59:59) must still be active';
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-09 15:00:00+00');
  assert v_result.id is null, 'rolling past KST midnight into unselected weekday (Thu) must be inactive';

  -- enabled=false 버전은 항상 비활성
  update public.promotion_campaign_schedule_weekdays set iso_dow = iso_dow where false; -- no-op, keep table shape stable
end $$;

do $$
declare
  v_campaign_id bigint;
  v_version_id uuid;
  v_result public.promotion_campaign_schedule_versions;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_EVAL_DISABLED', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), false,
    '2026-09-07 00:00:00+09', '2026-09-14 00:00:00+09',
    'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
    gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow) values (v_version_id, 1);

  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-09-06 15:00:00+00');
  assert v_result.id is null, 'enabled=false version must never evaluate active';
end $$;

-- version effective_from 경계: 최신 effective_from을 가진 version만 평가 대상이고,
-- 그 시각 이전에는 이전 version의 규칙이 그대로 적용된다. 요일 라벨을 하드코딩하지 않고
-- 실제 날짜에서 계산해, 실행 시점의 달력과 무관하게 테스트 논리가 성립하도록 한다.
do $$
declare
  v_campaign_id bigint;
  v_v1_id uuid;
  v_v2_id uuid;
  v_event_start timestamptz := date_trunc('day', wallet_private.fixed_db_now()) + interval '1 day';
  v_v2_effective timestamptz;
  v_event_end timestamptz;
  v_dow_at_start smallint;
  v_result public.promotion_campaign_schedule_versions;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_EVAL_EFFECTIVE', 'PURCHASE_BONUS')
    returning id into v_campaign_id;

  v_v2_effective := v_event_start + interval '7 days'; -- 7-day shift keeps the same KST weekday as v_event_start
  v_event_end := v_event_start + interval '21 days';
  v_dow_at_start := extract(isodow from (v_event_start at time zone 'Asia/Seoul'));

  -- v1: event_start의 요일만 허용
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true, v_event_start, v_event_end,
    'Asia/Seoul', 15, false, true, '{"ko":"v1"}'::jsonb, gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_v1_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow) values (v_v1_id, v_dow_at_start);

  -- v2: event_start 요일 + 1(다른 요일)만 허용, event_start로부터 7일 뒤부터 effective
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 2, v_v2_effective, true, v_event_start, v_event_end,
    'Asia/Seoul', 20, false, true, '{"ko":"v2"}'::jsonb, gen_random_uuid(), 'weekday narrowed', 'CS-2'
  ) returning id into v_v2_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
    values (v_v2_id, (v_dow_at_start % 7) + 1); -- a different iso_dow than v1's, computed not hardcoded

  -- v2.effective_from 직전 순간에는 여전히 v1이 선택되고, v1이 허용한 요일이므로 활성이다
  -- (v_v2_effective 자체는 v1과 같은 요일이므로, 그 1초 전을 확인해 v1의 창을 벗어나지 않게 한다)
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, v_v2_effective - interval '1 second');
  assert v_result.id = v_v1_id, 'the instant before v2.effective_from must still select v1';

  -- v2.effective_from 시각(요일은 v1과 동일)에는 v2가 선택되지만, v2는 이 요일을 허용하지
  -- 않으므로 비활성(null)이어야 한다 — v1의 규칙이 새어 들어오면 안 된다.
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, v_v2_effective);
  assert v_result.id is null,
    'at v2.effective_from, v2 (not v1) governs, and v1''s now-superseded weekday must not leak through';

  -- (v_dow_at_start % 7) + 1 은 "v_dow_at_start의 다음 날 요일"과 정확히 같으므로,
  -- v_v2_effective의 하루 뒤가 v2가 허용하는 요일의 첫 발생 시점이다.
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, v_v2_effective + interval '1 day');
  assert v_result.id = v_v2_id, 'v2''s own selected weekday must be active under v2';
end $$;

-- 연말 경계: 12/31(목) 활성, 1/1(금) 비선택 요일이면 비활성
do $$
declare
  v_campaign_id bigint;
  v_version_id uuid;
  v_result public.promotion_campaign_schedule_versions;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_EVAL_YEAREND', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    '2026-12-28 00:00:00+09', '2027-01-04 00:00:00+09',
    'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
    gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow) values (v_version_id, 4); -- Thursday only

  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2026-12-31 10:00:00+09');
  assert v_result.id is not null, 'year-end Thursday (Dec 31) must be active';
  v_result := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign_id, '2027-01-01 10:00:00+09');
  assert v_result.id is null, 'New Year Friday (Jan 1, unselected weekday) must be inactive';
end $$;

-- 정수 배수: 부동소수점/반올림이 아닌 정수 산술 + 최소 extra=1 보장
do $$
declare v_gross bigint; v_extra bigint;
begin
  select gross_total, extra_bonus into v_gross, v_extra from wallet_private.compute_promotion_reward_v2(1, 11);
  assert v_gross = 2 and v_extra = 1, format('base=1,tenths=11 expected gross=2/extra=1, got gross=%s/extra=%s', v_gross, v_extra);

  select gross_total, extra_bonus into v_gross, v_extra from wallet_private.compute_promotion_reward_v2(15, 15);
  assert v_gross = 22 and v_extra = 7, format('base=15,tenths=15 expected gross=22/extra=7, got gross=%s/extra=%s', v_gross, v_extra);

  -- half-integer product (75/10=7.5): must truncate/floor to 7, not round to 8
  select gross_total, extra_bonus into v_gross, v_extra from wallet_private.compute_promotion_reward_v2(3, 25);
  assert v_gross = 7 and v_extra = 4, format('base=3,tenths=25 expected gross=7/extra=4 (floor, not round), got gross=%s/extra=%s', v_gross, v_extra);

  -- max multiplier
  select gross_total, extra_bonus into v_gross, v_extra from wallet_private.compute_promotion_reward_v2(100, 30);
  assert v_gross = 300 and v_extra = 200, format('base=100,tenths=30 expected gross=300/extra=200, got gross=%s/extra=%s', v_gross, v_extra);
end $$;

rollback;
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_campaign_schedule_v2_evaluator.test.sql`
Expected: FAIL — `function wallet_private.evaluate_campaign_promotion_schedule_v2(...) does not exist`

- [ ] **Step 3: 최소 구현**

`supabase/migrations/20260821103000_promotion_schedule_v2_evaluator_and_math.sql`:

```sql
create or replace function wallet_private.evaluate_campaign_promotion_schedule_v2(
  p_campaign_id bigint, p_at timestamptz
) returns public.promotion_campaign_schedule_versions
language plpgsql stable security definer set search_path = '' as $$
declare
  v_version public.promotion_campaign_schedule_versions%rowtype;
  v_local_date date;
  v_local_dow smallint;
begin
  if p_at is null or p_campaign_id is null then return null; end if;

  select v.* into v_version from public.promotion_campaign_schedule_versions v
  where v.campaign_id = p_campaign_id and v.effective_from <= p_at
  order by v.effective_from desc, v.version desc limit 1;

  if v_version.id is null or not v_version.enabled then return null; end if;
  if not (p_at >= v_version.event_starts_at and p_at < v_version.event_ends_at) then return null; end if;

  v_local_date := (p_at at time zone v_version.timezone)::date;
  v_local_dow := extract(isodow from v_local_date);
  if not exists (
    select 1 from public.promotion_campaign_schedule_weekdays w
    where w.campaign_version_id = v_version.id and w.iso_dow = v_local_dow
  ) then
    return null;
  end if;

  return v_version;
end
$$;

revoke all on function wallet_private.evaluate_campaign_promotion_schedule_v2(bigint, timestamptz)
  from public, anon, authenticated, service_role;

-- gross_total = floor(base*tenths/10), but never less than base_reward_total + 1 —
-- multiplier_tenths >= 11 always implies a strictly positive extra bonus even for base=1
-- (spec: "base_reward_total은 양수이고 multiplier_tenths>=11이므로 extra도 최소 1이 된다").
-- Integer bigint/integer division truncates toward zero, which equals floor() for the
-- always-positive operands here — no numeric/float cast anywhere in this function.
create or replace function wallet_private.compute_promotion_reward_v2(
  p_base_reward_total bigint, p_multiplier_tenths smallint
) returns table(gross_total bigint, extra_bonus bigint)
language sql immutable set search_path = '' as $$
  select
    greatest(p_base_reward_total + 1, (p_base_reward_total * p_multiplier_tenths) / 10),
    greatest(p_base_reward_total + 1, (p_base_reward_total * p_multiplier_tenths) / 10) - p_base_reward_total
$$;

revoke all on function wallet_private.compute_promotion_reward_v2(bigint, smallint)
  from public, anon, authenticated, service_role;
```

- [ ] **Step 4: 테스트 실행 배열에 등록**

`run-wallet-sql-tests.mjs` 배열에 `'promotion_campaign_schedule_v2_evaluator.test.sql'` 추가.

- [ ] **Step 5: 통과 확인 후 commit**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
git add supabase/migrations/20260821103000_promotion_schedule_v2_evaluator_and_math.sql \
  supabase/tests/promotion_campaign_schedule_v2_evaluator.test.sql scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add V2 evaluator and integer-multiplier reward math"
```

#### Sub-cycle B: V2 read RPC (필수 반례: surface/V1/flag)

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`supabase/tests/promotion_schedule_v2_surface_contract.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_banner_id integer;
  v_version_id uuid;
  v_payload jsonb;
begin
  update public.wallet_runtime_flags set value_json = 'true', version = version + 1
    where flag_key = 'promotion_surfaces_enabled';

  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_SURFACE', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into public.banner (title, image) values ('{"ko":"t"}'::jsonb, '{"ko":"i"}'::jsonb)
    returning id into v_banner_id;
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge, home_banner_id,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    wallet_private.fixed_db_now() - interval '1 day', wallet_private.fixed_db_now() + interval '6 days',
    'Asia/Seoul', 15, true, false, v_banner_id, '{"ko":"t"}'::jsonb,
    gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
    select v_version_id, extract(isodow from wallet_private.fixed_db_now() at time zone 'Asia/Seoul')::smallint;

  -- flag off (default false): items must stay empty even though a matching version exists
  v_payload := public.get_active_promotion_campaigns_v2('HOME');
  assert v_payload->>'total_count' = '0', 'promotion_schedule_v2_enabled=false must yield empty items';

  update public.wallet_runtime_flags set value_json = 'true', version = version + 1
    where flag_key = 'promotion_schedule_v2_enabled';

  -- HOME surface: item appears (show_home_banner=true)
  v_payload := public.get_active_promotion_campaigns_v2('HOME');
  assert jsonb_array_length(v_payload->'items') = 1, 'HOME must return the badge-off/home-on version';
  assert (v_payload->'items'->0->>'campaign_version_id')::uuid = v_version_id, 'HOME item must be this version';

  -- PAYMENT_BADGE surface: same version must NOT leak (show_payment_badge=false)
  v_payload := public.get_active_promotion_campaigns_v2('PAYMENT_BADGE');
  assert jsonb_array_length(v_payload->'items') = 0, 'PAYMENT_BADGE must not return a home-only version';

  -- invalid surface rejected
  begin
    perform public.get_active_promotion_campaigns_v2('STORE');
    raise exception 'expected PROMOTION_INVALID_SURFACE';
  exception when others then
    if sqlerrm <> 'PROMOTION_INVALID_SURFACE' then raise; end if;
  end;

  -- V1 read RPC must remain unaffected by V2 tables/flags existing
  v_payload := public.get_active_promotion_campaigns('HOME');
  assert v_payload ? 'items' and v_payload ? 'total_count' and v_payload ? 'campaign_owned_home_banner_ids',
    'V1 get_active_promotion_campaigns envelope shape must be unchanged';
end $$;

rollback;
```

- [ ] **Step 2: 실패 확인**

Run: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_schedule_v2_surface_contract.test.sql`
Expected: FAIL — `function public.get_active_promotion_campaigns_v2(unknown) does not exist`

- [ ] **Step 3: 최소 구현**

`supabase/migrations/20260821110000_promotion_schedule_v2_read_rpc.sql`:

```sql
create or replace function wallet_private.promotion_schedule_v2_wire_item(
  v public.promotion_campaign_schedule_versions, p_surface text
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_campaign_wire uuid;
  v_creative jsonb;
  v_dows jsonb;
begin
  select wire_id into v_campaign_wire from wallet_private.promotion_campaign_wire_ids
    where kind = 'CAMPAIGN' and internal_id = v.campaign_id;
  select coalesce(jsonb_agg(w.iso_dow order by w.iso_dow), '[]'::jsonb) into v_dows
    from public.promotion_campaign_schedule_weekdays w where w.campaign_version_id = v.id;

  v_creative := null;
  if p_surface = 'HOME' and v.home_banner_id is not null then
    -- Mirrors the home_creative jsonb shape built by
    -- wallet_private.get_active_promotion_campaigns_v1_unguarded
    -- (supabase/migrations/20260723021059_align_promotion_surface_contract.sql:60-141) — same keys.
    select jsonb_build_object(
      'banner_id', b.id, 'title', b.title, 'image', b.image,
      'thumbnail', b.thumbnail, 'link', b.link, 'duration', b.duration
    ) into v_creative
    from public.banner b where b.id = v.home_banner_id;
  end if;

  return jsonb_build_object(
    'campaign_id', v_campaign_wire,
    'campaign_version_id', v.id,
    'code', (select code from public.promotion_campaigns where id = v.campaign_id),
    'display_name', v.display_name,
    'multiplier_tenths', v.multiplier_tenths,
    'event_starts_at', v.event_starts_at,
    'event_ends_at', v.event_ends_at,
    'repeat_iso_dows', v_dows,
    'home_creative', v_creative
  );
end
$$;

create or replace function public.get_active_promotion_campaigns_v2(p_surface text)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_surfaces_enabled boolean;
  v_v2_enabled boolean;
  v_items jsonb := '[]'::jsonb;
  v_owned jsonb;
  v_at timestamptz := wallet_private.fixed_db_now();
  v_campaign record;
  v_match public.promotion_campaign_schedule_versions;
begin
  if p_surface is null or p_surface not in ('HOME', 'PAYMENT_BADGE') then
    raise exception using errcode = 'P0001', message = 'PROMOTION_INVALID_SURFACE';
  end if;

  select coalesce((value_json #>> '{}')::boolean, false) into v_surfaces_enabled
    from public.wallet_runtime_flags where flag_key = 'promotion_surfaces_enabled';
  select coalesce((value_json #>> '{}')::boolean, false) into v_v2_enabled
    from public.wallet_runtime_flags where flag_key = 'promotion_schedule_v2_enabled';

  if coalesce(v_surfaces_enabled, false) and coalesce(v_v2_enabled, false) then
    for v_campaign in select distinct campaign_id from public.promotion_campaign_schedule_versions loop
      v_match := wallet_private.evaluate_campaign_promotion_schedule_v2(v_campaign.campaign_id, v_at);
      if v_match.id is not null
         and ((p_surface = 'HOME' and v_match.show_home_banner)
              or (p_surface = 'PAYMENT_BADGE' and v_match.show_payment_badge)) then
        v_items := v_items || jsonb_build_array(wallet_private.promotion_schedule_v2_wire_item(v_match, p_surface));
      end if;
    end loop;
  end if;

  select coalesce(jsonb_agg(o.home_banner_id), '[]'::jsonb) into v_owned
    from public.promotion_home_banner_owners o;

  return jsonb_build_object(
    'items', v_items, 'total_count', jsonb_array_length(v_items)::text,
    'next_cursor', null, 'snapshot_at', to_jsonb(v_at),
    'campaign_owned_home_banner_ids', v_owned
  );
end
$$;

revoke all on function public.get_active_promotion_campaigns_v2(text) from public, anon;
grant execute on function public.get_active_promotion_campaigns_v2(text) to authenticated, service_role;

insert into public.wallet_service_rpc_catalog (function_identity, snapshot_reason)
values ('public.get_active_promotion_campaigns_v2(text)', 'promotion schedule v2 read rpc')
on conflict do nothing;
insert into public.wallet_service_rpc_manifest (function_identity, classification)
values ('public.get_active_promotion_campaigns_v2(text)', 'READ')
on conflict (function_identity) do update set classification = excluded.classification;
select wallet_private.assert_wallet_service_rpc_manifest();
```

> `wallet_service_rpc_catalog`/`manifest`의 실제 컬럼명은 `wallet_admin_wrapper_contract.sql:24-34`를 열어 그대로 맞춘다(이 계획은 정확한 컬럼명까지는 조사하지 않았다 — 이름이 다르면 그 파일의 INSERT 문 형태를 그대로 복제한다).

- [ ] **Step 4: 테스트 배열 등록 + 통과 확인**

`run-wallet-sql-tests.mjs`에 `'promotion_schedule_v2_surface_contract.test.sql'` 추가 후:

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260821110000_promotion_schedule_v2_read_rpc.sql \
  supabase/tests/promotion_schedule_v2_surface_contract.test.sql scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add V2 surface-scoped read RPC"
```

---

### Task 3: Supabase admin read/write RPC + grant snapshot (필수 반례: provider timestamp NULL 보류, snapshot 환불)

**Files:**
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821113000_promotion_schedule_v2_admin_read_rpcs.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821120000_promotion_schedule_v2_admin_write_rpc.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/migrations/20260821123000_promotion_schedule_v2_grant_snapshot.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_schedule_v2_admin_read.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_schedule_v2_admin_commands.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/promotion_schedule_v2_grant_snapshot.test.sql`
- Modify: `scripts/safety/run-wallet-sql-tests.mjs`

**Interfaces:**
- Consumes: Task 1/2의 테이블·evaluator·math·wire helper; `wallet_private.begin_admin_command`/`finish_admin_command`/`assert_wallet_admin_actor`/`command_failure_envelope`/`uuid_or_null`/`nonnegative_bigint_or_null` (모두 V1이 이미 정의, `wallet_admin_command_rpcs.sql:86-137`, 시그니처 변경 없이 재사용).
- Produces: `wallet_private.evaluate_promotion_schedule_v2_status(p_campaign_version_id uuid, p_at timestamptz) returns table(is_active boolean, inactive_reason text, next_active_at timestamptz)`, `public.admin_list_promotion_schedule_versions(p_campaign_id uuid) returns jsonb`(actor는 `auth.uid()`로 derive — 명령 RPC와 달리 브라우저가 직접 호출), `public.admin_preview_promotion_schedule_version(p_campaign_version_id uuid, p_at timestamptz default null) returns jsonb`(동일), `public.admin_create_promotion_schedule_version(p_actor_user_id uuid, p_request jsonb) returns public.wallet_stable_command_envelope`(명령 RPC이므로 V1과 동일하게 서버 라우트가 `p_actor_user_id`를 주입), `public.promotion_schedule_v2_grants` 테이블과 `wallet_private.record_promotion_schedule_v2_grant(...)`. Task 4가 `admin_create_promotion_schedule_version`의 요청 필드셋과 도메인 코드를, Task 8이 세 RPC 이름을 그대로 소비한다.
- 신규 permission key: `promotion.schedule_version.create`(Super Admin만, V1의 `promotion.version.create`와 동일 패턴), `promotion.schedule_version.read`(Operator/Finance Admin/Super Admin). `admin_permissions_wallet_key_check` 허용 배열(`wallet_admin_read_rpcs.sql:24-29`)과 `admin_role_permissions` 매핑(`wallet_admin_rbac_and_direct_writer_lockdown.sql:8-27` 패턴)에 추가한다.

#### Sub-cycle A: admin read/preview RPC

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`supabase/tests/promotion_schedule_v2_admin_read.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_campaign_wire uuid;
  v_version_id uuid;
  v_actor uuid := gen_random_uuid();
  v_payload jsonb;
begin
  perform wallet_private.assign_wallet_admin_role(v_actor, 'Super Admin', gen_random_uuid());

  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_ADMIN_READ', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into wallet_private.promotion_campaign_wire_ids (kind, internal_id, wire_id)
    values ('CAMPAIGN', v_campaign_id, gen_random_uuid()) returning wire_id into v_campaign_wire;

  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    wallet_private.fixed_db_now() + interval '1 day', wallet_private.fixed_db_now() + interval '8 days',
    'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb,
    v_actor, 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow) values (v_version_id, 1);

  -- 이 RPC는 auth.uid()로 actor를 derive하므로(위 Step 3 참고), 로컬 psql 테스트에서는
  -- authenticated 세션을 request.jwt.claims로 흉내낸다.
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_actor)::text, true);

  v_payload := public.admin_list_promotion_schedule_versions(v_campaign_wire);
  assert jsonb_array_length(v_payload->'items') = 1, 'admin list must return the created version';
  assert (v_payload->'items'->0->>'campaign_version_id')::uuid = v_version_id, 'listed version id must match';

  -- preview: not yet started -> inactive with a reason and a computed next_active_at
  v_payload := public.admin_preview_promotion_schedule_version(v_version_id, wallet_private.fixed_db_now());
  assert (v_payload->>'is_active')::boolean = false, 'preview before event_starts_at must be inactive';
  assert v_payload->>'inactive_reason' = 'PROMOTION_OUTSIDE_EVENT_RANGE', 'reason must explain why inactive';
  assert v_payload->>'next_active_at' is not null, 'next_active_at must be computed';

  -- non-admin actor rejected
  perform set_config('request.jwt.claims', json_build_object('sub', gen_random_uuid())::text, true);
  begin
    perform public.admin_list_promotion_schedule_versions(v_campaign_wire);
    raise exception 'expected ADMIN_ROLE_REQUIRED';
  exception when others then
    if sqlerrm not like '%insufficient%' and sqlerrm not like '%ADMIN_ROLE_REQUIRED%' then raise; end if;
  end;
  reset role;
end $$;

rollback;
```

- [ ] **Step 2: 실패 확인**

Run: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_schedule_v2_admin_read.test.sql`
Expected: FAIL — `function public.admin_list_promotion_schedule_versions(uuid) does not exist`

> `wallet_private.assign_wallet_admin_role`의 정확한 인자 순서와 `request.jwt.claims`를 통한 `auth.uid()` 시뮬레이션이 이 저장소의 로컬 테스트에서 이미 쓰이는 방식과 다르면, `supabase/tests/` 안의 다른 actor 기반 테스트(예: `wallet_admin_commands.test.sql`)가 실제로 어떻게 actor를 준비하는지 열어 그 패턴을 그대로 따른다.

- [ ] **Step 3: 최소 구현**

`supabase/migrations/20260821113000_promotion_schedule_v2_admin_read_rpcs.sql`:

```sql
create or replace function wallet_private.evaluate_promotion_schedule_v2_status(
  p_campaign_version_id uuid, p_at timestamptz
) returns table(is_active boolean, inactive_reason text, next_active_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
declare
  v public.promotion_campaign_schedule_versions%rowtype;
  v_local_date date;
  v_local_dow smallint;
  v_next_date date;
begin
  select * into v from public.promotion_campaign_schedule_versions where id = p_campaign_version_id;
  if v.id is null then
    return query select false, 'PROMOTION_VERSION_NOT_FOUND', null::timestamptz;
    return;
  end if;
  if not v.enabled then
    return query select false, 'PROMOTION_VERSION_DISABLED', null::timestamptz;
    return;
  end if;
  if p_at < v.event_starts_at or p_at >= v.event_ends_at then
    v_local_date := greatest(v.event_starts_at, p_at) at time zone v.timezone;
    select min(d)::date into v_next_date
    from generate_series(
      (greatest(v.event_starts_at, p_at) at time zone v.timezone)::date,
      (v.event_ends_at at time zone v.timezone)::date - 1, interval '1 day'
    ) d
    where extract(isodow from d) in (
      select iso_dow from public.promotion_campaign_schedule_weekdays where campaign_version_id = v.id
    );
    return query select false, 'PROMOTION_OUTSIDE_EVENT_RANGE',
      case when v_next_date is null or p_at >= v.event_ends_at then null
        else (v_next_date::timestamp at time zone v.timezone) end;
    return;
  end if;
  v_local_date := (p_at at time zone v.timezone)::date;
  v_local_dow := extract(isodow from v_local_date);
  if exists (
    select 1 from public.promotion_campaign_schedule_weekdays w
    where w.campaign_version_id = v.id and w.iso_dow = v_local_dow
  ) then
    return query select true, null::text, null::timestamptz;
    return;
  end if;
  select min(d)::date into v_next_date
  from generate_series(v_local_date, (v.event_ends_at at time zone v.timezone)::date - 1, interval '1 day') d
  where extract(isodow from d) in (
    select iso_dow from public.promotion_campaign_schedule_weekdays where campaign_version_id = v.id
  );
  return query select false, 'PROMOTION_WEEKDAY_NOT_SELECTED_TODAY',
    case when v_next_date is null then null else (v_next_date::timestamp at time zone v.timezone) end;
end
$$;

revoke all on function wallet_private.evaluate_promotion_schedule_v2_status(uuid, timestamptz)
  from public, anon, authenticated, service_role;

create or replace function public.admin_list_promotion_schedule_versions(p_campaign_id uuid)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_campaign bigint;
  v_items jsonb;
begin
  -- 이 RPC는 admin_get_wallet_actor_context()와 동일하게 브라우저가 자신의 인증 세션으로
  -- Postgres를 직접 호출하는 read RPC다(명령 RPC처럼 /api/wallet-ops/commands 서버 라우트를
  -- 거치지 않는다) — actor를 요청 바디로 받지 않고 auth.uid()로 derive한다.
  perform wallet_private.assert_wallet_admin_actor(auth.uid(), 'promotion.schedule_version.read');
  select internal_id into v_campaign from wallet_private.promotion_campaign_wire_ids
    where kind = 'CAMPAIGN' and wire_id = p_campaign_id;
  if v_campaign is null then
    return jsonb_build_object('items', '[]'::jsonb, 'total_count', '0',
      'snapshot_at', to_jsonb(wallet_private.fixed_db_now()));
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'campaign_version_id', v.id, 'version', v.version::text,
      'effective_from', v.effective_from, 'enabled', v.enabled,
      'event_starts_at', v.event_starts_at, 'event_ends_at', v.event_ends_at,
      'multiplier_tenths', v.multiplier_tenths,
      'show_home_banner', v.show_home_banner, 'show_payment_badge', v.show_payment_badge,
      'display_name', v.display_name,
      'repeat_iso_dows', (
        select coalesce(jsonb_agg(w.iso_dow order by w.iso_dow), '[]'::jsonb)
        from public.promotion_campaign_schedule_weekdays w where w.campaign_version_id = v.id
      )
    ) order by v.version desc), '[]'::jsonb)
  into v_items
  from public.promotion_campaign_schedule_versions v where v.campaign_id = v_campaign;
  return jsonb_build_object('items', v_items, 'total_count', jsonb_array_length(v_items)::text,
    'snapshot_at', to_jsonb(wallet_private.fixed_db_now()));
end
$$;

create or replace function public.admin_preview_promotion_schedule_version(
  p_campaign_version_id uuid, p_at timestamptz default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_status record;
begin
  perform wallet_private.assert_wallet_admin_actor(auth.uid(), 'promotion.schedule_version.read');
  select * into v_status from wallet_private.evaluate_promotion_schedule_v2_status(
    p_campaign_version_id, coalesce(p_at, wallet_private.fixed_db_now())
  );
  return jsonb_build_object(
    'is_active', v_status.is_active, 'inactive_reason', v_status.inactive_reason,
    'next_active_at', to_jsonb(v_status.next_active_at),
    'snapshot_at', to_jsonb(wallet_private.fixed_db_now())
  );
end
$$;

alter function public.admin_list_promotion_schedule_versions(uuid) owner to wallet_command_owner;
revoke all on function public.admin_list_promotion_schedule_versions(uuid) from public, anon, service_role;
grant execute on function public.admin_list_promotion_schedule_versions(uuid) to authenticated;

alter function public.admin_preview_promotion_schedule_version(uuid, timestamptz) owner to wallet_command_owner;
revoke all on function public.admin_preview_promotion_schedule_version(uuid, timestamptz) from public, anon, service_role;
grant execute on function public.admin_preview_promotion_schedule_version(uuid, timestamptz) to authenticated;

insert into public.admin_permissions (permission_key) values
  ('promotion.schedule_version.read'), ('promotion.schedule_version.create')
on conflict do nothing;
insert into public.admin_role_permissions (role_name, permission_key) values
  ('Operator', 'promotion.schedule_version.read'),
  ('Finance Admin', 'promotion.schedule_version.read'),
  ('Super Admin', 'promotion.schedule_version.read'),
  ('Super Admin', 'promotion.schedule_version.create')
on conflict do nothing;
```

> `admin_permissions`/`admin_role_permissions`의 정확한 컬럼명과 `admin_permissions_wallet_key_check` CHECK 허용 배열은 `wallet_admin_read_rpcs.sql:24-29`를 열어 그대로 맞춘다 — 이 CHECK에 새 두 키를 추가하지 않으면 위 INSERT가 거부된다.

- [ ] **Step 4: 테스트 배열 등록 + 통과 확인 + commit**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
git add supabase/migrations/20260821113000_promotion_schedule_v2_admin_read_rpcs.sql \
  supabase/tests/promotion_schedule_v2_admin_read.test.sql scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add V2 admin list/preview RPCs with inactive-reason status"
```

#### Sub-cycle B: admin write RPC

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`supabase/tests/promotion_schedule_v2_admin_commands.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_campaign_wire uuid;
  v_banner_id integer;
  v_banner_wire uuid;
  v_actor uuid := gen_random_uuid();
  v_request_id uuid := gen_random_uuid();
  v_request jsonb;
  v_result public.wallet_stable_command_envelope;
begin
  perform wallet_private.assign_wallet_admin_role(v_actor, 'Super Admin', gen_random_uuid());
  update public.wallet_runtime_flags set value_json = 'true', version = version + 1
    where flag_key = 'promotion_surfaces_enabled';

  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_ADMIN_CMD', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into wallet_private.promotion_campaign_wire_ids (kind, internal_id, wire_id)
    values ('CAMPAIGN', v_campaign_id, gen_random_uuid()) returning wire_id into v_campaign_wire;
  insert into public.banner (title, image) values ('{"ko":"t"}'::jsonb, '{"ko":"i"}'::jsonb)
    returning id into v_banner_id;
  insert into wallet_private.promotion_campaign_wire_ids (kind, internal_id, wire_id)
    values ('BANNER', v_banner_id, gen_random_uuid()) returning wire_id into v_banner_wire;

  v_request := jsonb_build_object(
    'request_id', v_request_id, 'campaign_id', v_campaign_wire, 'expected_latest_version', '0',
    'enabled', true, 'event_starts_at', '2026-09-07T00:00:00+09:00', 'event_ends_at', '2026-09-14T00:00:00+09:00',
    'repeat_iso_dows', jsonb_build_array(1,3,5), 'multiplier_tenths', 15,
    'display_name', jsonb_build_object('ko','추석 캔디 부스트'),
    'show_home_banner', true, 'show_payment_badge', true, 'home_banner_id', v_banner_wire,
    'reason', '추석 프로모션', 'cs_ticket', 'CS-100'
  );

  -- reject: end before start
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    v_request || jsonb_build_object('event_ends_at', '2026-09-01T00:00:00+09:00'));
  assert v_result.domain_code = 'PROMOTION_INVALID_EVENT_RANGE', format('expected PROMOTION_INVALID_EVENT_RANGE, got %s', v_result.domain_code);

  -- reject: no weekday
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    v_request || jsonb_build_object('repeat_iso_dows', '[]'::jsonb));
  assert v_result.domain_code = 'PROMOTION_WEEKDAY_REQUIRED', format('expected PROMOTION_WEEKDAY_REQUIRED, got %s', v_result.domain_code);

  -- reject: multiplier out of range
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    v_request || jsonb_build_object('multiplier_tenths', 31));
  assert v_result.domain_code = 'PROMOTION_MULTIPLIER_INVALID', format('expected PROMOTION_MULTIPLIER_INVALID, got %s', v_result.domain_code);

  -- reject: HOME on but no banner
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    (v_request - 'home_banner_id') || jsonb_build_object('home_banner_id', null));
  assert v_result.domain_code = 'PROMOTION_HOME_BANNER_REQUIRED', format('expected PROMOTION_HOME_BANNER_REQUIRED, got %s', v_result.domain_code);

  -- reject: blank reason/cs_ticket
  v_result := public.admin_create_promotion_schedule_version(v_actor, v_request || jsonb_build_object('cs_ticket', '  '));
  assert v_result.domain_code = 'ADMIN_REASON_TICKET_REQUIRED', format('expected ADMIN_REASON_TICKET_REQUIRED, got %s', v_result.domain_code);

  -- reject: unknown field (no bps/rollout_policy/weekly fields accepted)
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    v_request || jsonb_build_object('extra_bonus_bps', 5000));
  assert v_result.domain_code = 'ADMIN_UNKNOWN_REQUEST_FIELD', format('expected ADMIN_UNKNOWN_REQUEST_FIELD, got %s', v_result.domain_code);

  -- reject: non-admin actor
  v_result := public.admin_create_promotion_schedule_version(gen_random_uuid(), v_request);
  assert v_result.domain_code = 'ADMIN_ROLE_REQUIRED', format('expected ADMIN_ROLE_REQUIRED, got %s', v_result.domain_code);

  -- success
  v_result := public.admin_create_promotion_schedule_version(v_actor, v_request);
  assert v_result.ok, format('expected success, got domain_code=%s', v_result.domain_code);
  assert (v_result.payload->>'version') = '1', 'first version must be 1';

  -- idempotent replay with the same request_id + identical payload returns the same result
  v_result := public.admin_create_promotion_schedule_version(v_actor, v_request);
  assert v_result.ok and (v_result.payload->>'version') = '1', 'replay must return the original result, not a new version';

  -- optimistic concurrency: stale expected_latest_version rejected
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    (v_request || jsonb_build_object('request_id', gen_random_uuid())));
  assert v_result.domain_code = 'PROMOTION_VERSION_CONFLICT', format('expected PROMOTION_VERSION_CONFLICT, got %s', v_result.domain_code);

  -- safety stop: promotion_surfaces_enabled=false blocks creation
  update public.wallet_runtime_flags set value_json = 'false', version = version + 1
    where flag_key = 'promotion_surfaces_enabled';
  v_result := public.admin_create_promotion_schedule_version(v_actor,
    v_request || jsonb_build_object('request_id', gen_random_uuid(), 'expected_latest_version', '1'));
  assert v_result.domain_code = 'PROMOTION_SURFACES_DISABLED', format('expected PROMOTION_SURFACES_DISABLED, got %s', v_result.domain_code);
end $$;

rollback;
```

- [ ] **Step 2: 실패 확인**

Run: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_schedule_v2_admin_commands.test.sql`
Expected: FAIL — `function public.admin_create_promotion_schedule_version(uuid,jsonb) does not exist`

- [ ] **Step 3: 최소 구현**

`supabase/migrations/20260821120000_promotion_schedule_v2_admin_write_rpc.sql`:

```sql
create or replace function wallet_private.admin_create_promotion_schedule_version_internal(
  p_actor_user_id uuid, p_request jsonb
) returns public.wallet_stable_command_envelope
language plpgsql security definer set search_path = '' as $$
declare
  c record;
  campaign bigint;
  expected bigint;
  latest bigint;
  banner integer;
  new_id uuid;
  dow_val integer;
  v_surfaces_enabled boolean;
  r public.wallet_stable_command_envelope;
  audit uuid;
begin
  begin
    select * into c from wallet_private.begin_admin_command(
      p_actor_user_id, 'CREATE_PROMOTION_SCHEDULE_VERSION', 'promotion.schedule_version.create', p_request
    );
  exception
    when insufficient_privilege then return wallet_private.command_failure_envelope('ADMIN_ROLE_REQUIRED', false);
    when invalid_parameter_value then return wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST', false);
  end;
  if c.prior is distinct from null::public.wallet_stable_command_envelope then return c.prior; end if;

  if exists (
    select 1 from jsonb_object_keys(p_request) k
    where k not in (
      'request_id','campaign_id','expected_latest_version','enabled',
      'event_starts_at','event_ends_at','repeat_iso_dows','multiplier_tenths',
      'display_name','show_home_banner','show_payment_badge','home_banner_id',
      'reason','cs_ticket'
    )
  ) then
    return wallet_private.command_failure_envelope('ADMIN_UNKNOWN_REQUEST_FIELD', false);
  end if;

  if nullif(btrim(p_request->>'reason'), '') is null then
    return wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST', false);
  end if;
  if nullif(btrim(p_request->>'cs_ticket'), '') is null then
    return wallet_private.command_failure_envelope('ADMIN_REASON_TICKET_REQUIRED', false);
  end if;

  select internal_id into campaign from wallet_private.promotion_campaign_wire_ids
    where kind = 'CAMPAIGN' and wire_id = wallet_private.uuid_or_null(p_request->>'campaign_id');
  expected := wallet_private.nonnegative_bigint_or_null(p_request->>'expected_latest_version');
  if campaign is null or expected is null
     or jsonb_typeof(p_request->'display_name') <> 'object'
     or nullif(btrim(p_request->'display_name'->>'ko'), '') is null
  then
    return wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST', false);
  end if;

  if (p_request->>'event_starts_at')::timestamptz >= (p_request->>'event_ends_at')::timestamptz then
    return wallet_private.command_failure_envelope('PROMOTION_INVALID_EVENT_RANGE', false);
  end if;

  if jsonb_typeof(p_request->'repeat_iso_dows') <> 'array' or jsonb_array_length(p_request->'repeat_iso_dows') = 0 then
    return wallet_private.command_failure_envelope('PROMOTION_WEEKDAY_REQUIRED', false);
  end if;
  for dow_val in select (value #>> '{}')::integer from jsonb_array_elements(p_request->'repeat_iso_dows') loop
    if dow_val < 1 or dow_val > 7 then
      return wallet_private.command_failure_envelope('PROMOTION_WEEKDAY_REQUIRED', false);
    end if;
  end loop;

  if (p_request->>'multiplier_tenths')::integer not between 11 and 30 then
    return wallet_private.command_failure_envelope('PROMOTION_MULTIPLIER_INVALID', false);
  end if;

  if (p_request->>'show_home_banner')::boolean and wallet_private.uuid_or_null(p_request->>'home_banner_id') is null then
    return wallet_private.command_failure_envelope('PROMOTION_HOME_BANNER_REQUIRED', false);
  end if;
  if not (p_request->>'show_home_banner')::boolean and p_request->>'home_banner_id' is not null then
    return wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST', false);
  end if;

  select coalesce((value_json #>> '{}')::boolean, false) into v_surfaces_enabled
    from public.wallet_runtime_flags where flag_key = 'promotion_surfaces_enabled';
  if not coalesce(v_surfaces_enabled, false) then
    return wallet_private.command_failure_envelope('PROMOTION_SURFACES_DISABLED', false);
  end if;

  banner := null;
  if (p_request->>'show_home_banner')::boolean then
    select internal_id into banner from wallet_private.promotion_campaign_wire_ids
      where kind = 'BANNER' and wire_id = wallet_private.uuid_or_null(p_request->>'home_banner_id');
    if banner is null then
      return wallet_private.command_failure_envelope('PROMOTION_HOME_BANNER_REQUIRED', false);
    end if;
  end if;

  perform pg_advisory_xact_lock(hashtextextended('promotion:campaign:' || campaign, 0));
  select coalesce(max(version), 0) into latest
    from public.promotion_campaign_schedule_versions where campaign_id = campaign;
  if latest <> expected then
    r := wallet_private.command_failure_envelope('PROMOTION_VERSION_CONFLICT', false);
  else
    begin
      insert into public.promotion_campaign_schedule_versions (
        campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
        timezone, multiplier_tenths, show_home_banner, show_payment_badge, home_banner_id,
        display_name, changed_by, change_reason, cs_ticket
      ) values (
        campaign, latest + 1, wallet_private.fixed_db_now(), (p_request->>'enabled')::boolean,
        (p_request->>'event_starts_at')::timestamptz, (p_request->>'event_ends_at')::timestamptz,
        'Asia/Seoul', (p_request->>'multiplier_tenths')::integer,
        (p_request->>'show_home_banner')::boolean, (p_request->>'show_payment_badge')::boolean, banner,
        p_request->'display_name', p_actor_user_id, btrim(p_request->>'reason'), btrim(p_request->>'cs_ticket')
      ) returning id into new_id;

      insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
      select distinct new_id, (value #>> '{}')::integer from jsonb_array_elements(p_request->'repeat_iso_dows') as value;

      audit := gen_random_uuid();
      r := (true, null, false, null, audit,
        jsonb_build_object('campaign_version_id', new_id, 'version', (latest + 1)::text), null
      )::public.wallet_stable_command_envelope;
    exception
      when check_violation or foreign_key_violation then r := wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST', false);
      when unique_violation then r := wallet_private.command_failure_envelope('PROMOTION_VERSION_CONFLICT', false);
    end;
  end if;
  return wallet_private.finish_admin_command(p_actor_user_id, 'CREATE_PROMOTION_SCHEDULE_VERSION', c.request_id, c.request_hash, r);
end
$$;

create or replace function public.admin_create_promotion_schedule_version(p_actor_user_id uuid, p_request jsonb)
returns public.wallet_stable_command_envelope
language sql security definer set search_path = '' as $$
  select wallet_private.admin_create_promotion_schedule_version_internal(p_actor_user_id, p_request)
$$;

alter function public.admin_create_promotion_schedule_version(uuid, jsonb) owner to wallet_command_owner;
revoke all on function public.admin_create_promotion_schedule_version(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.admin_create_promotion_schedule_version(uuid, jsonb) to service_role;
```

- [ ] **Step 4: 테스트 배열 등록 + 통과 확인 + commit**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
git add supabase/migrations/20260821120000_promotion_schedule_v2_admin_write_rpc.sql \
  supabase/tests/promotion_schedule_v2_admin_commands.test.sql scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add V2 admin schedule version create command"
```

#### Sub-cycle C: grant snapshot — provider timestamp NULL 보류 + 환불 불변성

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`supabase/tests/promotion_schedule_v2_grant_snapshot.test.sql`:

```sql
begin;

do $$
declare
  v_campaign_id bigint;
  v_version_id uuid;
  v_snapshot_id uuid := gen_random_uuid();
  v_grant record;
  v_gross bigint; v_extra bigint;
begin
  insert into public.promotion_campaigns (code, kind) values ('SCHED_V2_GRANT', 'PURCHASE_BONUS')
    returning id into v_campaign_id;
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 1, wallet_private.fixed_db_now(), true,
    wallet_private.fixed_db_now() - interval '1 day', wallet_private.fixed_db_now() + interval '6 days',
    'Asia/Seoul', 15, false, true, '{"ko":"t"}'::jsonb, gen_random_uuid(), 'setup', 'CS-1'
  ) returning id into v_version_id;
  insert into public.promotion_campaign_schedule_weekdays (campaign_version_id, iso_dow)
    select v_version_id, extract(isodow from wallet_private.fixed_db_now() at time zone 'Asia/Seoul')::smallint;

  -- provider 발생 시각이 NULL이면 처리 시각으로 대체하지 않고 보류한다
  begin
    perform wallet_private.record_promotion_schedule_v2_grant(
      v_snapshot_id, v_version_id, 15, null
    );
    raise exception 'expected PROMOTION_TIME_UNVERIFIABLE for null provider timestamp';
  exception when others then
    if sqlerrm <> 'PROMOTION_TIME_UNVERIFIABLE' then raise; end if;
  end;
  assert not exists (select 1 from public.promotion_schedule_v2_grants where purchase_snapshot_id = v_snapshot_id),
    'a held (unverifiable) grant must not insert any snapshot row';

  -- 검증된 provider 시각이 있으면 정수 배수 math로 기록된다
  v_grant := wallet_private.record_promotion_schedule_v2_grant(
    v_snapshot_id, v_version_id, 15, wallet_private.fixed_db_now()
  );
  assert v_grant.gross_total = 22 and v_grant.extra_bonus = 7,
    format('expected gross=22/extra=7 for base=15,tenths=15, got gross=%s/extra=%s', v_grant.gross_total, v_grant.extra_bonus);

  -- 같은 snapshot_id로 재호출(replay)해도 새 행이 늘지 않는다
  perform wallet_private.record_promotion_schedule_v2_grant(v_snapshot_id, v_version_id, 15, wallet_private.fixed_db_now());
  assert (select count(*) from public.promotion_schedule_v2_grants where purchase_snapshot_id = v_snapshot_id) = 1,
    'replay with the same purchase_snapshot_id must not duplicate the grant row';

  -- 환불 불변성: 이후에 같은 campaign의 새 version(배수 변경)이 생겨도 기존 grant snapshot 값은 그대로다
  insert into public.promotion_campaign_schedule_versions (
    campaign_id, version, effective_from, enabled, event_starts_at, event_ends_at,
    timezone, multiplier_tenths, show_home_banner, show_payment_badge,
    display_name, changed_by, change_reason, cs_ticket
  ) values (
    v_campaign_id, 2, wallet_private.fixed_db_now(), true,
    wallet_private.fixed_db_now(), wallet_private.fixed_db_now() + interval '6 days',
    'Asia/Seoul', 30, false, true, '{"ko":"t2"}'::jsonb, gen_random_uuid(), 'multiplier bumped', 'CS-2'
  );
  select * into v_grant from public.promotion_schedule_v2_grants where purchase_snapshot_id = v_snapshot_id;
  assert v_grant.multiplier_tenths = 15 and v_grant.gross_total = 22 and v_grant.extra_bonus = 7,
    'existing grant snapshot must be unaffected by a later version change on the same campaign';

  -- append-only: grants 테이블도 UPDATE/DELETE 거부
  begin
    update public.promotion_schedule_v2_grants set extra_bonus = 0 where purchase_snapshot_id = v_snapshot_id;
    raise exception 'expected immutability violation on grants update';
  exception when others then
    if sqlerrm <> 'promotion_schedule_v2_grants is immutable' then raise; end if;
  end;
end $$;

rollback;
```

- [ ] **Step 2: 실패 확인**

Run: `psql "postgresql://postgres:postgres@localhost:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/promotion_schedule_v2_grant_snapshot.test.sql`
Expected: FAIL — `function wallet_private.record_promotion_schedule_v2_grant(...) does not exist`

- [ ] **Step 3: 최소 구현**

`supabase/migrations/20260821123000_promotion_schedule_v2_grant_snapshot.sql`:

```sql
create table public.promotion_schedule_v2_grants (
  id uuid primary key default gen_random_uuid(),
  campaign_version_id uuid not null references public.promotion_campaign_schedule_versions(id),
  purchase_snapshot_id uuid not null,
  base_reward_total bigint not null check (base_reward_total > 0),
  multiplier_tenths smallint not null check (multiplier_tenths between 11 and 30),
  gross_total bigint not null,
  extra_bonus bigint not null,
  evaluated_at timestamptz not null,
  created_at timestamptz not null default wallet_private.fixed_db_now(),
  unique (purchase_snapshot_id),
  check (gross_total = extra_bonus + base_reward_total)
);
alter table public.promotion_schedule_v2_grants owner to wallet_command_owner;
revoke all on table public.promotion_schedule_v2_grants from public, anon, authenticated, service_role;

create trigger promotion_schedule_v2_grants_immutable
  before update or delete on public.promotion_schedule_v2_grants
  for each row execute function wallet_private.reject_immutable_change();
create trigger promotion_schedule_v2_grants_truncate_immutable
  before truncate on public.promotion_schedule_v2_grants
  for each statement execute function wallet_private.reject_immutable_change();

-- p_verified_occurred_at이 NULL이면(provider 시각 미검증) 처리 시각으로 대체하지 않고
-- PROMOTION_TIME_UNVERIFIABLE 예외로 보류한다 — snapshot row를 절대 만들지 않는다.
-- purchase_snapshot_id는 unique이므로 재호출(replay)은 기존 행을 그대로 반환한다(중복 지급 방지).
-- 반환된 행은 이후 어떤 version 변경에도 영향받지 않는다(append-only + 값 자체를 이 시점에 고정).
create or replace function wallet_private.record_promotion_schedule_v2_grant(
  p_purchase_snapshot_id uuid, p_campaign_version_id uuid,
  p_base_reward_total bigint, p_verified_occurred_at timestamptz
) returns public.promotion_schedule_v2_grants
language plpgsql security definer set search_path = '' as $$
declare
  v_existing public.promotion_schedule_v2_grants%rowtype;
  v_gross bigint; v_extra bigint;
  v_multiplier smallint;
begin
  select * into v_existing from public.promotion_schedule_v2_grants where purchase_snapshot_id = p_purchase_snapshot_id;
  if v_existing.id is not null then return v_existing; end if;

  if p_verified_occurred_at is null then
    raise exception using errcode = 'P0001', message = 'PROMOTION_TIME_UNVERIFIABLE';
  end if;

  select multiplier_tenths into v_multiplier from public.promotion_campaign_schedule_versions
    where id = p_campaign_version_id;
  if v_multiplier is null then
    raise exception using errcode = 'P0001', message = 'PROMOTION_VERSION_NOT_FOUND';
  end if;

  select gross_total, extra_bonus into v_gross, v_extra
    from wallet_private.compute_promotion_reward_v2(p_base_reward_total, v_multiplier);

  insert into public.promotion_schedule_v2_grants (
    campaign_version_id, purchase_snapshot_id, base_reward_total,
    multiplier_tenths, gross_total, extra_bonus, evaluated_at
  ) values (
    p_campaign_version_id, p_purchase_snapshot_id, p_base_reward_total,
    v_multiplier, v_gross, v_extra, p_verified_occurred_at
  ) returning * into v_existing;
  return v_existing;
end
$$;

revoke all on function wallet_private.record_promotion_schedule_v2_grant(uuid, uuid, bigint, timestamptz)
  from public, anon, authenticated, service_role;
grant execute on function wallet_private.record_promotion_schedule_v2_grant(uuid, uuid, bigint, timestamptz)
  to wallet_command_owner;
```

> 이 함수를 실제 구매 정산 디스패처에서 호출하는 배선은 Global Constraints에 명시한 대로 이 계획 범위 밖이다 — 여기서는 함수 자체의 정확성(NULL 보류, 정수 math, 환불 불변성, 멱등 replay)만 완전히 구현·테스트한다.

- [ ] **Step 4: 테스트 배열 등록 + 통과 확인 + commit**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
git add supabase/migrations/20260821123000_promotion_schedule_v2_grant_snapshot.sql \
  supabase/tests/promotion_schedule_v2_grant_snapshot.test.sql scripts/safety/run-wallet-sql-tests.mjs
git commit -m "feat(promotion): add V2 grant snapshot with unverifiable-time hold"
```

---

### Task 4: Admin — 오류 매핑 + command/parser 계층 + API route allowlist

**Files:**
- Create: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/lib/wallet-ops/errors.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/lib/wallet-ops/__tests__/errors.test.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/lib/wallet-ops/commands.ts` (새 타입/빌더/executor 메서드 추가, 기존 `PromotionVersionInput`/`buildPromotionVersionRequest`/`createPromotionVersion`은 유지)
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/lib/wallet-ops/client.ts` (새 parser/read 메서드 추가)
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/lib/wallet-ops/command-route-handler.ts:4-14` (`ACTIONS` allowlist에 항목 추가)
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/__tests__/wallet-ops/commands.test.ts`, `commands-route.test.ts`

**Interfaces:**
- Consumes: Task 3의 RPC 이름(`admin_create_promotion_schedule_version`, `admin_list_promotion_schedule_versions`, `admin_preview_promotion_schedule_version`)과 요청/응답 필드셋, 도메인 코드 목록.
- Produces: `PromotionScheduleVersionInput` 타입, `buildPromotionScheduleVersionRequest(input, requestId)`, `WalletCommandExecutor.createPromotionScheduleVersion(input, requestId?)`, `resolvePromotionScheduleError(code)`. Task 5가 이 세 가지를 그대로 소비한다.

#### Sub-cycle A: 오류 매핑

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`lib/wallet-ops/__tests__/errors.test.ts`:

```ts
import { resolvePromotionScheduleError } from '../errors';

describe('resolvePromotionScheduleError', () => {
  it('maps known domain codes to Korean messages', () => {
    expect(resolvePromotionScheduleError('PROMOTION_WEEKDAY_REQUIRED')).toBe('요일을 하나 이상 선택하세요.');
    expect(resolvePromotionScheduleError('PROMOTION_SURFACES_DISABLED')).toBe(
      '프로모션 노출이 안전 정지 상태입니다. 새 버전을 만들 수 없습니다.',
    );
  });

  it('falls back to the raw code for unknown codes without inventing text', () => {
    expect(resolvePromotionScheduleError('BACKEND_RPC_FAILED')).toBe('BACKEND_RPC_FAILED');
  });

  it('handles null/undefined', () => {
    expect(resolvePromotionScheduleError(null)).toBe('알 수 없는 오류가 발생했습니다.');
    expect(resolvePromotionScheduleError(undefined)).toBe('알 수 없는 오류가 발생했습니다.');
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `npm test -- lib/wallet-ops/__tests__/errors.test.ts --runInBand`
Expected: FAIL — `Cannot find module '../errors'`

- [ ] **Step 3: 최소 구현**

`lib/wallet-ops/errors.ts`:

```ts
export type PromotionScheduleErrorEntry = { field?: string; message: string };

export const PROMOTION_SCHEDULE_ERROR_MESSAGES: Record<string, PromotionScheduleErrorEntry> = {
  PROMOTION_INVALID_EVENT_RANGE: { field: 'eventEndsAt', message: '종료 일시는 시작 일시보다 뒤여야 합니다.' },
  PROMOTION_WEEKDAY_REQUIRED: { field: 'repeatIsoDows', message: '요일을 하나 이상 선택하세요.' },
  PROMOTION_MULTIPLIER_INVALID: { field: 'multiplierTenths', message: '배수는 1.1x~3.0x 사이여야 합니다.' },
  PROMOTION_HOME_BANNER_REQUIRED: { field: 'homeBannerId', message: 'HOME 배너를 켰다면 배너를 선택하세요.' },
  PROMOTION_VERSION_CONFLICT: { message: '다른 운영자가 먼저 버전을 생성했습니다. 최신 값을 다시 불러옵니다.' },
  ADMIN_ROLE_REQUIRED: { message: '이 작업을 수행할 권한이 없습니다.' },
  ADMIN_REASON_TICKET_REQUIRED: { message: '사유와 CS 티켓을 입력하세요.' },
  ADMIN_UNKNOWN_REQUEST_FIELD: { message: '요청 형식이 올바르지 않습니다. 새로고침 후 다시 시도하세요.' },
  PROMOTION_SURFACES_DISABLED: { message: '프로모션 노출이 안전 정지 상태입니다. 새 버전을 만들 수 없습니다.' },
};

export function resolvePromotionScheduleError(domainCodeOrMessage: string | null | undefined): string {
  if (!domainCodeOrMessage) return '알 수 없는 오류가 발생했습니다.';
  return PROMOTION_SCHEDULE_ERROR_MESSAGES[domainCodeOrMessage]?.message ?? domainCodeOrMessage;
}
```

- [ ] **Step 4: 통과 확인 + commit**

```bash
npm test -- lib/wallet-ops/__tests__/errors.test.ts --runInBand
git add lib/wallet-ops/errors.ts lib/wallet-ops/__tests__/errors.test.ts
git commit -m "feat(wallet): map promotion schedule v2 domain codes to messages"
```

#### Sub-cycle B: command builder/executor + read parser

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`__tests__/wallet-ops/commands.test.ts`에 추가(기존 `describe`/`import` 블록 옆에 새 블록으로):

```ts
import { buildPromotionScheduleVersionRequest } from '../../lib/wallet-ops/commands';

describe('buildPromotionScheduleVersionRequest', () => {
  const base = {
    campaignId: '11111111-1111-4111-8111-111111111111',
    expectedLatestVersion: '0',
    enabled: true,
    eventStartsAt: '2026-09-07T00:00:00+09:00',
    eventEndsAt: '2026-09-14T00:00:00+09:00',
    repeatIsoDows: [1, 3, 5],
    multiplierTenths: 15,
    displayName: { ko: '추석 캔디 부스트' },
    showHomeBanner: true,
    showPaymentBadge: true,
    homeBannerId: '22222222-2222-4222-8222-222222222222',
    reason: '추석 프로모션',
    csTicket: 'CS-100',
  };

  it('builds the exact V2 wire shape with no bps/rollout_policy/weekly fields', () => {
    const request = buildPromotionScheduleVersionRequest(base, 'req-1');
    expect(request).toEqual({
      request_id: 'req-1',
      campaign_id: base.campaignId,
      expected_latest_version: 0,
      enabled: true,
      event_starts_at: base.eventStartsAt,
      event_ends_at: base.eventEndsAt,
      repeat_iso_dows: [1, 3, 5],
      multiplier_tenths: 15,
      display_name: { ko: '추석 캔디 부스트' },
      show_home_banner: true,
      show_payment_badge: true,
      home_banner_id: base.homeBannerId,
      reason: base.reason,
      cs_ticket: base.csTicket,
    });
    expect(request).not.toHaveProperty('rollout_policy');
    expect(request).not.toHaveProperty('extra_bonus_bps');
    expect(request).not.toHaveProperty('weekly_start_isodow');
  });

  it('rejects showHomeBanner=true with a null homeBannerId', () => {
    expect(() => buildPromotionScheduleVersionRequest({ ...base, homeBannerId: null }, 'req-2')).toThrow(
      'homeBannerId',
    );
  });

  it('rejects an empty repeatIsoDows array', () => {
    expect(() => buildPromotionScheduleVersionRequest({ ...base, repeatIsoDows: [] }, 'req-3')).toThrow(
      'repeatIsoDows',
    );
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `npm test -- __tests__/wallet-ops/commands.test.ts --runInBand`
Expected: FAIL — `buildPromotionScheduleVersionRequest is not exported`

- [ ] **Step 3: 최소 구현**

`lib/wallet-ops/commands.ts`에 추가(기존 `PromotionVersionInput`/`buildPromotionVersionRequest` 바로 아래, 삭제하지 않고 나란히):

```ts
export type PromotionScheduleVersionInput = {
  campaignId: string;
  expectedLatestVersion: string;
  enabled: boolean;
  eventStartsAt: string;
  eventEndsAt: string;
  repeatIsoDows: number[];
  multiplierTenths: number;
  displayName: JsonObject;
  showHomeBanner: boolean;
  showPaymentBadge: boolean;
  homeBannerId: string | null;
  reason: string;
  csTicket: string;
};

export function buildPromotionScheduleVersionRequest(input: PromotionScheduleVersionInput, requestId: string) {
  if (input.showHomeBanner && input.homeBannerId === null) {
    throw new CommandValidationError('homeBannerId', 'is required');
  }
  if (!input.showHomeBanner && input.homeBannerId !== null) {
    throw new CommandValidationError('homeBannerId', 'must be null when showHomeBanner is false');
  }
  if (input.repeatIsoDows.length === 0) {
    throw new CommandValidationError('repeatIsoDows', 'must include at least one weekday');
  }
  return {
    request_id: requireUuid(requestId, 'requestId'),
    campaign_id: requireUuid(input.campaignId, 'campaignId'),
    expected_latest_version: requireUnsigned(input.expectedLatestVersion, 'expectedLatestVersion'),
    enabled: input.enabled,
    event_starts_at: requireText(input.eventStartsAt, 'eventStartsAt'),
    event_ends_at: requireText(input.eventEndsAt, 'eventEndsAt'),
    repeat_iso_dows: input.repeatIsoDows,
    multiplier_tenths: input.multiplierTenths,
    display_name: input.displayName,
    show_home_banner: input.showHomeBanner,
    show_payment_badge: input.showPaymentBadge,
    home_banner_id: input.homeBannerId === null ? null : requireUuid(input.homeBannerId, 'homeBannerId'),
    ...audit(input.reason, input.csTicket),
  };
}
```

`WalletCommandExecutor` 클래스 안, 기존 `createPromotionVersion` 메서드 바로 아래에 추가:

```ts
createPromotionScheduleVersion(input: PromotionScheduleVersionInput, requestId?: string) {
  return this.submit('createPromotionScheduleVersion', (id) => buildPromotionScheduleVersionRequest(input, id), requestId);
}
```

`requireUnsigned(input.expectedLatestVersion, 'expectedLatestVersion')`는 기존 `buildPromotionVersionRequest`(`commands.ts:169-191`)의 `expected_latest_version` 처리와 정확히 같은 호출이므로 반환 타입은 자동으로 V1과 동일하게 맞는다 — 위 테스트의 `expected_latest_version: 0`이 실행 시 실제 타입과 다르면(예: 문자열 `'0'`이어야 하면) Step 2에서 그 타입 그대로 테스트를 고쳐 다시 실행한다.

- [ ] **Step 4: 읽기 파서 추가 — `client.ts`**

`lib/wallet-ops/client.ts`에 `campaignVersion()`/`CAMPAIGN_VERSION_KEYS` 근처에 새 exact-key 상수와 파서를 추가(기존 V1 파서는 수정하지 않는다):

```ts
const CAMPAIGN_SCHEDULE_VERSION_KEYS = [
  'campaign_version_id', 'version', 'effective_from', 'enabled',
  'event_starts_at', 'event_ends_at', 'multiplier_tenths',
  'show_home_banner', 'show_payment_badge', 'display_name', 'repeat_iso_dows',
] as const;

function campaignScheduleVersion(row: unknown) {
  return requireExactKeys(row, CAMPAIGN_SCHEDULE_VERSION_KEYS);
}
```

`WalletOpsClient` 클래스에 `campaignVersions()`/`previewCampaign()` 바로 아래 추가:

```ts
async campaignScheduleVersions(campaignId: string) {
  const { data, error } = await this.client.rpc('admin_list_promotion_schedule_versions', { p_campaign_id: campaignId });
  if (error) throw new WalletCommandTransportError(error.message, false);
  const { items, ...rest } = data as { items: unknown[] } & Record<string, unknown>;
  return { items: items.map(campaignScheduleVersion), ...rest };
}

async previewScheduleCampaign(campaignVersionId: string, at: string | null) {
  const { data, error } = await this.client.rpc('admin_preview_promotion_schedule_version', {
    p_campaign_version_id: campaignVersionId, p_at: at,
  });
  if (error) throw new WalletCommandTransportError(error.message, false);
  return data;
}
```

이 두 메서드가 기존 `campaignVersions()`/`previewCampaign()`(`client.ts:317-345`)과 다른 RPC 호출 방식(예: 별도 wrapped fetch 헬퍼)을 쓰고 있다면, 새 메서드도 그 기존 방식을 그대로 복제한다 — `this.client.rpc(...)` 직접 호출은 Supabase-js 표준 형태이며 `WalletOpsClient`가 이미 `this.client: SupabaseClient`를 갖고 있다는 전제 위의 기본 구현이다.

- [ ] **Step 5: 테스트 통과 확인 + commit**

```bash
npm test -- __tests__/wallet-ops/commands.test.ts lib/wallet-ops/__tests__ --runInBand
git add lib/wallet-ops/commands.ts lib/wallet-ops/client.ts __tests__/wallet-ops/commands.test.ts
git commit -m "feat(wallet): add V2 promotion schedule command builder and read parser"
```

#### Sub-cycle C: API route allowlist

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`__tests__/wallet-ops/commands-route.test.ts`에 추가:

```ts
it('routes createPromotionScheduleVersion to admin_create_promotion_schedule_version', async () => {
  const invoke = jest.fn().mockResolvedValue({
    data: { ok: true, domain_code: null, retryable: false, operation_id: null, audit_id: 'a1', payload: {}, support_ref: null },
    error: null,
  });
  const response = await handleWalletCommand(
    request({ action: 'createPromotionScheduleVersion', p_request: { request_id: 'r1' } }),
    { getUser: async () => ({ id: actorId }), invoke },
  );
  expect(response.status).toBe(200);
  expect(invoke).toHaveBeenCalledWith('admin_create_promotion_schedule_version', {
    p_actor_user_id: actorId, p_request: { request_id: 'r1' },
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `npm test -- __tests__/wallet-ops/commands-route.test.ts --runInBand`
Expected: FAIL — 알 수 없는 action이라 400/404 등 에러 응답.

- [ ] **Step 3: 최소 구현**

`lib/wallet-ops/command-route-handler.ts:4-14`의 `ACTIONS` 객체에 한 줄 추가:

```ts
const ACTIONS = {
  adjust: 'admin_adjust_star_bonus',
  waiveDebt: 'admin_waive_wallet_debt',
  correction: 'apply_wallet_correction',
  previewRepair: 'admin_preview_wallet_repair',
  executeRepair: 'admin_execute_wallet_repair',
  retryOperation: 'admin_request_wallet_operation_retry',
  acknowledgeAlert: 'admin_ack_wallet_ops_alert',
  createPromotionVersion: 'admin_create_promotion_version',
  createPromotionScheduleVersion: 'admin_create_promotion_schedule_version',
  setEmergencyFlags: 'admin_emergency_set_wallet_flags',
} as const;
```

- [ ] **Step 4: 통과 확인 + commit**

```bash
npm test -- __tests__/wallet-ops/commands-route.test.ts --runInBand
git add lib/wallet-ops/command-route-handler.ts __tests__/wallet-ops/commands-route.test.ts
git commit -m "feat(wallet): allow the promotion schedule v2 create action in the command route"
```

---

### Task 5: Admin — `PromotionCampaigns.tsx` V2 폼으로 교체

**Files:**
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/app/wallet-ops/components/PromotionCampaigns.tsx` (기존 모달 폼 전체를 V2로 교체 — 주간 하드코딩·`rolloutPolicy:{}`·`extraBonusBps` 필드 제거)
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/app/wallet-ops/page.tsx:50` (`createVersion` prop → `createPromotionScheduleVersion` 호출로 교체)
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/__tests__/wallet-ops/ops-dashboard.test.tsx`

**Interfaces:**
- Consumes: Task 4의 `PromotionScheduleVersionInput`, `WalletCommandExecutor.createPromotionScheduleVersion`, `resolvePromotionScheduleError`.

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`__tests__/wallet-ops/ops-dashboard.test.tsx`에 추가(기존 `PromotionCampaigns` 관련 `describe` 옆):

```tsx
describe('PromotionCampaigns v2 schedule creation', () => {
  it('submits event range, weekdays, multiplier, and independent surface toggles — no bps or rolloutPolicy', async () => {
    const createPromotionScheduleVersion = jest.fn().mockResolvedValue({ ok: true, domainCode: null, payload: { version: '1' } });
    render(
      <PromotionCampaigns
        permissions={['promotion.schedule_version.create']}
        loadCampaigns={jest.fn().mockResolvedValue({ items: [{ id: 'c1', code: 'BOOST', latest_version: { version: '0' } }] })}
        loadScheduleVersions={jest.fn().mockResolvedValue({ items: [] })}
        loadHomeBanners={jest.fn().mockResolvedValue({ items: [{ id: 'b1', title: 'Banner' }], snapshotAt: 'now' })}
        previewScheduleCampaign={jest.fn()}
        createPromotionScheduleVersion={createPromotionScheduleVersion}
      />,
    );
    fireEvent.click(await screen.findByRole('button', { name: '새 버전' }));
    fireEvent.change(screen.getByLabelText('행사 시작(KST)'), { target: { value: '2026-09-07T00:00' } });
    fireEvent.change(screen.getByLabelText('행사 종료(KST)'), { target: { value: '2026-09-14T00:00' } });
    fireEvent.click(screen.getByLabelText('월'));
    fireEvent.click(screen.getByLabelText('수'));
    fireEvent.change(screen.getByLabelText('배수'), { target: { value: '1.5' } });
    fireEvent.click(screen.getByLabelText('결제 화면 배지'));
    fireEvent.change(screen.getByLabelText('사유'), { target: { value: '추석 프로모션' } });
    fireEvent.change(screen.getByLabelText('CS 티켓'), { target: { value: 'CS-100' } });
    fireEvent.click(screen.getByRole('button', { name: '생성' }));

    await waitFor(() => expect(createPromotionScheduleVersion).toHaveBeenCalled());
    const [input] = createPromotionScheduleVersion.mock.calls[0];
    expect(input.repeatIsoDows).toEqual([1, 3]);
    expect(input.multiplierTenths).toBe(15);
    expect(input.showHomeBanner).toBe(false);
    expect(input.showPaymentBadge).toBe(true);
    expect(input).not.toHaveProperty('rolloutPolicy');
    expect(input).not.toHaveProperty('extraBonusBps');
  });

  it('requires a banner when HOME is on and maps PROMOTION_HOME_BANNER_REQUIRED to a field error', async () => {
    const createPromotionScheduleVersion = jest.fn().mockResolvedValue({ ok: false, domainCode: 'PROMOTION_HOME_BANNER_REQUIRED' });
    render(
      <PromotionCampaigns
        permissions={['promotion.schedule_version.create']}
        loadCampaigns={jest.fn().mockResolvedValue({ items: [{ id: 'c1', code: 'BOOST', latest_version: { version: '0' } }] })}
        loadScheduleVersions={jest.fn().mockResolvedValue({ items: [] })}
        loadHomeBanners={jest.fn().mockResolvedValue({ items: [], snapshotAt: 'now' })}
        previewScheduleCampaign={jest.fn()}
        createPromotionScheduleVersion={createPromotionScheduleVersion}
      />,
    );
    fireEvent.click(await screen.findByRole('button', { name: '새 버전' }));
    fireEvent.click(screen.getByLabelText('HOME 배너'));
    fireEvent.click(screen.getByRole('button', { name: '생성' }));
    expect(await screen.findByText('HOME 배너를 켰다면 배너를 선택하세요.')).toBeInTheDocument();
  });

  it('reloads instead of resubmitting on PROMOTION_VERSION_CONFLICT', async () => {
    const load = jest.fn().mockResolvedValue({ items: [{ id: 'c1', code: 'BOOST', latest_version: { version: '1' } }] });
    const createPromotionScheduleVersion = jest.fn().mockResolvedValue({ ok: false, domainCode: 'PROMOTION_VERSION_CONFLICT' });
    render(
      <PromotionCampaigns
        permissions={['promotion.schedule_version.create']}
        loadCampaigns={load}
        loadScheduleVersions={jest.fn().mockResolvedValue({ items: [] })}
        loadHomeBanners={jest.fn().mockResolvedValue({ items: [], snapshotAt: 'now' })}
        previewScheduleCampaign={jest.fn()}
        createPromotionScheduleVersion={createPromotionScheduleVersion}
      />,
    );
    fireEvent.click(await screen.findByRole('button', { name: '새 버전' }));
    fireEvent.click(screen.getByLabelText('월'));
    fireEvent.change(screen.getByLabelText('사유'), { target: { value: 'r' } });
    fireEvent.change(screen.getByLabelText('CS 티켓'), { target: { value: 'CS-1' } });
    fireEvent.click(screen.getByRole('button', { name: '생성' }));
    await waitFor(() => expect(load).toHaveBeenCalledTimes(2));
    expect(await screen.findByText('다른 운영자가 먼저 버전을 생성했습니다. 최신 값을 다시 불러옵니다.')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `npm test -- __tests__/wallet-ops/ops-dashboard.test.tsx --runInBand`
Expected: FAIL — 새 label(`행사 시작(KST)` 등)이 존재하지 않음(기존 컴포넌트는 여전히 주간/bps 필드).

- [ ] **Step 3: 최소 구현 — `PromotionCampaigns.tsx` 폼 교체**

`app/wallet-ops/components/PromotionCampaigns.tsx`의 props 시그니처를 다음으로 교체한다(파일 상단 9-16줄):

```tsx
export function PromotionCampaigns({
  permissions, loadCampaigns, loadScheduleVersions, loadHomeBanners, previewScheduleCampaign, createPromotionScheduleVersion,
}: {
  permissions: string[];
  loadCampaigns: () => Promise<{ items: any[] }>;
  loadScheduleVersions: (campaignId: string) => Promise<{ items: any[] }>;
  loadHomeBanners: () => Promise<{ items: WalletHomeBanner[]; snapshotAt: string }>;
  previewScheduleCampaign: (campaignVersionId: string, at: string | null) => Promise<any>;
  createPromotionScheduleVersion: (input: PromotionScheduleVersionInput) => Promise<StableCommandEnvelope<unknown>>;
})
```

`Form.onFinish` 핸들러(기존 84-103줄)를 다음으로 교체한다 — 주간 하드코딩·`rolloutPolicy: {}`·`extraBonusBps` 제거, `repeatIsoDows`/`multiplierTenths`/독립 surface 토글 추가:

```tsx
<Modal open={Boolean(selected)} title='불변 프로모션 새 버전' footer={null} onCancel={() => setSelected(null)}>
  <Form form={form} layout='vertical' onFinish={async (values) => {
    try {
      const response = await createPromotionScheduleVersion({
        campaignId: selected.id,
        expectedLatestVersion: selected.latest_version.version,
        enabled: true,
        eventStartsAt: toKstIso(values.eventStartsAt),
        eventEndsAt: toKstIso(values.eventEndsAt),
        repeatIsoDows: values.repeatIsoDows ?? [],
        multiplierTenths: Math.round(Number(values.multiplierTenths) * 10),
        displayName: { ko: values.title },
        showHomeBanner: values.home === true,
        showPaymentBadge: values.badge === true,
        homeBannerId: values.home === true ? values.homeBannerId : null,
        reason: values.reason, csTicket: values.csTicket,
      });
      if (response.ok) { setSelected(null); await load(); }
      else if (response.domainCode === 'PROMOTION_VERSION_CONFLICT') { setError(resolvePromotionScheduleError(response.domainCode)); await load(); }
      else setError(resolvePromotionScheduleError(response.domainCode));
    } catch (caught) {
      setError(resolvePromotionScheduleError(caught instanceof Error ? caught.message : 'INVALID'));
    }
  }}>
    <Form.Item name='title' label='제목' rules={[{ required: true, whitespace: true }]}><Input /></Form.Item>
    <Form.Item name='eventStartsAt' label='행사 시작(KST)' rules={[{ required: true }]}><Input type='datetime-local' /></Form.Item>
    <Form.Item name='eventEndsAt' label='행사 종료(KST)' rules={[{ required: true }]}><Input type='datetime-local' /></Form.Item>
    <Form.Item name='repeatIsoDows' label='반복 요일' rules={[{ required: true, type: 'array', min: 1 }]}>
      <Checkbox.Group options={[
        { label: '월', value: 1 }, { label: '화', value: 2 }, { label: '수', value: 3 },
        { label: '목', value: 4 }, { label: '금', value: 5 }, { label: '토', value: 6 }, { label: '일', value: 7 },
      ]} />
    </Form.Item>
    <Form.Item name='multiplierTenths' label='배수' rules={[{ required: true }]} initialValue='1.1'>
      <Select options={Array.from({ length: 20 }, (_, i) => {
        const v = ((11 + i) / 10).toFixed(1);
        return { label: `${v}x`, value: v };
      })} />
    </Form.Item>
    <Form.Item name='home' label='HOME 배너' valuePropName='checked'><Switch /></Form.Item>
    {homeSelected && (
      <Form.Item name='homeBannerId' label='배너 선택' rules={[{ required: true }]}>
        <Select options={banners.map((b) => ({ label: b.title, value: b.id }))} />
      </Form.Item>
    )}
    <Form.Item name='badge' label='결제 화면 배지' valuePropName='checked'><Switch /></Form.Item>
    <Form.Item name='reason' label='사유' rules={[{ required: true, whitespace: true }]}><Input /></Form.Item>
    <Form.Item name='csTicket' label='CS 티켓' rules={[{ required: true, whitespace: true }]}><Input /></Form.Item>
    <Button type='primary' htmlType='submit'>생성</Button>
    {error && <Alert type='error' message={error} />}
  </Form>
</Modal>
```

버전 이력 테이블(기존 70-81줄)도 `weekly_start_isodow` 등 V1 필드 대신 `event_starts_at`/`event_ends_at`/`repeat_iso_dows`/`multiplier_tenths`/`show_home_banner`/`show_payment_badge` 컬럼으로 교체하고, `loadVersions` 대신 `loadScheduleVersions`를 호출하도록 바꾼다. `toKstIso`(datetime-local 입력값에 `+09:00` 오프셋을 붙이는 순수 헬퍼)를 같은 파일 상단에 추가한다:

```tsx
function toKstIso(datetimeLocal: string): string {
  return `${datetimeLocal}:00+09:00`;
}
```

`app/wallet-ops/page.tsx:50`의 prop 연결을 교체한다:

```tsx
createPromotionScheduleVersion={(input) => commands.createPromotionScheduleVersion(input)}
```

(`loadScheduleVersions`/`previewScheduleCampaign` prop도 `reads.campaignScheduleVersions`/`reads.previewScheduleCampaign`로 같은 자리에서 연결한다.)

- [ ] **Step 4: 통과 확인**

```bash
npm test -- __tests__/wallet-ops/ops-dashboard.test.tsx --runInBand
npm run type-check
```

Expected: 두 명령 모두 exit 0.

- [ ] **Step 5: Commit**

```bash
git add app/wallet-ops/components/PromotionCampaigns.tsx app/wallet-ops/page.tsx __tests__/wallet-ops/ops-dashboard.test.tsx
git commit -m "fix(wallet): replace the weekly/bps promotion form with the v2 schedule form"
```

---

### Task 6: Flutter — V2 모델/디코더 + repository/provider

**Files:**
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/data/models/promotion/promotion_campaign_v2.dart`
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/data/repositories/promotion_campaign_v2_repository.dart`
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/providers/promotion_campaign_v2_provider.dart`
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json`
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/data/repositories/promotion_campaign_v2_repository_test.dart`
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/presentation/providers/promotion_campaign_v2_provider_test.dart`

**Interfaces:**
- Consumes: Task 2의 `get_active_promotion_campaigns_v2(p_surface)` 이름·`HOME`/`PAYMENT_BADGE` surface 값·응답 필드셋(`campaign_id,campaign_version_id,code,display_name,multiplier_tenths,event_starts_at,event_ends_at,repeat_iso_dows,home_creative`), `requireExactContractKeys`(`picnic_lib/lib/data/models/wallet/wallet_amount.dart`), `PromotionCreativeModel`(`promotion_campaign.dart`, home_creative 하위 shape가 V1과 동일해 그대로 재사용).
- Produces: `enum PromotionSurfaceV2 { home, paymentBadge }`, `ActivePromotionCampaignV2Model`, `ActivePromotionCampaignsV2Model`, `promotionCampaignV2RepositoryProvider`, `activePromotionCampaignV2Provider(PromotionSurfaceV2 surface)`(family, HOME/PAYMENT_BADGE 독립 캐시 키). Task 7이 이 provider를 그대로 소비한다.

#### Sub-cycle A: 모델 + exact-key 디코더

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json`:

```json
{
  "items": [
    {
      "campaign_id": "33333333-3333-4333-8333-333333333333",
      "campaign_version_id": "44444444-4444-4444-8444-444444444444",
      "code": "CANDY_BOOST_V2",
      "display_name": { "ko": "추석 캔디 부스트", "en": "Chuseok Candy Boost" },
      "multiplier_tenths": 15,
      "event_starts_at": "2026-09-07T00:00:00+09:00",
      "event_ends_at": "2026-09-14T00:00:00+09:00",
      "repeat_iso_dows": [1, 3, 5],
      "home_creative": {
        "banner_id": 501,
        "title": { "ko": "부스트 배너" },
        "image": { "ko": "https://cdn.picnic.fan/boost.png" },
        "thumbnail": null,
        "link": null,
        "duration": 4000
      }
    }
  ],
  "total_count": "1",
  "next_cursor": null,
  "snapshot_at": "2026-09-07T00:10:00Z",
  "campaign_owned_home_banner_ids": [501]
}
```

`test/data/repositories/promotion_campaign_v2_repository_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';

void main() {
  final json = jsonDecode(
    File('test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('decodes the V2 envelope and item exactly', () {
    final model = ActivePromotionCampaignsV2Model.fromJson(json);
    expect(model.items.single.multiplierTenths, 15);
    expect(model.items.single.repeatIsoDows, [1, 3, 5]);
    expect(model.items.single.homeCreative!.bannerId, 501);
    expect(model.campaignOwnedHomeBannerIds, [501]);
  });

  test('envelope, item, and creative reject extra keys', () {
    expect(() => ActivePromotionCampaignsV2Model.fromJson({...json, 'extra': true}), throwsFormatException);
    final item = Map<String, dynamic>.from((json['items'] as List).single as Map);
    expect(() => ActivePromotionCampaignV2Model.fromJson({...item, 'extra': true}), throwsFormatException);
  });

  test('wireValue distinguishes HOME and PAYMENT_BADGE', () {
    expect(PromotionSurfaceV2.home.wireValue, 'HOME');
    expect(PromotionSurfaceV2.paymentBadge.wireValue, 'PAYMENT_BADGE');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run (from `picnic_lib/`): `flutter test test/data/repositories/promotion_campaign_v2_repository_test.dart`
Expected: FAIL — `Error: Not found: 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart'`

- [ ] **Step 3: 최소 구현**

`lib/data/models/promotion/promotion_campaign_v2.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/promotion/promotion_campaign_v2.freezed.dart';
part '../../../generated/providers/models/promotion/promotion_campaign_v2.g.dart';

enum PromotionSurfaceV2 { home, paymentBadge }

extension PromotionSurfaceV2Wire on PromotionSurfaceV2 {
  String get wireValue =>
      this == PromotionSurfaceV2.home ? 'HOME' : 'PAYMENT_BADGE';
}

const _campaignV2Keys = {
  'campaign_id',
  'campaign_version_id',
  'code',
  'display_name',
  'multiplier_tenths',
  'event_starts_at',
  'event_ends_at',
  'repeat_iso_dows',
  'home_creative',
};
const _campaignV2EnvelopeKeys = {
  'items',
  'total_count',
  'next_cursor',
  'snapshot_at',
  'campaign_owned_home_banner_ids',
};

@freezed
abstract class ActivePromotionCampaignV2Model
    with _$ActivePromotionCampaignV2Model {
  const ActivePromotionCampaignV2Model._();
  const factory ActivePromotionCampaignV2Model({
    @JsonKey(name: 'campaign_id') required String campaignId,
    @JsonKey(name: 'campaign_version_id') required String campaignVersionId,
    required String code,
    @JsonKey(name: 'display_name') required Map<String, dynamic> displayName,
    @JsonKey(name: 'multiplier_tenths') required int multiplierTenths,
    @JsonKey(name: 'event_starts_at') required DateTime eventStartsAt,
    @JsonKey(name: 'event_ends_at') required DateTime eventEndsAt,
    @JsonKey(name: 'repeat_iso_dows') required List<int> repeatIsoDows,
    @JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative,
  }) = _ActivePromotionCampaignV2Model;

  String localizedDisplayName(String locale) {
    for (final key in [locale, 'ko']) {
      final value = displayName[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return code;
  }

  bool hasReadableHomeCreative(String locale) =>
      homeCreative?.localizedTitle(locale) != null &&
      homeCreative?.localizedImage(locale) != null;

  factory ActivePromotionCampaignV2Model.fromJson(Map<String, dynamic> json) {
    final exact = requireExactContractKeys(json, _campaignV2Keys);
    if (exact['home_creative'] is Map &&
        (exact['home_creative'] as Map).isEmpty) {
      exact['home_creative'] = null;
    }
    return _$ActivePromotionCampaignV2ModelFromJson(exact);
  }
}

@freezed
abstract class ActivePromotionCampaignsV2Model
    with _$ActivePromotionCampaignsV2Model {
  const ActivePromotionCampaignsV2Model._();
  const factory ActivePromotionCampaignsV2Model({
    required List<ActivePromotionCampaignV2Model> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
    @JsonKey(name: 'campaign_owned_home_banner_ids')
    required List<int> campaignOwnedHomeBannerIds,
  }) = _ActivePromotionCampaignsV2Model;

  List<ActivePromotionCampaignV2Model> visibleHomeItems(String locale) =>
      items.where((item) => item.hasReadableHomeCreative(locale)).toList();

  factory ActivePromotionCampaignsV2Model.fromJson(Map<String, dynamic> json) =>
      _$ActivePromotionCampaignsV2ModelFromJson(
        requireExactContractKeys(json, _campaignV2EnvelopeKeys),
      );
}
```

- [ ] **Step 4: 코드 생성 + 통과 확인**

```bash
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/repositories/promotion_campaign_v2_repository_test.dart
```

Expected: build_runner exit 0(새 `.freezed.dart`/`.g.dart` 생성), 테스트 전부 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/promotion/promotion_campaign_v2.dart \
  lib/generated/providers/models/promotion/promotion_campaign_v2.freezed.dart \
  lib/generated/providers/models/promotion/promotion_campaign_v2.g.dart \
  test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json \
  test/data/repositories/promotion_campaign_v2_repository_test.dart
git commit -m "feat(promotion): add V2 campaign model with strict-key decoding"
```

#### Sub-cycle B: repository + provider

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`test/presentation/providers/promotion_campaign_v2_provider_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Repository extends PromotionCampaignV2Repository {
  _Repository(this.value) : super(SupabaseClient('http://localhost', 'key'));
  final ActivePromotionCampaignsV2Model value;
  PromotionSurfaceV2? requested;
  @override
  Future<ActivePromotionCampaignsV2Model> getActive(PromotionSurfaceV2 surface) async {
    requested = surface;
    return value;
  }
}

void main() {
  test('HOME and PAYMENT_BADGE are independent cache entries forwarding the exact surface', () async {
    final value = ActivePromotionCampaignsV2Model.fromJson(jsonDecode(
      File('test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json').readAsStringSync(),
    ) as Map<String, dynamic>);
    final repository = _Repository(value);
    final container = ProviderContainer(
      overrides: [promotionCampaignV2RepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final home = await container.read(activePromotionCampaignV2Provider(PromotionSurfaceV2.home).future);
    expect(repository.requested, PromotionSurfaceV2.home);
    expect(identical(home, value), isTrue);

    final badge = await container.read(activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge).future);
    expect(repository.requested, PromotionSurfaceV2.paymentBadge);
    expect(identical(badge, value), isTrue);

    expect(
      container.exists(activePromotionCampaignV2Provider(PromotionSurfaceV2.home)) &&
          container.exists(activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/presentation/providers/promotion_campaign_v2_provider_test.dart`
Expected: FAIL — `promotion_campaign_v2_provider.dart` 없음.

- [ ] **Step 3: 최소 구현**

`lib/data/repositories/promotion_campaign_v2_repository.dart`:

```dart
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionCampaignV2Repository {
  const PromotionCampaignV2Repository(this.client);
  final SupabaseClient client;

  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) async {
    final value = await client.rpc(
      'get_active_promotion_campaigns_v2',
      params: {'p_surface': surface.wireValue},
    );
    return ActivePromotionCampaignsV2Model.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }
}
```

`lib/presentation/providers/promotion_campaign_v2_provider.dart` — 기존 `promotion_campaign_provider.dart`(17줄 전체)와 동일한 import 목록으로 시작해(`supabase` 전역 client getter가 그 import들 중 하나에서 온다) 아래 본문을 추가한다:

```dart
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// + promotion_campaign_provider.dart 가 'supabase' 식별자를 어디서 import 하는지
//   그대로 이 파일에도 추가한다(동일 전역 client getter를 재사용).

part '../../generated/providers/promotion_campaign_v2_provider.g.dart';

@Riverpod(keepAlive: true)
PromotionCampaignV2Repository promotionCampaignV2Repository(Ref ref) =>
    PromotionCampaignV2Repository(supabase);

@riverpod
Future<ActivePromotionCampaignsV2Model> activePromotionCampaignV2(
  Ref ref,
  PromotionSurfaceV2 surface,
) => ref.watch(promotionCampaignV2RepositoryProvider).getActive(surface);
```

- [ ] **Step 4: 코드 생성 + 통과 확인 + commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/presentation/providers/promotion_campaign_v2_provider_test.dart
flutter analyze
git add lib/data/repositories/promotion_campaign_v2_repository.dart \
  lib/presentation/providers/promotion_campaign_v2_provider.dart \
  lib/generated/providers/promotion_campaign_v2_provider.g.dart \
  test/presentation/providers/promotion_campaign_v2_provider_test.dart
git commit -m "feat(promotion): add V2 repository and surface-keyed provider"
```

---

### Task 7: Flutter — 결제 배지 + HOME 배너 V2 렌더링 + V1 폴백

**Files:**
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart` (표시 문자열을 파라미터로 받도록 축소)
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart:1562-1567,1591` (badge 호출부를 새 resolver provider로 교체)
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/common/candy_boost_banner.dart` (campaign 전체 대신 creative만 받도록 축소)
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/common/common_banner.dart:116-137,310-322` (`_homeSlides`를 소스-불문 형태로, HOME provider를 resolver로 교체)
- Create: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/presentation/providers/promotion_badge_resolver_provider.dart`
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/lib/l10n/app_en.arb`, `app_ko.arb`
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart`
- Modify: `/Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/presentation/common/common_banner_render_test.dart`, `candy_boost_banner_test.dart`, `candy_boost_banner_golden_test.dart`

**Interfaces:**
- Consumes: Task 6의 `activePromotionCampaignV2Provider`, 기존 V1 `activePromotionCampaignProvider`(변경 없음).
- Produces: `formatCandyBoostMultiplierTenths(int tenths) -> String`(정수 전용, 반올림 없음), `paymentBadgePromotionProvider`, `homePromotionCampaignProvider`.

#### Sub-cycle A: 결제 배지

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart`의 기존 위젯 생성부를 다음 형태의 새 테스트로 교체/추가한다(기존 파일의 `buildTestApp` 사용 패턴은 유지):

```dart
testWidgets('renders the exact-double copy when bonusLabel is the exact-double string', (tester) async {
  await tester.pumpWidget(buildTestApp(const CandyBoostBadge(
    displayName: '캔디 부스트 데이', bonusLabel: '기본 지급 + 추가 보너스 100%',
  )));
  expect(find.text('기본 지급 + 추가 보너스 100%'), findsOneWidget);
});

testWidgets('renders a V2 multiplier label verbatim', (tester) async {
  await tester.pumpWidget(buildTestApp(const CandyBoostBadge(
    displayName: '추석 캔디 부스트', bonusLabel: '1.5배',
  )));
  expect(find.text('1.5배'), findsOneWidget);
});

test('formatCandyBoostMultiplierTenths drops a trailing .0 and never rounds', () {
  expect(formatCandyBoostMultiplierTenths(20), '2');
  expect(formatCandyBoostMultiplierTenths(15), '1.5');
  expect(formatCandyBoostMultiplierTenths(21), '2.1');
  expect(formatCandyBoostMultiplierTenths(11), '1.1');
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart`
Expected: FAIL — `CandyBoostBadge`는 아직 `campaign` 파라미터만 받음, `formatCandyBoostMultiplierTenths` 없음.

- [ ] **Step 3: 최소 구현**

`lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart`를 다음으로 교체(순수 표시 위젯으로 축소 — V1/V2 어느 모델도 직접 참조하지 않는다):

```dart
class CandyBoostBadge extends StatelessWidget {
  const CandyBoostBadge({super.key, required this.displayName, required this.bonusLabel});
  final String displayName;
  final String bonusLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: displayName,
      child: Container(
        // (기존 padding/decoration 그대로 유지)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: getTextStyle(AppTypo.caption10SB, AppColors.primary500)),
            Text(bonusLabel, style: getTextStyle(AppTypo.caption10R, AppColors.primary500)),
          ],
        ),
      ),
    );
  }
}

String formatCandyBoostMultiplierTenths(int tenths) {
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  return frac == 0 ? '$whole' : '$whole.$frac';
}
```

`app_en.arb`/`app_ko.arb`(`candy_boost_extra_bonus` 키 옆)에 추가:

```json
"candy_boost_multiplier": "{multiplier}× bonus",
"@candy_boost_multiplier": { "placeholders": { "multiplier": { "type": "String" } } }
```

```json
"candy_boost_multiplier": "{multiplier}배",
"@candy_boost_multiplier": { "placeholders": { "multiplier": { "type": "String" } } }
```

`lib/presentation/providers/promotion_badge_resolver_provider.dart`(V2 우선, 실패 시에만 V1 폴백 — "실패·미지원" 시에만 대체하고 빈 V2 응답은 그대로 신뢰한다):

```dart
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/promotion_badge_resolver_provider.g.dart';

typedef ResolvedPaymentBadgePromotion = ({
  Map<String, dynamic> displayName,
  int? multiplierTenths,
  int? extraBonusBps,
});

@riverpod
Future<ResolvedPaymentBadgePromotion?> paymentBadgePromotion(Ref ref) async {
  // V2가 성공하고 활성 item이 있으면 그것을 쓴다. V2가 예외를 던지거나(미지원/실패)
  // 활성 item이 없으면(예: promotion_schedule_v2_enabled가 아직 꺼져 있어 서버가 빈
  // 결과를 낸 dark-launch 구간) V1을 그대로 다시 조회해 폴백한다 — 클라이언트는 "V2가
  // 정말 활성 캠페인이 없어서 비었는지"와 "flag가 꺼져 있어서 비었는지"를 구분할 수
  // 없으므로, 빈 V2 응답도 실패와 동일하게 취급해야 V1의 실제 활성 캠페인을 놓치지 않는다.
  try {
    final v2 = await ref.watch(promotionCampaignV2RepositoryProvider).getActive(PromotionSurfaceV2.paymentBadge);
    final item = v2.items.firstOrNull;
    if (item != null) {
      return (displayName: item.displayName, multiplierTenths: item.multiplierTenths, extraBonusBps: null);
    }
  } catch (_) {
    // fall through to V1 below
  }
  final v1 = await ref.watch(promotionCampaignRepositoryProvider).getActive(PromotionSurface.store);
  final item = v1.items.where((i) => i.showInStore).firstOrNull;
  if (item == null) return null;
  return (displayName: item.displayName, multiplierTenths: null, extraBonusBps: item.extraBonusBps);
}
```

`purchase_star_candy_state.dart:1562-1567,1591`의 호출부를 다음으로 교체(두 곳 — 구매 화면과 확인 다이얼로그):

```dart
final resolved = ref.watch(paymentBadgePromotionProvider).value;
final badge = resolved == null
    ? null
    : CandyBoostBadge(
        displayName: localizedPromotionDisplayName(resolved.displayName, Localizations.localeOf(context).languageCode),
        bonusLabel: resolved.multiplierTenths != null
            ? AppLocalizations.of(context).candy_boost_multiplier(formatCandyBoostMultiplierTenths(resolved.multiplierTenths!))
            : (resolved.extraBonusBps == 10000
                ? AppLocalizations.of(context).candy_boost_exact_double
                : AppLocalizations.of(context).candy_boost_extra_bonus),
      );
```

`promotion_campaign.dart`에 공유 헬퍼를 추가하고 기존 `ActivePromotionCampaignModel.localizedDisplayName`이 이를 위임하도록 리팩터한다(동작 변경 없음):

```dart
String localizedPromotionDisplayName(Map<String, dynamic> displayName, String locale) {
  for (final key in [locale, 'ko']) {
    final value = displayName[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
```

- [ ] **Step 4: 코드 생성 + 통과 확인**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter test test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart
flutter test test/presentation/widgets/vote/store/purchase/ # purchase_star_candy_state 관련 기존 테스트 회귀 확인
```

Expected: 전부 PASS. `purchase_star_candy_state.dart`를 참조하는 기존 테스트가 `campaign:` named 파라미터를 여전히 기대한다면 그 테스트들도 새 `displayName`/`bonusLabel` 기대값으로 함께 갱신한다.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart \
  lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart \
  lib/presentation/providers/promotion_badge_resolver_provider.dart \
  lib/generated/providers/promotion_badge_resolver_provider.g.dart \
  lib/data/models/promotion/promotion_campaign.dart \
  lib/l10n/app_en.arb lib/l10n/app_ko.arb \
  test/presentation/widgets/vote/store/purchase/candy_boost_badge_test.dart
git commit -m "feat(promotion): render V2 multiplier badge with V1 fallback"
```

#### Sub-cycle B: HOME 배너

- [ ] **Step 1: 실패하는 테스트를 먼저 작성한다**

`test/presentation/common/common_banner_render_test.dart`에 추가:

```dart
testWidgets('HOME uses V2 when it has an active item', (tester) async {
  await pumpAndDrain(tester, buildTestApp(
    const CommonBanner('vote_home', 16 / 9),
    extraOverrides: [
      asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
      homePromotionCampaignProvider('en')
          .overrideWith((ref) async => (slides: [v2HomeSlide()], ownedBannerIds: <int>{501})),
    ],
  ));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(CandyBoostBanner), findsOneWidget);
});

testWidgets('HOME falls back to V1 when V2 throws', (tester) async {
  await pumpAndDrain(tester, buildTestApp(
    const CommonBanner('vote_home', 16 / 9),
    extraOverrides: [
      asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
      activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
          .overrideWith((ref) async => throw Exception('undefined function')),
      activePromotionCampaignProvider(PromotionSurface.home)
          .overrideWith((ref) async => homeCampaign()),
    ],
  ));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(CandyBoostBanner), findsOneWidget);
});

testWidgets('HOME falls back to V1 when V2 succeeds but has no active item (e.g. flag still off)', (tester) async {
  await pumpAndDrain(tester, buildTestApp(
    const CommonBanner('vote_home', 16 / 9),
    extraOverrides: [
      asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
      activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
          .overrideWith((ref) async => emptyV2Campaigns()),
      activePromotionCampaignProvider(PromotionSurface.home)
          .overrideWith((ref) async => homeCampaign()),
    ],
  ));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(CandyBoostBanner), findsOneWidget);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/presentation/common/common_banner_render_test.dart`
Expected: FAIL — `homePromotionCampaignProvider`가 없어 컴파일 실패.

- [ ] **Step 3: 최소 구현**

`candy_boost_banner.dart`를 creative만 받도록 축소:

```dart
class CandyBoostBanner extends ConsumerWidget {
  const CandyBoostBanner({super.key, required this.creative});
  final PromotionCreativeModel creative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final image = creative.localizedImage(locale)!;
    final title = creative.localizedTitle(locale)!;
    // (본문은 기존과 동일 — campaign.homeCreative! 대신 creative를 직접 사용)
  }
}
```

`promotion_badge_resolver_provider.dart`(또는 별도 `promotion_home_resolver_provider.dart`, 같은 파일에 추가 가능)에 HOME resolver를 추가:

```dart
typedef HomePromotionSlideData = ({int bannerId, int durationMs, PromotionCreativeModel creative});

// locale은 family 파라미터로 위젯에서 직접 전달받는다(V1의 `visibleHomeItems(locale)`와
// 동일하게 "선택한 locale에서 읽을 수 없는 creative는 노출하지 않는다"는 불변식을 유지하기
// 위함) — provider 레이어가 locale을 하드코딩하거나 추측하지 않는다.
@riverpod
Future<({List<HomePromotionSlideData> slides, Set<int> ownedBannerIds})> homePromotionCampaign(
  Ref ref,
  String locale,
) async {
  // 배지와 동일한 이유로, V2가 예외를 던지거나 활성 item이 0개면(성공이든 실패든) V1로
  // 폴백한다 — flag-off로 인한 "정상적인 빈 응답"과 "정말 활성 캠페인이 없는 상태"를
  // 클라이언트가 구분할 수 없기 때문이다.
  try {
    final v2 = await ref.watch(promotionCampaignV2RepositoryProvider).getActive(PromotionSurfaceV2.home);
    final visible = v2.visibleHomeItems(locale);
    if (visible.isNotEmpty) {
      return (
        slides: [
          for (final item in visible)
            (bannerId: item.homeCreative!.bannerId, durationMs: item.homeCreative!.duration, creative: item.homeCreative!),
        ],
        ownedBannerIds: v2.campaignOwnedHomeBannerIds.toSet(),
      );
    }
  } catch (_) {
    // fall through to V1 below
  }
  final v1 = await ref.watch(promotionCampaignRepositoryProvider).getActive(PromotionSurface.home);
  return (
    slides: [
      for (final item in v1.visibleHomeItems(locale))
        (bannerId: item.homeCreative!.bannerId, durationMs: item.homeCreative!.duration, creative: item.homeCreative!),
    ],
    ownedBannerIds: v1.campaignOwnedHomeBannerIds.toSet(),
  );
}
```

`common_banner.dart`의 HOME 분기에서 `ref.watch(homePromotionCampaignProvider)`는 `ref.watch(homePromotionCampaignProvider(Localizations.localeOf(context).languageCode))`로 호출한다(family 인자 추가).

`common_banner.dart`의 `_homeSlides`(116-137줄)와 `build`(310-322줄)를 다음으로 교체:

```dart
List<CommonBannerSlide> _homeSlides(
  List<BannerModel> ordinary,
  ({List<HomePromotionSlideData> slides, Set<int> ownedBannerIds}) resolved,
) {
  final emitted = <int>{};
  return [
    for (final slide in resolved.slides)
      if (emitted.add(slide.bannerId))
        CommonBannerSlide(
          id: 'campaign:${slide.bannerId}',
          duration: commonBannerSlideDuration(slide.durationMs),
          child: CandyBoostBanner(creative: slide.creative),
        ),
    ..._ordinarySlides(
      ordinary.where((banner) => !resolved.ownedBannerIds.contains(banner.id)).toList(),
    ),
  ];
}
```

```dart
return ref.watch(homePromotionCampaignProvider(Localizations.localeOf(context).languageCode)).when(
  data: (resolved) {
    _clearCampaignWaitCap(resetExpired: true);
    return _renderSlides(_homeSlides(data, resolved));
  },
  loading: () {
    if (_campaignWaitExpired) return _renderSlides(_ordinarySlides(data));
    _armCampaignWaitCap();
    return _buildBannerShimmer();
  },
  error: (_, _) {
    _clearCampaignWaitCap(resetExpired: false);
    return _renderSlides(_ordinarySlides(data));
  },
);
```

- [ ] **Step 4: 코드 생성 + 회귀 확인**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/presentation/common/common_banner_render_test.dart \
  test/presentation/common/candy_boost_banner_test.dart \
  test/presentation/common/candy_boost_banner_golden_test.dart
flutter analyze
```

Expected: 전부 PASS(golden 픽셀은 `creative`만 렌더 대상이 바뀌었을 뿐 실제 렌더 내용은 동일하므로 기존 golden 파일 그대로 통과해야 한다 — 실패하면 `--update-goldens`로 갱신하기 전에 렌더 결과가 실제로 동일한지 먼저 확인한다).

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/common/candy_boost_banner.dart lib/presentation/common/common_banner.dart \
  lib/presentation/providers/promotion_badge_resolver_provider.dart \
  lib/generated/providers/promotion_badge_resolver_provider.g.dart \
  test/presentation/common/common_banner_render_test.dart \
  test/presentation/common/candy_boost_banner_test.dart
git commit -m "feat(promotion): render HOME banner from V2 with V1 fallback"
```

---

### Task 8: 통합 — 3저장소 fixture 동기화 + rollout

**Files:**
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/supabase/tests/wallet/contracts/manifest.json`
- Modify: `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/types/supabase.ts` (재생성)
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling/docs/wallet/promotion-ops-rollout-runbook.md`

**Interfaces:**
- Consumes: Task 1-7의 모든 산출물.

#### Sub-cycle A: fixture 동기화

- [ ] **Step 1: 실패하는 검증을 먼저 확인한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling
node scripts/wallet/verify_contract_checksums.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/fixtures/wallet_contracts \
  /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
```

Expected: FAIL — `promotion_surfaces_active_v2`가 manifest에 없어 Task 6에서 만든 `picnic_lib` fixture가 미등록 상태로 checksum 불일치 또는 "unknown fixture" 보고.

- [ ] **Step 2: manifest에 V2 fixture를 등록한다**

`supabase/tests/wallet/contracts/manifest.json`을 열어 기존 12개 fixture 키(`wallet_summary_v1, ..., promotion_surfaces_active_v1, ...`) 배열/객체와 동일한 형식으로 `promotion_surfaces_active_v2`(및 `promotion_surfaces_empty_v2`, `stable_error_v1` 옆에 새 도메인 코드가 필요하면 함께) 항목을 추가한다. 정확한 JSON 구조(배열인지 객체인지, 각 항목 필드)는 파일을 직접 열어 기존 12개 항목의 형식을 그대로 복제한다 — 이 계획은 그 바이트 단위 형식까지는 조사하지 않았다.

- [ ] **Step 3: DB fixture를 export하고 3저장소에 동기화한다**

```bash
env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset
node scripts/wallet/export_contract_fixtures.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  --output supabase/tests/wallet/contracts/fixtures \
  --app /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/fixtures/wallet_contracts \
  --admin /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
node scripts/wallet/verify_contract_checksums.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib/test/fixtures/wallet_contracts \
  /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
```

Expected: `N contract fixtures verified; integration constants verified; checksum mismatches: 0`.

- [ ] **Step 4: admin의 pinned checksum을 재고정한다**

`picnic-admin-wallet-ops/README.md:67-78`이 기술하는 pinned SHA-256 게이트(`npm run verify:wallet-contracts`, `pretest`에서 매 `npm test`마다 실행)가 새 fixture 때문에 실패하면, 그 문서가 설명하는 재고정 절차(리뷰된 source commit 갱신)를 그대로 따른다.

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
npm run verify:wallet-contracts
```

Expected: exit 0 (재고정 후).

- [ ] **Step 5: Commit(3개 저장소 각각)**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling
git add supabase/tests/wallet/contracts/manifest.json supabase/tests/wallet/contracts/fixtures
git commit -m "chore(wallet): register V2 promotion fixtures in the shared contract manifest"

cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트
git add picnic_lib/test/fixtures/wallet_contracts/promotion_surfaces_active_v2.json picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
git commit -m "chore(wallet): sync V2 promotion fixture from the shared manifest"

cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
git add test/fixtures/wallet-contracts scripts/verify-wallet-contracts.mjs
git commit -m "chore(wallet): re-pin contract checksum for the V2 promotion fixture"
```

#### Sub-cycle B: rollout 순서와 최종 검증

- [ ] **Step 1: 3저장소 전체 자동 검증을 한 번에 실행한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling && env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib && flutter test && flutter analyze
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_app && flutter test
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && npm run type-check && npm test -- --runInBand && npm run lint
```

Expected: 네 블록 모두 exit 0.

- [ ] **Step 2: `docs/wallet/promotion-ops-rollout-runbook.md`에 V2 절차를 추가한다**

기존 문서의 "Dark launch → 24h 섀도잉 → 승인자 배정 → 활성화" 구조를 그대로 따르는 새 섹션("Candy Boost V2 스케줄 롤아웃")을 추가한다:

1. Task 1-7 배포 후 `promotion_schedule_v2_enabled=false` 상태로 dark launch(스키마·RPC만, flag off).
2. `promotion_surfaces_enabled=true`인 staging에서 운영자가 `admin_create_promotion_schedule_version`으로 실제 V2 version을 생성하고 `admin_preview_promotion_schedule_version`으로 KST 경계·각 요일·양쪽 surface를 확인한다.
3. `promotion_schedule_v2_enabled`를 staging 소수 계정에서 먼저 켜고(`set_wallet_runtime_flag`), `get_active_promotion_campaigns_v2` 응답과 admin preview 결과가 일치하는지, V1 `get_active_promotion_campaigns`가 그대로 동작하는지 확인한다.
4. cohort 요구가 없으므로(스펙 결정) 일반 출시는 100% — `promotion_schedule_v2_enabled=true`로 전환.
5. 되돌리기는 flag를 다시 false로 내리는 것뿐이다. 이미 생성된 V2 version/grant snapshot/감사 행은 삭제·수정하지 않는다(Task 1/3의 append-only 설계로 이미 보장됨).

- [ ] **Step 3: 저장소별 PR을 생성한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling && git push -u origin feat/candy-boost-admin-scheduling && gh pr create --fill --base main --head feat/candy-boost-admin-scheduling
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트 && git push -u origin charlie0421/결제이벤트 && gh pr create --fill --base main --head charlie0421/결제이벤트
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && git push -u origin feat/wallet-ops && gh pr create --fill --base main --head feat/wallet-ops
```

각 `gh pr create` 직후 저장소 지침의 Vercel comment polling(최대 8회×20초)을 실행하고 발견된 Preview URL을 사용자에게 출력한다. UI/API가 바뀐 PR(admin, app)을 `main`에 merge하기 전에는 반드시 "Vercel Preview URL 로 확인하셨나요?"라고 묻고 답을 기다린다.

- [ ] **Step 4: Commit(문서 변경만, 코드는 이미 Step 5 이전에 커밋됨)**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling
git add docs/wallet/promotion-ops-rollout-runbook.md
git commit -m "docs(wallet): add the candy boost v2 schedule rollout procedure"
```

---

## 최종 검증 명령 요약

```bash
# Backend
cd /Users/charlie.hyun/Repositories/picnic-supabase-candy-boost-scheduling && env -u SUPABASE_ACCESS_TOKEN npm run wallet:db:reset && env -u SUPABASE_ACCESS_TOKEN npm run test:wallet:sql

# Flutter
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_lib && flutter test && flutter analyze
cd /Users/charlie.hyun/orca/workspaces/picnic-app/결제이벤트/picnic_app && flutter test

# Admin
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && npm run type-check && npm test -- --runInBand && npm run lint
```

## 필수 반례 커버리지

| 반례 | 위치 |
|---|---|
| provider timestamp NULL 보류(처리 시각 대체 금지) | Task 3 sub-cycle C, `record_promotion_schedule_v2_grant`의 `p_verified_occurred_at is null → PROMOTION_TIME_UNVERIFIABLE`, snapshot 미생성 검증 |
| snapshot 환불 불변성(후속 version 변경에 영향받지 않음) | Task 3 sub-cycle C, 같은 테스트 파일의 "환불 불변성" 블록 — grant 이후 새 version(배수 30) 생성해도 기존 snapshot 값(15/22/7) 불변 확인 |
| 정수 배수(부동소수점/반올림 금지) | Task 2 sub-cycle A, `compute_promotion_reward_v2` — base=1,tenths=11→2/1, base=15,tenths=15→22/7, base=3,tenths=25→7/4(반올림이었다면 8/5) |
| KST 반개구간([start,end), 요일 자정 경계, 연말) | Task 2 sub-cycle A, evaluator 테스트 — start 포함/end 제외, 비선택 요일, 요일 경계 자정 전후, 12/31→1/1 연말 |
| surface/V1/flag(HOME↔PAYMENT_BADGE 누출 금지, V1 불변, flag off 시 빈 결과) | Task 2 sub-cycle B — HOME이 badge-only 버전 미반환·역방향도 동일, flag off 시 total_count=0, V1 `get_active_promotion_campaigns` envelope 불변 확인 |

