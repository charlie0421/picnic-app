import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/services/error_handling_service.dart';

/// Additional tests targeting uncovered lines in error_handling_service.dart.
///
/// Targets:
/// - handleVoteItemRequestError: catch handler itself throwing (lines 155-162)
/// - logError with retryDelay set (line 324)
/// - logError with context (line 327)
/// - handleServerError context propagation
/// - TimeoutException toString variations
void main() {
  late ErrorHandlingService service;

  setUp(() {
    service = ErrorHandlingService();
  });

  group('handleVoteItemRequestError - error during handling', () {
    test('handles error thrown during error processing gracefully', () {
      // If the error handling code itself throws, the outer catch returns
      // a critical nonRetryable result (lines 154-162)
      // This is hard to trigger directly since all handler methods are safe,
      // but we can test the catch-all by passing unusual types
      final result = service.handleVoteItemRequestError(null);
      // null isn't a String, isn't a known exception type - handled by _handleUnknownError
      expect(result.errorType, ErrorType.unknown);
      expect(result.shouldRetry, isFalse);
    });

    test('handles list error type', () {
      final result = service.handleVoteItemRequestError([1, 2, 3]);
      expect(result.errorType, ErrorType.unknown);
      expect(result.technicalMessage, contains('List'));
    });

    test('handles map error type', () {
      final result = service.handleVoteItemRequestError({'key': 'value'});
      expect(result.errorType, ErrorType.unknown);
    });

    test('handles bool error type', () {
      final result = service.handleVoteItemRequestError(true);
      expect(result.errorType, ErrorType.unknown);
      expect(result.technicalMessage, contains('bool'));
    });

    test('handles double error type', () {
      final result = service.handleVoteItemRequestError(3.14);
      expect(result.errorType, ErrorType.unknown);
    });
  });

  group('handleVoteItemRequestError - string patterns', () {
    test('handles UPPERCASE NETWORK string', () {
      final result = service.handleVoteItemRequestError('NETWORK ERROR');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles UPPERCASE TIMEOUT string', () {
      final result = service.handleVoteItemRequestError('REQUEST TIMEOUT');
      expect(result.errorType, ErrorType.network);
      expect(result.shouldRetry, isTrue);
    });

    test('handles mixed case UNAUTHORIZED', () {
      final result = service.handleVoteItemRequestError('Unauthorized Access');
      expect(result.errorType, ErrorType.authentication);
      expect(result.shouldRetry, isFalse);
    });

    test('handles mixed case FORBIDDEN', () {
      final result = service.handleVoteItemRequestError('Forbidden Resource');
      expect(result.errorType, ErrorType.authentication);
    });

    test('handles CONNECTION string', () {
      final result =
          service.handleVoteItemRequestError('Connection timed out');
      expect(result.errorType, ErrorType.network);
    });
  });

  group('handleVoteItemRequestError - with context and stackTrace', () {
    test('passes context through for VoteRequestException', () {
      final ctx = {'voteId': 123, 'action': 'request'};
      final result = service.handleVoteItemRequestError(
        const VoteRequestException('test'),
        context: ctx,
        stackTrace: StackTrace.current,
      );
      expect(result.additionalData, ctx);
    });

    test('passes context through for FormatException', () {
      final ctx = {'field': 'name'};
      final result = service.handleVoteItemRequestError(
        const FormatException('bad'),
        context: ctx,
      );
      expect(result.additionalData, ctx);
    });

    test('passes context through for TimeoutException', () {
      final ctx = {'endpoint': '/api/test'};
      final result = service.handleVoteItemRequestError(
        const TimeoutException('timed out', Duration(seconds: 30)),
        context: ctx,
      );
      expect(result.additionalData, ctx);
    });

    test('passes context through for ArgumentError', () {
      final ctx = {'param': 'invalid'};
      final result = service.handleVoteItemRequestError(
        ArgumentError('bad argument'),
        context: ctx,
      );
      expect(result.additionalData, ctx);
    });

    test('passes context through for unknown error', () {
      final ctx = {'unknown': true};
      final result = service.handleVoteItemRequestError(
        42,
        context: ctx,
      );
      expect(result.additionalData, ctx);
    });
  });

  group('logError - all severity levels with context', () {
    test('logs info with retryDelay and context', () {
      final result = ErrorHandlingResult(
        userMessage: 'info msg',
        technicalMessage: 'tech info',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.info,
        shouldRetry: true,
        retryDelay: const Duration(seconds: 3),
      );
      expect(
        () => service.logError(result, 'test', context: {'key': 'val'}),
        returnsNormally,
      );
    });

    test('logs warning with context', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'warning',
        technicalMessage: 'tech',
        errorType: ErrorType.network,
      );
      expect(
        () => service.logError(result, 'err', context: {'url': '/test'}),
        returnsNormally,
      );
    });

    test('logs error with null retryDelay', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: 'error',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
      );
      // retryDelay is null, so logData['retryDelay'] is null
      expect(() => service.logError(result, 'err'), returnsNormally);
    });

    test('logs critical with additionalData', () {
      final result = ErrorHandlingResult(
        userMessage: 'critical',
        technicalMessage: 'tech',
        errorType: ErrorType.unknown,
        severity: ErrorSeverity.critical,
        additionalData: {'crash_id': 'abc-123'},
      );
      expect(
        () => service.logError(result, Exception('crash')),
        returnsNormally,
      );
    });
  });

  group('handleServerError - all status codes with context', () {
    test('400 with context', () {
      final ctx = {'body': 'invalid'};
      final result = service.handleServerError(400, 'bad', context: ctx);
      expect(result.additionalData, ctx);
      expect(result.errorType, ErrorType.client);
    });

    test('401 with context', () {
      final result =
          service.handleServerError(401, 'auth', context: {'token': 'exp'});
      expect(result.errorType, ErrorType.authentication);
    });

    test('403 with context', () {
      final result = service.handleServerError(403, 'forbidden',
          context: {'role': 'user'});
      expect(result.errorType, ErrorType.authentication);
    });

    test('404 with context', () {
      final result = service.handleServerError(404, 'missing',
          context: {'id': '999'});
      expect(result.errorType, ErrorType.client);
    });

    test('409 with context', () {
      final result = service.handleServerError(409, 'conflict',
          context: {'resource': 'vote'});
      expect(result.errorType, ErrorType.business);
    });

    test('429 with context', () {
      final result = service.handleServerError(429, 'rate limited',
          context: {'ip': '1.2.3.4'});
      expect(result.shouldRetry, isTrue);
    });
  });

  group('handleNetworkError - additional cases', () {
    test('with null context', () {
      final result = service.handleNetworkError('timeout error');
      expect(result.errorType, ErrorType.network);
      expect(result.additionalData, isNull);
    });

    test('with empty context', () {
      final result =
          service.handleNetworkError('error', context: <String, dynamic>{});
      expect(result.additionalData, isEmpty);
    });
  });

  group('ErrorHandlingResult factories - edge cases', () {
    test('retryable with custom severity', () {
      final result = ErrorHandlingResult.retryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.server,
        severity: ErrorSeverity.error,
        additionalData: {'key': 'val'},
      );
      expect(result.severity, ErrorSeverity.error);
      expect(result.shouldRetry, isTrue);
      expect(result.additionalData, {'key': 'val'});
    });

    test('nonRetryable with custom severity', () {
      final result = ErrorHandlingResult.nonRetryable(
        userMessage: 'msg',
        technicalMessage: 'tech',
        errorType: ErrorType.validation,
        severity: ErrorSeverity.warning,
        additionalData: {'field': 'email'},
      );
      expect(result.severity, ErrorSeverity.warning);
      expect(result.shouldRetry, isFalse);
    });
  });

  group('TimeoutException - edge cases', () {
    test('with zero duration', () {
      const e = TimeoutException('instant', Duration.zero);
      expect(e.toString(), contains('0ms'));
    });

    test('with large duration', () {
      const e = TimeoutException('long wait', Duration(minutes: 5));
      expect(e.toString(), contains('300000ms'));
    });

    test('message getter', () {
      const e = TimeoutException('test message');
      expect(e.message, 'test message');
      expect(e.timeout, isNull);
    });
  });
}
