import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';

/// Terminal-failure popup-noise regression (1.3.0 internal beta).
///
/// A purchase whose server settlement fails is shown an error dialog, but the
/// 90s per-product safety timer armed at launch used to stay alive: removing
/// only the attempt (`_removeAttempt`) leaves `_safetyTimersByProduct` armed,
/// so `onTimeoutUIReset` fires the "구매 처리 지연" popup after the user was
/// already told the purchase failed. The fixed `showMappedError` branch of
/// `_processActivePurchase` tears the product state down through
/// `_resetProductPurchaseState(..., terminal: true)` - mirrored by
/// [failTerminally] below - which stops that timer.
///
/// The genuinely-slow case must not change: an attempt that has seen no
/// terminal error still gets its one safety-timeout popup at 90s.
///
/// The collaborators are wired exactly the way
/// `PurchaseStarCandyState.initState` wires them.
void main() {
  const productId = 'STAR100';
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

  tearDown(() => manager.disposeSafetyTimer());

  /// Runs the production launch sequence up to the point where the store event
  /// has been bound and receipt verification is in flight.
  Future<void> launch(String product, String id) async {
    registry.begin(
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      ),
    );
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

  /// Mirrors the terminal branch of `_processActivePurchase`'s error handler:
  /// `_resetProductPurchaseState(eventProductId, attemptId: ..., terminal:
  /// true)` for a mapped error that ends the attempt. [eventProductId] is the
  /// store event's casing, which on Android differs from the catalog ID the
  /// timer was armed with.
  void failTerminally(String eventProductId, String id) {
    expect(
      PurchaseProcessor.isTerminalMappedError(
        PurchaseProcessor.mapErrorToType('SERVER'),
      ),
      isTrue,
      reason: 'a server settlement error is the terminal failure under test',
    );
    manager.resetProductState(eventProductId);
    registry.removeIfMatches(eventProductId, id);
  }

  testWidgets('no delay popup fires after a terminal settlement failure', (
    tester,
  ) async {
    await launch(productId, attemptId);

    failTerminally(productId, attemptId);

    await tester.pump(const Duration(seconds: 91));

    expect(
      timeoutMessages,
      0,
      reason:
          'the user was already shown the error dialog; the 90s safety timer '
          'must be cancelled with the attempt or it raises the delay popup '
          'again',
    );
    expect(registry.contains(productId), isFalse);
  });

  testWidgets('the timer armed with the catalog ID is cancelled by the '
      'store-cased failure event', (tester) async {
    await launch(productId, attemptId);

    // Android: the timer started with STAR100, the failing Play event carries
    // star100. The teardown must meet it through the canonical product key.
    failTerminally('star100', attemptId);

    await tester.pump(const Duration(seconds: 91));

    expect(timeoutMessages, 0);
    expect(registry.contains(productId), isFalse);
  });

  testWidgets('a purchase that is merely slow still gets exactly one delay '
      'popup', (tester) async {
    await launch(productId, attemptId);

    // No terminal error arrives - verification is simply still in flight.
    await tester.pump(const Duration(seconds: 91));

    expect(
      timeoutMessages,
      1,
      reason: 'the safety net for a still-alive attempt must keep working',
    );
    expect(
      registry.contains(productId),
      isFalse,
      reason: 'onProductTimeout releases the attempt when the net fires',
    );

    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1, reason: 'the net fires once, not repeatedly');
  });

  testWidgets('mapped timeout and network errors keep the attempt alive for '
      'a late settlement', (tester) async {
    // These are the still-pending flavors: the settlement may yet land, so the
    // attempt (and its safety net) must survive the error dialog.
    for (final code in ['TIMEOUT', 'NETWORK']) {
      expect(
        PurchaseProcessor.isTerminalMappedError(
          PurchaseProcessor.mapErrorToType(code),
        ),
        isFalse,
        reason: '$code must not tear the attempt down',
      );
    }

    await launch(productId, attemptId);
    // The widget performs no teardown for these errors...
    await tester.pump(const Duration(seconds: 91));
    // ...so the safety net still resolves the attempt exactly as today.
    expect(timeoutMessages, 1);
    expect(registry.contains(productId), isFalse);
  });
}
