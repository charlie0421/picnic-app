import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseCampaignAttempt {
  const PurchaseCampaignAttempt({
    required this.attemptId,
    required this.productId,
    required this.displayedCampaign,
  });
  final String attemptId;
  final String productId;
  final ActivePromotionCampaignModel? displayedCampaign;
}

class PurchaseExecutionContext {
  PurchaseExecutionContext({required this.attempt});
  final PurchaseCampaignAttempt attempt;
  bool launched = false;
  String? transactionId;
}

class PurchaseCampaignAttemptRegistry {
  final Map<String, PurchaseExecutionContext> _byProduct = {};
  final Map<String, String> _attemptByTransaction = {};
  final Set<String> _completedTransactions = {};

  PurchaseCampaignAttempt? operator [](String productId) =>
      _byProduct[productId]?.attempt;
  bool contains(String productId) => _byProduct.containsKey(productId);

  bool begin(PurchaseCampaignAttempt attempt) =>
      _byProduct
          .putIfAbsent(
            attempt.productId,
            () => PurchaseExecutionContext(attempt: attempt),
          )
          .attempt ==
      attempt;

  bool removeIfMatches(String productId, String attemptId) {
    if (_byProduct[productId]?.attempt.attemptId != attemptId) return false;
    _byProduct.remove(productId);
    return true;
  }

  bool applyLaunchResult(
    String productId,
    String attemptId,
    Map<String, dynamic> result,
  ) {
    final terminal =
        result['wasCancelled'] == true || result['success'] != true;
    if (terminal) return removeIfMatches(productId, attemptId);
    final context = _byProduct[productId];
    if (context?.attempt.attemptId == attemptId) context!.launched = true;
    return false;
  }

  /// Binds a StoreKit/Play event to the attempt that was locked at launch.
  ///
  /// A transaction id is mandatory: product id alone is not transaction
  /// identity. Restores are recovery traffic and never consume a live launch.
  PurchaseCampaignAttempt? bind(PurchaseDetails purchase) {
    final transactionId = purchase.purchaseID;
    if (transactionId == null ||
        transactionId.isEmpty ||
        purchase.status == PurchaseStatus.restored ||
        _completedTransactions.contains(transactionId)) {
      return null;
    }
    final existingAttemptId = _attemptByTransaction[transactionId];
    if (existingAttemptId != null) {
      final context = _byProduct[purchase.productID];
      return context?.attempt.attemptId == existingAttemptId
          ? context!.attempt
          : null;
    }
    final context = _byProduct[purchase.productID];
    if (context == null || !context.launched || context.transactionId != null) {
      return null;
    }
    context.transactionId = transactionId;
    _attemptByTransaction[transactionId] = context.attempt.attemptId;
    return context.attempt;
  }

  bool finish(PurchaseDetails purchase, String attemptId) {
    final transactionId = purchase.purchaseID;
    if (transactionId == null ||
        _attemptByTransaction[transactionId] != attemptId) {
      return false;
    }
    _completedTransactions.add(transactionId);
    _attemptByTransaction.remove(transactionId);
    return removeIfMatches(purchase.productID, attemptId);
  }
}

typedef PresentPurchaseSettlement =
    Future<void> Function(
      PurchaseSettlementResultModel result,
      ActivePromotionCampaignModel? displayedCampaign,
    );

/// Production seam between PurchaseService's verified result callback and the
/// dialog layer. It deliberately forwards the same immutable result and the
/// campaign captured before StoreKit/Play was launched.
class PurchaseSettlementPresentation {
  const PurchaseSettlementPresentation();

  Future<void> present({
    required PurchaseSettlementResultModel result,
    required PurchaseCampaignAttempt attempt,
    required bool isLate,
    required PresentPurchaseSettlement showSuccess,
    required PresentPurchaseSettlement showLateSuccess,
  }) => (isLate ? showLateSuccess : showSuccess)(
    result,
    attempt.displayedCampaign,
  );
}
