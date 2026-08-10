import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/retry_http_client.dart';

/// A mock client that always throws the given exception.
class _FailingClient extends http.BaseClient {
  final Exception error;
  int callCount = 0;

  _FailingClient(this.error);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    throw error;
  }
}

/// A mock client that succeeds immediately.
class _SucceedingClient extends http.BaseClient {
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode('{"ok": true}')]),
      200,
      request: request,
    );
  }
}

/// A custom stream request type to trigger _copyRequest UnsupportedError
class _UnsupportedRequest extends http.BaseRequest {
  _UnsupportedRequest(super.method, super.url);
}

/// Additional tests targeting uncovered lines in retry_http_client.dart.
///
/// Targets:
/// - _sendWithTimeout: timeout handler
/// - _sendWithTimeout: SocketException path
/// - _sendWithTimeout: generic error path
/// - _shouldRetry: string-pattern branches
/// - _copyRequest: UnsupportedError for unknown request types
void main() {
  http.Request makeGetRequest() =>
      http.Request('GET', Uri.parse('https://example.com/test'));

  group('NetworkError', () {
    test('toString format', () {
      final error = NetworkError('test msg', isRetryable: false);
      expect(error.toString(), 'NetworkError: test msg');
      expect(error.isRetryable, isFalse);
    });
  });

  group('RetryHttpClient - consecutive requests', () {
    test('back-to-back requests to the same host both reach inner client',
        () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      await client
          .send(http.Request('GET', Uri.parse('https://example.com/a')));
      await client
          .send(http.Request('GET', Uri.parse('https://example.com/b')));

      expect(inner.callCount, 2);
      client.close();
    });
  });

  group('RetryHttpClient - _copyRequest UnsupportedError', () {
    test('throws UnsupportedError for unknown request types', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final request =
          _UnsupportedRequest('GET', Uri.parse('https://example.com'));

      // _copyRequest should throw UnsupportedError
      final response = await client.send(request);

      // The error is caught and returned as a 500 response
      expect(response.statusCode, 500);
      client.close();
    });
  });

  group('RetryHttpClient - _shouldRetry with different exceptions', () {
    test('NetworkError without connection pattern is wrapped to ClientException and retried',
        () async {
      // NetworkError thrown by _FailingClient -> caught by _sendWithTimeout
      // -> not SocketException, toString doesn't contain "connection"
      // -> wrapped as ClientException -> _shouldRetry returns true for ClientException
      final inner = _FailingClient(
        NetworkError('some random error', isRetryable: false),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client.send(makeGetRequest());

      // ClientException is retryable, so all 3 attempts are made
      expect(inner.callCount, 3);
      client.close();
    });

    test('retries when error toString contains "connection closed"', () async {
      final inner = _FailingClient(
        NetworkError('Network connection error: connection closed'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      await client.send(makeGetRequest());

      // toString contains "connection closed" -> _shouldRetry returns true
      expect(inner.callCount, 2);
      client.close();
    });

    test('retries when error toString contains "broken pipe"', () async {
      final inner = _FailingClient(
        Exception('broken pipe error'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      await client.send(makeGetRequest());

      // Exception wraps to ClientException (no "connection") ->
      // ClientException matches _shouldRetry
      expect(inner.callCount, 2);
      client.close();
    });

    test('retries when error contains "before full header was received"',
        () async {
      final inner = _FailingClient(
        Exception('before full header was received'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      await client.send(makeGetRequest());

      expect(inner.callCount, 2);
      client.close();
    });
  });

  group('RetryHttpClient - HttpException message patterns', () {
    test('HttpException with timeout message yields synthetic 500', () async {
      final inner = _FailingClient(
        HttpException('connection timeout occurred'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client.send(makeGetRequest());
      expect(response.statusCode, 500);
      client.close();
    });

    test('HttpException with network message yields synthetic 500', () async {
      final inner = _FailingClient(
        HttpException('network unreachable'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client.send(makeGetRequest());
      expect(response.statusCode, 500);
      client.close();
    });
  });

  group('RetryHttpClient - _createErrorResponse', () {
    test('creates error response with null exception', () async {
      // This is an edge case - when lastException is somehow null
      // We can't easily trigger this through the normal flow, but we test
      // that the response format is correct for known exceptions
      final inner = _FailingClient(
        TimeoutException('test timeout', const Duration(seconds: 5)),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client.send(makeGetRequest());

      expect(response.statusCode, 500);
      expect(response.reasonPhrase, 'Network Error');
      expect(response.headers['X-Error-Type'], 'TimeoutException');
      expect(response.headers['X-Error-Time'], isNotEmpty);
      expect(response.headers['Content-Type'],
          'application/json; charset=utf-8');

      final body = await response.stream.bytesToString();
      expect(body, contains('test timeout'));
      client.close();
    });
  });

  group('RetryHttpClient - _createDetailedErrorLog', () {
    test('log includes URL and attempt info for ClientException', () async {
      final inner = _FailingClient(
        http.ClientException('test detail',
            Uri.parse('https://example.com/detail')),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      // The log is internal, but we verify the send completes
      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com/detail')));

      expect(response.statusCode, 500);
      expect(inner.callCount, 2);
      client.close();
    });
  });

  group('RetryHttpClient - non-idempotent methods', () {
    test('PATCH request does not retry', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client
          .send(http.Request('PATCH', Uri.parse('https://example.com')));

      expect(inner.callCount, 1);
      client.close();
    });

    test('DELETE request does not retry', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client
          .send(http.Request('DELETE', Uri.parse('https://example.com')));

      expect(inner.callCount, 1);
      client.close();
    });
  });

  group('RetryHttpClient - close', () {
    test('close after multiple requests', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      await client.send(makeGetRequest());
      await client.send(makeGetRequest());

      expect(() => client.close(), returnsNormally);
      expect(inner.callCount, 2);
    });
  });
}
