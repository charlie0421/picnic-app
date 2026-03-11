import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

void main() {
  group('PurchaseValidationResult', () {
    test('허용된 결과', () {
      final result = PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );
      expect(result.allowed, isTrue);
      expect(result.reason, isNull);
      expect(result.type, isNull);
    });

    test('쿨다운으로 차단된 결과', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '너무 빠른 연속 클릭입니다.',
        type: PurchaseDenyType.cooldown,
      );
      expect(result.allowed, isFalse);
      expect(result.reason, equals('너무 빠른 연속 클릭입니다.'));
      expect(result.type, equals(PurchaseDenyType.cooldown));
    });

    test('동시 구매로 차단된 결과', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '동시 구매 감지',
        type: PurchaseDenyType.concurrent,
      );
      expect(result.type, equals(PurchaseDenyType.concurrent));
    });

    test('인증 진행 중 차단', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '인증 진행 중',
        type: PurchaseDenyType.authenticationInProgress,
      );
      expect(result.type, equals(PurchaseDenyType.authenticationInProgress));
    });

    test('백그라운드 구매 차단', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '백그라운드 구매 감지',
        type: PurchaseDenyType.backgroundPurchase,
      );
      expect(result.type, equals(PurchaseDenyType.backgroundPurchase));
    });
  });

  group('PurchaseDenyType', () {
    test('7개 유형 존재', () {
      expect(PurchaseDenyType.values.length, equals(7));
    });

    test('모든 유형 확인', () {
      expect(PurchaseDenyType.concurrent, isNotNull);
      expect(PurchaseDenyType.authenticationInProgress, isNotNull);
      expect(PurchaseDenyType.backgroundPurchase, isNotNull);
      expect(PurchaseDenyType.cooldown, isNotNull);
      expect(PurchaseDenyType.recentPurchase, isNotNull);
      expect(PurchaseDenyType.systemError, isNotNull);
      expect(PurchaseDenyType.rapidInteraction, isNotNull);
    });
  });
}
