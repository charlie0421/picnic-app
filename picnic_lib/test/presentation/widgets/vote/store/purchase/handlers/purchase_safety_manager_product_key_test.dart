import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

/// The safety manager's per-product state is keyed by two different casings of
/// the same product: timers start with the Supabase catalog ID (STAR100,
/// `_handlePurchaseResult` in the store state) while settlement stops them with
/// the Play event's lowercase productID (star100, `PurchaseSettlementStep`).
/// On Android those differ, so without one canonical key a successful purchase
/// leaves its 90s safety timer alive - the user gets a "processing is taking
/// too long" popup a minute and a half after a purchase that already succeeded
/// - and `_activeProducts` keeps a ghost entry that blocks re-purchasing the
/// same product until app restart. iOS is unaffected only because both IDs are
/// uppercase there.
void main() {
  late PurchaseSafetyManager manager;

  setUp(() {
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
    );
  });

  test('safety timer started with the server ID is stopped by the '
      'store-cased settlement', () {
    fakeAsync((async) {
      var timeoutFired = false;
      var productTimeoutFired = false;
      manager.onTimeoutUIReset = () => timeoutFired = true;
      manager.onProductTimeout = (_, __) => productTimeoutFired = true;

      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'a1');
      manager.completePurchaseSession('star100');

      async.elapse(const Duration(seconds: 91));

      expect(timeoutFired, isFalse,
          reason: 'settled purchase must not raise the timeout popup');
      expect(productTimeoutFired, isFalse);
    });
  });

  test('active product registered with the server ID is released by the '
      'store-cased settlement', () {
    manager.recordPurchaseAttempt(productId: 'STAR100');
    manager.completePurchaseSession('star100');
    manager.clearProductCooldown('STAR100');

    expect(manager.canAttemptPurchase(), isTrue);
    expect(manager.canAttemptPurchaseForProduct('STAR100'), isTrue,
        reason: 'no ghost active-product entry may survive settlement');
  });

  test('cooldown recorded at settlement casing blocks an immediate '
      're-purchase asked for with the server casing', () {
    manager.recordPurchaseAttempt(productId: 'STAR100');
    manager.completePurchaseSession('star100');

    expect(manager.canAttemptPurchaseForProduct('STAR100'), isFalse,
        reason: 'the per-product cooldown must apply across ID casings');
  });
}
