import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';

/// Settles a purchase whose receipt has just been verified.
///
/// This is the body of the success callback handed to
/// `PurchaseService.handleOptimizedPurchase`, lifted out of the widget so the
/// ordering it depends on can be driven directly in tests. The order is the
/// invariant, not an implementation detail:
///
/// 1. read lateness
/// 2. [PurchaseSafetyManager.completePurchaseSession]
/// 3. cleanup of every timer on success
/// 4. post-purchase cleanup
/// 5. apply the wallet summary
/// 6. present the receipt
///
/// Steps 2 and 3 destroy the state lateness is derived from - step 2 drops the
/// product from the manager's active set, step 3 clears the triggered safety
/// timeout - so the read in step 1 cannot be moved below either of them.
///
/// Two more orderings are load-bearing and are pinned in the tests:
///
/// - The wallet is applied before the receipt is presented, and it is applied
///   whether or not the store is still mounted. The candy was granted
///   server-side when the receipt verified; skipping this leaves
///   `walletSummaryProvider` reporting a stale balance. This is why the write
///   arrives as a [WalletSummaryApplier] and not as a closure: the production
///   applier holds the Riverpod container, captured while the store was
///   mounted, so it still lands once the store is gone. Reaching this step at
///   all with the store gone is `PurchaseService`'s side of the same rule -
///   it reads providers through that container too, and no failure downstream
///   of receipt verification may turn a settled purchase into an `onError`.
///   `purchase_after_leaving_store_test.dart` drives that whole path.
/// - `attempts.finish` runs *after* the awaited receipt dialog returns, so an
///   attempt that is still registered when settlement starts stays registered
///   for as long as the receipt is on screen: `_purchaseAttempts.contains()`
///   is what makes a second tap hit `showPurchaseAlreadyPendingDialog` instead
///   of a second charge. That only covers settlements that arrive inside the
///   safety window - for a late one `PurchaseStarCandyState`'s
///   `onProductTimeout` already dropped the attempt when the 90s timer fired,
///   and the per-product cooldown is all that stands behind the receipt.
///
/// The rest of what is genuinely bound to the widget (mount state, `setState`,
/// the loading overlay) enters as a callback so the step never reaches into
/// widget state.
class PurchaseSettlementStep {
  const PurchaseSettlementStep({
    PurchaseSettlementPresentation presentation =
        const PurchaseSettlementPresentation(),
  }) : _presentation = presentation;

  final PurchaseSettlementPresentation _presentation;

  Future<void> settle({
    required PurchaseSafetyManager safetyManager,
    required PurchaseCampaignAttemptRegistry attempts,
    required PurchaseDetails purchaseDetails,
    required PurchaseSettlementResultModel result,
    required PurchaseCampaignAttempt attempt,
    required void Function(String productId) cleanupAllTimersOnSuccess,
    required WalletSummaryApplier applyWalletSummary,
    required bool Function() isMounted,
    required void Function(String productId) resetProductPurchaseState,
    required VoidCallback hideLoading,
    required PurchaseReceiptDialogs receiptDialogs,
  }) async {
    final productId = purchaseDetails.productID;

    // The safety timeout can fire while receipt verification is still
    // running, so lateness must be read here - when the verified result
    // lands - and before completePurchaseSession/cleanupAllTimersOnSuccess
    // below clear the safety state.
    final isLatePurchase = safetyManager.isLatePurchaseForProduct(productId);
    logger.i(
      '[PurchaseStarCandyState] Purchase successful (late: $isLatePurchase)',
    );

    // 🛡️ 구매 세션 완료 기록으로 중복 방지 (이미 내부적으로 안전망 타이머 정리함)
    safetyManager.completePurchaseSession(productId);

    // 🧹 모든 타이머 완전 정리 (정상 구매 완료 시)
    cleanupAllTimersOnSuccess(productId);

    // 🧹 구매 완료 후 클린 작업 수행 (동기 처리로 완전성 보장)
    final transactionId =
        purchaseDetails.purchaseID ??
        '${productId}_${DateTime.now().millisecondsSinceEpoch}';

    // 🧹 동기로 클린 작업 실행 - 완료까지 기다림 (확실성 우선)
    await safetyManager.performPostPurchaseCleanup(
      productId: productId,
      transactionId: transactionId,
      completedPurchase: purchaseDetails,
    );

    applyWalletSummary(result.wallet);
    if (isMounted()) {
      resetProductPurchaseState(productId);
      hideLoading();

      await _presentation.present(
        result: result,
        attempt: attempt,
        isLate: isLatePurchase,
        dialogs: receiptDialogs,
      );
    }
    attempts.finish(purchaseDetails, attempt.attemptId);
    // finish가 어템프트를 제거해도 위젯이 스스로 다시 그리지는 않는다.
    // 직전 setState는 다이얼로그가 뜨기 전이라 구매 버튼이 "어템프트
    // 등록됨(로딩)" 상태로 그려진 채 남는다 (iOS 실기기 재현, 2026-07-28).
    // 제거된 상태를 화면에 반영한다.
    if (isMounted()) {
      resetProductPurchaseState(productId);
    }
  }
}
