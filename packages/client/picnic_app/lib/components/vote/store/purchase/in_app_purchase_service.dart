import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_app/util/logger.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  DateTime? _lastPurchaseAttempt;
  static const _purchaseDebounceTime = Duration(seconds: 2);

  // 구매 완료 처리 상태를 추적하기 위한 Set
  final Set<String> _completingPurchases = {};

  void init(void Function(List<PurchaseDetails>) onPurchaseUpdate) {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) async {
        for (final purchase in purchaseDetailsList) {
          logger.i(
              'Purchase status updated: ${purchase.productID} -> ${purchase.status}');

          // 구매 완료 처리가 필요하고 아직 완료 처리 중이 아닌 경우에만 처리
          if (purchase.pendingCompletePurchase &&
              !_completingPurchases.contains(purchase.productID)) {
            await completePurchase(purchase);
          }
        }
        onPurchaseUpdate(purchaseDetailsList);
      },
      onError: (error) {
        logger.e('Purchase stream error', error: error);
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _completingPurchases.clear();
  }

  Future<bool> buyConsumable(ProductDetails productDetails) async {
    try {
      final now = DateTime.now();
      if (_lastPurchaseAttempt != null &&
          now.difference(_lastPurchaseAttempt!) < _purchaseDebounceTime) {
        logger.w('Purchase attempt debounced');
        return false;
      }
      _lastPurchaseAttempt = now;

      // 이미 완료 처리 중인 구매가 있는지 확인
      if (_completingPurchases.contains(productDetails.id)) {
        logger.w(
            'Purchase completion already in progress for ${productDetails.id}');
        return false;
      }

      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        logger.e('Store is not available');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool purchaseResult = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      logger.i('buyConsumable initiated with result: $purchaseResult');
      return purchaseResult;
    } catch (e, stack) {
      logger.e('Error in buyConsumable', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    // 이미 완료 처리 중인 경우 스킵
    if (_completingPurchases.contains(purchaseDetails.productID)) {
      logger.i(
          'Purchase completion already in progress for: ${purchaseDetails.productID}');
      return;
    }

    try {
      _completingPurchases.add(purchaseDetails.productID);
      await _inAppPurchase.completePurchase(purchaseDetails);
      logger.i('Purchase completed successfully: ${purchaseDetails.productID}');
    } catch (e, stack) {
      logger.e('Error completing purchase', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _completingPurchases.remove(purchaseDetails.productID);
    }
  }
}
