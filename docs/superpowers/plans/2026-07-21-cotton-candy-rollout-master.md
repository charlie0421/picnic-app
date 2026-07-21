# 코튼캔디 지갑 + 캔디 부스트 데이 통합 Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 세 저장소의 구현 순서와 계약, 단계별 출시 게이트를 고정해 코튼캔디 지급·만료·일반 투표 우선 차감과 캔디 부스트 구매·환불·운영 도구를 부분 커밋 없이 출시한다.

**Architecture:** `picnic-supabase`가 모든 재화 판단과 원장의 단일 진실이며, 먼저 additive schema와 안정 RPC DTO를 배포한다. `picnic-app`과 `picnic-admin`은 raw 금융 테이블 대신 이 계약만 소비해 선배포한다. 실제 Cotton/Boost write는 만료·writer coverage·reconciliation·관리자 안전 전환 게이트를 통과한 뒤 채널과 cohort별로 켠다.

**Tech Stack:** PostgreSQL/Supabase CLI/pgTAP, Deno Edge Functions, Flutter/Riverpod/Freezed, Next.js 14/TypeScript/Jest/Playwright, Git worktrees, Vercel Preview.

## Global Constraints

- 승인 설계는 `docs/superpowers/specs/2026-07-21-cotton-candy-and-candy-boost-design.md`다. 구현 중 정책을 바꾸지 말고, 충돌이 발견되면 구현을 멈추고 설계 변경 승인을 받는다.
- 사용자 노출명은 `코튼캔디`, `보너스 스타캔디`, `스타캔디`, `캔디 부스트 데이`다. `솜사탕` 문자열은 제품 코드·접근성 라벨·fixture에 추가하지 않는다.
- PIC 투표 비활성화, JMA/궁합 재화 변경, Tapjoy/Pincrux 지급 통화 변경은 이 계획 범위가 아니다.
- `picnic-web` 코드는 이 계획 범위에 추가하지 않는다. 기존 PayPal/PortOne RPC signature는 Supabase의 durable-intake compatibility wrapper로 유지한다. wrapper는 pending receipt/inbox만 commit하고 금융 mutation을 하지 않으며, Supabase worker가 provider API를 다시 조회해 정산한다. 실제 호출 트래픽과 현재 두 Next Route의 non-null `receipt_id` 호환성을 확인하기 전에는 signature를 revoke하거나 `web_purchase`를 migrated로 바꾸지 않는다.
- `picnic-app` 구현 작업트리는 `/Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy`, 브랜치는 `feat/cotton-candy-policy`다.
- `picnic-supabase`와 `picnic-admin`은 실행 전에 `/Users/charlie.hyun/Repositories/GIT_BRANCHING_POLICY.md`를 읽고 사용자의 명시적 승인을 받은 뒤 sibling worktree를 만든다. 메인 폴더에서 `checkout`/`switch`하지 않는다.
- `/Users/charlie.hyun/Repositories/picnic-supabase/.gitignore`와 `/Users/charlie.hyun/Repositories/picnic-admin/types/supabase.ts`의 기존 사용자 변경을 수정·stage·복사하지 않는다.
- DB migration과 계약이 먼저다. `picnic-admin/types/supabase.ts` 생성은 schema 배포 후 새 admin worktree 안에서만 수행한다.
- raw `user_profiles` 재화 컬럼이나 금융 원장에 대한 앱/관리자 write를 추가하지 않는다. 서버 command RPC의 stable envelope만 사용한다.
- 모든 금액은 정수/bigint로 처리한다. JavaScript/Flutter에서 64-bit 값을 JSON number로 강제하지 않고 DTO 경계에서 decimal string을 parse한다.
- 모든 commit은 Conventional Commits를 사용한다. 각 저장소의 계획에 지정된 테스트가 통과하기 전에는 해당 task를 commit하지 않는다.
- UI/API 변경을 `main`에 merge하기 전 반드시 사용자에게 `Vercel Preview URL 로 확인하셨나요?`라고 묻고 답을 기다린다.

---

## Plan Set

