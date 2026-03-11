import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

void main() {
  group('PurchaseValidationResult', () {
    test('allowed result', () {
      final result = PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );
      expect(result.allowed, isTrue);
      expect(result.reason, isNull);
      expect(result.type, isNull);
    });

    test('denied with cooldown', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '너무 빠른 연속 클릭입니다.',
        type: PurchaseDenyType.cooldown,
      );
      expect(result.allowed, isFalse);
      expect(result.reason, contains('클릭'));
      expect(result.type, PurchaseDenyType.cooldown);
    });

    test('denied with concurrent', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '동시 구매',
        type: PurchaseDenyType.concurrent,
      );
      expect(result.allowed, isFalse);
      expect(result.type, PurchaseDenyType.concurrent);
    });

    test('denied with authentication in progress', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '인증 진행 중',
        type: PurchaseDenyType.authenticationInProgress,
      );
      expect(result.type, PurchaseDenyType.authenticationInProgress);
    });

    test('denied with background purchase', () {
      final result = PurchaseValidationResult(
        allowed: false,
        type: PurchaseDenyType.backgroundPurchase,
      );
      expect(result.type, PurchaseDenyType.backgroundPurchase);
    });
  });

  group('PurchaseDenyType', () {
    test('all values exist', () {
      expect(PurchaseDenyType.values.length, 7);
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.concurrent));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.authenticationInProgress));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.backgroundPurchase));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.cooldown));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.recentPurchase));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.systemError));
      expect(PurchaseDenyType.values, contains(PurchaseDenyType.rapidInteraction));
    });
  });
}
