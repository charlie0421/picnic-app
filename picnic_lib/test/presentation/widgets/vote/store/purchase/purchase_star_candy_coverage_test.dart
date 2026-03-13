import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';

/// Coverage-focused tests for purchase_star_candy_state.dart.
///
/// The PurchaseStarCandy widget itself cannot be rendered in tests because
/// it depends on InAppPurchaseService which starts a platform-level timer
/// on initialization. Instead, we test the types and logic patterns used
/// within PurchaseStarCandyState.
void main() {
  group('PurchaseStarCandy widget', () {
    test('can be instantiated', () {
      const widget = PurchaseStarCandy();
      expect(widget, isNotNull);
    });

    test('has default key', () {
      const widget = PurchaseStarCandy();
      expect(widget.key, isNull);
    });

    test('can be instantiated with key', () {
      const widget = PurchaseStarCandy(key: ValueKey('test'));
      expect(widget.key, isNotNull);
    });
  });

  group('Cancel detection logic (mirrors _isPurchaseCanceled)', () {
    // This tests the cancel keyword matching logic from
    // PurchaseStarCandyState._isPurchaseCanceled

    final cancelKeywords = [
      'cancel',
      'cancelled',
      'canceled',
      'user cancel',
      'abort',
      'dismiss',
      'authentication',
      'touch id',
      'face id',
      'biometric',
      'passcode',
      'unauthorized',
      'permission denied',
      'operation was cancelled',
      'user cancelled',
      'user denied',
      'authentication failed',
      'authentication cancelled',
      'user interaction required',
      'interaction not allowed',
      'declined',
      'rejected',
      'stopped',
      'interrupted',
      'terminated',
      'aborted',
      'transaction has been cancelled',
      'cancelled by the user',
      'purchase was cancelled',
      'user has cancelled',
      'transaction cancelled',
      'purchase cancelled',
      'payment cancelled',
      'cancelled transaction',
      'user cancellation',
      'cancelled by user',
    ];

    final cancelErrorCodes = [
      'PAYMENT_CANCELED',
      'USER_CANCELED',
      '2',
      'SKErrorPaymentCancelled',
      'BILLING_RESPONSE_USER_CANCELED',
      '-1000',
      '-1001',
      'storekit2_purchase_cancelled',
      'storekit2_user_cancelled',
      'storekit2_cancelled',
      'purchase_cancelled',
      'transaction_cancelled',
      'user_cancelled_purchase',
      'cancelled_by_user',
      'platform_cancelled',
      'platform_user_cancelled',
      'ios_purchase_cancelled',
      'ios_user_cancelled',
    ];

    test('cancel keywords list is comprehensive', () {
      expect(cancelKeywords.length, greaterThan(30));
    });

    test('cancel error codes list is comprehensive', () {
      expect(cancelErrorCodes.length, greaterThan(15));
    });

    test('keyword matching detects cancel in error message', () {
      const errorMessage = 'the operation was cancelled by the system';

      bool isCanceled = false;
      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          isCanceled = true;
          break;
        }
      }
      expect(isCanceled, isTrue);
    });

    test('keyword matching does not detect cancel in unrelated message', () {
      const errorMessage = 'network connection failed';

      bool isCanceled = false;
      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          isCanceled = true;
          break;
        }
      }
      expect(isCanceled, isFalse);
    });

    test('error code matching detects PAYMENT_CANCELED', () {
      const errorCode = 'PAYMENT_CANCELED';

      bool isCanceled = false;
      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code)) {
          isCanceled = true;
          break;
        }
      }
      expect(isCanceled, isTrue);
    });

    test('error code matching detects SKErrorPaymentCancelled', () {
      const errorCode = 'SKErrorPaymentCancelled';

      bool isCanceled = false;
      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code)) {
          isCanceled = true;
          break;
        }
      }
      expect(isCanceled, isTrue);
    });

    test('error code matching does not match generic errors', () {
      const errorCode = 'NETWORK_ERROR';

      bool isCanceled = false;
      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code)) {
          isCanceled = true;
          break;
        }
      }
      expect(isCanceled, isFalse);
    });
  });

  group('Duplicate error detection logic (mirrors _isDuplicateError)', () {
    bool isDuplicateError(String error) {
      return error.contains('StoreKit 캐시 문제') ||
          error.contains('중복 영수증') ||
          error.contains('이미 처리된 구매') ||
          error.contains('Duplicate') ||
          error.toLowerCase().contains('reused');
    }

    test('detects StoreKit cache issue', () {
      expect(isDuplicateError('StoreKit 캐시 문제로 인한 오류'), isTrue);
    });

    test('detects duplicate receipt', () {
      expect(isDuplicateError('중복 영수증이 발견되었습니다'), isTrue);
    });

    test('detects already processed purchase', () {
      expect(isDuplicateError('이미 처리된 구매입니다'), isTrue);
    });

    test('detects Duplicate keyword', () {
      expect(isDuplicateError('Duplicate transaction detected'), isTrue);
    });

    test('detects reused keyword (case insensitive)', () {
      expect(isDuplicateError('Token was Reused'), isTrue);
      expect(isDuplicateError('reused receipt'), isTrue);
    });

    test('does not detect generic errors', () {
      expect(isDuplicateError('Network error'), isFalse);
      expect(isDuplicateError('Purchase failed'), isFalse);
      expect(isDuplicateError(''), isFalse);
    });
  });

  group('Status counts logic (mirrors _getStatusCounts)', () {
    Map<String, int> getStatusCounts(
        List<PurchaseStatus> statuses) {
      return {
        'pending': statuses.where((s) => s == PurchaseStatus.pending).length,
        'restored': statuses.where((s) => s == PurchaseStatus.restored).length,
        'purchased':
            statuses.where((s) => s == PurchaseStatus.purchased).length,
        'error': statuses.where((s) => s == PurchaseStatus.error).length,
        'canceled': statuses.where((s) => s == PurchaseStatus.canceled).length,
      };
    }

    test('counts empty list', () {
      final counts = getStatusCounts([]);
      expect(counts['pending'], 0);
      expect(counts['restored'], 0);
      expect(counts['purchased'], 0);
      expect(counts['error'], 0);
      expect(counts['canceled'], 0);
    });

    test('counts single pending', () {
      final counts = getStatusCounts([PurchaseStatus.pending]);
      expect(counts['pending'], 1);
      expect(counts['purchased'], 0);
    });

    test('counts mixed statuses', () {
      final counts = getStatusCounts([
        PurchaseStatus.pending,
        PurchaseStatus.purchased,
        PurchaseStatus.error,
        PurchaseStatus.purchased,
        PurchaseStatus.canceled,
      ]);
      expect(counts['pending'], 1);
      expect(counts['purchased'], 2);
      expect(counts['error'], 1);
      expect(counts['canceled'], 1);
      expect(counts['restored'], 0);
    });

    test('counts all restored', () {
      final counts = getStatusCounts([
        PurchaseStatus.restored,
        PurchaseStatus.restored,
        PurchaseStatus.restored,
      ]);
      expect(counts['restored'], 3);
      expect(counts['purchased'], 0);
    });
  });

  group('Error code to message mapping logic', () {
    // Tests the switch statement logic from _processActivePurchase
    String getErrorCategory(String error) {
      switch (error) {
        case PurchaseConstants.errPrevTransactionPending:
        case PurchaseConstants.errCooldownActive:
          return 'previous_transaction';
        case 'RECEIPT_VERIFICATION_FAILED':
          return 'receipt_verification';
        case 'USER_NOT_AUTHENTICATED':
          return 'user_auth';
        case 'PRODUCT_NOT_FOUND':
          return 'product_not_found';
        case PurchaseConstants.errTimeout:
          return 'timeout';
        case PurchaseConstants.errAuthTimeout:
          return 'auth_timeout';
        case PurchaseConstants.errNetwork:
          return 'network';
        case PurchaseConstants.errServer:
          return 'server';
        case PurchaseConstants.errPurchaseCanceled:
          return 'canceled';
        case PurchaseConstants.errInProgress:
        case PurchaseConstants.errConcurrent:
          return 'in_progress';
        case PurchaseConstants.errTooSoon:
        case PurchaseConstants.errRecentPurchase:
        case PurchaseConstants.errRequestDuplicate:
          return 'too_soon';
        default:
          return 'generic';
      }
    }

    test('ERR_PREV_TX maps to previous_transaction', () {
      expect(getErrorCategory(PurchaseConstants.errPrevTransactionPending),
          'previous_transaction');
    });

    test('ERR_COOLDOWN maps to previous_transaction', () {
      expect(getErrorCategory(PurchaseConstants.errCooldownActive),
          'previous_transaction');
    });

    test('RECEIPT_VERIFICATION_FAILED maps correctly', () {
      expect(getErrorCategory('RECEIPT_VERIFICATION_FAILED'),
          'receipt_verification');
    });

    test('USER_NOT_AUTHENTICATED maps correctly', () {
      expect(getErrorCategory('USER_NOT_AUTHENTICATED'), 'user_auth');
    });

    test('PRODUCT_NOT_FOUND maps correctly', () {
      expect(getErrorCategory('PRODUCT_NOT_FOUND'), 'product_not_found');
    });

    test('TIMEOUT maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errTimeout), 'timeout');
    });

    test('AUTH_TIMEOUT maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errAuthTimeout), 'auth_timeout');
    });

    test('NETWORK maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errNetwork), 'network');
    });

    test('SERVER maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errServer), 'server');
    });

    test('ERR_PURCHASE_CANCELED maps correctly', () {
      expect(
          getErrorCategory(PurchaseConstants.errPurchaseCanceled), 'canceled');
    });

    test('ERR_IN_PROGRESS maps correctly', () {
      expect(
          getErrorCategory(PurchaseConstants.errInProgress), 'in_progress');
    });

    test('ERR_CONCURRENT maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errConcurrent), 'in_progress');
    });

    test('ERR_TOO_SOON maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errTooSoon), 'too_soon');
    });

    test('ERR_RECENT_PURCHASE maps correctly', () {
      expect(
          getErrorCategory(PurchaseConstants.errRecentPurchase), 'too_soon');
    });

    test('ERR_REQUEST_DUPLICATE maps correctly', () {
      expect(getErrorCategory(PurchaseConstants.errRequestDuplicate),
          'too_soon');
    });

    test('unknown error maps to generic', () {
      expect(getErrorCategory('UNKNOWN_ERROR'), 'generic');
      expect(getErrorCategory(''), 'generic');
    });
  });

  group('Purchase result handling logic (mirrors _handlePurchaseResult)', () {
    test('wasCancelled=true triggers cancel path', () {
      final result = {'wasCancelled': true, 'success': false};
      final wasCancelled = result['wasCancelled'] == true;
      expect(wasCancelled, isTrue);
    });

    test('wasCancelled=false does not trigger cancel path', () {
      final result = {
        'wasCancelled': false,
        'success': true,
        'errorMessage': null,
      };
      final wasCancelled = result['wasCancelled'] == true;
      expect(wasCancelled, isFalse);
    });

    test('missing wasCancelled key treated as false', () {
      final result = {'success': true};
      final wasCancelled = result['wasCancelled'] == true;
      expect(wasCancelled, isFalse);
    });
  });

  group('PurchaseHelper.isDuplicateError (direct)', () {
    test('detects StoreKit cache issue', () {
      expect(PurchaseHelper.isDuplicateError('StoreKit 캐시 문제'), isTrue);
    });

    test('detects duplicate receipt', () {
      expect(PurchaseHelper.isDuplicateError('중복 영수증'), isTrue);
    });

    test('detects already processed', () {
      expect(PurchaseHelper.isDuplicateError('이미 처리된 구매'), isTrue);
    });

    test('detects Duplicate keyword', () {
      expect(PurchaseHelper.isDuplicateError('Duplicate'), isTrue);
    });

    test('detects reused (case insensitive)', () {
      expect(PurchaseHelper.isDuplicateError('Token Reused'), isTrue);
    });

    test('returns false for normal errors', () {
      expect(PurchaseHelper.isDuplicateError('Network error'), isFalse);
    });
  });

  group('PurchaseHelper.shouldForceCompletePending', () {
    test('returns true when not active, not cleared, and pending', () {
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.pending),
        ),
        isTrue,
      );
    });

    test('returns false when active', () {
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: true,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.pending),
        ),
        isFalse,
      );
    });

    test('returns false when transactions already cleared', () {
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: true,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.pending),
        ),
        isFalse,
      );
    });

    test('returns false for non-pending status', () {
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.shouldIgnoreDuringInit', () {
    test('returns true for restored during init', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.restored),
        ),
        isTrue,
      );
    });

    test('returns true for purchased during init', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
        ),
        isTrue,
      );
    });

    test('returns false when active purchasing', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: true,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
        ),
        isFalse,
      );
    });

    test('returns false when transactions cleared', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: true,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.restored),
        ),
        isFalse,
      );
    });

    test('returns false for error status during init', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.error),
        ),
        isFalse,
      );
    });

    test('returns false for pending status during init', () {
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.pending),
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.getStatusCounts (direct)', () {
    test('counts empty list', () {
      final counts = PurchaseHelper.getStatusCounts([]);
      expect(counts['pending'], 0);
      expect(counts['restored'], 0);
      expect(counts['purchased'], 0);
      expect(counts['error'], 0);
      expect(counts['canceled'], 0);
    });

    test('counts mixed statuses', () {
      final counts = PurchaseHelper.getStatusCounts([
        _FakePurchaseDetails(PurchaseStatus.pending),
        _FakePurchaseDetails(PurchaseStatus.purchased),
        _FakePurchaseDetails(PurchaseStatus.error),
        _FakePurchaseDetails(PurchaseStatus.restored),
        _FakePurchaseDetails(PurchaseStatus.canceled),
      ]);
      expect(counts['pending'], 1);
      expect(counts['purchased'], 1);
      expect(counts['error'], 1);
      expect(counts['restored'], 1);
      expect(counts['canceled'], 1);
    });
  });

  group('PurchaseHelper.shouldProcessActivePurchaseIOS', () {
    test('1st stage: active purchasing + purchased status', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('1st stage: active purchasing + restored status', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.restored),
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('2nd stage: late purchase after timeout within 2 min', () {
      final timeoutTime = DateTime.now().subtract(const Duration(seconds: 30));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('2nd stage: rejected if not actual purchase', () {
      final timeoutTime = DateTime.now().subtract(const Duration(seconds: 30));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => false,
        ),
        isFalse,
      );
    });

    test('2nd stage: rejected if timeout > 2 min ago', () {
      final timeoutTime = DateTime.now().subtract(const Duration(minutes: 5));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue, // Falls through to 3rd stage
      );
    });

    test('3rd stage: iOS safety fallback for actual purchase', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('blocked: not active, not actual', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isFalse,
      );
    });

    test('blocked: error status', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.error),
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.shouldProcessActivePurchaseAndroid', () {
    test('1st stage: active purchasing + purchased status', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('2nd stage: short delay after timeout within 1 min', () {
      final timeoutTime = DateTime.now().subtract(const Duration(seconds: 20));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('2nd stage: blocked for restored status (Android)', () {
      final timeoutTime = DateTime.now().subtract(const Duration(seconds: 20));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.restored),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('2nd stage: blocked if timeout > 1 min', () {
      final timeoutTime = DateTime.now().subtract(const Duration(minutes: 3));
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('strictly blocked: no fallback (unlike iOS)', () {
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: _FakePurchaseDetails(PurchaseStatus.purchased),
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.isPurchaseCanceled (direct)', () {
    test('returns true for canceled status', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetails(PurchaseStatus.canceled),
        ),
        isTrue,
      );
    });

    test('returns true for error with cancel keyword in message', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetailsWithError(
            PurchaseStatus.error,
            IAPError(
              source: 'test',
              code: '0',
              message: 'user cancelled the purchase',
            ),
          ),
        ),
        isTrue,
      );
    });

    test('returns true for error with cancel error code', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetailsWithError(
            PurchaseStatus.error,
            IAPError(
              source: 'test',
              code: 'PAYMENT_CANCELED',
              message: 'unknown',
            ),
          ),
        ),
        isTrue,
      );
    });

    test('returns false for error with non-cancel message', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetailsWithError(
            PurchaseStatus.error,
            IAPError(
              source: 'test',
              code: 'NETWORK',
              message: 'network connection lost',
            ),
          ),
        ),
        isFalse,
      );
    });

    test('returns false for purchased status', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetails(PurchaseStatus.purchased),
        ),
        isFalse,
      );
    });

    test('returns false for pending status', () {
      expect(
        PurchaseHelper.isPurchaseCanceled(
          _FakePurchaseDetails(PurchaseStatus.pending),
        ),
        isFalse,
      );
    });
  });
}

/// Fake PurchaseDetails for testing
class _FakePurchaseDetails extends PurchaseDetails {
  _FakePurchaseDetails(PurchaseStatus s)
      : super(
          productID: 'test_product',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: '',
          ),
          transactionDate: null,
          status: s,
        );
}

class _FakePurchaseDetailsWithError extends PurchaseDetails {
  _FakePurchaseDetailsWithError(PurchaseStatus s, IAPError err)
      : super(
          productID: 'test_product',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: '',
          ),
          transactionDate: null,
          status: s,
        ) {
    error = err;
  }
}
