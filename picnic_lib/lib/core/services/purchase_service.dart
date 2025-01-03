import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class PurchaseService {
  PurchaseService({
    required this.ref,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
  }) {
    // 전달받은 콜백으로 초기화
    inAppPurchaseService.init(onPurchaseUpdate);
  }

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
      logger.i(
          'Processing purchase: ${purchaseDetails.productID} with status: ${purchaseDetails.status}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          logger.i('Purchase is pending...');
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
          logger
              .i('Purchase was canceled by user: ${purchaseDetails.productID}');
          onError('구매가 취소되었습니다.');
          await analyticsService
              .logPurchaseCancelEvent(purchaseDetails.productID);
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await inAppPurchaseService.completePurchase(purchaseDetails);
      }
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      onError('구매 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('Purchase error: ${error?.message}, code: ${error?.code}');

    String errorMessage = '구매 중 오류가 발생했습니다.';

    if (error != null) {
      switch (error.code) {
        case 'payment_invalid':
          errorMessage = '결제 정보가 유효하지 않습니다.';
          break;
        case 'payment_canceled':
          errorMessage = '결제가 취소되었습니다.';
          break;
        case 'store_problem':
          errorMessage = '스토어 연결에 문제가 있습니다.';
          break;
        default:
          errorMessage = '구매 처리 중 오류가 발생했습니다: ${error.message}';
      }
    }

    onError(errorMessage);
    await analyticsService.logPurchaseErrorEvent(
      productId: purchaseDetails.productID,
      errorCode: error?.code ?? 'unknown',
      errorMessage: error?.message ?? 'No error message',
    );
  }

  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
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
        orElse: () => throw Exception('구매한 상품을 찾을 수 없습니다'),
      );

      await analyticsService.logPurchaseEvent(productDetails);
      onSuccess();

      logger.i('Purchase successfully completed: ${purchaseDetails.productID}');
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);
      onError('구매 검증 중 오류가 발생했습니다');
      rethrow;
    }
  }

  Future<bool> initiatePurchase(
    String productId, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final storeProducts = await ref.read(storeProductsProvider.future);
      final serverProduct = ref
          .read(serverProductsProvider.notifier)
          .getProductDetailById(productId);

      if (serverProduct == null) {
        throw Exception('서버에서 상품 정보를 찾을 수 없습니다');
      }

      final productDetails = storeProducts.firstWhere(
        (element) => isAndroid()
            ? element.id.toUpperCase() == serverProduct['id']
            : element.id == serverProduct['id'],
        orElse: () => throw Exception('스토어에서 상품을 찾을 수 없습니다'),
      );

      return await inAppPurchaseService.buyConsumable(productDetails);
    } catch (e, s) {
      logger.e('Error during buy button press: $e', stackTrace: s);
      onError('구매 시작 중 오류가 발생했습니다');
      return false;
    }
  }
}
