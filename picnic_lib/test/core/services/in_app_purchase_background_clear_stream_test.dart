import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';

/// PICNIC-2743 C-3 ①: 구매 후 백그라운드 정리가 유일한 구매 스트림 구독을
/// 끊었다(`_backgroundCacheClear` 의 `_subscription.cancel()`).
///
/// 플러그인(`in_app_purchase_storekit` 0.4.8+1)의 구매 스트림은 broadcast
/// 컨트롤러이고, 리스너가 0이 되면 `onCancel` 에서
/// `SK2Transaction.stopListeningToTransactions()` 로 네이티브
/// `Transaction.updates` 태스크를 취소한다. 그 틈에 도착한 거래 업데이트
/// (Ask to Buy 승인, 이전 시도·다른 기기의 완료, 재전달)는 아무도 받지
/// 못한다. SK2 의 buyConsumable 은 결제 결과를 받은 뒤 반환하므로 정리는
/// 결과 이후에 예약된다 - 평범한 느린 결제가 반드시 이 틈에 걸린다는 뜻은
/// 아니고, 이 테스트는 틈 동안 도착하는 이벤트가 끊기지 않음만 고정한다.
///
/// 이 페이크는 그 플러그인 동작(리스너 0 → 네이티브 중지, 리스너 없는 동안
/// 이벤트 유실)을 그대로 흉내낸다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PluginLikePlatform platform;
  late List<List<PurchaseDetails>> delivered;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = _PluginLikePlatform();
    InAppPurchase.instance;
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    platform = _PluginLikePlatform();
    InAppPurchasePlatform.instance = platform;
    delivered = [];
    final service = InAppPurchaseService();
    service.dispose();
    service.initialize(delivered.add);
  });

  tearDown(() {
    InAppPurchaseService().dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test('the background cache clear never drops the only purchase stream '
      'subscription', () async {
    expect(platform.nativeStarts, 1);

    await InAppPurchaseService().backgroundCacheClear();

    expect(
      platform.nativeStops,
      0,
      reason: '리스너가 0이 되는 순간 플러그인은 네이티브 Transaction.updates '
          '를 멈춘다 - 그 사이 도착한 결제 완료는 유실된다',
    );
    expect(platform.listenerCount, 1);
  });

  test('a purchase that completes while the clear is running is delivered',
      () async {
    final purchased = PurchaseDetails(
      purchaseID: '2000000001',
      productID: 'STAR100',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'jws',
        source: 'app_store',
      ),
      transactionDate: '2026-09-20T12:00:00Z',
      status: PurchaseStatus.purchased,
    );
    // 정리가 제품 캐시를 무효화하는 도중(= 예전 코드가 구독을 끊어 둔 구간)
    // 에 결제가 끝난다.
    platform.onQuery = () => platform.emit([purchased]);

    await InAppPurchaseService().backgroundCacheClear();
    await Future<void>.delayed(Duration.zero);

    expect(
      delivered.expand((batch) => batch).map((p) => p.purchaseID),
      contains('2000000001'),
      reason: '5초 넘게 걸린 결제의 완료 이벤트가 정리 구간과 겹쳐도 핸들러에 '
          '도달해야 한다',
    );
  });

  test('the clear does not add a second delivery path either', () async {
    final before = InAppPurchaseService().purchaseStreamSubscriptions;

    await InAppPurchaseService().backgroundCacheClear();

    expect(
      InAppPurchaseService().purchaseStreamSubscriptions,
      before,
      reason: '구독을 다시 만들 이유가 없다 - 이중 구독은 이중 정산이다',
    );
    expect(platform.listenerCount, 1);
  });
}

class _PluginLikePlatform extends InAppPurchasePlatform {
  _PluginLikePlatform() {
    _controller = StreamController<List<PurchaseDetails>>.broadcast(
      onListen: () => nativeStarts++,
      onCancel: () => nativeStops++,
    );
  }

  late final StreamController<List<PurchaseDetails>> _controller;
  int nativeStarts = 0;
  int nativeStops = 0;
  void Function()? onQuery;

  int get listenerCount => nativeStarts - nativeStops;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    onQuery?.call();
    onQuery = null;
    return ProductDetailsResponse(productDetails: [], notFoundIDs: []);
  }
}