| 순서 | 실행 문서 | 책임 |
|---|---|---|
| 1 | `docs/superpowers/plans/2026-07-21-cotton-candy-supabase-wallet-core.md` | 공통 lock/credit 경계, Cotton 원장, vote v3, 광고 claim, expiry, app read 계약 |
| 2 | `docs/superpowers/plans/2026-07-21-cotton-candy-supabase-promotion-ops.md` | purchase snapshot, Boost, 환불/debt, inbox, admin RPC, audit/alert/reconciliation |
| 3 | `docs/superpowers/plans/2026-07-21-cotton-candy-app.md` | wallet/history/UI, vote v3, 숏폼/Pangle 복구, store/home surface |
| 4 | `docs/superpowers/plans/2026-07-21-cotton-candy-admin-ops.md` | CS timeline, campaign, Wallet Ops, command UI, 직접 mutation 제거 |

각 하위 계획은 독립 commit 단위지만 다음 의존성을 지킨다.

```text
Supabase enum/core schema
  -> strict Bonus projection + global user lock + credit coverage
  -> Cotton schema/read RPC + expiry/reconciliation
  -> vote v3 + ad claim/callback
  -> purchase snapshot + campaign evaluator
  -> inbox/refund/debt/admin command/read RPC
  -> generated contract fixtures/types
       -> picnic-app predeploy
       -> picnic-admin predeploy
  -> Cotton canary
  -> Pangle required mode
  -> Boost write + refund reversal
  -> home/store surfaces
```

## Stable Cross-Repository Contract

계약 version은 `wallet.v1`로 고정하고 다음 RPC 이름을 변경하지 않는다.

- 앱 read/command: `get_wallet_summary`, `get_active_promotion_campaigns`, `get_currency_history`, `create_ad_reward_claim`, `get_ad_reward_status`, `list_unacknowledged_ad_rewards`, `acknowledge_ad_reward`, `perform_vote_transaction_v3`.
- provider/service command: `grant_ad_cotton`, `grant_verified_purchase`, `resolve_purchase_promotion`, `refund_verified_purchase`, `expire_cotton_candy_batch`.
- 관리자 read: `admin_get_wallet_actor_context`, `admin_get_user_cs_summary`, `admin_list_user_currency_history`, `admin_list_user_money_timeline`, `admin_list_promotion_campaigns`, `admin_list_promotion_campaign_versions`, `admin_preview_promotion_campaign`, `admin_list_user_wallet_debts`, `admin_list_wallet_operations`, `admin_list_ops_alerts`, `admin_get_wallet_ops_summary`, `admin_list_wallet_invariant_violations`, `admin_get_worker_health`, `admin_get_wallet_runtime_flags`, `admin_list_wallet_audit_events`.
- 관리자 command: `admin_create_promotion_version`, `admin_adjust_star_bonus`, `apply_wallet_correction`, `admin_request_wallet_operation_retry`, `admin_ack_wallet_ops_alert`, `admin_preview_wallet_repair`, `admin_execute_wallet_repair`, `admin_waive_wallet_debt`, `admin_emergency_set_wallet_flags`. retry, waiver, ACK, projection rebuild, emergency disable은 서로 다른 권한·action code를 사용한다.

모든 command 실패는 다음 envelope를 유지한다.

```json
{
  "ok": false,
  "domain_code": "VOTE_INSUFFICIENT_FUNDS",
  "retryable": false,
  "operation_id": "018f4f72-2ff0-7ae0-bf62-5b40d9855472",
  "support_ref": "WAL-20260721-000001"
}
```

모든 cursor 목록은 다음 envelope를 유지한다.

```json
{
  "items": [],
  "total_count": "0",
  "next_cursor": null,
  "snapshot_at": "2026-07-21T00:00:00Z"
}
```

호출 shape도 다음으로 고정한다.

