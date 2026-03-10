import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/services/error_handling_service.dart';

void main() {
  late ErrorHandlingService service;

  setUp(() {
    service = ErrorHandlingService();
  });

  group('ErrorHandlingResult', () {
    test('retryable 팩토리는 shouldRetry=true', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: '재시도 가능',
        technicalMessage: 'Retryable error',
        errorType: ErrorType.network,
      );
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, equals(const Duration(seconds: 3)));
      expect(result.severity, equals(ErrorSeverity.warning));
    });

    test('nonRetryable 팩토리는 shouldRetry=false', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: '재시도 불가',
        technicalMessage: 'Non-retryable error',
        errorType: ErrorType.validation,
      );
      expect(result.shouldRetry, isFalse);
      expect(result.retryDelay, isNull);
      expect(result.severity, equals(ErrorSeverity.error));
    });

    test('커스텀 retryDelay 지원', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
        retryDelay: const Duration(minutes: 1),
      );
      expect(result.retryDelay, equals(const Duration(minutes: 1)));
    });
  });

  group('handleVoteItemRequestError', () {
    test('VoteRequestException 처리', () {
      final error = VoteRequestException('투표 오류');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.business));
      expect(result.userMessage, equals('투표 오류'));
      expect(result.shouldRetry, isFalse);
    });

    test('DuplicateVoteRequestException 처리 (VoteRequestException 서브클래스)', () {
      // DuplicateVoteRequestException은 VoteRequestException의 서브클래스이므로
      // handleVoteItemRequestError에서 VoteRequestException 분기에서 먼저 처리됨
      final error = DuplicateVoteRequestException('이미 투표함');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.business));
      expect(result.userMessage, equals('이미 투표함'));
      expect(result.shouldRetry, isFalse);
    });

    test('InvalidVoteRequestStatusException 처리 (VoteRequestException 서브클래스)', () {
      final error = InvalidVoteRequestStatusException('잘못된 상태');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.business));
      expect(result.userMessage, equals('잘못된 상태'));
    });

    test('FormatException 처리', () {
      final error = const FormatException('잘못된 형식');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.validation));
      expect(result.shouldRetry, isFalse);
      expect(result.userMessage, contains('형식'));
    });

    test('TimeoutException 처리', () {
      final error = TimeoutException('타임아웃');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.network));
      expect(result.shouldRetry, isTrue);
    });

    test('ArgumentError 처리', () {
      final error = ArgumentError('잘못된 인자');
      final result = service.handleVoteItemRequestError(error);

      expect(result.errorType, equals(ErrorType.validation));
      expect(result.shouldRetry, isFalse);
    });

    test('String 오류 - network 키워드 감지', () {
      final result =
          service.handleVoteItemRequestError('network connection failed');

      expect(result.errorType, equals(ErrorType.network));
      expect(result.shouldRetry, isTrue);
    });

    test('String 오류 - timeout 키워드 감지', () {
      final result = service.handleVoteItemRequestError('request timeout');

      expect(result.errorType, equals(ErrorType.network));
      expect(result.shouldRetry, isTrue);
    });

    test('String 오류 - unauthorized 키워드 감지', () {
      final result = service.handleVoteItemRequestError('unauthorized access');

      expect(result.errorType, equals(ErrorType.authentication));
      expect(result.shouldRetry, isFalse);
    });

    test('String 오류 - 빈 문자열', () {
      final result = service.handleVoteItemRequestError('');

      expect(result.errorType, equals(ErrorType.unknown));
      expect(result.userMessage, equals('오류가 발생했습니다.'));
    });

    test('알 수 없는 오류 타입 처리', () {
      final result = service.handleVoteItemRequestError(42);

      expect(result.errorType, equals(ErrorType.unknown));
      expect(result.shouldRetry, isFalse);
      expect(result.technicalMessage, contains('int'));
    });
  });

  group('handleNetworkError', () {
    test('네트워크 오류는 재시도 가능', () {
      final result = service.handleNetworkError('connection refused');

      expect(result.errorType, equals(ErrorType.network));
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, equals(const Duration(seconds: 5)));
      expect(result.userMessage, contains('네트워크'));
    });

    test('context 정보 전달', () {
      final context = {'endpoint': '/api/test'};
      final result =
          service.handleNetworkError('error', context: context);

      expect(result.additionalData, equals(context));
    });
  });

  group('handleServerError', () {
    test('400 Bad Request', () {
      final result = service.handleServerError(400, 'bad request');
      expect(result.errorType, equals(ErrorType.client));
      expect(result.shouldRetry, isFalse);
    });

    test('401 Unauthorized', () {
      final result = service.handleServerError(401, 'unauthorized');
      expect(result.errorType, equals(ErrorType.authentication));
      expect(result.userMessage, contains('로그인'));
    });

    test('403 Forbidden', () {
      final result = service.handleServerError(403, 'forbidden');
      expect(result.errorType, equals(ErrorType.authentication));
      expect(result.userMessage, contains('권한'));
    });

    test('404 Not Found', () {
      final result = service.handleServerError(404, 'not found');
      expect(result.errorType, equals(ErrorType.client));
      expect(result.userMessage, contains('찾을 수 없습니다'));
    });

    test('409 Conflict', () {
      final result = service.handleServerError(409, 'conflict');
      expect(result.errorType, equals(ErrorType.business));
      expect(result.severity, equals(ErrorSeverity.warning));
    });

    test('429 Too Many Requests', () {
      final result = service.handleServerError(429, 'rate limited');
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, equals(const Duration(minutes: 1)));
    });

    test('500 Internal Server Error는 재시도 가능', () {
      final result = service.handleServerError(500, 'internal error');
      expect(result.errorType, equals(ErrorType.server));
      expect(result.shouldRetry, isTrue);
    });

    test('502 Bad Gateway는 재시도 가능', () {
      final result = service.handleServerError(502, 'bad gateway');
      expect(result.shouldRetry, isTrue);
    });

    test('503 Service Unavailable는 재시도 가능', () {
      final result = service.handleServerError(503, 'unavailable');
      expect(result.shouldRetry, isTrue);
    });

    test('알 수 없는 상태 코드', () {
      final result = service.handleServerError(418, "I'm a teapot");
      expect(result.errorType, equals(ErrorType.server));
      expect(result.shouldRetry, isFalse);
    });
  });

  group('generateUserFriendlyMessage', () {
    test('ErrorType별 사용자 친화적 메시지 생성', () {
      expect(
        service.generateUserFriendlyMessage(ErrorType.network, ''),
        contains('인터넷'),
      );
      expect(
        service.generateUserFriendlyMessage(ErrorType.authentication, ''),
        contains('로그인'),
      );
      expect(
        service.generateUserFriendlyMessage(ErrorType.validation, ''),
        contains('입력'),
      );
      expect(
        service.generateUserFriendlyMessage(ErrorType.server, ''),
        contains('서버'),
      );
      expect(
        service.generateUserFriendlyMessage(ErrorType.unknown, ''),
        contains('예상치 못한'),
      );
    });

    test('business 타입은 원본 메시지 반환', () {
      expect(
        service.generateUserFriendlyMessage(
            ErrorType.business, '투표가 마감되었습니다'),
        equals('투표가 마감되었습니다'),
      );
    });

    test('business 타입에 빈 메시지면 기본 메시지 반환', () {
      expect(
        service.generateUserFriendlyMessage(ErrorType.business, ''),
        contains('처리할 수 없습니다'),
      );
    });
  });

  group('logError', () {
    test('각 severity 레벨에서 예외 없이 로깅', () {
      for (final severity in ErrorSeverity.values) {
        final result = ErrorHandlingResult(
          userMessage: 'test',
          technicalMessage: 'tech',
          errorType: ErrorType.unknown,
          severity: severity,
        );

        // 예외 없이 로깅이 수행되어야 함
        expect(
          () => service.logError(result, 'test error'),
          returnsNormally,
        );
      }
    });
  });

  group('TimeoutException', () {
    test('timeout 포함 toString', () {
      final e = TimeoutException('test', const Duration(seconds: 5));
      expect(e.toString(), contains('5000ms'));
      expect(e.toString(), contains('test'));
    });

    test('timeout 없는 toString', () {
      final e = TimeoutException('test');
      expect(e.toString(), equals('TimeoutException: test'));
    });
  });
}
