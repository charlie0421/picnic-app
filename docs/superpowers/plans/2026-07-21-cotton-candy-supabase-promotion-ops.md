# Cotton Candy Supabase Promotion and Wallet Operations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 검증 구매 snapshot, 캔디 부스트 판정/지급, durable provider inbox, 누적 환불/부채 회수, 관리자 read/command/RBAC, immutable audit/alert, cron/worker health, 계정 익명화를 Supabase의 원자적 지갑 경계 위에 완성한다.

**Architecture:** wallet-core의 동일 operation, user-first lock, debt-aware credit 시그니처를 확장한다. 외부 event는 수신·lease·정산·실패 기록의 분리된 durable inbox 흐름을 거치고, 금융 transaction만 snapshot/원장/projection/debt와 inbox 성공 CAS를 함께 commit한다. 관리자 read는 `auth.uid()`를, service-only command는 Next Route가 세션에서 도출한 `p_actor_user_id`를 사용해 DB RBAC와 audit을 검증한다. Picnic-admin의 단일 Next Route Handler가 canonical wrapper다.

**Tech Stack:** PostgreSQL 15/Supabase migrations, SQL regression/property/concurrency tests, Supabase Edge Functions with Deno/TypeScript, Apple/Google/provider server verification, `supabase-js`, npm, Conventional Commits.

## Global Constraints

- 이 계획은 `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine`, branch `feat/cotton-candy-engine`에서 wallet-core 계획 직후 실행한다. 별도 worktree/branch를 만들지 않는다.
- `/Users/charlie.hyun/Repositories/picnic-supabase/.gitignore`의 기존 사용자 변경을 읽거나 복사할 수는 있어도 수정·stage하지 않는다.
- 승인 설계와 stable `wallet.v1` 계약을 바꾸지 않는다. 충돌이 있으면 구현을 중단하고 설계 승인을 받는다.
- enum migration과 새 enum 값 사용 migration을 분리한다. `wallet_currency` 값은 `STAR_CANDY`, `BONUS_STAR_CANDY`, `COTTON_CANDY`; operation/inbox 상태는 대문자다.
- 모든 금액/수량은 bigint 정수다. promo는 `floor((base_star_amount + base_bonus_amount) * extra_bonus_bps / 10000)`이며 provider 발생 시각으로 판정한다.
- refund는 immutable gross snapshot을 역분개한다. 첫 유효 refund에서 promo 전액, base는 누적 정수 비율의 이전 target과 새 target 차이를 사용한다. Cotton은 회수나 debt 상계에 쓰지 않는다.
- `refund_reversal_enabled`는 `debt_recovery_enabled=true`이고 `credit_source_coverage=100`일 때만 true가 될 수 있다.
- 모든 사용자 mutation의 lock 순서는 advisory user lock → profile row → snapshot/resolution/refund rows → currency bucket → open debt다.
- raw financial/campaign/inbox/audit DML은 `service_role`까지 회수한다. provider/worker service-only command는 Edge Function으로 감싸고 raw client `EXECUTE`를 열지 않는다. Admin command의 canonical wrapper는 picnic-admin Next Route Handler 하나다. 9개 command는 `service_role`/dedicated command role만 실행하며, Route가 사용자 세션에서 도출한 actor ID를 전달하고 DB가 whitelist/RBAC/승인을 재검증한다. 별도 admin Edge gateway를 만들지 않는다.
- safe admin read만 `authenticated`에 실행을 허용하며 함수 내부에서 현재 actor의 RBAC를 다시 검증한다.
- audit insert는 대상 mutation과 같은 transaction에서 성공해야 한다. ledger, snapshot, refund allocation, debt event, audit event는 update/delete할 수 없다.
- 삭제 전 provenance를 익명 subject로 재연결하며 금융 FK의 `ON DELETE RESTRICT`를 우회하거나 금융 행을 지우지 않는다.

---

## Fixed contracts and migration order

Service-only provider commands:

```text
grant_verified_purchase(provider text,environment text,provider_transaction_id text,user_id uuid,product_id text,quantity bigint,provider_occurred_at timestamptz,refund_ratio_basis text,provider_original_quantity bigint,provider_paid_amount_minor bigint,provider_currency text,verification_payload_hash text,request_context jsonb,operation_key text,inbox_id uuid,lease_token uuid)
resolve_purchase_promotion(snapshot_id uuid,verified_provider_occurred_at timestamptz,operation_key text,inbox_id uuid,lease_token uuid)
refund_verified_purchase(provider text,environment text,provider_refund_id text,provider_transaction_id text,cumulative_refunded_numerator bigint,provider_refunded_at timestamptz,payload_hash text,operation_key text,inbox_id uuid,lease_token uuid)
```

`grant_verified_purchase.provider_occurred_at` is nullable only when provider verification succeeded but the authoritative event time is not yet available; caller processing time never substitutes for it. After durable inbox receive, worker adapters pass server-verified Apple/Google `QUANTITY` plus original quantity or PayPal/PortOne `AMOUNT` plus exact paid minor units and uppercase ISO currency. The compatibility wrappers only enqueue and ignore caller reward values; they never claim to verify a provider or call this financial command. The DB derives `MOBILE|WEB`, `mobile_purchase|web_purchase`, required refund basis, and the channel Bonus column from the normalized provider; caller JSON cannot select them.

PostgREST-exposed service-only inbox wrappers are also fixed: `public.receive_provider_event`, `public.claim_provider_event_batch`, `public.complete_provider_event`, and `public.fail_provider_event`. Their `wallet_private.*` implementations remain unexposed; only the public wrappers receive `service_role` EXECUTE.

Safe admin reads:

```text
admin_get_wallet_actor_context()
admin_get_user_cs_summary(p_user_id uuid)
admin_list_user_currency_history(p_user_id uuid,p_currency wallet_currency,p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_list_user_money_timeline(p_user_id uuid,p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_list_promotion_campaigns(p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_preview_promotion_campaign(p_campaign_id uuid,p_at timestamptz)
admin_list_wallet_operations(p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_list_ops_alerts(p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_get_wallet_ops_summary(p_at timestamptz DEFAULT NULL)
admin_list_wallet_invariant_violations(p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_get_worker_health()
admin_list_promotion_campaign_versions(p_campaign_id uuid,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_list_user_wallet_debts(p_user_id uuid,p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
admin_get_wallet_runtime_flags()
admin_list_wallet_audit_events(p_filters jsonb,p_cursor text DEFAULT NULL,p_limit integer DEFAULT 20)
```

Admin command RPCs, all called only by picnic-admin's authenticated Next Route Handler:

```text
admin_create_promotion_version(p_actor_user_id uuid,p_request jsonb)
admin_adjust_star_bonus(p_actor_user_id uuid,p_request jsonb)
apply_wallet_correction(p_actor_user_id uuid,p_request jsonb)
admin_request_wallet_operation_retry(p_actor_user_id uuid,p_request jsonb)
admin_ack_wallet_ops_alert(p_actor_user_id uuid,p_request jsonb)
admin_preview_wallet_repair(p_actor_user_id uuid,p_request jsonb)
admin_execute_wallet_repair(p_actor_user_id uuid,p_request jsonb)
admin_waive_wallet_debt(p_actor_user_id uuid,p_request jsonb)
admin_emergency_set_wallet_flags(p_actor_user_id uuid,p_request jsonb)
record_wallet_command_failure(p_request jsonb)
```

각 request는 명령별 allowlist field와 `request_id`, `reason`, 필요한 `cs_ticket`/resource/version/approval reference만 포함한다. actor/approver ID는 JSON 허용 key가 아니다. Next Route가 session user ID를 별도 `p_actor_user_id`로 전달하고 DB가 `admin_user_roles`와 approval record에서 actor/approver를 검증한다. Retry request는 정확히 `{request_id,operation_id,expected_version,reason,cs_ticket}`이고 DB가 operation에서 inbox를 resolve한다. 앞의 9개 command는 mutation/audit을 같은 transaction에서 처리한다. `record_wallet_command_failure`만 Next Route가 rollback 뒤 별도 transaction으로 호출하며, its exact redacted request is `{actor_user_id,request_id,action_code,failure_stage,domain_code,retryable}`. `failure_stage`는 `TRANSPORT|RESPONSE_DECODE`만 허용한다. `actor_user_id`는 Next가 세션에서 추가한 service-derived 값이고 외부 body에서는 거부한다. DB는 actor context와 failure provenance만 기록하며 raw reason, CS ticket, 원 body/payload는 받거나 저장하지 않는다.

모든 9개 command의 named result는 `wallet_stable_command_envelope(ok boolean,domain_code text,retryable boolean,operation_id uuid,audit_id uuid,result jsonb,support_ref text)`다. 성공 wire는 `{ok:true,operation_id,audit_id,result}`, 실패 wire는 `{ok:false,domain_code,retryable,operation_id,support_ref}`만 직렬화한다.

Migrations deploy in this exact order:

1. `20260721100000_wallet_promotion_reason_enums.sql`
2. `20260721100500_wallet_inbox_audit_alert_schema.sql`
3. `20260721101000_promotion_campaign_schema.sql`
4. `20260721101500_purchase_reward_schema.sql`
5. `20260721102000_wallet_recovery_debt_schema.sql`
6. `20260721102500_wallet_debit_repair_schema.sql`
7. `20260721103000_wallet_debt_aware_credit.sql`
8. `20260721103500_purchase_settlement_commands.sql`
9. `20260721104000_purchase_promotion_commands.sql`
10. `20260721104500_purchase_refund_commands.sql`
11. `20260721105000_wallet_admin_read_rpcs.sql`
12. `20260721105500_wallet_admin_command_rpcs.sql`
13. `20260721110000_wallet_admin_rbac_and_direct_writer_lockdown.sql`
14. `20260721110500_wallet_ops_cron_jobs.sql`
15. `20260721111000_wallet_account_anonymization.sql`
16. `20260721111500_wallet_promotion_release_gates.sql`

### Task 1: Confirm the shared worktree and split enum deployment

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721100000_wallet_promotion_reason_enums.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_promotion_enum_contract.test.sql`

**Interfaces:** Consumes wallet-core migration `20260721095500`; produces reason values `CANDY_BOOST`, `REFUND_REVERSAL`, `DEBT_RECOVERY`, `CORRECTION` without using them in the same migration.

- [ ] **Step 1: Verify worktree, branch, lockfile, and core baseline**

```bash
git -C /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine status --short --branch
test -f /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/package-lock.json
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && npm install
rg -n "20260721095500|credit_star_bonus_with_debt|assert_cotton_issuance_ready" supabase/migrations docs/wallet
```

Expected: branch is `feat/cotton-candy-engine`; npm exits 0; all three core markers exist; `.gitignore` is not modified.

- [ ] **Step 2: Write a failing enum contract test**

Assert `candy_history_type` contains all four reason values, `wallet_currency` contains exactly the three stable values, and `wallet_operation_status` contains `PENDING`, `PROCESSING`, `SUCCEEDED`, `DEAD`.

- [ ] **Step 3: Observe missing reason values**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_promotion_enum_contract.test.sql
```

Expected: focused test exits non-zero at `CANDY_BOOST` before the enum migration.

- [ ] **Step 4: Add enum values only, verify after a fresh transaction, and commit**

