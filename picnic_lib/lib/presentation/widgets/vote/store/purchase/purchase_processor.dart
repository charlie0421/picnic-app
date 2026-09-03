import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/restore_purchase_handler.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';

/// 구매 처리 순수 로직 프로세서
///
/// UI/State 의존성 없이 구매 흐름의 비즈니스 로직을 처리합니다.
/// setState, mounted, ref 등 위젯 상태에 의존하는 코드는 포함하지 않습니다.
class PurchaseProcessor {
  PurchaseProcessor._();

  /// Releases the UI attempt owned by an Android PENDING event.
  ///
  /// There is deliberately no `await` between reading and removing the
  /// attempt. A PURCHASED update may arrive immediately after PENDING; once
  /// this returns it sees no bindable attempt and takes the orphan settlement
  /// path instead of being discarded by the pending UI lifecycle.
  static ({bool attemptReleased, bool shouldAnnounce})
  releaseAndroidPendingSurfaceAttempt({
    required String productId,
    required PurchaseCampaignAttemptRegistry attempts,
    required PurchaseSafetyManager safetyManager,
  }) {
    final attempt = attempts[productId];
    if (attempt == null) {
      return (attemptReleased: false, shouldAnnounce: false);
    }

    final alreadyAnnounced = safetyManager.markSettlementPending(productId);
    final attemptReleased = attempts.removeIfMatches(
      productId,
      attempt.attemptId,
    );
    return (
      attemptReleased: attemptReleased,
      shouldAnnounce: attemptReleased && !alreadyAnnounced,
    );
  }

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
      logger.i('[PurchaseProcessor] Pending purchase completed: ${duration}ms');
    } catch (e) {
      logger.e('[PurchaseProcessor] Failed to complete pending purchase: $e');
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
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        purchaseDetails.status == PurchaseStatus.pending) {
      logger.w(
        '[PurchaseProcessor] Android pending transaction preserved; '
        'failure cleanup must not acknowledge it.',
      );
      return;
    }
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

    runTimerCleanupGuarded(() {
      // 1. PurchaseSafetyManager 타이머 정리
      safetyManager.cleanupAllTimersOnSuccess();

      // 2. RestorePurchaseHandler 타이머 정리
      restoreHandler.cleanupTimersOnPurchaseSuccess();

      // 3. InAppPurchaseService 타이머 정리
      purchaseService.inAppPurchaseService.cleanupTimersOnPurchaseSuccess(
        productId,
      );

      logger.i('[PurchaseProcessor] 모든 타이머 정리 완료: $productId');
    });
  }

  /// Runs a timer teardown and swallows whatever it throws.
  ///
  /// This is the guarantee `PurchaseSettlementStep` settles against. By the
  /// time timers are torn down the charge has gone through and the wallet is
  /// about to be credited, so a failing timer owner must never abort the
  /// settlement: the step takes `cleanupAllTimersOnSuccess` as a plain `void`
  /// seam and has no catch of its own, so an exception escaping here would
  /// skip the post-purchase cleanup, the wallet update and the receipt.
  ///
  /// Extracted so that guarantee is reachable from a test. [cleanupAllTimersOnSuccess]
  /// itself needs a live `PurchaseService` - StoreKit/Play init plus the
  /// receipt queue - to construct its collaborators, which is more than a
  /// try/catch is worth.
  @visibleForTesting
  static void runTimerCleanupGuarded(void Function() cleanup) {
    try {
      cleanup();
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
      case PurchaseConstants.errProcessing:
        return PurchaseErrorType.processing;
      case PurchaseConstants.errTimeout:
        return PurchaseErrorType.timeout;
      case PurchaseConstants.errAuthTimeout:
      case PurchaseConstants.errPaymentInvalid:
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

  /// 매핑 에러가 이 구매 시도를 종결시키는지.
  ///
  /// 타임아웃/네트워크/정산 진행 중 오류는 정산이 늦게 도착해 아직 성사될
  /// 수 있으므로 종결 실패로 다루지 않는다. 그 외 매핑 에러는 사용자에게
  /// 종결 실패로 안내한 것이므로, 어템프트와 함께 해당 상품의 지연 알림
  /// 타이머까지 내려야 에러 다이얼로그 뒤에 "구매 처리 지연" 팝업이 또
  /// 뜨지 않는다 (1.3.0 베타 회귀).
  static bool isTerminalMappedError(PurchaseErrorType type) =>
      type != PurchaseErrorType.processing &&
      type != PurchaseErrorType.timeout &&
      type != PurchaseErrorType.networkError;

  /// 결제는 접수됐고 정산 결과만 아직 모르는 유형인지.
  ///
  /// 이 유형은 "실패"가 아니다. 사용자에게 재시도를 권하면 소비형 상품을
  /// 한 번 더 결제하게 되고, 그 이중 과금은 되돌릴 수 없다. 대신
  /// "접수됐고 처리되면 자동 적립된다"고 알리고 해당 상품의 재구매를
  /// 쿨다운으로 막는다.
  ///
  /// [PurchaseErrorType.networkError] 는 제외한다: 이 코드는 런치 단계
  /// (아직 과금 없음)에서도 나오므로 "네트워크를 확인하세요"가 맞는
  /// 안내다. 정산 단계의 소켓/타임아웃 실패는 타입 분류에서
  /// [PurchaseErrorType.processing] 으로 들어온다.
  static bool isSettlementPending(PurchaseErrorType type) =>
      type == PurchaseErrorType.processing || type == PurchaseErrorType.timeout;

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

  /// 결제 접수 완료, 정산 결과 미확정. 실패가 아니다.
  processing,
  timeout,
  purchaseFailed,
  networkError,
  serverError,
  purchaseCancelled,
  purchaseInProgress,
}
