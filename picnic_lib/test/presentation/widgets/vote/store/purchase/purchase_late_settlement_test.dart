import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

import 'recording_receipt_dialogs.dart';

/// Late-purchase settlement regression.
///
/// The 90s safety net can fire while receipt verification is still running: the
/// user is told the purchase timed out, and the verified result lands later.
/// That settlement must be presented with the late-purchase explanation, not
/// with the plain receipt.
///
/// The collaborators below are wired exactly the way
/// `PurchaseStarCandyState.initState` wires them.
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

  /// Runs the production launch sequence up to the point where the store event
  /// has been bound and receipt verification is in flight.
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
  }

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

  /// Mirrors the settlement branch of `_processActivePurchase`.
  Future<({int plain, int late})> settle(String product, String id) async {
    final dialogs = RecordingReceiptDialogs();
    await const PurchaseSettlementPresentation().present(
      result: verified(),
      attempt: attemptFor(product, id),
      isLate: manager.isLatePurchaseForProduct(product),
      dialogs: dialogs,
    );
    return (plain: dialogs.plainReceipts, late: dialogs.lateReceipts);
  }

  testWidgets('purchase verified after its safety timeout settles as late', (
    tester,
  ) async {
    await launch(productId, attemptId);

    // Receipt verification is still running when the 90s safety net fires and
    // the user is shown the timeout message.
    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1, reason: 'safety timeout must have fired');

    final presented = await settle(productId, attemptId);

    expect(
      presented.late,
      1,
      reason: 'a purchase settled after its own timeout must explain the delay',
    );
    expect(presented.plain, 0);

    manager.disposeSafetyTimer();
  });

  testWidgets('purchase verified inside the safety window settles as plain', (
    tester,
  ) async {
    await launch(productId, attemptId);
    await tester.pump(const Duration(seconds: 10));
    expect(timeoutMessages, 0);

    final presented = await settle(productId, attemptId);

    expect(presented.plain, 1);
    expect(presented.late, 0);

    manager.disposeSafetyTimer();
  });

  testWidgets('another product timing out does not make this one late', (
    tester,
  ) async {
    await launch(otherProductId, 'attempt-other');
    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1);

    await launch(productId, attemptId);
    final presented = await settle(productId, attemptId);

    expect(
      presented.plain,
      1,
      reason: 'lateness is per product, not a global flag',
    );
    expect(presented.late, 0);

    manager.disposeSafetyTimer();
  });
}
