# 코튼캔디 관리자 운영 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `picnic-admin`을 `wallet.v1` 안전 RPC 계약으로 전환해 CS가 세 재화와 구매·프로모션·환불·부채를 한 흐름으로 조회하고, 권한이 있는 운영자만 dry-run과 감사 가능한 제한 명령을 실행하게 한다.

**Architecture:** 브라우저는 공개 가능한 read RPC만 호출한다. 모든 금융·캠페인·복구 명령은 Next Route Handler가 사용자 세션을 인증한 뒤 server-derived actor ID와 service-role client로 command RPC를 호출하며, rollback된 기술 실패는 같은 서버 경계의 전용 failure recorder로 별도 기록한다. 금액 wire 값은 decimal string으로 받고 DTO 경계에서 `bigint`로 변환한다. 기존 `user_profiles` 잔액, Star/Bonus history, Bonus repair RPC에 대한 직접 mutation은 새 UI 검증 뒤 제거한다.

**Tech Stack:** Next.js 14 App Router, TypeScript strict mode, Supabase JS, Ant Design, Jest/React Testing Library, Playwright, npm.

## Global Constraints

- 승인 설계는 `/Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/docs/superpowers/specs/2026-07-21-cotton-candy-and-candy-boost-design.md`다. 정책 충돌이 발견되면 구현을 멈추고 설계 변경 승인을 받는다.
- 현재 원본 저장소의 tracked `.env`, tracked `supabase/.temp/**`, production-target local env, public service-role 변수 이름은 hard blocker다. 별도 승인된 security hotfix로 `.env`를 추적 해제하고 영향받은 production credential을 회전했다는 evidence가 없으면 이 worktree를 만들거나 Vercel Preview를 실행하지 않는다. 비밀값은 읽기·복사·출력하지 않는다.
- production Supabase ref `xtijtefcycoeqludlngc`는 local/Vercel Preview denylist다. staging ref가 별도로 provision되지 않으면 build/remote type generation/Playwright는 exit 1이며 production fallback은 없다.
- `NEXT_PUBLIC_*SERVICE_ROLE*`는 모든 환경에서 금지한다. browser에는 anon key만, server-only Route Handler에는 `SUPABASE_SERVICE_ROLE_KEY`만 허용하며 build/static test가 이를 검증한다.
- Vercel Preview는 staging만 사용하고 Production Branch는 `main`이어야 한다. clean checkout에서 `git fetch origin main` 후 `HEAD == VERCEL_GIT_COMMIT_SHA == origin/main`, expected repository identity, branch/ref, Preview 승인 evidence를 검증하기 전 production build를 허용하지 않는다.
- 이 계획은 `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops` worktree, `feat/wallet-ops` 브랜치에서만 실행한다. 실행 전 `/Users/charlie.hyun/Repositories/GIT_BRANCHING_POLICY.md`를 읽는다.
- `/Users/charlie.hyun/Repositories/picnic-admin/types/supabase.ts`의 기존 사용자 변경은 읽기 외에 수정·복사·stage하지 않는다. 생성 타입은 Supabase schema와 admin RPC가 배포된 뒤 새 worktree의 `/Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/types/supabase.ts`에서만 갱신한다.
- `wallet.v1`의 모든 bigint JSON 필드는 decimal string이다. `Number`, `parseInt`, `parseFloat`, unary `+`로 금액을 변환하지 않는다. DTO 경계에서 `BigInt`로 parse하고 API 응답으로 되돌릴 때는 decimal string을 유지한다.
- 통화 합산은 같은 통화 안에서만 한다. `STAR_CANDY`, `BONUS_STAR_CANDY`, `COTTON_CANDY`를 하나의 숫자로 합치지 않는다.
- cursor는 opaque string으로 전달만 한다. client가 cursor를 만들거나 해석하지 않는다. 목록 limit은 기본 20, 허용 범위 1..100이며 offset pagination은 추가하지 않는다.
- 브라우저에서 mutation RPC를 직접 호출하지 않는다. `supabaseBrowserClient.rpc`에 아래 command 이름이 전달되면 테스트 실패여야 한다.
- 9개 금융 command RPC는 `PUBLIC`, `anon`, `authenticated`의 EXECUTE를 회수하고 service-role/dedicated command role에만 허용한다. UI denylist는 이 DB privilege boundary를 보조한다.
- 관리자 입력으로 `user_profiles` 목표 잔액, raw ledger 행, debt row, provider 시각, campaign `effective_from`, actor ID, approver ID를 받지 않는다.
- Cotton 수동 조정은 제공하지 않는다. 일반 관리자 조정은 Star/Bonus만 허용한다.
- 시스템 지급 사유 enum을 수동 조정 선택지로 노출하지 않는다. 관리자는 자유 입력 사유와 CS ticket을 모두 입력한다.
- Wallet command 결과의 `operation_id`, `support_ref`, `audit_id`, `domain_code`, `retryable`을 임의 생성하거나 덮어쓰지 않는다.
- Wallet permission wire 값은 아래 `WALLET_PERMISSION_ALLOWLIST`의 11개 dotted string만 canonical이다. DB의 `(resource, action)` 저장 형식이나 `resource:action`, `wallet_adjust.execute` 같은 내부 alias를 wire에 노출하지 않는다.
- Operator retry는 settlement를 동기 실행하지 않고 원 inbox key를 enqueue할 뿐이다. `DEAD`, stale version, non-retryable operation은 서버가 거부하며 UI는 stable error를 그대로 표시한다.
- 일반 `ADMIN_ADJUST` DEBIT은 잔액 부족 시 전체 거부되고 debt를 만들지 않는다. CREDIT은 같은 통화 open debt를 먼저 상계한다. correction만 Super Admin 2인 승인으로 부족분을 correction debt로 남길 수 있다.
- Finance Admin의 Star/Bonus 조정이 서버 version 설정의 금액 한도를 넘으면 최초 호출은 wallet을 변경하지 않고 immutable approval record와 `approval_reference`를 반환한다. 요청자와 다른 Super Admin만 같은 `admin_adjust_star_bonus` RPC의 `APPROVE` action으로 승인할 수 있다.
- projection repair는 목표 잔액을 받지 않고 권위 원장에서 재계산한다. emergency UI는 안전 방향의 disable/pause만 허용하며 Cotton expiry와 debt recovery를 끄지 않는다.
- raw 금융 table SELECT를 새로 추가하지 않는다. CS·Wallet Ops·audit 데이터는 safe admin read RPC 결과만 사용한다.
- 모든 `p_filters`는 승인 설계의 key만 사용한다: `from`, `to`, `currency`, `event_types`, `statuses`, `provider`, `severity`, `campaign_id`. RPC별 subset 밖의 key와 단수 alias(`status`, `event_type`)는 client parser와 DB가 모두 거부한다.
- Next build와 별도로 `npm run type-check`를 반드시 통과한다. 각 task의 test와 type-check가 통과하기 전에 commit하지 않는다.
- UI/API가 달라지는 이 브랜치를 `main`에 merge하기 전 사용자에게 `Vercel Preview URL 로 확인하셨나요?`라고 묻고 답을 기다린다.

## Fixed RPC Contract

### Browser-safe reads

```text
admin_get_wallet_actor_context()
admin_get_user_cs_summary(p_user_id uuid)
admin_list_user_currency_history(p_user_id uuid, p_currency wallet_currency, p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_list_user_money_timeline(p_user_id uuid, p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_list_promotion_campaigns(p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_list_promotion_campaign_versions(p_campaign_id uuid, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_preview_promotion_campaign(p_campaign_id uuid, p_at timestamptz)
admin_list_user_wallet_debts(p_user_id uuid, p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_list_wallet_operations(p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_list_ops_alerts(p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_get_wallet_ops_summary(p_at timestamptz DEFAULT NULL)
admin_list_wallet_invariant_violations(p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
admin_get_worker_health()
admin_get_wallet_runtime_flags()
admin_list_wallet_audit_events(p_filters jsonb, p_cursor text DEFAULT NULL, p_limit int DEFAULT 20)
```

### Server-only commands

각 command RPC는 server-derived actor와 외부 body를 분리한 두 인자를 받고 stable envelope를 반환한다.

```text
admin_create_promotion_version(p_actor_user_id uuid, p_request jsonb)
admin_adjust_star_bonus(p_actor_user_id uuid, p_request jsonb)
apply_wallet_correction(p_actor_user_id uuid, p_request jsonb)
admin_request_wallet_operation_retry(p_actor_user_id uuid, p_request jsonb)
admin_ack_wallet_ops_alert(p_actor_user_id uuid, p_request jsonb)
admin_preview_wallet_repair(p_actor_user_id uuid, p_request jsonb)
admin_execute_wallet_repair(p_actor_user_id uuid, p_request jsonb)
admin_waive_wallet_debt(p_actor_user_id uuid, p_request jsonb)
admin_emergency_set_wallet_flags(p_actor_user_id uuid, p_request jsonb)
```

기술 실패 기록용 `record_wallet_command_failure(p_request jsonb)`는 service-role wrapper만 호출한다.

9개 command의 PostgREST JSON 결과는 예외 없이 `StableCommandEnvelope<TResult>` 한 건이다. 성공 composite의 필드는 `ok=true`, `operation_id`, `audit_id`, `result`이고 domain 실패 composite의 필드는 `ok=false`, `domain_code`, `retryable`, nullable `operation_id`, `support_ref`다. 권한·version·한도·상태 같은 domain 실패는 PostgreSQL exception/PostgREST `error`가 아니라 `command.data`의 stable failure composite로 돌아온다. transport 오류와 malformed response/decoder 오류만 별도 failure recorder를 호출하고 recorder가 반환한 stable envelope를 502로 전달한다. Route Handler는 정상 domain envelope를 다른 형태로 매핑하지 않는다.

### Wire envelopes

```ts
export interface StableErrorEnvelope {
  ok: false;
  domain_code: string;
  retryable: boolean;
  operation_id: string | null;
  support_ref: string;
}

export interface StableSuccessEnvelope<T> {
  ok: true;
  operation_id: string;
  audit_id: string;
  result: T;
}

export type StableCommandEnvelope<T> =
  | StableSuccessEnvelope<T>
  | StableErrorEnvelope;

export interface CursorPageWire<T> {
  items: T[];
  total_count: string;
  next_cursor: string | null;
  snapshot_at: string;
}
```

### Role capabilities

```ts
export type WalletActorRole = 'OPERATOR' | 'FINANCE_ADMIN' | 'SUPER_ADMIN';

export const WALLET_PERMISSION_ALLOWLIST = [
  'wallet.read',
  'wallet.alert.ack',
  'wallet.operation.retry',
  'wallet.repair.preview',
  'wallet.adjust.star_bonus',
  'wallet.adjust.star_bonus.approve',
  'wallet.debt.waive',
  'promotion.version.create',
  'wallet.correction.apply',
  'wallet.repair.execute',
  'wallet.flags.emergency_disable',
] as const;

export type WalletPermission = (typeof WALLET_PERMISSION_ALLOWLIST)[number];
```

Operator는 첫 네 권한, Finance Admin은 Operator 권한과 `wallet.adjust.star_bonus`, `wallet.debt.waive`를 갖는다. Super Admin은 전 권한을 갖지만 자신이 요청한 조정의 `wallet.adjust.star_bonus.approve`는 DB가 거부한다. UI guard는 편의 기능이고 RPC가 최종 권한·한도·2인 승인을 다시 검증한다.

Supabase handoff의 shared permission contract test와 Admin의 compile/runtime contract test는 위 배열의 순서와 값까지 동일함을 검증한다. Supabase actor-context RPC는 내부 role/permission row를 위 canonical string으로 명시적으로 매핑해야 하며 문자열 연결 규칙으로 wire 값을 추론하지 않는다.

### Browser-safe DTO exactness

15개 read RPC 중 목록은 모두 `CursorPageWire<T>`를 반환하고, SQL의 bigint/count/version은 `::text`를 거친 decimal string이어야 한다. 특히 양쪽 계획은 다음 네 추가 read를 같은 exact shape로 고정한다.

- `admin_list_promotion_campaign_versions`: `PromotionCampaignVersionWire`의 모든 필드를 반환하며 `home_banner_id`만 SQL `integer`/TypeScript `number | null`이다. `version`, `extra_bonus_bps`, `rollout_policy.cohort_threshold_bps`는 decimal string이다.
- `admin_list_user_wallet_debts`: `WalletDebtItemWire`의 `row_version`, 네 금액, status, 두 source reference, created/updated time을 모두 반환한다. SQL composite에서 필드명을 `version`으로 축약하지 않는다.
- `admin_get_wallet_runtime_flags`: 개별 item 배열이 아니라 `{flag_version, values, changed_at, changed_by, snapshot_at}` 한 건을 반환한다. `flag_version`은 decimal string이다.
- `admin_list_wallet_audit_events`: `WalletAuditEventWire`를 반환한다. `operation_id`와 `campaign_version_id`는 nullable이고, `before_json`/`after_json`은 DB safe RPC가 allowlist/masking한 JSON만 포함한다.

`types/wallet-admin-contract-check.ts`의 compile-only exactness assertion은 생성된 `Database['public']['Functions']` return/arg 타입과 위 Wire 타입의 key·primitive/nullability를 양방향 비교한다. Supabase promotion 계획의 pgTAP handoff도 같은 필드 manifest checksum을 검증한다. 함수 이름만 존재하면 통과하는 검사는 허용하지 않는다.

## Target File Map

| 책임 | 경로 |
|---|---|
| wire/domain DTO와 bigint decoder | `lib/types/wallet-admin.ts`, `lib/wallet/decode-wallet-admin.ts` |
| typed read adapter | `lib/services/walletAdminService.ts` |
| permission cache/guard | `lib/hooks/useWalletPermissions.ts`, `components/auth/RequireWalletPermission.tsx` |
| server/browser command boundary | `lib/services/walletAdminCommand.server.ts`, `lib/services/walletAdminCommand.client.ts`, `lib/supabase/service-role.server.ts`, `lib/wallet/admin-command-contract.ts` |
| CS 화면 | `app/user_profiles/components/wallet/*` |
| campaign 화면 | `app/promotion-campaigns/*` |
| Wallet Ops 화면 | `app/wallet-ops/*` |
| command API | `app/api/wallet/*/route.ts` |
| contract/Jest/Playwright | `test/fixtures/wallet-contracts/*`, `__tests__/wallet/*`, `__tests__/api/wallet/*`, `e2e/wallet-admin.spec.ts` |

---

### Task 0: 환경·credential·Vercel Preview를 production과 격리한다

**Precondition outside this worktree:** 사용자 승인을 받은 별도 security hotfix worktree가 원본 `picnic-admin/.env`와 `supabase/.temp/**`를 Git에서 제거하고 ignore해야 한다. tracked `.env`에 실제 production credential이 있었다면 모두 회전하고 audit reference만 남긴다. 이 precondition이 `main`에 merge되기 전에는 `picnic-admin-wallet-ops` feature worktree 생성과 Vercel Preview가 NO-GO다. 보안 hotfix worktree 자체는 별도 명시 승인을 받은 경우에만 만든다.

**Files:**
- Create: `scripts/verify-wallet-environment.mjs`
- Create: `__tests__/wallet/environment-isolation.test.ts`
- Modify: `.gitignore`
- Remove from Git index in the approved security hotfix: `.env`, `supabase/.temp/**`
- Modify: `lib/supabase/constants.ts`
- Modify: `next.config.mjs`
- Modify: `package.json`

**Interfaces:** Produces a fail-closed `development|preview|production` target guard. It validates names/host/ref equivalence without logging URL, anon key, service role, token, or password values.

- [ ] **Step 1: Prove the current repository is blocked without exposing values**

Run only file-name/key-name checks in the original repository:

```bash
if git -C /Users/charlie.hyun/Repositories/picnic-admin ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo 'NO-GO: tracked .env requires security hotfix and credential rotation' >&2
  exit 1
fi
if git -C /Users/charlie.hyun/Repositories/picnic-admin ls-files 'supabase/.temp/**' | rg . >/dev/null; then
  echo 'NO-GO: tracked Supabase link metadata' >&2
  exit 1
fi
```

Expected now: exit 1. Stop here until the approved hotfix is merged and credential-rotation evidence exists; do not copy `.env`/`.env.local` into a worktree.

- [ ] **Step 2: Write failing environment-isolation tests**

Tests use temporary sanitized fixtures and spawned processes to assert:

- `development` and `preview` require `PICNIC_STAGING_SUPABASE_PROJECT_REF`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and server-only `SUPABASE_SERVICE_ROLE_KEY`; the URL-derived ref must equal staging and differ from production.
- any environment key matching `NEXT_PUBLIC_.*SERVICE_ROLE`, production ref/host in local/Preview, `.env` or link metadata in the worktree, missing/placeholder fallback, unknown `VERCEL_ENV`, or missing staging config exits 1.
- production requires `VERCEL_ENV=production`, `VERCEL_GIT_COMMIT_REF=main`, a clean checkout after `git fetch origin main`, exact `HEAD == VERCEL_GIT_COMMIT_SHA == origin/main`, expected repository identity, a reviewed deployment-stage reference, and verified Vercel Production Branch evidence.
- stdout/stderr contains only variable names/reasons. Fixture sentinel `do-not-print-secret` never appears.

Run: `npm test -- --runInBand __tests__/wallet/environment-isolation.test.ts`

Expected before implementation: module-not-found or assertions fail.

- [ ] **Step 3: Implement the guard and remove unsafe fallbacks**

`verify-wallet-environment.mjs` has only explicit test-mode switches `--allow-offline` (unit tests; creates no client/request) and `--require-staging` (Preview/integration). It parses URL host/project ref in memory, checks Git-tracked CLI/env paths, checks public service-role variable **names**, and emits only `NO-GO: unsafe wallet environment (<source-name>)` on failure. `lib/supabase/constants.ts` no longer returns placeholder URL/key in development; missing validated variables throw before any Supabase client or request is created.

`next.config.mjs` derives the Supabase image hostname only from the already validated environment instead of hardcoding production. Set `typescript.ignoreBuildErrors=false` and `eslint.ignoreDuringBuilds=false`; Vercel must not publish a build with type/lint failures.

Use these package hooks; none performs remote type generation:

```json
{
  "verify:wallet-env": "node scripts/verify-wallet-environment.mjs",
  "predev": "npm run verify:wallet-env",
  "prebuild": "npm run verify:wallet-env",
  "prestart": "npm run verify:wallet-env",
  "pretest": "npm run verify:wallet-env -- --allow-offline",
  "pretest:e2e": "npm run verify:wallet-env -- --require-staging"
}
```

Run with sanitized staging variables through the approved local secret manager:

```bash
npm test -- --runInBand __tests__/wallet/environment-isolation.test.ts
VERCEL_ENV=preview PICNIC_STAGING_SUPABASE_PROJECT_REF="$PICNIC_STAGING_SUPABASE_PROJECT_REF" npm run verify:wallet-env
```

Expected: test PASS; preview guard exits 0 only for staging. Replacing only the fixture ref/URL with production exits 1, and no value appears in output.

- [ ] **Step 4: Record external Vercel controls before Preview**

An authorized operator verifies and records, without credentials:

