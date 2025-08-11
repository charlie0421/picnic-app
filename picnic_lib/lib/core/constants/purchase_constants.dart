// No UI/i18n imports here. UI 레이어에서 arb 기반으로 처리합니다.
import 'package:in_app_purchase/in_app_purchase.dart';

/// 구매 처리 상수
class PurchaseConstants {
  // 타임아웃 관련 - Touch ID/Face ID 인증 고려 (실용적인 시간으로 설정)
  static const Duration purchaseTimeout =
      Duration(seconds: 30); // 30초 - 실용적인 시간
  static const Duration debugPurchaseTimeout =
      Duration(seconds: 3); // 🧪 디버그용 짧은 타임아웃
  static const Duration ultraFastTimeout =
      Duration(milliseconds: 500); // 🧪 초고속 타임아웃 (0.5초)
  static const Duration instantTimeout =
      Duration(milliseconds: 100); // 🧪 거의 즉시 타임아웃 (0.1초)
  static const Duration verificationTimeout =
      Duration(seconds: 30); // Production 환경 타임아웃 (서버 검증용)
  static const Duration sandboxVerificationTimeout =
      Duration(seconds: 60); // Sandbox 환경 타임아웃 (개발환경은 조금 더 여유)

  // 🔧 연타 방지 수준으로 단순화
  static const Duration authenticationGracePeriod =
      Duration(milliseconds: 300); // 연타 방지용
  static const Duration backgroundPurchaseWindow =
      Duration(milliseconds: 300); // 연타 방지용
  static const Duration purchaseBlockingPeriod =
      Duration(milliseconds: 300); // 연타 방지용

  static const Duration cooldownPeriod = Duration(milliseconds: 300); // 연타 방지용
  static const Duration initializationDelay = Duration(seconds: 2);
  static const Duration cacheRefreshDelay = Duration(seconds: 1);

  // 재시도 관련
  static const int maxRetries = 3; // Production 환경
  static const int sandboxMaxRetries = 5; // Sandbox 환경 (더 많은 재시도)
  static const int baseRetryDelay = 2; // 초

  // 에러 메시지 키 (UI에서 i18n 매핑)
  static const String userNotAuthenticatedErrorKey =
      'error_user_not_authenticated';
  static const String productNotFoundErrorKey = 'error_product_not_found';
  static const String receiptVerificationErrorKey =
      'error_receipt_verification_failed';
  static const String duplicatePurchaseErrorKey = 'error_duplicate_purchase';
  static const String initializingErrorKey = 'error_initializing';
  static const String purchaseInProgressErrorKey = 'error_purchase_in_progress';

  // 표준 에러 코드(문자열 비교 지양 → 코드 비교 사용)
  static const String errPrevTransactionPending = 'ERR_PREV_TX';
  static const String errCooldownActive = 'ERR_COOLDOWN';
  static const String errPurchaseCanceled = 'ERR_PURCHASE_CANCELED';
  static const String errInProgress = 'ERR_IN_PROGRESS';
  static const String errTimeout = 'TIMEOUT';
  static const String errAuthTimeout = 'AUTH_TIMEOUT';
  static const String errNetwork = 'NETWORK';
  static const String errServer = 'SERVER';
  static const String errConcurrent = 'ERR_CONCURRENT';
  static const String errTooSoon = 'ERR_TOO_SOON';
  static const String errRecentPurchase = 'ERR_RECENT_PURCHASE';
  static const String errRequestDuplicate = 'ERR_REQUEST_DUPLICATE';

  // localizedMessage 제거: UI에서 직접 i18n 키로 처리

  // SharedPreferences 키
  static const String testDialogShownKey = 'test_environment_dialog_shown';

  // 🛡️ 구매 상태 추적 키
  static const String lastPurchaseAttemptKey = 'last_purchase_attempt_';
  static const String authenticationStartKey = 'authentication_start_';
  static const String backgroundPurchaseKey = 'background_purchase_';
}

/// 구매 처리 결과 타입
enum PurchaseResult {
  success,
  failed,
  canceled,
  duplicate,
  timeout,
}

/// 구매 환경 타입
enum PurchaseEnvironment {
  sandbox,
  production,
  unknown,
}

/// 영수증 형식 타입
enum ReceiptFormat {
  storeKit2JWT,
  storeKit1Base64,
  googlePlay,
  unknown,
}

/// 구매 에러 타입
class PurchaseError {
  final String code;
  final String message;
  final String? details;

  const PurchaseError({
    required this.code,
    required this.message,
    this.details,
  });

  static const PurchaseError userNotAuthenticated = PurchaseError(
    code: 'USER_NOT_AUTHENTICATED',
    message: PurchaseConstants.userNotAuthenticatedErrorKey,
  );

  static const PurchaseError productNotFound = PurchaseError(
    code: 'PRODUCT_NOT_FOUND',
    message: PurchaseConstants.productNotFoundErrorKey,
  );

  static const PurchaseError receiptVerification = PurchaseError(
    code: 'RECEIPT_VERIFICATION_FAILED',
    message: PurchaseConstants.receiptVerificationErrorKey,
  );

  static const PurchaseError duplicatePurchase = PurchaseError(
    code: 'DUPLICATE_PURCHASE',
    message: PurchaseConstants.duplicatePurchaseErrorKey,
  );

  @override
  String toString() => '$code: $message${details != null ? ' ($details)' : ''}';
}

/// 구매 상태 확장
extension PurchaseStatusExtension on PurchaseStatus {
  bool get isCompleted =>
      this == PurchaseStatus.purchased || this == PurchaseStatus.restored;
  bool get isFailed =>
      this == PurchaseStatus.error || this == PurchaseStatus.canceled;
  bool get isPending => this == PurchaseStatus.pending;
}
