import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

void main() {
  group('PicnicAuthException', () {
    test('toString', () {
      final e = PicnicAuthException('test_code', '테스트 메시지');
      expect(e.toString(), contains('test_code'));
      expect(e.toString(), contains('테스트 메시지'));
      expect(e.code, 'test_code');
      expect(e.message, '테스트 메시지');
    });

    test('with originalError', () {
      final original = Exception('original');
      final e = PicnicAuthException('code', 'msg', originalError: original);
      expect(e.originalError, original);
    });
  });

  group('PicnicAuthExceptions factory methods', () {
    test('invalidToken', () {
      final e = PicnicAuthExceptions.invalidToken();
      expect(e.code, 'invalid_token');
      expect(e, isA<PicnicAuthException>());
    });

    test('canceled', () {
      final e = PicnicAuthExceptions.canceled();
      expect(e.code, 'canceled');
    });

    test('network', () {
      final e = PicnicAuthExceptions.network();
      expect(e.code, 'network_error');
    });

    test('storageError', () {
      final e = PicnicAuthExceptions.storageError();
      expect(e.code, 'storage_error');
    });

    test('unsupportedProvider', () {
      final e = PicnicAuthExceptions.unsupportedProvider('facebook');
      expect(e.code, 'unsupported_provider');
      expect(e.message, contains('facebook'));
    });

    test('unknown', () {
      final e = PicnicAuthExceptions.unknown(originalError: 'test');
      expect(e.code, 'unknown');
      expect(e.originalError, 'test');
    });

    test('deviceBanned returns AuthException', () {
      final e = PicnicAuthExceptions.deviceBanned();
      expect(e.message, 'This device has been banned.');
      expect(e.statusCode, 'DEVICE_BANNED');
    });
  });

  group('VoteRequestException', () {
    test('toString', () {
      const e = VoteRequestException('test message');
      expect(e.toString(), 'VoteRequestException: test message');
      expect(e.message, 'test message');
    });
  });

  group('DuplicateVoteRequestException', () {
    test('toString', () {
      const e = DuplicateVoteRequestException('duplicate');
      expect(e.toString(), 'DuplicateVoteRequestException: duplicate');
      expect(e, isA<VoteRequestException>());
    });
  });

  group('VoteRequestNotFoundException', () {
    test('toString', () {
      const e = VoteRequestNotFoundException('not found');
      expect(e.toString(), 'VoteRequestNotFoundException: not found');
    });
  });

  group('InvalidVoteRequestStatusException', () {
    test('toString', () {
      const e = InvalidVoteRequestStatusException('invalid status');
      expect(e.toString(), 'InvalidVoteRequestStatusException: invalid status');
    });
  });
}
