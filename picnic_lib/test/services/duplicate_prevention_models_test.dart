import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

void main() {
  group('PurchaseValidationResult', () {
    test('허용 결과 생성', () {
      final result = PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );
      expect(result.allowed, isTrue);
      expect(result.reason, isNull);
      expect(result.type, isNull);
    });

    test('차단 결과 생성 - cooldown', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '너무 빠른 연속 클릭입니다.',
        type: PurchaseDenyType.cooldown,
      );
      expect(result.allowed, isFalse);
      expect(result.reason, equals('너무 빠른 연속 클릭입니다.'));
      expect(result.type, equals(PurchaseDenyType.cooldown));
    });

    test('차단 결과 생성 - concurrent', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '동시 구매 감지',
        type: PurchaseDenyType.concurrent,
      );
      expect(result.type, equals(PurchaseDenyType.concurrent));
    });
  });

  group('PurchaseDenyType enum', () {
    test('7개의 차단 유형이 정의됨', () {
      expect(PurchaseDenyType.values.length, equals(7));
    });

    test('모든 차단 유형 존재', () {
      expect(PurchaseDenyType.concurrent, isNotNull);
      expect(PurchaseDenyType.authenticationInProgress, isNotNull);
      expect(PurchaseDenyType.backgroundPurchase, isNotNull);
      expect(PurchaseDenyType.cooldown, isNotNull);
      expect(PurchaseDenyType.recentPurchase, isNotNull);
      expect(PurchaseDenyType.systemError, isNotNull);
      expect(PurchaseDenyType.rapidInteraction, isNotNull);
    });

    test('index 순서', () {
      expect(PurchaseDenyType.concurrent.index, equals(0));
      expect(PurchaseDenyType.authenticationInProgress.index, equals(1));
      expect(PurchaseDenyType.backgroundPurchase.index, equals(2));
      expect(PurchaseDenyType.cooldown.index, equals(3));
      expect(PurchaseDenyType.recentPurchase.index, equals(4));
      expect(PurchaseDenyType.systemError.index, equals(5));
      expect(PurchaseDenyType.rapidInteraction.index, equals(6));
    });
  });
}
