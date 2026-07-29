import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';

void main() {
  /// The guarantee `PurchaseSettlementStep` settles against.
  ///
  /// `cleanupAllTimersOnSuccess` tears down three independent timer owners -
  /// `PurchaseSafetyManager`, `RestorePurchaseHandler` and
  /// `InAppPurchaseService` - after the charge has gone through but before the
  /// wallet is credited and the receipt is shown. The step takes it as a plain
  /// `void` seam and has no catch of its own, so anything escaping this cleanup
  /// would abort a settlement whose money has already moved.
  ///
  /// Driving the three real collaborators would mean constructing a live
  /// `PurchaseService` (StoreKit/Play init, receipt queue, Supabase), so the
  /// guard itself is what is pinned here.
  group('PurchaseProcessor.runTimerCleanupGuarded', () {
    test('swallows a throwing timer owner', () {
      expect(
        () => PurchaseProcessor.runTimerCleanupGuarded(
          () => throw StateError('timer owner already disposed'),
        ),
        returnsNormally,
      );
    });

    test('runs the cleanup it is given', () {
      var ran = 0;
      PurchaseProcessor.runTimerCleanupGuarded(() => ran++);
      expect(ran, 1);
    });
  });

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

  group('PurchaseProcessor.isTerminalMappedError', () {
    // 종결 여부는 `_processActivePurchase`의 showMappedError 분기가 어템프트와
    // 90초 안전망 타이머를 함께 내릴지 결정한다. 종결인데 살려 두면 에러
    // 다이얼로그 뒤에 "구매 처리 지연" 팝업이 또 뜨고(1.3.0 베타), 비종결인데
    // 내리면 늦게 도착한 정산이 바인딩할 어템프트를 잃는다.
    test('timeout and network failures keep the attempt alive', () {
      expect(
        PurchaseProcessor.isTerminalMappedError(PurchaseErrorType.timeout),
        isFalse,
      );
      expect(
        PurchaseProcessor.isTerminalMappedError(PurchaseErrorType.networkError),
        isFalse,
      );
    });

    test('every other mapped error ends the attempt', () {
      const terminal = [
        PurchaseErrorType.previousTransactionPending,
        PurchaseErrorType.receiptVerificationFailed,
        PurchaseErrorType.userNotAuthenticated,
        PurchaseErrorType.productNotFound,
        PurchaseErrorType.purchaseFailed,
        PurchaseErrorType.serverError,
        PurchaseErrorType.purchaseCancelled,
        PurchaseErrorType.purchaseInProgress,
      ];
      for (final type in terminal) {
        expect(
          PurchaseProcessor.isTerminalMappedError(type),
          isTrue,
          reason: '$type must tear the attempt and its safety timer down',
        );
      }
    });
  });
}