- Vercel Production Branch is exactly `main`; Preview deployments receive only staging env values and Production receives only production values.
- Preview/Production environment scopes do not share Supabase URL, anon, or server-role variables.
- deployment protection/authorized reviewers are enabled for Production.
- the tracked `.env` security hotfix and credential rotations are complete.

Until all four references are present in the release manifest, `verify-wallet-environment.mjs` fails production and Playwright network mode. Unit tests using mocks may continue.

- [ ] **Step 5: Commit the isolation boundary**

```bash
git add .gitignore package.json next.config.mjs lib/supabase/constants.ts scripts/verify-wallet-environment.mjs __tests__/wallet/environment-isolation.test.ts
git commit -m "chore(admin): isolate wallet preview environment"
```

Expected: no `.env` or `supabase/.temp/**` path is tracked; no public service-role variable name remains in `.env*`, Vercel settings, or generated client config; the guard implementation may contain the denylist token; Preview guard and tests pass against staging only.

### Task 1: 생성 계약과 bigint DTO 경계를 고정한다

**Depends on:** Supabase admin RPC 배포와 master plan의 contract fixture export.

**Files:**
- Create: `test/fixtures/wallet-contracts/wallet_summary_v1.json`
- Create: `test/fixtures/wallet-contracts/currency_history_empty_v1.json`
- Create: `test/fixtures/wallet-contracts/currency_history_mixed_v1.json`
- Create: `test/fixtures/wallet-contracts/vote_result_v3.json`
- Create: `test/fixtures/wallet-contracts/ad_reward_pending_v1.json`
- Create: `test/fixtures/wallet-contracts/ad_reward_granted_v1.json`
- Create: `test/fixtures/wallet-contracts/promotion_surfaces_empty_v1.json`
- Create: `test/fixtures/wallet-contracts/promotion_surfaces_active_v1.json`
- Create: `test/fixtures/wallet-contracts/admin_cs_summary_v1.json`
- Create: `test/fixtures/wallet-contracts/admin_money_timeline_v1.json`
- Create: `test/fixtures/wallet-contracts/stable_error_v1.json`
- Create: `test/fixtures/wallet-contracts/purchase_results_v1.json`
- Create: `lib/types/wallet-admin.ts`
- Create: `lib/wallet/decode-wallet-admin.ts`
- Create: `types/wallet-admin-contract-check.ts`
- Create: `scripts/generate-supabase-types-safe.mjs`
- Create: `__tests__/wallet/wallet-contract.test.ts`
- Modify: `package.json`
- Generate in the new worktree only: `types/supabase.ts`
- Generate in the new worktree only: `types/interfaces.ts`

- [ ] **Step 1: source fixture를 admin worktree에 export하고 checksum을 검증한다**

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

Expected: `12 contract fixtures verified; checksum mismatches: 0; integration constants verified`. Exact 12-file manifest는 위 12개 파일이며 `purchase_results_v1`은 `PENDING_TIME`, `INELIGIBLE`, `GRANTED` case를 모두 포함한다. exporter가 manifest 밖의 파일을 만들거나 하나라도 누락하면 verifier가 실패한다.

- [ ] **Step 2: bigint와 empty page 계약을 먼저 실패하는 테스트로 고정한다**

`__tests__/wallet/wallet-contract.test.ts`:

```ts
import csSummary from '@/test/fixtures/wallet-contracts/admin_cs_summary_v1.json';
import emptyHistory from '@/test/fixtures/wallet-contracts/currency_history_empty_v1.json';
import purchaseResults from '@/test/fixtures/wallet-contracts/purchase_results_v1.json';
import stableError from '@/test/fixtures/wallet-contracts/stable_error_v1.json';
import {
  decodeCursorPage,
  decodeCsSummary,
  parseWalletAmount,
} from '@/lib/wallet/decode-wallet-admin';
import { WALLET_PERMISSION_ALLOWLIST } from '@/lib/types/wallet-admin';

describe('wallet.v1 admin contract', () => {
  it('decimal string을 정밀도 손실 없이 bigint로 바꾼다', () => {
    expect(parseWalletAmount('90071992547409930001')).toBe(
      BigInt('90071992547409930001'),
    );
    expect(() => parseWalletAmount('1.5')).toThrow('INVALID_WALLET_DECIMAL');
  });

  it('세 통화를 별도 bigint로 decode한다', () => {
    const value = decodeCsSummary(csSummary);
    expect(typeof value.balances.STAR_CANDY).toBe('bigint');
    expect(typeof value.balances.BONUS_STAR_CANDY).toBe('bigint');
    expect(typeof value.balances.COTTON_CANDY).toBe('bigint');
  });

  it('빈 cursor page도 total_count=0을 보존한다', () => {
    const value = decodeCursorPage(emptyHistory, (item) => item);
    expect(value.items).toEqual([]);
    expect(value.totalCount).toBe(BigInt(0));
    expect(value.nextCursor).toBeNull();
  });

  it('stable error 필드를 손실 없이 보존한다', () => {
    expect(stableError).toEqual(
      expect.objectContaining({
        ok: false,
        domain_code: expect.any(String),
        retryable: expect.any(Boolean),
        support_ref: expect.any(String),
      }),
    );
    expect(
      stableError.operation_id === null ||
        typeof stableError.operation_id === 'string',
    ).toBe(true);
  });

  it('permission wire와 purchase result state를 shared manifest와 동일하게 고정한다', () => {
    expect(WALLET_PERMISSION_ALLOWLIST).toEqual([
      'wallet.read', 'wallet.alert.ack', 'wallet.operation.retry',
      'wallet.repair.preview', 'wallet.adjust.star_bonus',
      'wallet.adjust.star_bonus.approve', 'wallet.debt.waive',
      'promotion.version.create', 'wallet.correction.apply',
      'wallet.repair.execute', 'wallet.flags.emergency_disable',
    ]);
    expect(purchaseResults.cases.map((item) => item.promotion.state)).toEqual(
      expect.arrayContaining(['PENDING_TIME', 'INELIGIBLE', 'GRANTED']),
    );
  });
});
```

Run: `cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops && npm test -- --runInBand __tests__/wallet/wallet-contract.test.ts`

Expected: FAIL because the DTO and decoder modules do not exist.

- [ ] **Step 3: exact wire/domain 타입과 decoder를 구현한다**

`lib/types/wallet-admin.ts`의 public 계약은 다음과 같다.

```ts
export const WALLET_CONTRACT_VERSION = 'wallet.v1' as const;

export type WalletCurrency =
  | 'STAR_CANDY'
  | 'BONUS_STAR_CANDY'
  | 'COTTON_CANDY';
export type WalletOperationStatus =
  | 'PENDING'
  | 'PROCESSING'
  | 'SUCCEEDED'
  | 'DEAD';
export type WalletInvariantStatus = 'OK' | 'DRIFT' | 'UNKNOWN';
export type WalletAlertStatus = 'OPEN' | 'ACKNOWLEDGED' | 'RESOLVED';
export type WalletDebtStatus = 'OPEN' | 'SETTLED' | 'WAIVED';
export type WalletActorRole = 'OPERATOR' | 'FINANCE_ADMIN' | 'SUPER_ADMIN';
export const WALLET_PERMISSION_ALLOWLIST = [
  'wallet.read',
  'wallet.alert.ack',
  'wallet.operation.retry',
  'wallet.repair.preview',
  'wallet.adjust.star_bonus',
  'wallet.adjust.star_bonus.approve',
  'wallet.debt.waive',
  'promotion.version.create',
  'wallet.correction.apply',
  'wallet.repair.execute',
  'wallet.flags.emergency_disable',
] as const;
export type WalletPermission = (typeof WALLET_PERMISSION_ALLOWLIST)[number];

export interface CursorPageWire<T> {
  items: T[];
  total_count: string;
  next_cursor: string | null;
  snapshot_at: string;
}

export interface CursorPage<T> {
  items: T[];
  totalCount: bigint;
  nextCursor: string | null;
  snapshotAt: string;
}

export interface WalletActorContextWire {
  actor_id: string;
  actor_role: WalletActorRole;
  permissions: WalletPermission[];
}

export interface WalletBalanceWire {
  currency: WalletCurrency;
  amount: string;
}

export interface WalletDebtWire {
  currency: Exclude<WalletCurrency, 'COTTON_CANDY'>;
  outstanding_amount: string;
}

export interface AdminCsSummaryWire {
  user_id: string;
  balances: Record<WalletCurrency, string>;
  open_debt: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, string>;
  cotton_expiring_amount: string;
  cotton_next_expires_at: string | null;
  invariant_status: WalletInvariantStatus;
  authoritative_totals: Record<WalletCurrency, string>;
  recent_operation: WalletOperationWire | null;
  snapshot_at: string;
}

export interface CurrencyHistoryItemWire {
  id: string;
  currency: WalletCurrency;
  event_type: string;
  origin: string;
  delta: string;
  balance_effect: string;
  expires_at: string | null;
  purchase_id: string | null;
  refund_id: string | null;
  grant_id: string | null;
  operation_id: string;
  created_at: string;
}

export interface TimelineAllocationWire {
  component: string;
  currency: WalletCurrency;
  gross_delta: string;
  wallet_delta: string;
  debt_delta: string;
}

export interface MoneyTimelineItemWire {
  id: string;
  kind: string;
  allocations: TimelineAllocationWire[];
  provider_occurred_at: string | null;
  campaign_version_id: string | null;
  audit_id: string | null;
  operation_id: string;
  created_at: string;
}

export interface WalletOperationWire {
  id: string;
  operation_type: string;
  status: WalletOperationStatus;
  retryable: boolean;
  attempt_count: string;
  next_retry_at: string | null;
  last_error_code: string | null;
  support_ref: string | null;
  row_version: string;
  approval_reference: string | null;
  approval_status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'EXPIRED' | null;
  requested_by: string | null;
  operation_key: string | null;
  requested_currency: Exclude<WalletCurrency, 'COTTON_CANDY'> | null;
  requested_direction: 'CREDIT' | 'DEBIT' | null;
  requested_amount: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminCsSummary {
  userId: string;
  balances: Record<WalletCurrency, bigint>;
  openDebt: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, bigint>;
  cottonExpiringAmount: bigint;
  cottonNextExpiresAt: string | null;
  invariantStatus: WalletInvariantStatus;
  authoritativeTotals: Record<WalletCurrency, bigint>;
  recentOperation: WalletOperation | null;
  snapshotAt: string;
}

export interface CurrencyHistoryItem
  extends Omit<CurrencyHistoryItemWire, 'delta' | 'balance_effect'> {
  delta: bigint;
  balance_effect: bigint;
}

export interface TimelineAllocation
  extends Omit<
    TimelineAllocationWire,
    'gross_delta' | 'wallet_delta' | 'debt_delta'
  > {
  gross_delta: bigint;
  wallet_delta: bigint;
  debt_delta: bigint;
}

export interface MoneyTimelineItem
  extends Omit<MoneyTimelineItemWire, 'allocations'> {
  allocations: TimelineAllocation[];
}

export interface PromotionCampaignVersionWire {
  id: string;
  campaign_id: string;
  version: string;
  effective_from: string;
  is_active: boolean;
  timezone: 'Asia/Seoul';
  weekly_start_isodow: 1;
  weekly_start_time: '00:00:00';
  weekly_end_isodow: 3;
  weekly_end_time: '00:00:00';
  extra_bonus_bps: string;
  display_name: Record<string, string>;
  show_home_banner: boolean;
  show_in_store: boolean;
  home_banner_id: number | null;
  rollout_policy: {
    minimum_app_version: string;
    minimum_app_build: string;
    cohort_version: string;
    cohort_seed: string;
    cohort_threshold_bps: string;
  };
  change_reason: string;
  created_by: string;
  created_at: string;
  audit_id: string;
}

export interface PromotionCampaignWire {
  id: string;
  code: 'CANDY_BOOST_DAY';
  kind: 'PURCHASE_BONUS';
  latest_version: PromotionCampaignVersionWire;
}

export interface PromotionCampaignVersion
  extends Omit<
    PromotionCampaignVersionWire,
    'version' | 'extra_bonus_bps' | 'rollout_policy'
  > {
  version: bigint;
  extra_bonus_bps: bigint;
  rollout_policy: Omit<
    PromotionCampaignVersionWire['rollout_policy'],
    'cohort_threshold_bps'
  > & {
    cohort_threshold_bps: bigint;
  };
}

export interface PromotionCampaign
  extends Omit<PromotionCampaignWire, 'latest_version'> {
  latest_version: PromotionCampaignVersion;
}

export type PromotionCampaignVersionPageWire =
  CursorPageWire<PromotionCampaignVersionWire>;
export type PromotionCampaignVersionPage =
  CursorPage<PromotionCampaignVersion>;

export interface PromotionPreviewWire {
  campaign_id: string;
  evaluated_at: string;
  status: 'ACTIVE' | 'INACTIVE' | 'NO_EFFECTIVE_VERSION';
  effective_version: PromotionCampaignVersionWire | null;
  window_start: string | null;
  window_end: string | null;
  surfaces: Array<'HOME' | 'STORE'>;
}

export interface PromotionPreview
  extends Omit<PromotionPreviewWire, 'effective_version'> {
  effective_version: PromotionCampaignVersion | null;
}

export interface WalletOperation
  extends Omit<WalletOperationWire, 'attempt_count' | 'row_version' | 'requested_amount'> {
  attempt_count: bigint;
  row_version: bigint;
  requested_amount: bigint | null;
}

export interface WalletDebtItemWire {
  id: string;
  user_id: string;
  currency: Exclude<WalletCurrency, 'COTTON_CANDY'>;
  reason: 'PURCHASE_REFUND' | 'CHARGEBACK' | 'CORRECTION';
  status: WalletDebtStatus;
  owed_amount: string;
  recovered_amount: string;
  waived_amount: string;
  outstanding_amount: string;
  source_refund_allocation_id: string | null;
  source_debit_allocation_id: string | null;
  row_version: string;
  created_at: string;
  updated_at: string;
}

export interface WalletDebtItem
  extends Omit<
    WalletDebtItemWire,
    | 'owed_amount'
    | 'recovered_amount'
    | 'waived_amount'
    | 'outstanding_amount'
    | 'row_version'
  > {
  owed_amount: bigint;
  recovered_amount: bigint;
  waived_amount: bigint;
  outstanding_amount: bigint;
  row_version: bigint;
}

export interface WalletAlertWire {
  id: string;
  severity: 'CRITICAL' | 'WARNING';
  status: WalletAlertStatus;
  summary: string;
  occurrence_count: string;
  resource_type: string;
  resource_id: string;
  first_seen_at: string;
  last_seen_at: string;
  row_version: string;
  audit_id: string | null;
}

export interface WalletAlert
  extends Omit<WalletAlertWire, 'occurrence_count' | 'row_version'> {
  occurrence_count: bigint;
  row_version: bigint;
}

export interface WalletOpsSummaryWire {
  inbox_pending_count: string;
  inbox_dead_count: string;
  inbox_oldest_pending_seconds: string;
  debt_open_amount: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, string>;
  debt_oldest_open_seconds: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, string>;
  debt_recovery_rate_bps: string;
  campaign_conflict_count: string;
  audit_completeness_bps: string;
  expiry_status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  reconciliation_status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  snapshot_at: string;
}

export interface WalletOpsSummary {
  inboxPendingCount: bigint;
  inboxDeadCount: bigint;
  inboxOldestPendingSeconds: bigint;
  debtOpenAmount: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, bigint>;
  debtOldestOpenSeconds: Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, bigint>;
  debtRecoveryRateBps: bigint;
  campaignConflictCount: bigint;
  auditCompletenessBps: bigint;
  expiryStatus: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  reconciliationStatus: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  snapshotAt: string;
}

export type WalletRuntimeFlagKey =
  | 'wallet.cotton_read_enabled'
  | 'wallet.cotton_spend_enabled'
  | 'wallet.cotton_expiry_enabled'
  | 'ads.internal_reward_mode'
  | 'ads.pangle_reward_mode'
  | 'ads.pangle_claim_mode'
  | 'ads.cotton_popup_enabled'
  | 'candy_boost_write_enabled'
  | 'refund_reversal_enabled'
  | 'debt_recovery_enabled'
  | 'promotion_surfaces_enabled'
  | 'admin_financial_commands_enabled';

export interface WalletRuntimeFlagValues {
  'wallet.cotton_read_enabled': boolean;
  'wallet.cotton_spend_enabled': boolean;
  'wallet.cotton_expiry_enabled': boolean;
  'ads.internal_reward_mode': 'bonus' | 'cotton' | 'paused';
  'ads.pangle_reward_mode': 'bonus' | 'cotton' | 'paused';
  'ads.pangle_claim_mode': 'shadow' | 'optional' | 'required';
  'ads.cotton_popup_enabled': boolean;
  candy_boost_write_enabled: boolean;
  refund_reversal_enabled: boolean;
  debt_recovery_enabled: boolean;
  promotion_surfaces_enabled: boolean;
  admin_financial_commands_enabled: boolean;
}

export interface WalletRuntimeFlagsWire {
  flag_version: string;
  values: WalletRuntimeFlagValues;
  changed_at: string;
  changed_by: string;
  snapshot_at: string;
}

export interface WalletRuntimeFlags
  extends Omit<WalletRuntimeFlagsWire, 'flag_version'> {
  flag_version: bigint;
}

export interface InvariantViolationWire {
  id: string;
  status: Exclude<WalletInvariantStatus, 'OK'>;
  resource_type: string;
  resource_id: string;
  currency: WalletCurrency | null;
  expected_amount: string | null;
  actual_amount: string | null;
  operation_id: string | null;
  support_ref: string;
  detected_at: string;
}

export interface InvariantViolation
  extends Omit<InvariantViolationWire, 'expected_amount' | 'actual_amount'> {
  expected_amount: bigint | null;
  actual_amount: bigint | null;
}

export interface WorkerHealthWire {
  worker_name: string;
  status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  last_heartbeat_at: string | null;
  last_success_at: string | null;
  lag_seconds: string;
  support_ref: string | null;
}

export interface WorkerHealth
  extends Omit<WorkerHealthWire, 'lag_seconds'> {
  lag_seconds: bigint;
}

export interface WalletAuditEventWire {
  id: string;
  actor_user_id: string;
  actor_role: WalletActorRole | 'SYSTEM';
  action_code: string;
  resource_type: string;
  resource_id: string;
  operation_id: string | null;
  request_id: string;
  reason: string;
  cs_ticket: string | null;
  before_json: Record<string, unknown>;
  after_json: Record<string, unknown>;
  campaign_version_id: string | null;
  created_at: string;
}

export type WalletAuditEvent = WalletAuditEventWire;

export interface StableErrorEnvelope {
  ok: false;
  domain_code: string;
  retryable: boolean;
  operation_id: string | null;
  support_ref: string;
}

export interface StableSuccessEnvelope<T> {
  ok: true;
  operation_id: string;
  audit_id: string;
  result: T;
}

export type StableCommandEnvelope<T> =
  | StableSuccessEnvelope<T>
  | StableErrorEnvelope;

export interface CursorQueryBase {
  cursor: string | null;
  limit: number;
}

export interface CurrencyHistoryQuery extends CursorQueryBase {
  userId: string;
  currency: WalletCurrency;
  filters: {
    from?: string;
    to?: string;
    event_types?: string[];
  };
}

export interface TimelineQuery extends CursorQueryBase {
  userId: string;
  filters: {
    from?: string;
    to?: string;
    event_types?: string[];
    provider?: string;
    campaign_id?: string;
  };
}

export interface PromotionCampaignQuery extends CursorQueryBase {
  filters: {
    statuses?: Array<'ACTIVE' | 'INACTIVE'>;
    campaign_id?: string;
  };
}

export interface PromotionCampaignVersionQuery extends CursorQueryBase {
  campaignId: string;
}

export interface WalletDebtQuery extends CursorQueryBase {
  userId: string;
  filters: {
    from?: string;
    to?: string;
    currency?: Exclude<WalletCurrency, 'COTTON_CANDY'>;
    statuses?: WalletDebtStatus[];
  };
}

export interface WalletOperationQuery extends CursorQueryBase {
  filters: {
    from?: string;
    to?: string;
    statuses?: WalletOperationStatus[];
    event_types?: string[];
    provider?: string;
  };
}

export interface WalletAlertQuery extends CursorQueryBase {
  filters: {
    from?: string;
    to?: string;
    statuses?: WalletAlertStatus[];
    severity?: 'CRITICAL' | 'WARNING';
  };
}

export interface InvariantViolationQuery extends CursorQueryBase {
  filters: {
    from?: string;
    to?: string;
    statuses?: Array<Exclude<WalletInvariantStatus, 'OK'>>;
  };
}

export interface WalletAuditQuery extends CursorQueryBase {
  filters: {
    from?: string;
    to?: string;
    event_types?: string[];
    campaign_id?: string;
  };
}
```

