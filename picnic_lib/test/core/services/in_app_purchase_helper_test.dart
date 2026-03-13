import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_helper.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

PurchaseDetails _makePurchase(
  String productId,
  PurchaseStatus status, {
  String? transactionDate,
  bool pendingComplete = false,
}) {
  // PurchaseDetails fields are final, so we use the Google Play constructor
  // which is the simplest available in the base package.
  final details = PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: transactionDate ?? '2025-01-01',
    status: status,
    purchaseID: 'purchase_$productId',
  );
  // pendingCompletePurchase defaults to false; override if needed via a
  // purchase in the 'purchased' state (the plugin sets it automatically).
  return details;
}

void main() {
  // ====================================================================
  // isPurchaseCancelledException
  // ====================================================================
  group('isPurchaseCancelledException', () {
    test('returns true for StoreKit2 cancel code', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          Exception('storekit2_purchase_cancelled'),
        ),
        isTrue,
      );
    });

    test('returns true for StoreKit1 cancel code', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'SKErrorPaymentCancelled - user changed mind',
        ),
        isTrue,
      );
    });

    test('returns true for Google Play cancel code', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'billing_response_user_canceled',
        ),
        isTrue,
      );
    });

    test('returns true for generic cancel keyword', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException('User cancelled'),
        isTrue,
      );
    });

    test('returns true for Touch ID keyword', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'Touch ID authentication required',
        ),
        isTrue,
      );
    });

    test('returns true for Face ID keyword', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'Face ID verification failed',
        ),
        isTrue,
      );
    });

    test('returns true for abort keyword', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException('abort'),
        isTrue,
      );
    });

    test('returns true for dismiss keyword', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'Payment sheet was dismissed by user',
        ),
        isTrue,
      );
    });

    test('returns true for operation was cancelled', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'The operation was cancelled by the system',
        ),
        isTrue,
      );
    });

    test('returns false for unrelated exception', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          Exception('Network timeout – please retry'),
        ),
        isFalse,
      );
    });

    test('returns false for empty string', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(''),
        isFalse,
      );
    });

    test('returns false for null-like value', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(null),
        isFalse,
      );
    });

    test('is case-insensitive', () {
      expect(
        InAppPurchaseHelper.isPurchaseCancelledException(
          'STOREKIT2_PURCHASE_CANCELLED',
        ),
        isTrue,
      );
    });
  });

  // ====================================================================
  // matchedCancelKeyword
  // ====================================================================
  group('matchedCancelKeyword', () {
    test('returns matching keyword for cancel exception', () {
      expect(
        InAppPurchaseHelper.matchedCancelKeyword('payment_canceled by user'),
        equals('payment_canceled'),
      );
    });

    test('returns null when no keyword matches', () {
      expect(
        InAppPurchaseHelper.matchedCancelKeyword('Unexpected server error 500'),
        isNull,
      );
    });

    test('returns first matching keyword when multiple apply', () {
      // "purchase_cancelled" should match before more generic keywords
      final result = InAppPurchaseHelper.matchedCancelKeyword(
        'purchase_cancelled by user cancel',
      );
      expect(result, isNotNull);
      // The first match in the list order should be returned
      expect(
        InAppPurchaseHelper.cancelKeywords.contains(result),
        isTrue,
      );
    });
  });

  // ====================================================================
  // resolveTimeout
  // ====================================================================
  group('resolveTimeout', () {
    test('forceTimeout always returns debugPurchaseTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: true,
          timeoutMode: 'normal',
        ),
        equals(PurchaseConstants.debugPurchaseTimeout),
      );
    });

    test('forceTimeout overrides any timeoutMode', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: true,
          timeoutMode: 'instant',
        ),
        equals(PurchaseConstants.debugPurchaseTimeout),
      );
    });

    test('instant mode returns instantTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: false,
          timeoutMode: 'instant',
        ),
        equals(PurchaseConstants.instantTimeout),
      );
    });

    test('ultrafast mode returns ultraFastTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: false,
          timeoutMode: 'ultrafast',
        ),
        equals(PurchaseConstants.ultraFastTimeout),
      );
    });

    test('debug mode returns debugPurchaseTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: false,
          timeoutMode: 'debug',
        ),
        equals(PurchaseConstants.debugPurchaseTimeout),
      );
    });

    test('normal mode returns purchaseTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: false,
          timeoutMode: 'normal',
        ),
        equals(PurchaseConstants.purchaseTimeout),
      );
    });

    test('unknown mode falls back to purchaseTimeout', () {
      expect(
        InAppPurchaseHelper.resolveTimeout(
          forceTimeout: false,
          timeoutMode: 'unknown_mode',
        ),
        equals(PurchaseConstants.purchaseTimeout),
      );
    });
  });

  // ====================================================================
  // formatDurationKorean
  // ====================================================================
  group('formatDurationKorean', () {
    test('formats sub-second durations in ms', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(
          const Duration(milliseconds: 500),
        ),
        equals('500ms'),
      );
    });

    test('formats 100ms', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(
          const Duration(milliseconds: 100),
        ),
        equals('100ms'),
      );
    });

    test('formats zero duration as 0ms', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(Duration.zero),
        equals('0ms'),
      );
    });

    test('formats exactly 1 second', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(const Duration(seconds: 1)),
        equals('1초'),
      );
    });

    test('formats 30 seconds', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(const Duration(seconds: 30)),
        equals('30초'),
      );
    });

    test('formats exactly 999ms as sub-second', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(
          const Duration(milliseconds: 999),
        ),
        equals('999ms'),
      );
    });

    test('formats 1000ms as seconds', () {
      expect(
        InAppPurchaseHelper.formatDurationKorean(
          const Duration(milliseconds: 1000),
        ),
        equals('1초'),
      );
    });
  });

  // ====================================================================
  // isTerminalStatus
  // ====================================================================
  group('isTerminalStatus', () {
    test('purchased is terminal', () {
      expect(InAppPurchaseHelper.isTerminalStatus(PurchaseStatus.purchased),
          isTrue);
    });

    test('restored is terminal', () {
      expect(
          InAppPurchaseHelper.isTerminalStatus(PurchaseStatus.restored), isTrue);
    });

    test('error is terminal', () {
      expect(
          InAppPurchaseHelper.isTerminalStatus(PurchaseStatus.error), isTrue);
    });

    test('canceled is terminal', () {
      expect(
          InAppPurchaseHelper.isTerminalStatus(PurchaseStatus.canceled), isTrue);
    });

    test('pending is NOT terminal', () {
      expect(
          InAppPurchaseHelper.isTerminalStatus(PurchaseStatus.pending), isFalse);
    });
  });

  // ====================================================================
  // filterPending
  // ====================================================================
  group('filterPending', () {
    test('returns only pending purchases', () {
      final purchases = [
        _makePurchase('A', PurchaseStatus.pending),
        _makePurchase('B', PurchaseStatus.purchased),
        _makePurchase('C', PurchaseStatus.pending),
        _makePurchase('D', PurchaseStatus.error),
      ];
      final result = InAppPurchaseHelper.filterPending(purchases);
      expect(result.length, 2);
      expect(result.map((p) => p.productID).toList(), ['A', 'C']);
    });

    test('returns empty list when no pending', () {
      final purchases = [
        _makePurchase('A', PurchaseStatus.purchased),
        _makePurchase('B', PurchaseStatus.error),
      ];
      expect(InAppPurchaseHelper.filterPending(purchases), isEmpty);
    });

    test('returns empty list for empty input', () {
      expect(InAppPurchaseHelper.filterPending([]), isEmpty);
    });
  });

  // ====================================================================
  // filterPendingForProduct
  // ====================================================================
  group('filterPendingForProduct', () {
    test('returns pending purchases for a specific product', () {
      final purchases = [
        _makePurchase('STAR10000', PurchaseStatus.pending),
        _makePurchase('STAR7000', PurchaseStatus.pending),
        _makePurchase('STAR10000', PurchaseStatus.purchased),
        _makePurchase('STAR10000', PurchaseStatus.pending),
      ];
      final result = InAppPurchaseHelper.filterPendingForProduct(
        purchases,
        'STAR10000',
      );
      expect(result.length, 2);
      expect(result.every((p) => p.productID == 'STAR10000'), isTrue);
    });

    test('returns empty when product has no pending purchases', () {
      final purchases = [
        _makePurchase('STAR10000', PurchaseStatus.purchased),
        _makePurchase('STAR7000', PurchaseStatus.pending),
      ];
      final result = InAppPurchaseHelper.filterPendingForProduct(
        purchases,
        'STAR10000',
      );
      expect(result, isEmpty);
    });
  });

  // ====================================================================
  // hasTerminalPurchaseForProduct
  // ====================================================================
  group('hasTerminalPurchaseForProduct', () {
    test('returns true when product has a purchased status', () {
      final purchases = [
        _makePurchase('STAR10000', PurchaseStatus.pending),
        _makePurchase('STAR10000', PurchaseStatus.purchased),
      ];
      expect(
        InAppPurchaseHelper.hasTerminalPurchaseForProduct(
            purchases, 'STAR10000'),
        isTrue,
      );
    });

    test('returns true when product has an error status', () {
      final purchases = [
        _makePurchase('STAR10000', PurchaseStatus.error),
      ];
      expect(
        InAppPurchaseHelper.hasTerminalPurchaseForProduct(
            purchases, 'STAR10000'),
        isTrue,
      );
    });

    test('returns false when product only has pending status', () {
      final purchases = [
        _makePurchase('STAR10000', PurchaseStatus.pending),
      ];
      expect(
        InAppPurchaseHelper.hasTerminalPurchaseForProduct(
            purchases, 'STAR10000'),
        isFalse,
      );
    });

    test('returns false for different product', () {
      final purchases = [
        _makePurchase('STAR7000', PurchaseStatus.purchased),
      ];
      expect(
        InAppPurchaseHelper.hasTerminalPurchaseForProduct(
            purchases, 'STAR10000'),
        isFalse,
      );
    });

    test('returns false for empty list', () {
      expect(
        InAppPurchaseHelper.hasTerminalPurchaseForProduct([], 'STAR10000'),
        isFalse,
      );
    });
  });

  // ====================================================================
  // cleanupSuccessRate
  // ====================================================================
  group('cleanupSuccessRate', () {
    test('returns 0 when totalFound is 0', () {
      expect(InAppPurchaseHelper.cleanupSuccessRate(0, 0), '0');
    });

    test('returns 100.0 when all cleared', () {
      expect(InAppPurchaseHelper.cleanupSuccessRate(10, 10), '100.0');
    });

    test('returns correct percentage', () {
      expect(InAppPurchaseHelper.cleanupSuccessRate(10, 8), '80.0');
    });

    test('handles one-third correctly', () {
      expect(InAppPurchaseHelper.cleanupSuccessRate(3, 1), '33.3');
    });

    test('returns 0 for negative totalFound', () {
      expect(InAppPurchaseHelper.cleanupSuccessRate(-1, 5), '0');
    });
  });

  // ====================================================================
  // buildCleanupStatusMap
  // ====================================================================
  group('buildCleanupStatusMap', () {
    test('builds correct map with pending purchases', () {
      final pending = [
        _makePurchase('A', PurchaseStatus.pending, transactionDate: '2025-06-01'),
      ];
      final now = DateTime(2025, 6, 1, 12, 0, 0);
      final result = InAppPurchaseHelper.buildCleanupStatusMap(
        currentPending: pending,
        totalFound: 5,
        totalCleared: 3,
        lastCleanupTime: now,
      );

      expect(result['currentPendingCount'], 1);
      expect(result['totalPendingFound'], 5);
      expect(result['totalPendingCleared'], 3);
      expect(result['lastCleanupTime'], now.toIso8601String());
      expect(result['currentPendingItems'], isList);
      expect((result['currentPendingItems'] as List).length, 1);
      expect(
        (result['currentPendingItems'] as List).first['productID'],
        'A',
      );
    });

    test('builds correct map with no pending purchases', () {
      final result = InAppPurchaseHelper.buildCleanupStatusMap(
        currentPending: [],
        totalFound: 0,
        totalCleared: 0,
      );
      expect(result['currentPendingCount'], 0);
      expect(result['lastCleanupTime'], isNull);
      expect(result['currentPendingItems'], isEmpty);
    });
  });

  // ====================================================================
  // buildCleanupErrorMap
  // ====================================================================
  group('buildCleanupErrorMap', () {
    test('builds error map with correct fields', () {
      final result = InAppPurchaseHelper.buildCleanupErrorMap(
        error: 'timeout',
        totalFound: 10,
        totalCleared: 7,
      );
      expect(result['error'], 'timeout');
      expect(result['currentPendingCount'], -1);
      expect(result['totalPendingFound'], 10);
      expect(result['totalPendingCleared'], 7);
    });
  });

  // ====================================================================
  // buildAuthDiagnosisSolutions
  // ====================================================================
  group('buildAuthDiagnosisSolutions', () {
    test('includes pending warning when pending count > 0', () {
      final solutions = InAppPurchaseHelper.buildAuthDiagnosisSolutions(
        currentPendingCount: 3,
        productQuerySuccess: true,
      );
      expect(
        solutions.first,
        contains('3개'),
      );
    });

    test('includes product query warning when query failed', () {
      final solutions = InAppPurchaseHelper.buildAuthDiagnosisSolutions(
        currentPendingCount: 0,
        productQuerySuccess: false,
      );
      expect(
        solutions.first,
        contains('제품 쿼리가 실패'),
      );
    });

    test('includes both warnings when both problems exist', () {
      final solutions = InAppPurchaseHelper.buildAuthDiagnosisSolutions(
        currentPendingCount: 2,
        productQuerySuccess: false,
      );
      // First two are dynamic warnings, rest are static
      expect(solutions.length, 7);
      expect(solutions[0], contains('2개'));
      expect(solutions[1], contains('제품 쿼리가 실패'));
    });

    test('only static solutions when no specific problems', () {
      final solutions = InAppPurchaseHelper.buildAuthDiagnosisSolutions(
        currentPendingCount: 0,
        productQuerySuccess: true,
      );
      expect(solutions.length, 5);
      expect(solutions.first, startsWith('1.'));
    });

    test('handles null values gracefully', () {
      final solutions = InAppPurchaseHelper.buildAuthDiagnosisSolutions();
      // null pending count -> no warning; null productQuerySuccess -> warning
      expect(solutions.any((s) => s.contains('제품 쿼리가 실패')), isTrue);
      expect(solutions.length, 6); // 1 dynamic + 5 static
    });
  });

  // ====================================================================
  // isDebugModeFromTimeoutMode
  // ====================================================================
  group('isDebugModeFromTimeoutMode', () {
    test('normal is NOT debug', () {
      expect(InAppPurchaseHelper.isDebugModeFromTimeoutMode('normal'), isFalse);
    });

    test('debug IS debug', () {
      expect(InAppPurchaseHelper.isDebugModeFromTimeoutMode('debug'), isTrue);
    });

    test('instant IS debug', () {
      expect(InAppPurchaseHelper.isDebugModeFromTimeoutMode('instant'), isTrue);
    });

    test('ultrafast IS debug', () {
      expect(
          InAppPurchaseHelper.isDebugModeFromTimeoutMode('ultrafast'), isTrue);
    });

    test('arbitrary string IS debug', () {
      expect(InAppPurchaseHelper.isDebugModeFromTimeoutMode('custom'), isTrue);
    });
  });

  // ====================================================================
  // timeoutModeForDebugToggle
  // ====================================================================
  group('timeoutModeForDebugToggle', () {
    test('enabled -> debug', () {
      expect(InAppPurchaseHelper.timeoutModeForDebugToggle(true), 'debug');
    });

    test('disabled -> normal', () {
      expect(InAppPurchaseHelper.timeoutModeForDebugToggle(false), 'normal');
    });
  });
}
