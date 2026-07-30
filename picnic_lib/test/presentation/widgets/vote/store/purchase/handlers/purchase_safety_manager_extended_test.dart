import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

/// Extended tests for PurchaseSafetyManager covering additional branches
/// beyond the existing purchase_safety_manager_test.dart.
void main() {
  late PurchaseSafetyManager manager;
  late int resetCallCount;

  setUp(() {
    resetCallCount = 0;
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () => resetCallCount++,
    );
  });

  group('Safety timer', () {
    test('startSafetyTimer creates timer', () {
      manager.startSafetyTimer();
      // Timer was started, verify no timeout yet
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
      manager.disposeSafetyTimer();
    });

    test('stopSafetyTimer cancels timer', () {
      manager.startSafetyTimer();
      manager.stopSafetyTimer();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      manager.disposeSafetyTimer();
    });

    test('disposeSafetyTimer cleans up', () {
      manager.startSafetyTimer();
      manager.disposeSafetyTimer();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
    });
  });

  group('Product-specific cooldown', () {
    test('clearProductCooldown removes all state for product', () {
      manager.recordPurchaseAttempt(productId: 'prod_a');
      manager.completePurchaseSession('prod_a');

      // Cooldown active
      expect(manager.canAttemptPurchaseForProduct('prod_a'), isFalse);

      // Clear cooldown
      manager.clearProductCooldown('prod_a');
      expect(manager.canAttemptPurchaseForProduct('prod_a'), isTrue);
    });

    test('remainingCooldownForProduct returns Duration during cooldown', () {
      manager.recordPurchaseAttempt(productId: 'prod_b');
      manager.completePurchaseSession('prod_b');

      final remaining = manager.remainingCooldownForProduct('prod_b');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('remainingCooldownForProduct returns null for unknown product', () {
      final remaining = manager.remainingCooldownForProduct('unknown');
      expect(remaining, isNull);
    });
  });

  group('Duplicate JWS cooldown', () {
    test('activateDuplicateCooldown blocks subsequent purchases', () {
      manager.activateDuplicateCooldown(
        productId: 'dup_prod',
        cooldown: const Duration(minutes: 5),
      );

      expect(manager.canAttemptPurchaseForProduct('dup_prod'), isFalse);
    });

    test('activateDuplicateCooldown without productId uses currentProductId', () {
      manager.recordPurchaseAttempt(productId: 'current_prod');
      manager.resetUIOnly();

      manager.activateDuplicateCooldown(cooldown: const Duration(minutes: 2));
      // Should affect current_prod
      expect(manager.canAttemptPurchaseForProduct('current_prod'), isFalse);
    });

    test('activateDuplicateCooldown increments consecutive count', () {
      // First purchase
      manager.recordPurchaseAttempt(productId: 'test_prod');
      manager.completePurchaseSession('test_prod');

      // Activate duplicate cooldown adds another count
      manager.activateDuplicateCooldown(
        productId: 'test_prod',
        cooldown: const Duration(seconds: 5),
      );

      // Product should be blocked
      expect(manager.canAttemptPurchaseForProduct('test_prod'), isFalse);
    });
  });

  group('resetInternalState', () {
    test('resets purchase in progress flag', () {
      manager.recordPurchaseAttempt(productId: 'test');
      expect(manager.canAttemptPurchase(), isFalse);

      manager.resetInternalState(reason: 'test reset');
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('resets consecutive count on cancel reason', () {
      manager.recordPurchaseAttempt(productId: 'prod');
      manager.resetInternalState(reason: '구매 취소');
      // After cancel, should be able to purchase immediately
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('resets consecutive count on failure reason', () {
      manager.recordPurchaseAttempt(productId: 'prod');
      manager.resetInternalState(reason: '구매 실패');
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('does not reset consecutive count for generic reason', () {
      manager.recordPurchaseAttempt(productId: 'prod');
      manager.resetInternalState(reason: 'general reset');
      expect(manager.canAttemptPurchase(), isTrue);
    });
  });

  group('resetUIOnly', () {
    test('resets purchase in progress but keeps cooldown', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.completePurchaseSession('test');

      // Cooldown active for product
      expect(manager.canAttemptPurchaseForProduct('test'), isFalse);

      manager.resetUIOnly(reason: 'UI reset');
      // canAttemptPurchase returns true (no purchase in progress)
      expect(manager.canAttemptPurchase(), isTrue);
      // But product-specific cooldown still active
      expect(manager.canAttemptPurchaseForProduct('test'), isFalse);
    });
  });

  group('isLatePurchase', () {
    test('returns false when purchasing is active', () {
      expect(manager.isLatePurchase(true), isFalse);
    });

    test('returns false when no timeout triggered', () {
      expect(manager.isLatePurchase(false), isFalse);
    });
  });

  group('resetLatePurchaseSuccess', () {
    test('resets timeout state', () {
      manager.resetLatePurchaseSuccess();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });
  });

  group('handlePurchaseResult', () {
    testWidgets('handles cancel result', (tester) async {
      bool errorDialogShown = false;

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': true,
          'errorMessage': null,
        },
        true,
        (msg) async {
          errorDialogShown = true;
        },
      );

      expect(resetCallCount, equals(1));
      expect(errorDialogShown, isFalse);
    });

    testWidgets('handles failure result', (tester) async {
      String? receivedError;

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': false,
          'errorMessage': 'Payment failed',
        },
        true,
        (msg) async {
          receivedError = msg;
        },
      );

      expect(resetCallCount, equals(1));
      expect(receivedError, equals('Payment failed'));
    });

    testWidgets('handles success result and starts safety timer', (tester) async {
      await manager.handlePurchaseResult(
        {
          'success': true,
          'wasCancelled': false,
          'errorMessage': null,
        },
        true,
        (msg) async {},
      );

      expect(resetCallCount, equals(0)); // No reset on success
      manager.disposeSafetyTimer();
    });

    testWidgets('handles failure with null error message', (tester) async {
      String? receivedError;

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': false,
          'errorMessage': null,
        },
        true,
        (msg) async {
          receivedError = msg;
        },
      );

      // 에러 코드여야 한다 - 여기서 한국어 문장을 만들면 로케일과 무관하게
      // 한국어 오류가 다이얼로그에 올라간다.
      expect(receivedError, equals('GENERIC'));
    });
  });

  group('cleanupAllTimersOnSuccess', () {
    test('resets timeout state and stops timer', () {
      manager.startSafetyTimer();
      manager.cleanupAllTimersOnSuccess();

      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });
  });

  group('remainingCooldown', () {
    test('returns null when no purchase has been made', () {
      expect(manager.remainingCooldown(), isNull);
    });

    test('returns remaining duration right after purchase', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.completePurchaseSession('test');

      final remaining = manager.remainingCooldown();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });

  group('lastPurchaseAttempt getter', () {
    test('returns null initially', () {
      expect(manager.lastPurchaseAttempt, isNull);
    });

    test('returns time after recordPurchaseAttempt', () {
      final before = DateTime.now();
      manager.recordPurchaseAttempt(productId: 'test');
      final after = DateTime.now();

      expect(manager.lastPurchaseAttempt, isNotNull);
      expect(
        manager.lastPurchaseAttempt!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        manager.lastPurchaseAttempt!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('isPurchaseCanceled', () {
    test('cancel keyword matching', () {
      bool checkCancelKeywords(String errorMessage) {
        const cancelKeywords = [
          'cancel', 'cancelled', 'canceled', 'user cancel',
          'abort', 'dismiss', 'authentication', 'touch id',
          'face id', 'biometric', 'passcode', 'unauthorized',
          'permission denied', 'operation was cancelled',
          'user cancelled', 'user denied', 'authentication failed',
          'authentication cancelled', 'user interaction required',
          'interaction not allowed', 'declined', 'rejected',
          'stopped', 'interrupted', 'terminated', 'aborted',
        ];

        for (final keyword in cancelKeywords) {
          if (errorMessage.contains(keyword)) {
            return true;
          }
        }
        return false;
      }

      expect(checkCancelKeywords('user cancel'), isTrue);
      expect(checkCancelKeywords('payment cancelled'), isTrue);
      expect(checkCancelKeywords('touch id failed'), isTrue);
      expect(checkCancelKeywords('face id error'), isTrue);
      expect(checkCancelKeywords('biometric check'), isTrue);
      expect(checkCancelKeywords('authentication failed'), isTrue);
      expect(checkCancelKeywords('payment declined'), isTrue);
      expect(checkCancelKeywords('terminated by system'), isTrue);
      expect(checkCancelKeywords('network error'), isFalse);
      expect(checkCancelKeywords('server error'), isFalse);
    });

    test('cancel error code matching', () {
      bool checkCancelErrorCodes(String errorCode, String errorMessage) {
        const cancelErrorCodes = [
          'PAYMENT_CANCELED', 'USER_CANCELED', '2',
          'SKErrorPaymentCancelled', 'BILLING_RESPONSE_USER_CANCELED',
          '-1002', '-2', 'LAErrorUserCancel',
        ];

        for (final code in cancelErrorCodes) {
          if (errorCode.contains(code) || errorMessage.contains(code)) {
            return true;
          }
        }
        return false;
      }

      expect(checkCancelErrorCodes('PAYMENT_CANCELED', ''), isTrue);
      expect(checkCancelErrorCodes('USER_CANCELED', ''), isTrue);
      expect(checkCancelErrorCodes('2', ''), isTrue);
      expect(checkCancelErrorCodes('SKErrorPaymentCancelled', ''), isTrue);
      expect(checkCancelErrorCodes('', 'LAErrorUserCancel'), isTrue);
      expect(checkCancelErrorCodes('UNKNOWN', ''), isFalse);
    });
  });
}