`lib/wallet/decode-wallet-admin.ts`는 `/^-?[0-9]+$/`만 허용하는 `parseWalletAmount`, `decodeCursorPage`, `decodeCsSummary`, currency history, timeline allocation, campaign version/history, debt item, operation, alert, ops summary, invariant, worker health, runtime flags, audit event decoder를 export한다. currency history의 `delta`와 `balance_effect`, debt의 네 금액과 `row_version`, ops summary의 debt aging, runtime `flag_version`까지 read service 밖으로 나오는 bigint 필드는 전부 `bigint`이어야 한다. `formatWalletAmount(value: bigint)`는 `value.toString()`에서 세 자리 구분만 추가하고 `Number`를 사용하지 않는다.

- [ ] **Step 4: type generation을 explicit하고 atomic하게 바꾼다**

`scripts/generate-supabase-types-safe.mjs`는 remote project id를 하드코딩하지 않는다. Preview/staging에서는 `PICNIC_STAGING_SUPABASE_PROJECT_REF`를 요구하고 production project ref `xtijtefcycoeqludlngc`는 거부한다. CI는 먼저 `verify:wallet-env`를 통과시키고, 허용된 staging ref에 대해서만 `supabase gen types typescript --project-id "$PICNIC_STAGING_SUPABASE_PROJECT_REF"` 출력을 임시 파일에 쓴 뒤 Fixed RPC Contract의 25개 function 이름이 모두 있을 때 새 worktree의 `types/supabase.ts`로 atomic rename한다. Production build는 remote type generation을 실행하지 않고 검증된 generated artifact만 사용한다. browser-safe read 15개, two-argument command 9개, failure recorder 1개가 검증 대상이다. 9개 command의 generated args가 정확히 `p_actor_user_id`, `p_request`인지 함께 검증한다. `types/wallet-admin-contract-check.ts`는 15개 read의 argument와 네 추가 safe DTO의 key/primitive/nullability, 11개 permission allowlist를 생성 타입/공유 manifest와 양방향 비교한다. 그 뒤 `npx tsx scripts/generate-interfaces.ts`를 실행하고 동일 입력에서 byte-identical `types/interfaces.ts`가 생성되는지 검증한다. 실패 시 기존 generated file은 그대로 남아야 한다.

`package.json`에는 Task 0의 fail-closed guard를 유지하고 다음 script를 둔다. `predev`, `prebuild`, `prestart`, `pretest` 어느 것도 remote type generation을 호출하지 않는다.

```json
{
  "gen:types": "npm run verify:wallet-env && node scripts/generate-supabase-types-safe.mjs",
  "verify:wallet-contracts": "node /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/scripts/wallet/verify_contract_checksums.mjs --manifest /Users/charlie.hyun/Repositories/picnic-supabase-cotton-candy-engine/supabase/tests/wallet/contracts/manifest.json /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_lib/test/fixtures/wallet_contracts /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops/test/fixtures/wallet-contracts --app-integration-dart /Users/charlie.hyun/Repositories/picnic-app-cotton-candy-policy/picnic_app/integration_test/fixtures/wallet_contract_fixtures.g.dart"
}
```

`types/interfaces.ts`는 현재 ignore되어 있으므로 최초 deterministic generation 직후 `git add -f types/interfaces.ts`로 tracked artifact화한다. 이후에는 ignore 규칙과 무관하게 일반 수정으로 추적되며, fresh checkout/Vercel은 remote type generation 없이 이 파일을 입력으로 사용한다. 원본 main worktree의 dirty `types/supabase.ts`는 읽거나 복사하거나 stage하지 않는다.

Run:

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
npm run gen:types
git add -f types/interfaces.ts
cp types/interfaces.ts /tmp/picnic-admin-wallet-interfaces.ts
npm run gen:types
cmp /tmp/picnic-admin-wallet-interfaces.ts types/interfaces.ts
npm run verify:wallet-contracts
git ls-files --error-unmatch types/interfaces.ts
git diff --exit-code -- types/interfaces.ts
```

Expected: type generation exits 0 only with a non-production staging ref, checksum verifier reports 12 fixtures and integration constants with zero mismatch, `types/interfaces.ts` is tracked and regeneration is byte-identical. Production-ref/link metadata or a public service-role variable fails before Supabase CLI. Running `npm run build` no longer starts remote type generation.

- [ ] **Step 5: contract test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet/wallet-contract.test.ts && npm run type-check`

Expected: PASS and both commands exit 0.

- [ ] **Step 6: commit한다**

```bash
git add package.json scripts/generate-supabase-types-safe.mjs types/supabase.ts types/wallet-admin-contract-check.ts lib/types/wallet-admin.ts lib/wallet/decode-wallet-admin.ts test/fixtures/wallet-contracts __tests__/wallet/wallet-contract.test.ts
git add -f types/interfaces.ts
git commit -m "chore(wallet): pin admin contract boundary"
```

---

### Task 2: typed read service와 wallet RBAC guard를 만든다

**Files:**
- Create: `lib/services/walletAdminService.ts`
- Create: `lib/hooks/useWalletPermissions.ts`
- Create: `components/auth/RequireWalletPermission.tsx`
- Create: `__tests__/wallet/walletAdminService.test.ts`
- Create: `__tests__/wallet/RequireWalletPermission.test.tsx`
- Modify: `lib/supabase/client.ts`
- Modify: `lib/supabase/server.ts`

- [ ] **Step 1: read RPC 이름과 parameter mapping을 실패하는 service test로 고정한다**

`__tests__/wallet/walletAdminService.test.ts`는 mock `rpc`가 받은 호출을 검사한다.

```ts
import { createWalletAdminService } from '@/lib/services/walletAdminService';
import { WALLET_PERMISSION_ALLOWLIST } from '@/lib/types/wallet-admin';

const TEST_RUNTIME_FLAGS = {
  'wallet.cotton_read_enabled': true,
  'wallet.cotton_spend_enabled': true,
  'wallet.cotton_expiry_enabled': true,
  'ads.internal_reward_mode': 'paused',
  'ads.pangle_reward_mode': 'paused',
  'ads.pangle_claim_mode': 'shadow',
  'ads.cotton_popup_enabled': false,
  candy_boost_write_enabled: false,
  refund_reversal_enabled: false,
  debt_recovery_enabled: true,
  promotion_surfaces_enabled: false,
  admin_financial_commands_enabled: false,
} as const;
const TEST_ACTOR_ID = '00000000-0000-4000-8000-000000000003';

describe('walletAdminService', () => {
  it('currency history에 opaque cursor와 고정 limit을 전달한다', async () => {
    const rpc = jest.fn().mockResolvedValue({
      data: {
        items: [],
        total_count: '0',
        next_cursor: null,
        snapshot_at: '2026-07-21T00:00:00Z',
      },
      error: null,
    });
    const service = createWalletAdminService({ rpc });

    const page = await service.listCurrencyHistory({
      userId: '9bce60fd-16c0-43c5-90d7-28bca0b2ac70',
      currency: 'BONUS_STAR_CANDY',
      filters: { event_types: ['PURCHASE'] },
      cursor: 'opaque-page-2',
      limit: 20,
    });

    expect(rpc).toHaveBeenCalledWith('admin_list_user_currency_history', {
      p_user_id: '9bce60fd-16c0-43c5-90d7-28bca0b2ac70',
      p_currency: 'BONUS_STAR_CANDY',
      p_filters: { event_types: ['PURCHASE'] },
      p_cursor: 'opaque-page-2',
      p_limit: 20,
    });
    expect(page.totalCount).toBe(BigInt(0));
  });

  it('history/debt/runtime/audit RPC의 고정 parameter 이름을 사용한다', async () => {
    const empty = {
      items: [], total_count: '0', next_cursor: null,
      snapshot_at: '2026-07-21T00:00:00Z',
    };
    const rpc = jest.fn().mockImplementation((name: string) =>
      Promise.resolve({
        data: name === 'admin_get_wallet_runtime_flags'
          ? {
              flag_version: '7',
              values: TEST_RUNTIME_FLAGS,
              changed_at: '2026-07-21T00:00:00Z',
              changed_by: TEST_ACTOR_ID,
              snapshot_at: '2026-07-21T00:00:00Z',
            }
          : empty,
        error: null,
      }),
    );
    const service = createWalletAdminService({ rpc });

    await service.listPromotionCampaignVersions({
      campaignId: '10119a59-32d9-475d-a0e8-a8e5af5a287d', cursor: null, limit: 20,
    });
    await service.listUserDebts({
      userId: '9bce60fd-16c0-43c5-90d7-28bca0b2ac70',
      filters: { statuses: ['OPEN'] }, cursor: null, limit: 20,
    });
    await service.getRuntimeFlags();
    await service.listAuditEvents({
      filters: { event_types: ['ADMIN_ADJUST'] }, cursor: null, limit: 20,
    });

    expect(rpc).toHaveBeenCalledWith('admin_list_promotion_campaign_versions', {
      p_campaign_id: '10119a59-32d9-475d-a0e8-a8e5af5a287d',
      p_cursor: null, p_limit: 20,
    });
    expect(rpc).toHaveBeenCalledWith('admin_list_user_wallet_debts', {
      p_user_id: '9bce60fd-16c0-43c5-90d7-28bca0b2ac70',
      p_filters: { statuses: ['OPEN'] }, p_cursor: null, p_limit: 20,
    });
    expect(rpc).toHaveBeenCalledWith('admin_get_wallet_runtime_flags', {});
    expect(rpc).toHaveBeenCalledWith('admin_list_wallet_audit_events', {
      p_filters: { event_types: ['ADMIN_ADJUST'] }, p_cursor: null, p_limit: 20,
    });
  });

  it('승인되지 않은 filter alias를 RPC 전에 거부한다', async () => {
    const rpc = jest.fn();
    const service = createWalletAdminService({ rpc });
    await expect(service.listOperations({
      filters: { status: 'PENDING' } as never, cursor: null, limit: 20,
    })).rejects.toThrow('WALLET_FILTER_KEY_NOT_ALLOWED');
    expect(rpc).not.toHaveBeenCalled();
  });

  it('limit 범위 밖 요청을 RPC 전에 거부한다', async () => {
    const rpc = jest.fn();
    const service = createWalletAdminService({ rpc });
    await expect(
      service.listOperations({ filters: {}, cursor: null, limit: 101 }),
    ).rejects.toThrow('WALLET_CURSOR_LIMIT_OUT_OF_RANGE');
    expect(rpc).not.toHaveBeenCalled();
  });

  it('actor context는 canonical dotted permission만 허용한다', async () => {
    const validRpc = jest.fn().mockResolvedValue({
      data: {
        actor_id: TEST_ACTOR_ID,
        actor_role: 'SUPER_ADMIN',
        permissions: [...WALLET_PERMISSION_ALLOWLIST],
      },
      error: null,
    });
    await expect(createWalletAdminService({ rpc: validRpc }).getActorContext())
      .resolves.toEqual(expect.objectContaining({ actor_id: TEST_ACTOR_ID }));

    for (const invalid of ['wallet:read', 'wallet_adjust.execute']) {
      const invalidRpc = jest.fn().mockResolvedValue({
        data: {
          actor_id: TEST_ACTOR_ID,
          actor_role: 'SUPER_ADMIN',
          permissions: [invalid],
        },
        error: null,
      });
      await expect(createWalletAdminService({ rpc: invalidRpc }).getActorContext())
        .rejects.toThrow('WALLET_PERMISSION_CONTRACT_INVALID');
    }
  });
});
```

Run: `npm test -- --runInBand __tests__/wallet/walletAdminService.test.ts`

Expected: FAIL because the service does not exist.

- [ ] **Step 2: generated Database type를 client 두 곳에 연결하고 read adapter를 구현한다**

`createBrowserClient<Database>`와 `createServerClient<Database>`를 사용한다. `walletAdminService.ts`의 public methods는 다음으로 고정한다.

```ts
export interface WalletAdminService {
  getActorContext(): Promise<WalletActorContextWire>;
  getUserCsSummary(userId: string): Promise<AdminCsSummary>;
  listCurrencyHistory(input: CurrencyHistoryQuery): Promise<CursorPage<CurrencyHistoryItem>>;
  listMoneyTimeline(input: TimelineQuery): Promise<CursorPage<MoneyTimelineItem>>;
  listPromotionCampaigns(input: PromotionCampaignQuery): Promise<CursorPage<PromotionCampaign>>;
  listPromotionCampaignVersions(input: PromotionCampaignVersionQuery): Promise<PromotionCampaignVersionPage>;
  previewPromotionCampaign(campaignId: string, at: string): Promise<PromotionPreview>;
  listUserDebts(input: WalletDebtQuery): Promise<CursorPage<WalletDebtItem>>;
  listOperations(input: WalletOperationQuery): Promise<CursorPage<WalletOperation>>;
  listAlerts(input: WalletAlertQuery): Promise<CursorPage<WalletAlert>>;
  getOpsSummary(at: string | null): Promise<WalletOpsSummary>;
  listInvariantViolations(input: InvariantViolationQuery): Promise<CursorPage<InvariantViolation>>;
  getWorkerHealth(): Promise<WorkerHealth[]>;
  getRuntimeFlags(): Promise<WalletRuntimeFlags>;
  listAuditEvents(input: WalletAuditQuery): Promise<CursorPage<WalletAuditEvent>>;
}
```

모든 method는 Fixed RPC Contract의 `p_` argument를 그대로 사용하고 `{ data, error }`의 error가 있으면 `WalletAdminReadError`를 throw한다. `getActorContext`는 `WALLET_PERMISSION_ALLOWLIST` 밖의 값, colon alias, resource/action 내부 이름을 발견하면 fail closed한다. read error 메시지에는 user ID, cursor, provider payload를 포함하지 않는다.

- [ ] **Step 3: 권한 guard를 먼저 실패하는 component test로 작성한다**

`__tests__/wallet/RequireWalletPermission.test.tsx`에서 actor context를 mock해 다음을 검증한다.

```ts
it.each([
  ['OPERATOR', 'wallet.read', true],
  ['OPERATOR', 'wallet.adjust.star_bonus', false],
  ['FINANCE_ADMIN', 'wallet.adjust.star_bonus', true],
  ['FINANCE_ADMIN', 'wallet.adjust.star_bonus.approve', false],
  ['FINANCE_ADMIN', 'wallet.correction.apply', false],
  ['SUPER_ADMIN', 'wallet.adjust.star_bonus.approve', true],
  ['SUPER_ADMIN', 'wallet.correction.apply', true],
] as const)('%s의 %s 노출은 %s다', async (role, permission, visible) => {
  mockActorContext(role);
  render(
    <RequireWalletPermission required={permission} fallback={null}>
      <button>protected-action</button>
    </RequireWalletPermission>,
  );
  if (visible) {
    expect(await screen.findByRole('button', { name: 'protected-action' })).toBeVisible();
  } else {
    await waitFor(() => {
      expect(screen.queryByRole('button', { name: 'protected-action' })).toBeNull();
    });
  }
});
```

Run: `npm test -- --runInBand __tests__/wallet/RequireWalletPermission.test.tsx`

Expected: FAIL because hook and guard do not exist.

- [ ] **Step 4: actor context cache와 guard를 구현한다**

`useWalletPermissions`는 `admin_get_wallet_actor_context` 결과를 5분 in-memory cache하고 sign-out 또는 명시적 `clearWalletPermissionCache()`에서 지운다. error 시 permissions는 빈 배열이다. `RequireWalletPermission`은 loading 중 `Skeleton`, page guard에서는 403 `Result`, action guard에서는 전달된 `fallback`을 렌더링한다.

- [ ] **Step 5: service와 guard test, type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet/walletAdminService.test.ts __tests__/wallet/RequireWalletPermission.test.tsx && npm run type-check`

Expected: PASS and both commands exit 0.

- [ ] **Step 6: commit한다**

```bash
git add lib/supabase/client.ts lib/supabase/server.ts lib/services/walletAdminService.ts lib/hooks/useWalletPermissions.ts components/auth/RequireWalletPermission.tsx __tests__/wallet/walletAdminService.test.ts __tests__/wallet/RequireWalletPermission.test.tsx
git commit -m "feat(wallet): add typed reads and role permissions"
```

---

### Task 3: 사용자 상세를 3재화 CS workspace로 전환한다

**Files:**
- Create: `app/user_profiles/components/wallet/UserWalletPanel.tsx`
- Create: `app/user_profiles/components/wallet/UserMoneySummary.tsx`
- Create: `app/user_profiles/components/wallet/UserCurrencyHistory.tsx`
- Create: `app/user_profiles/components/wallet/UserMoneyTimeline.tsx`
- Create: `app/user_profiles/components/wallet/UserDebtList.tsx`
- Create: `app/user_profiles/components/wallet/index.ts`
- Create: `__tests__/wallet/UserWalletPanel.test.tsx`
- Create: `__tests__/wallet/UserProfileWalletWriteGuard.test.tsx`
- Modify: `app/user_profiles/components/UserProfileDetail.tsx`
- Modify: `app/user_profiles/components/UserProfileForm.tsx`
- Modify: `app/user_profiles/components/UserProfileList.tsx`
- Modify: `app/user_profiles/show/[id]/page.tsx`

- [ ] **Step 1: 세 통화 분리, debt, cursor, timeline을 실패하는 UI test로 작성한다**

`__tests__/wallet/UserWalletPanel.test.tsx`는 `admin_cs_summary_v1`, `admin_money_timeline_v1`과 `admin_list_user_wallet_debts`의 concrete page fixture(`id=TEST_DEBT_ID`, `outstanding_amount='450'`, `row_version='4'`)를 mock service 결과로 사용해 다음을 검증한다.

```ts
const TEST_DEBT_ID = '00000000-0000-4000-8000-000000000030';