```sql
alter type public.candy_history_type add value if not exists 'CANDY_BOOST';
alter type public.candy_history_type add value if not exists 'REFUND_REVERSAL';
alter type public.candy_history_type add value if not exists 'DEBT_RECOVERY';
alter type public.candy_history_type add value if not exists 'CORRECTION';
```

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_promotion_enum_contract.test.sql
git add supabase/migrations/20260721100000_wallet_promotion_reason_enums.sql supabase/tests/wallet_promotion_enum_contract.test.sql
git commit -m "feat(wallet): add promotion ledger reasons"
```

Expected: test exits 0; migration contains no table/function using the new values.

### Task 2: Durable inbox, immutable audit, alert, and heartbeat schema

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721100500_wallet_inbox_audit_alert_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_inbox_state_machine.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_audit_alert_schema.test.sql`

**Interfaces:** Produces `wallet_provider_event_inbox`, immutable `wallet_audit_events`, deduplicated `ops_alerts`, `wallet_worker_heartbeats`, and lease/CAS helpers.

- [ ] **Step 1: Write failing transition and stale-lease tests**

Test A receive replay/conflict, B lease increment/token rotation, B success CAS, C retry/dead CAS, stale worker rejection, terminal immutability, audit immutability, and alert fingerprint dedupe/count increment.

- [ ] **Step 2: Observe missing inbox schema**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_inbox_state_machine.test.sql
```

Expected: non-zero exit because `wallet_provider_event_inbox` is absent.

- [ ] **Step 3: Implement schema and exact lease helpers**

Inbox columns include internal `id`, externally stable `operation_id uuid NOT NULL UNIQUE DEFAULT gen_random_uuid()`, `operation_type`, `idempotency_key`, `payload_hash`, `status`, `attempt_count`, `row_version`, `next_retry_at`, `lease_until`, `locked_by`, `lease_token`, `last_error_code`, nullable `last_error_retryable`, `result_type`, `result_id`, timestamps; unique `(operation_type,idempotency_key)`. Status check is `PENDING|PROCESSING|SUCCEEDED|DEAD`; every state/lease/retry mutation increments `row_version`. Admin DTOs expose `operation_id`, never the internal inbox `id`; commands resolve the inbox row by this column.

Create private implementations plus identically shaped public service-only wrappers:

```text
public.receive_provider_event(p_operation_type text,p_idempotency_key text,p_payload_hash text,p_encrypted_payload bytea,p_occurred_at timestamptz)
public.claim_provider_event_batch(p_worker_id uuid,p_limit integer,p_lease_seconds integer)
public.complete_provider_event(p_inbox_id uuid,p_lease_token uuid,p_result_type text,p_result_id uuid)
public.fail_provider_event(p_inbox_id uuid,p_lease_token uuid,p_retryable boolean,p_error_code text,p_next_retry_at timestamptz)
```

Each public function is owned by `wallet_command_owner`, uses `SECURITY DEFINER SET search_path=''`, delegates to `wallet_private`, revokes EXECUTE from `PUBLIC|anon|authenticated`, and grants only `service_role`. Tests call them through the same default-public PostgREST path used by the Edge worker and assert direct private-schema RPC exposure is absent.

The batch claim and fencing CAS use this shape inside their functions:

```sql
with candidate as (
  select id from public.wallet_provider_event_inbox
  where (status='PENDING' and next_retry_at<=wallet_private.fixed_db_now())
     or (status='PROCESSING' and lease_until<wallet_private.fixed_db_now())
  order by next_retry_at,id for update skip locked limit p_limit
)
update public.wallet_provider_event_inbox i
set status='PROCESSING',attempt_count=i.attempt_count+1,row_version=i.row_version+1,locked_by=p_worker_id,
    lease_token=gen_random_uuid(),lease_until=wallet_private.fixed_db_now()+make_interval(secs=>p_lease_seconds)
from candidate c where i.id=c.id
returning i.id,i.operation_type,i.lease_token,i.attempt_count,i.encrypted_payload;

update public.wallet_provider_event_inbox
set status='SUCCEEDED',result_type=p_result_type,result_id=p_result_id,
    row_version=row_version+1,lease_until=null,locked_by=null,lease_token=null,
    last_error_code=null,last_error_retryable=null
where id=p_inbox_id and status='PROCESSING' and lease_token=p_lease_token;
```

Expired PROCESSING takeover always rotates token/worker and increments attempt. Both completion/failure functions require affected-row count 1 or raise `WALLET_STALE_LEASE`; failure records `last_error_retryable`, increments `row_version`, returns retryable rows to PENDING and permanent rows to DEAD. The two-connection test holds the first token past lease expiry, claims a second token, proves first-token completion/failure affect 0 rows, and proves the second token completes exactly once. Success tests assert the terminal CAS increments `row_version` exactly once.

Audit fields are the design-required actor/role/action/resource/operation/request/reason/ticket/before/after/campaign/time fields. `ops_alerts` uses severity `CRITICAL|WARNING`, status `OPEN|ACKNOWLEDGED|RESOLVED`, and unique open fingerprint.

- [ ] **Step 4: Apply privilege/immutability guards, verify, and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_inbox_state_machine.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_audit_alert_schema.test.sql
git add supabase/migrations/20260721100500_wallet_inbox_audit_alert_schema.sql supabase/tests/wallet_inbox_state_machine.test.sql supabase/tests/wallet_audit_alert_schema.test.sql
git commit -m "feat(wallet): persist provider events and ops evidence"
```

Expected: tests exit 0; stale leases cannot overwrite; API roles have no raw DML; audit update/delete fails.

### Task 3: Append-only Candy Boost campaign and deterministic evaluator

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721101000_promotion_campaign_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/promotion_campaign_evaluator.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/promotion_campaign_constraints.test.sql`

**Interfaces:** Produces `promotion_campaigns`, immutable `promotion_campaign_versions`, private evaluator, and app-safe `get_active_promotion_campaigns(surface)`. HOME result is `wallet_promotion_surface_page(items,total_count,next_cursor,snapshot_at,campaign_owned_home_banner_ids integer[])`.

- [ ] **Step 1: Write boundary/property tests first**

Cover KST Monday 00 inclusive, Wednesday 00 exclusive, Sunday/Monday UTC crossing, inactive latest version with no fallback, cohort stability, overlap rejection, invalid timezone/BPS/window, missing `vote_home` banner, cross-campaign banner reuse rejection, and DB-now-only app read. For HOME, assert `items=[]` while inactive but `campaign_owned_home_banner_ids` still contains every non-null banner ID from all immutable versions.

- [ ] **Step 2: Observe failure before campaign schema**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/promotion_campaign_evaluator.test.sql
```

Expected: non-zero exit because `promotion_campaign_versions` is absent.

- [ ] **Step 3: Implement immutable version schema and evaluator**

`promotion_campaigns` stores identity/code/kind only; seed `CANDY_BOOST_DAY`. Versions have unique `(campaign_id,version)` and `(campaign_id,effective_from)`, `timezone='Asia/Seoul'`, start ISO day/time `1/00:00:00`, end `3/00:00:00`, `extra_bonus_bps=10000`, localized name, surfaces/banner, rollout policy, actor/reason/time. Guard all update/delete.

Private `wallet_private.evaluate_purchase_promotion(p_at timestamptz,p_user_id uuid,p_channel text,p_app_version text,p_app_build integer)` chooses latest effective version, applies half-open KST window and fixed cohort. App `get_active_promotion_campaigns(surface text)` passes only `fixed_db_now()`. For HOME it returns active evaluator rows in `items` and independently aggregates every non-null `home_banner_id` across all versions into `campaign_owned_home_banner_ids`; ordinary `vote_home` consumers must always exclude these IDs. A constraint trigger rejects a `home_banner_id` already owned by another campaign while allowing reuse by versions of the same campaign.

```sql
select v.* into v_version from public.promotion_campaign_versions v
where v.campaign_id=p_campaign_id and v.effective_from<=p_at
order by v.effective_from desc,v.version desc limit 1;
if v_version.id is null or not v_version.is_active then return null; end if;
v_local:=p_at at time zone 'Asia/Seoul';
v_week_start:=date_trunc('week',v_local);
if not (v_local>=v_week_start and v_local<v_week_start+interval '2 days') then return null; end if;
v_cohort:=mod(('x'||substr(encode(digest(v_version.rollout_policy->>'seed'||':'||p_user_id::text,'sha256'),'hex'),1,8))::bit(32)::bigint,10000);
if v_cohort>=(v_version.rollout_policy->>'threshold_bps')::integer then return null; end if;
return v_version;
```

HOME ownership is computed independently of the active evaluator:

```sql
select coalesce(array_agg(distinct home_banner_id order by home_banner_id)
       filter(where home_banner_id is not null),'{}'::integer[])
into v_campaign_owned_home_banner_ids
from public.promotion_campaign_versions;
```

- [ ] **Step 4: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/promotion_campaign_constraints.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/promotion_campaign_evaluator.test.sql
git add supabase/migrations/20260721101000_promotion_campaign_schema.sql supabase/tests/promotion_campaign_evaluator.test.sql supabase/tests/promotion_campaign_constraints.test.sql
git commit -m "feat(promotion): version candy boost policy"
```

Expected: tests exit 0; explicit private time is deterministic and app time cannot be supplied by caller.

### Task 4: Purchase snapshot, allocations, debt, debit, and repair provenance

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721101500_purchase_reward_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721102000_wallet_recovery_debt_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721102500_wallet_debit_repair_schema.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/purchase_reward_schema.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_debt_debit_schema.test.sql`

**Interfaces:** Produces immutable snapshots/base-promo links/resolutions/awards, Star/Bonus debts/events, debit allocations, and repair/approval records.

- [ ] **Step 1: Write constraint and provenance tests**

Assert purchase natural-key uniqueness, same-payload replay versus canonical-payload conflict, bigint overflow rejection, snapshot immutability, provider payload hash distinct from canonical eligibility/purchase hashes, BASE_STAR→STAR and BASE_BONUS/PROMO_BONUS→BONUS, gross=offset+net, debt currency excludes Cotton, debt event running equation, admin debit insufficiency rule, correction-only debt, versioned Finance limits, immutable approval request/decision events, and two-person approver differs from requester.

