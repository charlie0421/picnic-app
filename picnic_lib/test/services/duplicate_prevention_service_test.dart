import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PurchaseValidationResult', () {
    test('creates allowed result', () {
      final result = PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );

      expect(result.allowed, isTrue);
      expect(result.reason, isNull);
      expect(result.type, isNull);
    });

    test('creates denied result with reason', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: '너무 빠른 연속 클릭입니다.',
        type: PurchaseDenyType.cooldown,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, '너무 빠른 연속 클릭입니다.');
      expect(result.type, PurchaseDenyType.cooldown);
    });
  });

  group('PurchaseDenyType', () {
    test('contains all expected enum values', () {
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

  // Note: DuplicatePreventionService requires a WidgetRef which is difficult to
  // mock without a full Riverpod test environment. We test the data classes and
  // exercise what we can without a WidgetRef.
  //
  // The DuplicatePreventionService constructor takes a WidgetRef, and its methods
  // access _ref.read(voteItemRequestRepositoryProvider). Testing the full service
  // would require a ProviderContainer with overrides. Instead, we test the
  // publicly accessible classes and logic from this file.

  group('PurchaseValidationResult edge cases', () {
    test('all deny types can be used in result', () {
      for (final denyType in PurchaseDenyType.values) {
        final result = PurchaseValidationResult(
          allowed: false,
          reason: 'Test reason for $denyType',
          type: denyType,
        );

        expect(result.allowed, isFalse);
        expect(result.type, denyType);
        expect(result.reason, contains(denyType.toString()));
      }
    });

    test('allowed result with type and reason is valid', () {
      // Edge case: allowed=true but with type/reason set
      final result = PurchaseValidationResult(
        allowed: true,
        reason: 'Warning but allowed',
        type: PurchaseDenyType.cooldown,
      );

      expect(result.allowed, isTrue);
      expect(result.reason, isNotNull);
      expect(result.type, isNotNull);
    });
  });
}
