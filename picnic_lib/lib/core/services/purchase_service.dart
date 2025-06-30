import 'dart:async';
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
// 🔥 복잡한 가드 시스템 제거 - 단순 중복 방지만 사용
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';

class PurchaseService {
  PurchaseService({
    required this.ref,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
    required this.duplicatePreventionService,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
  }) {
    inAppPurchaseService.initialize(onPurchaseUpdate);

    // 🚨 타임아웃 콜백 설정
    inAppPurchaseService.onPurchaseTimeout = handlePurchaseTimeout;

    logger.i('✅ PurchaseService 초기화 완료 - 강화된 중복 방지 시스템 활성화');
  }

  final WidgetRef ref;
  final InAppPurchaseService inAppPurchaseService;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;
  final DuplicatePreventionService duplicatePreventionService;

  // 🔥 단순화: 복잡한 가드 시스템 제거
  // 기본적인 제품별 구매 진행 상태만 추적 (백업용)
  final Set<String> _processingProducts = {};

  // 🧹 UI 리셋 콜백 (타임아웃 시 UI 상태 정리용)
  void Function()? onTimeoutUIReset;

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

  /// 구매 처리 (단순화)
  Future<void> handleOptimizedPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError, {
    required bool isActualPurchase,
  }) async {
    try {
      if (isActualPurchase) {
        logger.i('=== 🚀 신규 구매 처리 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        await _handleActualPurchase(purchaseDetails, onSuccess, onError);

        logger.i('=== ✅ 신규 구매 완료 ===');
      } else {
        logger.i('=== 🚫 복원 구매 무시 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        // 🔥 복원 구매는 완전히 무시 - 콜백 실행 안함
        await _handleRestoredPurchase(purchaseDetails, onSuccess, onError);

        logger.i('=== ✅ 복원 구매 무시 완료 ===');
      }
    } catch (e, s) {
      logger.e('❌ 구매 처리 오류: $e', stackTrace: s);

      // 🔥 오류 시 진행 상태 정리
      _processingProducts.remove(purchaseDetails.productID);

      onError(PurchaseConstants.purchaseFailedError);
    } finally {
      await _completePurchaseIfNeeded(purchaseDetails);
    }
  }

  /// 구매 시작 (강화된 중복 방지) - 취소와 에러를 구분하여 반환
  Future<Map<String, dynamic>> initiatePurchase(
    String productId, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      onError('로그인이 필요합니다');
      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': '로그인이 필요합니다'
      };
    }

    try {
      // 🛡️ 1. 강화된 중복 방지 검증
      final validation =
          await duplicatePreventionService.validatePurchaseAttempt(
        productId,
        currentUser.id,
      );

      if (!validation.allowed) {
        logger.w('🚫 구매 중복 방지 검증 실패: ${validation.reason}');
        onError(validation.reason!);
        return {
          'success': false,
          'wasCancelled': false,
          'errorMessage': validation.reason,
          'denyType': validation.type?.toString(),
        };
      }

      logger.i('💳 구매 프로세스 시작 - Touch ID/Face ID 인증이 요청될 수 있습니다');

      // 🛡️ 2. 구매 시도 등록 (중복 방지 서비스에)
      duplicatePreventionService.registerPurchaseAttempt(
          productId, currentUser.id);

      // 3. 제품 정보 확인
      final storeProducts = await ref.read(storeProductsProvider.future);
      final serverProduct = ref
          .read(serverProductsProvider.notifier)
          .getProductDetailById(productId);

      if (serverProduct == null) {
        duplicatePreventionService.completePurchase(productId, currentUser.id,
            success: false);
        throw Exception('서버에서 상품 정보를 찾을 수 없습니다');
      }

      // 4. 구매 진행 상태 등록 (백업용)
      _processingProducts.add(productId);
      logger.i('✅ 구매 시작: $productId');

      // 🛡️ 5. Touch ID/Face ID 인증 시작 등록
      duplicatePreventionService.registerAuthenticationStart(
          productId, currentUser.id);

      // 6. 실제 구매 시작
      final productDetails = _findProductDetails(storeProducts, serverProduct);
      logger.i('🚀 StoreKit 구매 프로세스 시작 (Touch ID/Face ID 인증 포함)');

      final purchaseResult =
          await inAppPurchaseService.makePurchase(productDetails);

      if (!purchaseResult) {
        // 🔍 구매 실패 시 취소인지 실제 에러인지 구분
        if (inAppPurchaseService.lastPurchaseWasCancelled) {
          logger.i('🚫 구매 취소: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(productId, currentUser.id,
              success: false);
          // 취소는 에러가 아니므로 onError 호출하지 않음
          return {'success': false, 'wasCancelled': true, 'errorMessage': null};
        } else {
          logger.w('❌ 구매 요청 시작 실패: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(productId, currentUser.id,
              success: false);
          const errorMessage = '구매 요청을 시작할 수 없습니다. 잠시 후 다시 시도해주세요.';
          onError(errorMessage);
          return {
            'success': false,
            'wasCancelled': false,
            'errorMessage': errorMessage
          };
        }
      } else {
        logger.i('✅ StoreKit 구매 프로세스 시작 성공');
      }

      return {'success': true, 'wasCancelled': false, 'errorMessage': null};
    } catch (e, s) {
      logger.e('Error during purchase initiation: $e', stackTrace: s);
      _processingProducts.remove(productId);
      duplicatePreventionService.completePurchase(productId, currentUser.id,
          success: false);

      // 사용자 친화적 오류 메시지
      String userMessage = '구매 시작 중 오류가 발생했습니다';
      if (e.toString().contains('상품 정보')) {
        userMessage = '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.';
      } else if (e.toString().contains('네트워크')) {
        userMessage = '네트워크 연결을 확인해주세요.';
      }

      onError(userMessage);
      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': userMessage
      };
    }
  }

  /// 구매 에러 처리 (개선)
  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('❌ 구매 에러: ${error?.message}, code: ${error?.code}');

    // 🔥 에러 시에도 진행 상태에서 제거
    _processingProducts.remove(purchaseDetails.productID);

    final errorMessage = _getErrorMessage(error);
    onError(errorMessage);

    await analyticsService.logPurchaseErrorEvent(
      productId: purchaseDetails.productID,
      errorCode: error?.code ?? 'unknown',
      errorMessage: error?.message ?? 'No error message',
    );

    logger.i('✅ 구매 에러 처리 완료: ${purchaseDetails.productID}');
  }

  /// 구매 취소 처리 (개선)
  Future<void> _handlePurchaseCanceled(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    logger.i('🚫 구매 취소: ${purchaseDetails.productID}');

    // 🔥 진행 상태에서 제거 (중요!)
    _processingProducts.remove(purchaseDetails.productID);

    // 🔥 구매 취소 애널리틱스 로깅
    await analyticsService.logPurchaseCancelEvent(purchaseDetails.productID);

    logger.i('✅ 구매 취소 처리 완료: ${purchaseDetails.productID}');

    // 🔥 취소는 오류가 아니므로 onError 호출하지 않음
    // UI에서 별도의 취소 처리 로직이 있음 (_processErrorAndCancel)
  }

  /// 성공적인 구매 처리
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('Starting successful purchase handling...');

      _validateUserAuthentication();
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

  /// 실제 구매 처리 (단순화)
  Future<void> _handleActualPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🎯 실제 구매 처리 - 영수증 검증');

    try {
      _validateUserAuthentication();
      final environment = await receiptVerificationService.getEnvironment();
      logger.i('🌍 Environment detected: $environment');
      await _validateReceiptData(purchaseDetails);

      // 🔥 영수증 검증 (서버 검증 단계만 - 타임아웃 있음)
      await _verifyReceipt(purchaseDetails, environment);

      await _logPurchaseAnalytics(purchaseDetails);

      // 🔥 구매 완료 시 진행 상태 제거
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 성공 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
            purchaseDetails.productID, currentUser.id,
            success: true);
      }

      onSuccess();
      logger.i('✅ 실제 구매 검증 완료');
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 - StoreKit 캐시 문제: ${e.message}');
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 실패 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
            purchaseDetails.productID, currentUser.id,
            success: false);
      }

      onError('StoreKit 캐시 문제로 인한 중복 영수증. 잠시 후 다시 시도해주세요.');
    } catch (e, s) {
      logger.e('❌ 실제 구매 처리 중 오류: $e', stackTrace: s);
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 실패 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
            purchaseDetails.productID, currentUser.id,
            success: false);
      }

      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 복원된 구매 처리 (무시)
  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🚫 복원된 구매 무시: ${purchaseDetails.productID}');

    // 🔥 복원 구매는 완전히 무시하고 조용히 완료 처리만 함
    await _completePurchaseIfNeeded(purchaseDetails);

    // 진행 상태에서 제거 (혹시 있다면)
    _processingProducts.remove(purchaseDetails.productID);

    logger.i('✅ 복원된 구매 무시 완료');
  }

  /// 사용자 인증 검증 (단순화 - 타임아웃 제거)
  void _validateUserAuthentication() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception(PurchaseConstants.userNotAuthenticatedError);
    }
    logger.i('✅ 사용자 인증 확인 완료: ${currentUser.id}');
  }

  /// 영수증 데이터 검증
  Future<void> _validateReceiptData(PurchaseDetails purchaseDetails) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    if (receiptData.isEmpty) {
      throw Exception('영수증 데이터가 비어있습니다');
    }
    logger.i('영수증 데이터 검증 완료 - 길이: ${receiptData.length}');
  }

  /// 영수증 검증 (단순화 - 서비스에 위임)
  Future<void> _verifyReceipt(
    PurchaseDetails purchaseDetails,
    String environment,
  ) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    final currentUser = supabase.auth.currentUser!;

    logger.i('🔍 영수증 검증 시작 (서버 검증 단계)');
    logger.i('Environment: $environment');

    // ReceiptVerificationService가 타임아웃 + 재시도 로직을 모두 처리
    await receiptVerificationService.verifyReceipt(
      receiptData,
      purchaseDetails.productID,
      currentUser.id,
      environment,
    );

    logger.i('✅ 영수증 검증 완료');
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
    } else if (errorString.contains('구매 처리 시간이 초과')) {
      return PurchaseConstants.verificationTimeoutError;
    } else if (errorString.contains('Touch ID') ||
        errorString.contains('Face ID')) {
      return PurchaseConstants.authenticationTimeoutError;
    } else if (errorString
        .contains(PurchaseConstants.userNotAuthenticatedError)) {
      return '사용자 인증이 필요합니다. 다시 로그인해주세요.';
    } else if (errorString.contains(PurchaseConstants.productNotFoundError)) {
      return PurchaseConstants.productNotFoundError;
    }

    return PurchaseConstants.purchaseFailedError;
  }




  /// 서비스 해제 시 모든 진행 상태 정리
  void dispose() {
    logger.i('🧹 PurchaseService 해제: ${_processingProducts.length}개 진행 상태 정리');
    _processingProducts.clear();

    // 🛡️ 중복 방지 서비스 데이터 정리
    duplicatePreventionService.cleanupExpiredData();

    logger.i('✅ PurchaseService 해제 완료');
  }

  /// 현재 진행 중인 구매 수 (디버그용)
  int get activeProcessingCount => _processingProducts.length;

  /// 타임아웃 발생 시 구매 상태 정리 (InAppPurchaseService에서 호출)
  void handlePurchaseTimeout(String productId) {
    logger.w('⏰ 구매 타임아웃으로 인한 상태 정리: $productId');

    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      // 🛡️ 중복 방지 서비스에서 백그라운드 구매로 전환
      duplicatePreventionService.handlePurchaseTimeout(
          productId, currentUser.id);
    }

    if (_processingProducts.contains(productId)) {
      _processingProducts.remove(productId);
      logger.i('✅ 타임아웃된 구매 상태 정리 완료: $productId');
    } else {
      logger.i('ℹ️ 타임아웃된 구매가 진행 상태에 없음: $productId');
    }

    // 🧹 UI 상태 리셋 (로딩 해제, 구매 상태 초기화)
    if (onTimeoutUIReset != null) {
      logger.i('🧹 타임아웃으로 인한 UI 상태 리셋 호출');
      onTimeoutUIReset!();
    } else {
      logger.w('⚠️ UI 리셋 콜백이 설정되지 않음 - UI가 로딩 상태로 남을 수 있음');
    }
  }

  /// 모든 진행 중인 구매 상태 강제 정리 (긴급 상황용)
  void clearAllProcessingStates() {
    logger.w('🚨 모든 구매 진행 상태 강제 정리: ${_processingProducts.length}개');
    _processingProducts.clear();
    logger.i('✅ 모든 구매 상태 정리 완료');
  }

  /// 특정 상품의 진행 상태 확인 (디버그용)
  bool isProductProcessing(String productId) {
    return _processingProducts.contains(productId);
  }

  // 🧪 ============ 디버그 기능들 ============

  /// 🧪 디버그 모드 활성화 (타임아웃 시간 3초로 단축)
  void enableDebugMode() {
    inAppPurchaseService.setDebugMode(true);
    logger.w('🧪 구매 디버그 모드 활성화 - 타임아웃 3초로 단축');
  }

  /// 🧪 디버그 모드 비활성화 (타임아웃 시간 30초로 복원)
  void disableDebugMode() {
    inAppPurchaseService.setDebugMode(false);
    logger.i('🧪 구매 디버그 모드 비활성화 - 타임아웃 30초로 복원');
  }

  /// 🧪 타임아웃 모드 설정 (더 세밀한 제어)
  void setTimeoutMode(String mode) {
    inAppPurchaseService.setTimeoutMode(mode);
    logger.w('🧪 타임아웃 모드 설정: $mode');
  }

  /// 🧪 구매 지연 시뮬레이션 활성화
  void enableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(true);
    logger.w('🧪 구매 지연 시뮬레이션 활성화 - 5초 지연');
  }

  /// 🧪 구매 지연 시뮬레이션 비활성화
  void disableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(false);
    logger.i('🧪 구매 지연 시뮬레이션 비활성화');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 활성화 (실제 구매 요청 안함)
  void enableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(true);
    logger.w('🎯 강제 타임아웃 시뮬레이션 활성화 - 실제 구매 요청 없이 무조건 타임아웃');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 비활성화 (정상 구매 진행)
  void disableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(false);
    logger.i('🎯 강제 타임아웃 시뮬레이션 비활성화 - 정상 구매 진행');
  }

  /// 🧪 수동 타임아웃 트리거 (테스트용)
  void triggerManualTimeout({String? productId}) {
    logger.w('🧪 수동 타임아웃 트리거 요청: ${productId ?? "현재 구매 중인 상품"}');
    inAppPurchaseService.triggerManualTimeout(productId: productId);
  }

  /// 🧪 현재 디버그 상태와 진행 중인 구매 상태 출력
  void printDebugStatus() {
    logger.i(
        '🧪 === 구매 디버그 상태 ===\n🧪 디버그 모드: ${inAppPurchaseService.debugMode ? "활성화" : "비활성화"}\n🧪 타임아웃 모드: ${inAppPurchaseService.debugTimeoutMode}\n🧪 구매 지연: ${inAppPurchaseService.simulateSlowPurchase ? "활성화" : "비활성화"}\n🎯 강제 타임아웃: ${inAppPurchaseService.forceTimeoutSimulation ? "활성화" : "비활성화"}\n🧪 진행 중인 구매: ${_processingProducts.length}개${_processingProducts.isNotEmpty ? '\n${_processingProducts.map((productId) => '🧪   → $productId').join('\n')}' : ''}\n🧪 ========================');
  }
}
