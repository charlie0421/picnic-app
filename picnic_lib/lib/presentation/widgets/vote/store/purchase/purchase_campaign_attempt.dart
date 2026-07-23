import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';

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
}

class PurchaseCampaignAttemptRegistry {
  final Map<String, PurchaseExecutionContext> _byProduct = {};

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
}
