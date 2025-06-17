import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/supabase_options.dart';

class PurchaseService {
  PurchaseService({
    required this.ref,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
  }) {
    inAppPurchaseService.initialize(onPurchaseUpdate);
  }

  final WidgetRef ref;
  final InAppPurchaseService inAppPurchaseService;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;

  /// 구매 처리 메인 메서드
  Future<void> handlePurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('=== Purchase Handling Started ===');
      logger.i(
          'Processing: ${purchaseDetails.productID} (${purchaseDetails.status})');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          logger.i('Purchase is pending...');
          break;
        case PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails, onError);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails, onSuccess, onError);
          break;
        case PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails, onError);
          break;
      }

      await _completePurchaseIfNeeded(purchaseDetails);
      logger.i('=== Purchase Handling Completed ===');
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      onError(PurchaseConstants.purchaseFailedError);
    }
  }

  /// 최적화된 구매 처리 (JWT 재사용 방지 + 정상 영수증 검증)
  Future<void> handleOptimizedPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError, {
    required bool isActualPurchase,
  }) async {
    try {
      final purchaseType = isActualPurchase ? '신규 구매' : '복원된 구매';
      logger.i('=== 🚀 $purchaseType 처리 시작 ===');
      logger.i('Product: ${purchaseDetails.productID}');
      logger.i('실제 구매: $isActualPurchase');

      if (isActualPurchase) {
        await _handleActualPurchase(purchaseDetails, onSuccess, onError);
      } else {
        await _handleRestoredPurchase(purchaseDetails, onSuccess, onError);
      }

      logger.i('=== ✅ $purchaseType 처리 완료 ===');
    } catch (e, s) {
      logger.e('❌ 최적화된 구매 처리 오류: $e', stackTrace: s);
      onError(PurchaseConstants.purchaseFailedError);
    } finally {
      await _completePurchaseIfNeeded(purchaseDetails);
    }
  }

  /// 구매 시작
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

      final productDetails = _findProductDetails(storeProducts, serverProduct);
      return await inAppPurchaseService.makePurchase(productDetails);
    } catch (e, s) {
      logger.e('Error during purchase initiation: $e', stackTrace: s);
      onError('구매 시작 중 오류가 발생했습니다');
      return false;
    }
  }

  /// 구매 에러 처리
  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('Purchase error: ${error?.message}, code: ${error?.code}');

    final errorMessage = _getErrorMessage(error);
    onError(errorMessage);

    await analyticsService.logPurchaseErrorEvent(
      productId: purchaseDetails.productID,
      errorCode: error?.code ?? 'unknown',
      errorMessage: error?.message ?? 'No error message',
    );
  }

  /// 구매 취소 처리
  Future<void> _handlePurchaseCanceled(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    logger.i('Purchase canceled: ${purchaseDetails.productID}');
    onError(PurchaseConstants.purchaseCanceledError);
    await analyticsService.logPurchaseCancelEvent(purchaseDetails.productID);
  }

  /// 성공적인 구매 처리
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('Starting successful purchase handling...');

      await _validateUserAuthentication();
      final environment = await receiptVerificationService.getEnvironment();

      await _verifyReceipt(purchaseDetails, environment);
      await _logPurchaseAnalytics(purchaseDetails);

      onSuccess();
      logger.i('Purchase successfully completed: ${purchaseDetails.productID}');
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);
      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 실제 구매 처리 (단일 영수증 검증)
  Future<void> _handleActualPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🎯 실제 구매 처리 - 단일 영수증 검증');

    try {
      await _validateUserAuthentication();
      final environment = await receiptVerificationService.getEnvironment();
      await _validateReceiptData(purchaseDetails);

      final currentUser = supabase.auth.currentUser!;

      await receiptVerificationService.verifyReceipt(
        purchaseDetails.verificationData.serverVerificationData,
        purchaseDetails.productID,
        currentUser.id,
        environment,
      );

      await _logPurchaseAnalytics(purchaseDetails);
      onSuccess();

      logger.i('✅ 실제 구매 검증 완료');
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 - StoreKit 캐시 문제: ${e.message}');
      onError('StoreKit 캐시 문제로 인한 중복 영수증. 잠시 후 다시 시도해주세요.');
    }
  }

  /// 복원된 구매 처리
  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🔄 복원된 구매 처리');

    try {
      await _handleSuccessfulPurchase(purchaseDetails, onSuccess, onError);
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 복원 구매에서 JWT 재사용 감지: ${e.message}');
      onError('복원 과정에서 중복 영수증 감지. 이미 처리된 구매입니다.');
    }
  }

  /// 사용자 인증 검증
  Future<void> _validateUserAuthentication() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception(PurchaseConstants.userNotAuthenticatedError);
    }
    logger.i('User authenticated: ${currentUser.id}');
  }

  /// 영수증 데이터 검증
  Future<void> _validateReceiptData(PurchaseDetails purchaseDetails) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    if (receiptData.isEmpty) {
      throw Exception('영수증 데이터가 비어있습니다');
    }
    logger.i('영수증 데이터 검증 완료 - 길이: ${receiptData.length}');
  }

  /// 영수증 검증
  Future<void> _verifyReceipt(
    PurchaseDetails purchaseDetails,
    String environment,
  ) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    final currentUser = supabase.auth.currentUser!;

    logger.i('영수증 검증 시작...');
    await receiptVerificationService.verifyReceipt(
      receiptData,
      purchaseDetails.productID,
      currentUser.id,
      environment,
    );
    logger.i('영수증 검증 완료');
  }

  /// 구매 애널리틱스 로깅
  Future<void> _logPurchaseAnalytics(PurchaseDetails purchaseDetails) async {
    final storeProducts = await ref.read(storeProductsProvider.future);
    final productDetails = storeProducts.firstWhere(
      (product) => product.id == purchaseDetails.productID,
      orElse: () => throw Exception(PurchaseConstants.productNotFoundError),
    );

    logger.i('애널리틱스 로깅...');
    await analyticsService.logPurchaseEvent(productDetails);
    logger.i('애널리틱스 로깅 완료');
  }

  /// 구매 완료 처리
  Future<void> _completePurchaseIfNeeded(
      PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      logger.i('구매 완료 처리 중...');
      await inAppPurchaseService.completePurchase(purchaseDetails);
      logger.i('구매 완료 처리됨');
    }
  }

  /// 상품 세부 정보 찾기
  ProductDetails _findProductDetails(
    List<ProductDetails> storeProducts,
    Map<String, dynamic> serverProduct,
  ) {
    return storeProducts.firstWhere(
      (element) => isAndroid()
          ? element.id.toUpperCase() == serverProduct['id']
          : element.id == Environment.inappAppNamePrefix + serverProduct['id'],
      orElse: () => throw Exception('스토어에서 상품을 찾을 수 없습니다'),
    );
  }

  /// 에러 메시지 생성
  String _getErrorMessage(IAPError? error) {
    if (error == null) return PurchaseConstants.purchaseFailedError;

    switch (error.code) {
      case 'payment_invalid':
        return '결제 정보가 유효하지 않습니다.';
      case 'payment_canceled':
        return PurchaseConstants.purchaseCanceledError;
      case 'store_problem':
        return '스토어 연결에 문제가 있습니다.';
      default:
        return '구매 처리 중 오류가 발생했습니다: ${error.message}';
    }
  }

  /// 상세 에러 메시지 생성
  String _getDetailedErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Receipt verification failed')) {
      return '영수증 검증에 실패했습니다. 잠시 후 다시 시도해주세요.';
    } else if (errorString
        .contains(PurchaseConstants.userNotAuthenticatedError)) {
      return '사용자 인증이 필요합니다. 다시 로그인해주세요.';
    } else if (errorString.contains(PurchaseConstants.productNotFoundError)) {
      return PurchaseConstants.productNotFoundError;
    }

    return PurchaseConstants.purchaseFailedError;
  }
}
