import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/restore_purchase_handler.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';

/// 구매 처리 순수 로직 프로세서
///
/// UI/State 의존성 없이 구매 흐름의 비즈니스 로직을 처리합니다.
/// setState, mounted, ref 등 위젯 상태에 의존하는 코드는 포함하지 않습니다.
class PurchaseProcessor {
  PurchaseProcessor._();

  /// 초기화 중 pending 구매 강제 완료
  ///
  /// 앱 시작 시 미완료 트랜잭션을 정리합니다.
  static Future<void> forceCompletePendingPurchase({
    required PurchaseDetails purchaseDetails,
    required InAppPurchaseService inAppPurchaseService,
  }) async {
    logger.i(
      '[PurchaseProcessor] Force completing pending purchase: ${purchaseDetails.productID}',
    );

    try {
      final startTime = DateTime.now();
      await inAppPurchaseService.completePurchase(purchaseDetails);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logger.i(
        '[PurchaseProcessor] Pending purchase completed: ${duration}ms',
      );
    } catch (e) {
      logger.e(
        '[PurchaseProcessor] Failed to complete pending purchase: $e',
      );
    }
  }

  /// 에러/취소된 트랜잭션 완료 처리
  ///
  /// 에러가 발생하거나 취소된 경우에도 트랜잭션을 완료하여
  /// 반복적인 팝업을 방지합니다.
  static Future<void> completeFailedTransaction({
    required PurchaseDetails purchaseDetails,
    required InAppPurchaseService inAppPurchaseService,
  }) async {
    if (purchaseDetails.pendingCompletePurchase) {
      logger.i(
        '[PurchaseProcessor] Completing failed/canceled transaction to prevent re-delivery.',
      );
      await inAppPurchaseService.completePurchase(purchaseDetails);
    }
  }

  /// 정상 구매 완료 시 모든 타이머 완전 정리
  static void cleanupAllTimersOnSuccess({
    required String productId,
    required PurchaseSafetyManager safetyManager,
    required RestorePurchaseHandler restoreHandler,
    required PurchaseService purchaseService,
  }) {
    logger.i('[PurchaseProcessor] 모든 타이머 정리 시작: $productId');

    try {
      // 1. PurchaseSafetyManager 타이머 정리
      safetyManager.cleanupAllTimersOnSuccess();

      // 2. RestorePurchaseHandler 타이머 정리
      restoreHandler.cleanupTimersOnPurchaseSuccess();

      // 3. InAppPurchaseService 타이머 정리
      purchaseService.inAppPurchaseService.cleanupTimersOnPurchaseSuccess(
        productId,
      );

      logger.i('[PurchaseProcessor] 모든 타이머 정리 완료: $productId');
    } catch (e) {
      logger.w('[PurchaseProcessor] 타이머 정리 중 경고: $e');
      // 타이머 정리 실패해도 구매는 이미 성공했으므로 계속 진행
    }
  }

  /// 에러 코드를 기반으로 에러 처리 유형을 판별
  ///
  /// 반환값:
  /// - [PurchaseErrorAction.showPendingMessage]: 스토어 처리 중 안내
  /// - [PurchaseErrorAction.showCooldownMessage]: 쿨다운 안내
  /// - [PurchaseErrorAction.duplicateWithCooldown]: 중복 에러 + 쿨다운 적용
  /// - [PurchaseErrorAction.showMappedError]: 에러 코드에 매핑된 메시지 표시
  static PurchaseErrorAction classifyError(String error) {
    switch (error) {
      case PurchaseConstants.errPrevTransactionPending:
        return PurchaseErrorAction.showPendingMessage;
      case PurchaseConstants.errCooldownActive:
        return PurchaseErrorAction.showCooldownMessage;
      default:
        if (_isDuplicateErrorString(error)) {
          return PurchaseErrorAction.duplicateWithCooldown;
        }
        return PurchaseErrorAction.showMappedError;
    }
  }

  /// 에러 코드를 i18n 메시지 키로 매핑
  ///
  /// [error] 에러 코드 문자열
  /// 반환: i18n 키에 해당하는 에러 유형
  static PurchaseErrorType mapErrorToType(String error) {
    switch (error) {
      case PurchaseConstants.errPrevTransactionPending:
      case PurchaseConstants.errCooldownActive:
      case PurchaseConstants.errTooSoon:
      case PurchaseConstants.errRecentPurchase:
      case PurchaseConstants.errRequestDuplicate:
        return PurchaseErrorType.previousTransactionPending;
      case 'RECEIPT_VERIFICATION_FAILED':
        return PurchaseErrorType.receiptVerificationFailed;
      case 'USER_NOT_AUTHENTICATED':
        return PurchaseErrorType.userNotAuthenticated;
      case 'PRODUCT_NOT_FOUND':
        return PurchaseErrorType.productNotFound;
      case PurchaseConstants.errTimeout:
        return PurchaseErrorType.timeout;
      case PurchaseConstants.errAuthTimeout:
        return PurchaseErrorType.purchaseFailed;
      case PurchaseConstants.errNetwork:
        return PurchaseErrorType.networkError;
      case PurchaseConstants.errServer:
        return PurchaseErrorType.serverError;
      case PurchaseConstants.errPurchaseCanceled:
        return PurchaseErrorType.purchaseCancelled;
      case PurchaseConstants.errInProgress:
      case PurchaseConstants.errConcurrent:
        return PurchaseErrorType.purchaseInProgress;
      default:
        return PurchaseErrorType.purchaseFailed;
    }
  }

  static bool _isDuplicateErrorString(String error) {
    return error.contains('StoreKit 캐시 문제') ||
        error.contains('중복 영수증') ||
        error.contains('이미 처리된 구매') ||
        error.contains('Duplicate') ||
        error.toLowerCase().contains('reused');
  }
}

/// 에러 처리 액션 유형
enum PurchaseErrorAction {
  /// 스토어 처리 중 안내 + 중복 쿨다운 적용
  showPendingMessage,

  /// 쿨다운 위반 안내 (추가 쿨타임 미적용)
  showCooldownMessage,

  /// 중복 에러 + 쿨다운 적용
  duplicateWithCooldown,

  /// 에러 코드에 매핑된 다이얼로그 메시지 표시
  showMappedError,
}

/// 에러 유형 (i18n 메시지 매핑용)
enum PurchaseErrorType {
  previousTransactionPending,
  receiptVerificationFailed,
  userNotAuthenticated,
  productNotFound,
  timeout,
  purchaseFailed,
  networkError,
  serverError,
  purchaseCancelled,
  purchaseInProgress,
}
