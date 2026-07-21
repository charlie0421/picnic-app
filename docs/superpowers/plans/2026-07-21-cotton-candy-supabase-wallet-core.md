# Cotton Candy Supabase Wallet Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Supabase를 유일한 지갑 원장으로 만들고, 전역 잠금·양수 크레딧 경계·엄격한 Bonus 불변식·Cotton Candy 만료 원장·일반 투표 v3·Shortform/Pangle 보상 청구·앱 조회 RPC를 원자적이고 멱등하게 제공한다.

**Architecture:** 모든 금전 명령은 `wallet_command_owner` 소유의 `SECURITY DEFINER` 함수가 동일한 사용자 잠금을 획득한 뒤 operation/ledger/projection을 한 트랜잭션에서 갱신한다. Edge Function은 인증·공급자 검증·응답 매핑만 담당하고, 앱은 안전한 조회 RPC와 인증된 Edge endpoint만 사용한다. 구매·프로모션·환불·부채·운영 기능은 후속 `2026-07-21-cotton-candy-supabase-promotion-ops.md`가 같은 operation/credit 경계를 확장한다.

**Tech Stack:** PostgreSQL 15/Supabase migrations, SQL regression tests (`DO` blocks with `ASSERT`), Supabase Edge Functions (Deno/TypeScript), `supabase-js`, Deno test, Git worktree, Conventional Commits.

## Global Constraints

- 구현 저장소는 `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine`, branch `feat/cotton-candy-engine`이다. rollout master가 만든 이 단일 worktree를 사용하고 별도 core worktree/branch를 만들지 않는다.
- 잠금 순서는 user advisory lock → `public.user_profiles` row → domain/currency bucket이다. 다중 사용자는 UUID 문자열 오름차순으로 단일 사용자 잠금을 모두 획득한다.
- 앱·관리자·공급자는 금액, 만료시각, campaign 결과를 결정하지 않는다. DB가 상품·정책·서버 고정시각으로 계산한다.
- 모든 금융 명령은 전역 `operation_key`가 유일하다. provider inbox는 `(operation_type,idempotency_key)`가 유일하다. 같은 key/같은 payload는 저장 결과를 반환하고, 같은 key/다른 payload는 `OP_IDEMPOTENCY_CONFLICT`로 실패한다.
- `wallet_command_owner`는 `NOLOGIN`; 명령 함수는 `SECURITY DEFINER SET search_path = ''`와 완전 수식 이름을 사용한다.
- `anon`, `authenticated`, `service_role`의 금융 테이블 raw DML을 회수한다. 금전 command RPC는 `PUBLIC`, `anon`, `authenticated`의 `EXECUTE`를 회수하고 Edge Function으로 감싼다. 예외는 금액을 받지 않고 `auth.uid()` 소유권으로 제한된 `create_ad_reward_claim`과 `acknowledge_ad_reward`뿐이며 authenticated direct RPC로 제공한다.
- Cotton은 일반 투표에만 쓰며 JMA, 궁합, PIC에는 쓰지 않는다. 일반 투표 순서는 Cotton → Bonus → Star이다.
- Cotton은 `expires_at > wallet_private.fixed_db_now()`일 때만 활성이고 지급시각 다음 KST 자정에 만료된다.
- immutable ledger/operation은 update/delete하지 않는다. 정정은 연결된 반대 부호 entry로 남긴다.
- 첫 신규 `ON DELETE RESTRICT` 금융 FK보다 먼저 계정 삭제를 profile tombstone 익명화로 바꾸는 compatibility migration과 populated-upgrade test를 배포한다. 후속 promotion-ops의 anonymization task는 이 호환 경계를 완성·감사하되 배포 순서를 뒤집지 않는다.
- 첫 Cotton 발급은 schema/read, vote v3, expiry/reconciliation, provider-time 검증, 경보 gate가 모두 통과한 뒤 연다.

---

## Fixed interfaces and migration order

| Layer | Exact interface | Consumer |
|---|---|---|
| Lock | `wallet_private.wallet_user_lock_key(uuid) -> bigint` | all commands |
| Lock | `wallet_private.lock_wallet_user(uuid) -> void` | all user mutations |
| Lock | `wallet_private.try_lock_wallet_user(uuid) -> boolean` | batch workers |
| Clock | `wallet_private.fixed_db_now() -> timestamptz` | expiry/campaign-safe evaluation |
| Credit | `wallet_private.credit_star_bonus_with_debt(uuid,text,text,bigint,bigint,timestamptz,candy_history_type,text,text,jsonb) -> wallet_credit_result` | every positive Star/Bonus writer |
| Cotton | `public.grant_ad_cotton(text,text,text,text,text,uuid,integer,uuid,uuid,text,text,jsonb) -> wallet_ad_grant_result` | verified Shortform/Pangle wrapper |
| Vote | `public.perform_vote_transaction_v3(uuid,integer,integer,integer,uuid) -> wallet_vote_result` | `voting-v2` Edge service client |
| Ad claim | `public.create_ad_reward_claim(p_platform text,p_placement_id text,p_client_request_id uuid) -> wallet_ad_claim_result` | authenticated Pangle preflight |
| App read | `public.get_wallet_summary() -> wallet_summary` | authenticated app |
| App read | `public.get_currency_history(wallet_currency,text,integer) -> wallet_currency_history_page` | authenticated app |
| App read | `public.get_ad_reward_status(text,uuid) -> wallet_ad_reward_status` | authenticated app |
| App read | `public.list_unacknowledged_ad_rewards(text,integer) -> wallet_ad_reward_status_page` | authenticated app |
| App ack | `public.acknowledge_ad_reward(text,uuid) -> wallet_ad_reward_status` | authenticated owner only |

Migrations deploy in this exact order:

1. `20260721090000_wallet_core_roles_types.sql`
2. `20260721090200_wallet_account_anonymization_compatibility.sql`
3. `20260721090500_wallet_core_operation_schema.sql`
4. `20260721091000_wallet_core_locks_and_credit.sql`
5. `20260721091500_wallet_core_bonus_strictness.sql`
6. `20260721092000_wallet_core_credit_writer_cutover.sql`
7. `20260721092500_wallet_core_cotton_schema.sql`
8. `20260721093000_wallet_core_cotton_commands.sql`
9. `20260721093500_wallet_core_expiry_reconciliation.sql`
10. `20260721094000_wallet_core_vote_v3.sql`
11. `20260721094500_wallet_core_ad_claims.sql`
12. `20260721095000_wallet_core_app_reads.sql`
13. `20260721095500_wallet_core_release_gates.sql`

### Task 1: Shared worktree verification and executable contract

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/docs/wallet/cotton-wallet-contract.md`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_contract.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/package.json`

**Interfaces:** Produces the exact names above as schema assertions; consumes existing `supabase db reset`, `supabase test db`, and Deno conventions.

- [ ] **Step 1: Verify the rollout master's shared worktree**

```bash
sed -n '1,240p' /Users/charlie.hyun/Repositories/GIT_BRANCHING_POLICY.md
git -C /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine status --short --branch
test -f /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/package-lock.json
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && npm install
```

Expected: branch는 `feat/cotton-candy-engine`, npm exit 0, status에 `.gitignore` 변경이 없다.

- [ ] **Step 2: Write the failing schema contract**

`wallet_contract.test.sql`에 다음을 넣는다.

```sql
begin;
do $$ begin
  assert to_regnamespace('wallet_private') is not null, 'wallet_private schema missing';
  assert to_regprocedure('wallet_private.lock_wallet_user(uuid)') is not null, 'lock missing';
  assert to_regprocedure('public.perform_vote_transaction_v3(uuid,integer,integer,integer,uuid)') is not null, 'vote v3 missing';
  assert to_regprocedure('public.get_wallet_summary()') is not null, 'wallet summary missing';
  assert to_regprocedure('public.create_ad_reward_claim(text,text,uuid)') is not null, 'claim RPC missing';
  assert to_regprocedure('public.get_ad_reward_status(text,uuid)') is not null, 'status RPC missing';
  assert to_regprocedure('public.list_unacknowledged_ad_rewards(text,integer)') is not null, 'list RPC missing';
  assert to_regprocedure('public.acknowledge_ad_reward(text,uuid)') is not null, 'ack RPC missing';
  assert to_regclass('public.cotton_candy_ledger') is not null, 'cotton ledger missing';
  assert to_regclass('public.ad_reward_claims') is not null, 'Pangle claim table missing';
end $$;
rollback;
```

