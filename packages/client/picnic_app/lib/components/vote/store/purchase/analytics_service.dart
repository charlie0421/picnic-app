import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AnalyticsService {
  Future<void> logPurchaseEvent(ProductDetails productDetails) async {
    await FirebaseAnalytics.instance.logPurchase(
      currency: productDetails.currencyCode,
      value: productDetails.rawPrice,
      items: [
        AnalyticsEventItem(
          itemId: productDetails.id,
          itemName: productDetails.title,
          price: productDetails.rawPrice,
        ),
      ],
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
