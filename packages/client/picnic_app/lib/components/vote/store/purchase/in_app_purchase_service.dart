import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  DateTime? _lastPurchaseAttempt;
  static const _purchaseDebounceTime = Duration(seconds: 2);

  void init(void Function(List<PurchaseDetails>) onPurchaseUpdate) {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(onPurchaseUpdate);
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<bool> buyConsumable(ProductDetails productDetails) async {
    final now = DateTime.now();
    if (_lastPurchaseAttempt != null &&
        now.difference(_lastPurchaseAttempt!) < _purchaseDebounceTime) {
      return false; // Debounce: 2초 이내의 연속 구매 시도를 방지
    }
    _lastPurchaseAttempt = now;

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    await _inAppPurchase.completePurchase(purchaseDetails);
  }
}