- `voting-v2` body는 `vote_id: integer`, `vote_item_id: integer`, `amount: decimal string`, `request_id: uuid`만 받고, Edge가 JWT user와 integer 범위를 검증해 `perform_vote_transaction_v3(p_user_id uuid,p_vote_id integer,p_vote_item_id integer,p_amount integer,p_request_id uuid)`를 호출한다.
- `ad-reward-claim` body는 `platform`, `placement_id`, `client_request_id`만 받고 `{reference:{type:'PANGLE_CLAIM',id},platform,signed_token,expires_at}`를 반환한다.
- 앱 PostgREST args는 `get_currency_history(p_currency,p_cursor,p_limit)`, `get_ad_reward_status(p_reference_type,p_reference_id)`, `list_unacknowledged_ad_rewards(p_cursor,p_limit)`, `acknowledge_ad_reward(p_reference_type,p_reference_id)`다.
- wallet DTO는 `contract_version='wallet.v1'`, `star`, `bonus`, `cotton`, `cotton_expiring_amount`, nullable `cotton_next_expires_at`, `snapshot_at`을 반환하고 모든 금액은 decimal string이다.
- 광고 status DTO는 `{reference,state,grant,wallet,snapshot_at}`의 nested shape다. `grant.amount`와 cursor `total_count`도 decimal string이다.
- 내부 숏폼 issue 응답은 기존 `ad`, `tokens`에 authoritative `impression_id: uuid`를 additive하게 반환한다. 앱은 재생 시작 전에 이 reference를 사용자별 durable store에 저장하고, 보상 응답·복구 RPC는 같은 impression을 사용한다.
- 구매 wire는 `{contract_version:'wallet.v1',operation_id,replayed,base_star_amount,base_bonus_amount,promotion,wallet}`이고 `promotion`은 항상 non-null이다. 그 내부는 `{resolution_id,state,campaign_version_id,promo_bonus_amount,domain_code}`이며 상태는 `PENDING_TIME|ELIGIBLE|INELIGIBLE|GRANTED|REJECTED|CANCELLED_BY_REFUND`, domain code는 `PENDING_TIME`의 `PROMO_REVIEW_REQUIRED` 또는 null이다. 모든 금액은 decimal string이다.
- mobile receipt와 legacy web RPC는 provider event를 먼저 durable commit하고, 그 다음 lease worker가 Apple/Google/PayPal/PortOne을 검증한다. PayPal/PortOne wrapper는 stable pending receipt만 반환하고 caller amount/reward를 정산 권위로 사용하지 않는다.
- `grant_verified_purchase`는 검증 worker만 호출하고 provider/environment/transaction/user/product/quantity/provider time과 검증된 original quantity 또는 paid minor/currency, provider hash, allowlisted request context, operation/inbox lease를 받는다. DB provider registry가 Apple/Google=`QUANTITY`, PayPal/PortOne=`AMOUNT`를 강제하고 MOBILE/WEB·credit source·Bonus column을 도출하며 caller basis/reward/channel 선택을 거부한다.
- HOME promotion envelope은 active `items`, `snapshot_at`과 함께 `campaign_owned_home_banner_ids`를 항상 반환한다. 앱은 이 ID를 ordinary `vote_home` 목록에서 제외한다.
- 관리자 read는 `p_` argument 이름을 사용한다. Next Route Handler는 사용자 세션을 인증한 뒤 service-role 전용 command RPC를 정확히 `{p_actor_user_id: session.user.id, p_request: body}`로 호출한다. actor/approver ID는 외부 body에서 거부하고 DB가 전달된 actor의 RBAC와 승인 record를 다시 검증한다.
- 관리자 permission code는 정확히 `wallet.read`, `wallet.alert.ack`, `wallet.operation.retry`, `wallet.repair.preview`, `wallet.adjust.star_bonus`, `wallet.adjust.star_bonus.approve`, `wallet.debt.waive`, `promotion.version.create`, `wallet.correction.apply`, `wallet.repair.execute`, `wallet.flags.emergency_disable` 11개다.
- rollback된 transport/response-decode 실패만 별도 service-role recorder에 `{p_request:{actor_user_id,request_id,action_code,failure_stage,domain_code,retryable}}`로 기록한다. actor는 세션에서 만들고 `failure_stage`는 `TRANSPORT|RESPONSE_DECODE`만 허용하며 원 body/reason/ticket은 전달하지 않는다.

