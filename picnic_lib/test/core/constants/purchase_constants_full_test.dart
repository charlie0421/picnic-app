import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

void main() {
  group('PurchaseConstants', () {
    test('timeout values are positive', () {
      expect(PurchaseConstants.purchaseTimeout.inSeconds, 30);
      expect(PurchaseConstants.debugPurchaseTimeout.inSeconds, 3);
      expect(PurchaseConstants.verificationTimeout.inSeconds, 30);
      expect(PurchaseConstants.sandboxVerificationTimeout.inSeconds, 60);
    });

    test('sandbox timeout is longer than production', () {
      expect(
        PurchaseConstants.sandboxVerificationTimeout,
        greaterThan(PurchaseConstants.verificationTimeout),
      );
    });

    test('retry values', () {
      expect(PurchaseConstants.maxRetries, 3);
      expect(PurchaseConstants.sandboxMaxRetries, 5);
      expect(PurchaseConstants.baseRetryDelay, 2);
    });

    test('error code constants are non-empty', () {
      expect(PurchaseConstants.errPrevTransactionPending, isNotEmpty);
      expect(PurchaseConstants.errCooldownActive, isNotEmpty);
      expect(PurchaseConstants.errPurchaseCanceled, isNotEmpty);
      expect(PurchaseConstants.errInProgress, isNotEmpty);
      expect(PurchaseConstants.errTimeout, isNotEmpty);
      expect(PurchaseConstants.errNetwork, isNotEmpty);
      expect(PurchaseConstants.errServer, isNotEmpty);
      expect(PurchaseConstants.errConcurrent, isNotEmpty);
      expect(PurchaseConstants.errTooSoon, isNotEmpty);
    });

    test('sharedPreferences keys are non-empty', () {
      expect(PurchaseConstants.testDialogShownKey, isNotEmpty);
      expect(PurchaseConstants.lastPurchaseAttemptKey, isNotEmpty);
      expect(PurchaseConstants.authenticationStartKey, isNotEmpty);
      expect(PurchaseConstants.backgroundPurchaseKey, isNotEmpty);
    });

    test('error message keys are non-empty', () {
      expect(PurchaseConstants.userNotAuthenticatedErrorKey, isNotEmpty);
      expect(PurchaseConstants.productNotFoundErrorKey, isNotEmpty);
      expect(PurchaseConstants.receiptVerificationErrorKey, isNotEmpty);
      expect(PurchaseConstants.duplicatePurchaseErrorKey, isNotEmpty);
    });
  });

  group('PurchaseResult', () {
    test('has all expected values', () {
      expect(PurchaseResult.values.length, 5);
      expect(PurchaseResult.values, contains(PurchaseResult.success));
      expect(PurchaseResult.values, contains(PurchaseResult.failed));
      expect(PurchaseResult.values, contains(PurchaseResult.canceled));
      expect(PurchaseResult.values, contains(PurchaseResult.duplicate));
      expect(PurchaseResult.values, contains(PurchaseResult.timeout));
    });
  });

  group('PurchaseEnvironment', () {
    test('has all expected values', () {
      expect(PurchaseEnvironment.values.length, 3);
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.sandbox));
      expect(
          PurchaseEnvironment.values, contains(PurchaseEnvironment.production));
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.unknown));
    });
  });

  group('ReceiptFormat', () {
    test('has all expected values', () {
      expect(ReceiptFormat.values.length, 4);
      expect(ReceiptFormat.values, contains(ReceiptFormat.storeKit2JWT));
      expect(ReceiptFormat.values, contains(ReceiptFormat.storeKit1Base64));
      expect(ReceiptFormat.values, contains(ReceiptFormat.googlePlay));
      expect(ReceiptFormat.values, contains(ReceiptFormat.unknown));
    });
  });

  group('PurchaseError', () {
    test('toString without details', () {
      const error = PurchaseError(code: 'TEST', message: 'test message');
      expect(error.toString(), 'TEST: test message');
    });

    test('toString with details', () {
      const error =
          PurchaseError(code: 'TEST', message: 'msg', details: 'info');
      expect(error.toString(), 'TEST: msg (info)');
    });

    test('predefined errors have correct codes', () {
      expect(PurchaseError.userNotAuthenticated.code, 'USER_NOT_AUTHENTICATED');
      expect(PurchaseError.productNotFound.code, 'PRODUCT_NOT_FOUND');
      expect(PurchaseError.receiptVerification.code,
          'RECEIPT_VERIFICATION_FAILED');
      expect(PurchaseError.duplicatePurchase.code, 'DUPLICATE_PURCHASE');
    });

    test('predefined errors reference constants for messages', () {
      expect(PurchaseError.userNotAuthenticated.message,
          PurchaseConstants.userNotAuthenticatedErrorKey);
      expect(PurchaseError.productNotFound.message,
          PurchaseConstants.productNotFoundErrorKey);
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

    test('isFailed for error', () {
      expect(PurchaseStatus.error.isFailed, isTrue);
    });

    test('isFailed for canceled', () {
      expect(PurchaseStatus.canceled.isFailed, isTrue);
    });

    test('isFailed for purchased is false', () {
      expect(PurchaseStatus.purchased.isFailed, isFalse);
    });

    test('isPending for pending', () {
      expect(PurchaseStatus.pending.isPending, isTrue);
    });

    test('isPending for purchased is false', () {
      expect(PurchaseStatus.purchased.isPending, isFalse);
    });
  });
}
