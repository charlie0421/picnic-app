import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_app/util/logger.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  DateTime? _lastPurchaseAttempt;
  static const _purchaseDebounceTime = Duration(seconds: 2);

  // 진행 중인 구매 추적
  final Set<String> _pendingPurchases = {};

  Future<bool> buyConsumable(ProductDetails productDetails) async {
    try {
      final now = DateTime.now();
      // 디바운스 시간 증가
      if (_lastPurchaseAttempt != null &&
          now.difference(_lastPurchaseAttempt!) < Duration(seconds: 3)) {
        logger.w('Purchase attempt debounced');
        return false;
      }

      // 진행 중인 구매가 있는지 확인
      if (_pendingPurchases.contains(productDetails.id)) {
        logger.w('Purchase already in progress for ${productDetails.id}');
        return false;
      }

      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        logger.e('Store is not available');
        return false;
      }

      // 이전에 완료되지 않은 구매가 있는지 확인하고 처리
      await _handlePendingPurchases();

      _lastPurchaseAttempt = now;
      _pendingPurchases.add(productDetails.id);

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool purchaseResult = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      logger.i('buyConsumable initiated with result: $purchaseResult');

      if (!purchaseResult) {
        _pendingPurchases.remove(productDetails.id);
      }

      return purchaseResult;
    } catch (e, stack) {
      logger.e('Error in buyConsumable', error: e, stackTrace: stack);
      _pendingPurchases.remove(productDetails.id);
      return false;
    }
  }

  // 완료되지 않은 구매 처리
  Future<void> _handlePendingPurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      logger.e('Error handling pending purchases', error: e);
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      await _inAppPurchase.completePurchase(purchaseDetails);
      _pendingPurchases.remove(purchaseDetails.productID);
      logger.i('Purchase completed successfully: ${purchaseDetails.productID}');
    } catch (e, stack) {
      logger.e('Error completing purchase', error: e, stackTrace: stack);
      rethrow;
    }
  }

  void init(void Function(List<PurchaseDetails>) onPurchaseUpdate) {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) async {
        for (final purchase in purchaseDetailsList) {
          logger.i(
              'Purchase status updated: ${purchase.productID} -> ${purchase.status}');

          // 구매가 취소되면 pending 상태 제거 및 딜레이 추가
          if (purchase.status == PurchaseStatus.canceled) {
            _pendingPurchases.remove(purchase.productID);
            // 취소 상태 처리를 위한 딜레이
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }

          if (purchase.pendingCompletePurchase) {
            await completePurchase(purchase);
          }
        }
        onPurchaseUpdate(purchaseDetailsList);
      },
      onError: (error) {
        logger.e('Purchase stream error', error: error);
      },
    );

    // 초기화시 pending 구매 처리
    _handlePendingPurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _pendingPurchases.clear();
  }
}
