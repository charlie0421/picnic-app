import 'package:logger/logger.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

/// 오류 유형 분류
enum ErrorType {
  /// 네트워크 관련 오류
  network,

  /// 인증/권한 관련 오류
  authentication,

  /// 데이터 유효성 검사 오류
  validation,

  /// 비즈니스 로직 오류
  business,

  /// 서버 오류
  server,

  /// 클라이언트 오류
  client,

  /// 알 수 없는 오류
  unknown,
}

/// 오류 심각도 레벨
enum ErrorSeverity {
  /// 정보성 (사용자에게 알림만)
  info,

  /// 경고 (사용자 주의 필요)
  warning,

  /// 오류 (기능 실행 실패)
  error,

  /// 치명적 오류 (앱 크래시 가능성)
  critical,
}

/// 오류 처리 결과
class ErrorHandlingResult {
  final String userMessage;
  final String technicalMessage;
  final ErrorType errorType;
  final ErrorSeverity severity;
  final bool shouldRetry;
  final Duration? retryDelay;
  final Map<String, dynamic>? additionalData;

  const ErrorHandlingResult({
    required this.userMessage,
    required this.technicalMessage,
    required this.errorType,
    required this.severity,
    this.shouldRetry = false,
    this.retryDelay,
    this.additionalData,
  });

  /// 재시도 가능한 오류 결과 생성
  static ErrorHandlingResult retryable({
    required String userMessage,
    required String technicalMessage,
    required ErrorType errorType,
    ErrorSeverity severity = ErrorSeverity.warning,
    Duration? retryDelay,
    Map<String, dynamic>? additionalData,
  }) {
    return ErrorHandlingResult(
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      errorType: errorType,
      severity: severity,
      shouldRetry: true,
      retryDelay: retryDelay ?? const Duration(seconds: 3),
      additionalData: additionalData,
    );
  }

  /// 재시도 불가능한 오류 결과 생성
  static ErrorHandlingResult nonRetryable({
    required String userMessage,
    required String technicalMessage,
    required ErrorType errorType,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? additionalData,
  }) {
    return ErrorHandlingResult(
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      errorType: errorType,
      severity: severity,
      shouldRetry: false,
      additionalData: additionalData,
    );
  }
}

/// 오류 처리 서비스
class ErrorHandlingService {
  static final Logger logger = Logger();

