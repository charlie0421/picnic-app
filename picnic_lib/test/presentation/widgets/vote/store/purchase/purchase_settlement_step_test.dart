import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_settlement_step.dart';

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
/// the reads and the teardown in production order, so the ordering constraint -
/// lateness must be read before `completePurchaseSession` and
/// `cleanupAllTimersOnSuccess` destroy the state it is derived from - is under
/// test here, not just the predicate.
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

  late PurchaseCampaignAttemptRegistry registry;
  late PurchaseSafetyManager manager;
  late int timeoutMessages;

  setUp(() {
    timeoutMessages = 0;
    registry = PurchaseCampaignAttemptRegistry();
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
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
  /// `cleanupAllTimersOnSuccess` mirrors `PurchaseStarCandyState`, whose
  /// `PurchaseProcessor.cleanupAllTimersOnSuccess` calls straight through to
  /// the manager. That call clears the triggered safety timeout, so wiring it
  /// faithfully is what makes a mis-ordered read observable.
  Future<({int plain, int late, WalletSummaryModel? wallet})> settle(
    WidgetTester tester,
    String product,
    String id,
  ) async {
    var plainReceipts = 0;
    var lateReceipts = 0;
    WalletSummaryModel? appliedWallet;

    final settling = const PurchaseSettlementStep().settle(
      safetyManager: manager,
      attempts: registry,
      purchaseDetails: transactionFor(product),
      result: verified(),
      attempt: attemptFor(product, id),
      cleanupAllTimersOnSuccess: (_) => manager.cleanupAllTimersOnSuccess(),
      applyWalletSummary: (wallet) => appliedWallet = wallet,
      isMounted: () => true,
      resetProductPurchaseState: manager.resetProductState,
      hideLoading: () {},
      showSuccess: (_, _) async => plainReceipts++,
      showLateSuccess: (_, _) async => lateReceipts++,
    );

    // The step awaits PurchaseSafetyManager.performPostPurchaseCleanup, which
    // delays before handing control back. Let fake time run it out.
    await tester.pump(const Duration(seconds: 1));
    await settling;

    return (plain: plainReceipts, late: lateReceipts, wallet: appliedWallet);
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

  testWidgets('settled attempt is released so the product can be bought again', (
    tester,
  ) async {
    await launch(productId, attemptId);
    await settle(tester, productId, attemptId);

    expect(
      registry.contains(productId),
      isFalse,
      reason: 'the step must finish the attempt it settled',
    );

    manager.disposeSafetyTimer();
  });
}
