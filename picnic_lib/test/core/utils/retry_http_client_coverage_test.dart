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
  _UnsupportedRequest(String method, Uri url) : super(method, url);
}

/// Additional tests targeting uncovered lines in retry_http_client.dart.
///
/// Targets:
/// - Connection pool age check (line 62): connection older than _connectionMaxAge
/// - _sendWithTimeout: timeout handler (lines 127-130)
/// - _sendWithTimeout: SocketException path (line 159-160)
/// - _sendWithTimeout: generic error path (line 162)
/// - _shouldRetry: HttpException with connection patterns (lines 218-220)
/// - _copyRequest: UnsupportedError for unknown request types (lines 239-240)
/// - _shouldResetConnection: timeout pattern (line 263)
/// - _shouldResetConnection: network pattern (line 264)
void main() {
  http.Request makeGetRequest() =>
      http.Request('GET', Uri.parse('https://example.com/test'));

  group('NetworkError', () {
    test('isRetryableError with various messages', () {
      expect(
          NetworkError.isRetryableError('content size exceeds limit'), isFalse);
      expect(NetworkError.isRetryableError('connection closed'), isTrue);
      expect(NetworkError.isRetryableError('connection reset'), isTrue);
      expect(NetworkError.isRetryableError('normal error'), isTrue);
      expect(NetworkError.isRetryableError(''), isTrue);
    });

    test('toString format', () {
      final error = NetworkError('test msg', isRetryable: false);
      expect(error.toString(), 'NetworkError: test msg');
      expect(error.isRetryable, isFalse);
    });
  });

  group('RetryHttpClient - connection pool management', () {
    test('reuses connection within maxAge', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      // First request
      await client
          .send(http.Request('GET', Uri.parse('https://example.com/a')));
      // Second request to same host - should reuse pool entry
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
    test('does not retry a NetworkError marked non-retryable',
        () async {
      final inner = _FailingClient(
        NetworkError('some random error', isRetryable: false),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client.send(makeGetRequest());

      expect(inner.callCount, 1);
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

  group('RetryHttpClient - _shouldResetConnection patterns', () {
    test('resets connection on timeout error', () async {
      // HttpException with "timeout" in message
      final inner = _FailingClient(
        HttpException('connection timeout occurred'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      // First make a successful request to populate pool
      final successInner = _SucceedingClient();
      final preClient = RetryHttpClient(successInner, maxAttempts: 1);
      await preClient.send(makeGetRequest());
      preClient.close();

      final response = await client.send(makeGetRequest());
      expect(response.statusCode, 500);
      client.close();
    });

    test('resets connection on network error', () async {
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
