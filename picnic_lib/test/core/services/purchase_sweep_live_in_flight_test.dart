import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';

/// Sol 교차 리뷰 MAJOR (2026-08-07) 의 절반: **"정산 대상이 없다"와 "큐가
/// 비었다"는 다른 사실이다.**
///
/// iOS 스윕은 `purchasing`(사용자가 결제 시트/Face ID 프롬프트 안에 있음)과
/// `deferred`(Ask to Buy 승인 대기)를 정산 대상에서 뺀다 - 정산할 돈이 없고
/// StoreKit 이 finish 를 금지하기 때문이다. 그런데 두 상태 모두 **결제가
/// 살아 있다**는 뜻이라, 이걸 빈 큐로 보고하면 "큐가 비었으니 남은 상태는
/// 지워도 된다"는 판단이 진행 중인 정상 결제를 지운다.
void main() {
  SKPaymentTransactionWrapper txn(
    String productId,
    SKPaymentTransactionStateWrapper state,
  ) => SKPaymentTransactionWrapper(
    payment: SKPaymentWrapper(productIdentifier: productId),
    transactionState: state,
    transactionIdentifier: 'txn-$productId',
  );

  IosPaymentQueueSource sourceWith(
    List<SKPaymentTransactionWrapper> transactions, {
    String receipt = 'receipt',
  }) => IosPaymentQueueSource(
    readTransactions: () async => transactions,
    readReceipt: () async => receipt,
  );

  group('IosPaymentQueueSource.liveInFlight', () {
    test('a payment sheet the user is still inside is not an empty queue', () {
      return sourceWith([
        txn('STAR100', SKPaymentTransactionStateWrapper.purchasing),
      ]).scan().then((scan) {
        expect(
          scan.purchases,
          isEmpty,
          reason: 'purchasing has no money to settle and must not be finished',
        );
        expect(scan.liveInFlight, 1);
      });
    });

    test('an Ask to Buy request awaiting a guardian counts as live', () async {
      final scan = await sourceWith([
        txn('STAR100', SKPaymentTransactionStateWrapper.deferred),
      ]).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.liveInFlight, 1);
    });

    test(
      'a failed transaction is an ended payment, not a live one - that is '
      'exactly the cancel this app has to be able to clean up after',
      () async {
        final scan = await sourceWith([
          txn('STAR100', SKPaymentTransactionStateWrapper.failed),
        ]).scan();

        expect(scan.purchases, isEmpty);
        expect(scan.liveInFlight, 0);
      },
    );

    test('a genuinely empty queue reports nothing live', () async {
      final scan = await sourceWith(const []).scan();

      expect(scan.purchases, isEmpty);
      expect(scan.liveInFlight, 0);
      expect(scan.error, isNull);
    });

    test('a settleable transaction still reports a concurrent live one',
        () async {
      final scan = await sourceWith([
        txn('STAR100', SKPaymentTransactionStateWrapper.purchased),
        txn('STAR200', SKPaymentTransactionStateWrapper.purchasing),
      ]).scan();

      expect(scan.purchases.length, 1);
      expect(scan.liveInFlight, 1);
    });

    test('the unreadable-receipt guard still reports what it saw', () async {
      final scan = await sourceWith([
        txn('STAR100', SKPaymentTransactionStateWrapper.purchased),
        txn('STAR200', SKPaymentTransactionStateWrapper.deferred),
      ], receipt: '').scan();

      expect(scan.error, isNotNull);
      expect(scan.liveInFlight, 1);
    });
  });

  group('PurchaseSweepReport.verifiedEmpty', () {
    PurchaseSweepReport report({int found = 0, int liveInFlight = 0}) =>
        PurchaseSweepReport(
          trigger: PurchaseSweepTrigger.manual,
          outcome: PurchaseSweepOutcome.completed,
          found: found,
          liveInFlight: liveInFlight,
        );

    test('a completed sweep over an empty queue verifies empty', () {
      expect(report().verifiedEmpty, isTrue);
    });

    test(
      'a completed sweep with nothing to settle but a live payment does not '
      'verify empty - this is the counterexample',
      () {
        expect(report(liveInFlight: 1).verifiedEmpty, isFalse);
      },
    );

    test('found > 0 still blocks, as before', () {
      expect(report(found: 1).verifiedEmpty, isFalse);
    });
  });
}
