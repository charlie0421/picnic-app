import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure logic helper extracted from PurchaseSafetyManager.
/// All methods are static, side-effect free, and easily testable.
@visibleForTesting
class PurchaseSafetyHelper {
  // ---- Constants (mirrored from PurchaseSafetyManager) ----
  static const Duration safetyTimeout = Duration(seconds: 90);
  static const Duration basePurchaseCooldown = Duration(minutes: 1);
  static const Duration consecutivePurchaseCooldown = Duration(minutes: 1);
  static const Duration sessionWindowDuration = Duration(minutes: 10);

  // iOS / Android delayed-signal windows
  static const int iosFlexibleWindowSeconds = 30;
  static const int iosFallbackWindowMinutes = 3;
  static const int androidStrictWindowSeconds = 10;

  // ---- Cancel keyword / error-code lists ----
  static const List<String> cancelKeywords = [
    'cancel',
    'cancelled',
    'canceled',
    'user cancel',
    'abort',
    'dismiss',
    'authentication',
    'touch id',
    'face id',
    'biometric',
    'passcode',
    'unauthorized',
    'permission denied',
    'operation was cancelled',
    'user cancelled',
    'user denied',
    'authentication failed',
    'authentication cancelled',
    'user interaction required',
    'interaction not allowed',
    'declined',
    'rejected',
    'stopped',
    'interrupted',
    'terminated',
    'aborted',
  ];

  static const List<String> cancelErrorCodes = [
    'PAYMENT_CANCELED',
    'USER_CANCELED',
    '2',
    'SKErrorPaymentCancelled',
    'BILLING_RESPONSE_USER_CANCELED',
    '-1002',
    '-2',
    'LAErrorUserCancel',
  ];

  // ----------------------------------------------------------------
  // Adaptive cooldown calculation
  // ----------------------------------------------------------------

  /// Returns whether the session should be reset (i.e. session window expired).
  static bool isSessionExpired({
    required DateTime? firstPurchaseInSession,
    required DateTime now,
    Duration sessionWindow = const Duration(minutes: 10),
  }) {
    if (firstPurchaseInSession == null) return false;
    return now.difference(firstPurchaseInSession).inMinutes >
        sessionWindow.inMinutes;
  }

  /// Returns the adaptive cooldown duration given a consecutive purchase count.
  /// If [consecutiveCount] >= 2, returns [consecutivePurchaseCooldown];
  /// otherwise returns [basePurchaseCooldown].
  static Duration getAdaptiveCooldown({
    required int consecutiveCount,
    Duration base = const Duration(minutes: 1),
    Duration consecutive = const Duration(minutes: 1),
  }) {
    if (consecutiveCount >= 2) {
      return consecutive;
    }
    return base;
  }

  // ----------------------------------------------------------------
  // Cooldown blocking checks
  // ----------------------------------------------------------------

  /// Returns `true` when the product is still within a forced cooldown window.
  static bool isProductForceCooldownActive({
    required DateTime? cooldownUntil,
    required DateTime now,
  }) {
    if (cooldownUntil == null) return false;
    return now.isBefore(cooldownUntil);
  }

  /// Computes the remaining cooldown [Duration] (or `null` if expired).
  static Duration? computeRemainingCooldown({
    required DateTime? lastPurchaseTime,
    required Duration requiredCooldown,
    required DateTime now,
  }) {
    if (lastPurchaseTime == null) return null;
    final elapsed = now.difference(lastPurchaseTime);
    if (elapsed < requiredCooldown) {
      return requiredCooldown - elapsed;
    }
    return null;
  }

  /// Whether a purchase attempt is blocked by per-product cooldown.
  /// Returns remaining [Duration] if blocked, otherwise `null`.
  static Duration? productCooldownRemaining({
    required DateTime? lastPurchaseTimeForProduct,
    required int consecutiveCountForProduct,
    required DateTime now,
    Duration base = const Duration(minutes: 1),
    Duration consecutive = const Duration(minutes: 1),
  }) {
    if (lastPurchaseTimeForProduct == null) return null;
    final required = getAdaptiveCooldown(
      consecutiveCount: consecutiveCountForProduct,
      base: base,
      consecutive: consecutive,
    );
    final elapsed = now.difference(lastPurchaseTimeForProduct);
    if (elapsed < required) {
      return required - elapsed;
    }
    return null;
  }

  // ----------------------------------------------------------------
  // Cancel / error classification
  // ----------------------------------------------------------------

