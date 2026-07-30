import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// What one enumeration of the store's unfinished transactions found.
///
/// An empty list and a failed query are different facts: the first means there
/// is nothing to recover, the second means we do not know yet and must ask
/// again on the next sweep. Collapsing them is how a charged-but-uncredited
/// purchase becomes invisible.
class UnfinishedPurchaseScan {
  const UnfinishedPurchaseScan({this.purchases = const [], this.error});

  /// Transactions the store still holds open, in the shape the verification
  /// path already accepts.
  final List<PurchaseDetails> purchases;

  /// Non-null when the enumeration itself failed.
  final Object? error;

  bool get isEmpty => purchases.isEmpty;
}

/// Enumerates the purchases a store still considers unfinished.
///
/// The two implementations are deliberately the same shape so that the one
/// reconcile loop in `PurchaseService` drives both platforms: Apple's guidance
/// is a transaction observer that lives for the whole app lifetime plus a sweep
/// of the payment queue, Google's is a `queryPurchasesAsync` reconcile. Those
/// are the same operation with different plumbing.
abstract interface class UnfinishedPurchaseSource {
  /// Short name used in logs, so a sweep report says which store answered.
  String get label;

  Future<UnfinishedPurchaseScan> scan();
}

/// Google Play: the purchases Play still holds because they were never
/// consumed.
class AndroidPastPurchaseSource implements UnfinishedPurchaseSource {
  const AndroidPastPurchaseSource();

  @override
  String get label => 'Android/queryPastPurchases';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    final addition = InAppPurchase.instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final resp = await addition.queryPastPurchases();
    return UnfinishedPurchaseScan(
      purchases: List<PurchaseDetails>.from(resp.pastPurchases),
      error: resp.error,
    );
  }
}

/// StoreKit: the transactions still sitting in `SKPaymentQueue` because nothing
/// has finished them.
///
/// This is the iOS half that did not exist. StoreKit re-delivers unfinished
/// transactions through `purchaseStream` when the queue observer is installed
/// (cold start), but it does nothing of the sort on a resume - so an Ask to Buy
/// approval, or a settlement that failed while the app was in the foreground,
/// had no path back until the next launch. Enumerating the queue gives that
/// path.
///
/// Only `purchased` is swept, and each exclusion is deliberate:
///
/// - `purchasing` has no payment yet and StoreKit's own documentation forbids
///   finishing it.
/// - `deferred` is an Ask to Buy request still awaiting a guardian. It becomes
///   `purchased` when approved, and only then is there money to settle.
/// - `failed` is not a charge; `InAppPurchaseService._clearIosPendingTransactions`
///   owns that cleanup.
/// - `restored` is excluded because it would be a *new* credit path. The app
///   receipt is scoped to the device, not to the signed-in account, so pushing
///   a restored transaction through verification could ask the server to settle
///   one account's purchase against whoever happens to be logged in now.
///   Unfinished `purchased` transactions carry no such risk - StoreKit already
///   re-delivers exactly those on cold start, so the sweep only closes the gap
///   between launches rather than opening a new door. Restored transactions also
///   never appear for consumables, which is everything we sell.
///
/// The receipt is the app receipt, which is what StoreKit 1 puts in
/// `serverVerificationData` for every purchase the plugin delivers - so a swept
/// transaction reaches the server in exactly the shape a live one does. That is
/// also why the receipt is read once, after the filter: it is the same bytes
/// for every transaction, and reading it is a platform round trip.
class IosPaymentQueueSource implements UnfinishedPurchaseSource {
  IosPaymentQueueSource({
    Future<List<SKPaymentTransactionWrapper>> Function()? readTransactions,
    Future<String> Function()? readReceipt,
  }) : _readTransactions =
           readTransactions ?? SKPaymentQueueWrapper().transactions,
       _readReceipt = readReceipt ?? SKReceiptManager.retrieveReceiptData;

  final Future<List<SKPaymentTransactionWrapper>> Function() _readTransactions;
  final Future<String> Function() _readReceipt;

  @override
  String get label => 'iOS/SKPaymentQueue';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    final transactions = await _readTransactions();
    final settleable = transactions
        .where(
          (t) =>
              t.transactionState == SKPaymentTransactionStateWrapper.purchased,
        )
        .toList();

    if (settleable.isEmpty) {
      if (transactions.isNotEmpty) {
        logger.i(
          'iOS 스윕: 큐에 ${transactions.length}건이 있으나 정산 대상(purchased)은 '
          '없음',
        );
      }
      return const UnfinishedPurchaseScan();
    }

    final receipt = await _readReceipt();
    if (receipt.isEmpty) {
      // 영수증 없이 검증을 보내면 서버는 그것을 영구 거부(422)로 답할 수
      // 있고, 그 판정이 큐에서 항목을 지운다. 모르는 상태로 남겨 다음
      // 스윕이 다시 시도하게 한다.
      return UnfinishedPurchaseScan(
        error: StateError(
          'iOS 앱 영수증을 읽을 수 없어 ${settleable.length}건의 미완료 '
          '트랜잭션을 검증에 보내지 않음',
        ),
      );
    }

    return UnfinishedPurchaseScan(
      purchases: settleable
          .map(
            (t) => AppStorePurchaseDetails.fromSKTransaction(t, receipt)
                as PurchaseDetails,
          )
          .toList(),
    );
  }
}

/// The source for the store this build is actually talking to, or null on a
/// host where there is no store (unit tests, desktop).
UnfinishedPurchaseSource? defaultUnfinishedPurchaseSource() {
  if (Platform.isAndroid) return const AndroidPastPurchaseSource();
  if (Platform.isIOS) return IosPaymentQueueSource();
  return null;
}