expect(await screen.findByText('스타캔디')).toBeVisible();
expect(screen.getByText('보너스 스타캔디')).toBeVisible();
expect(screen.getByText('코튼캔디')).toBeVisible();
expect(screen.getByText('만료 예정')).toBeVisible();
expect(screen.getByText('미회수 부채')).toBeVisible();
expect(screen.getByTestId('wallet-debt-id')).toHaveTextContent(TEST_DEBT_ID);
expect(screen.getByTestId('wallet-debt-version')).toHaveTextContent('4');
expect(screen.getAllByTestId('timeline-allocation')).toHaveLength(2);
expect(screen.queryByTestId('combined-star-bonus-total')).toBeNull();
```

통화 tab을 바꾼 뒤 `admin_list_user_currency_history`가 선택 통화를 받고, `더 보기`를 누르면 직전 `next_cursor`를 그대로 전달하는 assertion도 포함한다.

Run: `npm test -- --runInBand __tests__/wallet/UserWalletPanel.test.tsx`

Expected: FAIL because wallet components do not exist.

- [ ] **Step 2: summary와 currency history를 구현한다**

Summary card 순서는 `스타캔디`, `보너스 스타캔디`, `코튼캔디`다. 각 current balance는 `data-testid="wallet-balance-${currency}"`를 사용하고 authoritative total을 같은 통화끼리 비교한다. summary의 `invariant_status`가 `DRIFT` 또는 `UNKNOWN`이면 Wallet Ops 링크를 표시한다. Cotton card만 `cotton_expiring_amount`, `cotton_next_expires_at`을 표시한다. Star/Bonus card만 open debt를 표시한다.

History는 `currency` tab, 공개 `event_types`, `from`, `to` filter만 제공한다. 행은 bigint로 decode된 `delta`, `balance_effect`, origin, event type, expiry, purchase/refund/grant reference, operation ID를 표시하고 raw provider payload와 receipt를 렌더링하지 않는다. 동일 timestamp 행도 server cursor 순서를 그대로 유지한다.

`UserDebtList`는 `admin_list_user_wallet_debts` 결과의 debt ID, currency, reason, owed/recovered/waived/outstanding, status, `row_version`, source reference를 표시한다. Finance Admin 이상의 면제 action은 선택한 행의 `id`, `outstanding_amount`, `row_version`을 Task 7 drawer에 전달하며 aggregate open debt로 ID나 version을 추론하지 않는다.

- [ ] **Step 3: money timeline을 구현한다**

Timeline은 `kind`, provider occurred time, campaign version, operation ID, audit ID와 allocations table을 표시한다. allocation row는 `component`, `currency`, `gross_delta`, `wallet_delta`, `debt_delta`를 각각 `formatWalletAmount`로 렌더링한다. 합계 footer는 currency별 group만 허용한다.

- [ ] **Step 4: 기존 profile 화면에서 raw balance read와 입력을 제거한다**

`UserProfileDetail.tsx`에서 `fetchStarCandyHistory`, `fetchStarCandyBonusHistory`, `fetchUnifiedActivity`와 기존 재화 modal state를 제거하고 `<UserWalletPanel userId={profile.id} />`를 넣는다. 이 task에서는 read UI만 연결하고 command button은 Task 4에서 추가한다.

`UserProfileForm.tsx`의 생성/수정 Star·Bonus balance input을 제거한다. 입력을 숨기는 것만으로 충분하지 않다. 기존 `...formProps.initialValues`가 숨은 balance key를 다시 submit하지 않도록 create/edit 모두 다음 exact mutable identity allowlist로 새 payload를 구성한다.

```ts
export const USER_PROFILE_MUTABLE_FIELDS = [
  'nickname',
  'email',
  'avatar_url',
  'gender',
  'birth_date',
  'birth_time',
  'open_gender',
  'open_ages',
  'is_admin',
] as const;

export function toUserProfileMutationPayload(
  values: Record<string, unknown>,
): Record<(typeof USER_PROFILE_MUTABLE_FIELDS)[number], unknown> {
  return Object.fromEntries(
    USER_PROFILE_MUTABLE_FIELDS.map((key) => [key, values[key]]),
  ) as Record<(typeof USER_PROFILE_MUTABLE_FIELDS)[number], unknown>;
}
```

`handleFinish`는 오직 `toUserProfileMutationPayload(values)`를 `formProps.onFinish`에 전달한다. `id`, `country_code`, `last_ip`, `deleted_at`, `star_candy`, `star_candy_bonus`, `cotton_candy`와 알 수 없는 key는 create/edit body에 없어야 한다. `getInitialValues`도 balance default를 만들지 않는다. `UserProfileWalletWriteGuard.test.tsx`는 balance와 unknown key를 initial/form value에 주입한 create/edit 두 case에서 intercepted `onFinish` body의 key가 위 allowlist와 정확히 같고 세 balance key가 없음을 검증한다.

`UserProfileList.tsx`의 raw balance select와 balance column을 제거한다. `show/[id]/page.tsx`의 `.select('*')`를 identity/display 필드 allowlist로 교체한다.

- [ ] **Step 5: test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet/UserWalletPanel.test.tsx __tests__/wallet/UserProfileWalletWriteGuard.test.tsx && npm run type-check`

Expected: PASS. `combined-star-bonus-total`은 없고 raw balance form control도 없다.

- [ ] **Step 6: commit한다**

```bash
git add app/user_profiles/components/wallet app/user_profiles/components/UserProfileDetail.tsx app/user_profiles/components/UserProfileForm.tsx app/user_profiles/components/UserProfileList.tsx app/user_profiles/show/[id]/page.tsx __tests__/wallet/UserWalletPanel.test.tsx __tests__/wallet/UserProfileWalletWriteGuard.test.tsx
git commit -m "feat(wallet): replace profile balance views with cs workspace"
```

---

### Task 4: 서버 command boundary와 Star/Bonus 관리자 조정을 구현한다

**Files:**
- Create: `lib/supabase/service-role.server.ts`
- Create: `lib/wallet/admin-command-contract.ts`
- Create: `lib/services/walletAdminCommand.server.ts`
- Create: `lib/services/walletAdminCommand.client.ts`
- Create: `app/api/wallet/adjust/route.ts`
- Create: `app/api/wallet/adjust/approve/route.ts`
- Create: `app/user_profiles/components/wallet/AdminAdjustmentModal.tsx`
- Create: `app/wallet-ops/components/AdminAdjustmentApprovalDrawer.tsx`
- Create: `__tests__/api/wallet/walletAdminCommand.server.test.ts`
- Create: `__tests__/api/wallet/adjust.route.test.ts`
- Create: `__tests__/wallet/AdminAdjustmentModal.test.tsx`
- Modify: `app/user_profiles/components/wallet/UserWalletPanel.tsx`

- [ ] **Step 1: 허용 필드, role, failure recorder를 API 실패 test로 고정한다**

`admin_adjust_star_bonus` request는 `action`으로 분기하는 다음 exact union이다. `REQUEST`에서는 `approval_reference`가 반드시 null이고 `APPROVE`에서는 DB에 저장된 요청을 가리키는 non-empty reference다.

```ts
export interface AdminAdjustRequest {
  action: 'REQUEST';
  request_id: string;
  operation_key: string;
  user_id: string;
  direction: 'CREDIT' | 'DEBIT';
  currency: 'STAR_CANDY' | 'BONUS_STAR_CANDY';
  amount: string;
  reason: string;
  cs_ticket: string;
  approval_reference: null;
}

export interface AdminAdjustApprovalRequest {
  action: 'APPROVE';
  request_id: string;
  operation_key: string;
  approval_reference: string;
  reason: string;
  cs_ticket: string;
}

export type AdminAdjustCommandRequest =
  | AdminAdjustRequest
  | AdminAdjustApprovalRequest;

export interface AdminAdjustAppliedResult {
  status: 'APPLIED';
  user_id: string;
  currency: 'STAR_CANDY' | 'BONUS_STAR_CANDY';
  direction: 'CREDIT' | 'DEBIT';
  gross_amount: string;
  debt_offset_amount: string;
  net_wallet_credit_amount: string;
  wallet_delta: string;
  debt_created_amount: '0';
  balance_after: string;
  debt_outstanding_after: string;
}

export interface AdminAdjustPendingApprovalResult {
  status: 'PENDING_APPROVAL';
  approval_reference: string;
  operation_key: string;
  requested_by: string;
  expires_at: string;
}

export type AdminAdjustResult =
  | AdminAdjustAppliedResult
  | AdminAdjustPendingApprovalResult;
```

`__tests__/api/wallet/adjust.route.test.ts`는 다음을 검증한다.

- unauthenticated 요청은 401이고 RPC를 호출하지 않는다.
- `COTTON_CANDY`, 0, 음수, decimal amount, 빈 reason, 빈 ticket을 400으로 거부한다.
- `actor_id`, `approver_id`, `target_balance`, `history_type` 추가 필드를 400으로 거부한다.
- 정상 요청은 사용자 세션에서 얻은 actor ID를 사용해 service-role client로 `admin_adjust_star_bonus({ p_actor_user_id: session.user.id, p_request: body })`를 정확히 한 번 호출한다.
- Finance 한도 이하는 `APPLIED`, 한도 초과는 wallet delta 없이 `PENDING_APPROVAL` + `approval_reference`를 반환한다.
- `/api/wallet/adjust/approve`는 `wallet.adjust.star_bonus.approve`를 가진 Super Admin만 호출하고 `APPROVE` exact body 외의 user/currency/amount/actor/approver 재입력을 거부한다.
- requester와 approver가 같은 경우 DB의 `ADMIN_ADJUST_TWO_PERSON_REQUIRED` envelope를 status 200으로 그대로 반환한다.
- domain error envelope는 status 200과 원 필드로 전달한다.
- audit insert 실패를 나타내는 `AUDIT_WRITE_FAILED` envelope는 성공으로 바꾸지 않고, client cache invalidate도 실행하지 않는다. 실제 wallet mutation rollback은 Supabase pgTAP 계약 test가 검증한다.
- Supabase transport error 또는 malformed command response면 service-role로 `record_wallet_command_failure`를 별도 호출한다. recorder payload의 `actor_user_id`는 session-derived 값이고 외부 body의 actor spoof는 parser에서 거부하며, recorder가 반환한 stable failure만 응답한다.

Run: `npm test -- --runInBand __tests__/api/wallet/walletAdminCommand.server.test.ts __tests__/api/wallet/adjust.route.test.ts`

Expected: FAIL because route and command boundary do not exist.

- [ ] **Step 2: server-only command executor를 구현한다**

`lib/supabase/service-role.server.ts`는 아래 전체 내용으로 만든다. browser module에서 import되면 `server-only`로 Next build가 실패해야 한다.

```ts
import 'server-only';

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/supabase';

let singleton: SupabaseClient<Database> | null = null;

export function createSupabaseServiceRoleClient(): SupabaseClient<Database> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('WALLET_SERVICE_ROLE_ENV_MISSING');
  singleton ??= createClient<Database>(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  });
  return singleton;
}
```

`walletAdminCommand.server.ts`는 아래 전체 계약으로 작성한다. 이 파일 밖에서 service-role client를 사용해 wallet command를 호출하지 않는다.

```ts
import 'server-only';

import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { createSupabaseServiceRoleClient } from '@/lib/supabase/service-role.server';
import { requireAdmin } from '@/lib/utils/require-admin';
import {
  decodeStableCommandEnvelope,
  decodeStableErrorEnvelope,
  WalletCommandValidationError,
} from '@/lib/wallet/admin-command-contract';
import type {
  StableCommandEnvelope,
  WalletPermission,
} from '@/lib/types/wallet-admin';

export const WALLET_COMMAND_RPCS = [
  'admin_create_promotion_version',
  'admin_adjust_star_bonus',
  'apply_wallet_correction',
  'admin_request_wallet_operation_retry',
  'admin_ack_wallet_ops_alert',
  'admin_preview_wallet_repair',
  'admin_execute_wallet_repair',
  'admin_waive_wallet_debt',
  'admin_emergency_set_wallet_flags',
] as const;

export type WalletCommandRpc = (typeof WALLET_COMMAND_RPCS)[number];
type CommandBody = { request_id: string };
type RpcResponse = Promise<{
  data: unknown;
  error: { code?: string; message: string } | null;
}>;
type CommandRpc = (name: string, args: Record<string, unknown>) => RpcResponse;

export interface WalletCommandHandlerOptions<TBody extends CommandBody, TResult> {
  rpcName: WalletCommandRpc;
  permission: WalletPermission;
  parseBody(value: unknown): TBody;
  decodeResult(value: unknown): TResult;
}

async function recordCommandFailure(
  rpc: CommandRpc,
  rpcName: WalletCommandRpc,
  requestId: string,
  actorUserId: string,
  failureStage: 'TRANSPORT' | 'RESPONSE_DECODE',
  domainCode: 'ADMIN_COMMAND_TRANSPORT_ERROR' | 'ADMIN_COMMAND_RESPONSE_INVALID',
): Promise<StableCommandEnvelope<never> | null> {
  try {
    const recorded = await rpc('record_wallet_command_failure', {
      p_request: {
        request_id: requestId,
        actor_user_id: actorUserId,
        action_code: rpcName,
        failure_stage: failureStage,
        domain_code: domainCode,
        retryable: true,
      },
    });
    if (recorded.error) return null;
    return decodeStableErrorEnvelope(recorded.data);
  } catch {
    return null;
  }
}

export function createWalletCommandHandler<TBody extends CommandBody, TResult>(
  options: WalletCommandHandlerOptions<TBody, TResult>,
) {
  return async function POST(req: NextRequest): Promise<NextResponse> {
    const denied = await requireAdmin(req);
    if (denied) return denied;

    let body: TBody;
    try {
      body = options.parseBody(await req.json());
    } catch (error) {
      if (error instanceof WalletCommandValidationError) {
        return NextResponse.json(
          { error: error.code, code: 'INVALID_WALLET_COMMAND_BODY' },
          { status: 400 },
        );
      }
      return NextResponse.json(
        { error: 'INVALID_JSON_BODY', code: 'INVALID_WALLET_COMMAND_BODY' },
        { status: 400 },
      );
    }

    const userClient = createSupabaseServerClient();
    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) {
      return NextResponse.json({ error: 'UNAUTHORIZED' }, { status: 401 });
    }
    const actorId = authData.user.id;

    const { data: actor, error: actorError } = await userClient.rpc(
      'admin_get_wallet_actor_context',
    );
    if (
      actorError ||
      !actor ||
      actor.actor_id !== actorId ||
      !actor.permissions.includes(options.permission)
    ) {
      return NextResponse.json({ error: 'WALLET_PERMISSION_DENIED' }, { status: 403 });
    }

    const commandClient = createSupabaseServiceRoleClient();
    const rpc = commandClient.rpc.bind(commandClient) as unknown as CommandRpc;
    let command: Awaited<RpcResponse>;
    try {
      command = await rpc(options.rpcName, {
        p_actor_user_id: actorId,
        p_request: body,
      });
    } catch {
      command = { data: null, error: { code: 'ADMIN_COMMAND_NETWORK_ERROR', message: '' } };
    }

    if (command.error) {
      const stable = await recordCommandFailure(
        rpc,
        options.rpcName,
        body.request_id,
        actorId,
        'TRANSPORT',
        'ADMIN_COMMAND_TRANSPORT_ERROR',
      );
      if (!stable) {
        console.error('[wallet-command] failure recorder unavailable', {
          rpcName: options.rpcName,
          errorCode: command.error.code ?? 'ADMIN_COMMAND_TRANSPORT_ERROR',
        });
        return NextResponse.json(
          { error: 'COMMAND_FAILURE_RECORDING_UNAVAILABLE' },
          { status: 503 },
        );
      }
      return NextResponse.json(stable, { status: 502 });
    }

    try {
      const envelope = decodeStableCommandEnvelope(command.data, options.decodeResult);
      return NextResponse.json(envelope, { status: 200 });
    } catch {
      const stable = await recordCommandFailure(
        rpc,
        options.rpcName,
        body.request_id,
        actorId,
        'RESPONSE_DECODE',
        'ADMIN_COMMAND_RESPONSE_INVALID',
      );
      if (!stable) {
        console.error('[wallet-command] invalid response recorder unavailable', {
          rpcName: options.rpcName,
          errorCode: 'ADMIN_COMMAND_RESPONSE_INVALID',
        });
        return NextResponse.json(
          { error: 'COMMAND_FAILURE_RECORDING_UNAVAILABLE' },
          { status: 503 },
        );
      }
      return NextResponse.json(stable, { status: 502 });
    }
  };
}
```

`decodeStableCommandEnvelope`/`decodeStableErrorEnvelope`는 exact key, `ok` discriminator, UUID/string/nullability를 검증하고 추가 field를 거부한다. `lib/services/walletAdminCommand.client.ts`는 `/api/wallet/**`만 `fetch`하고 위 decoder를 재사용한다. command result의 decimal string을 JSON number로 바꾸지 않고, result-specific decoder가 `AdminAdjustAppliedResult` 금액, repair delta, waiver amount, flag version을 `bigint`로 바꿔 component에 넘긴다.

`__tests__/api/wallet/walletAdminCommand.server.test.ts`는 다음 matrix를 사용한다. test helper `mockAuthenticatedActor`, `makeRequest`는 user-session client의 `auth.getUser`와 `admin_get_wallet_actor_context`만 준비하고, `mockServiceRpc`만 command/failure recorder를 받게 한다.

```ts
const commandCases = [
  ['admin_create_promotion_version', 'promotion.version.create'],
  ['admin_adjust_star_bonus', 'wallet.adjust.star_bonus'],
  ['apply_wallet_correction', 'wallet.correction.apply'],
  ['admin_request_wallet_operation_retry', 'wallet.operation.retry'],
  ['admin_ack_wallet_ops_alert', 'wallet.alert.ack'],
  ['admin_preview_wallet_repair', 'wallet.repair.preview'],
  ['admin_execute_wallet_repair', 'wallet.repair.execute'],
  ['admin_waive_wallet_debt', 'wallet.debt.waive'],
  ['admin_emergency_set_wallet_flags', 'wallet.flags.emergency_disable'],
] as const satisfies ReadonlyArray<readonly [WalletCommandRpc, WalletPermission]>;

it.each(commandCases)(
  '%s는 user-session actor와 service-role command parameter를 분리한다',
  async (rpcName, permission) => {
    const body = { request_id: '435f6d09-c858-416a-916f-b9d0b25a2713' };
    mockAuthenticatedActor({
      actor_id: 'a407b700-bb64-4f30-ad29-999a8bb69eb1',
      actor_role: 'SUPER_ADMIN',
      permissions: [permission],
    });
    mockServiceRpc.mockResolvedValueOnce({
      data: {
        ok: true,
        operation_id: '6f11577b-56a0-4ddf-826f-2381f1bd28de',
        audit_id: '97895549-bfe8-45a9-974a-020b748e8a5d',
        result: { accepted: true },
      },
      error: null,
    });
    const POST = createWalletCommandHandler({
      rpcName,
      permission,
      parseBody: (value) => value as typeof body,
      decodeResult: (value) => value as { accepted: true },
    });

    const response = await POST(makeRequest(body));

    expect(response.status).toBe(200);
    expect(mockUserRpc).toHaveBeenCalledTimes(1);
    expect(mockUserRpc).toHaveBeenCalledWith('admin_get_wallet_actor_context');
    expect(mockServiceRpc).toHaveBeenCalledTimes(1);
    expect(mockServiceRpc).toHaveBeenCalledWith(rpcName, {
      p_actor_user_id: 'a407b700-bb64-4f30-ad29-999a8bb69eb1',
      p_request: body,
    });
    expect(Object.keys(mockServiceRpc.mock.calls[0][1])).toEqual([
      'p_actor_user_id',
      'p_request',
    ]);
  },
);
```

