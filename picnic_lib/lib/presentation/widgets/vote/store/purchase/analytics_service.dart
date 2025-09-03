import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  Future<void> logPurchaseEvent(
    ProductDetails product, {
    String? transactionId,
  }) async {
    try {
      logger.i('Purchase success: ${product.id}');
      final price = _extractPrice(product);
      final currency = _extractCurrency(product);

      // GA4 권장 스키마: purchase
      final items = <Map<String, Object>>[
        {
          'item_id': product.id,
          'item_name': product.title,
          if (price != null) 'price': price,
          if (currency != null) 'currency': currency,
          'quantity': 1,
        },
      ];

      final params = <String, Object>{
        if (currency != null) 'currency': currency,
        if (price != null) 'value': price,
        'items': items,
        if (transactionId != null) 'transaction_id': transactionId,
      };

      await FirebaseAnalytics.instance.logEvent(
        name: 'purchase',
        parameters: params,
      );
    } catch (e, s) {
      logger.e('Error logging purchase event', error: e, stackTrace: s);
    }
  }

  Future<void> logPurchaseCancelEvent(String productId) async {
    try {
      logger.i('Purchase canceled: $productId');
      await FirebaseAnalytics.instance.logEvent(
        name: 'purchase_cancel',
        parameters: {'product_id': productId},
      );
    } catch (e, s) {
      logger.e('Error logging purchase cancel event', error: e, stackTrace: s);
    }
  }

  Future<void> logPurchaseErrorEvent({
    required String productId,
    required String errorCode,
    required String errorMessage,
  }) async {
    try {
      logger.i(
        'Purchase error: $productId, code: $errorCode, message: $errorMessage',
      );
      await FirebaseAnalytics.instance.logEvent(
        name: 'purchase_error',
        parameters: {
          'product_id': productId,
          'error_code': errorCode,
          'error_message': errorMessage,
        },
      );
    } catch (e, s) {
      logger.e('Error logging purchase error event', error: e, stackTrace: s);
    }
  }

  String? _extractCurrency(ProductDetails product) {
    try {
      return product.currencyCode;
    } catch (_) {
      return null;
    }
  }

  num? _extractPrice(ProductDetails product) {
    try {
      return product.rawPrice;
    } catch (_) {
      return null;
    }
  }
}
