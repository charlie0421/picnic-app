import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

void main() {
  group('ImageComplexity', () {
    test('all values exist', () {
      expect(ImageComplexity.values.length, 3);
      expect(ImageComplexity.values, contains(ImageComplexity.low));
      expect(ImageComplexity.values, contains(ImageComplexity.medium));
      expect(ImageComplexity.values, contains(ImageComplexity.high));
    });
  });

  group('LazyLoadingStrategy', () {
    test('all values exist', () {
      expect(LazyLoadingStrategy.values.length, 4);
      expect(LazyLoadingStrategy.values, contains(LazyLoadingStrategy.none));
      expect(LazyLoadingStrategy.values, contains(LazyLoadingStrategy.viewport));
      expect(LazyLoadingStrategy.values, contains(LazyLoadingStrategy.preload));
      expect(LazyLoadingStrategy.values, contains(LazyLoadingStrategy.progressive));
    });
  });

  group('ImagePriority', () {
    test('all values exist', () {
      expect(ImagePriority.values.length, 3);
      expect(ImagePriority.values, contains(ImagePriority.low));
      expect(ImagePriority.values, contains(ImagePriority.normal));
      expect(ImagePriority.values, contains(ImagePriority.high));
    });
  });

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

    test('denied result with cooldown', () {
      final result = PurchaseValidationResult(
        allowed: false,
        reason: 'Too fast',
        type: PurchaseDenyType.cooldown,
      );
      expect(result.allowed, isFalse);
      expect(result.reason, 'Too fast');
      expect(result.type, PurchaseDenyType.cooldown);
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