- [ ] **Step 2: Observe missing snapshot/debt tables**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/purchase_reward_schema.test.sql
```

Expected: non-zero exit at `purchase_reward_snapshots`.

- [ ] **Step 3: Implement exact purchase provenance**

Create `purchase_reward_snapshots`, `purchase_reward_allocations`, `purchase_promotion_resolutions`, immutable resolution events, and `purchase_promotion_awards`. Snapshot stores provider/environment/transaction/purchase key/user/product/quantity/server-derived channel/request app inputs/provider quantity or paid minor/refund basis+denominator/provider occurred time/verified time, separate provider/eligibility/canonical-purchase hashes, unit+base amounts, and policy snapshots. Resolution states are `PENDING_TIME|ELIGIBLE|INELIGIBLE|GRANTED|REJECTED|CANCELLED_BY_REFUND` with only approved transitions.

```sql
create table public.purchase_reward_snapshots (
 id uuid primary key default gen_random_uuid(),receipt_id bigint unique references public.receipts(id) on delete restrict,
 provider text not null,environment text not null,provider_transaction_id text not null,purchase_key text not null unique,
 user_id uuid not null references public.user_profiles(id) on delete restrict,product_id text not null,
 quantity bigint not null check(quantity>0),channel text not null,request_platform text not null,
 request_app_version text not null,request_app_build integer not null,rollout_cohort_version text not null,
 eligibility_input_snapshot jsonb not null,eligibility_payload_hash text not null,
 canonical_purchase_payload_hash text not null,
 provider_original_quantity bigint,provider_paid_amount_minor bigint,provider_currency text,
 refund_ratio_basis text not null check(refund_ratio_basis in ('QUANTITY','AMOUNT')),
 refund_denominator bigint not null check(refund_denominator>0),initial_provider_occurred_at timestamptz,
 verified_at timestamptz not null,source_payload_hash text not null,unit_star_amount bigint not null,
 unit_bonus_amount bigint not null,base_star_amount bigint not null,base_bonus_amount bigint not null,
 base_policy_snapshot jsonb not null,unique(provider,environment,provider_transaction_id),
 unique(id,refund_ratio_basis,refund_denominator)
);
```

- [ ] **Step 4: Implement exact debt/debit/repair provenance**

Create `wallet_recovery_debts`, append-only `wallet_recovery_debt_events`, `wallet_debit_operations`, `wallet_debit_allocations`, `wallet_debit_bucket_allocations`, `wallet_repair_operations`, append-only `wallet_admin_limit_versions`, immutable `wallet_command_approval_requests`, and append-only `wallet_command_approval_events`. Debt currency check permits only Star/Bonus; reasons are `PURCHASE_REFUND|CHARGEBACK|CORRECTION`; events are `CREATE|RECOVER|WAIVE`. Add composite FKs enforcing same user/currency and allocation links.

`wallet_admin_limit_versions` keys `(role_name,action_code,currency_type,version)` and stores positive `max_amount`, `effective_from`, actor/reason; latest effective version is immutable. An approval request stores `approval_reference`, requester, action code, operation key, canonical stored-command payload/hash, the exact limit-version ID, expiry, and creation audit ID. Approval events store `PENDING|APPROVED|REJECTED|EXPIRED`, actor and event audit ID with a unique terminal event. Request/event rows are immutable; the command never accepts an approver ID or re-enters target/currency/direction/amount on approval.

```sql
create table public.wallet_recovery_debts (
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.user_profiles(id) on delete restrict,
 receipt_id bigint,source_refund_allocation_id uuid,source_debit_allocation_id bigint,
 currency_type public.wallet_currency not null check(currency_type in ('STAR_CANDY','BONUS_STAR_CANDY')),
 reason text not null check(reason in ('PURCHASE_REFUND','CHARGEBACK','CORRECTION')),
 owed_amount bigint not null check(owed_amount>0),recovered_amount bigint not null default 0,
 waived_amount bigint not null default 0,row_version bigint not null default 1,
 created_at timestamptz not null default wallet_private.fixed_db_now(),
 check(owed_amount>=recovered_amount+waived_amount),unique(id,user_id,currency_type),
 check((reason in ('PURCHASE_REFUND','CHARGEBACK') and source_refund_allocation_id is not null and source_debit_allocation_id is null)
    or (reason='CORRECTION' and source_refund_allocation_id is null and source_debit_allocation_id is not null))
);
```

Task 8 adds the deferred composite FK and partial unique index for `source_refund_allocation_id` after `purchase_refund_allocations` exists; the debit migration adds the corresponding correction FK immediately.

- [ ] **Step 5: Verify privilege guards and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/purchase_reward_schema.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_debt_debit_schema.test.sql
git add supabase/migrations/20260721101500_purchase_reward_schema.sql supabase/migrations/20260721102000_wallet_recovery_debt_schema.sql supabase/migrations/20260721102500_wallet_debit_repair_schema.sql supabase/tests/purchase_reward_schema.test.sql supabase/tests/wallet_debt_debit_schema.test.sql
git commit -m "feat(wallet): model purchase and recovery provenance"
```

Expected: tests exit 0; immutable rows reject mutation; API roles have no raw DML.

### Task 5: Upgrade the common credit command to recover same-currency debt

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721103000_wallet_debt_aware_credit.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_debt_aware_credit.test.sql`

**Interfaces:** Replaces only the body of wallet-core `credit_star_bonus_with_debt`; keeps its signature/result stable; consumes open debts in age/ID order.

- [ ] **Step 1: Write failing debt recovery tests**

Cover full/partial offset, multiple debts oldest-first, Star never offsets Bonus, Bonus never offsets Star, Cotton allocation never participates, zero-net history absence, replay creates no second RECOVER event, and concurrent credits cannot over-recover.

- [ ] **Step 2: Observe debt offset remains zero**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_debt_aware_credit.test.sql
```

Expected: non-zero assertion because wallet-core body returns debt offset 0.

- [ ] **Step 3: Replace allocation logic under the existing lock**

For each Star/Bonus gross allocation, lock matching open debt by `(created_at,id)` and build a local recovery plan without mutation. Insert the immutable allocation once with final gross/offset/net, then apply the locked debt plan and append linked `RECOVER` events. Create no legacy history when net is zero. Do not expose function execution to client roles.

```sql
v_recovery_plan:='[]'::jsonb;
v_remaining_gross:=p_gross;
for v_debt in select id,owed_amount-recovered_amount-waived_amount as open_amount
 from public.wallet_recovery_debts
 where user_id=p_user_id and currency_type=v_currency
   and owed_amount>recovered_amount+waived_amount
 order by created_at,id for update
loop
  v_take:=least(v_remaining_gross,v_debt.open_amount);
  v_recovery_plan:=v_recovery_plan||jsonb_build_array(jsonb_build_object('debt_id',v_debt.id,'amount',v_take));
  v_remaining_gross:=v_remaining_gross-v_take;
  exit when v_remaining_gross=0;
end loop;
insert into public.wallet_credit_allocations(credit_operation_id,allocation_no,currency_type,reason,
 gross_amount,debt_offset_amount,net_wallet_credit_amount,star_candy_history_id,star_candy_bonus_history_id)
values(v_credit_operation_id,v_allocation_no,v_currency,v_reason,p_gross,p_gross-v_remaining_gross,
 v_remaining_gross,v_star_history_id,v_bonus_history_id) returning id into v_allocation_id;
for v_recovery in select value from jsonb_array_elements(v_recovery_plan)
loop
  update public.wallet_recovery_debts set recovered_amount=recovered_amount+(v_recovery.value->>'amount')::bigint,
    row_version=row_version+1
   where id=(v_recovery.value->>'debt_id')::uuid;
  insert into public.wallet_recovery_debt_events(debt_id,event_type,amount,wallet_credit_allocation_id,operation_key)
  values((v_recovery.value->>'debt_id')::uuid,'RECOVER',(v_recovery.value->>'amount')::bigint,
    v_allocation_id,p_operation_key||':debt:'||(v_recovery.value->>'debt_id'));
end loop;
```

- [ ] **Step 4: Verify every previously migrated credit source and commit**

After concurrency passes, mark mutation route `debt_recovery` migrated with `wallet_debt_aware_credit.test.sql` evidence.

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_debt_aware_credit.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_credit_source_coverage.test.sql
git add supabase/migrations/20260721103000_wallet_debt_aware_credit.sql supabase/tests/wallet_debt_aware_credit.test.sql
git commit -m "feat(wallet): recover debt from future credits"
```

Expected: tests exit 0; same-currency equations hold and core credit regressions remain green.

### Task 6: Atomic verified purchase settlement and mobile/web writer cutover

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721103500_purchase_settlement_commands.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/grant_verified_purchase.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/verify_receipt/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-provider-event/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-operation-worker/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/wallet/purchase-provider-verifiers.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/purchase-settlement.test.ts`

**Interfaces:** Produces service-only `grant_verified_purchase`; every provider endpoint durably receives before verification; the worker refetches/verifies and settles. Existing web RPC signatures become durable-intake compatibility wrappers only: they create/replay a pending legacy receipt plus inbox row and perform no financial mutation. PayPal/PortOne authority lives in the Supabase worker's provider API refetch, not in SQL or caller JSON.

Canonical purchase wire is fixed:

```text
wallet_purchase_result = {contract_version:'wallet.v1',operation_id uuid,replayed boolean,base_star_amount text,base_bonus_amount text,promotion wallet_purchase_promotion_result,wallet wallet_summary}
wallet_purchase_promotion_result = {resolution_id uuid,state PENDING_TIME|ELIGIBLE|INELIGIBLE|GRANTED|REJECTED|CANCELLED_BY_REFUND,campaign_version_id uuid|null,promo_bonus_amount text,domain_code PROMO_REVIEW_REQUIRED|null}
```

Every v1 purchase returns a non-null promotion object, including ineligible/pending purchases. Public text amounts are cast from internal bigint. App-facing success copy may describe Candy Boost only when `promotion.state='GRANTED'`.

- [ ] **Step 1: Write purchase replay/atomicity tests**

Cover mobile `star_candy_bonus` versus web `web_bonus_amount`, product-derived unit amounts × quantity, Apple/Google `QUANTITY` and PayPal/PortOne verified paid-minor/currency `AMOUNT` snapshots, rejection of Apple/Google `AMOUNT` and PayPal/PortOne `QUANTITY`, provider natural-key same-payload replay/conflict before insert, missing product, overflow, debt offset, base settlement independent of promo pause, verified occurred time versus pending time, canonical allowlisted eligibility hash distinct from provider payload hash, inbox success CAS in the same financial transaction, and rollback leaving inbox retryable. Replay must return the original snapshot/result with `replayed=true` and create no second snapshot/allocation/resolution. Edge tests must prove the durable inbox commit exists before any Apple/Google/PayPal/PortOne network verifier runs, transient verification failure leaves that same row retryable, and no verifier output can bypass the matching lease token.

- [ ] **Step 2: Observe command absence**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/grant_verified_purchase.test.sql
```

Expected: non-zero exit because `grant_verified_purchase` is absent.

- [ ] **Step 3: Implement the service-only command**

The command consumes the fixed signature above. It derives channel/source from a closed provider registry (`APPLE|GOOGLE → MOBILE/mobile_purchase`, `PAYPAL|PORTONE → WEB/web_purchase`), rejects unknown request-context keys, builds an allowlisted eligibility snapshot, and computes separate eligibility, provider-verification, and canonical purchase hashes. It acquires user advisory/profile then a provider-source advisory lock, checks the provider natural key before any insert, and returns the original result only when the canonical hash matches. It then locks product/snapshot, derives Star and the channel-specific Bonus from `products`, applies quantity with checked integer arithmetic, calls debt-aware credit, creates resolution, and completes inbox through matching lease CAS. It never accepts reward amount, channel, source key, Bonus policy, or campaign result from caller.

```sql
create or replace function public.grant_verified_purchase(
 p_provider text,p_environment text,p_provider_transaction_id text,p_user_id uuid,p_product_id text,
 p_quantity bigint,p_provider_occurred_at timestamptz,p_refund_ratio_basis text,
 p_provider_original_quantity bigint,p_provider_paid_amount_minor bigint,p_provider_currency text,
 p_verification_payload_hash text,p_request_context jsonb,p_operation_key text,p_inbox_id uuid,p_lease_token uuid
) returns public.wallet_purchase_result language plpgsql security definer set search_path='' as $$
declare v_product public.products%rowtype;v_star_numeric numeric;v_bonus_numeric numeric;
        v_star bigint;v_bonus bigint;v_snapshot_id uuid;v_resolution_id uuid;
        v_evaluation public.wallet_promotion_evaluation;v_resolution_state text;v_channel text;v_source_key text;
        v_expected_refund_basis text;
        v_refund_denominator bigint;v_eligibility_input jsonb;v_eligibility_hash text;
        v_purchase_hash text;v_existing public.purchase_reward_snapshots%rowtype;