- [ ] **Step 3: Prove it fails**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_contract.test.sql
```

Expected: reset succeeds; focused test exits non-zero with `wallet_private schema missing`.

- [ ] **Step 4: Add deterministic scripts and contract prose**

Add to `package.json`:

```json
{"scripts":{"test:wallet:sql":"supabase test db","test:wallet:edge":"deno test --allow-all supabase/functions/tests/wallet","test:wallet":"npm run test:wallet:sql && npm run test:wallet:edge"}}
```

The contract document records exact signatures, lock order, domain errors, claim keys, and rollout implications from this plan.

- [ ] **Step 5: Commit**

```bash
git add package.json docs/wallet/cotton-wallet-contract.md supabase/tests/wallet_contract.test.sql
git commit -m "test(wallet): define cotton wallet contract"
```

Expected: one commit containing only these paths.

### Task 2: Private owner, stable clock, and immutable operation schema

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721090000_wallet_core_roles_types.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721090200_wallet_account_anonymization_compatibility.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721090500_wallet_core_operation_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_operation_idempotency.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_account_anonymization_compatibility.test.sql`

**Interfaces:** Produces `fixed_db_now`, a pre-FK tombstone anonymization boundary, operation/credit tables, `wallet_credit_source_registry`, `wallet_mutation_route_registry`, and per-currency `wallet_credit_result`.

- [ ] **Step 1: Write failing role/privilege/idempotency assertions**

```sql
do $$ declare v_can_dml boolean; begin
  select has_table_privilege('authenticated','public.wallet_financial_operations','insert') into v_can_dml;
  assert not v_can_dml, 'authenticated financial insert';
  assert exists(select 1 from pg_roles where rolname='wallet_command_owner' and not rolcanlogin);
  assert wallet_private.fixed_db_now() = wallet_private.fixed_db_now();
end $$;
```

Also assert duplicate `operation_key` raises `23505` and update/delete of `SUCCEEDED` rows fails.

In `wallet_account_anonymization_compatibility.test.sql`, run the currently deployed account-removal entrypoint against a populated baseline user before any new financial FK exists. Assert the `user_profiles.id` row survives with `deleted_at` set, PII/session/push-token rows are scrubbed or revoked, auth access is disabled through the existing supported helper, and no hard delete or balance/history deletion occurs. The test also asserts migration `20260721090200` sorts before every migration that contains a new `ON DELETE RESTRICT` reference to `user_profiles`.

- [ ] **Step 2: Run and observe the missing table**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_operation_idempotency.test.sql
```

Expected: operation test exits non-zero because the operation table does not exist; the compatibility test fails under the legacy hard-delete path.

- [ ] **Step 3: Implement role, schema, clock, and named types**

```sql
do $$ begin create role wallet_command_owner nologin;
exception when duplicate_object then null; end $$;
create schema if not exists wallet_private authorization wallet_command_owner;
revoke all on schema wallet_private from public, anon, authenticated;
create type public.wallet_operation_status as enum ('PENDING','PROCESSING','SUCCEEDED','DEAD');
create type public.wallet_operation_kind as enum ('CREDIT','DEBIT');
create type public.wallet_currency as enum ('STAR_CANDY','BONUS_STAR_CANDY','COTTON_CANDY');
create type public.wallet_credit_result as (
  operation_id uuid,replayed boolean,
  star_gross bigint,star_debt_offset bigint,star_net_wallet_credit bigint,star_balance bigint,
  bonus_gross bigint,bonus_debt_offset bigint,bonus_net_wallet_credit bigint,bonus_balance bigint
);
create or replace function wallet_private.fixed_db_now()
returns timestamptz language sql stable security definer set search_path=''
as $$ select transaction_timestamp() $$;
```

Set owner to `wallet_command_owner`; revoke all client execution.

- [ ] **Step 4: Install account-removal compatibility before the first RESTRICT FK**

`20260721090200_wallet_account_anonymization_compatibility.sql` replaces the deployed account-removal body with a service-only tombstone flow. It derives the same advisory key later used by `wallet_user_lock_key`, acquires advisory then `user_profiles FOR UPDATE`, scrubs profile PII, deletes/revokes push/session/auth access through existing supported helpers, and sets `deleted_at`; it never deletes the profile, wallet history, receipt, vote, or financial provenance. This migration intentionally does not depend on later financial/audit tables. Promotion-ops Task 13 extends the same entrypoint with the complete PII inventory and immutable wallet audit after those tables exist.

Run the compatibility test immediately after applying `20260721090000` and `20260721090200`, before `20260721090500` creates its first new RESTRICT FK.

- [ ] **Step 5: Implement operation/allocation/source tables**

```sql
create table public.wallet_financial_operations (
 id uuid primary key default gen_random_uuid(), operation_key text not null unique,
 operation_kind public.wallet_operation_kind not null,source_type text not null,source_reference text not null,
 payload_hash text not null check(payload_hash~'^[0-9a-f]{64}$'),
 user_id uuid not null references public.user_profiles(id) on delete restrict,
 status public.wallet_operation_status not null default 'PENDING',result jsonb,
 error_code text,source_event_at timestamptz,created_at timestamptz not null default wallet_private.fixed_db_now(),
 completed_at timestamptz
);
create table public.wallet_credit_operations (
 id uuid primary key default gen_random_uuid(),
 financial_operation_id uuid not null unique references public.wallet_financial_operations(id) on delete restrict,
 created_at timestamptz not null default wallet_private.fixed_db_now()
);
create table public.wallet_credit_allocations (
 id bigint generated always as identity primary key,
 credit_operation_id uuid not null references public.wallet_credit_operations(id) on delete restrict,
 allocation_no integer not null,currency_type public.wallet_currency not null
   check(currency_type in ('STAR_CANDY','BONUS_STAR_CANDY')),reason text not null,
 gross_amount bigint not null check(gross_amount>0),debt_offset_amount bigint not null default 0 check(debt_offset_amount>=0),
 net_wallet_credit_amount bigint not null check(net_wallet_credit_amount>=0),star_candy_history_id integer,
 star_candy_bonus_history_id integer,expires_at timestamptz,
 created_at timestamptz not null default wallet_private.fixed_db_now(),
 unique(credit_operation_id,allocation_no),unique(id,currency_type),
 check(gross_amount=debt_offset_amount+net_wallet_credit_amount),
 check((net_wallet_credit_amount=0 and star_candy_history_id is null and star_candy_bonus_history_id is null)
    or (net_wallet_credit_amount>0 and currency_type='STAR_CANDY' and star_candy_history_id is not null and star_candy_bonus_history_id is null)
    or (net_wallet_credit_amount>0 and currency_type='BONUS_STAR_CANDY' and star_candy_history_id is null and star_candy_bonus_history_id is not null))
);
create table public.wallet_credit_source_registry (
 source_key text primary key,owner_plan text not null check(owner_plan in ('wallet-core','promotion-ops')),
 classification text not null check(classification in ('POSITIVE_CREDIT','NON_CREDIT_DOMAIN','DISABLED')),
 writer_kind text not null check(writer_kind in ('sql','edge','provider')),
 target_interface text not null, migrated boolean not null default false,
 evidence jsonb not null default '{}'::jsonb, migrated_at timestamptz
);
create table public.wallet_mutation_route_registry (
 route_key text primary key,domain text not null,owner_plan text not null check(owner_plan in ('wallet-core','promotion-ops')),
 classification text not null check(classification in ('ACTIVE_MUTATION','SEPARATE_DOMAIN','DISABLED_LEGACY')),
 lock_interface text not null,migrated boolean not null default false,
 evidence jsonb not null default '{}'::jsonb,migrated_at timestamptz
);
```

Attach `wallet_private.reject_immutable_change()` before-update/delete triggers to credit operations/allocations. Financial operation identity, key, source, payload, user, result are immutable; `wallet_private.guard_financial_operation_transition()` permits owner-only `PENDING→PROCESSING→SUCCEEDED|DEAD` state fields and rejects terminal updates/deletes. Revoke raw table DML from `PUBLIC`, `anon`, `authenticated`, `service_role`; grant required DML only to owner.

- [ ] **Step 6: Seed the closed source inventory**

Insert exact source keys `attendance_check`, `admob_reward`, `pincrux_reward`, `tapjoy_reward`, `unity_reward`, `legacy_ads_reward`, `vote_share_bonus`, `gift_reward`, `mission_reward`, `event_reward`, `internal_shortform_view`, `pangle_reward`, `mobile_purchase`, `web_purchase`, `admin_adjustment`, `jma_reward`, `goonghap_reward`, `pic_reward`. Purchase/admin use `owner_plan='promotion-ops'`. JMA/Goonghap/PIC are explicitly `NON_CREDIT_DOMAIN` unless callsite evidence proves a positive Star/Bonus writer; such evidence must reclassify and migrate it before coverage can pass. Coverage denominator is every `POSITIVE_CREDIT` row, while a scan-discovered symbol without any registry row fails the test.

Seed mutation routes `core_positive_credit`, `general_vote_v3`, `legacy_general_vote`, `pic_vote`, `jma_exchange`, `jma_vote`, `goonghap_open`, `bonus_expiry`, `cotton_expiry`, `receipt_deletion`, `mobile_purchase`, `web_purchase`, `promotion_award`, `refund_reversal`, `admin_adjustment`, `debt_recovery`, `projection_repair`. Every active/separate domain that touches Star/Bonus/Cotton must name `wallet_private.lock_wallet_user`; `legacy_general_vote` and destructive `receipt_deletion` can pass only as `DISABLED_LEGACY` with a denial test. Unknown mutation scan matches make `wallet_mutation_lock_coverage` fail.

- [ ] **Step 7: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_account_anonymization_compatibility.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_operation_idempotency.test.sql
git add supabase/migrations/20260721090000_wallet_core_roles_types.sql supabase/migrations/20260721090200_wallet_account_anonymization_compatibility.sql supabase/migrations/20260721090500_wallet_core_operation_schema.sql supabase/tests/wallet_account_anonymization_compatibility.test.sql supabase/tests/wallet_operation_idempotency.test.sql
git commit -m "feat(wallet): add immutable operation boundary"
```

