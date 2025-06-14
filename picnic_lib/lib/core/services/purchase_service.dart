import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/adapters/in_app_purchase_adapter.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_lib/supabase_options.dart';

/// 구매 관련 모든 비즈니스 로직을 담당하는 서비스 (심플 버전)
class PurchaseService {
  PurchaseService({
    required this.ref,
    required this.receiptVerificationService,
    required this.analyticsService,
    InAppPurchaseAdapter? adapter,
  }) : _adapter = adapter ?? InAppPurchaseAdapterImpl() {
    _initializePurchaseStream();
  }

  final WidgetRef ref;
  final InAppPurchaseAdapter _adapter;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;

  // 구매 상태 관리
  final Set<String> _pendingPurchases = {};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // UI 콜백
  void Function(List<PurchaseDetails>)? _onPurchaseUpdate;

  /// UI 콜백 설정
  void setOnPurchaseUpdate(void Function(List<PurchaseDetails>) callback) {
    _onPurchaseUpdate = callback;
  }

  /// 구매 스트림 초기화
  void _initializePurchaseStream() {
    if (_adapter is InAppPurchaseAdapterImpl) {
      _adapter.init();
    }

    _purchaseSubscription = _adapter.purchaseStream.listen(
      _handlePurchaseStream,
      onError: (error) {
        logger.e('Purchase stream error', error: error);
      },
    );
  }

