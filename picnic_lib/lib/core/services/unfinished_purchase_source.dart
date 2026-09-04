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
  const UnfinishedPurchaseScan({
    this.purchases = const [],
    this.pendingPurchases = const [],
    this.error,
    this.liveInFlight = 0,
    this.unsettleableHeld = 0,
  });

  /// Transactions the store still holds open, in the shape the verification
  /// path already accepts.
  final List<PurchaseDetails> purchases;

  /// Android purchases that Play still reports as PENDING. They are alive but
  /// not settleable: callers may durably intake the token behind a remote
  /// capability gate, but must never verify through the purchased path or
  /// acknowledge/consume them.
  final List<PurchaseDetails> pendingPurchases;

  /// Non-null when the enumeration itself failed.
  final Object? error;

  /// Transactions the store is holding that are **not settleable yet because a
  /// payment is still live** - iOS `purchasing` (the user is inside the payment
  /// sheet / Face ID prompt) and `deferred` (Ask to Buy awaiting a guardian).
  ///
  /// [purchases] deliberately excludes these: there is no money to settle and
  /// StoreKit forbids finishing them. But "nothing to settle" is not "nothing
  /// is happening", and a caller that is deciding whether some *other* state
  /// may be discarded has to know the difference. Without this count an empty
  /// [purchases] reads as "the queue was empty", which is exactly what the
  /// queue looks like while the user is still staring at the payment sheet
  /// (Sol 교차 리뷰 MAJOR, 2026-08-07).
  final int liveInFlight;

  /// Transactions the store **holds but we can neither settle nor dismiss**,
  /// and which are not a payment the user is inside right now: Android
  /// PENDING (a deferred instrument the user has not paid yet, alive for up
  /// to three days) and any owned purchase whose state the store will not
  /// classify (`PurchaseStatus.error`, e.g. Play's UNSPECIFIED_STATE).
  ///
  /// Kept apart from [liveInFlight] deliberately. `liveInFlight` means "a
  /// payment is live at this instant"; a three-day cash payment is a
  /// different fact and folding it in makes that field lie. Both must be
  /// zero before a caller may treat the queue as having been empty, because
  /// in both cases the store is still holding something.
  final int unsettleableHeld;

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

  /// `queryPurchases` answers with owned purchases, so a slow payment already
  /// accepted by Play arrives as a `pending` [PurchaseDetails]. It is exposed
  /// separately through [UnfinishedPurchaseScan.pendingPurchases] and counted
  /// in `unsettleableHeld` - NOT `liveInFlight`, which means a payment the
  /// user is inside right now; it must not enter the settleable `purchases`
  /// list.
  ///
  /// A billing flow the user is merely *inside* is still invisible to every
  /// query Play offers: the flow runs in Play's own activity, and nothing is
  /// owned until it completes. So while the user stares at the payment sheet
  /// this scan can report an empty queue with `liveInFlight == 0` -
  /// indistinguishable from "nothing is happening".
  ///
  /// An earlier revision of this comment claimed the in-flight case could not
  /// be concurrent with a scan, because Play refuses a second billing flow.
  /// That is wrong: Play refuses a second *flow*, not a *query*, and the
  /// purchase stream keeps delivering while the app is paused - so a delayed
  /// event from an earlier attempt can trigger a sweep in the middle of a live
  /// payment (Sol 3차 재검증 #2).
  ///
  /// Callers must therefore never read an empty Android scan as proof that a
  /// registered attempt is dead. The evidence that closes this gap is lifecycle
  /// state, not the queue - see
  /// [PurchaseCampaignAttemptRegistry.cancellationCandidates].
  @override
  Future<UnfinishedPurchaseScan> scan() async {
    final addition = InAppPurchase.instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final resp = await addition.queryPastPurchases();
    final all = List<PurchaseDetails>.from(resp.pastPurchases);
    final pending = all
        .where((purchase) => purchase.status == PurchaseStatus.pending)
        .toList(growable: false);
    // Anything Play returns that is neither settleable nor PENDING is a state
    // this code cannot classify (GooglePlayPurchaseDetails maps Play's
    // UNSPECIFIED_STATE to PurchaseStatus.error). It must not vanish from the
    // scan: before the pending split it landed in `purchases`, so `found > 0`
    // kept every "the queue was empty" caller honest. Dropping it silently
    // would let the 90s safety net report a verified-empty queue while Play
    // holds an owned, unresolved purchase.
    final unclassified = all
        .where(
          (purchase) =>
              purchase.status != PurchaseStatus.purchased &&
              purchase.status != PurchaseStatus.pending,
        )
        .toList(growable: false);
    if (unclassified.isNotEmpty) {
      // Nothing in this app can retire such a row: it is not settleable, so
      // the sweep never verifies it, and unlike a PENDING token Play has no
      // three-day window that resolves it. It therefore keeps
      // PurchaseSweepReport.verifiedEmpty false for as long as Play keeps
      // reporting it, which holds the 90s "nothing happened" suppression off
      // indefinitely. That direction is deliberate - a queue holding an owned
      // purchase is not an empty queue - but it must be observable rather
      // than silent, because no code path here will ever clear it.
      logger.w(
        '🛑 Play 가 상태를 분류하지 않는 보유 구매 ${unclassified.length}건 - '
        '정산 대상도 대기도 아니라 스스로 해소되지 않는다: '
        '${unclassified.map((purchase) => purchase.productID).join(', ')}',
      );
    }
    return UnfinishedPurchaseScan(
      purchases: all
          .where((purchase) => purchase.status == PurchaseStatus.purchased)
          .toList(growable: false),
      pendingPurchases: pending,
      error: resp.error,
      // Play cannot report a billing flow the user is *inside*; nothing here
      // is live at this instant.
      liveInFlight: 0,
      unsettleableHeld: pending.length + unclassified.length,
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

  /// `purchasing`/`deferred` are counted separately rather than dropped.
  ///
  /// `failed` and `restored` are deliberately *not* counted as live: a failed
  /// transaction is a payment that already ended (that is exactly the cancel
  /// this app has to be able to clean up after), and `restored` never appears
  /// for consumables.
  static bool _isLiveInFlight(SKPaymentTransactionWrapper t) =>
      t.transactionState == SKPaymentTransactionStateWrapper.purchasing ||
      t.transactionState == SKPaymentTransactionStateWrapper.deferred;

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    final transactions = await _readTransactions();
    final settleable = transactions
        .where(
          (t) =>
              t.transactionState == SKPaymentTransactionStateWrapper.purchased,
        )
        .toList();
    final liveInFlight = transactions.where(_isLiveInFlight).length;

    if (settleable.isEmpty) {
      if (transactions.isNotEmpty) {
        logger.i(
          'iOS 스윕: 큐에 ${transactions.length}건이 있으나 정산 대상(purchased)은 '
          '없음 (진행 중 $liveInFlight건)',
        );
      }
      return UnfinishedPurchaseScan(liveInFlight: liveInFlight);
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
        liveInFlight: liveInFlight,
      );
    }

    return UnfinishedPurchaseScan(
      purchases: settleable
          .map(
            (t) =>
                AppStorePurchaseDetails.fromSKTransaction(t, receipt)
                    as PurchaseDetails,
          )
          .toList(),
      liveInFlight: liveInFlight,
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