Expected: tests exit 0; account removal is tombstone-only before the first RESTRICT FK, owner is `NOLOGIN`, duplicate operations and immutable mutations fail, client DML is denied.

### Task 3: Global locks and unified Star/Bonus credit

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721091000_wallet_core_locks_and_credit.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_locking.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_credit_command.test.sql`

**Interfaces:** Produces the three lock functions and stable `credit_star_bonus_with_debt` signature. Plan 1 returns debt offset 0; Plan 2 replaces its body after debt schema exists.

- [ ] **Step 1: Write failing two-session and replay tests**

Cover deterministic keys, missing profile, same-key replay, changed-payload conflict, negative inputs, rollback, and two concurrent credits. Canonical call:

```sql
select * from wallet_private.credit_star_bonus_with_debt(
 :'user_id'::uuid,'attendance_check','attendance:2026-07-21:'||:'user_id',
 0,10,'2026-08-20T15:00:00Z','MISSION'::public.candy_history_type,
 'attendance_day','2026-07-21','{"test":true}'::jsonb
);
```

Identical replay returns same operation ID and `replayed=true`; amount 11 with the same key raises `WALLET_IDEMPOTENCY_CONFLICT`.

- [ ] **Step 2: Prove locks are absent**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_locking.test.sql
```

Expected: non-zero exit at `wallet_user_lock_key`.

- [ ] **Step 3: Implement stable advisory/profile locks**

```sql
create or replace function wallet_private.wallet_user_lock_key(p_user_id uuid)
returns bigint language sql immutable security definer set search_path=''
as $$ select ('x'||substr(encode(digest('wallet:user:'||p_user_id::text,'sha256'),'hex'),1,16))::bit(64)::bigint $$;
create or replace function wallet_private.lock_wallet_user(p_user_id uuid)
returns void language plpgsql security definer set search_path='' as $$ begin
 perform pg_advisory_xact_lock(wallet_private.wallet_user_lock_key(p_user_id));
 perform 1 from public.user_profiles where id=p_user_id for update;
 if not found then raise exception using errcode='P0001',message='WALLET_USER_NOT_FOUND'; end if;
end $$;
create or replace function wallet_private.try_lock_wallet_user(p_user_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$ begin
 if not pg_try_advisory_xact_lock(wallet_private.wallet_user_lock_key(p_user_id)) then return false; end if;
 perform 1 from public.user_profiles where id=p_user_id for update skip locked;
 if not found then return false; end if;
 return true;
end $$;
```

The two-session test must hold the profile row without the advisory lock, call `try_lock_wallet_user` from the other session, and prove it returns `false` immediately. Batch code may not replace this with a blocking `FOR UPDATE`.

- [ ] **Step 4: Implement the unified credit command**

Exact signature:

```sql
wallet_private.credit_star_bonus_with_debt(
 p_user_id uuid,p_source_key text,p_operation_key text,p_star_amount bigint,p_bonus_amount bigint,
 p_bonus_expires_at timestamptz,p_reason public.candy_history_type,p_reference_type text,
 p_reference_id text,p_metadata jsonb default '{}'::jsonb
) returns public.wallet_credit_result
```

Validate registered source/nonnegative amounts; acquire user lock; SHA-256 a fixed-order `jsonb_build_object`; reserve or replay operation; reject a hash conflict; insert legacy Star/Bonus histories and allocations; rely on the Bonus projection trigger exactly once; update Star once; persist the complete result JSON; mark succeeded. No exception handler may commit a partial operation.

- [ ] **Step 5: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_locking.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_credit_command.test.sql
git add supabase/migrations/20260721091000_wallet_core_locks_and_credit.sql supabase/tests/wallet_locking.test.sql supabase/tests/wallet_credit_command.test.sql
git commit -m "feat(wallet): serialize unified credit commands"
```

Expected: tests exit 0; concurrency serializes, replay adds no history, conflict is deterministic, direct client execution is denied.

### Task 4: Strict Bonus projection and observed reconciliation defects

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721091500_wallet_core_bonus_strictness.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/bonus_strictness.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/bonus_projection_consistency.test.sql`

**Interfaces:** Consumes `sync_or_enqueue_bonus`, `recompute_user_bonus`, expiry/consolidation paths; produces nonnegative constraint and `wallet_bonus_projection_violations`.

- [ ] **Step 1: Write clamp/swallowed-error regressions**

Fixture profile/bucket at 3; deduct 4 and assert the transaction fails with unchanged profile/history. Write history for a missing profile and assert failure rather than queue-only success.

- [ ] **Step 2: Observe the current fail-open behavior**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/bonus_strictness.test.sql
```

Expected: non-zero assertion because a `GREATEST` zero clamp clamps or `OTHERS` is swallowed.

- [ ] **Step 3: Replace fail-open logic**

```sql
alter table public.user_profiles add constraint user_profiles_star_candy_bonus_nonnegative
check(star_candy_bonus>=0) not valid;
create table public.wallet_bonus_projection_violations (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.user_profiles(id) on delete restrict,
 profile_amount bigint not null,ledger_amount bigint not null,
 detected_at timestamptz not null default wallet_private.fixed_db_now(),resolved_at timestamptz,
 unique nulls not distinct(user_id,resolved_at)
);
```

Replace `sync_or_enqueue_bonus` so it uses the global lock, calculates `next_amount`, raises `WALLET_BONUS_OVERDRAFT` when negative, and has no `WHEN OTHERS`. Queue/recompute records mismatches and fails without clamping. `app.skip_sync_bonus` is legal only when the same transaction recomputes the exact projection before commit.

Override Bonus expiry/consolidation wrappers to acquire the same user lock and mark mutation route `bonus_expiry` migrated only after their legacy regression tests pass.

- [ ] **Step 4: Run all legacy SQL tests and commit**

```bash
supabase db reset
supabase test db
git add supabase/migrations/20260721091500_wallet_core_bonus_strictness.sql supabase/tests/bonus_strictness.test.sql supabase/tests/bonus_projection_consistency.test.sql
git commit -m "fix(wallet): enforce strict bonus projection"
```

Expected: all SQL tests exit 0; no expiry/consolidation path depends on a silent clamp.

### Task 5: Close and migrate non-purchase positive writers

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721092000_wallet_core_credit_writer_cutover.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_credit_source_coverage.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/ad/base-ad-service.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/attendance-check/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/process-ads-reward/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/reward-unity/index.ts`

