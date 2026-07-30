import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

void main() {
  late PurchaseSafetyManager manager;

  setUp(() {
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
    );
  });

  group('canAttemptPurchase', () {
    test('returns true when no purchase in progress', () {
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('returns false after recordPurchaseAttempt', () {
      manager.recordPurchaseAttempt(productId: 'test_product');
      expect(manager.canAttemptPurchase(), isFalse);
    });

    test('returns true after completePurchaseSession', () {
      manager.recordPurchaseAttempt(productId: 'test_product');
      manager.completePurchaseSession('test_product');
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('returns true after resetInternalState', () {
      manager.recordPurchaseAttempt(productId: 'test_product');
      manager.resetInternalState(reason: '테스트');
      expect(manager.canAttemptPurchase(), isTrue);
    });
  });

  group('canAttemptPurchaseForProduct', () {
    test('returns true for new product', () {
      expect(manager.canAttemptPurchaseForProduct('product_a'), isTrue);
    });

    test('returns false when purchase in progress', () {
      manager.recordPurchaseAttempt(productId: 'product_a');
      expect(manager.canAttemptPurchaseForProduct('product_a'), isFalse);
    });

    test('an unresolved product does not block a different product', () {
      manager.recordPurchaseAttempt(productId: 'STAR100');
      expect(manager.canAttemptPurchaseForProduct('STAR100'), isFalse);
      expect(manager.canAttemptPurchaseForProduct('STAR500'), isTrue);
    });

    test('a settled purchase does not refuse the next one', () {
      // 정산이 끝난 구매는 재구매를 막는 근거가 아니다: 그 차단이 "이전 결제가
      // 스토어에서 처리 중입니다. 잠시 후 다시 시도해 주세요." 로 안내되어
      // 소비형 상품의 정상적인 연속 구매를 막았다 (1.3.0 TestFlight patch 8).
      manager.recordPurchaseAttempt(productId: 'product_a');
      manager.completePurchaseSession('product_a');
      expect(manager.canAttemptPurchaseForProduct('product_a'), isTrue);
    });

    test('different products have independent cooldowns', () {
      manager.activateDuplicateCooldown(
        productId: 'product_a',
        cooldown: const Duration(minutes: 1),
      );
      // product_b should not be affected by product_a cooldown
      expect(manager.canAttemptPurchaseForProduct('product_a'), isFalse);
      expect(manager.canAttemptPurchaseForProduct('product_b'), isTrue);
    });

    test('returns false during forced cooldown', () {
      manager.activateDuplicateCooldown(
        productId: 'dup_product',
        cooldown: const Duration(minutes: 5),
      );
      expect(manager.canAttemptPurchaseForProduct('dup_product'), isFalse);
    });
  });

  group('recordPurchaseAttempt', () {
    test('sets purchase in progress', () {
      manager.recordPurchaseAttempt(productId: 'test');
      expect(manager.canAttemptPurchase(), isFalse);
    });

    test('tracks lastPurchaseAttempt time', () {
      expect(manager.lastPurchaseAttempt, isNull);
      manager.recordPurchaseAttempt(productId: 'test');
      expect(manager.lastPurchaseAttempt, isNotNull);
    });
  });

  group('completePurchaseSession', () {
    test('clears purchase in progress', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.completePurchaseSession('test');
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('updates lastPurchaseAttempt', () {
      manager.recordPurchaseAttempt(productId: 'test');
      final attemptTime = manager.lastPurchaseAttempt;
      manager.completePurchaseSession('test');
      expect(
        manager.lastPurchaseAttempt!.millisecondsSinceEpoch,
        greaterThanOrEqualTo(attemptTime!.millisecondsSinceEpoch),
      );
    });
  });

  group('resetInternalState', () {
    test('clears purchase progress', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.resetInternalState(reason: 'test reset');
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('resets consecutive count on cancel reason', () {
      manager.recordPurchaseAttempt(productId: 'p1');
      manager.completePurchaseSession('p1');
      manager.recordPurchaseAttempt(productId: 'p2');
      manager.resetInternalState(reason: '구매 취소');
      // After cancel reset, should be clean
      expect(manager.canAttemptPurchase(), isTrue);
    });

    test('resets consecutive count on failure reason', () {
      manager.recordPurchaseAttempt(productId: 'p1');
      manager.resetInternalState(reason: '구매 실패');
      expect(manager.canAttemptPurchase(), isTrue);
    });
  });

  group('resetUIOnly', () {
    test('clears purchase in progress but keeps cooldown', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.resetUIOnly(reason: 'UI reset');
      expect(manager.canAttemptPurchase(), isTrue);
      // lastPurchaseAttempt should still be set
      expect(manager.lastPurchaseAttempt, isNotNull);
    });
  });

  group('clearProductCooldown', () {
    test('clears cooldown for specific product', () {
      manager.activateDuplicateCooldown(
        productId: 'product_a',
        cooldown: const Duration(minutes: 1),
      );
      manager.clearProductCooldown('product_a');
      expect(manager.canAttemptPurchaseForProduct('product_a'), isTrue);
    });

    test('does not affect other products', () {
      manager.activateDuplicateCooldown(
        productId: 'product_a',
        cooldown: const Duration(minutes: 1),
      );
      manager.activateDuplicateCooldown(
        productId: 'product_b',
        cooldown: const Duration(minutes: 1),
      );
      manager.clearProductCooldown('product_a');
      // product_b cooldown should still be active
      expect(manager.canAttemptPurchaseForProduct('product_b'), isFalse);
    });
  });

  group('activateDuplicateCooldown', () {
    test('blocks purchase for specified duration', () {
      manager.activateDuplicateCooldown(
        productId: 'dup_test',
        cooldown: const Duration(minutes: 10),
      );
      expect(manager.canAttemptPurchaseForProduct('dup_test'), isFalse);
    });

    test('does not block other products', () {
      manager.activateDuplicateCooldown(
        productId: 'dup_test',
        cooldown: const Duration(minutes: 10),
      );
      expect(manager.canAttemptPurchaseForProduct('other'), isTrue);
    });
  });

  group('remainingCooldown', () {
    test('returns null when no purchase attempted', () {
      expect(manager.remainingCooldown(), isNull);
    });

    test('returns duration after purchase attempt', () {
      manager.recordPurchaseAttempt(productId: 'test');
      final remaining = manager.remainingCooldown();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });

  group('remainingCooldownForProduct', () {
    test('returns null for unknown product', () {
      expect(manager.remainingCooldownForProduct('unknown'), isNull);
    });

    test('returns null once a purchase has settled', () {
      manager.recordPurchaseAttempt(productId: 'test');
      manager.completePurchaseSession('test');
      expect(manager.remainingCooldownForProduct('test'), isNull,
          reason: '실제로 막는 시간만 보고한다 - 정산이 끝난 구매는 막지 않는다');
    });

    test('returns the enforced duration while a cooldown is armed', () {
      manager.activateDuplicateCooldown(
        productId: 'test',
        cooldown: const Duration(minutes: 1),
      );
      final remaining = manager.remainingCooldownForProduct('test');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });
  });

  group('isLatePurchase', () {
    test('returns false when not timed out', () {
      expect(manager.isLatePurchase(true), isFalse);
      expect(manager.isLatePurchase(false), isFalse);
    });

    test('returns false when actively purchasing', () {
      expect(manager.isLatePurchase(true), isFalse);
    });
  });

  group('resetLatePurchaseSuccess', () {
    test('completes without error', () {
      manager.resetLatePurchaseSuccess();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
    });
  });

  group('safetyTimer', () {
    test('startSafetyTimer does not throw', () {
      expect(() => manager.startSafetyTimer(), returnsNormally);
      manager.disposeSafetyTimer();
    });

    test('stopSafetyTimer does not throw when no timer', () {
      expect(() => manager.stopSafetyTimer(), returnsNormally);
    });

    test('disposeSafetyTimer cleans up', () {
      manager.startSafetyTimer();
      expect(() => manager.disposeSafetyTimer(), returnsNormally);
    });
  });

  group('cleanupAllTimersOnSuccess', () {
    test('resets timeout state', () {
      manager.startSafetyTimer();
      manager.cleanupAllTimersOnSuccess();
      expect(manager.isSafetyTimeoutTriggered, isFalse);
      expect(manager.safetyTimeoutTime, isNull);
      manager.disposeSafetyTimer();
    });
  });

  group('isPurchaseCanceled', () {
    PurchaseDetails makePurchase({
      required PurchaseStatus status,
      String? errorMessage,
      String? errorCode,
    }) {
      // PurchaseDetails is from in_app_purchase package
      // We create a GooglePlayPurchaseDetails or use the base
      final details = PurchaseDetails(
        productID: 'test_product',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: '',
        ),
        transactionDate: null,
        status: status,
        purchaseID: 'test_id',
      );
      if (errorMessage != null || errorCode != null) {
        details.error = IAPError(
          source: 'test',
          code: errorCode ?? '',
          message: errorMessage ?? '',
        );
      }
      return details;
    }

    test('returns true for canceled status', () {
      final purchase = makePurchase(status: PurchaseStatus.canceled);
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('returns false for purchased status', () {
      final purchase = makePurchase(status: PurchaseStatus.purchased);
      expect(manager.isPurchaseCanceled(purchase), isFalse);
    });

    test('returns false for pending status', () {
      final purchase = makePurchase(status: PurchaseStatus.pending);
      expect(manager.isPurchaseCanceled(purchase), isFalse);
    });

    test('detects cancel keyword in error message', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'user cancelled the purchase',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects cancel error code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: 'USER_CANCELED',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects biometric cancel keywords', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'face id authentication failed',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects touch id cancel', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'touch id was not recognized',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects SKError cancel code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: 'SKErrorPaymentCancelled',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('detects billing response cancel code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: 'BILLING_RESPONSE_USER_CANCELED',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('returns false for non-cancel error', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: 'network timeout occurred',
        errorCode: 'NETWORK_ERROR',
      );
      expect(manager.isPurchaseCanceled(purchase), isFalse);
    });

    test('detects PAYMENT_CANCELED code', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorCode: 'PAYMENT_CANCELED',
      );
      expect(manager.isPurchaseCanceled(purchase), isTrue);
    });

    test('error with no message or code returns false', () {
      final purchase = makePurchase(
        status: PurchaseStatus.error,
        errorMessage: '',
        errorCode: '',
      );
      expect(manager.isPurchaseCanceled(purchase), isFalse);
    });
  });

  group('getters', () {
    test('isSafetyTimeoutTriggered defaults to false', () {
      expect(manager.isSafetyTimeoutTriggered, isFalse);
    });

    test('safetyTimeoutTime defaults to null', () {
      expect(manager.safetyTimeoutTime, isNull);
    });

    test('lastPurchaseAttempt defaults to null', () {
      expect(manager.lastPurchaseAttempt, isNull);
    });
  });
}