begin
  if exists(select 1 from jsonb_object_keys(p_request_context) k
            where k not in ('platform','app_version','app_build','cohort_version')) then
    raise exception using errcode='22023',message='PURCHASE_UNKNOWN_CONTEXT_FIELD';
  end if;
  select channel,source_key,refund_ratio_basis into strict v_channel,v_source_key,v_expected_refund_basis
    from wallet_private.normalized_purchase_provider(p_provider,p_environment);
  if p_refund_ratio_basis<>v_expected_refund_basis then
    raise exception using errcode='22023',message='PURCHASE_PROVIDER_REFUND_BASIS_MISMATCH';
  end if;
  if p_refund_ratio_basis='QUANTITY' then
    if p_provider_original_quantity is null or p_provider_original_quantity<=0
       or p_provider_original_quantity<>p_quantity
       or p_provider_paid_amount_minor is not null or p_provider_currency is not null then
      raise exception using errcode='22023',message='PURCHASE_INVALID_QUANTITY_BASIS';
    end if;
    v_refund_denominator:=p_provider_original_quantity;
  elsif p_refund_ratio_basis='AMOUNT' then
    if p_provider_paid_amount_minor is null or p_provider_paid_amount_minor<=0
       or p_provider_currency is null or p_provider_currency !~ '^[A-Z]{3}$'
       or p_provider_original_quantity is not null then
      raise exception using errcode='22023',message='PURCHASE_INVALID_AMOUNT_BASIS';
    end if;
    v_refund_denominator:=p_provider_paid_amount_minor;
  else raise exception using errcode='22023',message='PURCHASE_INVALID_REFUND_BASIS'; end if;
  v_eligibility_input:=jsonb_build_object('platform',p_request_context->>'platform','channel',v_channel,
    'app_version',p_request_context->>'app_version','app_build',(p_request_context->>'app_build')::integer,
    'cohort_version',p_request_context->>'cohort_version','cohort_user_id',p_user_id);
  v_eligibility_hash:=encode(digest(convert_to(v_eligibility_input::text,'UTF8'),'sha256'),'hex');
  v_purchase_hash:=encode(digest(convert_to(jsonb_build_object(
    'provider',p_provider,'environment',p_environment,'provider_transaction_id',p_provider_transaction_id,
    'user_id',p_user_id,'product_id',p_product_id,'quantity',p_quantity,
    'provider_occurred_at',p_provider_occurred_at,'refund_ratio_basis',p_refund_ratio_basis,
    'provider_original_quantity',p_provider_original_quantity,'provider_paid_amount_minor',p_provider_paid_amount_minor,
    'provider_currency',p_provider_currency,'provider_payload_hash',p_verification_payload_hash,
    'eligibility_payload_hash',v_eligibility_hash,'channel',v_channel)::text,'UTF8'),'sha256'),'hex');
  perform wallet_private.lock_wallet_user(p_user_id);
  perform pg_advisory_xact_lock(wallet_private.purchase_source_lock_key(p_provider,p_environment,p_provider_transaction_id));
  select * into v_existing from public.purchase_reward_snapshots
   where provider=p_provider and environment=p_environment and provider_transaction_id=p_provider_transaction_id for share;
  if found then
    if v_existing.canonical_purchase_payload_hash<>v_purchase_hash then
      raise exception using errcode='P0001',message='OP_IDEMPOTENCY_CONFLICT';
    end if;
    perform wallet_private.complete_provider_event(p_inbox_id,p_lease_token,'PURCHASE_SNAPSHOT',v_existing.id);
    return wallet_private.build_purchase_result(v_existing.id,true);
  end if;
  select * into strict v_product from public.products where id=p_product_id for share;
  v_star_numeric:=coalesce(v_product.star_candy,0)::numeric*p_quantity::numeric;
  v_bonus_numeric:=case when v_channel='WEB' then coalesce(v_product.web_bonus_amount,0)::numeric
                        else coalesce(v_product.star_candy_bonus,0)::numeric end*p_quantity::numeric;
  if v_star_numeric<0 or v_bonus_numeric<0
     or v_star_numeric>2147483647::numeric or v_bonus_numeric>2147483647::numeric then
    raise exception using errcode='P0001',message='PURCHASE_AMOUNT_OUT_OF_RANGE';
  end if;
  v_star:=v_star_numeric::bigint;
  v_bonus:=v_bonus_numeric::bigint;
  insert into public.purchase_reward_snapshots(provider,environment,provider_transaction_id,purchase_key,
    user_id,product_id,quantity,channel,request_platform,request_app_version,request_app_build,
    rollout_cohort_version,eligibility_input_snapshot,eligibility_payload_hash,canonical_purchase_payload_hash,
    provider_original_quantity,provider_paid_amount_minor,provider_currency,refund_ratio_basis,
    refund_denominator,initial_provider_occurred_at,verified_at,source_payload_hash,unit_star_amount,
    unit_bonus_amount,base_star_amount,base_bonus_amount,base_policy_snapshot)
  values(p_provider,p_environment,p_provider_transaction_id,p_provider||':'||p_environment||':'||p_provider_transaction_id,
    p_user_id,p_product_id,p_quantity,v_channel,p_request_context->>'platform',
    p_request_context->>'app_version',(p_request_context->>'app_build')::integer,
    p_request_context->>'cohort_version',v_eligibility_input,v_eligibility_hash,v_purchase_hash,
    p_provider_original_quantity,p_provider_paid_amount_minor,p_provider_currency,p_refund_ratio_basis,
    v_refund_denominator,p_provider_occurred_at,wallet_private.fixed_db_now(),p_verification_payload_hash,
    v_product.star_candy,case when v_channel='WEB' then v_product.web_bonus_amount else v_product.star_candy_bonus end,
    v_star,v_bonus,jsonb_build_object('product_id',v_product.id,'channel',v_channel,
      'star_candy',v_product.star_candy,'base_bonus',case when v_channel='WEB' then v_product.web_bonus_amount else v_product.star_candy_bonus end))
    returning id into v_snapshot_id;
  perform wallet_private.credit_star_bonus_with_debt(p_user_id,v_source_key,p_operation_key,v_star,
    v_bonus,null,'PURCHASE','purchase_snapshot',v_snapshot_id::text,v_eligibility_input);
  if p_provider_occurred_at is null then
    v_resolution_state:='PENDING_TIME';
  else
    v_evaluation:=wallet_private.evaluate_purchase_promotion(p_provider_occurred_at,p_user_id,
      v_channel,p_request_context->>'app_version',(p_request_context->>'app_build')::integer);
    v_resolution_state:=case when v_evaluation.campaign_version_id is null then 'INELIGIBLE' else 'ELIGIBLE' end;
  end if;
  insert into public.purchase_promotion_resolutions(snapshot_id,status,verified_provider_occurred_at,
    campaign_version_id,rollout_policy_snapshot,eligibility_payload_hash,resolved_at,reason_code,row_version)
  values(v_snapshot_id,v_resolution_state,p_provider_occurred_at,v_evaluation.campaign_version_id,
    v_evaluation.rollout_policy,v_eligibility_hash,
    case when v_resolution_state='PENDING_TIME' then null else wallet_private.fixed_db_now() end,
    case when v_resolution_state='PENDING_TIME' then 'PROMO_REVIEW_REQUIRED' else null end,1)
  returning id into v_resolution_id;
  perform wallet_private.complete_provider_event(p_inbox_id,p_lease_token,'PURCHASE_SNAPSHOT',v_snapshot_id);
  return wallet_private.build_purchase_result(v_snapshot_id);
end $$;
```

`wallet_private.build_purchase_result(snapshot_id,replayed)` joins the mandatory resolution and same-snapshot wallet summary, emits `domain_code='PROMO_REVIEW_REQUIRED'` only for `PENDING_TIME`, emits promo amount `'0'` before a grant, and never returns a null promotion object.

- [ ] **Step 4: Replace mobile and web split commits with receive-then-verify flows**

`verify_receipt` first authenticates the owner and performs only bounded envelope/signature-shape validation, calls `wallet-provider-event`, and waits for transaction A to commit the raw Apple/Google proof under the provider natural key. Only after that commit does it invoke the same lease/worker path used by cron. The worker verifies Apple signed JWS certificate chain/environment/transaction or Google Play API purchase token/environment/original quantity, then supplies `QUANTITY` to `grant_verified_purchase`. A synchronous success returns the canonical purchase result; a transient verifier/DB failure returns the existing retryable 5xx while the inbox remains `PENDING`, and a retry or background worker resolves the same operation key. No handler may call the provider before the durable receive promise succeeds.

For web compatibility, `CREATE OR REPLACE` the baseline `process_paypal_capture` and `process_portone_capture` signatures without editing `supabase/migrations/_legacy/picnic_web_handoff_2026_04_24`. Add a unique provider-scope intake index covering `receipts(platform,environment,receipt_hash)` while status is `pending_verification|completed`; under the provider natural-key advisory lock, each service-role-only wrapper rejects malformed identity/environment fields, calls the inbox receive helper, and creates or replays that pending receipt. It ignores caller Star/Bonus/status/amount as settlement authority and returns non-null legacy JSON with the stable `receipt_id` and `pending:true`, but performs no profile/history/ledger mutation. This keeps the deployed `picnic-web` callers source-compatible while making settlement asynchronous.

The worker's shared verifier refetches PayPal order/capture with Supabase Edge secrets `PAYPAL_CLIENT_ID`/`PAYPAL_CLIENT_SECRET`, or PortOne payment with `PORTONE_API_SECRET`; it accepts only completed/paid state, derives user/product from provider-owned custom metadata, converts the provider amount/currency to exact positive minor units without floating point, and supplies `AMOUNT`. It rejects any mismatch with the intake claims or DB product price. On financial commit it marks the same pending receipt completed, completes the inbox lease CAS, and never uses caller reward/channel fields. Recorded-provider tests cover secret absence, transient 5xx, terminal mismatch, forged wrapper fields, replay, and eventual receipt/snapshot/credit completion. The existing read-only callers are `/Users/charlie.hyun/Repositories/picnic-web/app/api/payment/paypal/capture-order/route.ts` and `/Users/charlie.hyun/Repositories/picnic-web/app/api/payment/portone/webhook/route.ts`; rollout records their deployed commit and keeps `web_purchase` unmigrated if either no longer treats a non-null `receipt_id` response as success. Remove every explicit profile Bonus update so the strict trigger runs once.

- [ ] **Step 5: Reach closed 100% credit-source coverage**

Mark credit sources and mutation routes `mobile_purchase` and `web_purchase` migrated only after focused tests. `admin_adjustment` remains false until Task 10; therefore release flag stays blocked. Scan Edge/SQL for direct positive writers and classify every match as read, test, or delegated command evidence.

- [ ] **Step 6: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/grant_verified_purchase.test.sql
deno test --allow-all supabase/functions/tests/wallet/purchase-settlement.test.ts
git add supabase/migrations/20260721103500_purchase_settlement_commands.sql supabase/tests/grant_verified_purchase.test.sql supabase/functions/verify_receipt/index.ts supabase/functions/wallet-provider-event/index.ts supabase/functions/wallet-operation-worker/index.ts supabase/functions/_shared/wallet/purchase-provider-verifiers.ts supabase/functions/tests/wallet/purchase-settlement.test.ts
git commit -m "feat(purchase): settle verified rewards atomically"
```

Expected: tests exit 0; all four provider events are committed before network verification, provider event survives settlement failure, legacy web wrappers return a stable pending receipt without crediting, no purchase writer performs raw financial DML, and Edge fixtures match the canonical purchase wire with decimal-string amounts.

