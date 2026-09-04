import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test(
      'a settleable transaction still reports a concurrent live one',
      () async {
        final scan = await sourceWith([
          txn('STAR100', SKPaymentTransactionStateWrapper.purchased),
          txn('STAR200', SKPaymentTransactionStateWrapper.purchasing),
        ]).scan();

        expect(scan.purchases.length, 1);
        expect(scan.liveInFlight, 1);
      },
    );

    test('the unreadable-receipt guard still reports what it saw', () async {
      final scan = await sourceWith([
        txn('STAR100', SKPaymentTransactionStateWrapper.purchased),
        txn('STAR200', SKPaymentTransactionStateWrapper.deferred),
      ], receipt: '').scan();

      expect(scan.error, isNotNull);
      expect(scan.liveInFlight, 1);
    });
  });

  group('AndroidPastPurchaseSource pending separation', () {
    test('pending is held but never settleable, and never "live"', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      InAppPurchase.instance;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });
      final originalAddition = InAppPurchasePlatformAddition.instance;
      addTearDown(() {
        InAppPurchasePlatformAddition.instance = originalAddition;
      });

      final pending = _googlePurchase(
        token: 'pending-token',
        state: PurchaseStateWrapper.pending,
      );
      final purchased = _googlePurchase(
        token: 'purchased-token',
        state: PurchaseStateWrapper.purchased,
      );
      final addition = _FakeAndroidAddition(
        QueryPurchaseDetailsResponse(pastPurchases: [pending, purchased]),
      );
      InAppPurchasePlatformAddition.instance = addition;

      final scan = await const AndroidPastPurchaseSource().scan();

      expect(scan.purchases, [same(purchased)]);
      expect(scan.pendingPurchases, [same(pending)]);
      // Play cannot report a billing flow the user is *inside*, so nothing is
      // live at this instant. A PENDING token is alive for up to three days;
      // counting it as liveInFlight made that field mean two different things.
      expect(scan.liveInFlight, 0);
      expect(scan.unsettleableHeld, 1);
    });

    test(
      'a state Play will not classify is held, not silently dropped',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        InAppPurchase.instance;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
        });
        final originalAddition = InAppPurchasePlatformAddition.instance;
        addTearDown(() {
          InAppPurchasePlatformAddition.instance = originalAddition;
        });

        // GooglePlayPurchaseDetails maps UNSPECIFIED_STATE to
        // PurchaseStatus.error. Before the pending split it landed in
        // `purchases`, so `found > 0` kept every "the queue was empty" caller
        // honest; it must not become invisible now.
        final unspecified = _googlePurchase(
          token: 'unspecified-token',
          state: PurchaseStateWrapper.unspecified_state,
        );
        final addition = _FakeAndroidAddition(
          QueryPurchaseDetailsResponse(pastPurchases: [unspecified]),
        );
        InAppPurchasePlatformAddition.instance = addition;

        final scan = await const AndroidPastPurchaseSource().scan();

        expect(scan.purchases, isEmpty);
        expect(scan.pendingPurchases, isEmpty);
        expect(scan.liveInFlight, 0);
        expect(scan.unsettleableHeld, 1);
      },
    );
  });

  group('PurchaseSweepReport.verifiedEmpty', () {
    PurchaseSweepReport report({
      int found = 0,
      int liveInFlight = 0,
      int unsettleableHeld = 0,
    }) => PurchaseSweepReport(
      trigger: PurchaseSweepTrigger.manual,
      outcome: PurchaseSweepOutcome.completed,
      unsettleableHeld: unsettleableHeld,
      found: found,
      liveInFlight: liveInFlight,
    );

    test('a completed sweep over an empty queue verifies empty', () {
      expect(report().verifiedEmpty, isTrue);
    });

    test('a completed sweep with nothing to settle but a live payment does not '
        'verify empty - this is the counterexample', () {
      expect(report(liveInFlight: 1).verifiedEmpty, isFalse);
    });

    test('found > 0 still blocks, as before', () {
      expect(report(found: 1).verifiedEmpty, isFalse);
    });

    test('a held-but-unsettleable transaction is not an empty queue', () {
      // Android PENDING and unclassifiable owned purchases: nothing to settle,
      // but the store is still holding something, so a caller must not read
      // this as "the queue was checked and was empty".
      expect(report(unsettleableHeld: 1).verifiedEmpty, isFalse);
    });
  });
}

class _FakeAndroidAddition implements InAppPurchaseAndroidPlatformAddition {
  _FakeAndroidAddition(this.response);

  final QueryPurchaseDetailsResponse response;

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases({
    String? applicationUserName,
  }) async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GooglePlayPurchaseDetails _googlePurchase({
  required String token,
  required PurchaseStateWrapper state,
}) => GooglePlayPurchaseDetails.fromPurchase(
  PurchaseWrapper(
    orderId: 'order-$token',
    packageName: 'com.example.picnic',
    purchaseTime: 1785228000000,
    purchaseToken: token,
    signature: 'signature',
    products: const ['STAR100'],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: state,
  ),
).single;
