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
      manager.onTimeoutUIReset = (_) => timeoutFired = true;
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

  test('a cooldown armed at settlement casing blocks a re-purchase asked for '
      'with the server casing', () {
    // 명시적 쿨다운(정산 미확정 / 지급 미확정 중복)만 재구매를 막는다. 정산이
    // 끝난 구매는 막지 않는다 - 그 차단이 "이전 결제가 스토어에서 처리 중입니다"
    // 라는 거짓 안내로 정상적인 연속 구매를 막았다.
    manager.recordPurchaseAttempt(productId: 'STAR100');
    manager.activateDuplicateCooldown(
      productId: 'star100',
      cooldown: const Duration(minutes: 1),
    );

    expect(manager.canAttemptPurchaseForProduct('STAR100'), isFalse,
        reason: 'the per-product cooldown must apply across ID casings');
  });

  test('a settled purchase leaves the same product immediately buyable', () {
    manager.recordPurchaseAttempt(productId: 'STAR100');
    manager.completePurchaseSession('star100');

    expect(manager.canAttemptPurchaseForProduct('STAR100'), isTrue,
        reason: '소비형 상품의 연속 구매는 정상 동작이다 - 이미 적립까지 끝난 '
            '결제를 근거로 막으면 사용자는 거짓 "처리 중" 안내를 받는다 '
            '(1.3.0 TestFlight patch 8)');
  });
}
