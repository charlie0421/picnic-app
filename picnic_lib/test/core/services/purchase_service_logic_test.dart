import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';

/// Tests for PurchaseConstants, PurchaseError, PurchaseResult, PurchaseEnvironment,
/// ReceiptFormat, PurchaseStatusExtension, and ReusedPurchaseException.
///
/// The PurchaseService class itself cannot be instantiated in unit tests
/// because it depends on InAppPurchaseService (native plugin).
void main() {
  group('PurchaseConstants', () {
    test('timeout constants have expected values', () {
      expect(PurchaseConstants.purchaseTimeout, const Duration(seconds: 30));
      expect(PurchaseConstants.debugPurchaseTimeout, const Duration(seconds: 3));
      expect(
          PurchaseConstants.ultraFastTimeout, const Duration(milliseconds: 500));
      expect(PurchaseConstants.instantTimeout, const Duration(milliseconds: 100));
      expect(
          PurchaseConstants.verificationTimeout, const Duration(seconds: 30));
      expect(PurchaseConstants.sandboxVerificationTimeout,
          const Duration(seconds: 60));
    });

    test('guard constants', () {
      expect(PurchaseConstants.authenticationGracePeriod,
          const Duration(milliseconds: 300));
      expect(PurchaseConstants.backgroundPurchaseWindow,
          const Duration(milliseconds: 300));
      expect(PurchaseConstants.purchaseBlockingPeriod,
          const Duration(milliseconds: 300));
      expect(
          PurchaseConstants.cooldownPeriod, const Duration(milliseconds: 300));
      expect(
          PurchaseConstants.initializationDelay, const Duration(seconds: 2));
      expect(PurchaseConstants.cacheRefreshDelay, const Duration(seconds: 1));
    });

    test('retry constants', () {
      expect(PurchaseConstants.maxRetries, 3);
      expect(PurchaseConstants.sandboxMaxRetries, 5);
      expect(PurchaseConstants.baseRetryDelay, 2);
    });

    test('error message keys', () {
      expect(PurchaseConstants.userNotAuthenticatedErrorKey,
          'error_user_not_authenticated');
      expect(
          PurchaseConstants.productNotFoundErrorKey, 'error_product_not_found');
      expect(PurchaseConstants.receiptVerificationErrorKey,
          'error_receipt_verification_failed');
      expect(PurchaseConstants.duplicatePurchaseErrorKey,
          'error_duplicate_purchase');
      expect(PurchaseConstants.initializingErrorKey, 'error_initializing');
      expect(PurchaseConstants.purchaseInProgressErrorKey,
          'error_purchase_in_progress');
    });

    test('error codes', () {
      expect(PurchaseConstants.errPrevTransactionPending, 'ERR_PREV_TX');
      expect(PurchaseConstants.errCooldownActive, 'ERR_COOLDOWN');
      expect(PurchaseConstants.errPurchaseCanceled, 'ERR_PURCHASE_CANCELED');
      expect(PurchaseConstants.errInProgress, 'ERR_IN_PROGRESS');
      expect(PurchaseConstants.errTimeout, 'TIMEOUT');
      expect(PurchaseConstants.errAuthTimeout, 'AUTH_TIMEOUT');
      expect(PurchaseConstants.errNetwork, 'NETWORK');
      expect(PurchaseConstants.errServer, 'SERVER');
      expect(PurchaseConstants.errConcurrent, 'ERR_CONCURRENT');
      expect(PurchaseConstants.errTooSoon, 'ERR_TOO_SOON');
      expect(PurchaseConstants.errRecentPurchase, 'ERR_RECENT_PURCHASE');
      expect(PurchaseConstants.errRequestDuplicate, 'ERR_REQUEST_DUPLICATE');
    });

    test('SharedPreferences keys', () {
      expect(PurchaseConstants.testDialogShownKey,
          'test_environment_dialog_shown');
      expect(
          PurchaseConstants.lastPurchaseAttemptKey, 'last_purchase_attempt_');
      expect(
          PurchaseConstants.authenticationStartKey, 'authentication_start_');
      expect(PurchaseConstants.backgroundPurchaseKey, 'background_purchase_');
    });
  });

  group('PurchaseResult enum', () {
    test('has all expected values', () {
      expect(PurchaseResult.values.length, 5);
      expect(PurchaseResult.success.name, 'success');
      expect(PurchaseResult.failed.name, 'failed');
      expect(PurchaseResult.canceled.name, 'canceled');
      expect(PurchaseResult.duplicate.name, 'duplicate');
      expect(PurchaseResult.timeout.name, 'timeout');
    });
  });

  group('PurchaseEnvironment enum', () {
    test('has all expected values', () {
      expect(PurchaseEnvironment.values.length, 3);
      expect(PurchaseEnvironment.sandbox.name, 'sandbox');
      expect(PurchaseEnvironment.production.name, 'production');
      expect(PurchaseEnvironment.unknown.name, 'unknown');
    });
  });

  group('ReceiptFormat enum', () {
    test('has all expected values', () {
      expect(ReceiptFormat.values.length, 4);
      expect(ReceiptFormat.storeKit2JWT.name, 'storeKit2JWT');
      expect(ReceiptFormat.storeKit1Base64.name, 'storeKit1Base64');
      expect(ReceiptFormat.googlePlay.name, 'googlePlay');
      expect(ReceiptFormat.unknown.name, 'unknown');
    });
  });

  group('PurchaseError', () {
    test('constructor creates with code and message', () {
      const error = PurchaseError(code: 'TEST', message: 'test message');
      expect(error.code, 'TEST');
      expect(error.message, 'test message');
      expect(error.details, isNull);
    });

    test('constructor with details', () {
      const error = PurchaseError(
        code: 'ERR',
        message: 'msg',
        details: 'extra info',
      );
      expect(error.details, 'extra info');
    });

    test('toString without details', () {
      const error = PurchaseError(code: 'ERR', message: 'msg');
      expect(error.toString(), 'ERR: msg');
    });

    test('toString with details', () {
      const error =
          PurchaseError(code: 'ERR', message: 'msg', details: 'detail');
      expect(error.toString(), 'ERR: msg (detail)');
    });

    test('static userNotAuthenticated', () {
      expect(PurchaseError.userNotAuthenticated.code, 'USER_NOT_AUTHENTICATED');
      expect(PurchaseError.userNotAuthenticated.message,
          PurchaseConstants.userNotAuthenticatedErrorKey);
    });

    test('static productNotFound', () {
      expect(PurchaseError.productNotFound.code, 'PRODUCT_NOT_FOUND');
      expect(PurchaseError.productNotFound.message,
          PurchaseConstants.productNotFoundErrorKey);
    });

    test('static receiptVerification', () {
      expect(
          PurchaseError.receiptVerification.code, 'RECEIPT_VERIFICATION_FAILED');
      expect(PurchaseError.receiptVerification.message,
          PurchaseConstants.receiptVerificationErrorKey);
    });

    test('static duplicatePurchase', () {
      expect(PurchaseError.duplicatePurchase.code, 'DUPLICATE_PURCHASE');
      expect(PurchaseError.duplicatePurchase.message,
          PurchaseConstants.duplicatePurchaseErrorKey);
    });
  });

  group('PurchaseStatusExtension', () {
    test('isCompleted for purchased', () {
      expect(PurchaseStatus.purchased.isCompleted, isTrue);
    });

    test('isCompleted for restored', () {
      expect(PurchaseStatus.restored.isCompleted, isTrue);
    });

    test('isCompleted for pending is false', () {
      expect(PurchaseStatus.pending.isCompleted, isFalse);
    });

    test('isCompleted for error is false', () {
      expect(PurchaseStatus.error.isCompleted, isFalse);
    });

    test('isCompleted for canceled is false', () {
      expect(PurchaseStatus.canceled.isCompleted, isFalse);
    });

    test('isFailed for error', () {
      expect(PurchaseStatus.error.isFailed, isTrue);
    });

    test('isFailed for canceled', () {
      expect(PurchaseStatus.canceled.isFailed, isTrue);
    });

    test('isFailed for purchased is false', () {
      expect(PurchaseStatus.purchased.isFailed, isFalse);
    });

    test('isFailed for pending is false', () {
      expect(PurchaseStatus.pending.isFailed, isFalse);
    });

    test('isPending for pending', () {
      expect(PurchaseStatus.pending.isPending, isTrue);
    });

    test('isPending for purchased is false', () {
      expect(PurchaseStatus.purchased.isPending, isFalse);
    });

    test('isPending for error is false', () {
      expect(PurchaseStatus.error.isPending, isFalse);
    });

    test('all statuses have exactly one true state', () {
      for (final status in PurchaseStatus.values) {
        final states = [status.isCompleted, status.isFailed, status.isPending];
        final trueCount = states.where((s) => s).length;
        expect(trueCount, 1,
            reason: '$status should have exactly one true state');
      }
    });
  });

  group('ReusedPurchaseException', () {
    test('creates with message', () {
      final exception = ReusedPurchaseException(message: 'Duplicate');
      expect(exception.message, 'Duplicate');
      expect(exception.receiptId, isNull);
    });

    test('creates with message and receiptId', () {
      final exception = ReusedPurchaseException(
        message: 'Duplicate',
        receiptId: 'receipt_123',
      );
      expect(exception.message, 'Duplicate');
      expect(exception.receiptId, 'receipt_123');
    });

    test('toString format', () {
      final exception =
          ReusedPurchaseException(message: 'Already processed');
      expect(
          exception.toString(), 'ReusedPurchaseException: Already processed');
    });

    test('implements Exception', () {
      final exception = ReusedPurchaseException(message: 'test');
      expect(exception, isA<Exception>());
    });
  });
}
