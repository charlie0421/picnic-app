import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

void main() {
  late InAppPurchaseService service;

  setUp(() {
    service = InAppPurchaseService();
    // Reset debug state before each test
    service.debugMode = false;
    service.debugTimeoutMode = 'normal';
    service.simulateSlowPurchase = false;
    service.forceTimeoutSimulation = false;
    service.onPurchaseTimeout = null;
  });

  group('InAppPurchaseService singleton', () {
    test('returns identical instance via factory', () {
      final s1 = InAppPurchaseService();
      final s2 = InAppPurchaseService();
      expect(identical(s1, s2), isTrue);
    });
  });

  group('initial state', () {
    test('products is empty list', () {
      expect(service.products, isEmpty);
      expect(service.products, isA<List>());
    });

    test('isAvailable is false', () {
      expect(service.isAvailable, isFalse);
    });

    test('lastPurchaseWasCancelled is false', () {
      expect(service.lastPurchaseWasCancelled, isFalse);
    });
  });

  group('setDebugMode', () {
    test('enable sets debugMode true and debugTimeoutMode to debug', () {
      service.setDebugMode(true);
      expect(service.debugMode, isTrue);
      expect(service.debugTimeoutMode, equals('debug'));
    });

    test('disable resets to normal', () {
      service.setDebugMode(true);
      service.setDebugMode(false);
      expect(service.debugMode, isFalse);
      expect(service.debugTimeoutMode, equals('normal'));
    });

    test('multiple enables are idempotent', () {
      service.setDebugMode(true);
      service.setDebugMode(true);
      expect(service.debugMode, isTrue);
      expect(service.debugTimeoutMode, equals('debug'));
    });
  });

  group('setTimeoutMode', () {
    test('debug mode', () {
      service.setTimeoutMode('debug');
      expect(service.debugTimeoutMode, equals('debug'));
      expect(service.debugMode, isTrue);
    });

    test('ultrafast mode', () {
      service.setTimeoutMode('ultrafast');
      expect(service.debugTimeoutMode, equals('ultrafast'));
      expect(service.debugMode, isTrue);
    });

    test('instant mode', () {
      service.setTimeoutMode('instant');
      expect(service.debugTimeoutMode, equals('instant'));
      expect(service.debugMode, isTrue);
    });

    test('normal mode resets debugMode', () {
      service.setTimeoutMode('debug');
      service.setTimeoutMode('normal');
      expect(service.debugTimeoutMode, equals('normal'));
      expect(service.debugMode, isFalse);
    });

    test('unknown mode string does not crash', () {
      service.setTimeoutMode('custom_value');
      expect(service.debugTimeoutMode, equals('custom_value'));
      expect(service.debugMode, isTrue);
    });
  });

  group('setSlowPurchaseSimulation', () {
    test('enable', () {
      service.setSlowPurchaseSimulation(true);
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('disable', () {
      service.setSlowPurchaseSimulation(true);
      service.setSlowPurchaseSimulation(false);
      expect(service.simulateSlowPurchase, isFalse);
    });

    test('with custom delay', () {
      service.setSlowPurchaseSimulation(
        true,
        delay: const Duration(seconds: 3),
      );
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('with very short delay', () {
      service.setSlowPurchaseSimulation(
        true,
        delay: const Duration(milliseconds: 100),
      );
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('disable with delay does not crash', () {
      service.setSlowPurchaseSimulation(
        false,
        delay: const Duration(seconds: 5),
      );
      expect(service.simulateSlowPurchase, isFalse);
    });
  });

  group('setForceTimeoutSimulation', () {
    test('enable', () {
      service.setForceTimeoutSimulation(true);
      expect(service.forceTimeoutSimulation, isTrue);
    });

    test('disable', () {
      service.setForceTimeoutSimulation(true);
      service.setForceTimeoutSimulation(false);
      expect(service.forceTimeoutSimulation, isFalse);
    });

    test('multiple toggles', () {
      service.setForceTimeoutSimulation(true);
      service.setForceTimeoutSimulation(false);
      service.setForceTimeoutSimulation(true);
      expect(service.forceTimeoutSimulation, isTrue);
    });
  });

  group('onPurchaseTimeout callback', () {
    test('initial value is null', () {
      expect(service.onPurchaseTimeout, isNull);
    });

    test('can be set', () {
      service.onPurchaseTimeout = (productId) {};
      expect(service.onPurchaseTimeout, isNotNull);
    });

    test('can be cleared', () {
      service.onPurchaseTimeout = (productId) {};
      service.onPurchaseTimeout = null;
      expect(service.onPurchaseTimeout, isNull);
    });

    test('callback receives correct product ID', () {
      String? receivedProductId;
      service.onPurchaseTimeout = (productId) {
        receivedProductId = productId;
      };
      service.onPurchaseTimeout!('test_product_123');
      expect(receivedProductId, equals('test_product_123'));
    });
  });

  group('triggerManualTimeout', () {
    test('with no purchase in progress and no explicit ID does nothing', () {
      service.triggerManualTimeout();
    });

    test('with explicit product ID and callback', () {
      String? receivedProductId;
      service.onPurchaseTimeout = (productId) {
        receivedProductId = productId;
      };
      service.triggerManualTimeout(productId: 'manual_test_product');
      expect(receivedProductId, equals('manual_test_product'));
    });

    test('with explicit product ID but no callback', () {
      service.triggerManualTimeout(productId: 'some_product');
    });
  });

  group('cleanupTimersOnPurchaseSuccess', () {
    test('does not throw for any product ID', () {
      service.cleanupTimersOnPurchaseSuccess('STAR10000');
      service.cleanupTimersOnPurchaseSuccess('');
      service.cleanupTimersOnPurchaseSuccess('nonexistent_product');
    });
  });

  group('dispose', () {
    test('does not throw', () {
      service.dispose();
    });

    test('can dispose after debug mode changes', () {
      service.setDebugMode(true);
      service.setForceTimeoutSimulation(true);
      service.dispose();
    });
  });

  // ====================================================================
  // Tests calling ACTUAL production methods (via @visibleForTesting)
  // ====================================================================

  group('getCurrentTimeout (production method)', () {
    test('normal mode returns purchaseTimeout (30s)', () {
      service.debugTimeoutMode = 'normal';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.purchaseTimeout));
    });

    test('debug mode returns debugPurchaseTimeout (3s)', () {
      service.debugTimeoutMode = 'debug';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.debugPurchaseTimeout));
    });

    test('ultrafast mode returns ultraFastTimeout (500ms)', () {
      service.debugTimeoutMode = 'ultrafast';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.ultraFastTimeout));
    });

    test('instant mode returns instantTimeout (100ms)', () {
      service.debugTimeoutMode = 'instant';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.instantTimeout));
    });

    test('forceTimeoutSimulation overrides normal mode to debugPurchaseTimeout', () {
      service.debugTimeoutMode = 'normal';
      service.forceTimeoutSimulation = true;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.debugPurchaseTimeout));
    });

    test('forceTimeoutSimulation overrides ultrafast mode', () {
      service.debugTimeoutMode = 'ultrafast';
      service.forceTimeoutSimulation = true;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.debugPurchaseTimeout));
    });

    test('forceTimeoutSimulation overrides instant mode', () {
      service.debugTimeoutMode = 'instant';
      service.forceTimeoutSimulation = true;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.debugPurchaseTimeout));
    });

    test('unknown mode falls through to default (purchaseTimeout)', () {
      service.debugTimeoutMode = 'unknown_mode';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.purchaseTimeout));
    });

    test('empty string mode falls through to default', () {
      service.debugTimeoutMode = '';
      service.forceTimeoutSimulation = false;
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.purchaseTimeout));
    });

    test('setDebugMode(true) then getCurrentTimeout returns debug timeout', () {
      service.setDebugMode(true);
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.debugPurchaseTimeout));
    });

    test('setTimeoutMode changes getCurrentTimeout result', () {
      service.setTimeoutMode('ultrafast');
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.ultraFastTimeout));
      service.setTimeoutMode('instant');
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.instantTimeout));
      service.setTimeoutMode('normal');
      expect(service.getCurrentTimeout(), equals(PurchaseConstants.purchaseTimeout));
    });
  });

  group('getTimeoutDescription (production method)', () {
    test('normal mode returns seconds format', () {
      service.debugTimeoutMode = 'normal';
      service.forceTimeoutSimulation = false;
      // purchaseTimeout is 30s
      expect(service.getTimeoutDescription(), contains('30'));
    });

    test('debug mode returns seconds format', () {
      service.debugTimeoutMode = 'debug';
      service.forceTimeoutSimulation = false;
      // debugPurchaseTimeout is 3s
      expect(service.getTimeoutDescription(), contains('3'));
    });

    test('ultrafast mode returns milliseconds format', () {
      service.debugTimeoutMode = 'ultrafast';
      service.forceTimeoutSimulation = false;
      // ultraFastTimeout is 500ms
      expect(service.getTimeoutDescription(), equals('500ms'));
    });

    test('instant mode returns milliseconds format', () {
      service.debugTimeoutMode = 'instant';
      service.forceTimeoutSimulation = false;
      // instantTimeout is 100ms
      expect(service.getTimeoutDescription(), equals('100ms'));
    });

    test('forceTimeout always returns debug timeout description', () {
      service.forceTimeoutSimulation = true;
      service.debugTimeoutMode = 'normal';
      // debugPurchaseTimeout is 3s
      final desc = service.getTimeoutDescription();
      expect(desc, contains('3'));
    });
  });

  group('isPurchaseCancelledException (production method)', () {
    test('detects StoreKit2_purchase_cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('StoreKit2_purchase_cancelled'),
        ),
        isTrue,
      );
    });

    test('detects storekit2_user_cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('storekit2_user_cancelled'),
        ),
        isTrue,
      );
    });

    test('detects storekit2_cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('storekit2_cancelled'),
        ),
        isTrue,
      );
    });

    test('detects purchase_cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('purchase_cancelled'),
        ),
        isTrue,
      );
    });

    test('detects transaction_cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('transaction_cancelled'),
        ),
        isTrue,
      );
    });

    test('detects user_cancelled_purchase', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('user_cancelled_purchase'),
        ),
        isTrue,
      );
    });

    test('detects cancelled_by_user', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('cancelled_by_user'),
        ),
        isTrue,
      );
    });

    test('detects payment_canceled (American spelling)', () {
      expect(
        service.isPurchaseCancelledException(Exception('payment_canceled')),
        isTrue,
      );
    });

    test('detects user_canceled', () {
      expect(
        service.isPurchaseCancelledException(Exception('user_canceled')),
        isTrue,
      );
    });

    test('detects skeerrorpaymentcancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('SKErrorPaymentCancelled'),
        ),
        isTrue,
      );
    });

    test('detects billing_response_user_canceled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('billing_response_user_canceled'),
        ),
        isTrue,
      );
    });

    test('detects generic cancel keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('Something cancel here')),
        isTrue,
      );
    });

    test('detects cancelled keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('Cancelled by system')),
        isTrue,
      );
    });

    test('detects canceled keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('was canceled')),
        isTrue,
      );
    });

    test('detects user cancel keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('user cancel request')),
        isTrue,
      );
    });

    test('detects abort keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('Transaction aborted')),
        isTrue,
      );
    });

    test('detects dismiss keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('User dismissed dialog')),
        isTrue,
      );
    });

    test('detects authentication keyword', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('Authentication required'),
        ),
        isTrue,
      );
    });

    test('detects Touch ID keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('Touch ID failed')),
        isTrue,
      );
    });

    test('detects Face ID keyword', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('Face ID authentication error'),
        ),
        isTrue,
      );
    });

    test('detects biometric keyword', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('Biometric check failed'),
        ),
        isTrue,
      );
    });

    test('detects passcode keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('passcode required')),
        isTrue,
      );
    });

    test('detects unauthorized keyword', () {
      expect(
        service.isPurchaseCancelledException(Exception('unauthorized access')),
        isTrue,
      );
    });

    test('detects permission denied', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('Permission denied by user'),
        ),
        isTrue,
      );
    });

    test('detects operation was cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('operation was cancelled by user'),
        ),
        isTrue,
      );
    });

    test('detects user denied', () {
      expect(
        service.isPurchaseCancelledException(Exception('user denied request')),
        isTrue,
      );
    });

    test('detects authentication failed', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('authentication failed'),
        ),
        isTrue,
      );
    });

    test('detects user interaction required', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('user interaction required'),
        ),
        isTrue,
      );
    });

    test('detects interaction not allowed', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('interaction not allowed'),
        ),
        isTrue,
      );
    });

    test('detects transaction has been cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('transaction has been cancelled'),
        ),
        isTrue,
      );
    });

    test('detects purchase was cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('purchase was cancelled'),
        ),
        isTrue,
      );
    });

    test('detects user has cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('user has cancelled'),
        ),
        isTrue,
      );
    });

    test('detects payment cancelled', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('payment cancelled'),
        ),
        isTrue,
      );
    });

    test('detects cancelled transaction', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('cancelled transaction'),
        ),
        isTrue,
      );
    });

    test('detects user cancellation', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('user cancellation'),
        ),
        isTrue,
      );
    });

    test('case insensitive detection', () {
      expect(
        service.isPurchaseCancelledException(Exception('PURCHASE_CANCELLED')),
        isTrue,
      );
      expect(
        service.isPurchaseCancelledException(Exception('Purchase_Cancelled')),
        isTrue,
      );
    });

    test('does not detect random errors', () {
      expect(
        service.isPurchaseCancelledException(Exception('Network timeout error')),
        isFalse,
      );
    });

    test('does not detect server errors', () {
      expect(
        service.isPurchaseCancelledException(
          Exception('500 Internal Server Error'),
        ),
        isFalse,
      );
    });

    test('does not detect null pointer errors', () {
      expect(
        service.isPurchaseCancelledException(Exception('Null check error')),
        isFalse,
      );
    });

    test('does not detect product not found errors', () {
      expect(
        service.isPurchaseCancelledException(Exception('Product not found')),
        isFalse,
      );
    });

    test('works with String exceptions (not Exception objects)', () {
      expect(
        service.isPurchaseCancelledException('user cancelled'),
        isTrue,
      );
    });

    test('works with Error objects', () {
      expect(
        service.isPurchaseCancelledException(
          StateError('cancelled by user'),
        ),
        isTrue,
      );
    });

    test('does not detect empty exception', () {
      // Empty string has no cancel keyword
      expect(
        service.isPurchaseCancelledException(Exception('')),
        isFalse,
      );
    });
  });

  group('PurchaseConstants', () {
    test('timeout durations are ordered correctly', () {
      expect(
        PurchaseConstants.instantTimeout.inMilliseconds,
        lessThan(PurchaseConstants.ultraFastTimeout.inMilliseconds),
      );
      expect(
        PurchaseConstants.ultraFastTimeout.inMilliseconds,
        lessThan(PurchaseConstants.debugPurchaseTimeout.inMilliseconds),
      );
      expect(
        PurchaseConstants.debugPurchaseTimeout.inMilliseconds,
        lessThan(PurchaseConstants.purchaseTimeout.inMilliseconds),
      );
    });

    test('purchaseTimeout is 30 seconds', () {
      expect(PurchaseConstants.purchaseTimeout,
          equals(const Duration(seconds: 30)));
    });

    test('debugPurchaseTimeout is 3 seconds', () {
      expect(PurchaseConstants.debugPurchaseTimeout,
          equals(const Duration(seconds: 3)));
    });

    test('ultraFastTimeout is 500ms', () {
      expect(PurchaseConstants.ultraFastTimeout,
          equals(const Duration(milliseconds: 500)));
    });

    test('instantTimeout is 100ms', () {
      expect(PurchaseConstants.instantTimeout,
          equals(const Duration(milliseconds: 100)));
    });

    test('verificationTimeout is 30 seconds', () {
      expect(PurchaseConstants.verificationTimeout,
          equals(const Duration(seconds: 30)));
    });

    test('sandboxVerificationTimeout is 60 seconds', () {
      expect(PurchaseConstants.sandboxVerificationTimeout,
          equals(const Duration(seconds: 60)));
    });

    test('authenticationGracePeriod is 300ms', () {
      expect(PurchaseConstants.authenticationGracePeriod,
          equals(const Duration(milliseconds: 300)));
    });

    test('cooldownPeriod is 300ms', () {
      expect(PurchaseConstants.cooldownPeriod,
          equals(const Duration(milliseconds: 300)));
    });

    test('maxRetries values', () {
      expect(PurchaseConstants.maxRetries, equals(3));
      expect(PurchaseConstants.sandboxMaxRetries, equals(5));
      expect(PurchaseConstants.baseRetryDelay, equals(2));
    });

    test('error message keys are non-empty', () {
      expect(PurchaseConstants.userNotAuthenticatedErrorKey, isNotEmpty);
      expect(PurchaseConstants.productNotFoundErrorKey, isNotEmpty);
      expect(PurchaseConstants.receiptVerificationErrorKey, isNotEmpty);
      expect(PurchaseConstants.duplicatePurchaseErrorKey, isNotEmpty);
      expect(PurchaseConstants.initializingErrorKey, isNotEmpty);
      expect(PurchaseConstants.purchaseInProgressErrorKey, isNotEmpty);
    });

    test('error codes are non-empty and unique', () {
      final codes = [
        PurchaseConstants.errPrevTransactionPending,
        PurchaseConstants.errCooldownActive,
        PurchaseConstants.errPurchaseCanceled,
        PurchaseConstants.errInProgress,
        PurchaseConstants.errTimeout,
        PurchaseConstants.errAuthTimeout,
        PurchaseConstants.errNetwork,
        PurchaseConstants.errServer,
        PurchaseConstants.errConcurrent,
        PurchaseConstants.errTooSoon,
        PurchaseConstants.errRecentPurchase,
        PurchaseConstants.errRequestDuplicate,
      ];
      for (final code in codes) {
        expect(code, isNotEmpty);
      }
      expect(codes.toSet().length, equals(codes.length));
    });

    test('SharedPreferences keys are non-empty', () {
      expect(PurchaseConstants.testDialogShownKey, isNotEmpty);
      expect(PurchaseConstants.lastPurchaseAttemptKey, isNotEmpty);
      expect(PurchaseConstants.authenticationStartKey, isNotEmpty);
      expect(PurchaseConstants.backgroundPurchaseKey, isNotEmpty);
    });
  });

  group('PurchaseResult enum', () {
    test('has all expected values', () {
      expect(PurchaseResult.values.length, equals(5));
      expect(PurchaseResult.values, contains(PurchaseResult.success));
      expect(PurchaseResult.values, contains(PurchaseResult.failed));
      expect(PurchaseResult.values, contains(PurchaseResult.canceled));
      expect(PurchaseResult.values, contains(PurchaseResult.duplicate));
      expect(PurchaseResult.values, contains(PurchaseResult.timeout));
    });
  });

  group('PurchaseEnvironment enum', () {
    test('has all expected values', () {
      expect(PurchaseEnvironment.values.length, equals(3));
      expect(
          PurchaseEnvironment.values, contains(PurchaseEnvironment.sandbox));
      expect(PurchaseEnvironment.values,
          contains(PurchaseEnvironment.production));
      expect(
          PurchaseEnvironment.values, contains(PurchaseEnvironment.unknown));
    });
  });

  group('ReceiptFormat enum', () {
    test('has all expected values', () {
      expect(ReceiptFormat.values.length, equals(4));
      expect(ReceiptFormat.values, contains(ReceiptFormat.storeKit2JWT));
      expect(ReceiptFormat.values, contains(ReceiptFormat.storeKit1Base64));
      expect(ReceiptFormat.values, contains(ReceiptFormat.googlePlay));
      expect(ReceiptFormat.values, contains(ReceiptFormat.unknown));
    });
  });

  group('PurchaseError', () {
    test('creates with required parameters', () {
      const error = PurchaseError(code: 'TEST', message: 'test message');
      expect(error.code, equals('TEST'));
      expect(error.message, equals('test message'));
      expect(error.details, isNull);
    });

    test('creates with details', () {
      const error = PurchaseError(
        code: 'TEST',
        message: 'test message',
        details: 'some details',
      );
      expect(error.details, equals('some details'));
    });

    test('toString without details', () {
      const error = PurchaseError(code: 'ERR', message: 'msg');
      expect(error.toString(), equals('ERR: msg'));
    });

    test('toString with details', () {
      const error =
          PurchaseError(code: 'ERR', message: 'msg', details: 'detail');
      expect(error.toString(), equals('ERR: msg (detail)'));
    });

    test('static instances are properly defined', () {
      expect(PurchaseError.userNotAuthenticated.code,
          equals('USER_NOT_AUTHENTICATED'));
      expect(PurchaseError.productNotFound.code, equals('PRODUCT_NOT_FOUND'));
      expect(PurchaseError.receiptVerification.code,
          equals('RECEIPT_VERIFICATION_FAILED'));
      expect(
          PurchaseError.duplicatePurchase.code, equals('DUPLICATE_PURCHASE'));
    });

    test('static instances have message keys matching constants', () {
      expect(
        PurchaseError.userNotAuthenticated.message,
        equals(PurchaseConstants.userNotAuthenticatedErrorKey),
      );
      expect(
        PurchaseError.productNotFound.message,
        equals(PurchaseConstants.productNotFoundErrorKey),
      );
      expect(
        PurchaseError.receiptVerification.message,
        equals(PurchaseConstants.receiptVerificationErrorKey),
      );
      expect(
        PurchaseError.duplicatePurchase.message,
        equals(PurchaseConstants.duplicatePurchaseErrorKey),
      );
    });
  });

  group('getTimeoutDescription - additional branches', () {
    test('1 second timeout shows seconds', () {
      service.debugTimeoutMode = 'debug';
      service.forceTimeoutSimulation = false;
      // debugPurchaseTimeout is 3s -> "3초"
      expect(service.getTimeoutDescription(), endsWith('초'));
    });

    test('sub-second timeout shows milliseconds', () {
      service.debugTimeoutMode = 'ultrafast';
      service.forceTimeoutSimulation = false;
      expect(service.getTimeoutDescription(), endsWith('ms'));
    });

    test('instant timeout shows milliseconds', () {
      service.debugTimeoutMode = 'instant';
      service.forceTimeoutSimulation = false;
      expect(service.getTimeoutDescription(), endsWith('ms'));
    });

    test('normal mode shows seconds', () {
      service.debugTimeoutMode = 'normal';
      service.forceTimeoutSimulation = false;
      expect(service.getTimeoutDescription(), endsWith('초'));
    });

    test('unknown mode falls through to default', () {
      service.debugTimeoutMode = 'random';
      service.forceTimeoutSimulation = false;
      // default is purchaseTimeout (30s)
      expect(service.getTimeoutDescription(), contains('30'));
    });
  });

  group('setSlowPurchaseSimulation - delay descriptions', () {
    test('delay under 1 second shows ms description', () {
      service.setSlowPurchaseSimulation(
        true,
        delay: const Duration(milliseconds: 500),
      );
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('delay of 1 second shows seconds description', () {
      service.setSlowPurchaseSimulation(
        true,
        delay: const Duration(seconds: 2),
      );
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('delay without explicit value uses default', () {
      service.setSlowPurchaseSimulation(true);
      expect(service.simulateSlowPurchase, isTrue);
    });
  });

  group('triggerManualTimeout - additional', () {
    test('with currentPurchasingProductId null and no explicit ID', () {
      // Should log a warning but not crash
      service.triggerManualTimeout();
      // No exception means success
    });

    test('callback clears the current purchasing product ID', () {
      String? receivedId;
      service.onPurchaseTimeout = (productId) {
        receivedId = productId;
      };
      service.triggerManualTimeout(productId: 'test_product');
      expect(receivedId, 'test_product');
      // Calling again with no productId and no current should do nothing
      service.triggerManualTimeout();
    });
  });

  group('cleanupTimersOnPurchaseSuccess - additional', () {
    test('calling multiple times does not throw', () {
      service.cleanupTimersOnPurchaseSuccess('PRODUCT_A');
      service.cleanupTimersOnPurchaseSuccess('PRODUCT_B');
      service.cleanupTimersOnPurchaseSuccess('PRODUCT_A');
    });

    test('after setDebugMode does not throw', () {
      service.setDebugMode(true);
      service.cleanupTimersOnPurchaseSuccess('TEST');
      service.setDebugMode(false);
      service.cleanupTimersOnPurchaseSuccess('TEST');
    });
  });

  group('getCurrentTimeout with combined state changes', () {
    test('setDebugMode then setTimeoutMode override', () {
      service.setDebugMode(true);
      service.setTimeoutMode('instant');
      expect(
        service.getCurrentTimeout(),
        equals(PurchaseConstants.instantTimeout),
      );
    });

    test('setForceTimeoutSimulation after setTimeoutMode', () {
      service.setTimeoutMode('instant');
      service.setForceTimeoutSimulation(true);
      expect(
        service.getCurrentTimeout(),
        equals(PurchaseConstants.debugPurchaseTimeout),
      );
    });

    test('disable forceTimeout restores previous mode', () {
      service.setTimeoutMode('ultrafast');
      service.setForceTimeoutSimulation(true);
      expect(
        service.getCurrentTimeout(),
        equals(PurchaseConstants.debugPurchaseTimeout),
      );
      service.setForceTimeoutSimulation(false);
      expect(
        service.getCurrentTimeout(),
        equals(PurchaseConstants.ultraFastTimeout),
      );
    });
  });

  group('dispose - additional', () {
    test('dispose after setting callbacks', () {
      service.onPurchaseTimeout = (id) {};
      service.setDebugMode(true);
      service.setSlowPurchaseSimulation(true);
      service.setForceTimeoutSimulation(true);
      service.dispose();
      // Should not throw
    });
  });

  group('PurchaseStatusExtension', () {
    test('purchased isCompleted', () {
      expect(PurchaseStatus.purchased.isCompleted, isTrue);
      expect(PurchaseStatus.purchased.isFailed, isFalse);
      expect(PurchaseStatus.purchased.isPending, isFalse);
    });

    test('restored isCompleted', () {
      expect(PurchaseStatus.restored.isCompleted, isTrue);
      expect(PurchaseStatus.restored.isFailed, isFalse);
      expect(PurchaseStatus.restored.isPending, isFalse);
    });

    test('error isFailed', () {
      expect(PurchaseStatus.error.isFailed, isTrue);
      expect(PurchaseStatus.error.isCompleted, isFalse);
      expect(PurchaseStatus.error.isPending, isFalse);
    });

    test('canceled isFailed', () {
      expect(PurchaseStatus.canceled.isFailed, isTrue);
      expect(PurchaseStatus.canceled.isCompleted, isFalse);
      expect(PurchaseStatus.canceled.isPending, isFalse);
    });

    test('pending isPending', () {
      expect(PurchaseStatus.pending.isPending, isTrue);
      expect(PurchaseStatus.pending.isCompleted, isFalse);
      expect(PurchaseStatus.pending.isFailed, isFalse);
    });
  });
}