나머지 handler test는 unauthenticated=401, missing permission=403, parser failure=400, success/domain envelope byte-preserving 200을 검증한다. domain failure는 반드시 첫 command의 `data`에서 읽고 failure recorder를 호출하지 않는다. command transport 실패 시 두 번째 service-role 호출은 정확히 `record_wallet_command_failure({p_request:{request_id,actor_user_id,action_code,failure_stage:'TRANSPORT',domain_code:'ADMIN_COMMAND_TRANSPORT_ERROR',retryable:true}})`다. malformed success/error/result decoder 실패도 같은 server-derived `actor_user_id`와 `failure_stage:'RESPONSE_DECODE'`, `domain_code:'ADMIN_COMMAND_RESPONSE_INVALID'`로 recorder를 정확히 한 번 호출하고 stable 502를 반환한다. `actor_user_id`는 외부 body가 아니라 검증된 session에서만 가져오며 원 body, reason, ticket, provider 값은 recorder payload에 없어야 한다. recorder는 actor/command/request를 immutable failure audit에 남긴다. recorder가 error를 반환하거나 throw하거나 malformed envelope를 반환하면 503을 검증한다.

- [ ] **Step 3: route를 구현하고 API test를 통과시킨다**

`app/api/wallet/adjust/route.ts`:

```ts
import { createWalletCommandHandler } from '@/lib/services/walletAdminCommand.server';
import {
  decodeAdminAdjustResult,
  parseAdminAdjustRequest,
} from '@/lib/wallet/admin-command-contract';

export const runtime = 'nodejs';
export const POST = createWalletCommandHandler({
  rpcName: 'admin_adjust_star_bonus',
  permission: 'wallet.adjust.star_bonus',
  parseBody: parseAdminAdjustRequest,
  decodeResult: decodeAdminAdjustResult,
});
```

`app/api/wallet/adjust/approve/route.ts`:

```ts
import { createWalletCommandHandler } from '@/lib/services/walletAdminCommand.server';
import {
  decodeAdminAdjustResult,
  parseAdminAdjustApprovalRequest,
} from '@/lib/wallet/admin-command-contract';

export const runtime = 'nodejs';
export const POST = createWalletCommandHandler({
  rpcName: 'admin_adjust_star_bonus',
  permission: 'wallet.adjust.star_bonus.approve',
  parseBody: parseAdminAdjustApprovalRequest,
  decodeResult: decodeAdminAdjustResult,
});
```

Run: `npm test -- --runInBand __tests__/api/wallet/walletAdminCommand.server.test.ts __tests__/api/wallet/adjust.route.test.ts`

Expected: PASS.

- [ ] **Step 4: adjustment modal의 실패 test를 작성한다**

`__tests__/wallet/AdminAdjustmentModal.test.tsx`는 Operator에게 button이 없고 Finance Admin에게 보이는지, Cotton option과 system reason selector가 없는지, `REQUEST` submit body가 `approval_reference:null`을 포함한 exact contract인지 검증한다. `ADMIN_ADJUST_INSUFFICIENT_FUNDS`를 받으면 잔액을 임의 보정하지 않고 error와 support reference를 표시해야 한다. `APPLIED`는 `gross`, `debt_offset`, `net_wallet_credit`를 각 통화 단위로 보여 주고, `PENDING_APPROVAL`은 wallet cache를 applied로 냙관 변경하지 않은 채 approval reference와 만료 시각을 표시해야 한다.

`AdminAdjustmentApprovalDrawer` test는 Super Admin에게만 pending approval이 보이고, requester와 현재 actor가 같으면 승인 button이 없으며, 서로 다르면 `APPROVE` body가 `request_id`, 저장된 `operation_key`, `approval_reference`, 승인 reason, CS ticket만 포함하는지 검증한다. user/currency/direction/amount는 approval form에서 입력받지 않는다.

Run: `npm test -- --runInBand __tests__/wallet/AdminAdjustmentModal.test.tsx`

Expected: FAIL because modal is not implemented.

- [ ] **Step 5: adjustment modal을 구현한다**

Modal은 direction, Star/Bonus currency, 양의 정수 amount, 자유 입력 reason, CS ticket을 받아 `action:'REQUEST'`, `approval_reference:null`로 보낸다. 처음 submit할 때 `crypto.randomUUID()`로 `request_id`와 `operation_key`를 만들고, transport retry는 같은 body를 재사용한다. 사용자가 입력을 바꾸고 새로 submit하면 새 key를 만든다. `APPLIED`뒤에만 summary/history/timeline/debt cache를 invalidate하고, `PENDING_APPROVAL`은 approval list만 invalidate한다. 두 경우 모두 DB가 반환한 `operation_id`, `audit_id`를 표시한다.

Super Admin의 operation row action은 accessible name `조정 승인 검토`, drawer는 `Star/Bonus 조정 승인`, submit은 `조정 승인`으로 고정한다. Drawer는 `admin_list_wallet_operations` PENDING item에 있는 `approval_reference`, original requester, operation key, currency/direction/amount 요약을 읽기 전용으로 보여 준다. 승인자는 `승인 사유`와 CS ticket만 새로 입력하고 `/api/wallet/adjust/approve`를 호출한다. DB는 approval record의 immutable payload hash, 만료, requester≠approver, role limit을 다시 검증한다.

- [ ] **Step 6: 전체 관련 test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/api/wallet/walletAdminCommand.server.test.ts __tests__/api/wallet/adjust.route.test.ts __tests__/wallet/AdminAdjustmentModal.test.tsx __tests__/wallet/UserWalletPanel.test.tsx && npm run type-check`

Expected: PASS and both commands exit 0.

- [ ] **Step 7: commit한다**

```bash
git add lib/supabase/service-role.server.ts lib/wallet/admin-command-contract.ts lib/services/walletAdminCommand.server.ts lib/services/walletAdminCommand.client.ts app/api/wallet/adjust app/user_profiles/components/wallet/AdminAdjustmentModal.tsx app/user_profiles/components/wallet/UserWalletPanel.tsx app/wallet-ops/components/AdminAdjustmentApprovalDrawer.tsx __tests__/api/wallet/walletAdminCommand.server.test.ts __tests__/api/wallet/adjust.route.test.ts __tests__/wallet/AdminAdjustmentModal.test.tsx
git commit -m "feat(wallet): route admin adjustments through command api"
```

---

### Task 5: append-only 캔디 부스트 campaign 운영 화면을 만든다

**Files:**
- Create: `app/promotion-campaigns/page.tsx`
- Create: `app/promotion-campaigns/show/[id]/page.tsx`
- Create: `app/promotion-campaigns/components/PromotionCampaignList.tsx`
- Create: `app/promotion-campaigns/components/PromotionVersionEditor.tsx`
- Create: `app/promotion-campaigns/components/PromotionVersionHistory.tsx`
- Create: `app/promotion-campaigns/components/PromotionPreview.tsx`
- Create: `app/promotion-campaigns/components/index.ts`
- Create: `app/api/wallet/campaign-versions/route.ts`
- Create: `__tests__/wallet/PromotionCampaigns.test.tsx`
- Create: `__tests__/api/wallet/campaign-versions.route.test.ts`
- Modify: `app/banner/components/BannerForm.tsx`
- Modify: `lib/services/walletAdminService.ts`

- [ ] **Step 1: append-only version form 계약을 실패 test로 고정한다**

Campaign version 요청이 `is_active`, surface, cohort 값을 포함하더라도 이 UI가 production에서 즉시 live 효과를 만들 수 없다. DB command/RPC는 `promotion_surfaces_enabled`와 `candy_boost_write_enabled`를 다시 확인하고, full `GO: cotton-candy-v1` 전에는 active/cohort 설정을 저장하되 평가 결과를 비활성화하거나 stable `WALLET_RELEASE_GATE_BLOCKED`로 거부해야 한다. Preview와 staging에서는 동일한 command를 검증할 수 있지만 production flag 활성화는 별도 audited activation 단계에서만 수행한다. 이 경계를 route/component test에 포함한다.

Command body는 다음 exact shape다.

```ts
export interface CreatePromotionVersionRequest {
  request_id: string;
  campaign_id: string;
  expected_latest_version: string;
  is_active: boolean;
  timezone: 'Asia/Seoul';
  weekly_start_isodow: 1;
  weekly_start_time: '00:00:00';
  weekly_end_isodow: 3;
  weekly_end_time: '00:00:00';
  extra_bonus_bps: string;
  display_name: Record<string, string>;
  show_home_banner: boolean;
  show_in_store: boolean;
  home_banner_id: number | null;
  rollout_policy: {
    minimum_app_version: string;
    minimum_app_build: string;
    cohort_version: string;
    cohort_seed: string;
    cohort_threshold_bps: string;
  };
  change_reason: string;
}

export interface CreatePromotionVersionResult {
  campaign_id: string;
  campaign_version_id: string;
  version: string;
  effective_from: string;
}
```

UI test는 기존 version에 edit/delete action이 없고 `새 버전 만들기`만 있는지 검증한다. `admin_list_promotion_campaign_versions` 첫 page와 `next_cursor`를 사용한 다음 page가 version 순서를 그대로 보존하는지도 검증한다. 활성화, 비활성화, surface 변경도 새 version command여야 한다. form에 `effective_from`, `banner.start_at`, `banner.end_at` 입력은 없어야 한다. `show_home_banner=true`일 때 `vote_home` banner가 필수이고 `home_banner_id`는 JSON integer여야 한다. numeric string은 parser가 거부한다.

Run: `npm test -- --runInBand __tests__/wallet/PromotionCampaigns.test.tsx __tests__/api/wallet/campaign-versions.route.test.ts`

Expected: FAIL because campaign page and API route do not exist.

- [ ] **Step 2: list, version history, point-in-time preview를 구현한다**

List는 `admin_list_promotion_campaigns`의 `statuses`, `campaign_id` filter와 opaque cursor를 사용한다. surface는 승인 allowlist filter key가 아니므로 client filter로 보내지 않고 행에만 표시한다. 상세의 append-only history는 raw campaign table이 아닌 `admin_list_promotion_campaign_versions(p_campaign_id,p_cursor,p_limit)`를 사용하고 version, effective_from, active, weekly KST window, extra bonus bps, display name, surfaces, rollout policy, creator, change reason, audit ID를 읽기 전용으로 표시한다.

Preview는 사용자가 고른 ISO timestamp를 `admin_preview_promotion_campaign(p_campaign_id, p_at)`에 전달하고 `effective version 없음`, `inactive로 적용 없음`, `active`를 구분한다. preview 결과의 server evaluated window와 surface만 표시하고 client가 일정을 재계산하지 않는다.

- [ ] **Step 3: campaign command route와 editor를 구현한다**

Route는 Task 4 handler를 다음과 같이 사용한다.

```ts
export const POST = createWalletCommandHandler({
  rpcName: 'admin_create_promotion_version',
  permission: 'promotion.version.create',
  parseBody: parseCreatePromotionVersionRequest,
  decodeResult: decodeCreatePromotionVersionResult,
});
```

Editor는 actor ID와 `effective_from`을 전송하지 않는다. `extra_bonus_bps`와 cohort threshold는 decimal string으로 보낸다. response의 new version, campaign version ID, operation ID, audit ID를 표시하고 list/detail을 refresh한다. optimistic version conflict는 새 데이터를 refetch한 뒤 사용자 입력을 자동 재전송하지 않는다.

`CreatePromotionVersionResult.version`도 browser command client에서 `bigint`로 decode하고 렌더링 직전에 string으로 format한다.

- [ ] **Step 4: 기존 banner form에 authority 경고를 추가한다**

`location='vote_home'` banner는 image/locale/CTA/deeplink creative만 관리한다. form 상단에 `캔디 부스트 노출 일정은 프로모션 버전이 결정합니다. 이 배너의 시작·종료 시각은 캔디 부스트 판정에 사용되지 않습니다.`를 표시하고 campaign editor에서 선택 가능한 banner를 `vote_home`으로 제한한다.

- [ ] **Step 5: test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet/PromotionCampaigns.test.tsx __tests__/api/wallet/campaign-versions.route.test.ts && npm run type-check`

Expected: PASS. Backdate/future/effective time 필드는 DOM에 없고 old version mutation action도 없다.

- [ ] **Step 6: commit한다**

```bash
git add app/promotion-campaigns app/api/wallet/campaign-versions/route.ts app/banner/components/BannerForm.tsx lib/services/walletAdminService.ts lib/wallet/admin-command-contract.ts __tests__/wallet/PromotionCampaigns.test.tsx __tests__/api/wallet/campaign-versions.route.test.ts
git commit -m "feat(promotion): add append-only campaign operations"
```

---

### Task 6: Wallet Ops read dashboard를 만든다

**Files:**
- Create: `app/wallet-ops/page.tsx`
- Create: `app/wallet-ops/components/WalletOpsDashboard.tsx`
- Create: `app/wallet-ops/components/WalletOpsSummaryCards.tsx`
- Create: `app/wallet-ops/components/WalletOperationInbox.tsx`
- Create: `app/wallet-ops/components/WalletOpsAlerts.tsx`
- Create: `app/wallet-ops/components/WalletInvariantViolations.tsx`
- Create: `app/wallet-ops/components/WorkerHealthPanel.tsx`
- Create: `app/wallet-ops/components/WalletRuntimeFlagsPanel.tsx`
- Create: `app/wallet-ops/components/WalletAuditEvents.tsx`
- Create: `app/wallet-ops/components/index.ts`
- Create: `__tests__/wallet/WalletOpsDashboard.test.tsx`
- Modify: `lib/services/walletAdminService.ts`

- [ ] **Step 1: hash navigation, empty count, same timestamp cursor를 실패 test로 작성한다**

Dashboard hash key는 `#overview`, `#operations`, `#alerts`, `#invariants`, `#workers`, `#flags`, `#audit`로 고정한다. test는 initial hash가 tab을 선택하고 tab click이 `history.replaceState`로 hash를 바꾸는지 검증한다. empty fixture는 `0건`을 보여야 한다. 같은 `created_at`을 가진 두 operation/audit event가 fixture 순서를 유지하고 next page 요청이 opaque `next_cursor`만 재사용하는지 검증한다.

Run: `npm test -- --runInBand __tests__/wallet/WalletOpsDashboard.test.tsx`

Expected: FAIL because dashboard does not exist.

- [ ] **Step 2: overview와 worker health를 구현한다**

`admin_get_wallet_ops_summary({ p_at: null })` 결과로 inbox pending/dead/oldest age, expiry/reconciliation heartbeat, 통화별 `debt_oldest_open_seconds`와 recovery rate, campaign conflict, audit completeness를 각각 card로 표시한다. 값의 server status가 critical이면 card를 붉게 표시하지만 client threshold를 새로 계산하지 않는다.

`admin_get_worker_health()`는 worker name, last heartbeat, last success, lag, status, support reference를 표시한다. provider token, receipt, payload hash는 DTO와 DOM에 없어야 한다.

`admin_get_wallet_runtime_flags()`는 composite `flag_version`, exact dotted flag key/value, changed at/by, snapshot time을 반환한다. `WalletRuntimeFlagsPanel`은 이 read 결과만 보여 주고 Task 7 emergency drawer에 `flag_version`을 그대로 전달한다. client가 개별 flag version을 합성하지 않는다. Contract test는 `ads.pangle_claim_mode`의 `shadow`, `optional`, `required`를 각각 decode하고 `off`, `enforce`를 거부한다.

- [ ] **Step 3: operations, alerts, invariants cursor 목록을 구현한다**

Operations filters는 `from`, `to`, `statuses`, `event_types`, `provider`; Alerts는 `from`, `to`, `statuses`, `severity`; Invariants는 `from`, `to`, `statuses`만 사용한다. 단수 `status`, `operation_type`, `retryable`, `resource_type`은 RPC에 보내지 않는다. 세 목록은 total count, snapshot time, next cursor를 표시하고 offset state를 만들지 않는다.

Operation row는 status, retryability, attempt, retry time, last error code, support reference, row version을 표시한다. Alert row는 fingerprint 대신 사용자용 summary, severity, status, occurrence count, affected resource, first/last seen을 표시한다. Invariant row는 공개 가능한 expected/actual summary와 operation/support reference만 표시한다.

`WalletAuditEvents`는 `admin_list_wallet_audit_events` safe RPC의 immutable event만 사용한다. filter는 `from`, `to`, `event_types`, `campaign_id`만 허용하고 actor/role, action, resource, operation/request ID, reason/ticket, safe before/after JSON, campaign version, created time을 읽기 전용으로 표시한다. edit/delete action은 없다.

- [ ] **Step 4: masking test를 추가한다**

Operation/audit fixture의 top-level과 `before_json`/`after_json`에 `provider_payload`, `receipt`, `access_token`, `signature` 키를 주입해도 component가 해당 값을 DOM에 렌더링하지 않는 test를 작성한다. production DTO decoder도 allowlist field만 반환하고 safe audit RPC가 masking한 JSON만 렌더링한다.

- [ ] **Step 5: test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet/WalletOpsDashboard.test.tsx && npm run type-check`

Expected: PASS. hash, empty count, same-time cursor, masking assertions가 모두 통과한다.

- [ ] **Step 6: commit한다**

```bash
git add app/wallet-ops lib/services/walletAdminService.ts __tests__/wallet/WalletOpsDashboard.test.tsx
git commit -m "feat(wallet-ops): add operations dashboard"
```

---

### Task 7: retry, ACK, repair, correction, waiver, emergency command를 연결한다

**Files:**
- Create: `app/api/wallet/operations/retry/route.ts`
- Create: `app/api/wallet/alerts/ack/route.ts`
- Create: `app/api/wallet/repairs/preview/route.ts`
- Create: `app/api/wallet/repairs/execute/route.ts`
- Create: `app/api/wallet/corrections/route.ts`
- Create: `app/api/wallet/debts/waive/route.ts`
- Create: `app/api/wallet/flags/emergency/route.ts`
- Create: `app/wallet-ops/components/WalletRepairDrawer.tsx`
- Create: `app/wallet-ops/components/DebtWaiverDrawer.tsx`
- Create: `app/wallet-ops/components/EmergencyFlagsDrawer.tsx`
- Create: `__tests__/api/wallet/operations.route.test.ts`
- Create: `__tests__/wallet/WalletRecoveryCommands.test.tsx`
- Modify: `app/wallet-ops/components/WalletOperationInbox.tsx`
- Modify: `app/wallet-ops/components/WalletOpsAlerts.tsx`
- Modify: `app/wallet-ops/components/WalletOpsDashboard.tsx`
- Modify: `lib/wallet/admin-command-contract.ts`

- [ ] **Step 1: 모든 command body를 exact-key parser test로 고정한다**

```ts
export interface RetryWalletOperationRequest {
  request_id: string;
  operation_id: string;
  expected_version: string;
  reason: string;
  cs_ticket: string;
}

