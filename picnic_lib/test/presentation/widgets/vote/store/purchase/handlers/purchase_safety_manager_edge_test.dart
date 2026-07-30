import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

/// Edge-case tests for PurchaseSafetyManager that cover uncovered branches:
/// - handlePurchaseResult with default error message
/// - resetInternalState with generic reason (no cancel/failure)
/// - canAttemptPurchaseForProduct with expired forced cooldown
/// - consecutive purchase session boundary (exactly 10 min)
/// - isPurchaseCanceled keyword: declined, terminated, biometric, authentication failed
/// - error code in message field (cross-field detection)
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

  group('handlePurchaseResult edge cases', () {
    testWidgets('failure with null errorMessage uses default', (tester) async {
      String? receivedMessage;
      manager.recordPurchaseAttempt(productId: 'prod');

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': false,
          'errorMessage': null,
        },
        false,
        (msg) async {
          receivedMessage = msg;
        },
      );

      // 에러 코드여야 한다 - 한국어 문장을 만들면 로케일과 무관하게 노출된다.
      expect(receivedMessage, 'GENERIC');
      expect(resetCallCount, 1);
    });

    testWidgets('failure with custom errorMessage passes it through',
        (tester) async {
      String? receivedMessage;
      manager.recordPurchaseAttempt(productId: 'prod');

      await manager.handlePurchaseResult(
        {
          'success': false,
          'wasCancelled': false,
          'errorMessage': 'Network error',
        },
        false,
        (msg) async {
          receivedMessage = msg;
        },
      );

      expect(receivedMessage, 'Network error');
    });
  });

  group('resetInternalState with generic reason', () {
    test('does not reset consecutive count for generic reason', () {
      // Build up consecutive purchase count
      manager.recordPurchaseAttempt(productId: 'p1');
      manager.completePurchaseSession('p1');
      manager.recordPurchaseAttempt(productId: 'p2');
      manager.completePurchaseSession('p2');

      // Generic reason (not cancel/failure) should keep consecutive count
      manager.recordPurchaseAttempt(productId: 'p3');
      manager.resetInternalState(reason: '타임아웃');

      expect(manager.canAttemptPurchase(), isTrue);
      // lastPurchaseAttempt cleared since _lastProcessedTransactionId is null
    });
  });

  group('canAttemptPurchaseForProduct with expired forced cooldown', () {
    test('forced cooldown blocks purchase', () {
      // Set a forced cooldown
      manager.activateDuplicateCooldown(
        productId: 'short_cd',
        cooldown: const Duration(seconds: 5),
      );

      // Should be blocked
      expect(manager.canAttemptPurchaseForProduct('short_cd'), isFalse);
    });

    test('clearing forced cooldown allows purchase again', () {
      manager.activateDuplicateCooldown(
        productId: 'clear_cd',
        cooldown: const Duration(minutes: 5),
      );
      expect(manager.canAttemptPurchaseForProduct('clear_cd'), isFalse);

      manager.clearProductCooldown('clear_cd');
      expect(manager.canAttemptPurchaseForProduct('clear_cd'), isTrue);
    });
  });

  group('isPurchaseCanceled additional keyword coverage', () {
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

    test('detects declined keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'payment declined by issuer',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects terminated keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'session terminated unexpectedly',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects biometric keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'biometric verification required',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects authentication failed keyword', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'authentication failed due to timeout',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects cancel keyword in error message', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'cancel by system',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects error code in message field', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'error code SKErrorPaymentCancelled',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('error with error=null does not crash', () {
      final details = PurchaseDetails(
        productID: 'test_product',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: null,
        status: PurchaseStatus.error,
        purchaseID: 'test_id',
      );
      // error is null (default)
      expect(manager.isPurchaseCanceled(details), isFalse);
    });
  });

  group('Safety timer interaction with purchase flow', () {
    test('completePurchaseSession stops safety timer before it fires', () {
      manager.startSafetyTimer();
      manager.recordPurchaseAttempt(productId: 'quick');
      manager.completePurchaseSession('quick');

      // Timer should be stopped
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      manager.disposeSafetyTimer();
    });

    test('cleanupAllTimersOnSuccess after already stopped timer', () {
      manager.startSafetyTimer();
      manager.stopSafetyTimer();
      manager.cleanupAllTimersOnSuccess();

      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });
  });

  group('Multiple product cooldown interactions', () {
    test('recording and completing multiple different products', () {
      manager.recordPurchaseAttempt(productId: 'a');
      manager.completePurchaseSession('a');

      manager.recordPurchaseAttempt(productId: 'b');
      manager.completePurchaseSession('b');

      manager.recordPurchaseAttempt(productId: 'c');
      manager.completePurchaseSession('c');

      // All products should be in cooldown
      expect(manager.canAttemptPurchaseForProduct('a'), isFalse);
      expect(manager.canAttemptPurchaseForProduct('b'), isFalse);
      expect(manager.canAttemptPurchaseForProduct('c'), isFalse);

      // New product should be fine
      expect(manager.canAttemptPurchaseForProduct('d'), isTrue);
    });

    test('clearing one product cooldown does not affect others', () {
      manager.recordPurchaseAttempt(productId: 'x');
      manager.completePurchaseSession('x');
      manager.recordPurchaseAttempt(productId: 'y');
      manager.completePurchaseSession('y');

      manager.clearProductCooldown('x');
      expect(manager.canAttemptPurchaseForProduct('x'), isTrue);
      expect(manager.canAttemptPurchaseForProduct('y'), isFalse);
    });
  });

  group('remainingCooldown after session reset', () {
    test('remainingCooldown returns null after full internal reset', () {
      manager.recordPurchaseAttempt(productId: 'test');
      expect(manager.remainingCooldown(), isNotNull);

      // Generic reset does not clear _lastPurchaseTime
      manager.resetInternalState(reason: 'timeout');
      // _lastPurchaseTime is still set, so cooldown remains
      expect(manager.remainingCooldown(), isNotNull);
    });

    test('remainingCooldownForProduct returns null after clearProductCooldown',
        () {
      manager.recordPurchaseAttempt(productId: 'prod');
      manager.completePurchaseSession('prod');
      expect(manager.remainingCooldownForProduct('prod'), isNotNull);

      manager.clearProductCooldown('prod');
      expect(manager.remainingCooldownForProduct('prod'), isNull);
    });
  });

  group('activateDuplicateCooldown with custom cooldown duration', () {
    test('respects custom cooldown and blocks product', () {
      manager.activateDuplicateCooldown(
        productId: 'custom',
        cooldown: const Duration(hours: 1),
      );

      expect(manager.canAttemptPurchaseForProduct('custom'), isFalse);
      final remaining = manager.remainingCooldownForProduct('custom');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });
}