**Interfaces:** Produces compatibility SQL wrappers and `public.wallet_credit_source_coverage`; consumes the unified credit command.

- [ ] **Step 1: Write failing closed-world coverage assertions**

Assert every `owner_plan='wallet-core'` positive source has `migrated=true` and every discovered mutation has a registry classification/evidence row. Routes implemented in later tasks remain classified but unmigrated until their focused tests pass. Run the callsite inventory:

```bash
rg -n "star_candy(_bonus)?\s*[:=]|from\(['\"]star_candy_(bonus_)?history|INSERT INTO public\.star_candy" supabase/functions supabase/migrations
```

Expected before cutover: direct writers appear in BaseAdService, attendance, legacy reward functions, and baseline SQL.

- [ ] **Step 2: Override retained SQL writers in the new migration**

Preserve public signatures, but derive reward server-side and call `credit_star_bonus_with_debt` once. Require durable source identifiers. Mark migrated rows with concrete evidence:

```sql
update public.wallet_credit_source_registry set migrated=true,migrated_at=wallet_private.fixed_db_now(),
evidence='{"target_interface":"wallet_private.credit_star_bonus_with_debt","test_file":"wallet_credit_source_coverage.test.sql"}'::jsonb
where source_key in ('attendance_check','vote_share_bonus','gift_reward','mission_reward','event_reward');
```

- [ ] **Step 3: Replace Edge split writes**

`BaseAdService.addRewardHistory` takes `{sourceKey,operationKey,userId,referenceType,referenceId}`, calls one service wrapper RPC, and never inserts history/profile separately. Attendance, legacy ads, and Unity use durable source-specific keys.

- [ ] **Step 4: Verify coverage and callsites**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_credit_source_coverage.test.sql
deno test --allow-all supabase/functions/tests/ad supabase/functions/tests/attendance
rg -n "star_candy(_bonus)?\s*[:=]|from\(['\"]star_candy_(bonus_)?history" supabase/functions
```

Expected: tests exit 0; remaining matches are reads/tests. Core-scoped credit coverage is 100%; mutation lock coverage reports the later vote/expiry routes as not yet migrated rather than omitting them; promotion-owned coverage remains below 100%.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260721092000_wallet_core_credit_writer_cutover.sql supabase/tests/wallet_credit_source_coverage.test.sql supabase/functions/_shared/ad/base-ad-service.ts supabase/functions/attendance-check/index.ts supabase/functions/process-ads-reward/index.ts supabase/functions/reward-unity/index.ts
git commit -m "refactor(wallet): route core credits through one boundary"
```

### Task 6: Immutable Cotton grant and ledger schema

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721092500_wallet_core_cotton_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/cotton_schema.test.sql`

**Interfaces:** Produces `user_profiles.cotton_candy`, `cotton_candy_grants`, `cotton_candy_ledger`, `wallet_ad_grant_result`, and `compute_cotton_expiry`.

- [ ] **Step 1: Write failing schema/immutability tests**

Assert projection is nonnegative; positive grants require future expiry; remaining amount is within `[0,original]`; global idempotency key and provider source tuple are unique; grant user matches ledger user; GRANT is exactly once and EXPIRE at most once; ledger update/delete fails; API roles cannot insert.

```sql
do $$ begin
  assert not has_table_privilege('service_role','public.cotton_candy_ledger','insert');
  assert exists(select 1 from pg_constraint where conname='cotton_candy_grants_source_key');
end $$;
```

- [ ] **Step 2: Prove the schema is absent**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/cotton_schema.test.sql
```

Expected: non-zero exit because `cotton_candy_grants` is absent.

- [ ] **Step 3: Create bucket and immutable ledger**

```sql
alter table public.user_profiles add column cotton_candy integer not null default 0
  check(cotton_candy>=0);
create table public.cotton_candy_grants (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.user_profiles(id) on delete restrict,
 source_provider text not null,source_environment text not null,source_event_type text not null,
 source_transaction_id text not null,claim_id uuid,impression_id uuid,idempotency_key text not null unique,
 provider_payload_hash text not null check(provider_payload_hash~'^[0-9a-f]{64}$'),
 canonical_payload_hash text not null check(canonical_payload_hash~'^[0-9a-f]{64}$'),reward_policy_version text not null,
 original_amount integer not null check(original_amount>0),
 remain_amount integer not null check(remain_amount between 0 and original_amount),
 granted_at timestamptz not null,expires_at timestamptz not null check(expires_at>granted_at),
 metadata jsonb not null default '{}'::jsonb,unique(id,user_id),
 constraint cotton_candy_grants_source_key unique(source_provider,source_environment,source_event_type,source_transaction_id),
 check((source_provider='pangle' and claim_id is not null and impression_id is null)
    or (source_provider='internal_shortform' and claim_id is null and impression_id is not null))
);
create table public.cotton_candy_ledger (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.user_profiles(id) on delete restrict,
 grant_id bigint not null,event_type text not null check(event_type in ('GRANT','CONSUME','EXPIRE')),
 amount_delta integer not null,operation_key text not null,vote_pick_id integer,
 source_reference text,created_at timestamptz not null default wallet_private.fixed_db_now(),
 foreign key(grant_id,user_id) references public.cotton_candy_grants(id,user_id) on delete restrict,
 unique(operation_key,grant_id,event_type),
 check((event_type='GRANT' and amount_delta>0) or (event_type in ('CONSUME','EXPIRE') and amount_delta<0))
);
create unique index cotton_candy_one_grant_entry on public.cotton_candy_ledger(grant_id)
  where event_type='GRANT';
create unique index cotton_candy_one_expire_entry on public.cotton_candy_ledger(grant_id)
  where event_type='EXPIRE';
```

Attach immutable trigger to ledger. Grant guard permits only owner-command `remain_amount` decreases; it rejects provenance/expiry/original edits and increases. Add `(user_id,expires_at,id) WHERE remain_amount>0` and `(expires_at,id) WHERE remain_amount>0` indexes. Revoke raw DML from all API roles.

- [ ] **Step 4: Implement next KST midnight exactly**

```sql
create or replace function wallet_private.compute_cotton_expiry(p_occurred_at timestamptz)
returns timestamptz language sql immutable security definer set search_path=''
as $$ select (((p_occurred_at at time zone 'Asia/Seoul')::date+1)::timestamp at time zone 'Asia/Seoul') $$;
```

Test `2026-07-20T14:59:59Z`, `2026-07-20T15:00:00Z`, and Seoul's DST-independent result.

- [ ] **Step 5: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/cotton_schema.test.sql
git add supabase/migrations/20260721092500_wallet_core_cotton_schema.sql supabase/tests/cotton_schema.test.sql
git commit -m "feat(wallet): add cotton grant ledger"
```

Expected: test exits 0; direct mutations and expiry-boundary violations fail.

### Task 7: Cotton grant, expiry worker, and reconciliation

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721093000_wallet_core_cotton_commands.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721093500_wallet_core_expiry_reconciliation.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/cotton_commands.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/cotton_expiry_reconciliation.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-expiry-worker/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-reconciliation/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/expiry-worker.test.ts`

**Interfaces:** Produces service-only `grant_ad_cotton` and `expire_cotton_candy_batch`, plus private `ad_source_lock_key`, `reconcile_wallet_batch`; Edge workers wrap all commands.

- [ ] **Step 1: Write grant replay and fixed-time expiry tests**

Use a transaction-local clock override available only to the test role. Assert reward `2026-07-20T14:59:59Z` expires at `2026-07-20T15:00:00Z`; equality with now is inactive; operation-key and source-natural-key replay both return the first canonical result; changing user/amount/provider payload/policy/source tuple/claim ID/impression ID while reusing either key raises `OP_IDEMPOTENCY_CONFLICT`; replay creates no second grant; expiry appends one negative entry. Include a case that keeps `p_payload_hash` identical while changing claim/impression/source so the DB canonical hash—not a wrapper-supplied hash—must catch it.