  /// 구매 스트림 처리
  void _handlePurchaseStream(List<PurchaseDetails> purchaseDetailsList) {
    logger.i('Purchase stream received: ${purchaseDetailsList.length} items');

    for (final purchase in purchaseDetailsList) {
      logger.i('Purchase: ${purchase.productID} -> ${purchase.status}');
    }

    // 모든 구매를 UI로 전달 (Flutter 공식 권장 방식)
    final filteredPurchases = <PurchaseDetails>[];

    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        filteredPurchases.add(purchase);
      }
    }

    logger.i('Sending ${filteredPurchases.length} purchases to UI');

    if (filteredPurchases.isNotEmpty && _onPurchaseUpdate != null) {
      _onPurchaseUpdate!(filteredPurchases);
    }
  }

  /// UI에서 호출하는 구매 처리 메서드
  Future<void> handlePurchase(
    PurchaseDetails purchaseDetails, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      logger.i(
          'Processing purchase: ${purchaseDetails.productID} -> ${purchaseDetails.status}');

      // pending 구매 완료 처리
      if (purchaseDetails.pendingCompletePurchase) {
        logger.i('Completing pending purchase: ${purchaseDetails.productID}');
        await _adapter.completePurchase(purchaseDetails);
        return;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          logger.i(
              'Processing successful purchase: ${purchaseDetails.productID}');
          await _handleSuccessfulPurchase(purchaseDetails, onSuccess, onError);
          break;

        case PurchaseStatus.error:
          logger.e('Purchase error: ${purchaseDetails.error}');
          await _handlePurchaseError(purchaseDetails, onError);
          _cleanupPendingPurchase(purchaseDetails.productID);
          break;

        case PurchaseStatus.canceled:
          logger.i('Purchase canceled: ${purchaseDetails.productID}');
          _cleanupPendingPurchase(purchaseDetails.productID);
          break;

        default:
          logger.w('Unhandled purchase status: ${purchaseDetails.status}');
          _cleanupPendingPurchase(purchaseDetails.productID);
      }
    } catch (e, s) {
      logger.e('Error in handlePurchase: $e', stackTrace: s);
      _cleanupPendingPurchase(purchaseDetails.productID);
      onError('구매 처리 중 오류가 발생했습니다');
    }
  }

  /// pending 구매 정리
  void _cleanupPendingPurchase(String productId) {
    _pendingPurchases.remove(productId);
    logger.i('Cleaned up pending purchase: $productId');
  }

  /// 성공한 구매 처리
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger
          .i('Starting receipt verification for: ${purchaseDetails.productID}');

      final storeProducts = await ref.read(storeProductsProvider.future);

      // 🚧 시뮬레이터에서만 영수증 검증 우회 (실제 기기에서는 정상 검증)
      // iOS 시뮬레이터에서는 실제 결제가 불가능하므로 우회
      if (kDebugMode && Platform.isIOS) {
        // 시뮬레이터 여부는 실제 결제 시도 시 오류로 판단 가능
        // 하지만 안전하게 디버그 모드에서는 우회하도록 유지
        logger.w(
            '🚧 DEBUG MODE: Skipping receipt verification for local development');

        // 구매 완료 처리
        await _adapter.completePurchase(purchaseDetails);
        logger.i('Purchase completed (DEBUG): ${purchaseDetails.productID}');

        // Analytics 로깅
        final productDetails = storeProducts.firstWhere(
          (product) => product.id == purchaseDetails.productID,
          orElse: () => throw Exception('구매한 상품을 찾을 수 없습니다'),
        );

        // Analytics 로깅 (실패해도 구매는 성공으로 처리)
        try {
          await analyticsService.logPurchaseEvent(productDetails);
        } catch (e) {
          logger.w('Analytics logging failed: $e');
        }

        // pending에서 제거
        _cleanupPendingPurchase(purchaseDetails.productID);

        // 🎉 성공 콜백 호출
        onSuccess();
        logger.i(
            'Purchase completed successfully (DEBUG): ${purchaseDetails.productID}');
        return;
      }

      // 🏭 릴리즈 모드에서는 항상 영수증 검증 수행
      // 먼저 올바른 환경 감지
      final environment = await receiptVerificationService.getEnvironment();
      logger.i('Detected environment: $environment');

      try {
        await receiptVerificationService.verifyReceipt(
          purchaseDetails.verificationData.serverVerificationData,
          purchaseDetails.productID,
          supabase.auth.currentUser!.id,
          environment, // 감지된 환경 사용
        );

        logger.i(
            'Receipt verification successful with environment: $environment');
      } catch (verificationError) {
        // 21002 오류인 경우 다른 환경으로 재시도
        if (verificationError.toString().contains('21002')) {
          logger.w('21002 error detected, trying alternative environment');
          final alternativeEnvironment =
              receiptVerificationService.getAlternativeEnvironment(environment);

          try {
            await receiptVerificationService.verifyReceipt(
                purchaseDetails.verificationData.serverVerificationData,
                purchaseDetails.productID,
                supabase.auth.currentUser!.id,
                alternativeEnvironment);
            logger.i(
                'Receipt verification successful with alternative environment: $alternativeEnvironment');
          } catch (secondError) {
            // 두 환경 모두 실패한 경우 상세한 분석
            logger.e(
                'Receipt verification failed with both environments: $secondError');

            if (secondError.toString().contains('21002')) {
              logger.w(
                  '🚨 21002 error in both environments indicates SERVER-SIDE issue:');
              logger.w('1. Server may be using wrong Apple verification URLs');
              logger.w('2. Server configuration changed recently');
              logger.w('3. Apple server communication issue');
              logger.w('4. Receipt format processing problem on server');

              // 서버 문제 진단을 위한 상세 정보
              logger.w('📋 Diagnostic info for server team:');
              logger.w(
                  '   - Receipt length: ${purchaseDetails.verificationData.serverVerificationData.length}');
              logger.w('   - Product ID: ${purchaseDetails.productID}');
              logger.w('   - Purchase ID: ${purchaseDetails.purchaseID}');
              logger.w(
                  '   - Transaction date: ${purchaseDetails.transactionDate}');

              onError('서버에서 영수증 검증 중 오류가 발생했습니다.\n개발팀에 문의해주세요. (오류코드: 21002)');
            } else {
              onError('영수증 검증에 실패했습니다. 네트워크를 확인하거나 잠시 후 다시 시도해주세요.');
            }

            // 영수증 검증 실패 시 cleanup
            _cleanupPendingPurchase(purchaseDetails.productID);
            return; // 구매 완료하지 않음
          }
        } else {
          // 21002가 아닌 다른 오류
          logger.e('Receipt verification failed: $verificationError');
          onError('영수증 검증에 실패했습니다: ${verificationError.toString()}');
          _cleanupPendingPurchase(purchaseDetails.productID);
          return; // 구매 완료하지 않음
        }
      }

      // 🎯 영수증 검증 성공 시에만 여기 도달
      logger.i(
          'Receipt verification successful - proceeding with purchase completion');

      // 구매 완료 처리
      await _adapter.completePurchase(purchaseDetails);
      logger.i('Purchase completed: ${purchaseDetails.productID}');

      // Analytics 로깅
      final productDetails = storeProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => throw Exception('구매한 상품을 찾을 수 없습니다'),
      );

      // Analytics 로깅 (실패해도 구매는 성공으로 처리)
      try {
        await analyticsService.logPurchaseEvent(productDetails);
      } catch (e) {
        logger.w('Analytics logging failed: $e');
      }

      // pending에서 제거
      _cleanupPendingPurchase(purchaseDetails.productID);

      // 🎉 모든 처리 완료 후 성공 콜백 호출
      onSuccess();
      logger.i('Purchase completed successfully: ${purchaseDetails.productID}');
    } catch (e, s) {
      logger.e('Error in successful purchase handling: $e', stackTrace: s);
      _cleanupPendingPurchase(purchaseDetails.productID);
      onError('구매 처리 중 오류가 발생했습니다');
    }
  }

  /// 구매 오류 처리
  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('Purchase error: ${error?.message}, code: ${error?.code}');

    // 취소는 오류가 아님
    if (error != null &&
        (error.code == 'payment_canceled' ||
            error.code == 'user_canceled' ||
            error.message.toLowerCase().contains('canceled') ||
            error.message.toLowerCase().contains('cancelled'))) {
      logger.i('Purchase was canceled by user: ${purchaseDetails.productID}');

      // Analytics 로깅 (실패해도 계속 진행)
      try {
        await analyticsService
            .logPurchaseCancelEvent(purchaseDetails.productID);
      } catch (e) {
        logger.w('Analytics logging failed: $e');
      }
      return; // onError 호출하지 않음 (오류 팝업 방지)
    }

    onError('구매 중 오류가 발생했습니다: ${error?.message ?? "알 수 없는 오류"}');
  }

  /// 구매 시작
  Future<bool> initiatePurchase(
    String productId, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      logger.i('Starting purchase for: $productId');

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

      // 중복 구매 방지
      if (_pendingPurchases.contains(productDetails.id)) {
        logger.w('Purchase already in progress for ${productDetails.id}');
        onError('이미 구매가 진행 중입니다. 잠시 후 다시 시도해주세요.');
        return false;
      }

      _pendingPurchases.add(productDetails.id);
      logger.i('Added to pending purchases: ${productDetails.id}');

      final result = await _adapter.buyConsumable(productDetails);

      if (!result) {
        logger.w('Purchase initiation failed for ${productDetails.id}');
        _cleanupPendingPurchase(productDetails.id);
        onError('구매를 시작할 수 없습니다. 다시 시도해주세요.');
      }

      return result;
    } catch (e, s) {
      logger.e('Error starting purchase: $e', stackTrace: s);
      _cleanupPendingPurchase(productId); // 실패 시 cleanup
      onError('구매 시작 중 오류가 발생했습니다');
      return false;
    }
  }

  /// 리소스 정리
  void dispose() {
    _purchaseSubscription?.cancel();
    _adapter.dispose();
    _pendingPurchases.clear();
  }
}
