import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

void main() {
  group('PurchaseConstants', () {
    test('timeout values are set', () {
      expect(PurchaseConstants.purchaseTimeout, const Duration(seconds: 30));
      expect(PurchaseConstants.debugPurchaseTimeout, const Duration(seconds: 3));
      expect(PurchaseConstants.ultraFastTimeout, const Duration(milliseconds: 500));
      expect(PurchaseConstants.instantTimeout, const Duration(milliseconds: 100));
      expect(PurchaseConstants.verificationTimeout, const Duration(seconds: 30));
      expect(PurchaseConstants.sandboxVerificationTimeout, const Duration(seconds: 60));
    });

    test('retry values', () {
      expect(PurchaseConstants.maxRetries, 3);
      expect(PurchaseConstants.sandboxMaxRetries, 5);
      expect(PurchaseConstants.baseRetryDelay, 2);
    });

    test('error keys are non-empty strings', () {
      expect(PurchaseConstants.userNotAuthenticatedErrorKey, isNotEmpty);
      expect(PurchaseConstants.productNotFoundErrorKey, isNotEmpty);
      expect(PurchaseConstants.receiptVerificationErrorKey, isNotEmpty);
      expect(PurchaseConstants.duplicatePurchaseErrorKey, isNotEmpty);
      expect(PurchaseConstants.initializingErrorKey, isNotEmpty);
      expect(PurchaseConstants.purchaseInProgressErrorKey, isNotEmpty);
    });

    test('error codes are non-empty strings', () {
      expect(PurchaseConstants.errPrevTransactionPending, isNotEmpty);
      expect(PurchaseConstants.errCooldownActive, isNotEmpty);
      expect(PurchaseConstants.errPurchaseCanceled, isNotEmpty);
      expect(PurchaseConstants.errInProgress, isNotEmpty);
      expect(PurchaseConstants.errTimeout, isNotEmpty);
      expect(PurchaseConstants.errAuthTimeout, isNotEmpty);
      expect(PurchaseConstants.errNetwork, isNotEmpty);
      expect(PurchaseConstants.errServer, isNotEmpty);
      expect(PurchaseConstants.errConcurrent, isNotEmpty);
      expect(PurchaseConstants.errTooSoon, isNotEmpty);
      expect(PurchaseConstants.errRecentPurchase, isNotEmpty);
      expect(PurchaseConstants.errRequestDuplicate, isNotEmpty);
    });

    test('grace period values', () {
      expect(PurchaseConstants.authenticationGracePeriod, const Duration(milliseconds: 300));
      expect(PurchaseConstants.backgroundPurchaseWindow, const Duration(milliseconds: 300));
      expect(PurchaseConstants.purchaseBlockingPeriod, const Duration(milliseconds: 300));
      expect(PurchaseConstants.cooldownPeriod, const Duration(milliseconds: 300));
    });

    test('initialization and cache delays', () {
      expect(PurchaseConstants.initializationDelay, const Duration(seconds: 2));
      expect(PurchaseConstants.cacheRefreshDelay, const Duration(seconds: 1));
    });

    test('SharedPreferences keys', () {
      expect(PurchaseConstants.testDialogShownKey, isNotEmpty);
      expect(PurchaseConstants.lastPurchaseAttemptKey, isNotEmpty);
      expect(PurchaseConstants.authenticationStartKey, isNotEmpty);
      expect(PurchaseConstants.backgroundPurchaseKey, isNotEmpty);
    });
  });

  group('PurchaseResult enum', () {
    test('all values exist', () {
      expect(PurchaseResult.values.length, 5);
      expect(PurchaseResult.values, contains(PurchaseResult.success));
      expect(PurchaseResult.values, contains(PurchaseResult.failed));
      expect(PurchaseResult.values, contains(PurchaseResult.canceled));
      expect(PurchaseResult.values, contains(PurchaseResult.duplicate));
      expect(PurchaseResult.values, contains(PurchaseResult.timeout));
    });
  });

  group('PurchaseEnvironment enum', () {
    test('all values exist', () {
      expect(PurchaseEnvironment.values.length, 3);
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.sandbox));
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.production));
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.unknown));
    });
  });

  group('ReceiptFormat enum', () {
    test('all values exist', () {
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
      const error = PurchaseError(code: 'TEST', message: 'msg', details: 'extra');
      expect(error.toString(), 'TEST: msg (extra)');
    });

    test('static errors', () {
      expect(PurchaseError.userNotAuthenticated.code, 'USER_NOT_AUTHENTICATED');
      expect(PurchaseError.productNotFound.code, 'PRODUCT_NOT_FOUND');
      expect(PurchaseError.receiptVerification.code, 'RECEIPT_VERIFICATION_FAILED');
      expect(PurchaseError.duplicatePurchase.code, 'DUPLICATE_PURCHASE');
    });
  });

  group('PurchaseStatusExtension', () {
    test('isCompleted for purchased', () {
      expect(PurchaseStatus.purchased.isCompleted, isTrue);
      expect(PurchaseStatus.restored.isCompleted, isTrue);
      expect(PurchaseStatus.pending.isCompleted, isFalse);
      expect(PurchaseStatus.error.isCompleted, isFalse);
    });

    test('isFailed', () {
      expect(PurchaseStatus.error.isFailed, isTrue);
      expect(PurchaseStatus.canceled.isFailed, isTrue);
      expect(PurchaseStatus.purchased.isFailed, isFalse);
      expect(PurchaseStatus.pending.isFailed, isFalse);
    });

    test('isPending', () {
      expect(PurchaseStatus.pending.isPending, isTrue);
      expect(PurchaseStatus.purchased.isPending, isFalse);
      expect(PurchaseStatus.error.isPending, isFalse);
    });
  });
}
