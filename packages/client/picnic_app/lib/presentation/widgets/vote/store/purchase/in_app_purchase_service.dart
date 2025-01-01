import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:picnic_app/core/utils/logger.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  DateTime? _lastPurchaseAttempt;

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

      // iOS의 경우 pending 구매를 먼저 처리
      if (Platform.isIOS) {
        await _handlePendingPurchases();
      }

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
    } catch (e, s) {
      logger.e('Error handling pending purchases', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (Platform.isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      } else if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      } else {
        logger.w('Skipping completePurchase for unsupported platform/type');
      }
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

  /// 진행 중인 구매 트랜잭션을 정리합니다.
  Future<void> clearTransactions() async {
    try {
      // iOS의 경우만 restore 호출
      if (Platform.isIOS) {
        await _inAppPurchase.restorePurchases();
      }

      // pending 상태의 구매 목록 초기화
      _pendingPurchases.clear();
      _lastPurchaseAttempt = null;

      logger.i('Transactions cleared');
    } catch (e, s) {
      logger.e('Error clearing transactions', error: e, stackTrace: s);
      rethrow;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pendingPurchases.clear();
  }
}
