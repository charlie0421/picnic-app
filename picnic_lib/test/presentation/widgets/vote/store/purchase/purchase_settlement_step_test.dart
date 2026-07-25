import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_settlement_step.dart';

import 'recording_receipt_dialogs.dart';

/// The production safety manager with the settlement calls timestamped.
///
/// Every override still runs the real body, so the step is driven against real
/// safety state rather than a script. Recording is the only addition, and it is
/// what makes the documented order observable: nothing on the manager's public
/// surface distinguishes "completePurchaseSession ran" from "it ran second".
class _RecordingSafetyManager extends PurchaseSafetyManager {
  _RecordingSafetyManager({
    required super.loadingKey,
    required super.resetPurchaseState,
    required this.events,
  });

  final List<String> events;

  @override
  bool isLatePurchaseForProduct(String productId) {
    events.add('readLateness');
    return super.isLatePurchaseForProduct(productId);
  }

  @override
  void completePurchaseSession(String productId) {
    events.add('completePurchaseSession');
    super.completePurchaseSession(productId);
  }

  @override
  Future<void> performPostPurchaseCleanup({
    required String productId,
    required String transactionId,
    PurchaseDetails? completedPurchase,
  }) {
    events.add('performPostPurchaseCleanup');
    return super.performPostPurchaseCleanup(
      productId: productId,
      transactionId: transactionId,
      completedPurchase: completedPurchase,
    );
  }
}

/// The production attempt registry with `finish` timestamped.
class _RecordingRegistry extends PurchaseCampaignAttemptRegistry {
  _RecordingRegistry(this.events);

  final List<String> events;

  @override
  bool finish(PurchaseDetails purchase, String attemptId) {
    events.add('finish');
    return super.finish(purchase, attemptId);
  }
}

