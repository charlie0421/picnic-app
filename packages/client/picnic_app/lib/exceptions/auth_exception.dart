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
        message: '로그인 중 알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        originalError: originalError,
      );

  static PicnicAuthException canceled() => PicnicAuthException(
        code: 'canceled',
        message: '로그인이 취소되었습니다.',
      );

  static PicnicAuthException network() => PicnicAuthException(
        code: 'network_error',
        message: '네트워크 연결을 확인해주세요.',
      );

  static PicnicAuthException invalidToken() => PicnicAuthException(
        code: 'invalid_token',
        message: '인증 토큰이 유효하지 않습니다. 다시 시도해주세요.',
      );

  // Google 특화 오류
  static PicnicAuthException googlePlayServices() => PicnicAuthException(
        code: 'google_play_services_error',
        message:
            'Google Play Services 오류가 발생했습니다. Google Play Services를 업데이트하거나 기기를 재시작해주세요.',
      );

  // Kakao 특화 오류
  static PicnicAuthException kakaoNotSupported() => PicnicAuthException(
        code: 'kakao_not_supported',
        message: '카카오톡 앱으로 로그인할 수 없습니다. 카카오 계정으로 로그인을 시도합니다.',
      );

  // Apple 특화 오류
  static PicnicAuthException appleSignInFailed() => PicnicAuthException(
        code: 'apple_sign_in_failed',
        message: 'Apple 로그인에 실패했습니다. 다시 시도해주세요.',
      );

  static PicnicAuthException appleInvalidResponse() => PicnicAuthException(
        code: 'apple_invalid_response',
        message: 'Apple 서버로부터 유효하지 않은 응답을 받았습니다. 다시 시도해주세요.',
      );

  // Provider 관련 오류
  static PicnicAuthException unsupportedProvider(String provider) =>
      PicnicAuthException(
        code: 'unsupported_provider',
        message: '지원하지 않는 로그인 방식입니다: $provider',
      );
}
