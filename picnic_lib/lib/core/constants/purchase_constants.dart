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

  /// 정산이 서버에서 아직 진행 중인 상품의 재구매를 막는 시간.
  ///
  /// 클라이언트 예산(30초 타임아웃 × 재시도)이 끝나도 서버 정산은 끝나지
  /// 않았을 수 있다: wallet-operation-worker의 리스는 60초이고, 실패한
  /// 오퍼레이션은 cron 재시도를 타서 수 분이 걸릴 수 있다. 그 구간에
  /// 소비형 상품의 구매 버튼을 열어 두면 사용자는 "적립이 안 됐다"고
  /// 판단해 같은 상품을 한 번 더 결제한다 — 되돌릴 수 없는 이중 과금이다.
  static const Duration settlementPendingCooldown = Duration(minutes: 5);

  /// 영수증 검증 엣지 함수 이름.
  ///
  /// 프로덕션 전환 전략 C(엔드포인트 버저닝): 레거시 `verify_receipt` 는
  /// 구버전 앱 전용으로 동결되고, cotton-candy 세대는 이 이름을 호출한다.
  /// 두 이름의 호출량 비율이 세대 전환 진행률 지표다.
  static const String receiptVerificationFunction = 'verify-receipt-v2';

  /// 스토어 이벤트의 transactionDate(스토어 서버 시계)를 구매 시작 시각
  /// (기기 시계)과 비교할 때 허용하는 오차. iOS의 transactionDate는 Apple
  /// 서버 시계라 기기 시계보다 몇 초 이를 수 있는데, 오차 허용 없이
  /// 비교하면 정상 구매 전부가 stale로 오분류되어 조용히 폐기된다.
  /// 진짜 유령 트랜잭션(이전 세션의 미완료 결제)은 통상 몇 분~며칠
  /// 전이므로 10분 창으로도 계속 걸러진다.
  static const Duration purchaseClockSkewTolerance = Duration(minutes: 10);

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

  /// 결제는 접수됐지만 서버 정산 결과를 아직 모르는 상태.
  ///
  /// 실패 코드가 아니다. 타임아웃·소켓 오류·5xx·서버가 재시도 가능하다고
  /// 표시한 응답이 여기로 모인다. UI 는 이 코드를 "실패했으니 다시
  /// 시도하세요"가 아니라 "접수됐고 처리되면 자동 적립된다"로 안내해야
  /// 한다 — 소비형 상품에서 재시도를 권하면 이중 과금이 된다.
  static const String errProcessing = 'PROCESSING';

  /// 스토어가 결제 정보 자체를 거부한 경우(IAPError `payment_invalid`).
  static const String errPaymentInvalid = 'ERR_PAYMENT_INVALID';
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

  /// iOS 재전달 멱등 캐시(`sent_receipts_idem_keys`)가 보관하는 최대 키 수.
  ///
  /// 상한이 없으면 기기 설치 수명 내내 성공한 구매마다 키가 하나씩 쌓이고,
  /// 매 검증 호출마다 전체 리스트를 읽어 Set으로 변환하는 비용도 그만큼
  /// 커진다. 오래된 키부터 잘라내도 안전한 이유는 이 캐시가 최적화용
  /// 지름길일 뿐이기 때문이다 — 캐시에 없으면 서버에 정산 여부를 다시
  /// 묻는 경로로 폴백하므로(`confirmSettlementWithServer`), 잘못 비워도
  /// 정확성이 아니라 왕복 한 번만 더 든다.
  static const int maxIdemCacheEntries = 500;

  /// 영수증 큐(`receipt_queue_v1`)가 보관하는 항목의 최대 나이.
  ///
  /// 이 기간이 지나도 정산되지 않은(200) 항목은 로컬 큐에서만 지운다 -
  /// 스토어 트랜잭션 자체는 건드리지 않으므로(finish/consume 되지 않은 채
  /// 남는다), 다음 콜드 스타트·재개 스윕([PurchaseService
  /// .sweepUnfinishedPurchases])이 스토어에서 직접 다시 찾아내 재검증한다.
  /// 이 큐는 빠른 재시도 경로일 뿐 정산의 유일한 기록이 아니므로, 잘라내도
  /// 안전하다 - 최악의 경우 다음 스윕까지 재시도가 느려질 뿐이다.
  static const Duration receiptQueueMaxAge = Duration(days: 7);

  /// 영수증 큐가 보관하는 최대 항목 수. 상한을 넘으면 가장 오래된 항목부터
  /// 잘라낸다(FIFO) - 마찬가지로 스토어 쪽 재전달·리컨사일이 회수한다.
  static const int receiptQueueMaxEntries = 200;
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
