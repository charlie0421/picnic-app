import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

/// Pure logic methods extracted from [InAppPurchaseService] for testability.
///
/// These methods contain no side effects, no platform channel calls,
/// no timers, no streams, and no logger dependencies.
@visibleForTesting
class InAppPurchaseHelper {
  const InAppPurchaseHelper._();

  // ---------------------------------------------------------------------------
  // Cancellation detection
  // ---------------------------------------------------------------------------

  /// All keywords that indicate a user-initiated cancellation.
  static const List<String> cancelKeywords = [
    // StoreKit 2 cancel codes
    'storekit2_purchase_cancelled',
    'storekit2_user_cancelled',
    'storekit2_cancelled',
    'purchase_cancelled',
    'transaction_cancelled',
    'user_cancelled_purchase',
    'cancelled_by_user',
    // StoreKit 1 cancel codes
    'payment_canceled',
    'user_canceled',
    'skeerrorpaymentcancelled',
    'billing_response_user_canceled',
    // Generic cancel keywords
    'cancel',
    'cancelled',
    'canceled',
    'user cancel',
    'abort',
    'dismiss',
    // iOS authentication-related cancellation keywords
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
    // StoreKit 2 cancel messages
    'transaction has been cancelled',
    'cancelled by the user',
    'purchase was cancelled',
    'user has cancelled',
    'transaction cancelled',
    'purchase cancelled',
    'payment cancelled',
    'cancelled transaction',
    'user cancellation',
    'cancelled by user',
  ];

