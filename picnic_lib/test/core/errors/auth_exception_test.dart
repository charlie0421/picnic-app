import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';

void main() {
  group('PicnicAuthException 테스트', () {
    test('PicnicAuthException은 Exception을 구현해야 한다', () {
      final exception = PicnicAuthException('test', '테스트 메시지');
      expect(exception, isA<Exception>());
    });

    test('생성자가 code와 message를 올바르게 할당해야 한다', () {
      final exception = PicnicAuthException('test_code', '테스트 메시지');

      expect(exception.code, equals('test_code'));
      expect(exception.message, equals('테스트 메시지'));
      expect(exception.originalError, isNull);
    });

    test('originalError가 올바르게 보존되어야 한다', () {
      final originalError = FormatException('원본 에러');
      final exception = PicnicAuthException(
        'test_code',
        '테스트 메시지',
        originalError: originalError,
      );

      expect(exception.originalError, equals(originalError));
      expect(exception.originalError, isA<FormatException>());
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      final exception = PicnicAuthException('test_code', '테스트 메시지');

      expect(
        exception.toString(),
        equals('PicnicAuthException: 테스트 메시지 (code: test_code)'),
      );
    });
  });

  group('PicnicAuthExceptions 팩토리 메서드 테스트', () {
    test('invalidToken이 올바른 code와 message를 생성해야 한다', () {
      final exception = PicnicAuthExceptions.invalidToken();

      expect(exception.code, equals('invalid_token'));
      expect(exception.message, equals('유효하지 않은 토큰입니다.'));
    });

    test('canceled가 올바른 code와 message를 생성해야 한다', () {
      final exception = PicnicAuthExceptions.canceled();

      expect(exception.code, equals('canceled'));
      expect(exception.message, equals('인증이 취소되었습니다.'));
    });

    test('network가 올바른 code와 message를 생성해야 한다', () {
      final exception = PicnicAuthExceptions.network();

      expect(exception.code, equals('network_error'));
      expect(exception.message, equals('네트워크 연결을 확인해주세요.'));
    });

    test('storageError가 올바른 code와 message를 생성해야 한다', () {
      final exception = PicnicAuthExceptions.storageError();

      expect(exception.code, equals('storage_error'));
      expect(exception.message, equals('저장소 접근 중 오류가 발생했습니다.'));
    });

    test('unsupportedProvider가 provider 이름을 메시지에 포함해야 한다', () {
      final exception = PicnicAuthExceptions.unsupportedProvider('facebook');

      expect(exception.code, equals('unsupported_provider'));
      expect(
        exception.message,
        equals('지원하지 않는 로그인 방식입니다: facebook'),
      );
    });

    test('unsupportedProvider가 다양한 provider 이름을 처리해야 한다', () {
      final exception = PicnicAuthExceptions.unsupportedProvider('twitter');

      expect(exception.message, contains('twitter'));
    });

    test('unknown이 올바른 code와 message를 생성해야 한다', () {
      final exception = PicnicAuthExceptions.unknown();

      expect(exception.code, equals('unknown'));
      expect(exception.message, equals('알 수 없는 오류가 발생했습니다.'));
      expect(exception.originalError, isNull);
    });

    test('unknown이 originalError를 보존해야 한다', () {
      final originalError = StateError('원본 에러');
      final exception =
          PicnicAuthExceptions.unknown(originalError: originalError);

      expect(exception.code, equals('unknown'));
      expect(exception.originalError, equals(originalError));
    });

    test('모든 팩토리 메서드가 PicnicAuthException 인스턴스를 반환해야 한다', () {
      expect(PicnicAuthExceptions.invalidToken(), isA<PicnicAuthException>());
      expect(PicnicAuthExceptions.canceled(), isA<PicnicAuthException>());
      expect(PicnicAuthExceptions.network(), isA<PicnicAuthException>());
      expect(PicnicAuthExceptions.storageError(), isA<PicnicAuthException>());
      expect(
        PicnicAuthExceptions.unsupportedProvider('test'),
        isA<PicnicAuthException>(),
      );
      expect(PicnicAuthExceptions.unknown(), isA<PicnicAuthException>());
    });

    test('모든 팩토리 메서드의 결과가 Exception으로 캐치 가능해야 한다', () {
      expect(PicnicAuthExceptions.invalidToken(), isA<Exception>());
      expect(PicnicAuthExceptions.canceled(), isA<Exception>());
      expect(PicnicAuthExceptions.network(), isA<Exception>());
      expect(PicnicAuthExceptions.storageError(), isA<Exception>());
      expect(
        PicnicAuthExceptions.unsupportedProvider('test'),
        isA<Exception>(),
      );
      expect(PicnicAuthExceptions.unknown(), isA<Exception>());
    });

    test('deviceBanned가 AuthException을 반환해야 한다', () {
      final exception = PicnicAuthExceptions.deviceBanned();

      expect(exception.message, equals('This device has been banned.'));
      expect(exception.statusCode, equals('DEVICE_BANNED'));
    });
  });
}