```sql
do $$ declare v_count integer; begin
  select count(*) into v_count from public.cotton_candy_grants
   where idempotency_key='internal_shortform:view:00000000-0000-0000-0000-000000000111';
  assert v_count=1,'replay inserted a second grant';
  assert (select count(*) from public.cotton_candy_ledger where event_type='GRANT')=1;
end $$;
```

- [ ] **Step 2: Prove grant is absent**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/cotton_commands.test.sql
```

Expected: non-zero exit at `public.grant_ad_cotton`.

- [ ] **Step 3: Implement grant and non-blocking expiry**

Create the complete service contract:

```sql
create or replace function wallet_private.ad_source_lock_key(
 p_provider text,p_environment text,p_event_type text,p_transaction_id text
) returns bigint language sql immutable security definer set search_path='' as $$
 select ('x'||substr(encode(digest('wallet:ad-source:'||p_provider||':'||p_environment||':'||
   p_event_type||':'||p_transaction_id,'sha256'),'hex'),1,16))::bit(64)::bigint
$$;

create or replace function public.grant_ad_cotton(
 p_operation_key text,p_source_provider text,p_source_environment text,
 p_source_event_type text,p_source_transaction_id text,p_user_id uuid,p_amount integer,
 p_claim_id uuid,p_impression_id uuid,p_reward_policy_version text,p_payload_hash text,p_metadata jsonb
) returns public.wallet_ad_grant_result
language plpgsql security definer set search_path='' as $$
declare v_now timestamptz:=wallet_private.fixed_db_now();v_grant_id bigint;v_result public.wallet_ad_grant_result;
        v_existing public.cotton_candy_grants%rowtype;v_canonical_hash text;
begin
  perform wallet_private.assert_cotton_source_policy(p_source_provider,p_source_environment,p_source_event_type,p_amount,p_reward_policy_version);
  v_canonical_hash:=encode(digest(convert_to(jsonb_build_object(
    'source_provider',p_source_provider,'source_environment',p_source_environment,
    'source_event_type',p_source_event_type,'source_transaction_id',p_source_transaction_id,
    'user_id',p_user_id,'amount',p_amount,'claim_id',p_claim_id,'impression_id',p_impression_id,
    'reward_policy_version',p_reward_policy_version,'provider_payload_hash',p_payload_hash,
    'metadata',coalesce(p_metadata,'{}'::jsonb))::text,'UTF8'),'sha256'),'hex');
  perform wallet_private.lock_wallet_user(p_user_id);
  perform pg_advisory_xact_lock(wallet_private.ad_source_lock_key(
    p_source_provider,p_source_environment,p_source_event_type,p_source_transaction_id));
  select * into v_existing from public.cotton_candy_grants
   where source_provider=p_source_provider and source_environment=p_source_environment
     and source_event_type=p_source_event_type and source_transaction_id=p_source_transaction_id for share;
  if found then
    if v_existing.canonical_payload_hash<>v_canonical_hash
       or v_existing.provider_payload_hash<>p_payload_hash then
      raise exception using errcode='P0001',message='OP_IDEMPOTENCY_CONFLICT';
    end if;
    return wallet_private.build_ad_grant_result(v_existing.id,true,v_now);
  end if;
  select wallet_private.replay_ad_grant(p_operation_key,v_canonical_hash) into v_result;
  if v_result.operation_id is not null then return v_result; end if;
  insert into public.cotton_candy_grants(user_id,source_provider,source_environment,source_event_type,
    source_transaction_id,claim_id,impression_id,idempotency_key,provider_payload_hash,canonical_payload_hash,reward_policy_version,
    original_amount,remain_amount,granted_at,expires_at,metadata)
  values(p_user_id,p_source_provider,p_source_environment,p_source_event_type,p_source_transaction_id,
    p_claim_id,p_impression_id,p_operation_key,p_payload_hash,v_canonical_hash,p_reward_policy_version,p_amount,p_amount,
    v_now,wallet_private.compute_cotton_expiry(v_now),p_metadata)
  returning id into v_grant_id;
  insert into public.cotton_candy_ledger(user_id,grant_id,event_type,amount_delta,operation_key,source_reference)
  values(p_user_id,v_grant_id,'GRANT',p_amount,p_operation_key,p_source_transaction_id);
  update public.user_profiles set cotton_candy=cotton_candy+p_amount,updated_at=v_now where id=p_user_id;
  return wallet_private.complete_ad_grant_result(p_operation_key,v_grant_id,v_now);
end $$;
```

`public.expire_cotton_candy_batch(p_limit integer)` selects users with `expires_at <= fixed_db_now()`, calls `try_lock_wallet_user`, expires grants in `(expires_at,id)` order, appends `EXPIRE`, decrements projection exactly, and returns named `wallet_batch_result(processed,skipped_locked,next_cursor)`.

Mark mutation route `cotton_expiry` migrated only after the focused SQL and worker tests pass.

- [ ] **Step 4: Implement observation-only reconciliation**

Create `wallet_invariant_violations(violation_type,user_id,expected,actual,first_seen_at,last_seen_at,resolved_at,severity)`. `reconcile_wallet_batch` verifies:

- all Cotton grant `remain_amount` sum equals `user_profiles.cotton_candy`, while spendable separately sums only `expires_at > fixed_db_now()`;
- root Bonus `remain_amount` sum equals profile Bonus;
- Star projection equals operation/legacy ledger total;
- no negative projection, Cotton grant, or Bonus bucket exists;
- every succeeded operation has required allocation/ledger rows.

It upserts observations and resolves absent violations after a second consistent scan; it never repairs balances.

- [ ] **Step 5: Add thin Edge workers**

Both handlers require `X-Cron-Secret`, call exactly one service-only batch RPC, return `{processed,skippedLocked,nextCursor}`, and perform no raw table DML. Deno tests assert missing secret 401, domain conflict 409, transient DB failure 503.

- [ ] **Step 6: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/cotton_commands.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/cotton_expiry_reconciliation.test.sql
deno test --allow-all supabase/functions/tests/wallet/expiry-worker.test.ts
git add supabase/migrations/20260721093000_wallet_core_cotton_commands.sql supabase/migrations/20260721093500_wallet_core_expiry_reconciliation.sql supabase/tests/cotton_commands.test.sql supabase/tests/cotton_expiry_reconciliation.test.sql supabase/functions/wallet-expiry-worker/index.ts supabase/functions/wallet-reconciliation/index.ts supabase/functions/tests/wallet/expiry-worker.test.ts
git commit -m "feat(wallet): expire and reconcile cotton balances"
```

Expected: commands exit 0; locked users skip, expiry occurs once, reconciliation records without repair.

### Task 8: Atomic general vote v3

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721094000_wallet_core_vote_v3.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/vote_v3.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/voting-v2/vote-logic.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/voting-v2/db.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/voting-v2/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/voting-v3.test.ts`

**Interfaces:** Produces service-only `perform_vote_transaction_v3`; voting-v2 consumes it. PIC/JMA/Goonghap stay non-Cotton.

- [ ] **Step 1: Write spending-order/rollback tests**

Cover expired Cotton ignored; earliest expiry then grant ID; Cotton→Bonus→Star; insufficient aggregate rolls back; replay/conflict; disabled/ended/non-general vote rejection; PIC/JMA/Goonghap never touch Cotton.

```sql
select * from public.perform_vote_transaction_v3(
 :'user_id'::uuid,101,201,17,'00000000-0000-0000-0000-000000000301'::uuid
);
do $$ begin
  assert (select cotton_candy_usage from public.vote_pick where request_id='00000000-0000-0000-0000-000000000301')=5;
  assert (select star_candy_bonus_usage from public.vote_pick where request_id='00000000-0000-0000-0000-000000000301')=7;
  assert (select star_candy_usage from public.vote_pick where request_id='00000000-0000-0000-0000-000000000301')=5;
end $$;
```

- [ ] **Step 2: Observe missing v3**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/vote_v3.test.sql
```

Expected: non-zero exit because v3 is absent.

- [ ] **Step 3: Implement one locked transaction**