### Task 1: 실행 작업트리와 기준선 고정

**Files:**
- Read before execution: `/Users/charlie.hyun/Repositories/GIT_BRANCHING_POLICY.md`
- Preserve: `/Users/charlie.hyun/Repositories/picnic-supabase/.gitignore`
- Preserve: `/Users/charlie.hyun/Repositories/picnic-admin/types/supabase.ts`

- [ ] **Step 1: 사용자에게 두 신규 worktree 생성을 승인받는다**

승인 전에는 아래 `worktree add` 명령을 실행하지 않는다.

- [ ] **Step 2: 정책을 읽고 규격 브랜치의 sibling worktree를 만든다**

```bash
git -C /Users/charlie.hyun/Repositories/picnic-supabase worktree add /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine -b feat/cotton-candy-engine
git -C /Users/charlie.hyun/Repositories/picnic-admin worktree add /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops -b feat/wallet-ops
```

Expected: 두 worktree가 생성되고 원본 두 저장소는 `main`을 유지한다.

- [ ] **Step 3: 환경 파일과 의존성을 준비한다**

비밀값을 화면에 출력하지 말고 존재하는 파일만 같은 이름으로 복사한다.

```bash
find /Users/charlie.hyun/Repositories/picnic-supabase -maxdepth 1 -type f -name '.env*' -exec cp {} /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/ \;
find /Users/charlie.hyun/Repositories/picnic-admin -maxdepth 1 -type f -name '.env*' -exec cp {} /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/ \;
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && npm install
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && npm install
```

Expected: install exits 0; 원본 dirty 파일은 여전히 원본 worktree에만 있다.

- [ ] **Step 4: 세 작업트리의 시작점을 기록한다**

```bash
git -C /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy status --short --branch
git -C /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine status --short --branch
git -C /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops status --short --branch
```

Expected: 지정 브랜치이며, 의도하지 않은 tracked 변경이 없다.

### Task 2: 계약 fixture와 schema checksum 고정

**Files:**
- Create in Supabase: `supabase/tests/wallet/contracts/fixtures/*.json`
- Create in app: `picnic_lib/test/fixtures/wallet_contracts/*.json`
- Create in admin: `test/fixtures/wallet-contracts/*.json`
- Create in Supabase: `scripts/wallet/export_contract_fixtures.mjs`
- Create in Supabase: `scripts/wallet/verify_contract_checksums.mjs`
- Create in Supabase: `supabase/tests/wallet/contracts/manifest.json`

- [ ] **Step 1: Supabase 계획에서 실제 RPC를 먼저 구현하고 DB fixture를 export한다**

공유 manifest의 12개 fixture는 `wallet_summary_v1`, `currency_history_empty_v1`, `currency_history_mixed_v1`, `vote_result_v3`, `ad_reward_pending_v1`, `ad_reward_granted_v1`, `promotion_surfaces_empty_v1`, `promotion_surfaces_active_v1`, `purchase_results_v1`, `admin_cs_summary_v1`, `admin_money_timeline_v1`, `stable_error_v1`이다. `purchase_results_v1`은 `PENDING_TIME`, `INELIGIBLE`, `GRANTED` 사례를 한 bundle에 포함한다.

- [ ] **Step 2: 앱과 관리자 fixture를 source fixture와 byte-for-byte 동기화한다**

```bash
node /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/export_contract_fixtures.mjs \
  --manifest /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json \
  --output /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/fixtures \
  --app /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  --admin /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
node /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/verify_contract_checksums.mjs \
  --manifest /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json \
  /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts \
  /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts \
  --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart
```

Expected: `12 contract fixtures verified; integration constants verified; checksum mismatches: 0`.

- [ ] **Step 3: additive compatibility를 자동 검증한다**

기존 숏폼 top-level `ok`, `reward_added`, `impression_id`, `new_bonus` fixture와 기존 vote 성공 필드를 보존하는 contract test를 세 저장소에서 실행한다. 삭제/rename은 test failure여야 한다.

