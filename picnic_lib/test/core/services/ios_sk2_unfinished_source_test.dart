import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';

/// PICNIC-2743 C-1: iOS 스윕이 StoreKit 1 앱 영수증(점 없는 base64)을 보내서
/// 서버 `verifyAppleJws` 가 매번 422 `APPLE_JWS_INVALID` 로 거부했다.
///
/// 앱은 `in_app_purchase_storekit 0.4.8+1`(StoreKit 2 기본)이라 정상 경로는
/// 트랜잭션 JWS 를 보낸다. 스윕도 같은 모양이어야 한다: 정산 대상은
/// `SK2Transaction.unfinishedTransactions()`(네이티브 `Transaction.unfinished`,
/// 검증된 것만)이고, 서버로 가는 값은 그 트랜잭션의 `jwsRepresentation` 이다.
///
/// SK1 큐는 정산 대상이 아니라 "지금 결제가 살아 있는가"(purchasing/deferred)
/// 를 알려주는 용도로만 남는다 - 그 신호를 잃으면 결제 시트 안에 있는 사용자의
/// 정상 결제가 "빈 큐"로 오독된다 (Sol 교차 리뷰 MAJOR, 2026-08-07).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String b64(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  /// verify-receipt-v2 가 받는 모양의 JWS: 점 3분할, 앞 두 조각은 base64url JSON.
  String jwsFor(String transactionId) =>
      '${b64({'alg': 'ES256'})}.'
      '${b64({'transactionId': transactionId, 'productId': 'STAR100'})}.'
      'c2lnbmF0dXJl';

  SK2Transaction sk2(
    String id, {
    String? jws,
    bool useDefaultJws = true,
    String productId = 'STAR100',
    String? appAccountToken = 'a3f7c1d2-0000-4000-8000-000000000001',
  }) => SK2Transaction(
    id: id,
    originalId: id,
    productId: productId,
    purchaseDate: '2026-09-20T12:00:00Z',
    appAccountToken: appAccountToken,
    receiptData: useDefaultJws ? (jws ?? jwsFor(id)) : jws,
    jsonRepresentation: '{"transactionId":"$id"}',
  );

  SKPaymentTransactionWrapper sk1(
    SKPaymentTransactionStateWrapper state, {
    String? id,
    String productId = 'STAR100',
  }) => SKPaymentTransactionWrapper(
    payment: SKPaymentWrapper(productIdentifier: productId),
    transactionState: state,
    transactionIdentifier: id,
  );

  IosPaymentQueueSource source({
    List<SKPaymentTransactionWrapper> queue = const [],
    List<SK2Transaction> unfinished = const [],
    Object? unfinishedError,
    Object? queueError,
  }) => IosPaymentQueueSource(
    readTransactions: () async {
      if (queueError != null) throw queueError;
      return queue;
    },
    readUnfinishedTransactions: () async {
      if (unfinishedError != null) throw unfinishedError;
      return unfinished;
    },
  );

  group('IosPaymentQueueSource (StoreKit 2)', () {
    test('an unfinished SK2 transaction is swept with its own JWS, byte for '
        'byte', () async {
      final jws = jwsFor('2000000123');
      final scan = await source(
        unfinished: [sk2('2000000123', jws: jws)],
      ).scan();

      expect(scan.error, isNull);
      expect(scan.purchases, hasLength(1));
      final purchase = scan.purchases.single;
      expect(
        purchase.verificationData.serverVerificationData,
        jws,
        reason: '서버 verifyAppleJws 는 점 3분할 JWS 만 받는다 - 앱 영수증을 '
            '보내면 매번 422 APPLE_JWS_INVALID 다',
      );
      expect(purchase.verificationData.source, kIAPSource);
      expect(purchase.productID, 'STAR100');
      expect(purchase.purchaseID, '2000000123');
      expect(purchase.status, PurchaseStatus.purchased);
    });

    test('the swept purchase is an SK2PurchaseDetails, so finish goes through '
        'SK2Transaction.finish with the transaction id', () async {
      final scan = await source(unfinished: [sk2('2000000123')]).scan();

      final purchase = scan.purchases.single;
      expect(
        purchase,
        isA<SK2PurchaseDetails>(),
        reason: 'StoreKit 2 모드의 completePurchase 는 purchaseID 를 int 로 '
            '파싱해 SK2Transaction.finish 로 보낸다',
      );
      expect(int.tryParse(purchase.purchaseID!), 2000000123);
      expect(purchase.pendingCompletePurchase, isTrue);
      expect(
        (purchase as SK2PurchaseDetails).appAccountToken,
        'a3f7c1d2-0000-4000-8000-000000000001',
        reason: '서버의 appAccountToken 소유자 검사가 그대로 적용돼야 한다',
      );
    });

    test('the StoreKit 1 app receipt is never what the sweep sends', () async {
      // purchased 가 SK1 큐에 있어도, 정산은 SK2 가 돌려준 JWS 로만 한다.
      final scan = await source(
        queue: [
          sk1(SKPaymentTransactionStateWrapper.purchased, id: '2000000123'),
        ],
        unfinished: [sk2('2000000123')],
      ).scan();

      expect(scan.purchases, hasLength(1));
      expect(
        scan.purchases.single.verificationData.serverVerificationData
            .split('.'),
        hasLength(3),
      );
      expect(
        scan.unsettleableHeld,
        0,
        reason: 'SK2 에서 JWS 로 정산되는 같은 거래를 SK1 큐에서 한 번 더 '
            '세면 안 된다',
      );
    });

    test('a transaction with no JWS is held, not dropped and not sent',
        () async {
      final scan = await source(
        unfinished: [sk2('2000000123', jws: null, useDefaultJws: false)],
      ).scan();

      expect(scan.purchases, isEmpty, reason: '빈 영수증은 서버가 영구 거부한다');
      expect(
        scan.unsettleableHeld,
        1,
        reason: '스토어가 들고 있는 거래를 조용히 버리면 "빈 큐"로 오독된다',
      );
    });

    test('an empty-string JWS is held like a missing one', () async {
      final scan = await source(
        unfinished: [sk2('2000000123', jws: '', useDefaultJws: false)],
      ).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.unsettleableHeld, 1);
    });

    test('a malformed JWS (the old app-receipt shape) is held', () async {
      final scan = await source(
        unfinished: [
          sk2('2000000123', jws: 'MIIT1AYJKoZIhvcNAQcCoIITxTCCE8ECAQEx'),
        ],
      ).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.unsettleableHeld, 1);
    });

    test('a JWS that belongs to a different transaction is held', () async {
      final scan = await source(
        unfinished: [sk2('2000000123', jws: jwsFor('2000000999'))],
      ).scan();

      expect(
        scan.purchases,
        isEmpty,
        reason: '다른 거래의 JWS 로 정산하고 이 거래를 finish 하면 결제가 소멸한다',
      );
      expect(scan.unsettleableHeld, 1);
    });

    test('a transaction id that cannot be finished is held', () async {
      final scan = await source(
        unfinished: [sk2('0', jws: jwsFor('0'))],
      ).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.unsettleableHeld, 1);
    });

    test('valid and unusable transactions are split, not all-or-nothing',
        () async {
      final scan = await source(
        unfinished: [
          sk2('2000000123'),
          sk2('2000000124', jws: 'not-a-jws'),
        ],
      ).scan();

      expect(scan.purchases.map((p) => p.purchaseID), ['2000000123']);
      expect(scan.unsettleableHeld, 1);
    });

    test('a failed SK2 enumeration is an error, never an empty queue',
        () async {
      final scan = await source(
        queue: [sk1(SKPaymentTransactionStateWrapper.purchasing)],
        unfinishedError: StateError('storekit unavailable'),
      ).scan();

      expect(scan.error, isNotNull);
      expect(scan.purchases, isEmpty);
      expect(scan.liveInFlight, 1, reason: '실패해도 본 것은 보고한다');
    });

    test('a failed SK1 queue read is an error too', () async {
      final scan = await source(
        queueError: StateError('queue unavailable'),
        unfinished: [sk2('2000000123')],
      ).scan();

      expect(scan.error, isNotNull);
    });

    test('SK1 purchasing/deferred stay live-in-flight and are never settled',
        () async {
      final scan = await source(
        queue: [
          sk1(SKPaymentTransactionStateWrapper.purchasing),
          sk1(SKPaymentTransactionStateWrapper.deferred),
          sk1(SKPaymentTransactionStateWrapper.failed),
          sk1(SKPaymentTransactionStateWrapper.restored, id: 'r-1'),
        ],
      ).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.liveInFlight, 2);
      expect(scan.unsettleableHeld, 0);
      expect(scan.error, isNull);
    });

    test('an SK1 purchased transaction that SK2 did not return is held - '
        'StoreKit drops unverified transactions silently', () async {
      final scan = await source(
        queue: [
          sk1(SKPaymentTransactionStateWrapper.purchased, id: '2000000555'),
        ],
      ).scan();

      expect(scan.purchases, isEmpty);
      expect(
        scan.unsettleableHeld,
        1,
        reason: '네이티브 unfinishedTransactions 는 unverified 를 버린다 - 큐가 '
            '들고 있는 결제를 "비었다"로 보고하면 안 된다',
      );
    });

    test('a genuinely empty store is an empty scan', () async {
      final scan = await source().scan();

      expect(scan.isEmpty, isTrue);
      expect(scan.error, isNull);
      expect(scan.liveInFlight, 0);
      expect(scan.unsettleableHeld, 0);
    });

    test('a held transaction keeps the sweep from reporting verifiedEmpty',
        () {
      const report = PurchaseSweepReport(
        trigger: PurchaseSweepTrigger.manual,
        outcome: PurchaseSweepOutcome.completed,
        unsettleableHeld: 1,
      );
      expect(report.verifiedEmpty, isFalse);
    });
  });
}
