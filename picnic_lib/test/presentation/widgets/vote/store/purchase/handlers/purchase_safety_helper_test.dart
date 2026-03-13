import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_helper.dart';

void main() {
  // ================================================================
  // isSessionExpired
  // ================================================================
  group('isSessionExpired', () {
    test('returns false when firstPurchaseInSession is null', () {
      expect(
        PurchaseSafetyHelper.isSessionExpired(
          firstPurchaseInSession: null,
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isFalse,
      );
    });

    test('returns false when within session window', () {
      final start = DateTime(2025, 1, 1, 12, 0);
      final now = start.add(const Duration(minutes: 5));
      expect(
        PurchaseSafetyHelper.isSessionExpired(
          firstPurchaseInSession: start,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false at exactly 10 minutes (boundary)', () {
      final start = DateTime(2025, 1, 1, 12, 0);
      final now = start.add(const Duration(minutes: 10));
      expect(
        PurchaseSafetyHelper.isSessionExpired(
          firstPurchaseInSession: start,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns true when past session window', () {
      final start = DateTime(2025, 1, 1, 12, 0);
      final now = start.add(const Duration(minutes: 11));
      expect(
        PurchaseSafetyHelper.isSessionExpired(
          firstPurchaseInSession: start,
          now: now,
        ),
        isTrue,
      );
    });

    test('respects custom session window', () {
      final start = DateTime(2025, 1, 1, 12, 0);
      final now = start.add(const Duration(minutes: 6));
      expect(
        PurchaseSafetyHelper.isSessionExpired(
          firstPurchaseInSession: start,
          now: now,
          sessionWindow: const Duration(minutes: 5),
        ),
        isTrue,
      );
    });
  });

  // ================================================================
  // getAdaptiveCooldown
  // ================================================================
  group('getAdaptiveCooldown', () {
    test('returns base cooldown for count 0', () {
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(consecutiveCount: 0),
        const Duration(minutes: 1),
      );
    });

    test('returns base cooldown for count 1', () {
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(consecutiveCount: 1),
        const Duration(minutes: 1),
      );
    });

    test('returns consecutive cooldown for count 2', () {
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(consecutiveCount: 2),
        const Duration(minutes: 1),
      );
    });

    test('returns consecutive cooldown for count > 2', () {
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(consecutiveCount: 5),
        const Duration(minutes: 1),
      );
    });

    test('uses custom base and consecutive durations', () {
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(
          consecutiveCount: 0,
          base: const Duration(seconds: 8),
          consecutive: const Duration(seconds: 15),
        ),
        const Duration(seconds: 8),
      );
      expect(
        PurchaseSafetyHelper.getAdaptiveCooldown(
          consecutiveCount: 3,
          base: const Duration(seconds: 8),
          consecutive: const Duration(seconds: 15),
        ),
        const Duration(seconds: 15),
      );
    });
  });

  // ================================================================
  // isProductForceCooldownActive
  // ================================================================
  group('isProductForceCooldownActive', () {
    test('returns false when cooldownUntil is null', () {
      expect(
        PurchaseSafetyHelper.isProductForceCooldownActive(
          cooldownUntil: null,
          now: DateTime(2025, 1, 1),
        ),
        isFalse,
      );
    });

    test('returns true when now is before cooldownUntil', () {
      final until = DateTime(2025, 1, 1, 12, 5);
      final now = DateTime(2025, 1, 1, 12, 3);
      expect(
        PurchaseSafetyHelper.isProductForceCooldownActive(
          cooldownUntil: until,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false when now equals cooldownUntil', () {
      final time = DateTime(2025, 1, 1, 12, 5);
      expect(
        PurchaseSafetyHelper.isProductForceCooldownActive(
          cooldownUntil: time,
          now: time,
        ),
        isFalse,
      );
    });

    test('returns false when now is after cooldownUntil', () {
      final until = DateTime(2025, 1, 1, 12, 5);
      final now = DateTime(2025, 1, 1, 12, 6);
      expect(
        PurchaseSafetyHelper.isProductForceCooldownActive(
          cooldownUntil: until,
          now: now,
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // computeRemainingCooldown
  // ================================================================
  group('computeRemainingCooldown', () {
    test('returns null when lastPurchaseTime is null', () {
      expect(
        PurchaseSafetyHelper.computeRemainingCooldown(
          lastPurchaseTime: null,
          requiredCooldown: const Duration(minutes: 1),
          now: DateTime(2025, 1, 1),
        ),
        isNull,
      );
    });

    test('returns remaining duration when within cooldown', () {
      final last = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 30); // 30s elapsed
      final result = PurchaseSafetyHelper.computeRemainingCooldown(
        lastPurchaseTime: last,
        requiredCooldown: const Duration(minutes: 1),
        now: now,
      );
      expect(result, const Duration(seconds: 30));
    });

    test('returns null when cooldown has elapsed', () {
      final last = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 2);
      expect(
        PurchaseSafetyHelper.computeRemainingCooldown(
          lastPurchaseTime: last,
          requiredCooldown: const Duration(minutes: 1),
          now: now,
        ),
        isNull,
      );
    });

    test('returns null when exactly at cooldown boundary', () {
      final last = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 1);
      expect(
        PurchaseSafetyHelper.computeRemainingCooldown(
          lastPurchaseTime: last,
          requiredCooldown: const Duration(minutes: 1),
          now: now,
        ),
        isNull,
      );
    });
  });

  // ================================================================
  // productCooldownRemaining
  // ================================================================
  group('productCooldownRemaining', () {
    test('returns null when no previous purchase for product', () {
      expect(
        PurchaseSafetyHelper.productCooldownRemaining(
          lastPurchaseTimeForProduct: null,
          consecutiveCountForProduct: 0,
          now: DateTime(2025, 1, 1),
        ),
        isNull,
      );
    });

    test('returns remaining time with base cooldown', () {
      final last = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 20);
      final result = PurchaseSafetyHelper.productCooldownRemaining(
        lastPurchaseTimeForProduct: last,
        consecutiveCountForProduct: 0,
        now: now,
      );
      expect(result, const Duration(seconds: 40));
    });

    test('returns null when cooldown expired', () {
      final last = DateTime(2025, 1, 1, 12, 0);
      final now = DateTime(2025, 1, 1, 12, 5);
      expect(
        PurchaseSafetyHelper.productCooldownRemaining(
          lastPurchaseTimeForProduct: last,
          consecutiveCountForProduct: 3,
          now: now,
        ),
        isNull,
      );
    });
  });

  // ================================================================
  // containsCancelKeyword
  // ================================================================
  group('containsCancelKeyword', () {
    test('detects "cancel"', () {
      expect(PurchaseSafetyHelper.containsCancelKeyword('User cancel'), isTrue);
    });

    test('detects "cancelled" case-insensitively', () {
      expect(
          PurchaseSafetyHelper.containsCancelKeyword('CANCELLED by user'),
          isTrue);
    });

    test('detects "authentication"', () {
      expect(
          PurchaseSafetyHelper.containsCancelKeyword('authentication required'),
          isTrue);
    });

    test('detects "face id"', () {
      expect(
          PurchaseSafetyHelper.containsCancelKeyword('Face ID failed'), isTrue);
    });

    test('detects "aborted"', () {
      expect(
          PurchaseSafetyHelper.containsCancelKeyword('Transaction aborted'),
          isTrue);
    });

    test('returns false for unrelated message', () {
      expect(
          PurchaseSafetyHelper.containsCancelKeyword('network timeout'),
          isFalse);
    });

    test('returns false for empty string', () {
      expect(PurchaseSafetyHelper.containsCancelKeyword(''), isFalse);
    });
  });

  // ================================================================
  // matchesCancelErrorCode
  // ================================================================
  group('matchesCancelErrorCode', () {
    test('matches PAYMENT_CANCELED in code', () {
      expect(
        PurchaseSafetyHelper.matchesCancelErrorCode('PAYMENT_CANCELED', ''),
        isTrue,
      );
    });

    test('matches SKErrorPaymentCancelled in message', () {
      expect(
        PurchaseSafetyHelper.matchesCancelErrorCode(
            '', 'SKErrorPaymentCancelled occurred'),
        isTrue,
      );
    });

    test('matches code "2"', () {
      expect(
        PurchaseSafetyHelper.matchesCancelErrorCode('2', ''),
        isTrue,
      );
    });

    test('does not match unrelated code', () {
      expect(
        PurchaseSafetyHelper.matchesCancelErrorCode('500', 'server error'),
        isFalse,
      );
    });
  });

  // ================================================================
  // isPurchaseCanceled (combined)
  // ================================================================
  group('isPurchaseCanceled', () {
    test('returns true when status is canceled', () {
      expect(
        PurchaseSafetyHelper.isPurchaseCanceled(
          statusIsCanceled: true,
          statusIsError: false,
          errorMessage: '',
          errorCode: '',
        ),
        isTrue,
      );
    });

    test('returns true when error with cancel keyword', () {
      expect(
        PurchaseSafetyHelper.isPurchaseCanceled(
          statusIsCanceled: false,
          statusIsError: true,
          errorMessage: 'user cancelled the payment',
          errorCode: '',
        ),
        isTrue,
      );
    });

    test('returns true when error with cancel code', () {
      expect(
        PurchaseSafetyHelper.isPurchaseCanceled(
          statusIsCanceled: false,
          statusIsError: true,
          errorMessage: '',
          errorCode: 'USER_CANCELED',
        ),
        isTrue,
      );
    });

    test('returns false when error with non-cancel message', () {
      expect(
        PurchaseSafetyHelper.isPurchaseCanceled(
          statusIsCanceled: false,
          statusIsError: true,
          errorMessage: 'network error',
          errorCode: '500',
        ),
        isFalse,
      );
    });

    test('returns false when status is neither canceled nor error', () {
      expect(
        PurchaseSafetyHelper.isPurchaseCanceled(
          statusIsCanceled: false,
          statusIsError: false,
          errorMessage: 'cancelled',
          errorCode: 'USER_CANCELED',
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // isDuplicateTransaction
  // ================================================================
  group('isDuplicateTransaction', () {
    test('returns false when lastProcessedTransactionId is null', () {
      expect(
        PurchaseSafetyHelper.isDuplicateTransaction(
          transactionId: 'txn_123',
          lastProcessedTransactionId: null,
        ),
        isFalse,
      );
    });

    test('returns true when IDs match', () {
      expect(
        PurchaseSafetyHelper.isDuplicateTransaction(
          transactionId: 'txn_123',
          lastProcessedTransactionId: 'txn_123',
        ),
        isTrue,
      );
    });

    test('returns false when IDs differ', () {
      expect(
        PurchaseSafetyHelper.isDuplicateTransaction(
          transactionId: 'txn_123',
          lastProcessedTransactionId: 'txn_456',
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // isActualPurchaseIOS
  // ================================================================
  group('isActualPurchaseIOS', () {
    test('returns false when status is not purchased/restored', () {
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: false,
          isPurchaseInProgress: true,
          lastPurchaseTime: DateTime(2025, 1, 1, 12, 0),
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isFalse,
      );
    });

    test('returns true when purchase in progress and status valid', () {
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: true,
          lastPurchaseTime: null,
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isTrue,
      );
    });

    test('returns true within 30-second flexible window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 25);
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns true at exactly 30 seconds', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 30);
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns true within 3-minute fallback window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 2, 0);
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns true at exactly 3 minutes', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 3, 0);
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false after 3-minute fallback window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 4, 0);
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when no lastPurchaseTime and not in progress', () {
      expect(
        PurchaseSafetyHelper.isActualPurchaseIOS(
          statusIsPurchasedOrRestored: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: null,
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // isActualPurchaseAndroid
  // ================================================================
  group('isActualPurchaseAndroid', () {
    test('returns true when in progress and purchased', () {
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: true,
          isPurchaseInProgress: true,
          lastPurchaseTime: null,
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isTrue,
      );
    });

    test('returns false when in progress but not purchased', () {
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: false,
          isPurchaseInProgress: true,
          lastPurchaseTime: null,
          now: DateTime(2025, 1, 1, 12, 0),
        ),
        isFalse,
      );
    });

    test('returns true within 10-second strict window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 8);
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns true at exactly 10 seconds', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 10);
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isTrue,
      );
    });

    test('returns false after 10-second window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 15);
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: true,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isFalse,
      );
    });

    test('returns false when not purchased even within window', () {
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 5);
      expect(
        PurchaseSafetyHelper.isActualPurchaseAndroid(
          statusIsPurchased: false,
          isPurchaseInProgress: false,
          lastPurchaseTime: last,
          now: now,
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // isLatePurchase
  // ================================================================
  group('isLatePurchase', () {
    test('returns true when all conditions met', () {
      expect(
        PurchaseSafetyHelper.isLatePurchase(
          isActivePurchasing: false,
          safetyTimeoutTriggered: true,
          safetyTimeoutTime: DateTime(2025, 1, 1),
        ),
        isTrue,
      );
    });

    test('returns false when actively purchasing', () {
      expect(
        PurchaseSafetyHelper.isLatePurchase(
          isActivePurchasing: true,
          safetyTimeoutTriggered: true,
          safetyTimeoutTime: DateTime(2025, 1, 1),
        ),
        isFalse,
      );
    });

    test('returns false when timeout not triggered', () {
      expect(
        PurchaseSafetyHelper.isLatePurchase(
          isActivePurchasing: false,
          safetyTimeoutTriggered: false,
          safetyTimeoutTime: DateTime(2025, 1, 1),
        ),
        isFalse,
      );
    });

    test('returns false when safetyTimeoutTime is null', () {
      expect(
        PurchaseSafetyHelper.isLatePurchase(
          isActivePurchasing: false,
          safetyTimeoutTriggered: true,
          safetyTimeoutTime: null,
        ),
        isFalse,
      );
    });
  });

  // ================================================================
  // shouldResetConsecutiveSession
  // ================================================================
  group('shouldResetConsecutiveSession', () {
    test('returns true for reason containing "취소"', () {
      expect(
        PurchaseSafetyHelper.shouldResetConsecutiveSession('구매 취소'),
        isTrue,
      );
    });

    test('returns true for reason containing "실패"', () {
      expect(
        PurchaseSafetyHelper.shouldResetConsecutiveSession('구매 실패'),
        isTrue,
      );
    });

    test('returns false for unrelated reason', () {
      expect(
        PurchaseSafetyHelper.shouldResetConsecutiveSession('상태 리셋'),
        isFalse,
      );
    });

    test('returns false for empty reason', () {
      expect(
        PurchaseSafetyHelper.shouldResetConsecutiveSession(''),
        isFalse,
      );
    });
  });

  // ================================================================
  // shouldUseLightweightCleanup
  // ================================================================
  group('shouldUseLightweightCleanup', () {
    test('returns false for count 0', () {
      expect(
        PurchaseSafetyHelper.shouldUseLightweightCleanup(
            consecutivePurchaseCount: 0),
        isFalse,
      );
    });

    test('returns false for count 1', () {
      expect(
        PurchaseSafetyHelper.shouldUseLightweightCleanup(
            consecutivePurchaseCount: 1),
        isFalse,
      );
    });

    test('returns true for count 2', () {
      expect(
        PurchaseSafetyHelper.shouldUseLightweightCleanup(
            consecutivePurchaseCount: 2),
        isTrue,
      );
    });

    test('returns true for count > 2', () {
      expect(
        PurchaseSafetyHelper.shouldUseLightweightCleanup(
            consecutivePurchaseCount: 5),
        isTrue,
      );
    });
  });

  // ================================================================
  // getPostPurchaseWaitMs
  // ================================================================
  group('getPostPurchaseWaitMs', () {
    test('returns 100 for consecutive purchase', () {
      expect(
        PurchaseSafetyHelper.getPostPurchaseWaitMs(
            isConsecutivePurchase: true),
        100,
      );
    });

    test('returns 200 for non-consecutive purchase', () {
      expect(
        PurchaseSafetyHelper.getPostPurchaseWaitMs(
            isConsecutivePurchase: false),
        200,
      );
    });
  });
}