### Task 3: Phase 0 기준선과 release manifest 생성

**Files:**
- Create in Supabase: `ops/wallet/cotton-candy-v1-release-manifest.yaml`
- Create in Supabase: `scripts/wallet/verify_release_gate.mjs`
- Create in Supabase: `scripts/wallet/capture_baseline.sql`

- [ ] **Step 1: manifest를 안전한 NO-GO 기본값으로 추가한다**

```yaml
release: cotton-candy-v1
status: blocked
finance_error_budget: 0
required:
  credit_source_coverage: 100
  wallet_mutation_lock_coverage: 100
  general_vote_v3_route_coverage: 100
  invariant_mismatch: 0
  duplicate_financial_operations: 0
  negative_balances: 0
  audit_missing: 0
  contract_checksum_mismatch: 0
phase_thresholds:
  min_sample_size: 200
  min_observation_hours: 24
  vote_p95_regression_percent_max: 20
  pending_age_p95_seconds_max: 60
  callback_error_rate_bps_max: 50
  dlq_count_max: 0
rehearsal_complete: false
approvals:
  product_finance: false
  backend: false
  cs_oncall: false
```

`phase_thresholds`는 Cotton internal/Pangle 5%·25%·100%, Boost 5%·25%·100% 각 단계에 개별 적용한다. 다음 단계로 갈수록 더 엄격한 version은 허용하지만 완화는 새 사람 승인 없이는 거부한다.

- [ ] **Step 2: 기존 Star/Bonus 합계·drift·광고/결제 오류율·vote p95·expiry heartbeat를 읽기 전용 SQL로 저장한다**

Run: `cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && supabase db reset && psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f scripts/wallet/capture_baseline.sql`

Expected: baseline query exits 0 and no financial row is mutated.

- [ ] **Step 3: gate verifier의 실패 상태를 먼저 확인한다**

Run: `cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && node scripts/wallet/verify_release_gate.mjs ops/wallet/cotton-candy-v1-release-manifest.yaml`

Expected: exit 1 with `NO-GO: status=blocked; approvals incomplete`.

### Task 4: Supabase 엔진 dark launch

**Depends on:** Task 1, Supabase wallet-core plan, Supabase promotion-ops plan through read RPCs.

- [ ] **Step 1:** enum migration과 enum 사용 migration이 분리됐는지 확인한다.
- [ ] **Step 2:** 신규 금융 raw table의 `PUBLIC`, `anon`, `authenticated`, `service_role` DML 권한이 회수되고 command-owner RPC만 허용되는지 pgTAP으로 확인한다.
- [ ] **Step 3:** strict Bonus projection, 공통 debt-aware credit, user-first lock을 먼저 배포하고 legacy 지급 회귀 테스트를 통과시킨다.
- [ ] **Step 4:** Cotton expiry worker를 dry-run 후 실제 test-user grant로 KST 자정과 lazy exclude를 검증한다.
- [ ] **Step 5:** reconciliation, invariant alert, inbox worker heartbeat를 확인한다.
- [ ] **Step 6:** 모든 신규 write flag를 OFF/legacy Bonus mode로 둔 채 read RPC와 admin read만 배포한다.

Expected: 기존 Star/Bonus 합계 변화 0, 신규 live Cotton grant 0, invariant mismatch 0.

### Task 5: 앱·관리자 선배포와 legacy write 차단

**Depends on:** Task 2, Task 4.

- [ ] **Step 1:** app 계획을 완료하고 wallet-aware 최소 버전을 배포한다. 광고 지급 mode는 계속 Bonus다.
- [ ] **Step 2:** admin 계획의 read UI와 command UI를 배포하되 `admin_financial_commands_enabled=false`를 유지한다.
- [ ] **Step 3:** Vercel Preview에서 세 재화, empty cursor page, campaign preview, alert/operation timeline, 권한별 command 숨김을 확인한다.
- [ ] **Step 4:** 새 admin command UI 검증 후 기존 `UserProfileDetail` 직접 history/profile write를 제거하고 DB raw DML 차단 test를 실행한다.
- [ ] **Step 5:** 모든 일반 투표 client/Edge route를 `perform_vote_transaction_v3`로 전환하고 legacy 일반 vote RPC/endpoint의 client EXECUTE를 revoke한다.
- [ ] **Step 6:** JMA, 궁합, PIC는 별도 writer로 coverage matrix에 남아 있고 동작이 바뀌지 않았는지 회귀 테스트한다.

