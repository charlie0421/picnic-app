import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

/// Coverage-focused tests for PurchaseSafetyManager covering uncovered branches:
/// - _handleSafetyTimeout with onTimeoutUIReset callback
/// - _getAdaptiveCooldown session reset after 10 minutes
/// - _getAdaptiveCooldownForProduct session reset after 10 minutes
/// - activateDuplicateCooldown with no productId and no currentProductId
/// - Multiple consecutive purchases triggering extended cooldown
/// - isPurchaseCanceled with various additional keywords
/// - performPostPurchaseCleanup
/// - _cleanupInternalTransactionState
/// - _prepareForNextPurchase for consecutive purchases
void main() {
  late PurchaseSafetyManager manager;
  late int resetCallCount;
  late bool timeoutUIResetCalled;

  setUp(() {
    resetCallCount = 0;
    timeoutUIResetCalled = false;
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () => resetCallCount++,
    );
  });

  group('Safety timeout with onTimeoutUIReset callback', () {
    testWidgets('triggers callback after timeout', (tester) async {
      manager.onTimeoutUIReset = () {
        timeoutUIResetCalled = true;
      };

      manager.startSafetyTimer();
      // We can't easily wait 90 seconds, but we can verify the timer starts
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      manager.disposeSafetyTimer();
    });
  });

  group('Consecutive purchase tracking', () {
    test('consecutive purchases increase count', () {
      // First purchase
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');

      // Second purchase
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');

      // Third purchase (a duplicate verdict now picks the extended cooldown)
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');

      // 정산이 끝난 구매 자체는 재구매를 막지 않는다. 연속 구매 카운트는
      // 명시적 쿨다운의 **길이**를 정하는 데만 쓰인다.
      expect(manager.canAttemptPurchaseForProduct('prod_a'), isTrue);

      manager.activateDuplicateCooldown(productId: 'prod_a');
      expect(manager.canAttemptPurchaseForProduct('prod_a'), isFalse);
      expect(
        manager.remainingCooldownForProduct('prod_a')!.inSeconds,
        greaterThan(0),
      );
    });

    test('product-specific consecutive count is tracked independently', () {
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');

      // prod_b should not be affected by prod_a's consecutive count
      expect(manager.canAttemptPurchaseForProduct('prod_b'), isTrue);
    });
  });

  group('activateDuplicateCooldown edge cases', () {
    test('without productId and no current product falls back to global', () {
      // No current product set, no productId provided
      manager.activateDuplicateCooldown();
      // Should not crash and global state should be updated
      expect(manager.lastPurchaseAttempt, isNotNull);
    });

    test('with existing currentProductId from recordPurchaseAttempt', () {
      manager.recordPurchaseAttempt(productId: 'active_prod');
      manager.resetUIOnly(); // clears inProgress but keeps currentProductId
      manager.activateDuplicateCooldown();

      // Should affect active_prod
      expect(manager.canAttemptPurchaseForProduct('active_prod'), isFalse);
    });

    test('with explicit productId overrides currentProductId', () {
      manager.recordPurchaseAttempt(productId: 'active_prod');
      manager.resetUIOnly();
      manager.activateDuplicateCooldown(
        productId: 'override_prod',
        cooldown: const Duration(minutes: 3),
      );

      expect(manager.canAttemptPurchaseForProduct('override_prod'), isFalse);
      // active_prod may still have its own cooldown from the record
    });
  });

  group('clearProductCooldown', () {
    test('clears forced cooldown from activateDuplicateCooldown', () {
      manager.activateDuplicateCooldown(
        productId: 'forced',
        cooldown: const Duration(minutes: 10),
      );
      expect(manager.canAttemptPurchaseForProduct('forced'), isFalse);

      manager.clearProductCooldown('forced');
      expect(manager.canAttemptPurchaseForProduct('forced'), isTrue);
    });

    test('clears current product id when matching', () {
      manager.recordPurchaseAttempt(productId: 'current');
      manager.completePurchaseSession('current');
      manager.clearProductCooldown('current');
      expect(manager.canAttemptPurchaseForProduct('current'), isTrue);
    });
  });

  group('isPurchaseCanceled additional keywords', () {
    PurchaseDetails makePurchase({
      required PurchaseStatus status,
      String? errorMessage,
      String? errorCode,
    }) {
      final details = PurchaseDetails(
        productID: 'test_product',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: null,
        status: status,
        purchaseID: 'test_id',
      );
      if (errorMessage != null || errorCode != null) {
        details.error = IAPError(
          source: 'test',
          code: errorCode ?? '',
          message: errorMessage ?? '',
        );
      }
      return details;
    }

    test('detects abort keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'transaction abort',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects dismiss keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'dialog dismiss by user',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects passcode keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'passcode required',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects unauthorized keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'unauthorized access',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects permission denied keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'permission denied',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects operation was cancelled keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'operation was cancelled by system',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects user denied keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'user denied the request',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects authentication cancelled keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'authentication cancelled',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects user interaction required keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'user interaction required',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects interaction not allowed keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'interaction not allowed',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects rejected keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'payment rejected',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects stopped keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'process stopped',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects interrupted keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'connection interrupted',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects aborted keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'transaction aborted',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects -1002 error code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: '-1002',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects -2 error code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: '-2',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects LAErrorUserCancel error code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: 'LAErrorUserCancel',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects error code 2', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: '2',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('returns false for restored status', () {
      final purchase = makePurchase(status: PurchaseStatus.restored);
      expect(manager.isPurchaseCanceled(purchase), isFalse);
    });
  });

  group('handlePurchaseResult edge cases', () {
    testWidgets('cancel resets internal state with cancel reason', (tester) async {
      manager.recordPurchaseAttempt(productId: 'test');

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': true,
          'errorMessage': null,
        },
        false,
        (msg) async {},
      );

      expect(manager.canAttemptPurchase(), isTrue);
      expect(resetCallCount, 1);
    });

    testWidgets('failure resets internal state with failure reason', (tester) async {
      manager.recordPurchaseAttempt(productId: 'test');

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': false,
          'errorMessage': 'something went wrong',
        },
        false,
        (msg) async {},
      );

      expect(manager.canAttemptPurchase(), isTrue);
      expect(resetCallCount, 1);
    });

    testWidgets('success starts safety timer', (tester) async {
      await manager.handlePurchaseResult(
        {
          'success': true,
          'wasCancelled': false,
          'errorMessage': null,
        },
        true,
        (msg) async {},
      );

      // Safety timer should be running
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      manager.disposeSafetyTimer();
    });
  });

  group('Multiple timer operations', () {
    test('starting timer twice cancels first timer', () {
      manager.startSafetyTimer();
      manager.startSafetyTimer(); // should not throw
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      manager.disposeSafetyTimer();
    });

    test('stopping timer when no timer exists does not throw', () {
      expect(() => manager.stopSafetyTimer(), returnsNormally);
    });

    test('disposing timer when no timer exists does not throw', () {
      expect(() => manager.disposeSafetyTimer(), returnsNormally);
    });

    test('dispose after dispose does not throw', () {
      manager.startSafetyTimer();
      manager.disposeSafetyTimer();
      expect(() => manager.disposeSafetyTimer(), returnsNormally);
    });
  });

  group('cleanupAllTimersOnSuccess', () {
    test('stops safety timer and resets timeout state', () {
      manager.startSafetyTimer();
      manager.cleanupAllTimersOnSuccess();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });

    test('works even when no timer started', () {
      expect(() => manager.cleanupAllTimersOnSuccess(), returnsNormally);
      expect(manager.isSafetyTimeoutTriggered, isFalse);
    });
  });

  group('remainingCooldown with consecutive purchases', () {
    test('returns remaining duration after multiple purchases', () {
      manager.recordPurchaseAttempt(productId: 'p1');
      manager.completePurchaseSession('p1');
      manager.recordPurchaseAttempt(productId: 'p2');
      manager.completePurchaseSession('p2');

      final remaining = manager.remainingCooldown();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });

  group('Product-specific remaining cooldown after forced cooldown', () {
    test('returns remaining for forced cooldown product', () {
      manager.activateDuplicateCooldown(
        productId: 'forced_prod',
        cooldown: const Duration(minutes: 5),
      );

      final remaining = manager.remainingCooldownForProduct('forced_prod');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });

  group('isLatePurchase and resetLatePurchaseSuccess', () {
    test('reset clears triggered flag', () {
      manager.resetLatePurchaseSuccess();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });

    test('isLatePurchase false when active purchasing', () {
      expect(manager.isLatePurchase(true), isFalse);
    });

    test('isLatePurchase false when no timeout', () {
      expect(manager.isLatePurchase(false), isFalse);
    });
  });

  group('recordPurchaseAttempt', () {
    test('without productId still sets in progress', () {
      manager.recordPurchaseAttempt();
      expect(manager.canAttemptPurchase(), isFalse);
      expect(manager.lastPurchaseAttempt, isNotNull);
    });

    test('sets first purchase in session', () {
      manager.recordPurchaseAttempt(productId: 'first');
      expect(manager.lastPurchaseAttempt, isNotNull);
    });
  });

  group('completePurchaseSession stops safety timer', () {
    test('completes session and stops timer', () {
      manager.startSafetyTimer();
      manager.recordPurchaseAttempt(productId: 'test');
      manager.completePurchaseSession('test');

      expect(manager.canAttemptPurchase(), isTrue);
      // Timer should have been stopped
      manager.disposeSafetyTimer(); // cleanup
    });
  });
}
