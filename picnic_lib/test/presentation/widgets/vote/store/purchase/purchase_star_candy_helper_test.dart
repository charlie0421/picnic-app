import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_helper.dart';

void main() {
  // ===========================================================================
  // errorCodeToMessageKey
  // ===========================================================================
  group('PurchaseStarCandyHelper.errorCodeToMessageKey', () {
    test('maps ERR_PREV_TX to previousTransactionPendingError', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errPrevTransactionPending,
        ),
        'previousTransactionPendingError',
      );
    });

    test('maps ERR_COOLDOWN to previousTransactionPendingError', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errCooldownActive,
        ),
        'previousTransactionPendingError',
      );
    });

    test('maps ERR_TOO_SOON to previousTransactionPendingError', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errTooSoon,
        ),
        'previousTransactionPendingError',
      );
    });

    test('maps ERR_RECENT_PURCHASE to previousTransactionPendingError', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errRecentPurchase,
        ),
        'previousTransactionPendingError',
      );
    });

    test('maps ERR_REQUEST_DUPLICATE to previousTransactionPendingError', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errRequestDuplicate,
        ),
        'previousTransactionPendingError',
      );
    });

    test('maps RECEIPT_VERIFICATION_FAILED', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          'RECEIPT_VERIFICATION_FAILED',
        ),
        'error_receipt_verification_failed',
      );
    });

    test('maps USER_NOT_AUTHENTICATED', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          'USER_NOT_AUTHENTICATED',
        ),
        'error_user_not_authenticated',
      );
    });

    test('maps PRODUCT_NOT_FOUND', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey('PRODUCT_NOT_FOUND'),
        'error_product_not_found',
      );
    });

    test('maps TIMEOUT to the payment-accepted message', () {
      // 예전 문구(purchase_timeout_message: "나중에 다시 시도해주세요")는
      // 소비형 상품의 재결제를 권해 이중 과금을 유도했다.
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errTimeout,
        ),
        'purchase_payment_accepted_message',
      );
    });

    test('maps PROCESSING to the payment-accepted message', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errProcessing,
        ),
        'purchase_payment_accepted_message',
      );
    });

    test('no mapped message invites a retry for a settlement-pending code', () {
      for (final code in [
        PurchaseConstants.errProcessing,
        PurchaseConstants.errTimeout,
      ]) {
        expect(
          PurchaseStarCandyHelper.errorCodeToMessageKey(code),
          'purchase_payment_accepted_message',
          reason: '$code',
        );
      }
    });

    test('maps AUTH_TIMEOUT to dialog_message_purchase_failed', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errAuthTimeout,
        ),
        'dialog_message_purchase_failed',
      );
    });

    test('maps NETWORK to error_network_connection', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errNetwork,
        ),
        'error_network_connection',
      );
    });

    test('maps SERVER to network_error_message', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errServer,
        ),
        'network_error_message',
      );
    });

    test('maps ERR_PURCHASE_CANCELED to purchase_cancelled_message', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errPurchaseCanceled,
        ),
        'purchase_cancelled_message',
      );
    });

    test('maps ERR_IN_PROGRESS to purchase_in_progress_message', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errInProgress,
        ),
        'purchase_in_progress_message',
      );
    });

    test('maps ERR_CONCURRENT to purchase_in_progress_message', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(
          PurchaseConstants.errConcurrent,
        ),
        'purchase_in_progress_message',
      );
    });

    test('returns null for unknown error code', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey('TOTALLY_UNKNOWN'),
        isNull,
      );
    });

    test('returns null for empty string', () {
      expect(
        PurchaseStarCandyHelper.errorCodeToMessageKey(''),
        isNull,
      );
    });
  });

  // ===========================================================================
  // isPurchaseResultCancelled
  // ===========================================================================
  group('PurchaseStarCandyHelper.isPurchaseResultCancelled', () {
    test('returns true when wasCancelled is true', () {
      expect(
        PurchaseStarCandyHelper.isPurchaseResultCancelled(
          {'wasCancelled': true},
        ),
        isTrue,
      );
    });

    test('returns false when wasCancelled is false', () {
      expect(
        PurchaseStarCandyHelper.isPurchaseResultCancelled(
          {'wasCancelled': false},
        ),
        isFalse,
      );
    });

    test('returns false when wasCancelled key is absent', () {
      expect(
        PurchaseStarCandyHelper.isPurchaseResultCancelled({}),
        isFalse,
      );
    });

    test('returns false when wasCancelled is null', () {
      expect(
        PurchaseStarCandyHelper.isPurchaseResultCancelled(
          {'wasCancelled': null},
        ),
        isFalse,
      );
    });

    test('returns false when wasCancelled is a non-bool truthy value', () {
      expect(
        PurchaseStarCandyHelper.isPurchaseResultCancelled(
          {'wasCancelled': 1},
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // isBuyButtonEnabled
  // ===========================================================================
  group('PurchaseStarCandyHelper.isBuyButtonEnabled', () {
    test('returns true when not initializing and not purchasing', () {
      expect(
        PurchaseStarCandyHelper.isBuyButtonEnabled(
          isInitializing: false,
          isPurchasing: false,
        ),
        isTrue,
      );
    });

    test('returns false when initializing', () {
      expect(
        PurchaseStarCandyHelper.isBuyButtonEnabled(
          isInitializing: true,
          isPurchasing: false,
        ),
        isFalse,
      );
    });

    test('returns false when purchasing', () {
      expect(
        PurchaseStarCandyHelper.isBuyButtonEnabled(
          isInitializing: false,
          isPurchasing: true,
        ),
        isFalse,
      );
    });

    test('returns false when both initializing and purchasing', () {
      expect(
        PurchaseStarCandyHelper.isBuyButtonEnabled(
          isInitializing: true,
          isPurchasing: true,
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // isProductLoading
  // ===========================================================================
  group('PurchaseStarCandyHelper.isProductLoading', () {
    test('returns true when purchasing and product matches', () {
      expect(
        PurchaseStarCandyHelper.isProductLoading(
          isPurchasing: true,
          pendingProductId: 'STAR100',
          productId: 'STAR100',
        ),
        isTrue,
      );
    });

    test('returns false when not purchasing', () {
      expect(
        PurchaseStarCandyHelper.isProductLoading(
          isPurchasing: false,
          pendingProductId: 'STAR100',
          productId: 'STAR100',
        ),
        isFalse,
      );
    });

    test('returns false when product ID does not match', () {
      expect(
        PurchaseStarCandyHelper.isProductLoading(
          isPurchasing: true,
          pendingProductId: 'STAR100',
          productId: 'STAR500',
        ),
        isFalse,
      );
    });

    test('returns false when pendingProductId is null', () {
      expect(
        PurchaseStarCandyHelper.isProductLoading(
          isPurchasing: true,
          pendingProductId: null,
          productId: 'STAR100',
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // productIconAssetPath
  // ===========================================================================
  group('PurchaseStarCandyHelper.productIconAssetPath', () {
    test('generates correct path for STAR100', () {
      expect(
        PurchaseStarCandyHelper.productIconAssetPath('STAR100'),
        'assets/icons/store/star_100.png',
      );
    });

    test('generates correct path for STAR500', () {
      expect(
        PurchaseStarCandyHelper.productIconAssetPath('STAR500'),
        'assets/icons/store/star_500.png',
      );
    });

    test('generates correct path for STAR1000', () {
      expect(
        PurchaseStarCandyHelper.productIconAssetPath('STAR1000'),
        'assets/icons/store/star_1000.png',
      );
    });

    test('handles product ID without STAR prefix gracefully', () {
      // replaceAll('STAR', '') on '100' returns '100'
      expect(
        PurchaseStarCandyHelper.productIconAssetPath('100'),
        'assets/icons/store/star_100.png',
      );
    });
  });

  // ===========================================================================
  // formatButtonPrice
  // ===========================================================================
  group('PurchaseStarCandyHelper.formatButtonPrice', () {
    test('formats integer price', () {
      expect(
        PurchaseStarCandyHelper.formatButtonPrice({'price': 5}),
        '5 \$',
      );
    });

    test('formats decimal price', () {
      expect(
        PurchaseStarCandyHelper.formatButtonPrice({'price': 4.99}),
        '4.99 \$',
      );
    });

    test('formats string price', () {
      expect(
        PurchaseStarCandyHelper.formatButtonPrice({'price': '9.99'}),
        '9.99 \$',
      );
    });

    test('formats zero price', () {
      expect(
        PurchaseStarCandyHelper.formatButtonPrice({'price': 0}),
        '0 \$',
      );
    });
  });

  // ===========================================================================
  // validateCanPurchase
  // ===========================================================================
  group('PurchaseStarCandyHelper.validateCanPurchase', () {
    test('returns null when purchase is allowed', () {
      expect(
        PurchaseStarCandyHelper.validateCanPurchase(
          isPurchasing: false,
          canAttemptForProduct: true,
        ),
        isNull,
      );
    });

    test('returns in_progress when already purchasing', () {
      expect(
        PurchaseStarCandyHelper.validateCanPurchase(
          isPurchasing: true,
          canAttemptForProduct: true,
        ),
        'in_progress',
      );
    });

    test('returns cooldown when product cooldown is active', () {
      expect(
        PurchaseStarCandyHelper.validateCanPurchase(
          isPurchasing: false,
          canAttemptForProduct: false,
        ),
        'cooldown',
      );
    });

    test('returns in_progress when both purchasing and on cooldown (isPurchasing takes priority)', () {
      expect(
        PurchaseStarCandyHelper.validateCanPurchase(
          isPurchasing: true,
          canAttemptForProduct: false,
        ),
        'in_progress',
      );
    });
  });
}