Expected: wallet-aware 앱이 Cotton 0도 정상 렌더링하고, legacy 일반 투표 client 경로 0, 관리자 직접 재화 mutation 0.

### Task 6: Cotton 채널 canary

**Depends on:** credit source coverage 100%, wallet mutation lock coverage 100%, expiry/reconciliation active, Task 5.

- [ ] **Step 1:** `ads.pangle_claim_mode=shadow`에서 claim intent 누락률·bind 성공률·SSV latency를 측정한다.
- [ ] **Step 2:** 사내 allowlist에 `wallet.cotton_read_enabled`, `wallet.cotton_spend_enabled`, `ads.internal_reward_mode=cotton`, `ads.cotton_popup_enabled`를 적용한다.
- [ ] **Step 3:** internal shortform grant → 일반 vote Cotton-first spend → 앱 종료/재개 ack 복구 → 다음 KST 자정 expiry를 한 흐름으로 검증한다.
- [ ] **Step 4:** 안정 cohort로 확대한 뒤 `ads.pangle_claim_mode=optional`, `ads.pangle_reward_mode=cotton`을 적용하고 Pangle sandbox SSV를 검증한다.
- [ ] **Step 5:** 최소 지원 앱 version과 마지막 legacy session TTL을 확인한 뒤 `ads.pangle_claim_mode=required`로 전환한다.

Expected: duplicate grant 0, pending reference 유실 0, 만료 후 spend 0, 정상 replay HTTP 200 + immutable original result.

### Task 7: 캔디 부스트·환불·surface 출시

**Depends on:** 모든 Star/Bonus positive writer가 common credit helper를 사용하고 `debt_recovery_enabled=true`.

- [ ] **Step 1:** 최근 provider event를 shadow evaluator에 넣어 provider 시각, campaign version, base/promo 금액 일치율 100%를 확인한다. Apple/Google/PayPal/PortOne Edge secret과 worker refetch를 canary하고, 두 기존 `picnic-web` route의 배포 commit/non-null pending-receipt 호환성을 manifest에 기록하기 전에는 `web_purchase`를 켜지 않는다.
- [ ] **Step 2:** 제한 cohort에서 `candy_boost_write_enabled=true`로 바꾸고 base purchase가 pause와 무관하게 성공하는지 확인한다.
- [ ] **Step 3:** 부분 환불의 base 비례 회수, 첫 환불 promo 전액 회수, 부족분 debt, future same-currency credit 상계를 검증한다.
- [ ] **Step 4:** `refund_reversal_enabled=true` 설정 command가 `debt_recovery_enabled && credit_source_coverage=100%`가 아니면 거부되는지 확인한 뒤 활성화한다.
- [ ] **Step 5:** 마지막에 `promotion_surfaces_enabled=true`로 전환해 같은 campaign version이 스토어 badge와 `vote_home` 배너를 동시에 제어하는지 확인한다.

Expected: provider 시각 외 판정 0, 기간 밖 surface 0, 다른 통화 debt 상계 0, refund allocation 방정식 mismatch 0.

### Task 8: Pre-GO 자동 검증