/// Late-purchase settlement, driven through the production settlement step.
///
/// The 90s safety net can fire while receipt verification is still running: the
/// user is told the purchase timed out, and the verified result lands later.
/// That settlement must be presented with the late-purchase explanation, not
/// with the plain receipt.
///
/// Unlike `purchase_late_settlement_test.dart`, which reads lateness itself and
/// therefore only pins `PurchaseSafetyManager`, these tests hand the whole
/// settlement to [PurchaseSettlementStep] and let it decide. The step performs
/// the reads and the teardown in production order, so the ordering constraints
/// the class documents are under test here, not just the predicate:
///
/// - lateness is read before `completePurchaseSession` and
///   `cleanupAllTimersOnSuccess` destroy the state it is derived from;
/// - the session is released, and the transaction recorded, before anything is
///   presented;
/// - the wallet is credited before the receipt claims it was, mounted or not;
/// - the attempt is not finished until the awaited receipt has been dismissed.
///
/// The collaborators below are wired exactly the way `PurchaseStarCandyState`
/// wires them: the manager and registry are the real objects, and the callbacks
/// stand in only for what is genuinely bound to the widget.
void main() {
  const productId = 'STAR100';
  const otherProductId = 'STAR500';
  const attemptId = 'attempt-1';
  const launchSucceeded = <String, dynamic>{
    'success': true,
    'wasCancelled': false,
  };

  late _RecordingRegistry registry;
  late _RecordingSafetyManager manager;
  late List<String> events;
  late int timeoutMessages;

  setUp(() {
    timeoutMessages = 0;
    events = [];
    registry = _RecordingRegistry(events);
    manager = _RecordingSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
      events: events,
    );
    manager.onTimeoutUIReset = () => timeoutMessages++;
    manager.onProductTimeout = (timedOutProduct, timedOutAttempt) {
      if (timedOutAttempt != null) {
        registry.removeIfMatches(timedOutProduct, timedOutAttempt);
      }
    };
  });

  PurchaseCampaignAttempt attemptFor(String product, String id) =>
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      );

  PurchaseDetails transactionFor(String product) => PurchaseDetails(
    productID: product,
    purchaseID: 'txn-$product',
    transactionDate: DateTime.utc(2027).millisecondsSinceEpoch.toString(),
    status: PurchaseStatus.purchased,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
  );

  PurchaseSettlementResultModel verified() => PurchaseSettlementResultModel(
    contractVersion: 'wallet.v1',
    operationId: 'operation',
    replayed: false,
    baseStarAmount: BigInt.from(100),
    baseBonusAmount: BigInt.zero,
    promotion: null,
    wallet: WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.from(100),
      bonus: BigInt.zero,
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: DateTime.utc(2026),
    ),
  );

  /// Runs the production launch sequence, then delivers the store event.
  ///
  /// Binding the transaction is what `_processPurchaseDetail` does before it
  /// reaches the settlement branch, and it happens while the safety timer is
  /// still running. Only receipt verification is slow afterwards - a store
  /// event that arrives after the timeout is rejected earlier as an orphan and
  /// never reaches the step.
  Future<void> launch(String product, String id) async {
    registry.begin(attemptFor(product, id));
    manager.recordPurchaseAttempt(productId: product);
    registry.applyLaunchResult(product, id, launchSucceeded);
    await manager.handlePurchaseResult(
      launchSucceeded,
      registry.contains(product),
      (_) async {},
      productId: product,
      attemptId: id,
    );
    expect(
      registry.bind(transactionFor(product))?.attemptId,
      id,
      reason: 'the store event must bind before verification is awaited',
    );
  }

  /// Hands the verified result to the production settlement step.
  ///
  /// `cleanupAllTimersOnSuccess` narrows what production injects.
  /// `PurchaseStarCandyState` passes `_cleanupAllTimersOnSuccess`, which is
  /// `PurchaseProcessor.cleanupAllTimersOnSuccess`: the manager call below plus
  /// `RestorePurchaseHandler.cleanupTimersOnPurchaseSuccess()` and
  /// `InAppPurchaseService.cleanupTimersOnPurchaseSuccess(productId)`, all three
  /// inside a try/catch.
  ///
  /// Only the manager call is reproduced here, deliberately:
  ///
  /// - It is the only one of the three whose effect the step can observe. It
  ///   clears `_safetyTimeoutTriggered`, which is exactly what makes a lateness
  ///   read moved below this point report every late purchase as plain. The
  ///   other two touch timers the step never reads.
  /// - Reproducing them faithfully means constructing a real `PurchaseService`,
  ///   which initialises StoreKit/Play, flushes the receipt queue and reaches
  ///   Supabase - the whole plugin stack, hung off an ordering test.
  ///
  /// The narrowing is safe in the direction that matters. Production's version
  /// cannot throw (`PurchaseProcessor.runTimerCleanupGuarded` swallows, and
  /// `purchase_processor_test.dart` pins that), so the step is entitled to treat
  /// this seam as a plain `void` call - which is all the stand-in below is.
  Future<
    ({
      int plain,
      int late,
      WalletSummaryModel? wallet,
      List<String> cleanedUpProducts,
      int hideLoadingCalls,
      int resetProductCalls,
      bool? attemptHeldDuringReceipt,
      bool? walletAppliedDuringReceipt,
    })
  >
  settle(
    WidgetTester tester,
    String product,
    String id, {
    bool isMounted = true,
  }) async {
    WalletSummaryModel? appliedWallet;
    final cleanedUpProducts = <String>[];
    var hideLoadingCalls = 0;
    var resetProductCalls = 0;
    bool? attemptHeldDuringReceipt;
    bool? walletAppliedDuringReceipt;

    final dialogs = RecordingReceiptDialogs(
      whilePresenting: () async {
        events.add('receipt');
        // What a second tap on the tile behind the receipt would see: both
        // `_canPurchase` and `_handlePurchase` gate on
        // `_purchaseAttempts.contains(productId)`.
        attemptHeldDuringReceipt = registry.contains(product);
        walletAppliedDuringReceipt = appliedWallet != null;
      },
    );

    final settling = const PurchaseSettlementStep().settle(
      safetyManager: manager,
      attempts: registry,
      purchaseDetails: transactionFor(product),
      result: verified(),
      attempt: attemptFor(product, id),
      cleanupAllTimersOnSuccess: (cleanedProduct) {
        events.add('cleanupAllTimersOnSuccess');
        cleanedUpProducts.add(cleanedProduct);
        manager.cleanupAllTimersOnSuccess();
      },
      applyWalletSummary: (wallet) {
        events.add('applyWalletSummary');
        appliedWallet = wallet;
      },
      isMounted: () => isMounted,
      resetProductPurchaseState: (resetProduct) {
        resetProductCalls++;
        manager.resetProductState(resetProduct);
      },
      hideLoading: () => hideLoadingCalls++,
      receiptDialogs: dialogs,
    );

    // The step awaits PurchaseSafetyManager.performPostPurchaseCleanup, which
    // delays before handing control back. Let fake time run it out.
    await tester.pump(const Duration(seconds: 1));
    await settling;

    return (
      plain: dialogs.plainReceipts,
      late: dialogs.lateReceipts,
      wallet: appliedWallet,
      cleanedUpProducts: cleanedUpProducts,
      hideLoadingCalls: hideLoadingCalls,
      resetProductCalls: resetProductCalls,
      attemptHeldDuringReceipt: attemptHeldDuringReceipt,
      walletAppliedDuringReceipt: walletAppliedDuringReceipt,
    );
  }

  testWidgets('purchase verified after its safety timeout settles as late', (
    tester,
  ) async {
    await launch(productId, attemptId);

    // Receipt verification is still running when the 90s safety net fires and
    // the user is shown the timeout message.
    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1, reason: 'safety timeout must have fired');

    final presented = await settle(tester, productId, attemptId);

    expect(
      presented.late,
      1,
      reason: 'a purchase settled after its own timeout must explain the delay',
    );
    expect(presented.plain, 0);
    expect(
      presented.wallet,
      isNotNull,
      reason: 'a late settlement still credits the wallet',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('purchase verified inside the safety window settles as plain', (
    tester,
  ) async {
    await launch(productId, attemptId);
    await tester.pump(const Duration(seconds: 10));
    expect(timeoutMessages, 0);

    final presented = await settle(tester, productId, attemptId);

    expect(presented.plain, 1);
    expect(presented.late, 0);
    expect(presented.wallet, isNotNull);

    manager.disposeSafetyTimer();
  });

  testWidgets('another product timing out does not make this one late', (
    tester,
  ) async {
    await launch(otherProductId, 'attempt-other');
    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1);

    await launch(productId, attemptId);
    final presented = await settle(tester, productId, attemptId);

    expect(
      presented.plain,
      1,
      reason: 'lateness is per product, not a global flag',
    );
    expect(presented.late, 0);

    manager.disposeSafetyTimer();
  });

  testWidgets('settlement runs every step the class documents, in order', (
    tester,
  ) async {
    await launch(productId, attemptId);
    final presented = await settle(tester, productId, attemptId);

    expect(events, [
      'readLateness',
      'completePurchaseSession',
      'cleanupAllTimersOnSuccess',
      'performPostPurchaseCleanup',
      'applyWalletSummary',
      'receipt',
      'finish',
    ]);
    expect(
      presented.cleanedUpProducts,
      [productId],
      reason:
          'InAppPurchaseService.cleanupTimersOnPurchaseSuccess is keyed by '
          'product, so the settled product id must be forwarded',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('the attempt keeps blocking a second tap until the receipt is '
      'dismissed', (tester) async {
    await launch(productId, attemptId);
    final presented = await settle(tester, productId, attemptId);

    expect(
      presented.attemptHeldDuringReceipt,
      isTrue,
      reason:
          'a tap behind the receipt must reach showPurchaseAlreadyPendingDialog; '
          'finishing the attempt first leaves only the per-product cooldown '
          'between the user and a second charge',
    );
    expect(
      registry.contains(productId),
      isFalse,
      reason: 'the attempt is released once the receipt has been dismissed',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('the wallet is credited before the receipt reports the balance', (
    tester,
  ) async {
    await launch(productId, attemptId);
    final presented = await settle(tester, productId, attemptId);

    expect(
      presented.walletAppliedDuringReceipt,
      isTrue,
      reason:
          'the receipt renders the granted amount against walletSummaryProvider, '
          'which must already hold the post-purchase balance',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('settling a purchase releases the session for the next one', (
    tester,
  ) async {
    await launch(productId, attemptId);
    expect(
      manager.canAttemptPurchase(),
      isFalse,
      reason: 'the launch holds the purchase session',
    );

    await settle(tester, productId, attemptId);

    expect(
      manager.canAttemptPurchase(),
      isTrue,
      reason:
          'without completePurchaseSession _isPurchaseInProgress stays true and '
          'every later purchase in the session is blocked',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('the settled transaction is recorded so a redelivery is not '
      'charged again', (tester) async {
    await launch(productId, attemptId);
    await settle(tester, productId, attemptId);

    expect(
      manager.isActualPurchase(
        purchaseDetails: transactionFor(productId),
        isActivePurchasing: false,
        pendingProductId: null,
      ),
      isFalse,
      reason:
          'performPostPurchaseCleanup records the real transaction id; without '
          'it the store redelivering the same transaction is taken for a fresh '
          'purchase',
    );

    manager.disposeSafetyTimer();
  });

  testWidgets('a receipt verified after the user leaves the store still '
      'credits the wallet', (tester) async {
    await launch(productId, attemptId);

    final presented = await settle(
      tester,
      productId,
      attemptId,
      isMounted: false,
    );

    expect(
      presented.wallet,
      isNotNull,
      reason:
          'the candy was granted server-side when the receipt verified; leaving '
          'the store must not leave walletSummaryProvider on the old balance',
    );
    expect(
      presented.plain + presented.late,
      0,
      reason: 'there is no store on screen to present a receipt to',
    );
    expect(presented.hideLoadingCalls, 0);
    expect(presented.resetProductCalls, 0);
    expect(
      registry.contains(productId),
      isFalse,
      reason:
          'the attempt must be released with nothing to present to, or the '
          'product stays locked for the rest of the session',
    );
    expect(events, [
      'readLateness',
      'completePurchaseSession',
      'cleanupAllTimersOnSuccess',
      'performPostPurchaseCleanup',
      'applyWalletSummary',
      'finish',
    ]);

    manager.disposeSafetyTimer();
  });
}
