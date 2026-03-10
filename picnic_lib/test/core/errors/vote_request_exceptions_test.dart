import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

void main() {
  group('VoteRequestException 테스트', () {
    test('message를 올바르게 저장해야 한다', () {
      const exception = VoteRequestException('투표 요청 오류');

      expect(exception.message, equals('투표 요청 오류'));
    });

    test('Exception을 구현해야 한다', () {
      const exception = VoteRequestException('테스트');

      expect(exception, isA<Exception>());
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      const exception = VoteRequestException('투표 요청 오류');

      expect(
        exception.toString(),
        equals('VoteRequestException: 투표 요청 오류'),
      );
    });

    test('try-catch에서 Exception으로 캐치 가능해야 한다', () {
      Exception? caughtException;

      try {
        throw const VoteRequestException('테스트 예외');
      } on Exception catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException, isA<VoteRequestException>());
    });
  });

  group('DuplicateVoteRequestException 테스트', () {
    test('message를 올바르게 저장해야 한다', () {
      const exception = DuplicateVoteRequestException('중복된 투표 요청');

      expect(exception.message, equals('중복된 투표 요청'));
    });

    test('VoteRequestException을 상속해야 한다', () {
      const exception = DuplicateVoteRequestException('중복');

      expect(exception, isA<VoteRequestException>());
    });

    test('Exception으로 캐치 가능해야 한다', () {
      const exception = DuplicateVoteRequestException('중복');

      expect(exception, isA<Exception>());
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      const exception = DuplicateVoteRequestException('중복된 투표 요청');

      expect(
        exception.toString(),
        equals('DuplicateVoteRequestException: 중복된 투표 요청'),
      );
    });

    test('VoteRequestException으로 캐치 가능해야 한다', () {
      VoteRequestException? caughtException;

      try {
        throw const DuplicateVoteRequestException('중복 테스트');
      } on VoteRequestException catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException, isA<DuplicateVoteRequestException>());
    });
  });

  group('VoteRequestNotFoundException 테스트', () {
    test('message를 올바르게 저장해야 한다', () {
      const exception = VoteRequestNotFoundException('요청을 찾을 수 없음');

      expect(exception.message, equals('요청을 찾을 수 없음'));
    });

    test('VoteRequestException을 상속해야 한다', () {
      const exception = VoteRequestNotFoundException('찾을 수 없음');

      expect(exception, isA<VoteRequestException>());
    });

    test('Exception으로 캐치 가능해야 한다', () {
      const exception = VoteRequestNotFoundException('찾을 수 없음');

      expect(exception, isA<Exception>());
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      const exception = VoteRequestNotFoundException('요청을 찾을 수 없음');

      expect(
        exception.toString(),
        equals('VoteRequestNotFoundException: 요청을 찾을 수 없음'),
      );
    });

    test('VoteRequestException으로 캐치 가능해야 한다', () {
      VoteRequestException? caughtException;

      try {
        throw const VoteRequestNotFoundException('찾기 테스트');
      } on VoteRequestException catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException, isA<VoteRequestNotFoundException>());
    });
  });

  group('InvalidVoteRequestStatusException 테스트', () {
    test('message를 올바르게 저장해야 한다', () {
      const exception = InvalidVoteRequestStatusException('잘못된 상태');

      expect(exception.message, equals('잘못된 상태'));
    });

    test('VoteRequestException을 상속해야 한다', () {
      const exception = InvalidVoteRequestStatusException('잘못된 상태');

      expect(exception, isA<VoteRequestException>());
    });

    test('Exception으로 캐치 가능해야 한다', () {
      const exception = InvalidVoteRequestStatusException('잘못된 상태');

      expect(exception, isA<Exception>());
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      const exception = InvalidVoteRequestStatusException('잘못된 상태');

      expect(
        exception.toString(),
        equals('InvalidVoteRequestStatusException: 잘못된 상태'),
      );
    });

    test('VoteRequestException으로 캐치 가능해야 한다', () {
      VoteRequestException? caughtException;

      try {
        throw const InvalidVoteRequestStatusException('상태 테스트');
      } on VoteRequestException catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException, isA<InvalidVoteRequestStatusException>());
    });
  });

  group('예외 계층 구조 테스트', () {
    test('모든 하위 예외가 VoteRequestException으로 캐치 가능해야 한다', () {
      final exceptions = <VoteRequestException>[
        const DuplicateVoteRequestException('중복'),
        const VoteRequestNotFoundException('찾을 수 없음'),
        const InvalidVoteRequestStatusException('잘못된 상태'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<VoteRequestException>());
        expect(exception, isA<Exception>());
      }
    });

    test('각 하위 예외가 고유한 toString 형식을 가져야 한다', () {
      const message = '테스트 메시지';

      const duplicate = DuplicateVoteRequestException(message);
      const notFound = VoteRequestNotFoundException(message);
      const invalidStatus = InvalidVoteRequestStatusException(message);

      expect(duplicate.toString(), startsWith('DuplicateVoteRequestException'));
      expect(notFound.toString(), startsWith('VoteRequestNotFoundException'));
      expect(
        invalidStatus.toString(),
        startsWith('InvalidVoteRequestStatusException'),
      );

      // 모든 toString에 메시지가 포함되어야 한다
      expect(duplicate.toString(), contains(message));
      expect(notFound.toString(), contains(message));
      expect(invalidStatus.toString(), contains(message));
    });
  });
}
