import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

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
/// Everything that is genuinely bound to the widget (mount state, `setState`,
/// the loading overlay, the Riverpod container) enters as a callback so the
/// step never reaches into widget state.
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
    required void Function(WalletSummaryModel wallet) applyWalletSummary,
    required bool Function() isMounted,
    required void Function(String productId) resetProductPurchaseState,
    required VoidCallback hideLoading,
    required PresentPurchaseSettlement showSuccess,
    required PresentPurchaseSettlement showLateSuccess,
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
        showSuccess: showSuccess,
        showLateSuccess: showLateSuccess,
      );
    }
    attempts.finish(purchaseDetails, attempt.attemptId);
  }
}
