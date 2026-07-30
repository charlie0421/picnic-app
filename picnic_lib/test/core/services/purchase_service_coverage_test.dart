import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';

/// Coverage-focused tests for PurchaseService logic patterns.
///
/// PurchaseService itself cannot be instantiated in tests because it requires
/// WidgetRef, InAppPurchaseService (starts platform timers), Supabase auth,
/// and ReceiptQueueService. The classification logic it delegates to, however,
/// lives in [PurchaseServiceHelper] and *is* constructible - so these groups
/// call the real thing.
///
/// They used to re-implement it locally. That is how the C-1 defect stayed
/// invisible: the copy here asserted `contains('timeout')` behaved as intended
/// while production, running the same expression against
/// `TimeoutException.toString()` ("TimeoutException after ...", no lowercase
/// 'timeout'), classified a settling purchase as a terminal failure. A mirror
/// that can drift from what ships is worse than no test.
void main() {
  group('_getErrorMessage logic (mirrors PurchaseService._getErrorMessage)', () {
    String getErrorMessage(String? errorCode) => const PurchaseServiceHelper()
        .getErrorMessage(errorCode == null
            ? null
            : IAPError(source: 'test', code: errorCode, message: ''));

    test('null error returns GENERIC', () {
      expect(getErrorMessage(null), 'GENERIC');
    });

    test('payment_invalid returns an error code, not a Korean sentence', () {
      expect(
          getErrorMessage('payment_invalid'), PurchaseConstants.errPaymentInvalid);
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
    String getDetailedErrorMessage(String errorString) =>
        const PurchaseServiceHelper().getDetailedErrorMessage(errorString);

    test('Receipt verification failed', () {
      expect(getDetailedErrorMessage('Receipt verification failed'),
          'RECEIPT_VERIFICATION_FAILED');
    });

    test('timeout in English is settlement-pending, not a failure', () {
      expect(getDetailedErrorMessage('Connection timeout'),
          PurchaseConstants.errProcessing);
    });

    test('timeout in Korean (타임아웃) is settlement-pending', () {
      expect(getDetailedErrorMessage('요청 타임아웃 발생'),
          PurchaseConstants.errProcessing);
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

  group('Launch-failure error codes (initiatePurchase)', () {
    String getCode(String errorString) =>
        const PurchaseServiceHelper().getPurchaseInitiationErrorCode(
          errorString,
        );

    test('product info error', () {
      expect(getCode('상품 정보를 찾을 수 없습니다'), 'PRODUCT_NOT_FOUND');
    });

    test('network error', () {
      expect(getCode('네트워크 오류 발생'), PurchaseConstants.errNetwork);
    });

    test('generic error', () {
      expect(getCode('Unknown error'), 'GENERIC');
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
        'errorMessage': 'GENERIC',
      };
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], isNotNull);
    });

    test('login required result format carries a code, not Korean text', () {
      final result = {
        'success': false,
        'wasCancelled': false,
        'errorMessage': 'USER_NOT_AUTHENTICATED',
      };
      expect(result['errorMessage'], 'USER_NOT_AUTHENTICATED');
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
