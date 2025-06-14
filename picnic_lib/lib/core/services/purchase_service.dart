import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_lib/supabase_options.dart';

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
      logger.i('=== Purchase Handling Started ===');
      logger.i(
          'Processing purchase: ${purchaseDetails.productID} with status: ${purchaseDetails.status}');
      logger.i('Purchase ID: ${purchaseDetails.purchaseID}');
      logger.i('Pending complete: ${purchaseDetails.pendingCompletePurchase}');

      // 환경 정보 미리 확인
      final environment = await receiptVerificationService.getEnvironment();
      logger.i('Current environment: $environment');

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
        logger.i('Completing pending purchase...');
        await inAppPurchaseService.completePurchase(purchaseDetails);
        logger.i('Purchase completion finished');
      }

      logger.i('=== Purchase Handling Completed ===');
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
      logger.i('Starting successful purchase handling...');
      logger.i('Purchase ID: ${purchaseDetails.productID}');
      logger.i('Purchase Status: ${purchaseDetails.status}');
      logger.i('Transaction ID: ${purchaseDetails.purchaseID}');

      final storeProducts = await ref.read(storeProductsProvider.future);
      logger.i('Store products loaded: ${storeProducts.length} products');

      final environment = await receiptVerificationService.getEnvironment();
      logger.i('Environment determined: $environment');

      // 영수증 데이터 로그
      final receiptData =
          purchaseDetails.verificationData.serverVerificationData;
      logger.i('Receipt data available: ${receiptData.isNotEmpty}');
      logger.i('Receipt data length: ${receiptData.length}');

      // 사용자 정보 확인
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        logger.e('No authenticated user found');
        throw Exception('사용자 인증이 필요합니다');
      }
      logger.i('User authenticated: ${currentUser.id}');

      // 영수증 검증 시작
      logger.i('Starting receipt verification...');
      await receiptVerificationService.verifyReceipt(
        receiptData,
        purchaseDetails.productID,
        currentUser.id,
        environment,
      );
      logger.i('Receipt verification completed successfully');

      final productDetails = storeProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => throw Exception('구매한 상품을 찾을 수 없습니다'),
      );
      logger.i('Product details found: ${productDetails.id}');

      logger.i('Logging analytics event...');
      await analyticsService.logPurchaseEvent(productDetails);
      logger.i('Analytics event logged successfully');

      onSuccess();
      logger.i('Purchase successfully completed: ${purchaseDetails.productID}');
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);

      // 더 구체적인 에러 메시지 제공
      String errorMessage = '구매 검증 중 오류가 발생했습니다';
      if (e.toString().contains('Receipt verification failed')) {
        errorMessage = '영수증 검증에 실패했습니다. 잠시 후 다시 시도해주세요.';
      } else if (e.toString().contains('사용자 인증')) {
        errorMessage = '사용자 인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.toString().contains('구매한 상품을 찾을 수 없습니다')) {
        errorMessage = '구매한 상품 정보를 찾을 수 없습니다.';
      }

      onError(errorMessage);
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
            : element.id ==
                Environment.inappAppNamePrefix + serverProduct['id'],
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
