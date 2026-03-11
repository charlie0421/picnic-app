import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/services/error_handling_service.dart';

void main() {
  late ErrorHandlingService service;

  setUp(() {
    service = ErrorHandlingService();
  });

  group('ErrorHandlingResult', () {
    test('retryable factory sets shouldRetry true', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'Retry please',
        technicalMessage: 'tech',
        errorType: ErrorType.network,
      );
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 3));
      expect(result.severity, ErrorSeverity.warning);
    });

    test('retryable with custom delay', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
        retryDelay: const Duration(seconds: 10),
      );
      expect(result.retryDelay, const Duration(seconds: 10));
    });

    test('nonRetryable factory', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: 'Cannot retry',
        technicalMessage: 'tech',
        errorType: ErrorType.authentication,
      );
      expect(result.shouldRetry, isFalse);
      expect(result.retryDelay, isNull);
      expect(result.severity, ErrorSeverity.error);
    });

    test('with additionalData', () {
      final result = ErrorHandlingResult(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.info,
        additionalData: {'key': 'value'},
      );
      expect(result.additionalData, {'key': 'value'});
    });
  });

  group('handleVoteItemRequestError', () {
    test('handles VoteRequestException', () {
      final result = service.handleVoteItemRequestError(
        const VoteRequestException('투표 오류'),
      );
      expect(result.errorType, ErrorType.business);
      expect(result.shouldRetry, isFalse);
      expect(result.userMessage, '투표 오류');
    });

    test('handles FormatException', () {
      final result = service.handleVoteItemRequestError(
        const FormatException('잘못된 형식'),
      );
      expect(result.errorType, ErrorType.validation);
      expect(result.shouldRetry, isFalse);
    });

    test('handles TimeoutException', () {
      final result = service.handleVoteItemRequestError(
        TimeoutException('timeout'),
      );
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles ArgumentError', () {
      final result = service.handleVoteItemRequestError(
        ArgumentError('잘못된 인자'),
      );
      expect(result.errorType, ErrorType.validation);
      expect(result.shouldRetry, isFalse);
    });

    test('handles String error with network keyword', () {
      final result = service.handleVoteItemRequestError(
        'network connection failed',
      );
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles String error with timeout keyword', () {
      final result = service.handleVoteItemRequestError(
        'Request timeout occurred',
      );
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles unknown error', () {
      final result = service.handleVoteItemRequestError(12345);
      expect(result.errorType, ErrorType.unknown);
    });

    test('with context data', () {
      final result = service.handleVoteItemRequestError(
        const VoteRequestException('test'),
        context: {'page': 'vote_detail'},
      );
      expect(result.additionalData, {'page': 'vote_detail'});
    });

    test('with stack trace', () {
      final result = service.handleVoteItemRequestError(
        const VoteRequestException('test'),
        stackTrace: StackTrace.current,
      );
      expect(result, isNotNull);
    });
  });

  group('handleNetworkError', () {
    test('returns retryable result', () {
      final result = service.handleNetworkError('connection refused');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(seconds: 5));
    });

    test('with context', () {
      final result = service.handleNetworkError(
        'timeout',
        context: {'url': 'api/endpoint'},
      );
      expect(result.additionalData, {'url': 'api/endpoint'});
    });
  });

  group('handleServerError', () {
    test('400 Bad Request', () {
      final result = service.handleServerError(400, 'Bad Request');
      expect(result.errorType, ErrorType.client);
      expect(result.shouldRetry, isFalse);
    });

    test('401 Unauthorized', () {
      final result = service.handleServerError(401, 'Unauthorized');
      expect(result.errorType, ErrorType.authentication);
      expect(result.shouldRetry, isFalse);
    });

    test('403 Forbidden', () {
      final result = service.handleServerError(403, 'Forbidden');
      expect(result.errorType, ErrorType.authentication);
    });

    test('404 Not Found', () {
      final result = service.handleServerError(404, 'Not Found');
      expect(result.errorType, ErrorType.client);
    });

    test('409 Conflict', () {
      final result = service.handleServerError(409, 'Conflict');
      expect(result.errorType, ErrorType.business);
      expect(result.severity, ErrorSeverity.warning);
    });

    test('429 Too Many Requests', () {
      final result = service.handleServerError(429, 'Rate Limited');
      expect(result.errorType, ErrorType.server);
      expect(result.shouldRetry, isTrue);
      expect(result.retryDelay, const Duration(minutes: 1));
    });

    test('500 Internal Server Error', () {
      final result = service.handleServerError(500, 'Internal Error');
      expect(result.errorType, ErrorType.server);
      expect(result.shouldRetry, isTrue);
    });

    test('502 Bad Gateway', () {
      final result = service.handleServerError(502, 'Bad Gateway');
      expect(result.shouldRetry, isTrue);
    });

    test('503 Service Unavailable', () {
      final result = service.handleServerError(503, 'Service Unavailable');
      expect(result.shouldRetry, isTrue);
    });

    test('504 Gateway Timeout', () {
      final result = service.handleServerError(504, 'Gateway Timeout');
      expect(result.shouldRetry, isTrue);
    });

    test('unknown status code', () {
      final result = service.handleServerError(418, 'Teapot');
      expect(result.errorType, ErrorType.server);
      expect(result.shouldRetry, isFalse);
    });
  });

  group('generateUserFriendlyMessage', () {
    test('network', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.network, '');
      expect(msg, contains('인터넷'));
    });

    test('authentication', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.authentication, '');
      expect(msg, contains('로그인'));
    });

    test('validation', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.validation, '');
      expect(msg, contains('입력'));
    });

    test('business with message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.business, '커스텀 메시지');
      expect(msg, '커스텀 메시지');
    });

    test('business without message', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.business, '');
      expect(msg, contains('처리'));
    });

    test('server', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.server, '');
      expect(msg, contains('서버'));
    });

    test('client', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.client, '');
      expect(msg, contains('요청'));
    });

    test('unknown', () {
      final msg = service.generateUserFriendlyMessage(ErrorType.unknown, '');
      expect(msg, contains('예상치'));
    });
  });

  group('logError', () {
    test('logs info severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'info',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.info,
      );
      expect(() => service.logError(result, 'test error'), returnsNormally);
    });

    test('logs warning severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'warning',
        technicalMessage: 'tech',
        errorType: ErrorType.network,
        severity: ErrorSeverity.warning,
      );
      expect(() => service.logError(result, 'test'), returnsNormally);
    });

    test('logs error severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'error',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
        severity: ErrorSeverity.error,
      );
      expect(() => service.logError(result, 'test'), returnsNormally);
    });

    test('logs critical severity', () {
      final result = ErrorHandlingResult(
        userMessage: 'test',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.critical,
      );
      expect(() => service.logError(result, 'test error'), returnsNormally);
    });

    test('logs with context', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
      );
      expect(
        () => service.logError(result, 'err', context: {'key': 'val'}),
        returnsNormally,
      );
    });
  });
}
