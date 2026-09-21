import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';

/// PICNIC-2743 리뷰 MAJOR: 고정된 플러그인(0.4.8+1)의 StoreKit 2 `finish` 는
/// `Transaction.all` 에서 거래를 찾았을 때만 채널을 완료한다
/// (InAppPurchasePlugin+StoreKit2.swift `finish`). 스윕이 훑은 뒤 실시간
/// 경로가 같은 소비형 거래를 먼저 finish 하면, 스윕의 finish 는 거래를 못
/// 찾아 **영원히** 끝나지 않는다. 그걸 그대로 기다리면 스윕 진행 플래그가
/// 풀리지 않아 구매 게이트가 앱 재시작까지 멈춘다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = NeverFinishingPlatform();
    InAppPurchase.instance;
  });

  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  test('an iOS finish that never completes is reported as not finalized '
      'after a bounded wait', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final platform = NeverFinishingPlatform();
    InAppPurchasePlatform.instance = platform;

    fakeAsync((async) {
      bool? finalized;
      InAppPurchaseService()
          .finalizeSettledPurchase(settledPurchase())
          .then((value) => finalized = value);

      async.elapse(const Duration(seconds: 9));
      expect(finalized, isNull, reason: '정상적으로 느린 finish 는 기다린다');

      async.elapse(const Duration(seconds: 2));
      expect(
        finalized,
        isFalse,
        reason: '완료를 확인하지 못했으니 settled 가 아니다 - 거래는 보존으로 '
            '세고 다음 스윕이 다시 본다',
      );
      expect(platform.finishCalls, 1);
    });
  });

  test('a finish that completes in time is still finalized', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final platform = NeverFinishingPlatform(completes: true);
    InAppPurchasePlatform.instance = platform;

    fakeAsync((async) {
      bool? finalized;
      InAppPurchaseService()
          .finalizeSettledPurchase(settledPurchase())
          .then((value) => finalized = value);
      async.flushMicrotasks();

      expect(finalized, isTrue);
    });
  });
}

PurchaseDetails settledPurchase({String id = '2000000001'}) {
  final purchase = PurchaseDetails(
    purchaseID: id,
    productID: 'STAR100',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: 'jws',
      source: 'app_store',
    ),
    transactionDate: '2026-09-20T12:00:00Z',
    status: PurchaseStatus.purchased,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

/// The pinned plugin's SK2 `finish`: the channel never answers when the
/// transaction is no longer in `Transaction.all`.
class NeverFinishingPlatform extends InAppPurchasePlatform {
  NeverFinishingPlatform({this.completes = false});

  final bool completes;
  int finishCalls = 0;
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    finishCalls++;
    return completes ? Future<void>.value() : Completer<void>().future;
  }
}
