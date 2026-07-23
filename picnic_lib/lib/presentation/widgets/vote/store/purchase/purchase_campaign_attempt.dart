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

class PurchaseCampaignAttemptRegistry {
  final Map<String, PurchaseCampaignAttempt> _byProduct = {};

  PurchaseCampaignAttempt? operator [](String productId) =>
      _byProduct[productId];
  bool contains(String productId) => _byProduct.containsKey(productId);

  bool begin(PurchaseCampaignAttempt attempt) =>
      _byProduct.putIfAbsent(attempt.productId, () => attempt) == attempt;

  bool removeIfMatches(String productId, String attemptId) {
    if (_byProduct[productId]?.attemptId != attemptId) return false;
    _byProduct.remove(productId);
    return true;
  }
}