Create exact signature `public.perform_vote_transaction_v3(p_user_id uuid,p_vote_id integer,p_vote_item_id integer,p_amount integer,p_request_id uuid)`. After user lock, lock vote domain rows, evaluate eligibility at `fixed_db_now`, reserve `vote:<user_id>:<request_id>`, materialize overdue grants in the same rollback boundary, then allocate active Cotton:

```sql
for v_grant in select id,remain_amount from public.cotton_candy_grants
 where user_id=p_user_id and remain_amount>0 and expires_at>v_now
 order by expires_at,id for update
loop
  v_take:=least(v_remaining,v_grant.remain_amount);
  update public.cotton_candy_grants set remain_amount=remain_amount-v_take where id=v_grant.id;
  insert into public.cotton_candy_ledger(user_id,grant_id,vote_pick_id,event_type,amount_delta,operation_key)
  values(p_user_id,v_grant.id,v_vote_pick_id,'CONSUME',-v_take,v_operation_key);
  update public.user_profiles set cotton_candy=cotton_candy-v_take where id=p_user_id;
  v_remaining:=v_remaining-v_take;
  exit when v_remaining=0;
end loop;
```

Then consume Bonus oldest-expiry-first and Star. Insert vote and histories before success. Return named `operation_id,replayed,cotton_spent,bonus_spent,star_spent` and balances.

Mark `general_vote_v3` migrated and `legacy_general_vote` disabled after cutover tests. Existing PIC/JMA/Goonghap mutations must be wrapped with `lock_wallet_user` without allowing Cotton, then mark `pic_vote`, `jma_exchange`, `jma_vote`, and `goonghap_open` migrated with non-Cotton regression evidence.

- [ ] **Step 4: Replace Edge raw orchestration**

Remove no-op advisory lock and local `spendBonusBuckets`. App body contains only `vote_id`, `vote_item_id`, decimal-string `amount`, `request_id`. Handler accepts `/^(0|[1-9][0-9]*)$/`, parses bigint, rejects zero or values above PostgreSQL integer max, authenticates JWT, passes that subject as `p_user_id`, and calls only v3 via service client. Revoke v3 `EXECUTE` from `PUBLIC`, `anon`, `authenticated`; map insufficient balance 409 and eligibility failures 400/403. Preserve legacy success fields and add this exact v3 shape, mapping every bigint to a decimal string:

```json
{
  "votePickId": 301,
  "updatedVoteTotal": 1017,
  "addedVoteTotal": 17,
  "updatedAt": "2026-07-21T00:00:00Z",
  "operation_id": "00000000-0000-0000-0000-000000000301",
  "replayed": false,
  "usage": {
    "cotton_candy_usage": "5",
    "star_candy_bonus_usage": "7",
    "star_candy_usage": "5"
  },
  "wallet": {
    "contract_version": "wallet.v1",
    "star": "95",
    "bonus": "23",
    "cotton": "0",
    "cotton_expiring_amount": "0",
    "cotton_next_expires_at": null,
    "snapshot_at": "2026-07-21T00:00:00Z"
  }
}
```

The Edge test and `vote_result_v3` contract fixture assert all four legacy fields plus `operation_id`, `replayed`, `usage`, and `wallet`; no legacy success field is optionalized or renamed.

- [ ] **Step 5: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/vote_v3.test.sql
deno test --allow-all supabase/functions/tests/wallet/voting-v3.test.ts
git add supabase/migrations/20260721094000_wallet_core_vote_v3.sql supabase/tests/vote_v3.test.sql supabase/functions/voting-v2/vote-logic.ts supabase/functions/voting-v2/db.ts supabase/functions/voting-v2/index.ts supabase/functions/tests/wallet/voting-v3.test.ts
git commit -m "feat(voting): spend cotton before bonus and star"
```

Expected: tests exit 0; exact mixed allocation and all-or-nothing rollback are proven.

### Task 9: Provider-verified Shortform and Pangle claims

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721094500_wallet_core_ad_claims.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/ad_reward_claims.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/wallet/domain-error.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/wallet/payload-hash.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/wallet/provider-time.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/wallet/response.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/ad-reward-claim/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/ad-reward-status/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/ad-shortform-issue/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/callback-ad-shortform-view/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/callback-pangle/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/ad/platforms/pangle-service.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/ad-reward-claim.test.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/ad-shortform-issue.test.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/pangle-settlement.test.ts`

**Interfaces:** Produces Pangle-only `ad_reward_claims`, authenticated `create_ad_reward_claim`, service-only `grant_ad_cotton` wrappers, and internal `ad_impressions.view_reward_*` state. Shortform does not create an `ad_reward_claims` row.

- [ ] **Step 1: Write state-machine/idempotency tests**

Pangle states are `PENDING`, `GRANTED`, `DENIED`, `EXPIRED`, `ABANDONED`; only `PENDING` can transition and terminal states are immutable. Grant keys are `internal_shortform:view:<impression_id>` and `pangle:<environment>:reward:<trans_id>`. Test intent replay/conflict, claim TTL, provider transaction uniqueness, same callback replay, conflicting source payload, invalid provider time, and grant rollback.

```sql
do $$ begin
  assert (select status from public.ad_reward_claims where client_request_id='00000000-0000-0000-0000-000000000401')='PENDING';
  begin
    update public.ad_reward_claims set status='PENDING' where status='GRANTED';
    assert false,'terminal claim changed';
  exception when check_violation then null; end;
end $$;
```

- [ ] **Step 2: Write failing Edge verification tests**

Shortform issuance preserves existing top-level `ad` and `tokens`, additively returns top-level `impression_id` UUID equal to the inserted `ad_impressions.id`, and fails closed before returning playable ad/token data when insert fails or the returned ID is absent. Its Deno test asserts the app can persist that exact reference before playback. Shortform callback rejects token/user/impression/action mismatch. Pangle claim creation accepts only `platform`, `placement_id`, `client_request_id`; tests reject user/channel/environment/TTL/reward fields. SSV rejects bad signature, unknown environment, absent occurred time, malformed signed token, raw CSV identity mismatch, and client reward. Valid callbacks make one `grant_ad_cotton` call.

```ts
Deno.test("Pangle claim rejects authority fields", async () => {
  const response = await issueClaim({
    platform: "ANDROID",
    placement_id: "reward-main",
    client_request_id: "00000000-0000-0000-0000-000000000401",
    user_id: "00000000-0000-0000-0000-000000000999",
  });
  assertEquals(response.status, 400);
  assertEquals((await response.json()).domain_code, "AD_CLAIM_UNKNOWN_FIELD");
});
```

- [ ] **Step 3: Create claim schema and commands**

```sql
create table public.ad_reward_claims (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.user_profiles(id) on delete restrict,
 channel text not null check(channel='PANGLE'),environment text not null,
 platform text not null,placement_id text not null,client_request_id uuid not null,
 status text not null check(status in ('PENDING','GRANTED','DENIED','EXPIRED','ABANDONED')),
 provider_transaction_id text,expires_at timestamptz not null,result_grant_id bigint,
 payload_hash text not null check(payload_hash~'^[0-9a-f]{64}$'),acknowledged_at timestamptz,
 created_at timestamptz not null default wallet_private.fixed_db_now(),
 unique(user_id,channel,client_request_id),unique(channel,environment,provider_transaction_id),unique(result_grant_id),
 unique(id,user_id),
 check((status='GRANTED')=(result_grant_id is not null)),
 foreign key(result_grant_id,user_id) references public.cotton_candy_grants(id,user_id) on delete restrict
);
alter table public.ad_impressions
 add column view_reward_status text,
 add column view_result_grant_id bigint unique,
 add column view_reward_acknowledged_at timestamptz,
 add column view_reward_payload_hash text;
update public.ad_impressions set view_reward_status='ABANDONED' where view_reward_status is null;
alter table public.ad_impressions alter column view_reward_status set default 'PENDING',
 alter column view_reward_status set not null,
 add constraint ad_impressions_view_reward_status_check
 check(view_reward_status in ('PENDING','GRANTED','DENIED','EXPIRED','ABANDONED')),
 add constraint ad_impressions_view_grant_check
 check((view_reward_status='GRANTED')=(view_result_grant_id is not null)),
 add constraint ad_impressions_view_grant_user_fk foreign key(view_result_grant_id,user_id)
 references public.cotton_candy_grants(id,user_id) on delete restrict;
alter table public.ad_impressions add constraint ad_impressions_id_user_key unique(id,user_id);
alter table public.cotton_candy_grants
 add constraint cotton_grant_claim_user_fk foreign key(claim_id,user_id)
 references public.ad_reward_claims(id,user_id) on delete restrict,
 add constraint cotton_grant_impression_user_fk foreign key(impression_id,user_id)
 references public.ad_impressions(id,user_id) on delete restrict;
```

