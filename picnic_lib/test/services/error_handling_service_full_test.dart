import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/services/error_handling_service.dart';

void main() {
  late ErrorHandlingService service;

  setUp(() {
    service = ErrorHandlingService();
  });

  group('ErrorHandlingResult', () {
    test('retryable creates result with shouldRetry true', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.network,
      );
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 3));
      expect(result.errorType, ErrorType.network);
    });

    test('retryable uses custom retryDelay', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
        retryDelay: const Duration(seconds: 10),
      );
      expect(result.retryDelay, const Duration(seconds: 10));
    });

    test('nonRetryable creates result with shouldRetry false', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.client,
      );
      expect(result.shouldRetry, isFalse);
      expect(result.retryDelay, isNull);
      expect(result.severity, ErrorSeverity.error);
    });

    test('constructor with all fields', () {
      final result = ErrorHandlingResult(
        userMessage: 'user',
        technicalMessage: 'tech',
        errorType: ErrorType.validation,
        severity: ErrorSeverity.warning,
        shouldRetry: true,
        retryDelay: const Duration(seconds: 5),
        additionalData: {'key': 'value'},
      );
      expect(result.userMessage, 'user');
      expect(result.technicalMessage, 'tech');
      expect(result.additionalData?['key'], 'value');
    });
  });

  group('ErrorType', () {
    test('has all expected values', () {
      expect(ErrorType.values.length, 7);
      expect(ErrorType.values, contains(ErrorType.network));
      expect(ErrorType.values, contains(ErrorType.authentication));
      expect(ErrorType.values, contains(ErrorType.validation));
      expect(ErrorType.values, contains(ErrorType.business));
      expect(ErrorType.values, contains(ErrorType.server));
      expect(ErrorType.values, contains(ErrorType.client));
      expect(ErrorType.values, contains(ErrorType.unknown));
    });
  });

  group('ErrorSeverity', () {
    test('has all expected values', () {
      expect(ErrorSeverity.values.length, 4);
      expect(ErrorSeverity.values, contains(ErrorSeverity.info));
      expect(ErrorSeverity.values, contains(ErrorSeverity.warning));
      expect(ErrorSeverity.values, contains(ErrorSeverity.error));
      expect(ErrorSeverity.values, contains(ErrorSeverity.critical));
    });
  });

  group('handleServerError', () {
    test('400 returns client error non-retryable', () {
      final result = service.handleServerError(400, 'bad request');
      expect(result.errorType, ErrorType.client);
      expect(result.shouldRetry, isFalse);
    });

    test('401 returns authentication error', () {
      final result = service.handleServerError(401, 'unauthorized');
      expect(result.errorType, ErrorType.authentication);
      expect(result.shouldRetry, isFalse);
    });

    test('403 returns authentication error', () {
      final result = service.handleServerError(403, 'forbidden');
      expect(result.errorType, ErrorType.authentication);
      expect(result.shouldRetry, isFalse);
    });

    test('404 returns client error', () {
      final result = service.handleServerError(404, 'not found');
      expect(result.errorType, ErrorType.client);
      expect(result.shouldRetry, isFalse);
    });

    test('409 returns business error', () {
      final result = service.handleServerError(409, 'conflict');
      expect(result.errorType, ErrorType.business);
      expect(result.severity, ErrorSeverity.warning);
    });

    test('429 returns retryable server error', () {
      final result = service.handleServerError(429, 'too many');
      expect(result.errorType, ErrorType.server);
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(minutes: 1));
    });

    test('500 returns retryable server error', () {
      final result = service.handleServerError(500, 'internal error');
      expect(result.errorType, ErrorType.server);
      expect(result.shouldRetry, isTrue);
    });

    test('502 returns retryable server error', () {
      final result = service.handleServerError(502, 'bad gateway');
      expect(result.shouldRetry, isTrue);
    });

    test('503 returns retryable server error', () {
      final result = service.handleServerError(503, 'unavailable');
      expect(result.shouldRetry, isTrue);
    });

    test('504 returns retryable server error', () {
      final result = service.handleServerError(504, 'timeout');
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 10));
    });

    test('unknown status code returns non-retryable', () {
      final result = service.handleServerError(418, 'teapot');
      expect(result.shouldRetry, isFalse);
      expect(result.errorType, ErrorType.server);
    });

    test('with context passes additionalData', () {
      final context = {'endpoint': '/api/test'};
      final result =
          service.handleServerError(500, 'err', context: context);
      expect(result.additionalData, context);
    });
  });

  group('generateUserFriendlyMessage', () {
    test('network returns connection message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.network, '');
      expect(msg, contains('인터넷'));
    });

    test('authentication returns login message', () {
      final msg =
          service.generateUserFriendlyMessage(ErrorType.authentication, '');
      expect(msg, contains('로그인'));
    });

    test('validation returns input message', () {
      final msg =
          service.generateUserFriendlyMessage(ErrorType.validation, '');
      expect(msg, contains('입력'));
    });

    test('business returns original message if non-empty', () {
      final msg =
          service.generateUserFriendlyMessage(ErrorType.business, 'custom');
      expect(msg, 'custom');
    });

    test('business returns default if empty', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.business, '');
      expect(msg, contains('처리'));
    });

    test('server returns server message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.server, '');
      expect(msg, contains('서버'));
    });

    test('client returns request message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.client, '');
      expect(msg, contains('요청'));
    });

    test('unknown returns generic message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.unknown, '');
      expect(msg, contains('예상치'));
    });
  });

  group('handleNetworkError', () {
    test('returns retryable network error', () {
      final result = service.handleNetworkError('connection refused');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 5));
    });
  });

  group('handleVoteItemRequestError', () {
    test('handles VoteRequestException', () {
      final result = service.handleVoteItemRequestError(
        const VoteRequestException('test error'),
      );
      expect(result.errorType, ErrorType.business);
      expect(result.userMessage, 'test error');
    });

    test('handles DuplicateVoteRequestException as VoteRequestException', () {
      final result = service.handleVoteItemRequestError(
        const DuplicateVoteRequestException('duplicate'),
      );
      expect(result.errorType, ErrorType.business);
      // DuplicateVoteRequestException extends VoteRequestException,
      // so it matches the VoteRequestException check first
      expect(result.severity, ErrorSeverity.error);
    });

    test('handles InvalidVoteRequestStatusException as VoteRequestException', () {
      final result = service.handleVoteItemRequestError(
        const InvalidVoteRequestStatusException('invalid status'),
      );
      expect(result.errorType, ErrorType.business);
      expect(result.severity, ErrorSeverity.error);
    });

    test('handles FormatException', () {
      final result = service.handleVoteItemRequestError(
        const FormatException('bad format'),
      );
      expect(result.errorType, ErrorType.validation);
      expect(result.shouldRetry, isFalse);
    });

    test('handles TimeoutException', () {
      final result = service.handleVoteItemRequestError(
        const TimeoutException('timed out'),
      );
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles ArgumentError', () {
      final result = service.handleVoteItemRequestError(
        ArgumentError('bad arg'),
      );
      expect(result.errorType, ErrorType.validation);
      expect(result.shouldRetry, isFalse);
    });

    test('handles String error with network keyword', () {
      final result =
          service.handleVoteItemRequestError('network connection failed');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles String error with connection keyword', () {
      final result =
          service.handleVoteItemRequestError('connection refused');
      expect(result.errorType, ErrorType.network);
    });

    test('handles String error with timeout keyword', () {
      final result = service.handleVoteItemRequestError('request timeout');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles String error with unauthorized keyword', () {
      final result = service.handleVoteItemRequestError('unauthorized access');
      expect(result.errorType, ErrorType.authentication);
      expect(result.shouldRetry, isFalse);
    });

    test('handles String error with forbidden keyword', () {
      final result = service.handleVoteItemRequestError('forbidden resource');
      expect(result.errorType, ErrorType.authentication);
    });

    test('handles generic String error', () {
      final result = service.handleVoteItemRequestError('something happened');
      expect(result.errorType, ErrorType.unknown);
      expect(result.userMessage, 'something happened');
    });

    test('handles empty String error', () {
      final result = service.handleVoteItemRequestError('');
      expect(result.userMessage, contains('오류'));
    });

    test('handles unknown error type', () {
      final result = service.handleVoteItemRequestError(42);
      expect(result.errorType, ErrorType.unknown);
      expect(result.shouldRetry, isFalse);
    });

    test('with context passes data through', () {
      final ctx = {'action': 'vote'};
      final result = service.handleVoteItemRequestError(
        'some error',
        context: ctx,
      );
      expect(result.additionalData, ctx);
    });
  });

  group('logError', () {
    test('does not throw for info severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.info,
      );
      expect(() => service.logError(result, 'test'), returnsNormally);
    });

    test('does not throw for warning severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.network,
        severity: ErrorSeverity.warning,
      );
      expect(() => service.logError(result, 'test'), returnsNormally);
    });

    test('does not throw for error severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.error,
      );
      expect(() => service.logError(result, 'test'), returnsNormally);
    });

    test('does not throw for critical severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.critical,
      );
      expect(() => service.logError(result, 'test error'), returnsNormally);
    });
  });

  group('TimeoutException', () {
    test('toString with timeout', () {
      const e = TimeoutException('test', Duration(seconds: 5));
      expect(e.toString(), contains('5000ms'));
      expect(e.toString(), contains('test'));
    });

    test('toString without timeout', () {
      const e = TimeoutException('test');
      expect(e.toString(), contains('test'));
      expect(e.toString(), isNot(contains('ms')));
    });

    test('timeout property', () {
      const e = TimeoutException('test', Duration(seconds: 10));
      expect(e.timeout, const Duration(seconds: 10));
      expect(e.message, 'test');
    });
  });

  group('VoteRequestExceptions', () {
    test('VoteRequestException toString', () {
      const e = VoteRequestException('test');
      expect(e.toString(), 'VoteRequestException: test');
      expect(e.message, 'test');
    });

    test('DuplicateVoteRequestException toString', () {
      const e = DuplicateVoteRequestException('dup');
      expect(e.toString(), 'DuplicateVoteRequestException: dup');
    });

    test('VoteRequestNotFoundException toString', () {
      const e = VoteRequestNotFoundException('not found');
      expect(e.toString(), 'VoteRequestNotFoundException: not found');
    });

    test('InvalidVoteRequestStatusException toString', () {
      const e = InvalidVoteRequestStatusException('bad status');
      expect(e.toString(), 'InvalidVoteRequestStatusException: bad status');
    });
  });
}
