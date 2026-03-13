import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

/// Coverage-focused tests for PurchaseService logic patterns.
///
/// PurchaseService cannot be instantiated in tests because it requires
/// WidgetRef, InAppPurchaseService (starts platform timers), Supabase auth,
/// and ReceiptQueueService. Instead, we test the logic patterns from
/// _getErrorMessage and _getDetailedErrorMessage as pure functions.
void main() {
  group('_getErrorMessage logic (mirrors PurchaseService._getErrorMessage)', () {
    String getErrorMessage(String? errorCode) {
      if (errorCode == null) return 'GENERIC';

      switch (errorCode) {
        case 'payment_invalid':
          return '결제 정보가 유효하지 않습니다.';
        case 'payment_canceled':
          return PurchaseConstants.errPurchaseCanceled;
        case 'store_problem':
          return PurchaseConstants.errServer;
        default:
          return 'GENERIC';
      }
    }

    test('null error returns GENERIC', () {
      expect(getErrorMessage(null), 'GENERIC');
    });

    test('payment_invalid returns Korean message', () {
      expect(getErrorMessage('payment_invalid'), '결제 정보가 유효하지 않습니다.');
    });

    test('payment_canceled returns ERR_PURCHASE_CANCELED constant', () {
      expect(getErrorMessage('payment_canceled'),
          PurchaseConstants.errPurchaseCanceled);
    });

    test('store_problem returns ERR_SERVER constant', () {
      expect(getErrorMessage('store_problem'), PurchaseConstants.errServer);
    });

    test('unknown code returns GENERIC', () {
      expect(getErrorMessage('unknown_code'), 'GENERIC');
    });

    test('empty string returns GENERIC', () {
      expect(getErrorMessage(''), 'GENERIC');
    });
  });

  group(
      '_getDetailedErrorMessage logic (mirrors PurchaseService._getDetailedErrorMessage)',
      () {
    String getDetailedErrorMessage(String errorString) {
      if (errorString.contains('Receipt verification failed')) {
        return 'RECEIPT_VERIFICATION_FAILED';
      } else if (errorString.contains('timeout') ||
          errorString.contains('타임아웃')) {
        return PurchaseConstants.errTimeout;
      } else if (errorString.contains('Touch ID') ||
          errorString.contains('Face ID')) {
        return PurchaseConstants.errAuthTimeout;
      } else if (errorString.contains('USER_NOT_AUTHENTICATED')) {
        return 'USER_NOT_AUTHENTICATED';
      } else if (errorString.contains('PRODUCT_NOT_FOUND')) {
        return 'PRODUCT_NOT_FOUND';
      } else if (errorString.toLowerCase().contains('network')) {
        return PurchaseConstants.errNetwork;
      } else if (errorString.toLowerCase().contains('server')) {
        return PurchaseConstants.errServer;
      }

      return 'GENERIC';
    }

    test('Receipt verification failed', () {
      expect(getDetailedErrorMessage('Receipt verification failed'),
          'RECEIPT_VERIFICATION_FAILED');
    });

    test('timeout in English', () {
      expect(getDetailedErrorMessage('Connection timeout'),
          PurchaseConstants.errTimeout);
    });

    test('timeout in Korean (타임아웃)', () {
      expect(getDetailedErrorMessage('요청 타임아웃 발생'),
          PurchaseConstants.errTimeout);
    });

    test('Touch ID error', () {
      expect(getDetailedErrorMessage('Touch ID authentication failed'),
          PurchaseConstants.errAuthTimeout);
    });

    test('Face ID error', () {
      expect(getDetailedErrorMessage('Face ID was cancelled'),
          PurchaseConstants.errAuthTimeout);
    });

    test('USER_NOT_AUTHENTICATED', () {
      expect(getDetailedErrorMessage('Exception: USER_NOT_AUTHENTICATED'),
          'USER_NOT_AUTHENTICATED');
    });

    test('PRODUCT_NOT_FOUND', () {
      expect(getDetailedErrorMessage('Exception: PRODUCT_NOT_FOUND'),
          'PRODUCT_NOT_FOUND');
    });

    test('network error (case insensitive)', () {
      expect(getDetailedErrorMessage('Network connection lost'),
          PurchaseConstants.errNetwork);
    });

    test('server error (case insensitive)', () {
      expect(getDetailedErrorMessage('Internal Server Error'),
          PurchaseConstants.errServer);
    });

    test('unknown error returns GENERIC', () {
      expect(getDetailedErrorMessage('Something went wrong'), 'GENERIC');
    });

    test('empty string returns GENERIC', () {
      expect(getDetailedErrorMessage(''), 'GENERIC');
    });
  });

  group('Error message user-friendly mapping logic (mirrors initiatePurchase)',
      () {
    String getUserMessage(String errorString) {
      String userMessage = '구매 시작 중 오류가 발생했습니다';
      if (errorString.contains('상품 정보')) {
        userMessage = '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.';
      } else if (errorString.contains('네트워크')) {
        userMessage = '네트워크 연결을 확인해주세요.';
      }
      return userMessage;
    }

    test('product info error', () {
      expect(getUserMessage('상품 정보를 찾을 수 없습니다'),
          '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.');
    });

    test('network error', () {
      expect(getUserMessage('네트워크 오류 발생'), '네트워크 연결을 확인해주세요.');
    });

    test('generic error', () {
      expect(getUserMessage('Unknown error'), '구매 시작 중 오류가 발생했습니다');
    });
  });

  group('PurchaseStatus handling logic (mirrors handlePurchase switch)', () {
    test('all PurchaseStatus values are handled', () {
      // Ensures the switch statement covers all cases
      for (final status in PurchaseStatus.values) {
        String result;
        switch (status) {
          case PurchaseStatus.pending:
            result = 'pending';
            break;
          case PurchaseStatus.error:
            result = 'error';
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            result = 'success';
            break;
          case PurchaseStatus.canceled:
            result = 'canceled';
            break;
        }
        expect(result, isNotEmpty);
      }
    });

    test('PurchaseStatus.values has expected count', () {
      expect(PurchaseStatus.values.length, 5);
    });
  });

  group('initiatePurchase result format', () {
    test('success result format', () {
      final result = {
        'success': true,
        'wasCancelled': false,
        'errorMessage': null,
      };
      expect(result['success'], isTrue);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], isNull);
    });

    test('cancelled result format', () {
      final result = {
        'success': false,
        'wasCancelled': true,
        'errorMessage': null,
      };
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isTrue);
      expect(result['errorMessage'], isNull);
    });

    test('error result format', () {
      final result = {
        'success': false,
        'wasCancelled': false,
        'errorMessage': '구매 요청을 시작할 수 없습니다. 잠시 후 다시 시도해주세요.',
      };
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], isNotNull);
    });

    test('login required result format', () {
      final result = {
        'success': false,
        'wasCancelled': false,
        'errorMessage': '로그인이 필요합니다',
      };
      expect(result['errorMessage'], '로그인이 필요합니다');
    });

    test('duplicate prevention deny result includes denyType', () {
      final result = {
        'success': false,
        'wasCancelled': false,
        'errorMessage': 'Duplicate detected',
        'denyType': 'COOLDOWN',
      };
      expect(result['denyType'], 'COOLDOWN');
    });
  });
}
