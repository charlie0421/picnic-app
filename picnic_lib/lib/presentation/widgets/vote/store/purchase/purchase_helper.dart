import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 구매 관련 순수 로직 헬퍼 클래스
/// UI/State 의존성 없이 테스트 가능한 메서드들을 모아놓은 클래스
class PurchaseHelper {
  /// 구매 취소 감지
  static bool isPurchaseCanceled(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.canceled) {
      return true;
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      final errorMessage = purchaseDetails.error?.message.toLowerCase() ?? '';
      final errorCode = purchaseDetails.error?.code ?? '';

      final cancelKeywords = [
        'cancel',
        'cancelled',
        'canceled',
        'user cancel',
        'abort',
        'dismiss',
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
        'declined',
        'rejected',
        'stopped',
        'interrupted',
        'terminated',
        'aborted',
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

      final cancelErrorCodes = [
        'PAYMENT_CANCELED',
        'USER_CANCELED',
        '2',
        'SKErrorPaymentCancelled',
        'BILLING_RESPONSE_USER_CANCELED',
        '-1000',
        '-1001',
        '-1002',
        '-1003',
        '-1004',
        '-1005',
        '-1006',
        '-1007',
        '-1008',
        '-1',
        '-2',
        '-3',
        '-4',
        '-5',
        '-6',
        '-7',
        '-8',
        '-9',
        '-10',
        '-11',
        '-1001',
        '2',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        'SKError2',
        'SKError1002',
        'LAError2',
        'LAError4',
        'LAError5',
        'LAError8',
        'storekit2_purchase_cancelled',
        'storekit2_user_cancelled',
        'storekit2_cancelled',
        'purchase_cancelled',
        'transaction_cancelled',
        'user_cancelled_purchase',
        'cancelled_by_user',
        'platform_cancelled',
        'platform_user_cancelled',
        'ios_purchase_cancelled',
        'ios_user_cancelled',
      ];

      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          logger.i(
            '[PurchaseHelper] Cancel keyword detected: $keyword in "$errorMessage"',
          );
          return true;
        }
      }

      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code) || errorMessage.contains(code)) {
          logger.i(
            '[PurchaseHelper] Cancel error code detected: $code (errorCode: "$errorCode", errorMessage: "$errorMessage")',
          );
          return true;
        }
      }
      logger.w(
        '''[PurchaseHelper] UNDETECTED ERROR - Please check if this should be treated as cancellation:
Error Code: "$errorCode"
Error Message: "$errorMessage"
Full Error: ${purchaseDetails.error}
''',
      );
    }

    return false;
  }

  /// 중복 에러 확인
  static bool isDuplicateError(String error) {
    return error.contains('StoreKit 캐시 문제') ||
        error.contains('중복 영수증') ||
        error.contains('이미 처리된 구매') ||
        error.contains('Duplicate') ||
        error.toLowerCase().contains('reused');
  }

  /// 초기화 중 pending 구매 강제 완료 여부 확인
  static bool shouldForceCompletePending({
    required bool isActivePurchasing,
    required bool transactionsCleared,
    required PurchaseDetails purchaseDetails,
  }) {
    return !isActivePurchasing &&
        !transactionsCleared &&
        purchaseDetails.status == PurchaseStatus.pending;
  }

  /// 초기화 중 무시할 구매 여부 확인
  static bool shouldIgnoreDuringInit({
    required bool isActivePurchasing,
    required bool transactionsCleared,
    required PurchaseDetails purchaseDetails,
  }) {
    return !isActivePurchasing &&
        !transactionsCleared &&
        (purchaseDetails.status == PurchaseStatus.restored ||
            purchaseDetails.status == PurchaseStatus.purchased);
  }

  /// 상태별 구매 개수 계산
  static Map<String, int> getStatusCounts(
    List<PurchaseDetails> purchaseDetailsList,
  ) {
    return {
      'pending': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .length,
      'restored': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.restored)
          .length,
      'purchased': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.purchased)
          .length,
      'error': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.error)
          .length,
      'canceled': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.canceled)
          .length,
    };
  }

  /// iOS 전용 활성 구매 판별 - 유연한 3단계 처리
  ///
  /// [isActivePurchasing] 현재 활성 구매 중인지
  /// [isSafetyTimeoutTriggered] 안전망 타임아웃이 발생했는지
  /// [safetyTimeoutTime] 안전망 타임아웃 시간
  /// [isActualPurchaseCheck] 실제 구매인지 확인하는 콜백
  /// [now] 현재 시간 (테스트 시 주입 가능)
  static bool shouldProcessActivePurchaseIOS({
    required PurchaseDetails purchaseDetails,
    required bool isActivePurchasing,
    required bool isSafetyTimeoutTriggered,
    required DateTime? safetyTimeoutTime,
    required bool Function(PurchaseDetails) isActualPurchaseCheck,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1단계: 현재 활성 구매인지 확인
    if (isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      logger.i('[iOS] 1단계: 현재 활성 구매 확인');
      return true;
    }

    // 2단계: 타임아웃 후 늦은 구매 성공 (iOS 특화)
    if (isSafetyTimeoutTriggered &&
        safetyTimeoutTime != null &&
        !isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      final timeSinceTimeout = currentTime.difference(safetyTimeoutTime);

      if (timeSinceTimeout.inMinutes <= 2) {
        final isActual = isActualPurchaseCheck(purchaseDetails);

        if (isActual) {
          logger.w(
            '[iOS] 2단계: 늦은 구매 성공 감지 (${timeSinceTimeout.inSeconds}초)',
          );
          return true;
        }
      }
    }

    // 3단계: iOS 안전 fallback - 정상 구매가 차단되지 않도록!
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      final isActual = isActualPurchaseCheck(purchaseDetails);

      if (isActual) {
        final statusText = purchaseDetails.status == PurchaseStatus.restored
            ? 'restored→정상 구매'
            : '정상 구매';
        logger.i('[iOS] 3단계: iOS 안전 fallback - $statusText 감지, 영수증 검증 진행');
        return true;
      }
    }

    logger.w('[iOS] iOS 차단: 활성 구매 아님');
    return false;
  }

  /// Android 전용 활성 구매 판별 - 엄격한 2단계 처리
  ///
  /// [isActivePurchasing] 현재 활성 구매 중인지
  /// [isSafetyTimeoutTriggered] 안전망 타임아웃이 발생했는지
  /// [safetyTimeoutTime] 안전망 타임아웃 시간
  /// [isActualPurchaseCheck] 실제 구매인지 확인하는 콜백
  /// [now] 현재 시간 (테스트 시 주입 가능)
  static bool shouldProcessActivePurchaseAndroid({
    required PurchaseDetails purchaseDetails,
    required bool isActivePurchasing,
    required bool isSafetyTimeoutTriggered,
    required DateTime? safetyTimeoutTime,
    required bool Function(PurchaseDetails) isActualPurchaseCheck,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1단계: 현재 활성 구매인지 확인 (엄격)
    if (isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      logger.i('[Android] 1단계: 현재 활성 구매 확인');
      return true;
    }

    // 2단계: 타임아웃 후 짧은 지연만 허용 (Android 특화)
    if (isSafetyTimeoutTriggered &&
        safetyTimeoutTime != null &&
        !isActivePurchasing &&
        purchaseDetails.status == PurchaseStatus.purchased) {
      // restored 제외
      final timeSinceTimeout = currentTime.difference(safetyTimeoutTime);

      // Android는 1분만 허용 (더 엄격)
      if (timeSinceTimeout.inMinutes <= 1) {
        final isActual = isActualPurchaseCheck(purchaseDetails);

        if (isActual) {
          logger.w(
            '[Android] 2단계: 짧은 지연 허용 (${timeSinceTimeout.inSeconds}초)',
          );
          return true;
        }
      }
    }

    // 3단계: Android는 fallback 없음 - 엄격 차단
    logger.w('[Android] Android 엄격 차단: 활성 구매 아님');
    return false;
  }
}