Add `create_ad_reward_claim(p_platform text,p_placement_id text,p_client_request_id uuid)`. It derives user from `auth.uid()`, channel `PANGLE`, environment from server deployment, TTL from server policy, and returns the same intent for an identical replay. A changed platform/placement for the same request raises `AD_CLAIM_IDEMPOTENCY_CONFLICT`. Add immutable terminal transition guards and the deferred grant FKs in this migration.

The Shortform wrapper first reads only the immutable impression owner ID without a row lock, acquires `lock_wallet_user(owner_id)`, then locks the impression `FOR UPDATE` and revalidates the stored issue token/user/action=`view`/watch condition before calling `grant_ad_cotton`. It updates `view_reward_status`, result grant, canonical/provider payload hashes, and `ad_reward_events` in the same transaction. The Pangle wrapper follows the same order: read immutable claim owner without a row lock → user advisory/profile lock → claim `FOR UPDATE` → revalidate ownership/TTL/token/payload → bind `(environment,trans_id)` → call `grant_ad_cotton` → mark `GRANTED`. It never binds or locks claim/impression before the user lock. DB reward policy chooses amount.

Add two-connection tests where one transaction holds the user lock and another begins Shortform/Pangle settlement, plus the inverse domain-row probe. They must prove every callback waits only in the user-first order and cannot form a domain→user/user→domain deadlock.

`ad-shortform-issue` inserts `ad_impressions` first with `INSERT ... RETURNING id`, binds every issued token to that returned UUID, then returns exactly `{ad:<legacy>,tokens:<legacy>,impression_id:<same UUID>}`. It never generates or returns playable tokens before the durable impression exists. Insert error, non-UUID ID, or missing ID returns a stable 5xx failure with no `ad`, `tokens`, or synthetic reference. The callback and status RPC accept only this durable ID; no later endpoint creates a replacement impression after playback.

- [ ] **Step 4: Implement wrappers and replace split commits**

`ad-reward-claim` accepts only `{platform,placement_id,client_request_id}` and calls authenticated `create_ad_reward_claim`; user/channel/environment/TTL are server-derived. It HMAC-signs a canonical opaque v2 payload containing claim ID, user ID, platform, placement, environment, expiry, and DB claim payload hash, then returns `signed_token`:

```ts
const tokenPayload = {
  v: 2,
  claim_id: claim.id,
  user_id: claim.user_id,
  platform: claim.platform,
  placement_id: claim.placement_id,
  environment: claim.environment,
  expires_at: claim.expires_at,
  payload_hash: claim.payload_hash,
};
const signed_token = await signOpaqueClaim(tokenPayload, Deno.env.get("PANGLE_CLAIM_HMAC_KEY")!);
return Response.json({
  reference: { type: "PANGLE_CLAIM", id: claim.id },
  platform: claim.platform,
  signed_token,
  expires_at: claim.expires_at,
});
```

Pangle remains provider SSV. SSV verifies provider signature, opaque-token HMAC, claim payload hash, TTL, and DB ownership before binding `trans_id`. Remove Shortform's split insert/mark/reward and Pangle's split transaction/reward commits. Signed token supplies authoritative identity and signed provider payload supplies occurrence time. Legacy CSV is parse compatibility only and cannot choose identity, reward, placement, environment, or time. Add a Deno assertion that changing raw CSV user/platform while keeping a valid v2 token either uses the token's claim owner or rejects; it must never reward the CSV identity.

- [ ] **Step 5: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/ad_reward_claims.test.sql
deno test --allow-all supabase/functions/tests/wallet/ad-reward-claim.test.ts supabase/functions/tests/wallet/ad-shortform-issue.test.ts supabase/functions/tests/wallet/pangle-settlement.test.ts
git add supabase/migrations/20260721094500_wallet_core_ad_claims.sql supabase/tests/ad_reward_claims.test.sql supabase/functions/_shared/wallet supabase/functions/ad-reward-claim supabase/functions/ad-reward-status supabase/functions/ad-shortform-issue/index.ts supabase/functions/callback-ad-shortform-view/index.ts supabase/functions/callback-pangle/index.ts supabase/functions/_shared/ad/platforms/pangle-service.ts supabase/functions/tests/wallet/ad-reward-claim.test.ts supabase/functions/tests/wallet/ad-shortform-issue.test.ts supabase/functions/tests/wallet/pangle-settlement.test.ts
git commit -m "feat(ads): settle cotton reward claims atomically"
```

Expected: tests exit 0; duplicates grant once, provider occurred time is verified/provenance only, and `granted_at` plus next-KST-midnight `expires_at` use the same DB fixed clock; callbacks do no raw financial DML.

### Task 10: Safe app read RPCs and generated types

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721095000_wallet_core_app_reads.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_app_reads.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/database.types.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/ad-reward-status/index.ts`

**Interfaces:** Produces `get_wallet_summary`, `get_currency_history`, `get_ad_reward_status`, `list_unacknowledged_ad_rewards`, and owner-bound `acknowledge_ad_reward` with named composites/pages; consumes `auth.uid()` and ledgers.

- [ ] **Step 1: Write ownership/cursor/boundary tests**

User A reads only A; signatures expose no user UUID; summary excludes `expires_at <= fixed_db_now`; currency enum accepts only stable values; cursor `(created_at,id)` handles ties; list returns `{items,total_count,next_cursor,snapshot_at}`; status/ack supports only `PANGLE_CLAIM|INTERNAL_IMPRESSION`; ack cannot change reward state or another user's row. Call ACK twice for each reference type and assert both calls return the same canonical status, the first acknowledgement timestamp is unchanged, no duplicate event/audit row appears, and the item remains absent from the unacknowledged list.

```sql
do $$ begin
  assert (select total_count from public.list_unacknowledged_ad_rewards(null,20))='2';
  perform public.acknowledge_ad_reward('PANGLE_CLAIM','00000000-0000-0000-0000-000000000401');
  assert (select total_count from public.list_unacknowledged_ad_rewards(null,20))='1';
end $$;
```