  /// Returns `true` when [errorMessage] contains any cancel keyword.
  static bool containsCancelKeyword(String errorMessage) {
    final lower = errorMessage.toLowerCase();
    for (final keyword in cancelKeywords) {
      if (lower.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` when [errorCode] or [errorMessage] matches a known
  /// cancel error code.
  static bool matchesCancelErrorCode(String errorCode, String errorMessage) {
    for (final code in cancelErrorCodes) {
      if (errorCode.contains(code) || errorMessage.contains(code)) {
        return true;
      }
    }
    return false;
  }

  /// Combined cancel detection: status-based or keyword/code-based.
  /// [statusIsCanceled] should be `true` when
  /// `purchaseDetails.status == PurchaseStatus.canceled`.
  /// [statusIsError] should be `true` when
  /// `purchaseDetails.status == PurchaseStatus.error`.
  static bool isPurchaseCanceled({
    required bool statusIsCanceled,
    required bool statusIsError,
    required String errorMessage,
    required String errorCode,
  }) {
    if (statusIsCanceled) return true;
    if (statusIsError) {
      return containsCancelKeyword(errorMessage) ||
          matchesCancelErrorCode(errorCode, errorMessage);
    }
    return false;
  }

  // ----------------------------------------------------------------
  // Purchase validation (platform-independent logic)
  // ----------------------------------------------------------------

  /// Whether the transaction is a known duplicate.
  static bool isDuplicateTransaction({
    required String transactionId,
    required String? lastProcessedTransactionId,
  }) {
    if (lastProcessedTransactionId == null) return false;
    return transactionId == lastProcessedTransactionId;
  }

  /// iOS purchase validation: determines whether a purchase event should be
  /// treated as a real purchase vs. a stale/duplicate signal.
  ///
  /// [statusIsPurchasedOrRestored] - true when status is purchased or restored.
  /// [isPurchaseInProgress] - true when there is an active purchase flow.
  /// [lastPurchaseTime] - when the last purchase attempt was made.
  /// [now] - current time.
  static bool isActualPurchaseIOS({
    required bool statusIsPurchasedOrRestored,
    required bool isPurchaseInProgress,
    required DateTime? lastPurchaseTime,
    required DateTime now,
  }) {
    if (!statusIsPurchasedOrRestored) return false;

    // Stage 1: active purchase in progress
    if (isPurchaseInProgress) return true;

    // Stage 2: within 30-second flexible window
    if (lastPurchaseTime != null) {
      final elapsed = now.difference(lastPurchaseTime);
      if (elapsed.inSeconds <= iosFlexibleWindowSeconds) return true;

      // Stage 3: within 3-minute fallback window
      if (elapsed.inMinutes <= iosFallbackWindowMinutes) return true;
    }

    return false;
  }

  /// Android purchase validation: stricter than iOS.
  ///
  /// [statusIsPurchased] - true when status is exactly purchased.
  /// [isPurchaseInProgress] - true when there is an active purchase flow.
  /// [lastPurchaseTime] - when the last purchase attempt was made.
  /// [now] - current time.
  static bool isActualPurchaseAndroid({
    required bool statusIsPurchased,
    required bool isPurchaseInProgress,
    required DateTime? lastPurchaseTime,
    required DateTime now,
  }) {
    // Stage 1: active + purchased
    if (isPurchaseInProgress && statusIsPurchased) return true;

    // Stage 2: within 10-second strict window
    if (lastPurchaseTime != null && statusIsPurchased) {
      final elapsed = now.difference(lastPurchaseTime);
      if (elapsed.inSeconds <= androidStrictWindowSeconds) return true;
    }

    // Android: strict block otherwise
    return false;
  }

  // ----------------------------------------------------------------
  // Late purchase detection
  // ----------------------------------------------------------------

  /// Whether a purchase signal is a "late" purchase (arrived after safety
  /// timeout fired).
  static bool isLatePurchase({
    required bool isActivePurchasing,
    required bool safetyTimeoutTriggered,
    required DateTime? safetyTimeoutTime,
  }) {
    return !isActivePurchasing &&
        safetyTimeoutTriggered &&
        safetyTimeoutTime != null;
  }

  // ----------------------------------------------------------------
  // State reset determination
  // ----------------------------------------------------------------

  /// Whether the consecutive-purchase session should be reset based on the
  /// provided [reason] string (contains cancel/failure keywords).
  static bool shouldResetConsecutiveSession(String reason) {
    return reason.contains('\uCDE8\uC18C') || reason.contains('\uC2E4\uD328');
  }

  // ----------------------------------------------------------------
  // Cleanup type determination
  // ----------------------------------------------------------------

  /// Whether cleanup should use the lightweight path (consecutive purchase).
  static bool shouldUseLightweightCleanup({
    required int consecutivePurchaseCount,
  }) {
    return consecutivePurchaseCount >= 2;
  }

  /// Returns the post-purchase wait time in milliseconds.
  static int getPostPurchaseWaitMs({required bool isConsecutivePurchase}) {
    return isConsecutivePurchase ? 100 : 200;
  }
}
