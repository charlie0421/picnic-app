# Admin Menu Functionality Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 관리자 메뉴의 충전 내역과 GDPR 초기화를 실제로 동작시키고 캔디 내역 오류 및 하위 화면 패딩을 수정한다.

**Architecture:** 기존 Supabase `get_payment_breakdown` RPC를 repository/provider/page로 연결하고 각 페이지에서 관리자 권한을 다시 검사한다. 코튼캔디 내역은 운영 플래그가 꺼진 동안 요청하지 않도록 탭에서 제외하며, GDPR 작업은 주입 가능한 실행 경계로 분리해 플랫폼 채널 없이 동작을 검증한다.

**Tech Stack:** Flutter, Riverpod, Supabase RPC, google_mobile_ads UMP, flutter_phoenix, flutter_test

## Global Constraints

- `get_payment_breakdown`의 `revenue_usd`만 decimal 문자열로 반환하도록 새 Supabase 마이그레이션을 추가하고 Edge Function은 변경하지 않는다.
- 충전 내역은 기존 `get_payment_breakdown` RPC의 `platform` 및 `product` 차원을 사용한다.
- 충전 내역은 결제 건수와 USD 매출을 표시한다.
- 관리자 메뉴, 캔디 내역, 충전 내역의 좌우 패딩은 정확히 16px이다.
- 캔디 내역은 스타캔디와 보너스 스타캔디만 표시하고 `COTTON_CANDY`를 요청하지 않는다.
- GDPR 성공 시 실제 앱 reload를 실행하고, 실패·예외 시 reload하지 않는다.
- 관리자 페이지의 클라이언트 권한 검사와 DB 권한 검사를 모두 유지한다.
- OTA 대상 릴리스는 `1.3.0+130001`이다.

---

### Task 1: 관리자 충전 내역 데이터와 화면

**Files:**
- Create: `picnic_lib/lib/data/models/admin/payment_breakdown.dart`
- Create: `picnic_lib/lib/data/repositories/admin_repository.dart`
- Create: `picnic_lib/lib/presentation/providers/admin_provider.dart`
- Create: `picnic_lib/lib/presentation/pages/my_page/charge_history_page.dart`
- Create: `picnic_lib/test/data/repositories/admin_repository_test.dart`
- Create: `picnic_lib/test/presentation/pages/my_page/charge_history_page_test.dart`
- Create: `supabase/migrations/<generated_timestamp>_cast_payment_breakdown_revenue_to_text.sql`
- Modify: generated provider files only when the repository's established Riverpod generation workflow requires them

**Interfaces:**
- Produces: `PaymentBreakdownItem(key: String, payCount: BigInt, revenueUsd: Decimal/string-safe value)`, `AdminRepository.getPaymentBreakdown({required PaymentBreakdownDimension dimension})`, Riverpod providers for both dimensions, `const ChargeHistoryPage()`
- Consumes: Supabase RPC `get_payment_breakdown` with `p_start: null`, `p_end: null`, and `p_dimension` equal to `platform` or `product`; `revenue_usd` is returned as decimal text

- [ ] Write repository tests that assert exact RPC name/parameters and strict parsing of `key`, `pay_cnt`, and `revenue_usd`.
- [ ] Run repository tests and verify RED because the model/repository do not exist.
- [ ] Generate a Supabase migration and change only `get_payment_breakdown`'s `revenue_usd` JSON field to `revenue_usd::text`.
- [ ] Implement the minimal model and repository; accept `revenue_usd` only as decimal text so it never passes through binary floating point.
- [ ] Write widget tests for admin platform/product tabs, rows, loading/error/empty state, non-admin access denial, and exact 16px horizontal content inset.
- [ ] Run widget tests and verify RED because the page/provider do not exist.
- [ ] Implement `ChargeHistoryPage`, title `충전 내역`, direct admin guard, two tabs, and list rows.
- [ ] Run both test files and analyzer until green.
- [ ] Commit with `feat(mypage): add administrator charge history`.

### Task 2: 관리자 내비게이션, 캔디 탭, 패딩

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/my_page/admin_menu_page.dart`
- Modify: `picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart`
- Modify: `picnic_lib/test/presentation/pages/my_page/admin_menu_page_test.dart`
- Modify: `picnic_lib/test/presentation/pages/my_page/currency_history_page_test.dart`

**Interfaces:**
- Consumes: `const ChargeHistoryPage()` from Task 1
- Produces: working `충전 내역` navigation and two-currency history UI

- [ ] Update tests first: tapping `충전 내역` opens `ChargeHistoryPage`; admin menu has 16px inset; currency history shows only 스타/보너스 tabs, never requests cotton, and has 16px inset.
- [ ] Run both tests and verify expected RED failures.
- [ ] Add `EdgeInsets.symmetric(horizontal: 16)` around admin menu and currency history content.
- [ ] Connect `충전 내역` to `ChargeHistoryPage`.
- [ ] Reduce currency history controller/view to `WalletCurrency.starCandy` and `WalletCurrency.bonusStarCandy` only.
- [ ] Run focused tests and analyzer until green.
- [ ] Commit with `fix(mypage): repair admin history navigation`.

### Task 3: GDPR reset and reload

**Files:**
- Modify: `picnic_lib/lib/core/services/consent_service.dart`
- Modify: `picnic_lib/lib/presentation/pages/my_page/admin_menu_page.dart`
- Create: `picnic_lib/lib/presentation/controllers/admin_gdpr_reset_controller.dart`
- Create: `picnic_lib/test/presentation/controllers/admin_gdpr_reset_controller_test.dart`
- Modify: `picnic_lib/test/presentation/pages/my_page/admin_menu_page_test.dart`

**Interfaces:**
- Produces: controller result with success/failure and a single-flight guard; admin page invokes reset then `Phoenix.rebirth(context)` only on success
- Consumes: `ConsentService.resetAndReinitialize()` and best-effort `ConsentService.logCurrentState()`

- [ ] Write controller tests for success, false result, thrown exception, best-effort logging failure, and duplicate call suppression.
- [ ] Run tests and verify RED because the controller does not exist.
- [ ] Implement a small controller with injected async reset/log callbacks and no Flutter platform dependency.
- [ ] Update admin page tests with injected controller/reload callback so success reloads once and failure does not reload.
- [ ] Run page tests and verify RED before wiring production behavior.
- [ ] Wire the controller to `ConsentService`, show progress/success/failure feedback, prevent duplicate taps, and call `Phoenix.rebirth(context)` only after success.
- [ ] Ensure `ConsentService.resetAndReinitialize()` catches platform exceptions and returns false instead of escaping.
- [ ] Run controller, admin page, consent service, charge history, and currency history tests plus analyzer.
- [ ] Commit with `fix(mypage): restore GDPR reset and reload`.

### Task 4: Integration verification and OTA readiness

**Files:**
- Verify only; modify production files only for findings raised by review

**Interfaces:**
- Consumes: Tasks 1–3 completed commits
- Produces: reviewed, pushed commit set suitable for Shorebird patching

- [ ] Run all affected tests for admin menu, charge history, currency history, consent service/controller, MyPage, wallet repository/provider.
- [ ] Run analyzer on every changed Dart file and `git diff --check`.
- [ ] Confirm `picnic_app/pubspec.yaml` is exactly `1.3.0+130001`.
- [ ] Complete task reviews and a final whole-branch review; fix all Critical/Important findings.
- [ ] Push the existing PR branch and confirm PR head/mergeability.
- [ ] Create local Shorebird stable patches for iOS and Android without tags or Codemagic.
- [ ] Query Shorebird and confirm both new patches are stable and not rolled back.