- [ ] **Step 2: Observe missing reads**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_app_reads.test.sql
```

Expected: non-zero exit at `get_wallet_summary()`.

- [ ] **Step 3: Add named safe reads**

Define exact named fields:

```text
wallet_summary = {contract_version text,star text,bonus text,cotton text,cotton_expiring_amount text,cotton_next_expires_at timestamptz|null,snapshot_at timestamptz}
wallet_currency_history_item = {id text,currency wallet_currency,event_type text,origin text,delta text,balance_effect text,expires_at timestamptz|null,purchase_id uuid|null,refund_id uuid|null,grant_id text|null,operation_id uuid,created_at timestamptz}
wallet_currency_history_page = {items wallet_currency_history_item[],total_count text,next_cursor text|null,snapshot_at timestamptz}
wallet_ad_reward_reference = {type text,id uuid}
wallet_ad_reward_grant = {id text,currency wallet_currency,amount text,granted_at timestamptz,expires_at timestamptz}
wallet_ad_reward_status = {reference wallet_ad_reward_reference,state text,grant wallet_ad_reward_grant|null,wallet wallet_summary,snapshot_at timestamptz}
wallet_ad_reward_status_page = {items wallet_ad_reward_status[],total_count text,next_cursor text|null,snapshot_at timestamptz}
```

Implement exact signatures:

```sql
public.get_wallet_summary()
public.get_currency_history(p_currency public.wallet_currency,p_cursor text,p_limit integer)
public.get_ad_reward_status(p_reference_type text,p_reference_id uuid)
public.list_unacknowledged_ad_rewards(p_cursor text,p_limit integer)
public.acknowledge_ad_reward(p_reference_type text,p_reference_id uuid)
```

Each `SECURITY DEFINER SET search_path=''` derives non-null `auth.uid()` and selects that UID only. `get_ad_reward_status` branches on the two reference types and returns the nested reference/grant plus a same-snapshot wallet summary. List unions Pangle claims with `ad_impressions.view_reward_status`, filters unacknowledged rows, orders by terminal time/ID, and emits a signed opaque cursor. Acknowledge updates only the selected owner's acknowledgement timestamp after terminal state and returns canonical status. Repeating the same owner/reference ACK is idempotent: it returns the original canonical status, does not change the first acknowledgement timestamp or append duplicate evidence, and remains HTTP 200 through PostgREST. Grant execute only to `authenticated`; raw table update remains revoked. History labels currency/source/gross/net/debt offset/expiry/reference. Because app reads call PostgREST directly, public SQL functions cast every internal bigint amount, ID, and count to base-10 `text`; composites themselves expose `text`, not bigint. They fix `contract_version='wallet.v1'`, preserve UUID/timestamp/null, keep field names byte-for-byte, and return nullable history references as null. Contract tests reject JSON numeric money/counts and flattened aliases.

- [ ] **Step 4: Generate and reconcile Edge types**

```bash
supabase db reset
supabase gen types typescript --local > /tmp/picnic-supabase-wallet-types.ts
diff -u supabase/functions/_shared/database.types.ts /tmp/picnic-supabase-wallet-types.ts
```

Expected initially: diff contains new composites/RPCs. Reconcile through normal editing, regenerate to `/tmp`, and expect empty diff. Never overwrite a user-modified generated file blindly.

- [ ] **Step 5: Verify and commit**

```bash
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_app_reads.test.sql
deno check supabase/functions/ad-reward-status/index.ts
git add supabase/migrations/20260721095000_wallet_core_app_reads.sql supabase/tests/wallet_app_reads.test.sql supabase/functions/_shared/database.types.ts supabase/functions/ad-reward-status/index.ts
git commit -m "feat(wallet): expose user-scoped wallet reads"
```

Expected: tests exit 0; generated definitions contain named composites, not anonymous JSON.

### Task 11: Release gates, cron, and legacy lockdown

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721095500_wallet_core_release_gates.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_release_gates.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/config.toml`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/voting/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/docs/wallet/cotton-wallet-rollout-runbook.md`

**Interfaces:** Produces versioned flags and private `assert_cotton_issuance_ready`; consumes coverage, invariants, worker health, deployed version.

- [ ] **Step 1: Write implication/privilege tests**

Exact keys are `wallet.cotton_read_enabled`, `wallet.cotton_spend_enabled`, `wallet.cotton_expiry_enabled`, `ads.internal_reward_mode`, `ads.pangle_reward_mode`, `ads.pangle_claim_mode`, `ads.cotton_popup_enabled`. Reward mode values are `bonus|cotton|paused`; Pangle claim mode values are `shadow|optional|required`. Any `cotton` reward mode requires read/spend/expiry true, zero critical violation, 100% core credit coverage, and 100% core mutation lock coverage. Once a live Cotton grant exists, changing `wallet.cotton_expiry_enabled` to false is rejected. Legacy mutation RPCs are non-client-executable.

- [ ] **Step 2: Observe missing gate state**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_release_gates.test.sql
```

Expected: non-zero exit because release flags are absent.

- [ ] **Step 3: Implement versioned flags/gate**

Create `wallet_runtime_flags(flag_key primary key,value_json,version,changed_at,changed_by,reason)` with guarded service-only mutation. `assert_cotton_issuance_ready` checks the exact bool/mode implications in one snapshot and raises a named failed gate. `grant_ad_cotton` invokes it except under a test-only DB role.

- [ ] **Step 4: Configure workers and legacy shutdown**

`wallet-expiry-worker` and `wallet-reconciliation` use `verify_jwt=false` plus `X-Cron-Secret`; app claim/status keeps JWT verification. Schedule expiry every 5 minutes, reconciliation hourly. After vote-v3 flag, legacy `/voting` returns `410 VOTING_CLIENT_UPGRADE_REQUIRED`; revoke client execute from `perform_vote_transaction`, `process_vote`, and both `use_star_candy_bonus` overloads without dropping them.

Override `handle_receipt_deletion` so it never zeros balances or deletes histories/votes; verify account removal still routes through the already-deployed `20260721090200` tombstone compatibility contract and mark `receipt_deletion` as `DISABLED_LEGACY` with a denial test. This late migration may strengthen guards but must not be the first point at which hard deletion is disabled.

- [ ] **Step 5: Validate strict Bonus after clean reconciliation**

```sql
do $$ begin
 if exists(select 1 from public.wallet_bonus_projection_violations where resolved_at is null)
 then raise exception using errcode='P0001',message='WALLET_BONUS_RECONCILIATION_REQUIRED'; end if;
end $$;
alter table public.user_profiles validate constraint user_profiles_star_candy_bonus_nonnegative;
```

- [ ] **Step 6: Record exact rollout gates**

Runbook order:

1. Deploy migrations 1–8 with flags false; full SQL suite plus two clean reconciliation scans.
2. Deploy vote/read; enable `wallet.cotton_read_enabled`, then `wallet.cotton_spend_enabled` at 5%, 25%, 100%, requiring zero double-spend/invariant defects.
3. Enable `wallet.cotton_expiry_enabled`; require two expiry intervals and one reconciliation interval before any Cotton reward mode.
4. Shadow Shortform/Pangle settlement 24 hours and compare verified versus would-credit counts.
5. Set `ads.internal_reward_mode=cotton` at 5%, 25%, 100%; duplicate credit 0 and non-provider failure below 0.5%.
6. Move `ads.pangle_claim_mode` shadow→optional→required and set `ads.pangle_reward_mode=cotton` at 5%, 25%, 100% with environment-separated keys and the same thresholds.
7. Enable `ads.cotton_popup_enabled` only after acknowledgement recovery fixtures pass.
8. Rollback sets reward modes to `paused` or `bonus` and disables popup first; it never deletes ledger/grants and keeps spend/expiry/reconciliation active. Expiry cannot be disabled after the first live grant.

- [ ] **Step 7: Run complete verification and commit**

```bash
supabase db reset
supabase test db
deno test --allow-all supabase/functions/tests
deno check supabase/functions/voting-v2/index.ts supabase/functions/ad-reward-claim/index.ts supabase/functions/ad-reward-status/index.ts supabase/functions/wallet-expiry-worker/index.ts supabase/functions/wallet-reconciliation/index.ts
git diff --check
git status --short
git add supabase/migrations/20260721095500_wallet_core_release_gates.sql supabase/tests/wallet_release_gates.test.sql supabase/config.toml supabase/functions/voting/index.ts docs/wallet/cotton-wallet-rollout-runbook.md
git commit -m "chore(wallet): gate cotton production rollout"
```

Expected: commands exit 0; status has only intended files and no `.gitignore` change.

### Task 12: Independent review and promotion handoff

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/docs/wallet/wallet-core-handoff.md`
- Read: `/Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/docs/superpowers/plans/2026-07-21-cotton-candy-supabase-promotion-ops.md`

**Interfaces:** Verifies wallet-core and publishes the exact promotion baseline.

- [ ] **Step 1: Request requirement-focused review**

Use `superpowers:requesting-code-review`. Check lock order, replay, strict Bonus, immutable provenance, time boundaries, forbidden vote domains, provider time, privileges, and gate implications.

- [ ] **Step 2: Re-run evidence after every review fix**

```bash
supabase db reset
npm run test:wallet
git diff --check
git log --oneline --decorate -12
```

Expected: reset/tests exit 0, diff check is empty, each task has a Conventional Commit.

- [ ] **Step 3: Record the promotion baseline**

Write `docs/wallet/wallet-core-handoff.md` with migration `20260721095500`, operation/credit signatures, exact public DTO checksums, flag versions, registry rows, and unresolved invariant count. Promotion may begin only with zero critical violations and passing core tests. Overall coverage remains below 100% until mobile purchase, web purchase, and admin adjustment migrate in the next plan.

- [ ] **Step 4: Commit the reviewed handoff**

```bash
git add docs/wallet/wallet-core-handoff.md
git commit -m "docs(wallet): hand off cotton wallet core"
```

Expected: the twelfth task has one Conventional Commit and the handoff contains no secrets or raw provider payload.
