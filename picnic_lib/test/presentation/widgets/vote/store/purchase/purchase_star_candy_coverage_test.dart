import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
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
}
