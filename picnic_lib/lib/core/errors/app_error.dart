import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Base class for all application errors
@freezed
class AppError with _$AppError {
  /// Network related errors
  const factory AppError.network({
    required String message,
    String? code,
    int? statusCode,
    Map<String, dynamic>? details,
  }) = NetworkError;

  /// Authentication related errors
  const factory AppError.authentication({
    required String message,
    String? code,
    AuthErrorType? type,
    Map<String, dynamic>? details,
  }) = AuthenticationError;

  /// Database/Storage related errors
  const factory AppError.database({
    required String message,
    String? code,
    DatabaseErrorType? type,
    Map<String, dynamic>? details,
  }) = DatabaseError;

  /// Validation related errors
  const factory AppError.validation({
    required String message,
    String? code,
    String? field,
    Map<String, dynamic>? details,
  }) = ValidationError;

  /// Business logic related errors
  const factory AppError.business({
    required String message,
    String? code,
    BusinessErrorType? type,
    Map<String, dynamic>? details,
  }) = BusinessError;

  /// Server related errors
  const factory AppError.server({
    required String message,
    String? code,
    int? statusCode,
    Map<String, dynamic>? details,
  }) = ServerError;

  /// Unexpected/Unknown errors
  const factory AppError.unexpected({
    required String message,
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) = UnexpectedError;

  /// Permission related errors
  const factory AppError.permission({
    required String message,
    String? code,
    String? resource,
    String? action,
    Map<String, dynamic>? details,
  }) = PermissionError;

  /// Cache related errors
  const factory AppError.cache({
    required String message,
    String? code,
    String? cacheKey,
    Map<String, dynamic>? details,
  }) = CacheError;
}

/// Authentication error types
enum AuthErrorType {
  invalidCredentials,
  tokenExpired,
  tokenInvalid,
  userNotFound,
  accountLocked,
  twoFactorRequired,
  socialLoginFailed,
  logoutFailed,
}

/// Database error types
enum DatabaseErrorType {
  connectionFailed,
  queryFailed,
  transactionFailed,
  migrationFailed,
  constraintViolation,
  recordNotFound,
  recordAlreadyExists,
  timeoutError,
}

/// Business error types
enum BusinessErrorType {
  ruleViolation,
  insufficientFunds,
  limitExceeded,
  resourceUnavailable,
  operationNotAllowed,
  invalidState,
  prerequisiteNotMet,
  conflictDetected,
}

/// Extension for AppError to provide convenient methods
extension AppErrorX on AppError {
  /// Get user-friendly error message
  String get userMessage => when(
    network: (message, code, statusCode, details) => _getNetworkErrorMessage(statusCode),
    authentication: (message, code, type, details) => _getAuthErrorMessage(type),
    database: (message, code, type, details) => _getDatabaseErrorMessage(type),
    validation: (message, code, field, details) => _getValidationErrorMessage(field, message),
    business: (message, code, type, details) => _getBusinessErrorMessage(type, message),
    server: (message, code, statusCode, details) => _getServerErrorMessage(statusCode),
    unexpected: (message, code, originalError, stackTrace, details) => 
        '예상치 못한 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
    permission: (message, code, resource, action, details) => 
        '해당 작업을 수행할 권한이 없습니다.',
    cache: (message, code, cacheKey, details) => 
        '데이터를 불러오는 중 오류가 발생했습니다.',
  );

  /// Get error code for logging/analytics
  String get errorCode => when(
    network: (message, code, statusCode, details) => code ?? 'NETWORK_ERROR',
    authentication: (message, code, type, details) => code ?? 'AUTH_ERROR',
    database: (message, code, type, details) => code ?? 'DATABASE_ERROR',
    validation: (message, code, field, details) => code ?? 'VALIDATION_ERROR',
    business: (message, code, type, details) => code ?? 'BUSINESS_ERROR',
    server: (message, code, statusCode, details) => code ?? 'SERVER_ERROR',
    unexpected: (message, code, originalError, stackTrace, details) => 
        code ?? 'UNEXPECTED_ERROR',
    permission: (message, code, resource, action, details) => 
        code ?? 'PERMISSION_ERROR',
    cache: (message, code, cacheKey, details) => code ?? 'CACHE_ERROR',
  );

