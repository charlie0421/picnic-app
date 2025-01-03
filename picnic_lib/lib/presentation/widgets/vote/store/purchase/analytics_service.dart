import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class AnalyticsService {
  Future<void> logPurchaseEvent(ProductDetails product) async {
    try {
      logger.i('Purchase success: ${product.id}');
      // 구매 성공 이벤트 로깅 로직
    } catch (e, s) {
      logger.e('Error logging purchase event', error: e, stackTrace: s);
    }
  }

  Future<void> logPurchaseCancelEvent(String productId) async {
    try {
      logger.i('Purchase canceled: $productId');
      // 구매 취소 이벤트 로깅 로직
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
          'Purchase error: $productId, code: $errorCode, message: $errorMessage');
      // 구매 에러 이벤트 로깅 로직
    } catch (e, s) {
      logger.e('Error logging purchase error event', error: e, stackTrace: s);
    }
  }
}
