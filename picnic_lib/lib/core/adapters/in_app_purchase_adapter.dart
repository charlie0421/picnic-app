import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 인앱 구매 플랫폼 어댑터 인터페이스
/// Infrastructure Layer - 외부 API 래핑만 담당
abstract class InAppPurchaseAdapter {
  /// 소모품 구매 시작
  Future<bool> buyConsumable(ProductDetails productDetails);

  /// 구매 완료 처리
  Future<void> completePurchase(PurchaseDetails purchaseDetails);

  /// 구매 스트림
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// 기존 구매 복원
  Future<void> restorePurchases();

  /// 스토어 사용 가능 여부
  Future<bool> isAvailable();

  /// 리소스 정리
  void dispose();
}

/// InAppPurchase 플랫폼 어댑터 구현체
class InAppPurchaseAdapterImpl implements InAppPurchaseAdapter {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  void init() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        logger.i(
            'Raw purchase stream received: ${purchaseDetailsList.length} items');
        for (final purchase in purchaseDetailsList) {
          logger.i('Purchase: ${purchase.productID} -> ${purchase.status}');
        }
        _purchaseController.add(purchaseDetailsList);
      },
      onError: (error) {
        logger.e('Purchase stream error', error: error);
        _purchaseController.addError(error);
      },
    );
  }

  @override
  Future<bool> buyConsumable(ProductDetails productDetails) async {
    try {
      final bool available = await isAvailable();
      if (!available) {
        logger.e('Store is not available');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool result = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      logger.i('buyConsumable initiated: ${productDetails.id} -> $result');
      return result;
    } catch (e, stack) {
      logger.e('Error in buyConsumable', error: e, stackTrace: stack);
      return false;
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      logger.i('Completing purchase: ${purchaseDetails.productID}');
      await _inAppPurchase.completePurchase(purchaseDetails);
      logger.i('Purchase completed: ${purchaseDetails.productID}');
    } catch (e, stack) {
      logger.e('Error completing purchase: ${purchaseDetails.productID}',
          error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      logger.i('Restoring purchases');
      await _inAppPurchase.restorePurchases();
    } catch (e, stack) {
      logger.e('Error restoring purchases', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}