  /// Returns `true` when [exception] looks like a user-initiated cancellation.
  ///
  /// The check is case-insensitive and matches against [cancelKeywords].
  static bool isPurchaseCancelledException(dynamic exception) {
    final exceptionString = exception.toString().toLowerCase();
    for (final keyword in cancelKeywords) {
      if (exceptionString.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Returns the specific cancel keyword that matched, or `null` if none did.
  static String? matchedCancelKeyword(dynamic exception) {
    final exceptionString = exception.toString().toLowerCase();
    for (final keyword in cancelKeywords) {
      if (exceptionString.contains(keyword)) {
        return keyword;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Timeout selection
  // ---------------------------------------------------------------------------

  /// Resolves the purchase timeout [Duration] for the given debug settings.
  ///
  /// [forceTimeout] – when `true`, always returns [PurchaseConstants.debugPurchaseTimeout].
  /// [timeoutMode] – one of `'instant'`, `'ultrafast'`, `'debug'`, or `'normal'`.
  static Duration resolveTimeout({
    required bool forceTimeout,
    required String timeoutMode,
  }) {
    if (forceTimeout) {
      return PurchaseConstants.debugPurchaseTimeout;
    }
    switch (timeoutMode) {
      case 'instant':
        return PurchaseConstants.instantTimeout;
      case 'ultrafast':
        return PurchaseConstants.ultraFastTimeout;
      case 'debug':
        return PurchaseConstants.debugPurchaseTimeout;
      default:
        return PurchaseConstants.purchaseTimeout;
    }
  }

  // ---------------------------------------------------------------------------
  // Duration formatting
  // ---------------------------------------------------------------------------

  /// Formats a [Duration] into a human-readable Korean string.
  ///
  /// - Durations < 1 second → `"500ms"` style
  /// - Durations >= 1 second → `"30초"` style
  static String formatDurationKorean(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }
    return '${duration.inSeconds}초';
  }

  // ---------------------------------------------------------------------------
  // Purchase status classification
  // ---------------------------------------------------------------------------

  /// Returns `true` when [status] indicates the purchase flow has ended
  /// (successfully, with an error, or by cancellation).
  static bool isTerminalStatus(PurchaseStatus status) {
    return status == PurchaseStatus.purchased ||
        status == PurchaseStatus.restored ||
        status == PurchaseStatus.error ||
        status == PurchaseStatus.canceled;
  }

  /// Filters [purchases] to only those whose [PurchaseDetails.status] is
  /// [PurchaseStatus.pending].
  static List<PurchaseDetails> filterPending(List<PurchaseDetails> purchases) {
    return purchases
        .where((p) => p.status == PurchaseStatus.pending)
        .toList();
  }

  /// Filters [purchases] to those that match [productId] AND are pending.
  static List<PurchaseDetails> filterPendingForProduct(
    List<PurchaseDetails> purchases,
    String productId,
  ) {
    return purchases
        .where(
            (p) => p.productID == productId && p.status == PurchaseStatus.pending)
        .toList();
  }

  /// Returns `true` when any purchase in [purchases] has a terminal status
  /// for the given [productId].
  static bool hasTerminalPurchaseForProduct(
    List<PurchaseDetails> purchases,
    String productId,
  ) {
    return purchases.any(
      (p) => p.productID == productId && isTerminalStatus(p.status),
    );
  }

  // ---------------------------------------------------------------------------
  // Cleanup statistics
  // ---------------------------------------------------------------------------

  /// Computes the cleanup success rate as a percentage string (e.g. `"85.0"`).
  ///
  /// Returns `"0"` when [totalFound] is zero.
  static String cleanupSuccessRate(int totalFound, int totalCleared) {
    if (totalFound <= 0) return '0';
    return (totalCleared / totalFound * 100).toStringAsFixed(1);
  }

  /// Builds the status map returned by `getPendingCleanupStatus`.
  ///
  /// [currentPending] – purchases currently in the pending state.
  /// [totalFound] / [totalCleared] – cumulative counters.
  /// [lastCleanupTime] – nullable timestamp of last cleanup.
  static Map<String, dynamic> buildCleanupStatusMap({
    required List<PurchaseDetails> currentPending,
    required int totalFound,
    required int totalCleared,
    DateTime? lastCleanupTime,
  }) {
    return {
      'currentPendingCount': currentPending.length,
      'totalPendingFound': totalFound,
      'totalPendingCleared': totalCleared,
      'lastCleanupTime': lastCleanupTime?.toIso8601String(),
      'currentPendingItems': currentPending
          .map((p) => {
                'productID': p.productID,
                'transactionDate': p.transactionDate,
                'pendingCompletePurchase': p.pendingCompletePurchase,
              })
          .toList(),
    };
  }

  /// Builds the error status map when cleanup status retrieval fails.
  static Map<String, dynamic> buildCleanupErrorMap({
    required String error,
    required int totalFound,
    required int totalCleared,
  }) {
    return {
      'error': error,
      'currentPendingCount': -1,
      'totalPendingFound': totalFound,
      'totalPendingCleared': totalCleared,
    };
  }

  // ---------------------------------------------------------------------------
  // Diagnosis helpers
  // ---------------------------------------------------------------------------

  /// Builds the list of recommended solutions for authentication problems.
  static List<String> buildAuthDiagnosisSolutions({
    int? currentPendingCount,
    bool? productQuerySuccess,
  }) {
    final solutions = <String>[];

    if (currentPendingCount != null && currentPendingCount > 0) {
      solutions.add(
        'Pending 구매가 $currentPendingCount개 있습니다. 핵리셋을 시도해보세요.',
      );
    }

    if (productQuerySuccess != true) {
      solutions.add('제품 쿼리가 실패했습니다. 인증초기화를 다시 시도해보세요.');
    }

    solutions.addAll(const [
      '1. 앱을 완전히 종료하고 재시작하세요',
      '2. iOS 설정 > App Store에서 로그아웃 후 재로그인하세요',
      '3. 디바이스를 재부팅해보세요',
      '4. 다른 Apple ID로 테스트해보세요',
      '5. 시뮬레이터에서 Device > Erase All Content and Settings 시도',
    ]);

    return solutions;
  }

  /// Builds the base diagnosis map shared by sandbox/auth diagnostic methods.
  static Map<String, dynamic> buildBaseDiagnosisMap({
    required String platform,
    required bool isDebugMode,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': platform,
      'isDebugMode': isDebugMode,
    };
  }

  // ---------------------------------------------------------------------------
  // Debug mode derivation
  // ---------------------------------------------------------------------------

  /// Derives the `debugMode` flag from a timeout mode string.
  ///
  /// Returns `true` for any mode other than `'normal'`.
  static bool isDebugModeFromTimeoutMode(String mode) {
    return mode != 'normal';
  }

  /// Returns the timeout mode string to use when debug mode is toggled.
  static String timeoutModeForDebugToggle(bool enabled) {
    return enabled ? 'debug' : 'normal';
  }
}