### Task 7: Resolve and award Candy Boost from provider time

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721104000_purchase_promotion_commands.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/purchase_promotion_commands.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/purchase_promotion_race.test.sql`

**Interfaces:** Produces service-only `resolve_purchase_promotion` and promo-award branch inside `grant_verified_purchase`; consumes immutable eligibility input and campaign version.

- [ ] **Step 1: Write formula, time, pause, and race tests**

Test exact integer values around division remainders; only provider occurred time selects version/window; latest inactive means ineligible; `PENDING_TIME` uses stored request context when resolved; write pause leaves base `SUCCEEDED` and a `PROMOTION_AWARD` inbox row; concurrent resolve/refund leaves one terminal result.

- [ ] **Step 2: Observe missing resolution command**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/purchase_promotion_commands.test.sql
```

Expected: non-zero exit because `resolve_purchase_promotion` is absent.

- [ ] **Step 3: Implement deterministic resolution and award**

Lock user → snapshot → resolution. Re-evaluate only the snapshot's allowlisted platform/channel/app/cohort input at `verified_provider_occurred_at`. Calculate:

```sql
v_promo_numeric:=floor(((v_snapshot.base_star_amount::numeric+v_snapshot.base_bonus_amount::numeric)
                        *v_version.extra_bonus_bps::numeric)/10000::numeric);
if v_promo_numeric<0 or v_promo_numeric>9223372036854775807::numeric then
  raise exception using errcode='22003',message='PROMOTION_AMOUNT_OUT_OF_RANGE';
end if;
v_promo_bonus:=v_promo_numeric::bigint;
```

For an eligible write-enabled purchase, insert award, PROMO_BONUS link, debt-aware Bonus allocation/history, resolution event, terminal resolution, audit, and inbox success in one transaction. If a refund exists, transition to `CANCELLED_BY_REFUND` and never award.

After the race test passes, mark mutation route `promotion_award` migrated with the command test evidence.

- [ ] **Step 4: Verify both lock orders and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/purchase_promotion_commands.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/purchase_promotion_race.test.sql
git add supabase/migrations/20260721104000_purchase_promotion_commands.sql supabase/tests/purchase_promotion_commands.test.sql supabase/tests/purchase_promotion_race.test.sql
git commit -m "feat(promotion): award candy boost by provider time"
```

Expected: tests exit 0; award/refund races deadlock neither and cannot both win incorrectly.

### Task 8: Cumulative refund reversal and debt creation

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721104500_purchase_refund_commands.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/refund_verified_purchase.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/refund_credit_concurrency.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/google-play-notifications/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/refund-settlement.test.ts`

**Interfaces:** Produces immutable refund events/allocations and service-only `refund_verified_purchase`; Google RTDN uses durable inbox and the operation worker.

- [ ] **Step 1: Write cumulative math and gross-provenance tests**

For each base component use `new_target = floor(original_gross * cumulative_numerator / denominator)` and `incremental = new_target - prior_target`; when numerator equals denominator force target to original gross. For PROMO_BONUS set cumulative target to full original gross on the first valid refund and keep that target on later refunds, so later incremental is zero. Test stored cumulative target as well as incremental across first/replayed/later refunds, duplicate/conflict, decreasing cumulative rejection, refund after debt-offset net zero, Bonus order promo→base then original bucket→other earliest expiry, deficit debt, Cotton unchanged, and rollback. For every deficit assert the immutable refund allocation exists before debt creation, debt `source_refund_allocation_id` matches it by user/currency composite FK, CREATE event references the same allocation, and a second debt for that allocation is rejected.

- [ ] **Step 2: Observe missing refund command**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/refund_verified_purchase.test.sql
```

Expected: non-zero exit because `refund_verified_purchase` is absent.

- [ ] **Step 3: Implement refund with fixed lock/CAS order**

Acquire user lock, profile, snapshot, resolution, prior refunds/allocations, Star/Bonus buckets, open debt. Validate provider refund basis against snapshot composite FK. Under those locks, build a local recovery plan without mutation, insert the immutable refund allocation once with its final `incremental=wallet_recovered+debt_created` amounts, apply the locked bucket plan, then append debt and CREATE event referencing that allocation. Cancel unresolved promo or reverse granted promo, audit, and mark matching inbox lease succeeded in the same transaction.

`purchase_refund_allocations` includes `user_id` and `UNIQUE(id,user_id,currency_type)`. `wallet_recovery_debts` stores nullable `receipt_id` and `source_refund_allocation_id`; `(source_refund_allocation_id,user_id,currency_type)` references that allocation composite, is partial-unique when non-null, and the source XOR/reason check requires it for `PURCHASE_REFUND|CHARGEBACK`. A refund CREATE event also stores the same `source_refund_allocation_id` and allocation number. No helper may mutate wallet buckets before the immutable allocation row has been inserted.

After refund/credit concurrency passes, mark mutation route `refund_reversal` migrated with both test files as evidence.

```sql
if v_snapshot.refund_denominator<=0 then
  raise exception using errcode='22012',message='REFUND_INVALID_DENOMINATOR';
end if;
v_target_numeric:=case
 when v_component='PROMO_BONUS' then v_original_gross::numeric
 when p_cumulative_refunded_numerator=v_snapshot.refund_denominator then v_original_gross::numeric
 else floor(v_original_gross::numeric*p_cumulative_refunded_numerator::numeric
            /v_snapshot.refund_denominator::numeric) end;
if v_target_numeric<0 or v_target_numeric>9223372036854775807::numeric then
  raise exception using errcode='22003',message='REFUND_AMOUNT_OUT_OF_RANGE';
end if;
v_new_target:=v_target_numeric::bigint;
select coalesce(max(cumulative_target_amount),0) into v_prior_target
 from public.purchase_refund_allocations where original_reward_allocation_id=v_original_allocation_id;
v_incremental:=v_new_target-v_prior_target;
if v_incremental<0 then raise exception using errcode='P0001',message='REFUND_CUMULATIVE_DECREASE'; end if;
v_recovery_plan:=wallet_private.plan_refund_recovery(
  v_snapshot.user_id,v_currency,v_component,v_original_allocation_id,v_incremental);
v_wallet_recovered:=(v_recovery_plan->>'wallet_recovered_amount')::bigint;
v_debt_created:=v_incremental-v_wallet_recovered;
insert into public.purchase_refund_allocations(refund_event_id,user_id,original_reward_allocation_id,
  component,currency_type,cumulative_target_amount,incremental_reversal_amount,
  wallet_recovered_amount,debt_created_amount,operation_key)
values(v_refund_event_id,v_snapshot.user_id,v_original_allocation_id,v_component,v_currency,
  v_new_target,v_incremental,v_wallet_recovered,v_debt_created,p_operation_key)
returning id into v_refund_allocation_id;
perform wallet_private.apply_locked_refund_recovery_plan(v_recovery_plan,v_refund_allocation_id,p_operation_key);
if v_debt_created>0 then
  insert into public.wallet_recovery_debts(user_id,receipt_id,source_refund_allocation_id,
    currency_type,reason,owed_amount)
  values(v_snapshot.user_id,v_snapshot.receipt_id,v_refund_allocation_id,
    v_currency,'PURCHASE_REFUND',v_debt_created) returning id into v_debt_id;
  insert into public.wallet_recovery_debt_events(debt_id,event_type,amount,operation_key,
    allocation_no,source_refund_allocation_id)
  values(v_debt_id,'CREATE',v_debt_created,p_operation_key||':debt:'||v_component,
    v_component_no,v_refund_allocation_id);
end if;
```

- [ ] **Step 4: Replace Google hard-coded reversal**

RTDN verifies package/subscription/product token and provider refund state/time through Google API, durably receives the normalized event, and never maps hard-coded reward amounts or updates profile/history. Worker calls only `refund_verified_purchase`. Invalid provider payload is DEAD; transient provider/DB failure schedules retry.

- [ ] **Step 5: Run race and Edge verification, then commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/refund_verified_purchase.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/refund_credit_concurrency.test.sql
deno test --allow-all supabase/functions/tests/wallet/refund-settlement.test.ts
git add supabase/migrations/20260721104500_purchase_refund_commands.sql supabase/tests/refund_verified_purchase.test.sql supabase/tests/refund_credit_concurrency.test.sql supabase/functions/google-play-notifications/index.ts supabase/functions/tests/wallet/refund-settlement.test.ts
git commit -m "feat(wallet): reverse verified refunds into debt"
```

Expected: tests exit 0; cumulative targets are exact, concurrency creates neither excess recovery nor duplicate debt.

### Task 9: Named admin read DTOs, signed cursors, and masking

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721105000_wallet_admin_read_rpcs.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_reads.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_cursor.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_read_shape_contract.test.sql`

**Interfaces:** Produces every fixed admin read listed above as named SQL composites; consumes `admin_user_roles → admin_roles.name`, `admin_whitelist`, ledgers, operations, alerts, invariants, heartbeats.

- [ ] **Step 1: Write role, masking, filter, and cursor failures first**

Test non-admin denial, inactive whitelist denial, Operator/Finance/Super actor context, unknown filter rejection, limit outside 1–100, reversed time range, cursor signature tamper, same timestamp pagination, empty page with string bigint `total_count`, stable first-page `snapshot_at`, and masked provider identifiers.

- [ ] **Step 2: Observe missing actor context**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_reads.test.sql
```

Expected: non-zero exit at `admin_get_wallet_actor_context()`.

- [ ] **Step 3: Define named composite/page types**

Create `wallet_admin_actor_context(actor_id uuid,actor_role text,permissions text[])`, the existing summary/list composites, plus `wallet_admin_campaign_version_item/page`, `wallet_admin_debt_item/page`, `wallet_admin_runtime_flags`, and `wallet_admin_audit_item/page`. Public actor roles are exactly `OPERATOR|FINANCE_ADMIN|SUPER_ADMIN`; existing DB names map internally. Because admin reads call PostgREST directly, public composites declare all money, balance, debt, delta, count, attempt, and potentially 64-bit version fields as `text`; every page declares `total_count text`. SQL casts internal bigint with `::text`, and generated wire types remain `string` until the admin domain layer parses bigint.

```text
wallet_admin_campaign_version_item = {id uuid,campaign_id uuid,version text,effective_from timestamptz,is_active boolean,timezone text,weekly_start_isodow integer,weekly_start_time time,weekly_end_isodow integer,weekly_end_time time,extra_bonus_bps text,display_name jsonb,show_home_banner boolean,show_in_store boolean,home_banner_id integer|null,rollout_policy jsonb,change_reason text,created_by uuid,created_at timestamptz,audit_id uuid}
wallet_admin_debt_item = {id uuid,user_id uuid,currency wallet_currency,reason text,status text,owed_amount text,recovered_amount text,waived_amount text,outstanding_amount text,source_refund_allocation_id uuid|null,source_debit_allocation_id text|null,row_version text,created_at timestamptz,updated_at timestamptz}
wallet_admin_runtime_flags = {flag_version text,values jsonb,changed_at timestamptz,changed_by uuid,snapshot_at timestamptz}
wallet_admin_audit_item = {id uuid,actor_user_id uuid,actor_role text,action_code text,resource_type text,resource_id text,operation_id uuid|null,request_id uuid,reason text,cs_ticket text|null,before_json jsonb,after_json jsonb,campaign_version_id uuid|null,created_at timestamptz}
```