- [ ] **Step 1: 전체 자동 검증을 실행한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && supabase db reset && supabase test db
cd /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib && flutter test && flutter analyze
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && npm test -- --runInBand && npm run type-check && npm run build
```

Expected: 모든 명령 exit 0.

- [ ] **Step 2: property/concurrency/performance gate를 실행한다**

고정 seed 100개 × seed당 200 operation, 각 동시성 시나리오 100회, 오염 fixture 탐지율 100%, 일반 vote p95 악화 20% 미만을 확인한다.

- [ ] **Step 3: manifest 관찰 수치를 실제 결과로 갱신한다**

모든 금융 error/count 필드는 0, coverage는 100이어야 한다. 표본 200건 이상, 관찰 24시간 이상, vote p95 악화 20% 미만, PENDING p95 60초 이하, callback 오류율 50bps 이하, DLQ 0을 실제 값으로 기록한다. 이 단계에서는 `rehearsal_complete`와 사람이 확인하지 않은 approval을 true로 바꾸지 않는다.

- [ ] **Step 4: rehearsal 전에는 gate가 계속 NO-GO인지 확인한다**

Run: `cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && node scripts/wallet/verify_release_gate.mjs ops/wallet/cotton-candy-v1-release-manifest.yaml`

Expected: exit 1 with `NO-GO: rehearsal incomplete; approvals incomplete`.

### Task 9: rollback/recovery rehearsal, 최종 GO, 저장소별 PR

- [ ] **Step 1:** provider event 수신을 유지한 채 각 신규 settlement flag를 pause하고 inbox가 보존되는지 확인한다.
- [ ] **Step 2:** Cotton 문제 시 reward mode pause, Boost 문제 시 promo write/surface만 off, admin command freeze가 서로 독립적으로 동작하는지 확인한다.
- [ ] **Step 3:** 실패 settlement는 원 key replay, commit된 오결과는 새 correction key, projection drift는 권위 원장 rebuild만 허용되는지 확인한다.
- [ ] **Step 4:** schema drop, snapshot restore, ledger delete, 과거 expiry 연장이 실행되지 않았음을 audit로 확인한다.
- [ ] **Step 5:** drift·중복·debt 방정식·audit mismatch 0과 alert 자동 resolve 뒤에만 제한 cohort부터 재개한다.

Expected: rollback rehearsal 중 원장 삭제 0, 신규 중복 operation 0, 보류 inbox 유실 0.

- [ ] **Step 6: rehearsal 증거와 사람 승인을 manifest에 기록한다**

kill switch, alert → dry-run repair → auto-resolve 결과의 audit/support reference를 기록하고 `rehearsal_complete=true`로 바꾼다. Product/Finance, Backend, CS/on-call이 실제 증거를 확인한 뒤에만 각 approval을 true로 바꾼다.

- [ ] **Step 7: 최종 gate가 GO인지 확인한다**

Run: `cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && node scripts/wallet/verify_release_gate.mjs ops/wallet/cotton-candy-v1-release-manifest.yaml`

Expected: exit 0 with `GO: cotton-candy-v1`.

- [ ] **Step 8: 각 저장소 branch를 push하고 PR을 생성한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine && git push -u origin feat/cotton-candy-engine && gh pr create --fill --base main --head feat/cotton-candy-engine
cd /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy && git push -u origin feat/cotton-candy-policy && gh pr create --fill --base main --head feat/cotton-candy-policy
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && git push -u origin feat/wallet-ops && gh pr create --fill --base main --head feat/wallet-ops
```

Expected: 세 PR이 `main` 대상으로 생성된다. 각 `gh pr create` 직후 저장소 지침의 Vercel comment polling을 실행하고 발견된 Preview URL을 사용자에게 출력한다.

각 저장소에서 `gh pr create` 직후 다음을 실행한다. 코멘트가 없는 저장소는 출력 없이 끝난다.

```bash
PR=$(gh pr view --json number --jq .number)
for i in $(seq 1 8); do
  URL=$(gh api "repos/:owner/:repo/issues/$PR/comments" \
    --jq '.[] | select(.user.login=="vercel[bot]") | .body' 2>/dev/null \
    | grep -oE 'https://[a-z0-9-]+\.vercel\.app' | head -1)
  [ -n "$URL" ] && echo "Preview: $URL" && break
  sleep 20
done
```

- [ ] **Step 9: merge 승인 전에 사용자 확인을 받는다**

반드시 `Vercel Preview URL 로 확인하셨나요?`라고 묻고 답을 기다린다.
