/// 구매 관련 공통 상수 및 타입 정의
import 'package:in_app_purchase/in_app_purchase.dart';

/// 구매 처리 상수
class PurchaseConstants {
  // 타임아웃 관련
  static const Duration purchaseTimeout = Duration(seconds: 30);
  static const Duration verificationTimeout = Duration(seconds: 30);
  static const Duration cooldownPeriod = Duration(seconds: 2);
  static const Duration initializationDelay = Duration(seconds: 2);
  static const Duration cacheRefreshDelay = Duration(seconds: 1);

  // 재시도 관련
  static const int maxRetries = 3;
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