  /// 투표 신청 관련 오류 처리
  ///
  /// [error] 발생한 오류
  /// [stackTrace] 스택 트레이스 (선택사항)
  /// [context] 추가 컨텍스트 정보 (선택사항)
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleVoteItemRequestError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    try {
      logger.e('투표 신청 오류 처리 시작', error: error, stackTrace: stackTrace);

      // 1. 알려진 예외 타입별 처리
      if (error is VoteRequestException) {
        return _handleVoteRequestException(error, context);
      }

      if (error is DuplicateVoteRequestException) {
        return _handleDuplicateVoteRequestException(error, context);
      }

      if (error is InvalidVoteRequestStatusException) {
        return _handleInvalidVoteRequestStatusException(error, context);
      }

      // 2. 일반적인 예외 타입별 처리
      if (error is FormatException) {
        return _handleFormatException(error, context);
      }

      if (error is TimeoutException) {
        return _handleTimeoutException(error, context);
      }

      if (error is ArgumentError) {
        return _handleArgumentError(error, context);
      }

      // 3. 문자열 오류 메시지 처리
      if (error is String) {
        return _handleStringError(error, context);
      }

      // 4. 알 수 없는 오류 처리
      return _handleUnknownError(error, context);
    } catch (e) {
      logger.e('오류 처리 중 예외 발생', error: e);
      return ErrorHandlingResult.nonRetryable(
        userMessage: '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        technicalMessage: '오류 처리 중 예외 발생: $e',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.critical,
      );
    }
  }

  /// 네트워크 관련 오류 처리
  ///
  /// [error] 네트워크 오류
  /// [context] 추가 컨텍스트 정보
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleNetworkError(
    dynamic error, {
    Map<String, dynamic>? context,
  }) {
    logger.w('네트워크 오류 처리', error: error);

    // 네트워크 오류는 일반적으로 재시도 가능
    return ErrorHandlingResult.retryable(
      userMessage: '네트워크 연결에 문제가 있습니다. 인터넷 연결을 확인하고 다시 시도해주세요.',
      technicalMessage: '네트워크 오류: $error',
      errorType: ErrorType.network,
      severity: ErrorSeverity.warning,
      retryDelay: const Duration(seconds: 5),
      additionalData: context,
    );
  }

  /// 서버 오류 처리
  ///
  /// [statusCode] HTTP 상태 코드
  /// [message] 서버 오류 메시지
  /// [context] 추가 컨텍스트 정보
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleServerError(
    int statusCode,
    String message, {
    Map<String, dynamic>? context,
  }) {
    logger.w('서버 오류 처리 - 상태코드: $statusCode, 메시지: $message');

    switch (statusCode) {
      case 400:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '잘못된 요청입니다. 입력 정보를 확인해주세요.',
          technicalMessage: 'Bad Request (400): $message',
          errorType: ErrorType.client,
          severity: ErrorSeverity.error,
          additionalData: context,
        );

      case 401:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '로그인이 필요합니다. 다시 로그인해주세요.',
          technicalMessage: 'Unauthorized (401): $message',
          errorType: ErrorType.authentication,
          severity: ErrorSeverity.error,
          additionalData: context,
        );

      case 403:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '접근 권한이 없습니다.',
          technicalMessage: 'Forbidden (403): $message',
          errorType: ErrorType.authentication,
          severity: ErrorSeverity.error,
          additionalData: context,
        );

      case 404:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '요청한 정보를 찾을 수 없습니다.',
          technicalMessage: 'Not Found (404): $message',
          errorType: ErrorType.client,
          severity: ErrorSeverity.error,
          additionalData: context,
        );

      case 409:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '이미 처리된 요청입니다.',
          technicalMessage: 'Conflict (409): $message',
          errorType: ErrorType.business,
          severity: ErrorSeverity.warning,
          additionalData: context,
        );

      case 429:
        return ErrorHandlingResult.retryable(
          userMessage: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          technicalMessage: 'Too Many Requests (429): $message',
          errorType: ErrorType.server,
          severity: ErrorSeverity.warning,
          retryDelay: const Duration(minutes: 1),
          additionalData: context,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ErrorHandlingResult.retryable(
          userMessage: '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
          technicalMessage: 'Server Error ($statusCode): $message',
          errorType: ErrorType.server,
          severity: ErrorSeverity.error,
          retryDelay: const Duration(seconds: 10),
          additionalData: context,
        );

      default:
        return ErrorHandlingResult.nonRetryable(
          userMessage: '서버 오류가 발생했습니다. 관리자에게 문의해주세요.',
          technicalMessage: 'Unknown Server Error ($statusCode): $message',
          errorType: ErrorType.server,
          severity: ErrorSeverity.error,
          additionalData: context,
        );
    }
  }

  /// 사용자 친화적 오류 메시지 생성
  ///
  /// [errorType] 오류 유형
  /// [originalMessage] 원본 오류 메시지
  ///
  /// Returns: 사용자에게 표시할 친화적인 메시지
  String generateUserFriendlyMessage(
      ErrorType errorType, String originalMessage) {
    switch (errorType) {
      case ErrorType.network:
        return '인터넷 연결을 확인하고 다시 시도해주세요.';
      case ErrorType.authentication:
        return '로그인 정보를 확인하고 다시 시도해주세요.';
      case ErrorType.validation:
        return '입력 정보를 확인하고 다시 시도해주세요.';
      case ErrorType.business:
        return originalMessage.isNotEmpty ? originalMessage : '요청을 처리할 수 없습니다.';
      case ErrorType.server:
        return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case ErrorType.client:
        return '요청에 문제가 있습니다. 입력 정보를 확인해주세요.';
      case ErrorType.unknown:
        return '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 오류 로깅
  ///
  /// [result] 오류 처리 결과
  /// [originalError] 원본 오류
  /// [context] 추가 컨텍스트 정보
  void logError(
    ErrorHandlingResult result,
    dynamic originalError, {
    Map<String, dynamic>? context,
  }) {
    final logData = {
      'errorType': result.errorType.name,
      'severity': result.severity.name,
      'userMessage': result.userMessage,
      'technicalMessage': result.technicalMessage,
      'shouldRetry': result.shouldRetry,
      'retryDelay': result.retryDelay?.inSeconds,
      'originalError': originalError.toString(),
      'context': context,
    };

    switch (result.severity) {
      case ErrorSeverity.info:
        logger.i('오류 처리 완료 (정보)', error: logData);
        break;
      case ErrorSeverity.warning:
        logger.w('오류 처리 완료 (경고)', error: logData);
        break;
      case ErrorSeverity.error:
        logger.e('오류 처리 완료 (오류)', error: logData);
        break;
      case ErrorSeverity.critical:
        logger.f('오류 처리 완료 (치명적)', error: logData);
        break;
    }
  }

  /// VoteRequestException 처리
  ErrorHandlingResult _handleVoteRequestException(
    VoteRequestException error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: error.message,
      technicalMessage: 'VoteRequestException: ${error.message}',
      errorType: ErrorType.business,
      severity: ErrorSeverity.error,
      additionalData: context,
    );
  }

  /// DuplicateVoteRequestException 처리
  ErrorHandlingResult _handleDuplicateVoteRequestException(
    DuplicateVoteRequestException error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: error.message,
      technicalMessage: 'DuplicateVoteRequestException: ${error.message}',
      errorType: ErrorType.business,
      severity: ErrorSeverity.warning,
      additionalData: context,
    );
  }

  /// InvalidVoteRequestStatusException 처리
  ErrorHandlingResult _handleInvalidVoteRequestStatusException(
    InvalidVoteRequestStatusException error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: error.message,
      technicalMessage: 'InvalidVoteRequestStatusException: ${error.message}',
      errorType: ErrorType.business,
      severity: ErrorSeverity.warning,
      additionalData: context,
    );
  }

  /// FormatException 처리
  ErrorHandlingResult _handleFormatException(
    FormatException error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: '입력 형식이 올바르지 않습니다. 다시 확인해주세요.',
      technicalMessage: 'FormatException: ${error.message}',
      errorType: ErrorType.validation,
      severity: ErrorSeverity.error,
      additionalData: context,
    );
  }

  /// TimeoutException 처리
  ErrorHandlingResult _handleTimeoutException(
    TimeoutException error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.retryable(
      userMessage: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
      technicalMessage: 'TimeoutException: ${error.message}',
      errorType: ErrorType.network,
      severity: ErrorSeverity.warning,
      retryDelay: const Duration(seconds: 5),
      additionalData: context,
    );
  }

  /// ArgumentError 처리
  ErrorHandlingResult _handleArgumentError(
    ArgumentError error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: '잘못된 입력 정보입니다. 다시 확인해주세요.',
      technicalMessage: 'ArgumentError: ${error.message}',
      errorType: ErrorType.validation,
      severity: ErrorSeverity.error,
      additionalData: context,
    );
  }

  /// 문자열 오류 처리
  ErrorHandlingResult _handleStringError(
    String error,
    Map<String, dynamic>? context,
  ) {
    // 일반적인 오류 패턴 분석
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return ErrorHandlingResult.retryable(
        userMessage: '네트워크 연결에 문제가 있습니다. 다시 시도해주세요.',
        technicalMessage: 'Network Error: $error',
        errorType: ErrorType.network,
        severity: ErrorSeverity.warning,
        additionalData: context,
      );
    }

    if (lowerError.contains('timeout')) {
      return ErrorHandlingResult.retryable(
        userMessage: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
        technicalMessage: 'Timeout Error: $error',
        errorType: ErrorType.network,
        severity: ErrorSeverity.warning,
        additionalData: context,
      );
    }

    if (lowerError.contains('unauthorized') ||
        lowerError.contains('forbidden')) {
      return ErrorHandlingResult.nonRetryable(
        userMessage: '접근 권한이 없습니다. 로그인을 확인해주세요.',
        technicalMessage: 'Auth Error: $error',
        errorType: ErrorType.authentication,
        severity: ErrorSeverity.error,
        additionalData: context,
      );
    }

    // 기본 문자열 오류 처리
    return ErrorHandlingResult.nonRetryable(
      userMessage: error.isNotEmpty ? error : '오류가 발생했습니다.',
      technicalMessage: 'String Error: $error',
      errorType: ErrorType.unknown,
      severity: ErrorSeverity.error,
      additionalData: context,
    );
  }

  /// 알 수 없는 오류 처리
  ErrorHandlingResult _handleUnknownError(
    dynamic error,
    Map<String, dynamic>? context,
  ) {
    return ErrorHandlingResult.nonRetryable(
      userMessage: '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      technicalMessage: 'Unknown Error: $error (${error.runtimeType})',
      errorType: ErrorType.unknown,
      severity: ErrorSeverity.error,
      additionalData: context,
    );
  }
}

/// TimeoutException 클래스 (dart:async에서 가져오지 않는 경우를 위한 정의)
class TimeoutException implements Exception {
  final String message;
  final Duration? timeout;

  const TimeoutException(this.message, [this.timeout]);

  @override
  String toString() {
    if (timeout != null) {
      return 'TimeoutException after ${timeout!.inMilliseconds}ms: $message';
    }
    return 'TimeoutException: $message';
  }
}
