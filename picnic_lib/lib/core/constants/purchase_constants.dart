import 'package:in_app_purchase/in_app_purchase.dart';

/// 구매 처리 상수
class PurchaseConstants {
  // 타임아웃 관련
  static const Duration purchaseTimeout = Duration(seconds: 30);
  static const Duration debugPurchaseTimeout =
      Duration(seconds: 3); // 🧪 디버그용 짧은 타임아웃
  static const Duration ultraFastTimeout =
      Duration(milliseconds: 500); // 🧪 초고속 타임아웃 (0.5초)
  static const Duration instantTimeout =
      Duration(milliseconds: 100); // 🧪 거의 즉시 타임아웃 (0.1초)
  static const Duration verificationTimeout =
      Duration(seconds: 60); // Production 환경 타임아웃 (서버 검증용)
  static const Duration sandboxVerificationTimeout =
      Duration(seconds: 120); // Sandbox 환경 타임아웃
  // authenticationTimeout 제거 - 단순한 동기적 체크로 변경
  static const Duration cooldownPeriod = Duration(seconds: 2);
  static const Duration initializationDelay = Duration(seconds: 2);
  static const Duration cacheRefreshDelay = Duration(seconds: 1);

  // 재시도 관련
  static const int maxRetries = 3; // Production 환경
  static const int sandboxMaxRetries = 5; // Sandbox 환경 (더 많은 재시도)
  static const int baseRetryDelay = 2; // 초

  // 에러 메시지
  static const String userNotAuthenticatedError = '사용자 인증이 필요합니다';
  static const String productNotFoundError = '구매한 상품을 찾을 수 없습니다';
  static const String receiptVerificationError = '영수증 검증에 실패했습니다';
  static const String purchaseFailedError = '구매 처리 중 오류가 발생했습니다';
  static const String purchaseCanceledError = '구매가 취소되었습니다';
  static const String duplicatePurchaseError = '이미 처리된 구매입니다';
  static const String initializingError = '초기화 중입니다. 잠시 후 다시 시도해주세요.';
  static const String purchaseInProgressError = '구매가 진행 중입니다. 잠시만 기다려주세요.';
  static const String cooldownActiveError = '잠시 후 다시 시도해주세요.';

  // 타임아웃 관련 에러 메시지
  static const String verificationTimeoutError =
      '구매 처리 시간이 초과되었습니다. 네트워크 연결을 확인하고 다시 시도해 주세요.';
  static const String authenticationTimeoutError =
      'Touch ID/Face ID 인증 시간이 초과되었습니다. 다시 시도해 주세요.';
  static const String sandboxTimeoutWarning =
      'Sandbox 환경에서 서버 응답이 지연되었지만 구매는 정상 처리되었습니다.';
  static const String timeoutGracefulHandling =
      '영수증 검증 응답이 지연되었지만 구매가 성공했을 가능성이 높아 성공으로 처리합니다.';
  static const String networkConnectionError = '네트워크 연결을 확인해주세요.';
  static const String serverResponseError = '서버에서 응답이 없습니다. 잠시 후 다시 시도해 주세요.';

  // 🛡️ 중복 방지 관련 에러 메시지
  static const String concurrentPurchaseError = '해당 제품에 대한 구매가 이미 진행 중입니다.';
  static const String timeTooSoonError = '구매 요청 간격이 너무 짧습니다. 잠시 후 다시 시도해주세요.';
  static const String recentPurchaseError =
      '최근에 동일한 구매를 완료했습니다. 잠시 후 다시 시도해주세요.';
  static const String requestIdDuplicateError = '이미 처리된 요청입니다.';
  static const String guardSystemError = '구매 보안 시스템 오류가 발생했습니다.';

  // 성공 메시지
  static const String purchaseSuccessMessage = '구매가 완료되었습니다';

  // SharedPreferences 키
  static const String testDialogShownKey = 'test_environment_dialog_shown';
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
    message: PurchaseConstants.userNotAuthenticatedError,
  );

  static const PurchaseError productNotFound = PurchaseError(
    code: 'PRODUCT_NOT_FOUND',
    message: PurchaseConstants.productNotFoundError,
  );

  static const PurchaseError receiptVerification = PurchaseError(
    code: 'RECEIPT_VERIFICATION_FAILED',
    message: PurchaseConstants.receiptVerificationError,
  );

  static const PurchaseError duplicatePurchase = PurchaseError(
    code: 'DUPLICATE_PURCHASE',
    message: PurchaseConstants.duplicatePurchaseError,
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
