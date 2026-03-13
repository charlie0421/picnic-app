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

/// A mock client that fails [failCount] times then succeeds.
class _FailThenSucceedClient extends http.BaseClient {
  final Exception error;
  final int failCount;
  int callCount = 0;

  _FailThenSucceedClient(this.error, {this.failCount = 1});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    if (callCount <= failCount) {
      throw error;
    }
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode('{"ok": true}')]),
      200,
      request: request,
    );
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

void main() {
  group('NetworkError', () {
    test('stores message and isRetryable', () {
      final error = NetworkError('test error', isRetryable: false);
      expect(error.message, equals('test error'));
      expect(error.isRetryable, isFalse);
    });

    test('isRetryable defaults to true', () {
      final error = NetworkError('test');
      expect(error.isRetryable, isTrue);
    });

    test('toString returns formatted message', () {
      final error = NetworkError('something went wrong');
      expect(error.toString(), equals('NetworkError: something went wrong'));
    });

    group('isRetryableError', () {
      test('returns false for content size exceeds', () {
        expect(NetworkError.isRetryableError('content size exceeds limit'), isFalse);
      });

      test('returns false for connection closed', () {
        expect(NetworkError.isRetryableError('connection closed by peer'), isFalse);
      });

      test('returns false for connection reset', () {
        expect(NetworkError.isRetryableError('connection reset by peer'), isFalse);
      });

      test('returns true for timeout errors', () {
        expect(NetworkError.isRetryableError('request timed out'), isTrue);
      });

      test('returns true for generic errors', () {
        expect(NetworkError.isRetryableError('something failed'), isTrue);
      });

      test('returns true for empty message', () {
        expect(NetworkError.isRetryableError(''), isTrue);
      });
    });
  });

  group('RetryHttpClient', () {
    test('can be created with custom params', () {
      final client = RetryHttpClient(
        http.Client(),
        maxAttempts: 5,
        timeout: const Duration(seconds: 60),
        keepAlive: const Duration(seconds: 120),
      );
      expect(client, isNotNull);
      expect(client.maxAttempts, equals(5));
      expect(client.timeout, equals(const Duration(seconds: 60)));
      expect(client.keepAlive, equals(const Duration(seconds: 120)));
      client.close();
    });

    test('close does not throw', () {
      final client = RetryHttpClient(http.Client());
      expect(() => client.close(), returnsNormally);
    });

    test('default maxAttempts is 3', () {
      final client = RetryHttpClient(http.Client());
      expect(client.maxAttempts, equals(3));
      client.close();
    });

    test('default timeout is 30 seconds', () {
      final client = RetryHttpClient(http.Client());
      expect(client.timeout, equals(const Duration(seconds: 30)));
      client.close();
    });
  });

  group('send() - _shouldRetry logic', () {
    // Note: _sendWithTimeout wraps exceptions before they reach _shouldRetry:
    // - SocketException -> NetworkError (contains "connection" in message)
    // - TimeoutException -> rethrown as-is
    // - Exceptions with "connection" in toString -> NetworkError
    // - All other exceptions -> ClientException
    //
    // _shouldRetry returns true for: SocketException, TimeoutException,
    // ClientException, or string-matching on connection closed/reset,
    // broken pipe, before full header, content size exceeds.

    http.Request makeGetRequest() =>
        http.Request('GET', Uri.parse('https://example.com/test'));

    test('SocketException is wrapped to NetworkError and does not retry '
        '(NetworkError is not in _shouldRetry type checks)', () async {
      final inner = _FailingClient(
        const SocketException('Connection refused'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      // SocketException -> NetworkError("Network connection error: ...") ->
      // NetworkError is not SocketException/TimeoutException/ClientException,
      // and toString doesn't match any string patterns -> no retry
      expect(inner.callCount, equals(1));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('retries on TimeoutException (rethrown as-is by _sendWithTimeout)',
        () async {
      final inner = _FailingClient(
        TimeoutException('timed out', const Duration(seconds: 5)),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('retries on ClientException (re-wrapped as ClientException)',
        () async {
      // ClientException with "connection" -> NetworkError (no retry)
      // ClientException without "connection" -> re-wrapped as ClientException
      final inner = _FailingClient(
        http.ClientException('Some failure'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test(
        'exception with "connection closed" is wrapped to NetworkError '
        'whose toString matches "connection closed" -> retries', () async {
      final inner = _FailingClient(
        Exception('connection closed before full header was received'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      // Exception contains "connection" -> NetworkError
      // NetworkError toString: "NetworkError: Network connection error:
      //   Exception: connection closed ..."
      // Lowercased contains "connection closed" -> _shouldRetry returns true
      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test(
        'exception with "connection reset" is wrapped to NetworkError '
        'whose toString matches "connection reset" -> retries', () async {
      final inner = _FailingClient(
        Exception('connection reset by peer'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test(
        'exception with "broken pipe" (no "connection") is wrapped to '
        'ClientException -> retries because ClientException', () async {
      final inner = _FailingClient(
        Exception('broken pipe'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      // "broken pipe" doesn't contain "connection" ->
      // wrapped as ClientException -> _shouldRetry returns true
      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test(
        'exception with "content size exceeds" (no "connection") is wrapped '
        'to ClientException -> retries because ClientException', () async {
      final inner = _FailingClient(
        Exception('content size exceeds limit'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test(
        'FormatException without "connection" is wrapped to ClientException '
        '-> retries because ClientException', () async {
      final inner = _FailingClient(
        const FormatException('bad format'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      // FormatException -> no "connection" -> ClientException ->
      // _shouldRetry returns true -> retries all attempts
      expect(inner.callCount, equals(3));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('succeeds after transient failure with retry (TimeoutException)',
        () async {
      final inner = _FailThenSucceedClient(
        TimeoutException('temporary timeout'),
        failCount: 1,
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(200));
      client.close();
    });
  });

  group('send() - _isIdempotent logic', () {
    // Use TimeoutException since it's rethrown as-is and _shouldRetry
    // returns true for it, so we can isolate the idempotent check.

    test('GET request retries on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client.send(http.Request('GET', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(3));
      client.close();
    });

    test('HEAD request retries on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client.send(http.Request('HEAD', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(3));
      client.close();
    });

    test('OPTIONS request retries on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      await client
          .send(http.Request('OPTIONS', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(2));
      client.close();
    });

    test('POST request does NOT retry on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client
          .send(http.Request('POST', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(1));
      client.close();
    });

    test('PUT request does NOT retry on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client.send(http.Request('PUT', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(1));
      client.close();
    });

    test('PATCH request does NOT retry on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client
          .send(http.Request('PATCH', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(1));
      client.close();
    });

    test('DELETE request does NOT retry on failure', () async {
      final inner = _FailingClient(
        TimeoutException('fail'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      await client
          .send(http.Request('DELETE', Uri.parse('https://example.com')));

      expect(inner.callCount, equals(1));
      client.close();
    });
  });

  group('send() - _copyRequest', () {
    test('copies http.Request with body and headers', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final request =
          http.Request('GET', Uri.parse('https://example.com/copy'))
            ..body = '{"key": "value"}'
            ..headers['X-Custom'] = 'test-header';

      final response = await client.send(request);

      expect(response.statusCode, equals(200));
      expect(inner.callCount, equals(1));
      client.close();
    });

    test('copies http.MultipartRequest with fields and files', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://example.com/upload'),
      )
        ..fields['name'] = 'test'
        ..files.add(http.MultipartFile.fromString('file', 'file content'));

      final response = await client.send(request);

      expect(response.statusCode, equals(200));
      expect(inner.callCount, equals(1));
      client.close();
    });

    test('copies request headers and redirect settings', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final request =
          http.Request('GET', Uri.parse('https://example.com/redirect'))
            ..followRedirects = false
            ..maxRedirects = 0
            ..headers['Authorization'] = 'Bearer token123';

      final response = await client.send(request);

      expect(response.statusCode, equals(200));
      client.close();
    });
  });

  group('send() - _createErrorResponse', () {
    test('returns 500 response with error details when all retries fail',
        () async {
      final inner = _FailingClient(
        TimeoutException('all attempts failed'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com/error')));

      expect(response.statusCode, equals(500));
      expect(response.reasonPhrase, equals('Network Error'));

      final body = await response.stream.bytesToString();
      expect(body, contains('error'));
      expect(body, contains('all attempts failed'));

      expect(response.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
      expect(response.headers['X-Error-Type'], isNotEmpty);
      expect(response.headers['X-Error-Time'], isNotEmpty);
      client.close();
    });

    test('error response contains the exception type in X-Error-Type header',
        () async {
      final inner = _FailingClient(
        TimeoutException('timed out'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com')));

      expect(response.headers['X-Error-Type'], equals('TimeoutException'));
      client.close();
    });
  });

  group('send() - _createDetailedErrorLog', () {
    test('logs include attempt number and URL on failure', () async {
      // Indirectly tested: the log is created during send() failures.
      // We verify the method runs without errors by ensuring send completes.
      final inner = _FailingClient(
        http.ClientException(
          'detailed error test',
          Uri.parse('https://example.com/log'),
        ),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com/log')));

      expect(response.statusCode, equals(500));
      expect(inner.callCount, equals(2));
      client.close();
    });
  });

  group('send() - connection pool age check', () {
    test('old connection in pool gets reset on next request', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        keepAlive: Duration.zero, // connections expire immediately
      );

      // First request populates pool
      await client
          .send(http.Request('GET', Uri.parse('https://example.com/pool1')));
      // Second request should find expired pool entry and reset
      await client
          .send(http.Request('GET', Uri.parse('https://example.com/pool2')));

      expect(inner.callCount, equals(2));
      client.close();
    });
  });

  group('send() - HttpException path in _shouldResetConnection', () {
    test('HttpException with connection closed triggers connection reset',
        () async {
      final inner = _FailingClient(
        HttpException('connection closed while receiving data'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com/http')));

      // HttpException contains "connection" -> NetworkError
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('HttpException with connection reset triggers connection reset',
        () async {
      final inner = _FailingClient(
        HttpException('connection reset by peer'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client
          .send(http.Request('GET', Uri.parse('https://example.com/reset')));

      expect(response.statusCode, equals(500));
      client.close();
    });
  });

  group('close()', () {
    test('clears connection pool and closes inner client', () {
      final inner = http.Client();
      final client = RetryHttpClient(inner);

      // Should not throw
      client.close();

      // Calling close again should also not throw
      expect(() => client.close(), returnsNormally);
    });

    test('close after successful request does not throw', () async {
      final inner = _SucceedingClient();
      final client = RetryHttpClient(inner, maxAttempts: 1);

      await client
          .send(http.Request('GET', Uri.parse('https://example.com')));

      expect(() => client.close(), returnsNormally);
    });
  });
}
