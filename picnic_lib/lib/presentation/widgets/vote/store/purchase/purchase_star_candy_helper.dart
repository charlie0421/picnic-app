import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/core/constants/purchase_constants.dart';

/// Pure logic helpers extracted from PurchaseStarCandyState.
///
/// These are stateless utility methods that have no dependency on
/// Flutter widgets, Riverpod, or any async service. They can be
/// unit-tested without a widget test harness.
@visibleForTesting
class PurchaseStarCandyHelper {
  // ---------------------------------------------------------------------------
  // Error-code → i18n-key mapping
  // ---------------------------------------------------------------------------

  /// Maps an error code (from PurchaseService / edge function) to the
  /// corresponding i18n message key used by `AppLocalizations`.
  ///
  /// Returns `null` when the error code is unrecognised – callers should
  /// fall back to a generic failure message.
  static String? errorCodeToMessageKey(String errorCode) {
    switch (errorCode) {
      case PurchaseConstants.errPrevTransactionPending:
      case PurchaseConstants.errCooldownActive:
      case PurchaseConstants.errTooSoon:
      case PurchaseConstants.errRecentPurchase:
      case PurchaseConstants.errRequestDuplicate:
        return 'previousTransactionPendingError';
      case 'RECEIPT_VERIFICATION_FAILED':
        return 'error_receipt_verification_failed';
      case 'USER_NOT_AUTHENTICATED':
        return 'error_user_not_authenticated';
      case 'PRODUCT_NOT_FOUND':
        return 'error_product_not_found';
      case PurchaseConstants.errTimeout:
        return 'purchase_timeout_message';
      case PurchaseConstants.errAuthTimeout:
        return 'dialog_message_purchase_failed';
      case PurchaseConstants.errNetwork:
        return 'error_network_connection';
      case PurchaseConstants.errServer:
        return 'network_error_message';
      case PurchaseConstants.errPurchaseCanceled:
        return 'purchase_cancelled_message';
      case PurchaseConstants.errInProgress:
      case PurchaseConstants.errConcurrent:
        return 'purchase_in_progress_message';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase result analysis
  // ---------------------------------------------------------------------------

  /// Returns `true` when the purchase result map signals a user-initiated
  /// cancellation (the store sheet was dismissed by the user).
  static bool isPurchaseResultCancelled(Map<String, dynamic> purchaseResult) {
    return purchaseResult['wasCancelled'] == true;
  }

  // ---------------------------------------------------------------------------
  // UI state helpers
  // ---------------------------------------------------------------------------

  /// Determines whether the buy button should be enabled.
  ///
  /// The button is disabled while the store is still initialising or while
  /// a purchase is already in progress.
  static bool isBuyButtonEnabled({
    required bool isInitializing,
    required bool isPurchasing,
  }) {
    return !isInitializing && !isPurchasing;
  }

  /// Returns `true` when the loading spinner should be shown on a specific
  /// product tile (the product whose purchase is currently pending).
  static bool isProductLoading({
    required bool isPurchasing,
    required String? pendingProductId,
    required String productId,
  }) {
    return isPurchasing && pendingProductId == productId;
  }

  // ---------------------------------------------------------------------------
  // Asset path generation
  // ---------------------------------------------------------------------------

  /// Builds the asset path for a star-candy product icon.
  ///
  /// Product IDs follow the pattern `STAR100`, `STAR500`, etc. The method
  /// strips the `STAR` prefix to locate the matching PNG asset.
  static String productIconAssetPath(String productId) {
    final suffix = productId.replaceAll('STAR', '');
    return 'assets/icons/store/star_$suffix.png';
  }

  // ---------------------------------------------------------------------------
  // Price / display formatting
  // ---------------------------------------------------------------------------

  /// Formats a price value from a server product map for display on the buy
  /// button (e.g. `"4.99 \$"`).
  static String formatButtonPrice(Map<String, dynamic> serverProduct) {
    return '${serverProduct['price']} \$';
  }

  // ---------------------------------------------------------------------------
  // Purchase-guard validation
  // ---------------------------------------------------------------------------

  /// Checks whether a new purchase attempt is currently allowed.
  ///
  /// Returns one of:
  /// - `null` when the purchase may proceed,
  /// - `'in_progress'` when a purchase is already running,
  /// - `'cooldown'` when the per-product cooldown has not yet elapsed.
  static String? validateCanPurchase({
    required bool isPurchasing,
    required bool canAttemptForProduct,
  }) {
    if (isPurchasing) return 'in_progress';
    if (!canAttemptForProduct) return 'cooldown';
    return null;
  }
}