The four added reads use the exact fixed signatures above. Campaign/debt/audit lists use signed cursors and masking. Audit safe JSON omits email, profile PII, provider token/signature, and raw payload while retaining allowlisted before/after operational fields. Runtime `values` contains exactly the fixed flag keys/modes. A shape-contract test compares `pg_attribute` name/order/type/nullability for all four composites/pages with the admin wire manifest, explicitly asserts `home_banner_id` is SQL `integer`, and rejects alias or numeric-bigint drift.

- [ ] **Step 4: Implement safe reads with a shared actor assertion**

`wallet_private.assert_wallet_admin_reader()` derives `auth.uid()`, verifies active whitelist and exact role name `Operator|Finance Admin|Super Admin`, and returns actor context. List functions accept only allowlisted filter keys, decode/verify HMAC cursor `{snapshot_at,created_at,id}`, order `(created_at DESC,id DESC)`, and never expose encrypted/raw provider payload. Grant only these read functions to authenticated.

```sql
create or replace function wallet_private.admin_permissions_for_role(p_role_name text)
returns text[] language sql stable security definer set search_path='' as $$
 select coalesce(array_agg(p.permission_key order by array_position(array[
   'wallet.read','wallet.alert.ack','wallet.operation.retry','wallet.repair.preview',
   'wallet.adjust.star_bonus','wallet.adjust.star_bonus.approve','wallet.debt.waive',
   'promotion.version.create','wallet.correction.apply','wallet.repair.execute',
   'wallet.flags.emergency_disable']::text[],p.permission_key)),'{}'::text[])
 from public.admin_roles r join public.admin_role_permissions rp on rp.role_id=r.id
 join public.admin_permissions p on p.id=rp.permission_id where r.name=p_role_name
$$;

create or replace function wallet_private.assert_wallet_admin_reader()
returns public.wallet_admin_actor_context language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid();v_result public.wallet_admin_actor_context;
begin
  if v_actor is null then raise exception using errcode='42501',message='ADMIN_AUTH_REQUIRED'; end if;
  select row(v_actor,case r.name when 'Operator' then 'OPERATOR' when 'Finance Admin' then 'FINANCE_ADMIN'
                    when 'Super Admin' then 'SUPER_ADMIN' end,
             wallet_private.admin_permissions_for_role(r.name))::public.wallet_admin_actor_context into v_result
  from public.admin_user_roles ur join public.admin_roles r on r.id=ur.role_id
  join public.admin_whitelist w on lower(w.email)=lower((select email from public.user_profiles where id=v_actor))
  where ur.user_id=v_actor and w.is_active and r.name in ('Operator','Finance Admin','Super Admin')
  order by case r.name when 'Super Admin' then 1 when 'Finance Admin' then 2 else 3 end limit 1;
  if v_result.actor_id is null then raise exception using errcode='42501',message='ADMIN_ROLE_REQUIRED'; end if;
  return v_result;
end $$;
```

`admin_permissions.permission_key` is unique and restricted to: `wallet.read`, `wallet.alert.ack`, `wallet.operation.retry`, `wallet.repair.preview`, `wallet.adjust.star_bonus`, `wallet.adjust.star_bonus.approve`, `wallet.debt.waive`, `promotion.version.create`, `wallet.correction.apply`, `wallet.repair.execute`, `wallet.flags.emergency_disable`. Actor-context tests compare each role's returned array byte-for-byte with this allowlist and reject colon aliases such as `wallet:read`.

The assignment matrix is exact: Operator gets the first four keys; Finance Admin gets those plus `wallet.adjust.star_bonus` and `wallet.debt.waive`; Super Admin gets all eleven. No legacy `is_admin` boolean implicitly adds a permission.

- [ ] **Step 5: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_reads.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_cursor.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_read_shape_contract.test.sql
git add supabase/migrations/20260721105000_wallet_admin_read_rpcs.sql supabase/tests/wallet_admin_reads.test.sql supabase/tests/wallet_admin_cursor.test.sql supabase/tests/wallet_admin_read_shape_contract.test.sql
git commit -m "feat(admin): expose safe wallet operations reads"
```

Expected: tests exit 0; raw table SELECT is denied while approved reads return stable pages.

### Task 10: Admin RBAC, approvals, repair, adjustment, waiver, and flags

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721105500_wallet_admin_command_rpcs.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721110000_wallet_admin_rbac_and_direct_writer_lockdown.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_commands.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_rbac_privileges.test.sql`

**Interfaces:** Produces every fixed `(p_actor_user_id uuid,p_request jsonb)` admin command listed above and private `assert_wallet_admin_actor`; completes `admin_adjustment` credit coverage.

- [ ] **Step 1: Write permission matrix and audit rollback tests**

Operator: reads, alert ACK, retry enqueue, preview only. Finance: bounded Star/Bonus adjust and waiver with reason/ticket. Super: campaign/flag/correction/repair and over-limit Finance approval. Test actor/approver difference, versioned server amount limits, under-limit immediate apply, over-limit REQUEST with zero wallet delta, immutable stored payload, APPROVE by a different Super Admin, requester self-approval/expired/hash/version rejection, optimistic version, request replay/conflict, an identical retry replay returning the byte-identical original success after the inbox version advanced, malformed UUID/bigint returning a stable domain envelope without invoking the failure recorder, Cotton rejection, insufficient admin debit atomic rejection, correction-only debt, audit failure rollback, every authenticated direct-execute denial, and service-wrapper calls for each DB role.

- [ ] **Step 2: Observe missing fixed commands**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_commands.test.sql
```

Expected: non-zero exit at `admin_request_wallet_operation_retry`.

- [ ] **Step 3: Implement the fixed authenticated admin commands**

First add/backfill `admin_permissions.permission_key`, then enforce a unique/allowlist check for the eleven dotted keys and idempotently seed exact wallet roles/capabilities without assigning a user:

```sql
insert into public.admin_roles(name,description) values
 ('Operator','Wallet read, alert ACK, retry request, repair preview'),
 ('Finance Admin','Operator capabilities plus bounded Star/Bonus adjustment and debt waiver'),
 ('Super Admin','Finance capabilities plus campaign, correction, repair execution, emergency flags')
on conflict(name) do nothing;
insert into public.admin_permissions(permission_key,resource,action,description) values
 ('wallet.read','wallet','read','Read safe wallet RPCs'),
 ('wallet.alert.ack','wallet_alert','ack','Acknowledge ops alert'),
 ('wallet.operation.retry','wallet_operation','retry','Request eligible retry'),
 ('wallet.repair.preview','wallet_repair','preview','Preview wallet repair'),
 ('wallet.adjust.star_bonus','wallet_adjust','execute','Adjust Star or Bonus'),
 ('wallet.adjust.star_bonus.approve','wallet_adjust','approve','Approve over-limit adjustment'),
 ('wallet.debt.waive','wallet_debt','waive','Waive debt with audit'),
 ('promotion.version.create','promotion','version','Append promotion version'),
 ('wallet.correction.apply','wallet_correction','execute','Execute approved correction'),
 ('wallet.repair.execute','wallet_repair','execute','Execute approved repair'),
 ('wallet.flags.emergency_disable','wallet_flag','emergency','Change emergency flags')
on conflict(permission_key) do nothing;
```

Insert `admin_role_permissions` from a fixed role/capability value table with `ON CONFLICT(role_id,permission_id) DO NOTHING`. Do not insert or update `admin_user_roles`/`admin_whitelist` in the migration. Add private break-glass-only `assign_wallet_admin_role(p_actor_user_id,p_target_user_id,p_role_name,p_reason,p_request_id,p_approval_id)`. Normally it requires an active wallet Super Admin actor. Every Super Admin assignment requires an unused approval from a different active-whitelisted approver bound to target/role/request hash. While wallet Super count is zero, bootstrap requires both actor and approver to be active-whitelisted legacy `user_profiles.is_super_admin=true`. It appends assignment and audit in one transaction, consumes approval once, and is revoked from API roles. This permits explicit first assignment without automatic elevation.

Create append-only `wallet_admin_command_executions(actor_user_id,action_code,request_id,canonical_request_hash,response_envelope public.wallet_stable_command_envelope,created_at)` with unique `(actor_user_id,action_code,request_id)`. `response_envelope` stores the exact successful or stateful domain result and an immutable trigger blocks update/delete. Before any state check or mutation, every command takes `admin_request_lock_key(actor,action,request_id)`, looks up this row, returns its stored envelope when the hash matches, and returns `ADMIN_REQUEST_CONFLICT` when it does not. `wallet_private.finish_admin_command(...)` inserts the execution row in the same transaction as mutation/audit and returns that exact envelope. Thus a rolled-back infrastructure failure stores neither mutation nor replay result, while a committed retry request can never be re-evaluated against its now-incremented inbox version.

Each exact `(p_actor_user_id uuid,p_request jsonb)` signature rejects unknown keys and any JSON actor/approver ID, validates the passed server-derived actor against active whitelist/DB role, operation/request replay hash, reason/ticket/amount/approval/version. Retry only advances eligible PENDING retry time; alert command only ACKs; preview persists canonical input/result hash; execute requires matching unexpired preview hash and a separate approver stored in the approval record; repair replays inbox, appends correction, or rebuilds projection according to command type. Waiver appends `WAIVE`; emergency flag change enforces all flag implications.

`admin_adjust_star_bonus` has an exact action union. `REQUEST` allows only `{action:'REQUEST',request_id,operation_key,user_id,direction,currency,amount,reason,cs_ticket,approval_reference:null}`. It snapshots the latest effective `wallet_admin_limit_versions` row. At or below the Finance limit it applies atomically; above the limit it makes no wallet/ledger change and inserts an immutable approval request plus `PENDING` event/audit, returning `PENDING_APPROVAL` and `approval_reference`. `APPROVE` allows only `{action:'APPROVE',request_id,operation_key,approval_reference,reason,cs_ticket}`; user/currency/direction/amount are forbidden. A different active-whitelisted Super Admin locks the pending request, verifies expiry, original canonical hash and limit version, executes only the stored payload, and appends one immutable `APPROVED` event and audit in the same financial transaction. Requester approval, payload re-entry, expired/terminal approval, and replay with a different body are rejected.

```sql
create or replace function public.admin_request_wallet_operation_retry(p_actor_user_id uuid,p_request jsonb)
returns public.wallet_stable_command_envelope language plpgsql security definer set search_path='' as $$
declare v_actor public.wallet_admin_actor_context;
        v_operation_id uuid;v_inbox_id uuid;v_request_id uuid;v_expected_version bigint;
        v_reason text;v_cs_ticket text;v_audit_id uuid;v_idempotency_key text;
        v_request_hash text;v_prior public.wallet_admin_command_executions%rowtype;
        v_result public.wallet_stable_command_envelope;
