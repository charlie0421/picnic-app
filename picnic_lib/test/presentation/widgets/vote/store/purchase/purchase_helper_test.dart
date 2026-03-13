import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_helper.dart';

/// Helper to create PurchaseDetails for testing
PurchaseDetails _makePurchase({
  PurchaseStatus status = PurchaseStatus.purchased,
  String productID = 'STAR100',
  String? purchaseID,
  IAPError? error,
}) {
  final pd = PurchaseDetails(
    purchaseID: purchaseID,
    productID: productID,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: '',
    ),
    transactionDate: null,
    status: status,
  );
  if (error != null) {
    pd.error = error;
  }
  return pd;
}

IAPError _makeError({String code = '', String message = ''}) {
  return IAPError(source: 'test', code: code, message: message);
}

void main() {
  group('PurchaseHelper.isPurchaseCanceled', () {
    test('returns true for PurchaseStatus.canceled', () {
      final pd = _makePurchase(status: PurchaseStatus.canceled);
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('returns false for PurchaseStatus.purchased', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(PurchaseHelper.isPurchaseCanceled(pd), isFalse);
    });

    test('returns false for PurchaseStatus.pending', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(PurchaseHelper.isPurchaseCanceled(pd), isFalse);
    });

    test('returns false for PurchaseStatus.restored', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(PurchaseHelper.isPurchaseCanceled(pd), isFalse);
    });

    test('detects cancel keyword in error message', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'User cancelled the purchase'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "cancel" keyword (lowercase)', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'purchase cancel by system'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "abort" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'transaction abort'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "dismiss" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'dialog dismiss'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "authentication" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'authentication required'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "touch id" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'touch id failed'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "face id" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'face id not available'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "biometric" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'biometric verification failed'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "unauthorized" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'unauthorized access'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "declined" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'payment declined'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "rejected" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'payment rejected by bank'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects PAYMENT_CANCELED error code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'PAYMENT_CANCELED'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects USER_CANCELED error code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'USER_CANCELED'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects SKErrorPaymentCancelled error code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'SKErrorPaymentCancelled'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects storekit2_purchase_cancelled error code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'storekit2_purchase_cancelled'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects cancel code in error message', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(
          code: 'UNKNOWN',
          message: 'Error PAYMENT_CANCELED occurred',
        ),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects LAError codes', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'LAError2'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects negative error codes', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: '-1000'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('returns false for genuine error with unknown code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(
          code: 'NETWORK_TIMEOUT_XYZ',
          message: 'connection timed out with server',
        ),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isFalse);
    });

    test('returns false for error with no error object', () {
      final pd = _makePurchase(status: PurchaseStatus.error);
      // error is null, errorMessage will be '', errorCode will be ''
      // '' does not contain any cancel keywords or codes
      // However, code '2' is in cancelErrorCodes and '' does not contain '2'
      expect(PurchaseHelper.isPurchaseCanceled(pd), isFalse);
    });

    test('detects "operation was cancelled" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'The operation was cancelled by the system'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "user denied" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'user denied the transaction'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects "transaction has been cancelled" keyword', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(message: 'this transaction has been cancelled'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });

    test('detects ios_purchase_cancelled error code', () {
      final pd = _makePurchase(
        status: PurchaseStatus.error,
        error: _makeError(code: 'ios_purchase_cancelled'),
      );
      expect(PurchaseHelper.isPurchaseCanceled(pd), isTrue);
    });
  });

  group('PurchaseHelper.isDuplicateError', () {
    test('detects StoreKit cache issue', () {
      expect(
        PurchaseHelper.isDuplicateError('StoreKit 캐시 문제 발생'),
        isTrue,
      );
    });

    test('detects duplicate receipt', () {
      expect(PurchaseHelper.isDuplicateError('중복 영수증 감지됨'), isTrue);
    });

    test('detects already processed purchase', () {
      expect(PurchaseHelper.isDuplicateError('이미 처리된 구매입니다'), isTrue);
    });

    test('detects Duplicate keyword', () {
      expect(PurchaseHelper.isDuplicateError('Duplicate transaction'), isTrue);
    });

    test('detects reused keyword (case insensitive)', () {
      expect(PurchaseHelper.isDuplicateError('Token REUSED'), isTrue);
    });

    test('detects reused keyword lowercase', () {
      expect(PurchaseHelper.isDuplicateError('receipt reused'), isTrue);
    });

    test('returns false for normal error', () {
      expect(PurchaseHelper.isDuplicateError('Network error'), isFalse);
    });

    test('returns false for empty string', () {
      expect(PurchaseHelper.isDuplicateError(''), isFalse);
    });

    test('returns false for unrelated Korean text', () {
      expect(PurchaseHelper.isDuplicateError('네트워크 오류'), isFalse);
    });
  });

  group('PurchaseHelper.shouldForceCompletePending', () {
    test('returns true when not active, not cleared, and pending', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isTrue,
      );
    });

    test('returns false when active purchasing', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: true,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when transactions cleared', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: true,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when status is purchased', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when status is restored', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when status is error', () {
      final pd = _makePurchase(status: PurchaseStatus.error);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when both active and cleared', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldForceCompletePending(
          isActivePurchasing: true,
          transactionsCleared: true,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.shouldIgnoreDuringInit', () {
    test('returns true for restored when not active and not cleared', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isTrue,
      );
    });

    test('returns true for purchased when not active and not cleared', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isTrue,
      );
    });

    test('returns false when active purchasing', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: true,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false when transactions cleared', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: true,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false for pending status', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false for error status', () {
      final pd = _makePurchase(status: PurchaseStatus.error);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });

    test('returns false for canceled status', () {
      final pd = _makePurchase(status: PurchaseStatus.canceled);
      expect(
        PurchaseHelper.shouldIgnoreDuringInit(
          isActivePurchasing: false,
          transactionsCleared: false,
          purchaseDetails: pd,
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.getStatusCounts', () {
    test('returns all zeros for empty list', () {
      final result = PurchaseHelper.getStatusCounts([]);
      expect(result['pending'], 0);
      expect(result['restored'], 0);
      expect(result['purchased'], 0);
      expect(result['error'], 0);
      expect(result['canceled'], 0);
    });

    test('counts single pending purchase', () {
      final result = PurchaseHelper.getStatusCounts([
        _makePurchase(status: PurchaseStatus.pending),
      ]);
      expect(result['pending'], 1);
      expect(result['restored'], 0);
      expect(result['purchased'], 0);
      expect(result['error'], 0);
      expect(result['canceled'], 0);
    });

    test('counts mixed statuses correctly', () {
      final result = PurchaseHelper.getStatusCounts([
        _makePurchase(status: PurchaseStatus.pending),
        _makePurchase(status: PurchaseStatus.pending),
        _makePurchase(status: PurchaseStatus.purchased),
        _makePurchase(status: PurchaseStatus.restored),
        _makePurchase(status: PurchaseStatus.error),
        _makePurchase(status: PurchaseStatus.canceled),
        _makePurchase(status: PurchaseStatus.canceled),
      ]);
      expect(result['pending'], 2);
      expect(result['purchased'], 1);
      expect(result['restored'], 1);
      expect(result['error'], 1);
      expect(result['canceled'], 2);
    });

    test('counts all purchased', () {
      final result = PurchaseHelper.getStatusCounts([
        _makePurchase(status: PurchaseStatus.purchased),
        _makePurchase(status: PurchaseStatus.purchased),
        _makePurchase(status: PurchaseStatus.purchased),
      ]);
      expect(result['purchased'], 3);
      expect(result['pending'], 0);
    });

    test('has all expected keys', () {
      final result = PurchaseHelper.getStatusCounts([]);
      expect(result.keys, containsAll(['pending', 'restored', 'purchased', 'error', 'canceled']));
    });
  });

  group('PurchaseHelper.shouldProcessActivePurchaseIOS', () {
    test('step 1: returns true when active and purchased', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isTrue,
      );
    });

    test('step 1: returns true when active and restored', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isTrue,
      );
    });

    test('step 1: returns false when active but pending', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isFalse,
      );
    });

    test('step 2: returns true for late purchase within 2 minutes', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 1, 30); // 90 seconds later
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
          now: now,
        ),
        isTrue,
      );
    });

    test('step 2: returns false for late purchase after 2 minutes when not actual', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 3, 0); // 3 minutes later
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => false,
          now: now,
        ),
        isFalse,
      );
    });

    test('step 2: returns false when timeout triggered but not actual purchase', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 1, 0);
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => false,
          now: now,
        ),
        isFalse,
      );
    });

    test('step 3: iOS fallback returns true for actual purchased', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('step 3: iOS fallback returns true for actual restored', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isTrue,
      );
    });

    test('step 3: iOS fallback returns false for non-actual purchase', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isFalse,
      );
    });

    test('returns false for error status even when active', () {
      final pd = _makePurchase(status: PurchaseStatus.error);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('step 2: handles restored status in late purchase', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 1, 0);
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
          now: now,
        ),
        isTrue,
      );
    });

    test('step 2: returns false when safetyTimeoutTime is null', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseIOS(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isFalse,
      );
    });
  });

  group('PurchaseHelper.shouldProcessActivePurchaseAndroid', () {
    test('step 1: returns true when active and purchased', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isTrue,
      );
    });

    test('step 1: returns true when active and restored', () {
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => false,
        ),
        isTrue,
      );
    });

    test('step 2: returns true for late purchased within 1 minute', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 0, 45); // 45 seconds
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
          now: now,
        ),
        isTrue,
      );
    });

    test('step 2: returns false for late purchase after 1 minute', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 2, 1); // 121 seconds (> 1 min in integer division)
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
          now: now,
        ),
        isFalse,
      );
    });

    test('step 2: Android excludes restored status in late purchase', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 0, 30);
      final pd = _makePurchase(status: PurchaseStatus.restored);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => true,
          now: now,
        ),
        isFalse,
      );
    });

    test('step 3: Android has no fallback - blocks non-active', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('returns false for error status even when active', () {
      final pd = _makePurchase(status: PurchaseStatus.error);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('returns false for pending status', () {
      final pd = _makePurchase(status: PurchaseStatus.pending);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: true,
          isSafetyTimeoutTriggered: false,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });

    test('step 2: returns false when not actual purchase', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 0, 30);
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: timeoutTime,
          isActualPurchaseCheck: (_) => false,
          now: now,
        ),
        isFalse,
      );
    });

    test('step 2: returns false when safetyTimeoutTime is null', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);
      expect(
        PurchaseHelper.shouldProcessActivePurchaseAndroid(
          purchaseDetails: pd,
          isActivePurchasing: false,
          isSafetyTimeoutTriggered: true,
          safetyTimeoutTime: null,
          isActualPurchaseCheck: (_) => true,
        ),
        isFalse,
      );
    });
  });

  group('iOS vs Android behavior differences', () {
    test('iOS allows restored in late purchase, Android does not', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 0, 30);
      final pd = _makePurchase(status: PurchaseStatus.restored);

      final iosResult = PurchaseHelper.shouldProcessActivePurchaseIOS(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: true,
        safetyTimeoutTime: timeoutTime,
        isActualPurchaseCheck: (_) => true,
        now: now,
      );

      final androidResult = PurchaseHelper.shouldProcessActivePurchaseAndroid(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: true,
        safetyTimeoutTime: timeoutTime,
        isActualPurchaseCheck: (_) => true,
        now: now,
      );

      expect(iosResult, isTrue);
      expect(androidResult, isFalse);
    });

    test('iOS has fallback for non-active actual purchases, Android does not', () {
      final pd = _makePurchase(status: PurchaseStatus.purchased);

      final iosResult = PurchaseHelper.shouldProcessActivePurchaseIOS(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: false,
        safetyTimeoutTime: null,
        isActualPurchaseCheck: (_) => true,
      );

      final androidResult = PurchaseHelper.shouldProcessActivePurchaseAndroid(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: false,
        safetyTimeoutTime: null,
        isActualPurchaseCheck: (_) => true,
      );

      expect(iosResult, isTrue);
      expect(androidResult, isFalse);
    });

    test('iOS allows 2 min late window, Android only 1 min', () {
      final timeoutTime = DateTime(2024, 1, 1, 12, 0, 0);
      final now = DateTime(2024, 1, 1, 12, 2, 1); // 121 seconds (> 1 min integer, <= 2 min)
      final pd = _makePurchase(status: PurchaseStatus.purchased);

      final iosResult = PurchaseHelper.shouldProcessActivePurchaseIOS(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: true,
        safetyTimeoutTime: timeoutTime,
        isActualPurchaseCheck: (_) => true,
        now: now,
      );

      final androidResult = PurchaseHelper.shouldProcessActivePurchaseAndroid(
        purchaseDetails: pd,
        isActivePurchasing: false,
        isSafetyTimeoutTriggered: true,
        safetyTimeoutTime: timeoutTime,
        isActualPurchaseCheck: (_) => true,
        now: now,
      );

      expect(iosResult, isTrue);
      expect(androidResult, isFalse);
    });
  });
}
