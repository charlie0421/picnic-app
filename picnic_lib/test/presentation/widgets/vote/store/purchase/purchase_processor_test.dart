import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';

void main() {
  group('PurchaseProcessor.classifyError', () {
    test('returns showPendingMessage for errPrevTransactionPending', () {
      expect(
        PurchaseProcessor.classifyError(
          PurchaseConstants.errPrevTransactionPending,
        ),
        PurchaseErrorAction.showPendingMessage,
      );
    });

    test('returns showCooldownMessage for errCooldownActive', () {
      expect(
        PurchaseProcessor.classifyError(PurchaseConstants.errCooldownActive),
        PurchaseErrorAction.showCooldownMessage,
      );
    });

    group('returns duplicateWithCooldown for duplicate error strings', () {
      test('containing "StoreKit 캐시 문제"', () {
        expect(
          PurchaseProcessor.classifyError('StoreKit 캐시 문제가 발생했습니다'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "중복 영수증"', () {
        expect(
          PurchaseProcessor.classifyError('중복 영수증 감지됨'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "이미 처리된 구매"', () {
        expect(
          PurchaseProcessor.classifyError('이미 처리된 구매입니다'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "Duplicate"', () {
        expect(
          PurchaseProcessor.classifyError('Duplicate transaction detected'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "reused" (case-insensitive)', () {
        expect(
          PurchaseProcessor.classifyError('Receipt was reused'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "Reused" (uppercase)', () {
        expect(
          PurchaseProcessor.classifyError('Reused receipt'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });
    });

    test('returns showMappedError for unknown error strings', () {
      expect(
        PurchaseProcessor.classifyError('SOME_UNKNOWN_ERROR'),
        PurchaseErrorAction.showMappedError,
      );
    });

    test('returns showMappedError for empty string', () {
      expect(
        PurchaseProcessor.classifyError(''),
        PurchaseErrorAction.showMappedError,
      );
    });
  });

  group('PurchaseProcessor.mapErrorToType', () {
    group('returns previousTransactionPending for pending/duplicate codes', () {
      test('errPrevTransactionPending', () {
        expect(
          PurchaseProcessor.mapErrorToType(
            PurchaseConstants.errPrevTransactionPending,
          ),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errCooldownActive', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errCooldownActive),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errTooSoon', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errTooSoon),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errRecentPurchase', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errRecentPurchase),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errRequestDuplicate', () {
        expect(
          PurchaseProcessor.mapErrorToType(
            PurchaseConstants.errRequestDuplicate,
          ),
          PurchaseErrorType.previousTransactionPending,
        );
      });
    });

    test('returns receiptVerificationFailed for RECEIPT_VERIFICATION_FAILED',
        () {
      expect(
        PurchaseProcessor.mapErrorToType('RECEIPT_VERIFICATION_FAILED'),
        PurchaseErrorType.receiptVerificationFailed,
      );
    });

    test('returns userNotAuthenticated for USER_NOT_AUTHENTICATED', () {
      expect(
        PurchaseProcessor.mapErrorToType('USER_NOT_AUTHENTICATED'),
        PurchaseErrorType.userNotAuthenticated,
      );
    });

    test('returns productNotFound for PRODUCT_NOT_FOUND', () {
      expect(
        PurchaseProcessor.mapErrorToType('PRODUCT_NOT_FOUND'),
        PurchaseErrorType.productNotFound,
      );
    });

    test('returns timeout for errTimeout', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errTimeout),
        PurchaseErrorType.timeout,
      );
    });

    test('returns purchaseFailed for errAuthTimeout', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errAuthTimeout),
        PurchaseErrorType.purchaseFailed,
      );
    });

    test('returns networkError for errNetwork', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errNetwork),
        PurchaseErrorType.networkError,
      );
    });

    test('returns serverError for errServer', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errServer),
        PurchaseErrorType.serverError,
      );
    });

    test('returns purchaseCancelled for errPurchaseCanceled', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errPurchaseCanceled),
        PurchaseErrorType.purchaseCancelled,
      );
    });

    group('returns purchaseInProgress for in-progress codes', () {
      test('errInProgress', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errInProgress),
          PurchaseErrorType.purchaseInProgress,
        );
      });

      test('errConcurrent', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errConcurrent),
          PurchaseErrorType.purchaseInProgress,
        );
      });
    });

    test('returns purchaseFailed for unknown error code', () {
      expect(
        PurchaseProcessor.mapErrorToType('UNKNOWN_ERROR'),
        PurchaseErrorType.purchaseFailed,
      );
    });

    test('returns purchaseFailed for empty string', () {
      expect(
        PurchaseProcessor.mapErrorToType(''),
        PurchaseErrorType.purchaseFailed,
      );
    });
  });
}
