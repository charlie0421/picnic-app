import 'package:supabase_flutter/supabase_flutter.dart';

class PicnicAuthExceptions {
  static PicnicAuthException invalidToken() =>
      PicnicAuthException('invalid_token', '유효하지 않은 토큰입니다.');

  static PicnicAuthException canceled() =>
      PicnicAuthException('canceled', '인증이 취소되었습니다.');

  static PicnicAuthException network() =>
      PicnicAuthException('network_error', '네트워크 연결을 확인해주세요.');

  static PicnicAuthException storageError() =>
      PicnicAuthException('storage_error', '저장소 접근 중 오류가 발생했습니다.');

  static PicnicAuthException unsupportedProvider(String provider) =>
      PicnicAuthException(
          'unsupported_provider', '지원하지 않는 로그인 방식입니다: $provider');

  static PicnicAuthException unknown({dynamic originalError}) =>
      PicnicAuthException('unknown', '알 수 없는 오류가 발생했습니다.',
          originalError: originalError);

  static AuthException deviceBanned() => const AuthException(
        'This device has been banned.',
        statusCode: 'DEVICE_BANNED',
      );
}

class PicnicAuthException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  PicnicAuthException(this.code, this.message, {this.originalError});

  @override
  String toString() => 'PicnicAuthException: $message (code: $code)';
}