export interface AckWalletAlertRequest {
  request_id: string;
  alert_id: string;
  expected_version: string;
  reason: string;
}

export type WalletRepairKind = 'CORRECTION' | 'REBUILD_PROJECTION';

export interface PreviewWalletRepairRequest {
  request_id: string;
  kind: WalletRepairKind;
  target_resource_type: 'WALLET_OPERATION' | 'USER_WALLET_PROJECTION';
  target_resource_id: string;
  expected_version: string;
  reason: string;
  cs_ticket: string;
  correction: {
    currency: 'STAR_CANDY' | 'BONUS_STAR_CANDY';
    amount: string;
  } | null;
}

export interface ExecuteWalletRepairRequest {
  request_id: string;
  repair_operation_id: string;
  dry_run_hash: string;
  expected_version: string;
  reason: string;
  cs_ticket: string;
}

export interface WaiveWalletDebtRequest {
  request_id: string;
  operation_key: string;
  debt_id: string;
  amount: string;
  expected_version: string;
  reason: string;
  cs_ticket: string;
}

export interface EmergencyWalletFlagsRequest {
  request_id: string;
  expected_version: string;
  reason: string;
  cs_ticket: string;
  safe_changes: {
    'wallet.cotton_spend_enabled'?: false;
    'ads.internal_reward_mode'?: 'paused';
    'ads.pangle_reward_mode'?: 'paused';
    candy_boost_write_enabled?: false;
    refund_reversal_enabled?: false;
    promotion_surfaces_enabled?: false;
    admin_financial_commands_enabled?: false;
  };
}

export interface RetryWalletOperationResult {
  enqueued: true;
  inbox_operation_id: string;
  idempotency_key: string;
  status: 'PENDING';
}

export interface AckWalletAlertResult {
  alert_id: string;
  status: 'ACKNOWLEDGED';
  acknowledged_at: string;
}

export interface RepairPreviewResult {
  repair_operation_id: string;
  repair_kind: WalletRepairKind;
  requester_id: string;
  dry_run_hash: string;
  expected_version: string;
  source_summary: Record<string, string | boolean | null>;
  snapshot_summary: Record<string, string | boolean | null>;
  ledger_rows: Array<Record<string, string | boolean | null>>;
  debt_rows: Array<Record<string, string | boolean | null>>;
  before_rows: Array<Record<string, string | boolean | null>>;
  after_rows: Array<Record<string, string | boolean | null>>;
  wallet_delta: Partial<Record<WalletCurrency, string>>;
  debt_delta: Partial<
    Record<Exclude<WalletCurrency, 'COTTON_CANDY'>, string>
  >;
}

export interface ExecuteWalletRepairResult {
  repair_operation_id: string;
  result_reference: string;
  invariant_status: 'OK';
}

export interface WaiveWalletDebtResult {
  debt_id: string;
  waived_amount: string;
  outstanding_amount: string;
}

export interface EmergencyWalletFlagsResult {
  flag_version: string;
  applied_safe_changes: EmergencyWalletFlagsRequest['safe_changes'];
}

export interface WalletCommandContractMap {
  admin_create_promotion_version: {
    request: CreatePromotionVersionRequest;
    result: CreatePromotionVersionResult;
  };
  admin_adjust_star_bonus: {
    request: AdminAdjustCommandRequest;
    result: AdminAdjustResult;
  };
  apply_wallet_correction: {
    request: ExecuteWalletRepairRequest;
    result: ExecuteWalletRepairResult;
  };
  admin_request_wallet_operation_retry: {
    request: RetryWalletOperationRequest;
    result: RetryWalletOperationResult;
  };
  admin_ack_wallet_ops_alert: {
    request: AckWalletAlertRequest;
    result: AckWalletAlertResult;
  };
  admin_preview_wallet_repair: {
    request: PreviewWalletRepairRequest;
    result: RepairPreviewResult;
  };
  admin_execute_wallet_repair: {
    request: ExecuteWalletRepairRequest;
    result: ExecuteWalletRepairResult;
  };
  admin_waive_wallet_debt: {
    request: WaiveWalletDebtRequest;
    result: WaiveWalletDebtResult;
  };
  admin_emergency_set_wallet_flags: {
    request: EmergencyWalletFlagsRequest;
    result: EmergencyWalletFlagsResult;
  };
}
```

Correction 승인 실행은 `ExecuteWalletRepairRequest`와 같은 body를 `apply_wallet_correction`에 보낸다. preview가 만든 repair operation의 requester와 현재 actor가 같으면 RPC가 `CORRECTION_TWO_PERSON_REQUIRED`로 거부한다. projection rebuild는 같은 body를 `admin_execute_wallet_repair`에 보낸다. 어떤 body에도 target balance, actor ID, approver ID, raw row patch를 허용하지 않는다.

위 map의 각 result는 반드시 `StableCommandEnvelope<WalletCommandContractMap[K]['result']>`로만 전달된다. browser command client는 `wallet_delta`, `debt_delta`, waiver amount, flag version을 DTO 경계에서 `bigint`로 decode하며 component는 wire decimal string을 직접 산술하지 않는다. `RetryWalletOperationRequest`는 위의 다섯 key만 허용하고 `inbox_id`, actor/approver, idempotency key 재입력을 거부한다. DB가 `operation_id`로 원 inbox/idempotency key를 찾아 실행 가능 시각만 앞당긴다.

Supabase handoff contract는 retry 성공 `result`를 정확히 `{enqueued:true,inbox_operation_id,idempotency_key,status:'PENDING'}`로 반환한다. 같은 actor/action/request ID와 byte-identical body를 다시 보내면 inbox `row_version`이 이미 증가했어도 immutable command execution에서 첫 성공 envelope를 byte-for-byte 재생하며 audit/queue row를 추가하지 않는다. 같은 request ID의 다른 body는 `ADMIN_REQUEST_CONFLICT`다. stale version, non-retryable, `DEAD`, unknown operation은 exception을 raise하지 않고 각각 stable failure를 command `data`로 반환한다. Admin route test는 성공, 동일 replay, conflict와 네 domain failure에서 HTTP 200/stable envelope/failure-recorder 미호출을 함께 검증한다.

Run: `npm test -- --runInBand __tests__/api/wallet/operations.route.test.ts`

Expected: FAIL because routes and parsers are incomplete.

- [ ] **Step 2: fixed RPC 이름과 permission으로 route를 구현한다**

| Route | RPC | Permission | Parser / result decoder |
|---|---|---|---|
| `/api/wallet/operations/retry` | `admin_request_wallet_operation_retry` | `wallet.operation.retry` | `parseRetryWalletOperationRequest` / `decodeRetryWalletOperationResult` |
| `/api/wallet/alerts/ack` | `admin_ack_wallet_ops_alert` | `wallet.alert.ack` | `parseAckWalletAlertRequest` / `decodeAckWalletAlertResult` |
| `/api/wallet/repairs/preview` | `admin_preview_wallet_repair` | `wallet.repair.preview` | `parsePreviewWalletRepairRequest` / `decodeRepairPreviewResult` |
| `/api/wallet/repairs/execute` | `admin_execute_wallet_repair` | `wallet.repair.execute` | `parseExecuteWalletRepairRequest` / `decodeExecuteWalletRepairResult` |
| `/api/wallet/corrections` | `apply_wallet_correction` | `wallet.correction.apply` | `parseExecuteWalletRepairRequest` / `decodeExecuteWalletRepairResult` |
| `/api/wallet/debts/waive` | `admin_waive_wallet_debt` | `wallet.debt.waive` | `parseWaiveWalletDebtRequest` / `decodeWaiveWalletDebtResult` |
| `/api/wallet/flags/emergency` | `admin_emergency_set_wallet_flags` | `wallet.flags.emergency_disable` | `parseEmergencyWalletFlagsRequest` / `decodeEmergencyWalletFlagsResult` |

Retry route는 exact `operation_id`, `expected_version`, `reason`, `cs_ticket`을 보내고 command success의 `enqueued=true`, 원 `idempotency_key`, `status='PENDING'`을 검증하지만 worker settlement 결과를 기다리지 않는다. stale version, `retryable=false`, `DEAD`는 DB stable error를 그대로 표시한다. ACK route는 ACKNOWLEDGED만 만들고 RESOLVED 입력을 받지 않는다. Emergency parser는 dotted exact flag key 중 safe false/paused 값만 허용하고 `true`, Cotton expiry disable, debt recovery disable을 exact-key/type validation에서 거부한다.

- [ ] **Step 3: dry-run preview UI를 실패 test로 작성한다**

`WalletRecoveryCommands.test.tsx`는 다음을 검증한다.

- Operator는 retry, ACK, dry-run preview만 볼 수 있다.
- Finance Admin은 debt waiver와 Star/Bonus adjust를 추가로 볼 수 있다.
- Super Admin만 한도 초과 Star/Bonus adjustment approve, correction approve, projection rebuild execute, emergency disable을 볼 수 있다.
- repair preview에는 source/snapshot/ledger/debt timeline, before/after rows, wallet delta, debt delta, dry-run hash가 표시된다.
- preview 이후 target version이 바뀌면 execute button이 비활성화되고 새 preview가 필요하다.
- correction requester와 같은 actor에게 approve button이 보이지 않는다.
- target balance와 raw ledger editor가 없다.

Run: `npm test -- --runInBand __tests__/wallet/WalletRecoveryCommands.test.tsx`

Expected: FAIL because recovery components do not exist.

- [ ] **Step 4: retry와 alert ACK UI를 구현한다**

Retry button은 `retryable=true`, non-DEAD operation에서만 보이고 click 후 reason과 ticket을 요구한다. success 후 `요청이 큐에 등록되었습니다`와 operation/support reference를 표시하며 status를 SUCCEEDED로 낙관 변경하지 않는다.

ACK는 OPEN alert와 `wallet.alert.ack` permission에서만 보인다. ACK success 후 audit ID를 표시한다. resolve action은 만들지 않는다.

- [ ] **Step 5: repair/correction/waiver UI를 구현한다**

`WalletRepairDrawer`는 correction 또는 projection rebuild target을 고르고 preview API를 호출한다. Correction만 Star/Bonus currency와 amount를 받는다. Projection rebuild는 amount와 target balance를 받지 않는다. Preview response의 immutable `repair_operation_id`, `dry_run_hash`, `expected_version`을 execute body에 그대로 사용한다.

Correction preview requester는 실행할 수 없고 다른 Super Admin만 `/api/wallet/corrections`로 승인한다. Projection rebuild는 `/api/wallet/repairs/execute`를 사용한다. Debt waiver는 `UserDebtList`에서 선택한 safe DTO의 `debt_id`, `outstanding_amount`, `row_version`을 받아 Finance Admin 이상이 outstanding 이하 양의 정수 amount, reason, ticket, operation key로 실행한다. aggregate summary에서 debt ID/version을 추론하지 않는다. 성공 결과의 wallet/debt/audit references를 표시한다.

- [ ] **Step 6: emergency safe-disable UI를 구현한다**

Drawer는 `admin_get_wallet_runtime_flags()`가 반환한 현재 `flag_version`과 서버 상태를 보여 주고 그 version을 `expected_version`으로 그대로 보낸다. checked command는 dotted exact key의 안전 값으로만 보낸다. `wallet.cotton_expiry_enabled`와 `debt_recovery_enabled`는 목록 자체에 없다. 기본 구매를 멈추는 option도 없다. submit 전 reason, CS ticket, 변경 flag 목록을 확인하는 2단계 confirmation을 요구한다.

- [ ] **Step 7: route/component test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/api/wallet/operations.route.test.ts __tests__/wallet/WalletRecoveryCommands.test.tsx && npm run type-check`

Expected: PASS. retry enqueue-only, stale/non-retryable/DEAD rejection, 2인 correction, safe-disable assertions가 통과한다.

- [ ] **Step 8: commit한다**

```bash
git add app/api/wallet/operations app/api/wallet/alerts app/api/wallet/repairs app/api/wallet/corrections app/api/wallet/debts app/api/wallet/flags app/wallet-ops/components lib/wallet/admin-command-contract.ts __tests__/api/wallet/operations.route.test.ts __tests__/wallet/WalletRecoveryCommands.test.tsx
git commit -m "feat(wallet-ops): add audited recovery commands"
```

---

### Task 8: navigation을 연결하고 legacy 직접 mutation을 폐쇄한다

**Files:**
- Modify: `components/layout/CustomSider.tsx`
- Modify: `components/layout/DynamicRefineResources.tsx`
- Modify: `components/auth/AuthorizePage.tsx`
- Modify: `app/monitoring/bonus/page.tsx`
- Delete: `app/monitoring/bonus/components/BonusMonitoringView.tsx`
- Modify: `app/user_profiles/components/UserProfileDetail.tsx`
- Modify: `app/user_profiles/components/UserProfileForm.tsx`
- Modify: `app/user_profiles/components/UserProfileList.tsx`
- Create: `__tests__/wallet/wallet-navigation.test.tsx`
- Create: `__tests__/wallet/no-direct-wallet-mutation.test.ts`

- [ ] **Step 1: navigation과 legacy denylist를 실패 test로 작성한다**

Navigation test는 `wallet.read` 없는 actor에게 menu가 없고 Operator에게 `Wallet Ops`와 읽기 전용 `프로모션 운영`이 보이는지 검증한다. Super Admin에게만 `새 버전 만들기` action이 보인다. URL은 각각 `/wallet-ops#overview`, `/promotion-campaigns`다.

`no-direct-wallet-mutation.test.ts`는 source file text를 읽어 아래 문자열이 production 대상에 남으면 실패한다.

```ts
const forbidden = [
  /\.from\(['"]star_candy_history['"]\)[\s\S]{0,200}\.insert\(/,
  /\.from\(['"]star_candy_bonus_history['"]\)[\s\S]{0,200}\.insert\(/,
  /\.from\(['"]user_profiles['"]\)[\s\S]{0,200}\.update\(\{\s*(star_candy|star_candy_bonus|cotton_candy)\b/,
  /\.rpc\(['"]repair_bonus_balance['"]/,
  /\.rpc\(['"]repair_bonus_balance_bulk['"]/,
  /\.rpc\(['"]list_bonus_drift['"]/,
  /CANDY_HISTORY_TYPES/,
];

const browserForbiddenCommandNames = [
  'admin_create_promotion_version',
  'admin_adjust_star_bonus',
  'apply_wallet_correction',
  'admin_request_wallet_operation_retry',
  'admin_ack_wallet_ops_alert',
  'admin_preview_wallet_repair',
  'admin_execute_wallet_repair',
  'admin_waive_wallet_debt',
  'admin_emergency_set_wallet_flags',
] as const;
```

기존 writer 검사 대상은 `UserProfileDetail.tsx`, `UserProfileForm.tsx`, `UserProfileList.tsx`, `app/monitoring/bonus`다. 별도로 `app`, `components`, browser-safe `lib`의 production module을 순회해 `supabaseBrowserClient.rpc(<browserForbiddenCommandNames>)` 호출이 하나라도 있으면 실패한다. `types/supabase.ts`, server-only file, Route Handler, test fixture는 browser call scan에서 제외한다. Supabase privilege test의 `authenticated` 9개 EXECUTE 거부가 본 보안 gate이고 이 source scan은 보조 gate다.

Run: `npm test -- --runInBand __tests__/wallet/wallet-navigation.test.tsx __tests__/wallet/no-direct-wallet-mutation.test.ts`

Expected: FAIL because legacy direct paths and navigation remain.

- [ ] **Step 2: permission-aware menu와 route guard를 연결한다**

`CustomSider`와 `DynamicRefineResources`는 actor context의 permission으로 Wallet Ops와 campaign resource를 구성한다. `AuthorizePage`의 기존 adminOnly boolean에 wallet permission을 억지로 합치지 않고 각 page root에서 `RequireWalletPermission`을 사용한다. `/wallet-ops`는 `wallet.read`, `/promotion-campaigns`는 `wallet.read`가 최소 접근 권한이고 create action만 `promotion.version.create`로 guard한다.

- [ ] **Step 3: legacy Bonus monitoring을 Wallet Ops로 redirect한다**

`app/monitoring/bonus/page.tsx`는 Next `redirect('/wallet-ops#invariants')`만 수행한다. `BonusMonitoringView.tsx`를 삭제해 `list_bonus_drift`, `repair_bonus_balance`, `repair_bonus_balance_bulk`의 browser 호출을 제거한다.

- [ ] **Step 4: user profile direct mutation 잔재를 제거한다**

기존 history insert 뒤 profile update의 2단계 handler, legacy modal, 시스템 사유 option, raw balance creation input을 모두 삭제한다. `UserProfileForm` create/edit는 Task 3의 exact identity allowlist payload만 전송하며 balance가 initial value나 임의 form field로 주입되어도 전달하지 않는다. 새 adjustment modal과 wallet service 외에는 재화 변경 경로가 없어야 한다.

Run:

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
if rg -n "repair_bonus_balance|repair_bonus_balance_bulk|list_bonus_drift|CANDY_HISTORY_TYPES" app lib components; then exit 1; fi
if rg -U -n "(?s)from\(['\"]star_candy(_bonus)?_history['\"]\).{0,200}\.insert\(|from\(['\"]user_profiles['\"]\).{0,200}\.update\(\{\s*(star_candy|star_candy_bonus|cotton_candy)\b" app/user_profiles; then exit 1; fi
```

Expected: both checks exit 0 with no matches.

- [ ] **Step 5: regression test와 type-check를 통과시킨다**

Run: `npm test -- --runInBand __tests__/wallet __tests__/wallet/UserProfileWalletWriteGuard.test.tsx && npm run type-check`

Expected: PASS. 직접 mutation denylist, create/edit identity-only payload, role menu, existing profile tests가 통과한다.

- [ ] **Step 6: commit한다**

```bash
git add components/layout/CustomSider.tsx components/layout/DynamicRefineResources.tsx components/auth/AuthorizePage.tsx app/monitoring/bonus/page.tsx app/user_profiles/components/UserProfileDetail.tsx app/user_profiles/components/UserProfileForm.tsx app/user_profiles/components/UserProfileList.tsx __tests__/wallet/wallet-navigation.test.tsx __tests__/wallet/no-direct-wallet-mutation.test.ts
git add -u -- app/monitoring/bonus/components/BonusMonitoringView.tsx
git commit -m "refactor(wallet): remove legacy direct mutation surfaces"
```

---

### Task 9: Playwright acceptance와 전체 release gate를 통과시킨다

**Files:**
- Create: `playwright.config.ts`
- Create: `e2e/wallet-admin.spec.ts`
- Modify: `.gitignore`
- Modify: `package.json`
- Modify: `package-lock.json`

- [ ] **Step 1: Playwright를 설치하고 auth state를 commit 대상에서 제외한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
npm install --save-dev @playwright/test
npx playwright install chromium
```

`package.json`에 다음을 추가한다.

```json
{
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui",
  "test:e2e:auth": "playwright codegen --save-storage=playwright/.auth/admin.json http://127.0.0.1:3200/login"
}
```

`.gitignore`에 `playwright/.auth/`와 `test-results/`를 추가한다.