begin
  begin
    v_actor:=wallet_private.assert_wallet_admin_actor(p_actor_user_id);
  exception when insufficient_privilege then
    return wallet_private.command_failure_envelope('ADMIN_ROLE_REQUIRED',false,null);
  end;
  if exists(select 1 from jsonb_object_keys(p_request) k
    where k not in ('request_id','operation_id','expected_version','reason','cs_ticket')) then
    return wallet_private.command_failure_envelope('ADMIN_UNKNOWN_REQUEST_FIELD',false,null);
  end if;
  v_operation_id:=wallet_private.uuid_or_null(p_request->>'operation_id');
  v_request_id:=wallet_private.uuid_or_null(p_request->>'request_id');
  v_expected_version:=wallet_private.nonnegative_bigint_or_null(p_request->>'expected_version');
  if v_operation_id is null or v_request_id is null or v_expected_version is null then
    return wallet_private.command_failure_envelope('ADMIN_INVALID_REQUEST',false,v_operation_id);
  end if;
  v_reason:=nullif(btrim(p_request->>'reason'),'');
  v_cs_ticket:=nullif(btrim(p_request->>'cs_ticket'),'');
  v_request_hash:=wallet_private.canonical_admin_request_hash(p_request);
  perform pg_advisory_xact_lock(wallet_private.admin_request_lock_key(
    p_actor_user_id,'REQUEST_OPERATION_RETRY',v_request_id));
  select * into v_prior from public.wallet_admin_command_executions
   where actor_user_id=p_actor_user_id and action_code='REQUEST_OPERATION_RETRY'
     and request_id=v_request_id;
  if found then
    if v_prior.canonical_request_hash<>v_request_hash then
      return wallet_private.command_failure_envelope('ADMIN_REQUEST_CONFLICT',false,v_operation_id);
    end if;
    return v_prior.response_envelope;
  end if;
  if v_reason is null or v_cs_ticket is null then
    v_result:=wallet_private.command_failure_envelope('ADMIN_REASON_TICKET_REQUIRED',false,v_operation_id);
    return wallet_private.finish_admin_command(p_actor_user_id,'REQUEST_OPERATION_RETRY',v_request_id,
      v_request_hash,v_result);
  end if;
  select id,idempotency_key into v_inbox_id,v_idempotency_key from public.wallet_provider_event_inbox
   where operation_id=v_operation_id for update;
  if not found then
    v_result:=wallet_private.command_failure_envelope('ADMIN_OPERATION_NOT_FOUND',false,v_operation_id);
    return wallet_private.finish_admin_command(p_actor_user_id,'REQUEST_OPERATION_RETRY',v_request_id,
      v_request_hash,v_result);
  end if;
  update public.wallet_provider_event_inbox set next_retry_at=wallet_private.fixed_db_now(),row_version=row_version+1
   where id=v_inbox_id and row_version=v_expected_version and status='PENDING'
     and last_error_code is not null and last_error_retryable is true;
  if not found then
    v_result:=wallet_private.command_failure_envelope('ADMIN_RETRY_NOT_ALLOWED',false,v_operation_id);
    return wallet_private.finish_admin_command(p_actor_user_id,'REQUEST_OPERATION_RETRY',v_request_id,
      v_request_hash,v_result);
  end if;
  insert into public.wallet_audit_events(actor_user_id,actor_role,action_code,resource_type,resource_id,
    request_id,reason,cs_ticket,before_json,after_json)
  values(p_actor_user_id,v_actor.actor_role,'REQUEST_OPERATION_RETRY','PROVIDER_INBOX',v_operation_id::text,
    v_request_id,v_reason,v_cs_ticket,jsonb_build_object('row_version',v_expected_version),
    jsonb_build_object('row_version',v_expected_version+1,'next_retry_at',wallet_private.fixed_db_now())) returning id into v_audit_id;
  v_result:=row(true,null,false,v_operation_id,v_audit_id,jsonb_build_object(
    'enqueued',true,'inbox_operation_id',v_operation_id,'idempotency_key',v_idempotency_key,'status','PENDING'),null)
    ::public.wallet_stable_command_envelope;
  return wallet_private.finish_admin_command(p_actor_user_id,'REQUEST_OPERATION_RETRY',v_request_id,
    v_request_hash,v_result);
end $$;
```

`uuid_or_null` and `nonnegative_bigint_or_null` catch invalid text and overflow internally; they never leak a cast exception. All other fixed commands use the same unknown-key rejection, safe scalar decoders, `p_actor_user_id` DB lookup, advisory request fence, immutable replay row, and same-transaction audit pattern with role-specific allowlists. Actor/RBAC, validation, optimistic-version, approval, and other expected domain failures never escape as SQL message strings: before mutation they return `wallet_stable_command_envelope(ok=false,domain_code,retryable,operation_id,support_ref)`. A failure discovered after tentative writes runs inside a PL/pgSQL subtransaction that rolls those writes back before storing and returning the same stable envelope; unexpected infrastructure/SQLSTATE failures may raise for the Next wrapper to map and record separately. Contract tests invoke every one of the nine commands through its domain-failure cases and assert the exact five-field failure wire plus byte-identical same-request replay.

`admin_adjust_star_bonus` CREDIT calls debt-aware credit; DEBIT uses Star or earliest-expiry Bonus and creates no debt, and its over-limit flow follows the stored REQUEST/APPROVE contract above. `apply_wallet_correction` uses two-person Super approval and may create CORRECTION debt. `admin_create_promotion_version` appends version with `effective_from=fixed_db_now()` and checks expected latest version.

- [ ] **Step 4: Lock down legacy raw writers and close coverage**

Override `admin_adjust_user_bonus` to deny legacy use. Revoke DML on profile balance columns through guard triggers and histories from admin/service roles. Set credit source `admin_adjustment` and mutation routes `admin_adjustment`/`projection_repair` migrated with fixed command/test evidence. Assert every `POSITIVE_CREDIT` and active mutation row migrated, JMA/Goonghap/PIC have explicit domain evidence, unclassified scan matches are 0, and both credit/lock coverage are 100.

Add a migration test that snapshots `admin_user_roles` before role/capability seed, reruns the seed, and asserts the assignment set is byte-for-byte unchanged. Test the private assignment procedure for active-whitelist enforcement, audit rollback, duplicate assignment replay, and non-Super denial.

- [ ] **Step 5: Verify exact privilege matrix and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_commands.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_rbac_privileges.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_credit_source_coverage.test.sql
git add supabase/migrations/20260721105500_wallet_admin_command_rpcs.sql supabase/migrations/20260721110000_wallet_admin_rbac_and_direct_writer_lockdown.sql supabase/tests/wallet_admin_commands.test.sql supabase/tests/wallet_admin_rbac_privileges.test.sql
git commit -m "feat(admin): enforce audited wallet commands"
```

Expected: tests exit 0; coverage is 100; authenticated cannot execute commands, service wrapper is DB-RBAC constrained, and service role still cannot perform raw financial mutation.

### Task 11: Hand off the canonical Next admin wrapper contract

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_admin_wrapper_handoff.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/docs/wallet/admin-command-handoff.md`

**Interfaces:** Produces the service-only DB contract consumed by picnic-admin's canonical Next Route Handler. No `wallet-admin-command` Edge Function is created.

- [ ] **Step 1: Write server-derived actor and two-argument contract tests**

For all nine command RPCs, query `pg_proc` to assert arguments `(p_actor_user_id uuid,p_request jsonb)`. Assert `authenticated` cannot execute them and `service_role` can. Through service-role fixtures test server-derived actor, JSON actor/approver spoof fields, wrong DB role, request replay, approval error, and stable envelope. `record_wallet_command_failure(jsonb)` remains service-only; its tests accept only `{actor_user_id,request_id,action_code,failure_stage,domain_code,retryable}`, accept only `TRANSPORT|RESPONSE_DECODE` for the stage, reject missing/spoofed/unwhitelisted actor context and every extra key including reason/ticket/body, and assert its audit contains no raw request payload.

```sql
do $$ declare v_bad integer; begin
  select count(*) into v_bad from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname in ('admin_create_promotion_version','admin_adjust_star_bonus',
     'apply_wallet_correction','admin_request_wallet_operation_retry','admin_ack_wallet_ops_alert',
     'admin_preview_wallet_repair','admin_execute_wallet_repair','admin_waive_wallet_debt',
     'admin_emergency_set_wallet_flags')
     and (p.pronargs<>2 or p.proargnames<>array['p_actor_user_id','p_request']::text[]);
  assert v_bad=0,'admin command signature drift';
  assert not has_function_privilege('authenticated','public.admin_adjust_star_bonus(uuid,jsonb)','execute');
  assert has_function_privilege('service_role','public.admin_adjust_star_bonus(uuid,jsonb)','execute');
  assert has_function_privilege('service_role','public.record_wallet_command_failure(jsonb)','execute');
end $$;
```

- [ ] **Step 2: Run the handoff contract after Task 10**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_wrapper_handoff.test.sql
```

Expected: exit 0; every command takes server-derived actor plus `p_request`, authenticated direct execution is denied, and service role is the server wrapper executor.

- [ ] **Step 3: Record the exact Next Route Handler handoff**

The handoff fixes action→RPC mapping, `{p_actor_user_id: session.user.id,p_request: body}` call shape, and stable success/error envelopes. The Next Route Handler authenticates the admin session, rejects actor/approver IDs in the body, uses its service-role client to call one command, and DB rechecks that passed actor's whitelist/RBAC/approval. After rollback it calls `record_wallet_command_failure` in a separate transaction with exactly `{p_request:{actor_user_id:session.user.id,request_id,action_code,failure_stage,domain_code,retryable}}`; the server constructs this object, uses `TRANSPORT|RESPONSE_DECODE` only, and never forwards raw reason, CS ticket, or body. DB revalidates the actor context and records only masked failure provenance. It never writes a wallet table and no parallel Edge gateway exists.

- [ ] **Step 4: Verify and commit the handoff**

```bash
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_rbac_privileges.test.sql
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_admin_wrapper_handoff.test.sql
git add supabase/tests/wallet_admin_wrapper_handoff.test.sql docs/wallet/admin-command-handoff.md
git commit -m "docs(wallet): hand off admin command wrapper"
```

Expected: commands exit 0; the handoff has one canonical Next wrapper, no Edge gateway, and no browser raw mutation path.

### Task 12: Worker cron, retries, alerts, reconciliation, and health

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721110500_wallet_ops_cron_jobs.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_ops_cron_alerts.test.sql`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-operation-worker/index.ts`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/wallet-reconciliation/index.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/tests/wallet/operation-worker.test.ts`

**Interfaces:** Produces cron schedules, retry backoff/dead-letter alerts, heartbeat writes, automatic invariant alert resolution; consumes inbox lease/CAS helpers.

- [ ] **Step 1: Write crash/fencing/backoff/alert tests**

Cover receive commit then crash, lease expiry takeover, stale B and C CAS rejection, exponential bounded retry, permanent DEAD alert, fingerprint dedupe, ACK audit, system-only resolve after two clean reconciliation scans, missing heartbeat warning, and no sensitive payload in logs.

- [ ] **Step 2: Observe worker behavior gaps**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_ops_cron_alerts.test.sql
deno test --allow-all supabase/functions/tests/wallet/operation-worker.test.ts
```

Expected: at least one focused test exits non-zero before cron/alert integration.

- [ ] **Step 3: Implement schedules and worker evidence**

Schedule provider operation worker every minute, expiry every five minutes, reconciliation hourly, stale-claim cleanup every ten minutes, and heartbeat alert evaluation every five minutes. Worker claims a bounded batch, runs each financial settlement with lease token, records C failure separately after rollback, updates heartbeat counts/latency/version, and uses no raw financial DML outside private inbox helpers.

```ts
const { data: leases, error: claimError } = await service.rpc("claim_provider_event_batch", {
  p_worker_id: workerId,
  p_limit: 50,
  p_lease_seconds: 60,
});
if (claimError) throw claimError;
for (const lease of leases) {
  try {
    await settleByOperationType(service, {
      inbox_id: lease.id,
      lease_token: lease.lease_token,
      operation_type: lease.operation_type,
      encrypted_payload: lease.encrypted_payload,
    });
  } catch (error) {
    const mapped = mapSettlementError(error);
    await service.rpc("fail_provider_event", {
      p_inbox_id: lease.id,
      p_lease_token: lease.lease_token,
      p_retryable: mapped.retryable,
      p_error_code: mapped.domain_code,
      p_next_retry_at: nextBackoffAt(lease.attempt_count),
    });
  }
}
```

