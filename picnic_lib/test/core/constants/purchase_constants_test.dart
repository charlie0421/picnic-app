import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

void main() {
  group('PurchaseConstants 타임아웃', () {
    test('purchaseTimeout은 30초', () {
      expect(
          PurchaseConstants.purchaseTimeout, equals(const Duration(seconds: 30)));
    });

    test('디버그 타임아웃은 프로덕션보다 짧음', () {
      expect(PurchaseConstants.debugPurchaseTimeout.inMilliseconds,
          lessThan(PurchaseConstants.purchaseTimeout.inMilliseconds));
    });

    test('sandbox 검증 타임아웃이 production보다 길거나 같음', () {
      expect(PurchaseConstants.sandboxVerificationTimeout.inSeconds,
          greaterThanOrEqualTo(PurchaseConstants.verificationTimeout.inSeconds));
    });

    test('연타 방지 cooldown은 300ms', () {
      expect(PurchaseConstants.cooldownPeriod,
          equals(const Duration(milliseconds: 300)));
    });
  });

  group('PurchaseConstants 에러 코드', () {
    test('에러 코드가 비어있지 않음', () {
      expect(PurchaseConstants.errPrevTransactionPending, isNotEmpty);
      expect(PurchaseConstants.errCooldownActive, isNotEmpty);
      expect(PurchaseConstants.errPurchaseCanceled, isNotEmpty);
      expect(PurchaseConstants.errTimeout, isNotEmpty);
      expect(PurchaseConstants.errNetwork, isNotEmpty);
      expect(PurchaseConstants.errServer, isNotEmpty);
    });

    test('에러 코드가 모두 고유함', () {
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
      expect(codes.length, equals(codes.toSet().length));
    });
  });

  group('PurchaseResult', () {
    test('모든 결과 타입이 존재', () {
      expect(PurchaseResult.values, hasLength(5));
      expect(PurchaseResult.values, contains(PurchaseResult.success));
      expect(PurchaseResult.values, contains(PurchaseResult.failed));
      expect(PurchaseResult.values, contains(PurchaseResult.canceled));
      expect(PurchaseResult.values, contains(PurchaseResult.duplicate));
      expect(PurchaseResult.values, contains(PurchaseResult.timeout));
    });
  });

  group('PurchaseEnvironment', () {
    test('모든 환경 타입이 존재', () {
      expect(PurchaseEnvironment.values, hasLength(3));
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.sandbox));
      expect(
          PurchaseEnvironment.values, contains(PurchaseEnvironment.production));
      expect(PurchaseEnvironment.values, contains(PurchaseEnvironment.unknown));
    });
  });

  group('ReceiptFormat', () {
    test('모든 영수증 형식이 존재', () {
      expect(ReceiptFormat.values, hasLength(4));
      expect(ReceiptFormat.values, contains(ReceiptFormat.storeKit2JWT));
      expect(ReceiptFormat.values, contains(ReceiptFormat.googlePlay));
      expect(ReceiptFormat.values, contains(ReceiptFormat.unknown));
    });
  });

  group('PurchaseError', () {
    test('사전 정의된 에러 상수', () {
      expect(PurchaseError.userNotAuthenticated.code,
          equals('USER_NOT_AUTHENTICATED'));
      expect(PurchaseError.productNotFound.code, equals('PRODUCT_NOT_FOUND'));
      expect(PurchaseError.receiptVerification.code,
          equals('RECEIPT_VERIFICATION_FAILED'));
      expect(
          PurchaseError.duplicatePurchase.code, equals('DUPLICATE_PURCHASE'));
    });

    test('toString 포맷', () {
      const error = PurchaseError(
        code: 'TEST',
        message: 'test message',
        details: 'detail info',
      );
      expect(error.toString(), equals('TEST: test message (detail info)'));
    });

    test('details 없는 toString', () {
      const error = PurchaseError(code: 'TEST', message: 'msg');
      expect(error.toString(), equals('TEST: msg'));
    });
  });

  group('PurchaseStatusExtension', () {
    test('purchased는 isCompleted', () {
      expect(PurchaseStatus.purchased.isCompleted, isTrue);
      expect(PurchaseStatus.purchased.isFailed, isFalse);
      expect(PurchaseStatus.purchased.isPending, isFalse);
    });

    test('restored는 isCompleted', () {
      expect(PurchaseStatus.restored.isCompleted, isTrue);
    });

    test('error는 isFailed', () {
      expect(PurchaseStatus.error.isFailed, isTrue);
      expect(PurchaseStatus.error.isCompleted, isFalse);
    });

    test('canceled는 isFailed', () {
      expect(PurchaseStatus.canceled.isFailed, isTrue);
    });

    test('pending은 isPending', () {
      expect(PurchaseStatus.pending.isPending, isTrue);
      expect(PurchaseStatus.pending.isCompleted, isFalse);
      expect(PurchaseStatus.pending.isFailed, isFalse);
    });
  });
}