Expected: package lock이 갱신되고 auth cookie/token 파일은 untracked 상태에서도 git 대상이 아니다.

- [ ] **Step 2: local server와 저장된 관리자 session을 사용하는 config를 만든다**

`playwright.config.ts`:

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://127.0.0.1:3200',
    storageState: 'playwright/.auth/admin.json',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run dev',
    url: 'http://127.0.0.1:3200',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: devices['Desktop Chrome'],
    },
  ],
});
```

Run: `npx playwright test --list`

Expected: config와 spec이 parse되고 Chromium project의 9개 test가 나열된다.

- [ ] **Step 3: 승인된 acceptance 흐름을 Playwright test로 작성한다**

`e2e/wallet-admin.spec.ts`는 아래 코드로 작성한다. mock은 알 수 없는 RPC/API를 500/404로 실패시켜 누락된 계약 호출이 테스트를 조용히 통과하지 못하게 한다.

```ts
import { expect, test, type Page, type Route } from '@playwright/test';

type ActorRole = 'OPERATOR' | 'FINANCE_ADMIN' | 'SUPER_ADMIN';

const USER_ID = '9bce60fd-16c0-43c5-90d7-28bca0b2ac70';
const CAMPAIGN_ID = '10119a59-32d9-475d-a0e8-a8e5af5a287d';
const SNAPSHOT_AT = '2026-07-21T00:00:00Z';

const FIXTURE_IDS = {
  actorOperator: '00000000-0000-4000-8000-000000000001',
  actorFinanceAdmin: '00000000-0000-4000-8000-000000000002',
  actorSuperAdmin: '00000000-0000-4000-8000-000000000003',
  actorOtherSuperAdmin: '00000000-0000-4000-8000-000000000004',
  campaignVersion7: '00000000-0000-4000-8000-000000000010',
  campaignVersion8: '00000000-0000-4000-8000-000000000011',
  auditCampaign8: '00000000-0000-4000-8000-000000000012',
  operationPurchase: '00000000-0000-4000-8000-000000000020',
  operationBoost: '00000000-0000-4000-8000-000000000021',
  operationRefund: '00000000-0000-4000-8000-000000000022',
  operationDebt: '00000000-0000-4000-8000-000000000023',
  operationRecovery: '00000000-0000-4000-8000-000000000024',
  auditRecovery: '00000000-0000-4000-8000-000000000025',
  debt: '00000000-0000-4000-8000-000000000030',
  refundAllocation: '00000000-0000-4000-8000-000000000031',
  alert: '00000000-0000-4000-8000-000000000032',
  operationB: '00000000-0000-4000-8000-000000000060',
  operationA: '00000000-0000-4000-8000-000000000061',
  operationOlder: '00000000-0000-4000-8000-000000000062',
  operationRetry: '00000000-0000-4000-8000-000000000063',
  operationMasked: '00000000-0000-4000-8000-000000000064',
  retryCommandOperation: '00000000-0000-4000-8000-000000000065',
  auditRetry: '00000000-0000-4000-8000-000000000066',
  repairPreviewCommandOperation: '00000000-0000-4000-8000-000000000067',
  auditRepairPreview: '00000000-0000-4000-8000-000000000068',
  repairOperation: '00000000-0000-4000-8000-000000000069',
  ledger: '00000000-0000-4000-8000-000000000070',
  correctionCommandOperation: '00000000-0000-4000-8000-000000000071',
  auditCorrection: '00000000-0000-4000-8000-000000000072',
  adjustCommandOperation: '00000000-0000-4000-8000-000000000073',
  auditAdjust: '00000000-0000-4000-8000-000000000074',
  waiveCommandOperation: '00000000-0000-4000-8000-000000000075',
  auditWaive: '00000000-0000-4000-8000-000000000076',
  adjustPendingCommandOperation: '00000000-0000-4000-8000-000000000077',
  auditAdjustPending: '00000000-0000-4000-8000-000000000078',
  adjustApproveCommandOperation: '00000000-0000-4000-8000-000000000079',
  auditAdjustApprove: '00000000-0000-4000-8000-000000000080',
} as const;

const ADJUST_APPROVAL_REFERENCE = 'wallet-adjust-approval-20260721-001';

const actorIdByRole: Record<ActorRole, string> = {
  OPERATOR: FIXTURE_IDS.actorOperator,
  FINANCE_ADMIN: FIXTURE_IDS.actorFinanceAdmin,
  SUPER_ADMIN: FIXTURE_IDS.actorSuperAdmin,
};

const permissionsByRole = {
  OPERATOR: [
    'wallet.read',
    'wallet.alert.ack',
    'wallet.operation.retry',
    'wallet.repair.preview',
  ],
  FINANCE_ADMIN: [
    'wallet.read',
    'wallet.alert.ack',
    'wallet.operation.retry',
    'wallet.repair.preview',
    'wallet.adjust.star_bonus',
    'wallet.debt.waive',
  ],
  SUPER_ADMIN: [
    'wallet.read',
    'wallet.alert.ack',
    'wallet.operation.retry',
    'wallet.repair.preview',
    'wallet.adjust.star_bonus',
    'wallet.adjust.star_bonus.approve',
    'wallet.debt.waive',
    'promotion.version.create',
    'wallet.correction.apply',
    'wallet.repair.execute',
    'wallet.flags.emergency_disable',
  ],
} as const;

const emptyPage = {
  items: [],
  total_count: '0',
  next_cursor: null,
  snapshot_at: SNAPSHOT_AT,
};

const csSummary = {
  user_id: USER_ID,
  balances: {
    STAR_CANDY: '90071992547409930001',
    BONUS_STAR_CANDY: '3500',
    COTTON_CANDY: '200',
  },
  open_debt: {
    STAR_CANDY: '400',
    BONUS_STAR_CANDY: '50',
  },
  cotton_expiring_amount: '100',
  cotton_next_expires_at: '2026-07-22T15:00:00Z',
  invariant_status: 'OK',
  authoritative_totals: {
    STAR_CANDY: '90071992547409930001',
    BONUS_STAR_CANDY: '3500',
    COTTON_CANDY: '200',
  },
  recent_operation: null,
  snapshot_at: SNAPSHOT_AT,
};

const timelinePage = {
  total_count: '5',
  next_cursor: null,
  snapshot_at: SNAPSHOT_AT,
  items: [
    {
      id: 'timeline-purchase',
      kind: 'PURCHASE',
      allocations: [
        {
          component: 'BASE_STAR',
          currency: 'STAR_CANDY',
          gross_delta: '1000',
          wallet_delta: '1000',
          debt_delta: '0',
        },
        {
          component: 'BASE_BONUS',
          currency: 'BONUS_STAR_CANDY',
          gross_delta: '100',
          wallet_delta: '100',
          debt_delta: '0',
        },
      ],
      provider_occurred_at: '2026-07-21T01:00:00Z',
      campaign_version_id: null,
      audit_id: null,
      operation_id: FIXTURE_IDS.operationPurchase,
      created_at: '2026-07-21T01:00:01Z',
    },
    {
      id: 'timeline-boost',
      kind: 'PROMOTION_AWARD',
      allocations: [
        {
          component: 'PROMO_BONUS',
          currency: 'BONUS_STAR_CANDY',
          gross_delta: '1100',
          wallet_delta: '1100',
          debt_delta: '0',
        },
      ],
      provider_occurred_at: '2026-07-21T01:00:00Z',
      campaign_version_id: FIXTURE_IDS.campaignVersion7,
      audit_id: null,
      operation_id: FIXTURE_IDS.operationBoost,
      created_at: '2026-07-21T01:00:02Z',
    },
    {
      id: 'timeline-refund',
      kind: 'PURCHASE_REFUND',
      allocations: [
        {
          component: 'PROMO_BONUS',
          currency: 'BONUS_STAR_CANDY',
          gross_delta: '-1100',
          wallet_delta: '-700',
          debt_delta: '400',
        },
      ],
      provider_occurred_at: '2026-07-21T02:00:00Z',
      campaign_version_id: FIXTURE_IDS.campaignVersion7,
      audit_id: null,
      operation_id: FIXTURE_IDS.operationRefund,
      created_at: '2026-07-21T02:00:01Z',
    },
    {
      id: 'timeline-debt',
      kind: 'DEBT_CREATE',
      allocations: [
        {
          component: 'PROMO_BONUS',
          currency: 'BONUS_STAR_CANDY',
          gross_delta: '0',
          wallet_delta: '0',
          debt_delta: '400',
        },
      ],
      provider_occurred_at: null,
      campaign_version_id: FIXTURE_IDS.campaignVersion7,
      audit_id: null,
      operation_id: FIXTURE_IDS.operationDebt,
      created_at: '2026-07-21T02:00:02Z',
    },
    {
      id: 'timeline-recovery',
      kind: 'DEBT_RECOVERY',
      allocations: [
        {
          component: 'MISSION_CREDIT',
          currency: 'BONUS_STAR_CANDY',
          gross_delta: '500',
          wallet_delta: '100',
          debt_delta: '-400',
        },
      ],
      provider_occurred_at: null,
      campaign_version_id: null,
      audit_id: FIXTURE_IDS.auditRecovery,
      operation_id: FIXTURE_IDS.operationRecovery,
      created_at: '2026-07-21T03:00:00Z',
    },
  ],
};

function operation(id: string, overrides: Record<string, unknown> = {}) {
  return Object.assign(
    {
      id,
      operation_type: 'PURCHASE_REFUND',
      status: 'PENDING',
      retryable: true,
      attempt_count: '2',
      next_retry_at: '2026-07-21T00:05:00Z',
      last_error_code: 'TX_CONFLICT_RETRYABLE',
      support_ref: 'WAL-20260721-000001',
      row_version: '4',
      approval_reference: null,
      approval_status: null,
      requested_by: null,
      operation_key: 'operation-key-1',
      requested_currency: null,
      requested_direction: null,
      requested_amount: null,
      created_at: '2026-07-21T00:00:01Z',
      updated_at: '2026-07-21T00:00:02Z',
    },
    overrides,
  );
}

interface MockState {
  actorId: string;
  role: ActorRole;
  operationsPage: Record<string, unknown>;
  operationsSecondPage: Record<string, unknown>;
  timeline: Record<string, unknown>;
  repairRequesterId: string;
  rpcRequests: Array<{ name: string; body: unknown }>;
  commandRequests: Array<{ path: string; body: unknown }>;
}

function createState(role: ActorRole = 'OPERATOR'): MockState {
  return {
    actorId: actorIdByRole[role],
    role,
    operationsPage: emptyPage,
    operationsSecondPage: emptyPage,
    timeline: timelinePage,
    repairRequesterId: FIXTURE_IDS.actorOtherSuperAdmin,
    rpcRequests: [],
    commandRequests: [],
  };
}

async function json(route: Route, body: unknown, status = 200) {
  await route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) });
}