- [ ] **Step 4: Verify and commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_ops_cron_alerts.test.sql
deno test --allow-all supabase/functions/tests/wallet/operation-worker.test.ts
git add supabase/migrations/20260721110500_wallet_ops_cron_jobs.sql supabase/tests/wallet_ops_cron_alerts.test.sql supabase/functions/wallet-operation-worker/index.ts supabase/functions/wallet-reconciliation/index.ts supabase/functions/tests/wallet/operation-worker.test.ts
git commit -m "feat(ops): monitor wallet settlement workers"
```

Expected: tests exit 0; stale workers cannot corrupt terminal state and all critical failures have deduplicated alerts.

### Task 13: Complete and verify provenance-preserving account anonymization

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721111000_wallet_account_anonymization.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_account_anonymization.test.sql`

**Interfaces:** Extends the pre-FK core migration `20260721090200_wallet_account_anonymization_compatibility.sql`; consumes RESTRICT financial FKs and preserves the profile UUID as non-PII provenance with complete immutable audit.

- [ ] **Step 1: Write an operating-scale anonymization fixture**

Create a user with Cotton grant/spend, purchase/promo/refund, debt/recovery, inbox, audit, and alert. Call the existing account removal entrypoint. Assert profile UUID remains as tombstone; email/nickname/avatar/birth/gender/IP/session/push tokens are scrubbed; auth access is revoked; every financial FK and CS aggregate still resolves; no ledger/snapshot/audit row count changes.

- [ ] **Step 2: Prove the early compatibility works but completion checks still fail**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_account_anonymization.test.sql
```

Expected: the core compatibility assertion proves hard deletion is already impossible; this focused test remains non-zero only for the not-yet-added complete PII inventory, wallet audit, or reactivation guard.

- [ ] **Step 3: Extend the existing locked tombstone anonymization**

Keep the same entrypoint and lock key installed before the first RESTRICT FK. Extend it to cover the complete PII/session inventory, append the now-available wallet audit with masked before/after, and enforce reactivation denial. Keep profile ID and balances/provenance. Never restore a hard-delete path, disable constraints, or cascade financial rows.

```sql
perform wallet_private.lock_wallet_user(p_user_id);
delete from public.user_push_tokens where user_id=p_user_id;
update public.user_profiles set email=null,nickname='deleted-'||substr(p_user_id::text,1,8),avatar_url=null,
 birth_date=null,gender=null,birth_time=null,last_ip=null,deleted_at=wallet_private.fixed_db_now(),
 updated_at=wallet_private.fixed_db_now() where id=p_user_id;
insert into public.wallet_audit_events(actor_user_id,actor_role,action_code,resource_type,resource_id,
 request_id,reason,before_json,after_json)
values(p_user_id,'SYSTEM','ANONYMIZE_ACCOUNT','USER_PROFILE',p_user_id::text,p_request_id,
 'USER_REQUEST','{"pii":"present"}'::jsonb,'{"pii":"removed","wallet_provenance":"retained"}'::jsonb);
```

- [ ] **Step 4: Verify fresh and populated upgrades, then commit**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_account_anonymization.test.sql
supabase db lint
git add supabase/migrations/20260721111000_wallet_account_anonymization.sql supabase/tests/wallet_account_anonymization.test.sql
git commit -m "fix(auth): anonymize accounts without losing wallet provenance"
```

Expected: tests/lint exit 0; populated financial provenance survives and PII queries return no retained value.

### Task 14: Promotion/refund rollout gates, generated contracts, and final review

**Files:**

- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/migrations/20260721111500_wallet_promotion_release_gates.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet_promotion_release_gates.test.sql`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/export_contract_fixtures.mjs`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/verify_contract_checksums.mjs`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/verify_release_gate.mjs`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/ops/wallet/cotton-candy-v1-release-manifest.yaml`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/fixtures/*.json`
- Modify: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/functions/_shared/database.types.ts`
- Create: `/Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/docs/wallet/promotion-ops-rollout-runbook.md`
- Generate for the app plan: `/Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart`

**Interfaces:** Produces flag implications, stable fixtures/generated SQL types, measurable GO/NO-GO manifest; consumes both Supabase plans.

- [ ] **Step 1: Write failing release implication tests**

Flags are `candy_boost_write_enabled`, `debt_recovery_enabled`, `refund_reversal_enabled`, `admin_financial_commands_enabled`, `promotion_surfaces_enabled`. Assert refund implies debt recovery and 100% credit coverage; surfaces imply campaign read/schema; admin commands imply admin UI direct-write cutover evidence; all write flags require zero critical invariants, healthy workers, and immutable audit coverage 100%.

- [ ] **Step 2: Observe blocked defaults**

```bash
supabase db reset
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -v ON_ERROR_STOP=1 -f supabase/tests/wallet_promotion_release_gates.test.sql
```

Expected: test proves all write flags default false and an invalid refund enable attempt fails with `WALLET_RELEASE_GATE_BLOCKED`.

- [ ] **Step 3: Implement versioned implications and NO-GO manifest**

Extend the core runtime flag command, never update flags directly. Manifest requires credit and lock coverage 100; duplicate operations, negative balances, invariant mismatch, audit missing, cursor fixture mismatch all 0; worker heartbeat fresh; finance/backend/CS approvals false until humans set them. Gate verifier returns non-zero until every condition is observed.

```sql
if (p_changes->>'refund_reversal_enabled')::boolean then
  if not wallet_private.flag_bool('debt_recovery_enabled')
     or wallet_private.credit_source_coverage_percent()<>100 then
    raise exception using errcode='P0001',message='WALLET_RELEASE_GATE_BLOCKED';
  end if;
end if;
if exists(select 1 from public.wallet_invariant_violations
          where resolved_at is null and severity='CRITICAL') then
  raise exception using errcode='P0001',message='WALLET_RELEASE_GATE_BLOCKED';
end if;
if (p_changes->>'admin_financial_commands_enabled')::boolean then
  select count(distinct ur.user_id) filter(where r.name='Super Admin'),
         count(distinct ur.user_id) filter(where r.name='Finance Admin'),
         count(distinct ur.user_id) filter(where r.name='Operator')
  into v_super_count,v_finance_count,v_operator_count
  from public.admin_user_roles ur join public.admin_roles r on r.id=ur.role_id
  join public.user_profiles u on u.id=ur.user_id
  join public.admin_whitelist w on lower(w.email)=lower(u.email) and w.is_active;
  if v_super_count<2 or v_finance_count<1 or v_operator_count<1 then
    raise exception using errcode='P0001',message='ADMIN_ASSIGNMENT_GATE_BLOCKED';
  end if;
end if;
```

- [ ] **Step 4: Generate contracts to temporary files and reconcile**

```bash
supabase db reset
supabase gen types typescript --local > /tmp/picnic-wallet-promotion-types.ts
diff -u supabase/functions/_shared/database.types.ts /tmp/picnic-wallet-promotion-types.ts
node scripts/wallet/export_contract_fixtures.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  --output supabase/tests/wallet/contracts/fixtures \
  --app /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  --admin /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
node scripts/wallet/verify_contract_checksums.mjs \
  --manifest supabase/tests/wallet/contracts/manifest.json \
  /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
```

Expected initially: type diff contains promotion/admin named composites. Reconcile through normal editing, regenerate, and expect an empty type diff. The shared manifest fixes exactly 12 bundles: `wallet_summary_v1`, `currency_history_empty_v1`, `currency_history_mixed_v1`, `vote_result_v3`, `ad_reward_pending_v1`, `ad_reward_granted_v1`, `promotion_surfaces_empty_v1`, `promotion_surfaces_active_v1`, `purchase_results_v1`, `admin_cs_summary_v1`, `admin_money_timeline_v1`, `stable_error_v1`. `purchase_results_v1` contains `PENDING_TIME`, `INELIGIBLE`, and `GRANTED` cases. Exporter and verifier fail on missing/extra/renamed files or manifest checksum drift and produce no provider secrets. Export also produces a Dart file containing required raw const JSON fixtures and checksum constants. Verifier prints `12 contract fixtures verified; checksum mismatches: 0; integration constants verified`. Do not place contract JSON in production Flutter assets; generated Dart stays under `integration_test/fixtures` and is committed by the app plan.

- [ ] **Step 5: Record exact staged rollout/rollback gates**

Runbook order:

1. Dark-deploy schema/read/inbox/workers with all new write flags false; require two clean reconciliation scans and fresh heartbeats.
2. Shadow provider purchase events and campaign evaluation for 24 hours; require provider-time/version/base/promo agreement 100% and base purchase regression 0.
3. Use the audited private assignment procedure to explicitly assign at least two distinct active-whitelisted Super Admins, one Finance Admin, and one Operator; the same person may not satisfy both Super slots. Record human approver identities in the runbook without secrets.
4. Enable debt recovery after credit source and lock coverage reach 100; prove net-zero/partial recovery samples and no cross-currency recovery.
5. Enable Candy Boost write for 5%, 25%, 100%; at each gate require duplicate award 0, invariant mismatch 0, inbox DEAD rate below 0.1% excluding permanent provider rejects.
6. After admin command UI is deployed and direct writer probes fail, enable admin commands only if the assignment/whitelist gate above still passes; verify role matrix, audit rollback, alert ACK.
7. Enable refund reversal only after the implication command passes; canary verified full/partial refunds and require allocation equation mismatch 0.
8. Enable surfaces last; creative missing hides surface and opens alert.
9. Rollback pauses write/source flags and workers only when safe; keep inbox intake, debt recovery, expiry, reconciliation, read RPCs, and immutable evidence. Never delete or restore over ledgers.

- [ ] **Step 6: Run full, property, concurrency, and privilege verification**

```bash
supabase db reset
supabase test db
deno test --allow-all supabase/functions/tests
deno check supabase/functions/wallet-provider-event/index.ts supabase/functions/wallet-operation-worker/index.ts
npm run test:wallet
node scripts/wallet/verify_release_gate.mjs ops/wallet/cotton-candy-v1-release-manifest.yaml
git diff --check
git status --short
```

Expected before human approvals: tests/checks exit 0, verifier exits 1 with approval-only NO-GO, status has intended files and no `.gitignore`. Property suite uses 100 fixed seeds × 200 operations; each concurrency case runs 100 times; duplicate/negative/invariant counts remain 0; vote p95 regression stays below 20%.

- [ ] **Step 7: Commit release evidence**

```bash
git add supabase/migrations/20260721111500_wallet_promotion_release_gates.sql supabase/tests/wallet_promotion_release_gates.test.sql supabase/tests/wallet/contracts/manifest.json supabase/tests/wallet/contracts/fixtures scripts/wallet/export_contract_fixtures.mjs scripts/wallet/verify_contract_checksums.mjs scripts/wallet/verify_release_gate.mjs ops/wallet/cotton-candy-v1-release-manifest.yaml supabase/functions/_shared/database.types.ts docs/wallet/promotion-ops-rollout-runbook.md
git commit -m "chore(wallet): gate promotion and refund rollout"
```

- [ ] **Step 8: Request independent review and rerun evidence**

Use `superpowers:requesting-code-review`. Reviewer checks purchase gross provenance, provider time, campaign versioning, inbox fencing, refund integer math, debt recovery, admin fixed RPC names, role/approval/audit, alert lifecycle, anonymization, raw privilege revocation, and rollout implications. After fixes rerun Step 6. Implementation handoff records migration `20260721111500`, flag versions, coverage, invariant count, worker health, and approval state.
