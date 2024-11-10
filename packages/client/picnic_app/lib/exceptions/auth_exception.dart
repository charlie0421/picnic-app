import 'package:intl/intl.dart';

class PicnicAuthException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  PicnicAuthException({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => message;
}

// 인증 관련 예외 정의
class PicnicAuthExceptions {
  // 일반적인 오류
  static PicnicAuthException unknown({dynamic originalError}) =>
      PicnicAuthException(
        code: 'unknown_error',
        message: Intl.message('exception_auth_message_common_unknown'),
        originalError: originalError,
      );

  static PicnicAuthException canceled() => PicnicAuthException(
        code: 'canceled',
        message: Intl.message('exception_auth_message_common_cancel'),
      );

  static PicnicAuthException network() => PicnicAuthException(
        code: 'network_error',
        message: Intl.message('exception_auth_message_common_network'),
      );

  static PicnicAuthException invalidToken() => PicnicAuthException(
        code: 'invalid_token',
        message: Intl.message('exception_auth_message_common_invalid_token'),
      );

  // Google 특화 오류
  static PicnicAuthException googlePlayServices() => PicnicAuthException(
        code: 'google_play_services_error',
        message:
            Intl.message('exception_auth_message_google_play_services_error'),
      );

  // Kakao 특화 오류
  static PicnicAuthException kakaoNotSupported() => PicnicAuthException(
        code: 'kakao_not_supported',
        message: Intl.message('exception_auth_message_kakao_not_supported'),
      );

  // Apple 특화 오류
  static PicnicAuthException appleSignInFailed() => PicnicAuthException(
        code: 'apple_sign_in_failed',
        message: Intl.message('exception_auth_message_apple_sign_in_failed'),
      );

  static PicnicAuthException appleInvalidResponse() => PicnicAuthException(
        code: 'apple_invalid_response',
        message: Intl.message('exception_auth_message_apple_invalid_response'),
      );

  // Provider 관련 오류
  static PicnicAuthException unsupportedProvider(String provider) =>
      PicnicAuthException(
        code: 'unsupported_provider',
        message:
            '${Intl.message('exception_auth_message_common_unsupported_provider')} $provider',
      );
}