async function installWalletMocks(page: Page, state: MockState) {
  await page.route('**/rest/v1/rpc/**', async (route) => {
    const url = new URL(route.request().url());
    const name = url.pathname.split('/').pop() ?? '';
    const body = route.request().postDataJSON();
    state.rpcRequests.push({ name, body });

    if (name === 'admin_get_wallet_actor_context') {
      await json(route, {
        actor_id: state.actorId,
        actor_role: state.role,
        permissions: permissionsByRole[state.role],
      });
      return;
    }
    if (name === 'admin_get_user_cs_summary') {
      await json(route, csSummary);
      return;
    }
    if (name === 'admin_list_user_currency_history') {
      await json(route, emptyPage);
      return;
    }
    if (name === 'admin_list_user_money_timeline') {
      await json(route, state.timeline);
      return;
    }
    if (name === 'admin_list_user_wallet_debts') {
      await json(route, {
        items: [{
          id: FIXTURE_IDS.debt, user_id: USER_ID, currency: 'BONUS_STAR_CANDY',
          reason: 'PURCHASE_REFUND', status: 'OPEN', owed_amount: '450',
          recovered_amount: '0', waived_amount: '0', outstanding_amount: '450',
          source_refund_allocation_id: FIXTURE_IDS.refundAllocation,
          source_debit_allocation_id: null, row_version: '4',
          created_at: '2026-07-21T00:00:00Z', updated_at: '2026-07-21T00:00:00Z',
        }],
        total_count: '1', next_cursor: null, snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    if (name === 'admin_list_wallet_operations') {
      const cursor = (body as { p_cursor?: string | null }).p_cursor;
      await json(route, cursor ? state.operationsSecondPage : state.operationsPage);
      return;
    }
    if (name === 'admin_list_ops_alerts') {
      await json(route, {
        items: [
          {
            id: FIXTURE_IDS.alert,
            severity: 'WARNING',
            status: 'OPEN',
            summary: '환불 worker 지연',
            occurrence_count: '3',
            resource_type: 'WALLET_OPERATION',
            resource_id: FIXTURE_IDS.operationRetry,
            first_seen_at: '2026-07-21T00:00:00Z',
            last_seen_at: '2026-07-21T00:03:00Z',
            row_version: '2',
            audit_id: null,
          },
        ],
        total_count: '1',
        next_cursor: null,
        snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    if (name === 'admin_get_wallet_ops_summary') {
      await json(route, {
        inbox_pending_count: '1',
        inbox_dead_count: '0',
        inbox_oldest_pending_seconds: '30',
        debt_open_amount: { STAR_CANDY: '400', BONUS_STAR_CANDY: '50' },
        debt_oldest_open_seconds: { STAR_CANDY: '3600', BONUS_STAR_CANDY: '1800' },
        debt_recovery_rate_bps: '8000',
        campaign_conflict_count: '0',
        audit_completeness_bps: '10000',
        expiry_status: 'HEALTHY',
        reconciliation_status: 'HEALTHY',
        snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    if (name === 'admin_list_wallet_invariant_violations') {
      await json(route, emptyPage);
      return;
    }
    if (name === 'admin_get_worker_health') {
      await json(route, []);
      return;
    }
    if (name === 'admin_get_wallet_runtime_flags') {
      await json(route, {
        flag_version: '7',
        values: {
          'wallet.cotton_read_enabled': true,
          'wallet.cotton_spend_enabled': true,
          'wallet.cotton_expiry_enabled': true,
          'ads.internal_reward_mode': 'paused',
          'ads.pangle_reward_mode': 'paused',
          'ads.pangle_claim_mode': 'shadow',
          'ads.cotton_popup_enabled': false,
          candy_boost_write_enabled: false,
          refund_reversal_enabled: false,
          debt_recovery_enabled: true,
          promotion_surfaces_enabled: false,
          admin_financial_commands_enabled: false,
        },
        changed_at: SNAPSHOT_AT,
        changed_by: FIXTURE_IDS.actorSuperAdmin,
        snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    if (name === 'admin_list_wallet_audit_events') {
      await json(route, emptyPage);
      return;
    }
    if (name === 'admin_list_promotion_campaigns') {
      await json(route, {
        items: [
          {
            id: CAMPAIGN_ID,
            code: 'CANDY_BOOST_DAY',
            kind: 'PURCHASE_BONUS',
            latest_version: {
              id: FIXTURE_IDS.campaignVersion8,
              campaign_id: CAMPAIGN_ID,
              version: '8',
              effective_from: '2026-07-21T00:00:00Z',
              is_active: false,
              timezone: 'Asia/Seoul',
              weekly_start_isodow: 1,
              weekly_start_time: '00:00:00',
              weekly_end_isodow: 3,
              weekly_end_time: '00:00:00',
              extra_bonus_bps: '10000',
              display_name: { ko: '캔디 부스트 데이' },
              show_home_banner: false,
              show_in_store: false,
              home_banner_id: null,
              rollout_policy: {
                minimum_app_version: '1.2.34',
                minimum_app_build: '123401',
                cohort_version: 'boost-v1',
                cohort_seed: 'boost-seed-v1',
                cohort_threshold_bps: '10000',
              },
              change_reason: '운영 비활성화',
              created_by: FIXTURE_IDS.actorSuperAdmin,
              created_at: '2026-07-21T00:00:00Z',
              audit_id: FIXTURE_IDS.auditCampaign8,
            },
          },
        ],
        total_count: '1',
        next_cursor: null,
        snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    if (name === 'admin_preview_promotion_campaign') {
      await json(route, {
        campaign_id: CAMPAIGN_ID,
        evaluated_at: '2026-07-21T01:00:00Z',
        status: 'INACTIVE',
        effective_version: {
          id: FIXTURE_IDS.campaignVersion8,
          campaign_id: CAMPAIGN_ID,
          version: '8',
          effective_from: '2026-07-21T00:00:00Z',
          is_active: false,
          timezone: 'Asia/Seoul',
          weekly_start_isodow: 1,
          weekly_start_time: '00:00:00',
          weekly_end_isodow: 3,
          weekly_end_time: '00:00:00',
          extra_bonus_bps: '10000',
          display_name: { ko: '캔디 부스트 데이' },
          show_home_banner: false,
          show_in_store: false,
          home_banner_id: null,
          rollout_policy: {
            minimum_app_version: '1.2.34',
            minimum_app_build: '123401',
            cohort_version: 'boost-v1',
            cohort_seed: 'boost-seed-v1',
            cohort_threshold_bps: '10000',
          },
          change_reason: '운영 비활성화',
          created_by: FIXTURE_IDS.actorSuperAdmin,
          created_at: '2026-07-21T00:00:00Z',
          audit_id: FIXTURE_IDS.auditCampaign8,
        },
        window_start: null,
        window_end: null,
        surfaces: [],
      });
      return;
    }
    if (name === 'admin_list_promotion_campaign_versions') {
      await json(route, {
        items: [{
          id: FIXTURE_IDS.campaignVersion8, campaign_id: CAMPAIGN_ID, version: '8',
          effective_from: '2026-07-21T00:00:00Z', is_active: false,
          timezone: 'Asia/Seoul', weekly_start_isodow: 1,
          weekly_start_time: '00:00:00', weekly_end_isodow: 3,
          weekly_end_time: '00:00:00', extra_bonus_bps: '10000',
          display_name: { ko: '캔디 부스트 데이' }, show_home_banner: false,
          show_in_store: false, home_banner_id: null,
          rollout_policy: {
            minimum_app_version: '1.2.34', minimum_app_build: '123401',
            cohort_version: 'boost-v1', cohort_seed: 'boost-seed-v1',
            cohort_threshold_bps: '10000',
          },
          change_reason: '운영 비활성화', created_by: FIXTURE_IDS.actorSuperAdmin,
          created_at: SNAPSHOT_AT, audit_id: FIXTURE_IDS.auditCampaign8,
        }],
        total_count: '1', next_cursor: null, snapshot_at: SNAPSHOT_AT,
      });
      return;
    }
    await json(route, { code: 'UNMOCKED_RPC', name }, 500);
  });

  await page.route('**/rest/v1/user_profiles**', async (route) => {
    const profile = {
      id: USER_ID,
      nickname: 'wallet-e2e-user',
      email: 'wallet-e2e@example.com',
      created_at: '2026-01-01T00:00:00Z',
      deleted_at: null,
    };
    const accept = route.request().headers().accept ?? '';
    await json(route, accept.includes('vnd.pgrst.object') ? profile : [profile]);
  });

  await page.route('**/api/wallet/**', async (route) => {
    const path = new URL(route.request().url()).pathname;
    const body = route.request().postDataJSON();
    state.commandRequests.push({ path, body });

    if (path === '/api/wallet/operations/retry') {
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.retryCommandOperation,
        audit_id: FIXTURE_IDS.auditRetry,
        result: {
          enqueued: true,
          inbox_operation_id: FIXTURE_IDS.operationRetry,
          idempotency_key: 'original-inbox-key',
          status: 'PENDING',
        },
      });
      return;
    }
    if (path === '/api/wallet/repairs/preview') {
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.repairPreviewCommandOperation,
        audit_id: FIXTURE_IDS.auditRepairPreview,
        result: {
          repair_operation_id: FIXTURE_IDS.repairOperation,
          repair_kind: 'CORRECTION',
          requester_id: state.repairRequesterId,
          dry_run_hash: 'dry-run-hash-1',
          expected_version: '9',
          source_summary: { source: FIXTURE_IDS.operationRetry },
          snapshot_summary: { snapshot: 'purchase-snapshot-1' },
          ledger_rows: [{ id: FIXTURE_IDS.ledger, amount: '-500' }],
          debt_rows: [{ id: FIXTURE_IDS.debt, amount: '200' }],
          before_rows: [{ balance: '100' }],
          after_rows: [{ balance: '0' }],
          wallet_delta: { BONUS_STAR_CANDY: '-100' },
          debt_delta: { BONUS_STAR_CANDY: '400' },
        },
      });
      return;
    }
    if (path === '/api/wallet/corrections') {
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.correctionCommandOperation,
        audit_id: FIXTURE_IDS.auditCorrection,
        result: {
          repair_operation_id: FIXTURE_IDS.repairOperation,
          result_reference: 'correction-result-1',
          invariant_status: 'OK',
        },
      });
      return;
    }
    if (path === '/api/wallet/adjust') {
      if ((body as { amount?: string }).amount === '1000001') {
        await json(route, {
          ok: true,
          operation_id: FIXTURE_IDS.adjustPendingCommandOperation,
          audit_id: FIXTURE_IDS.auditAdjustPending,
          result: {
            status: 'PENDING_APPROVAL',
            approval_reference: ADJUST_APPROVAL_REFERENCE,
            operation_key: (body as { operation_key: string }).operation_key,
            requested_by: FIXTURE_IDS.actorFinanceAdmin,
            expires_at: '2026-07-22T00:00:00Z',
          },
        });
        return;
      }
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.adjustCommandOperation,
        audit_id: FIXTURE_IDS.auditAdjust,
        result: {
          status: 'APPLIED',
          user_id: USER_ID,
          currency: 'STAR_CANDY',
          direction: 'CREDIT',
          gross_amount: '100',
          debt_offset_amount: '100',
          net_wallet_credit_amount: '0',
          wallet_delta: '0',
          debt_created_amount: '0',
          balance_after: '90071992547409930001',
          debt_outstanding_after: '300',
        },
      });
      return;
    }
    if (path === '/api/wallet/adjust/approve') {
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.adjustApproveCommandOperation,
        audit_id: FIXTURE_IDS.auditAdjustApprove,
        result: {
          status: 'APPLIED',
          user_id: USER_ID,
          currency: 'STAR_CANDY',
          direction: 'CREDIT',
          gross_amount: '1000001',
          debt_offset_amount: '400',
          net_wallet_credit_amount: '999601',
          wallet_delta: '999601',
          debt_created_amount: '0',
          balance_after: '90071992547410929602',
          debt_outstanding_after: '0',
        },
      });
      return;
    }
    if (path === '/api/wallet/debts/waive') {
      await json(route, {
        ok: true,
        operation_id: FIXTURE_IDS.waiveCommandOperation,
        audit_id: FIXTURE_IDS.auditWaive,
        result: {
          debt_id: FIXTURE_IDS.debt,
          waived_amount: '50',
          outstanding_amount: '350',
        },
      });
      return;
    }
    await json(route, { code: 'UNMOCKED_COMMAND', path }, 404);
  });
}

async function openCorrectionPreview(page: Page) {
  await page.getByRole('button', { name: '복구 dry-run' }).click();
  const drawer = page.getByRole('dialog', { name: '지갑 복구 dry-run' });
  await drawer.getByLabel('복구 종류').click();
  await page.getByRole('option', { name: 'Correction' }).click();
  await drawer.getByLabel('통화').click();
  await page.getByRole('option', { name: '보너스 스타캔디' }).click();
  await drawer.getByLabel('금액').fill('500');
  await drawer.getByLabel('사유').fill('오지급 검증 완료');
  await drawer.getByLabel('CS 티켓').fill('CS-20260721-001');
  await drawer.getByRole('button', { name: 'dry-run 실행' }).click();
  await expect(drawer.getByText('dry-run-hash-1')).toBeVisible();
  await expect(drawer.getByText('BONUS_STAR_CANDY -100')).toBeVisible();
  await expect(drawer.getByText('BONUS_STAR_CANDY 400')).toBeVisible();
  return drawer;
}

test('hash direct navigation이 Alerts tab을 선택한다', async ({ page }) => {
  const state = createState();
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#alerts');
  await expect(page.getByRole('tab', { name: 'Alerts' })).toHaveAttribute(
    'aria-selected',
    'true',
  );
  await expect(page).toHaveURL(/#alerts$/);
});

test('empty operation page가 total_count 0을 표시한다', async ({ page }) => {
  const state = createState();
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#operations');
  await expect(page.getByTestId('wallet-operation-total')).toHaveText('0건');
  await expect(page.getByRole('button', { name: '더 보기' })).toHaveCount(0);
});

test('동일 timestamp operation과 opaque cursor 순서를 보존한다', async ({ page }) => {
  const state = createState();
  state.operationsPage = {
    items: [operation(FIXTURE_IDS.operationB), operation(FIXTURE_IDS.operationA)],
    total_count: '3',
    next_cursor: 'opaque-operations-page-2',
    snapshot_at: SNAPSHOT_AT,
  };
  state.operationsSecondPage = {
    items: [
      operation(FIXTURE_IDS.operationOlder, {
        created_at: '2026-07-20T23:59:59Z',
      }),
    ],
    total_count: '3',
    next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#operations');
  await expect(page.getByTestId('wallet-operation-id')).toHaveText([
    FIXTURE_IDS.operationB,
    FIXTURE_IDS.operationA,
  ]);
  await page.getByRole('button', { name: '더 보기' }).click();
  await expect(page.getByTestId('wallet-operation-id')).toHaveText([
    FIXTURE_IDS.operationB,
    FIXTURE_IDS.operationA,
    FIXTURE_IDS.operationOlder,
  ]);
  expect(state.rpcRequests).toContainEqual({
    name: 'admin_list_wallet_operations',
    body: expect.objectContaining({ p_cursor: 'opaque-operations-page-2' }),
  });
});

test('Operator retry는 enqueue만 하고 금융 action은 숨긴다', async ({ page }) => {
  const state = createState('OPERATOR');
  state.operationsPage = {
    items: [operation(FIXTURE_IDS.operationRetry)],
    total_count: '1',
    next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#operations');
  await page.getByRole('button', { name: '재시도 요청' }).click();
  const dialog = page.getByRole('dialog', { name: '재시도 요청' });
  await dialog.getByLabel('사유').fill('일시 충돌 재시도');
  await dialog.getByLabel('CS 티켓').fill('CS-20260721-002');
  await dialog.getByRole('button', { name: '큐에 등록' }).click();
  await expect(page.getByText('요청이 큐에 등록되었습니다')).toBeVisible();
  expect(state.commandRequests[0]).toEqual({
    path: '/api/wallet/operations/retry',
    body: expect.objectContaining({
      operation_id: FIXTURE_IDS.operationRetry,
      expected_version: '4',
    }),
  });
  await expect(page.getByRole('button', { name: '재화 조정' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Correction 승인' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: '긴급 비활성화' })).toHaveCount(0);
});

test('Finance 한도 초과 조정은 wallet 무변경 후 다른 Super Admin만 승인한다', async ({ browser }) => {
  const financeContext = await browser.newContext({
    storageState: 'playwright/.auth/admin.json',
  });
  const financePage = await financeContext.newPage();
  const financeState = createState('FINANCE_ADMIN');
  await installWalletMocks(financePage, financeState);
  await financePage.goto(`/user_profiles/show/${USER_ID}`);
  const beforeBalance = await financePage
    .getByTestId('wallet-balance-STAR_CANDY')
    .textContent();

  await financePage.getByRole('button', { name: '재화 조정' }).click();
  const dialog = financePage.getByRole('dialog', { name: 'Star/Bonus 재화 조정' });
  await dialog.getByLabel('방향').click();
  await financePage.getByRole('option', { name: '적립' }).click();
  await dialog.getByLabel('통화').click();
  await expect(financePage.getByRole('option', { name: '스타캔디' })).toBeVisible();
  await expect(financePage.getByRole('option', { name: '보너스 스타캔디' })).toBeVisible();
  await expect(financePage.getByRole('option', { name: '코튼캔디' })).toHaveCount(0);
  await financePage.getByRole('option', { name: '스타캔디' }).click();
  await dialog.getByLabel('금액').fill('1000001');
  await dialog.getByLabel('사유').fill('한도 초과 고객 보상');
  await dialog.getByLabel('CS 티켓').fill('CS-20260721-LIMIT');
  await dialog.getByRole('button', { name: '조정 요청' }).click();

  await expect(financePage.getByText('승인 대기')).toBeVisible();
  await expect(financePage.getByText(ADJUST_APPROVAL_REFERENCE)).toBeVisible();
  await expect(financePage.getByTestId('wallet-balance-STAR_CANDY')).toHaveText(
    beforeBalance ?? '',
  );
  const financeRequest = financeState.commandRequests.find(
    (item) => item.path === '/api/wallet/adjust',
  );
  expect(Object.keys(financeRequest?.body as object).sort()).toEqual([
    'action', 'amount', 'approval_reference', 'cs_ticket', 'currency',
    'direction', 'operation_key', 'reason', 'request_id', 'user_id',
  ]);
  expect(financeRequest?.body).toEqual(expect.objectContaining({
    action: 'REQUEST',
    amount: '1000001',
    approval_reference: null,
  }));
  const operationKey = (financeRequest?.body as { operation_key: string }).operation_key;
  await financeContext.close();

  const pendingOperation = operation(FIXTURE_IDS.adjustPendingCommandOperation, {
    operation_type: 'ADMIN_ADJUST',
    status: 'PENDING',
    retryable: false,
    approval_reference: ADJUST_APPROVAL_REFERENCE,
    approval_status: 'PENDING',
    requested_by: FIXTURE_IDS.actorFinanceAdmin,
    operation_key: operationKey,
    requested_currency: 'STAR_CANDY',
    requested_direction: 'CREDIT',
    requested_amount: '1000001',
  });

  const sameActorContext = await browser.newContext({
    storageState: 'playwright/.auth/admin.json',
  });
  const sameActorPage = await sameActorContext.newPage();
  const sameActorState = createState('SUPER_ADMIN');
  sameActorState.actorId = FIXTURE_IDS.actorFinanceAdmin;
  sameActorState.operationsPage = {
    items: [pendingOperation], total_count: '1', next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  await installWalletMocks(sameActorPage, sameActorState);
  await sameActorPage.goto('/wallet-ops#operations');
  await sameActorPage.getByRole('button', { name: '조정 승인 검토' }).click();
  const sameActorDrawer = sameActorPage.getByRole('dialog', {
    name: 'Star/Bonus 조정 승인',
  });
  await expect(sameActorDrawer.getByRole('button', { name: '조정 승인' }))
    .toHaveCount(0);
  expect(sameActorState.commandRequests).toHaveLength(0);
  await sameActorContext.close();

  const approverContext = await browser.newContext({
    storageState: 'playwright/.auth/admin.json',
  });
  const approverPage = await approverContext.newPage();
  const approverState = createState('SUPER_ADMIN');
  approverState.actorId = FIXTURE_IDS.actorOtherSuperAdmin;
  approverState.operationsPage = {
    items: [pendingOperation], total_count: '1', next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  await installWalletMocks(approverPage, approverState);
  await approverPage.goto('/wallet-ops#operations');
  await approverPage.getByRole('button', { name: '조정 승인 검토' }).click();
  const approverDrawer = approverPage.getByRole('dialog', {
    name: 'Star/Bonus 조정 승인',
  });
  await approverDrawer.getByLabel('승인 사유').fill('별도 Super Admin 검토 완료');
  await approverDrawer.getByLabel('CS 티켓').fill('CS-20260721-APPROVE');
  await approverDrawer.getByRole('button', { name: '조정 승인' }).click();
  await expect(approverDrawer.getByText(FIXTURE_IDS.adjustApproveCommandOperation))
    .toBeVisible();
  const approvalRequest = approverState.commandRequests.find(
    (item) => item.path === '/api/wallet/adjust/approve',
  );
  expect(Object.keys(approvalRequest?.body as object).sort()).toEqual([
    'action', 'approval_reference', 'cs_ticket', 'operation_key', 'reason',
    'request_id',
  ]);
  expect(approvalRequest?.body).toEqual(expect.objectContaining({
    action: 'APPROVE',
    approval_reference: ADJUST_APPROVAL_REFERENCE,
    operation_key: operationKey,
  }));
  await approverContext.close();
});

test('Super Admin correction은 requester와 approver가 달라야 한다', async ({ page }) => {
  const state = createState('SUPER_ADMIN');
  state.operationsPage = {
    items: [operation(FIXTURE_IDS.operationRetry)],
    total_count: '1',
    next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  state.repairRequesterId = state.actorId;
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#operations');
  let drawer = await openCorrectionPreview(page);
  await expect(drawer.getByRole('button', { name: 'Correction 승인' })).toHaveCount(0);
  await drawer.getByRole('button', { name: '닫기' }).click();

  state.repairRequesterId = FIXTURE_IDS.actorOtherSuperAdmin;
  drawer = await openCorrectionPreview(page);
  await drawer.getByRole('button', { name: 'Correction 승인' }).click();
  await expect(drawer.getByText('correction-result-1')).toBeVisible();
  expect(state.commandRequests.some((item) => item.path === '/api/wallet/corrections')).toBe(true);
});

test('CS timeline이 구매부터 future recovery까지 통화별로 재구성한다', async ({ page }) => {
  const state = createState('FINANCE_ADMIN');
  await installWalletMocks(page, state);
  await page.goto(`/user_profiles/show/${USER_ID}`);
  await page.getByRole('tab', { name: '재화 타임라인' }).click();
  await expect(page.getByTestId('timeline-kind')).toHaveText([
    'PURCHASE',
    'PROMOTION_AWARD',
    'PURCHASE_REFUND',
    'DEBT_CREATE',
    'DEBT_RECOVERY',
  ]);
  await expect(page.getByTestId('timeline-allocation')).toHaveCount(6);
  await expect(page.getByTestId('combined-star-bonus-total')).toHaveCount(0);
  await expect(page.getByText(FIXTURE_IDS.campaignVersion7).first()).toBeVisible();
  await expect(page.getByText(FIXTURE_IDS.auditRecovery)).toBeVisible();
});

test('inactive latest campaign은 과거 active version으로 fallback하지 않는다', async ({ page }) => {
  const state = createState('SUPER_ADMIN');
  await installWalletMocks(page, state);
  await page.goto(`/promotion-campaigns/show/${CAMPAIGN_ID}`);
  await page.getByLabel('기준 시각').fill('2026-07-21T10:00');
  await page.getByRole('button', { name: '판정 미리보기' }).click();
  await expect(page.getByText('비활성 버전으로 적용 없음')).toBeVisible();
  await expect(page.getByText(FIXTURE_IDS.campaignVersion8).first()).toBeVisible();
  await expect(page.getByText(FIXTURE_IDS.campaignVersion7)).toHaveCount(0);
});

test('민감 provider와 receipt 필드를 DOM에 렌더링하지 않는다', async ({ page }) => {
  const state = createState();
  state.operationsPage = {
    items: [
      operation(FIXTURE_IDS.operationMasked, {
        provider_payload: 'secret-provider-payload',
        receipt: 'secret-receipt',
        access_token: 'secret-access-token',
        signature: 'secret-signature',
      }),
    ],
    total_count: '1',
    next_cursor: null,
    snapshot_at: SNAPSHOT_AT,
  };
  await installWalletMocks(page, state);
  await page.goto('/wallet-ops#operations');
  await expect(page.locator('body')).not.toContainText('secret-provider-payload');
  await expect(page.locator('body')).not.toContainText('secret-receipt');
  await expect(page.locator('body')).not.toContainText('secret-access-token');
  await expect(page.locator('body')).not.toContainText('secret-signature');
});
```

Run setup: `npm run dev`를 실행한 terminal에서 로그인한 뒤 별도 terminal에서 `npm run test:e2e:auth`를 실행해 `playwright/.auth/admin.json`을 만든다.

Run: `npm run test:e2e`

Expected: 9 acceptance flows pass in Chromium.

- [ ] **Step 4: 전체 Jest와 static gate를 실행한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
npm test -- --runInBand
npm run type-check
npm run build
```

Expected: all commands exit 0. Build는 Supabase type generation을 실행하지 않는다.

- [ ] **Step 5: direct mutation과 contract checksum gate를 마지막으로 실행한다**

```bash
cd /Users/charlie.hyun/Repositories/picnic-admin-wallet-ops
npm run verify:wallet-contracts
if rg -n "repair_bonus_balance|repair_bonus_balance_bulk|list_bonus_drift|CANDY_HISTORY_TYPES" app lib components; then exit 1; fi
if rg -U -n "(?s)from\(['\"]star_candy(_bonus)?_history['\"]\).{0,200}\.insert\(|from\(['\"]user_profiles['\"]\).{0,200}\.update\(\{\s*(star_candy|star_candy_bonus|cotton_candy)\b" app/user_profiles; then exit 1; fi
if rg -U -n --glob '!app/api/**' --glob '!**/*.server.ts' --glob '!**/__tests__/**' --glob '!**/test/**' "(?s)\.rpc\(\s*['\"](admin_create_promotion_version|admin_adjust_star_bonus|apply_wallet_correction|admin_request_wallet_operation_retry|admin_ack_wallet_ops_alert|admin_preview_wallet_repair|admin_execute_wallet_repair|admin_waive_wallet_debt|admin_emergency_set_wallet_flags)['\"]" app components lib; then exit 1; fi
git -C /Users/charlie.hyun/Repositories/picnic-admin status --short -- types/supabase.ts
```

Expected: checksum mismatch 0, legacy writer와 browser command RPC 직접 호출 0, 마지막 명령은 원본 main worktree의 기존 ` M types/supabase.ts`만 보여 준다.

- [ ] **Step 6: acceptance test를 commit한다**

```bash
git add .gitignore package.json package-lock.json playwright.config.ts e2e/wallet-admin.spec.ts
git commit -m "test(wallet): add admin acceptance coverage"
```

- [ ] **Step 7: Preview 검증 전 merge하지 않는다**

PR 생성 후 Vercel Preview URL에서 실제 Supabase preview schema를 대상으로 Operator, Finance Admin, Super Admin 각 계정의 read/action 노출과 stable error를 확인한다. 확인 결과를 PR 본문에 기록한 뒤에만 master rollout plan의 legacy revoke gate로 이동한다.
