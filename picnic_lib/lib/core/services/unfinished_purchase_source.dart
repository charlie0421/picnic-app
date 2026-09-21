import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart'
    hide kIAPSource;
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:picnic_lib/core/services/receipt_format_helper.dart';
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

/// StoreKit: the transactions nothing has finished yet.
///
/// StoreKit re-delivers unfinished transactions through `purchaseStream` when
/// the listener is installed (cold start), but it does nothing of the sort on
/// a resume - so an Ask to Buy approval, or a settlement that failed while the
/// app was in the foreground, had no path back until the next launch. This
/// enumeration gives that path.
///
/// **What is settled comes from StoreKit 2 only.** The plugin
/// (`in_app_purchase_storekit` 0.4.8+1) runs StoreKit 2 by default, so the live
/// path sends each transaction's JWS (`jwsRepresentation`), and verify-receipt
/// only accepts a three-part JWS. The previous revision swept the StoreKit 1
/// queue and sent the *app receipt* (dot-less base64): every such request was
/// answered 422 `APPLE_JWS_INVALID` and nothing was ever recovered
/// (PICNIC-2743). `SK2Transaction.unfinishedTransactions()` wraps native
/// `Transaction.unfinished`, which yields only *verified* transactions - the
/// plugin drops unverified ones silently - each carrying its own JWS.
///
/// A transaction is sent only when its JWS decodes to that same transaction
/// id and the id is one `SK2Transaction.finish` can parse. Anything else is
/// held in [UnfinishedPurchaseScan.unsettleableHeld] rather than dropped:
/// sending a missing or foreign JWS gets a permanent rejection, and dropping it
/// would make a queue that still holds a payment read as empty.
///
/// **The StoreKit 1 queue is read only for what StoreKit 2 cannot say.**
/// `purchasing`/`deferred` are the "payment is live right now" signal
/// (`liveInFlight`), which must survive so an empty settleable list is not read
/// as "nothing is happening". A `purchased` SK1 transaction that StoreKit 2 did
/// not return (an unverified one, typically) is held, for the same reason.
/// Nothing is ever settled from the SK1 queue: its only verification payload is
/// the device-scoped app receipt.
///
/// `restored` is never swept: it would be a *new* credit path that could
/// settle one account's purchase against whoever is logged in now, and it
/// never appears for consumables, which is everything we sell.
class IosPaymentQueueSource implements UnfinishedPurchaseSource {
  IosPaymentQueueSource({
    Future<List<SKPaymentTransactionWrapper>> Function()? readTransactions,
    Future<List<SK2Transaction>> Function()? readUnfinishedTransactions,
  }) : _readTransactions =
           readTransactions ?? SKPaymentQueueWrapper().transactions,
       _readUnfinishedTransactions =
           readUnfinishedTransactions ?? SK2Transaction.unfinishedTransactions;

  final Future<List<SKPaymentTransactionWrapper>> Function() _readTransactions;
  final Future<List<SK2Transaction>> Function() _readUnfinishedTransactions;

  @override
  String get label => 'iOS/SK2Transaction.unfinished';

  /// `purchasing`/`deferred` are counted separately rather than dropped.
  ///
  /// `failed` and `restored` are deliberately *not* counted as live: a failed
  /// transaction is a payment that already ended (that is exactly the cancel
  /// this app has to be able to clean up after), and `restored` never appears
  /// for consumables.
  static bool _isLiveInFlight(SKPaymentTransactionWrapper t) =>
      t.transactionState == SKPaymentTransactionStateWrapper.purchasing ||
      t.transactionState == SKPaymentTransactionStateWrapper.deferred;

  /// Whether [jws] is a transaction JWS for exactly [transactionId].
  ///
  /// Decoding the payload (rather than only counting dots) is what stops a
  /// transaction from being settled - and then finished - on another
  /// transaction's evidence.
  static bool _isJwsFor(String? jws, String transactionId) {
    if (jws == null || jws.isEmpty) return false;
    return ReceiptFormatHelper.appleTransactionIdFromJWS(jws) == transactionId;
  }

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    // SK1 first: a payment that moves purchasing -> purchased between the two
    // reads is then seen as live *and* as settleable - never as neither.
    final List<SKPaymentTransactionWrapper> queue;
    try {
      queue = await _readTransactions();
    } catch (e) {
      return UnfinishedPurchaseScan(error: e);
    }
    final liveInFlight = queue.where(_isLiveInFlight).length;

    final List<SK2Transaction> unfinished;
    try {
      unfinished = await _readUnfinishedTransactions();
    } catch (e) {
      // 조회 실패는 빈 큐가 아니다 - 다음 스윕이 다시 물어야 한다.
      return UnfinishedPurchaseScan(error: e, liveInFlight: liveInFlight);
    }

    final purchases = <PurchaseDetails>[];
    var held = 0;
    for (final t in unfinished) {
      final id = int.tryParse(t.id);
      final jws = t.receiptData;
      if (id == null || id <= 0 || !_isJwsFor(jws, t.id)) {
        held++;
        // JWS 자체는 로그에 남기지 않는다 - 결제 증빙이다.
        logger.w(
          'iOS 스윕: 검증에 보낼 수 없는 미완료 거래 보존 '
          '(${t.productId}, jws: ${jws == null || jws.isEmpty ? '없음' : '형식 불일치'})',
        );
        continue;
      }
      purchases.add(
        SK2PurchaseDetails(
          productID: t.productId,
          purchaseID: t.id,
          verificationData: PurchaseVerificationData(
            localVerificationData: t.jsonRepresentation ?? '',
            serverVerificationData: jws!,
            source: kIAPSource,
          ),
          transactionDate: t.purchaseDate,
          status: PurchaseStatus.purchased,
          appAccountToken: t.appAccountToken,
        ),
      );
    }

    // SK2 가 돌려주지 않은 purchased(대개 unverified) 는 보낼 수도 지울 수도
    // 없지만, 스토어가 들고 있으니 빈 큐가 아니다.
    final sk2Ids = unfinished.map((t) => t.id).toSet();
    final orphanedSk1 = queue
        .where(
          (t) =>
              t.transactionState ==
                  SKPaymentTransactionStateWrapper.purchased &&
              !sk2Ids.contains(t.transactionIdentifier),
        )
        .length;
    if (orphanedSk1 > 0) {
      logger.w('iOS 스윕: StoreKit 2 가 돌려주지 않은 purchased 거래 $orphanedSk1건 보존');
    }
    held += orphanedSk1;

    if (purchases.isEmpty && (queue.isNotEmpty || unfinished.isNotEmpty)) {
      logger.i(
        'iOS 스윕: 정산 대상 없음 (SK1 큐 ${queue.length}건, SK2 미완료 '
        '${unfinished.length}건, 진행 중 $liveInFlight건, 보존 $held건)',
      );
    }

    return UnfinishedPurchaseScan(
      purchases: purchases,
      liveInFlight: liveInFlight,
      unsettleableHeld: held,
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
