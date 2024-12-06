import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:picnic_app/components/vote/store/purchase/analytics_service.dart';
import 'package:picnic_app/components/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_app/components/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';

class PurchaseService {
  PurchaseService({
    required this.ref,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
  });

  final WidgetRef ref;
  final InAppPurchaseService inAppPurchaseService;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;

  Future<void> handlePurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Handle pending status
          break;
        case PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails, onError);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(
            purchaseDetails,
            onSuccess,
            onError,
          );
          break;
        case PurchaseStatus.canceled:
          onError('Purchase was canceled');
          break;
        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await inAppPurchaseService.completePurchase(purchaseDetails);
      }
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      onError('Failed to complete purchase');
      rethrow;
    }
  }

  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    logger.e('Purchase error: ${purchaseDetails.error!.message}');
    onError('Purchase failed');
  }

  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      // Get store products from provider
      final storeProducts = await ref.read(storeProductsProvider.future);
      final environment = await receiptVerificationService.getEnvironment();

      await receiptVerificationService.verifyReceipt(
        purchaseDetails.verificationData.serverVerificationData,
        purchaseDetails.productID,
        supabase.auth.currentUser!.id,
        environment,
      );

      final productDetails = storeProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => throw Exception('Product not found'),
      );
      await analyticsService.logPurchaseEvent(productDetails);

      onSuccess();
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);
      onError('Failed to verify purchase');
      rethrow;
    }
  }

  Future<void> initiatePurchase(String productId) async {
    try {
      // Get products from providers
      final storeProducts = await ref.read(storeProductsProvider.future);

      final serverProduct = ref
          .read(serverProductsProvider.notifier)
          .getProductDetailById(productId);

      if (serverProduct == null) {
        throw Exception('Product not found in server products');
      }

      final productDetails = storeProducts.firstWhere(
        (element) => isAndroid()
            ? element.id.toUpperCase() == serverProduct['id']
            : element.id == serverProduct['id'],
        orElse: () => throw Exception('Product not found in store products'),
      );

      await inAppPurchaseService.buyConsumable(productDetails);
    } catch (e, s) {
      logger.e('Error during buy button press: $e', stackTrace: s);
      throw Exception('Failed to initiate purchase');
    }
  }
}