  /// Check if error is retryable
  bool get isRetryable => when(
    network: (message, code, statusCode, details) => 
        statusCode == null || statusCode >= 500 || statusCode == 408 || statusCode == 429,
    authentication: (message, code, type, details) => 
        type == AuthErrorType.tokenExpired || type == AuthErrorType.tokenInvalid,
    database: (message, code, type, details) => 
        type == DatabaseErrorType.connectionFailed || type == DatabaseErrorType.timeoutError,
    validation: (message, code, field, details) => false,
    business: (message, code, type, details) => false,
    server: (message, code, statusCode, details) => 
        statusCode == null || statusCode >= 500,
    unexpected: (message, code, originalError, stackTrace, details) => true,
    permission: (message, code, resource, action, details) => false,
    cache: (message, code, cacheKey, details) => true,
  );

  /// Get severity level for logging
  ErrorSeverity get severity => when(
    network: (message, code, statusCode, details) => ErrorSeverity.medium,
    authentication: (message, code, type, details) => ErrorSeverity.high,
    database: (message, code, type, details) => ErrorSeverity.high,
    validation: (message, code, field, details) => ErrorSeverity.low,
    business: (message, code, type, details) => ErrorSeverity.medium,
    server: (message, code, statusCode, details) => ErrorSeverity.high,
    unexpected: (message, code, originalError, stackTrace, details) => ErrorSeverity.critical,
    permission: (message, code, resource, action, details) => ErrorSeverity.high,
    cache: (message, code, cacheKey, details) => ErrorSeverity.low,
  );

  String _getNetworkErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 데이터를 찾을 수 없습니다.';
      case 408:
        return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      case 429:
        return '너무 많은 요청을 보냈습니다. 잠시 후 다시 시도해주세요.';
      case 500:
      case 502:
      case 503:
      case 504:
        return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '네트워크 연결을 확인하고 다시 시도해주세요.';
    }
  }

  String _getAuthErrorMessage(AuthErrorType? type) {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case AuthErrorType.tokenExpired:
        return '로그인이 만료되었습니다. 다시 로그인해주세요.';
      case AuthErrorType.userNotFound:
        return '사용자를 찾을 수 없습니다.';
      case AuthErrorType.accountLocked:
        return '계정이 잠겨있습니다. 관리자에게 문의하세요.';
      case AuthErrorType.socialLoginFailed:
        return '소셜 로그인에 실패했습니다. 다시 시도해주세요.';
      default:
        return '인증 중 오류가 발생했습니다.';
    }
  }

  String _getDatabaseErrorMessage(DatabaseErrorType? type) {
    switch (type) {
      case DatabaseErrorType.connectionFailed:
        return '데이터베이스 연결에 실패했습니다.';
      case DatabaseErrorType.recordNotFound:
        return '요청한 데이터를 찾을 수 없습니다.';
      case DatabaseErrorType.recordAlreadyExists:
        return '이미 존재하는 데이터입니다.';
      case DatabaseErrorType.timeoutError:
        return '데이터베이스 응답 시간이 초과되었습니다.';
      default:
        return '데이터 처리 중 오류가 발생했습니다.';
    }
  }

  String _getValidationErrorMessage(String? field, String message) {
    if (field != null) {
      return '$field: $message';
    }
    return message;
  }

  String _getBusinessErrorMessage(BusinessErrorType? type, String message) {
    switch (type) {
      case BusinessErrorType.insufficientFunds:
        return '잔액이 부족합니다.';
      case BusinessErrorType.limitExceeded:
        return '허용된 한도를 초과했습니다.';
      case BusinessErrorType.operationNotAllowed:
        return '허용되지 않은 작업입니다.';
      case BusinessErrorType.conflictDetected:
        return '충돌이 발생했습니다. 다시 시도해주세요.';
      default:
        return message;
    }
  }

  String _getServerErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 500:
        return '서버 내부 오류가 발생했습니다.';
      case 502:
        return '서버가 일시적으로 사용할 수 없습니다.';
      case 503:
        return '서비스를 사용할 수 없습니다.';
      case 504:
        return '서버 응답 시간이 초과되었습니다.';
      default:
        return '서버 오류가 발생했습니다.';
    }
  }
}

/// Error severity levels for logging and monitoring
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Exception wrapper for AppError
class AppException implements Exception {
  final AppError error;
  final StackTrace? stackTrace;

  const AppException(this.error, [this.stackTrace]);

  @override
  String toString() => 'AppException: ${error.userMessage}';
}