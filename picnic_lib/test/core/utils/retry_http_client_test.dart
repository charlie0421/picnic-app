import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:supabase/src/auth_http_client.dart';

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

class _HangingBodyClient extends http.BaseClient {
  final List<StreamController<List<int>>> _controllers = [];
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    final controller = StreamController<List<int>>();
    _controllers.add(controller);
    return http.StreamedResponse(controller.stream, 200, request: request);
  }

  @override
  void close() {
    for (final controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }
}

class _HangingBodyAndCancelClient extends http.BaseClient {
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    final controller = StreamController<List<int>>(
      onCancel: () => Completer<void>().future,
    );
    return http.StreamedResponse(controller.stream, 200, request: request);
  }
}

class _ChunkThenHangClient extends http.BaseClient {
  _ChunkThenHangClient(this.contentType);

  final String contentType;
  final List<StreamController<List<int>>> _controllers = [];
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    final controller = StreamController<List<int>>();
    _controllers.add(controller);
    controller.add([1, 2, 3]);
    return http.StreamedResponse(
      controller.stream,
      200,
      headers: {'content-type': contentType},
      request: request,
    );
  }

  @override
  void close() {
    for (final controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }
}

class _FailingBodyThenSucceedClient extends http.BaseClient {
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    if (callCount == 1) {
      return http.StreamedResponse(
        Stream.error(const SocketException('body connection reset')),
        200,
        request: request,
          );
    }
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

      test('returns true for connection closed', () {
        expect(NetworkError.isRetryableError('connection closed by peer'), isTrue);
      });

      test('returns true for connection reset', () {
        expect(NetworkError.isRetryableError('connection reset by peer'), isTrue);
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
    // _shouldRetry returns true for: retryable NetworkError,
    // SocketException, TimeoutException, ClientException, or string-matching
    // on connection closed/reset, broken pipe, before full header.

    http.Request makeGetRequest() =>
        http.Request('GET', Uri.parse('https://example.com/test'));

    test('GET retries SocketException up to maxAttempts', () async {
      final inner = _FailingClient(
        const SocketException('Failed host lookup'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(3));
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
      // ClientException with "connection" -> retryable NetworkError
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

    test('does not retry when content size exceeds the declared limit',
        () async {
      final inner = _FailingClient(
        Exception('content size exceeds limit'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(1));
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

  group('unstreamed response body timeout and retry', () {
    test('GET retries when the response body never completes', () async {
      final inner = _HangingBodyClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 2,
        timeout: const Duration(milliseconds: 25),
      );

      try {
        final response = await client
            .get(Uri.parse('https://example.com/hanging-body'))
            .timeout(const Duration(seconds: 1));

        expect(response.statusCode, 500);
        expect(inner.callCount, 2);
      } finally {
        client.close();
      }
    });

    test('body timeout preserves the error when stream cancellation hangs',
        () async {
      final inner = _HangingBodyAndCancelClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        timeout: const Duration(milliseconds: 25),
      );

      final response = await client
          .get(Uri.parse('https://example.com/hanging-cancel'))
          .timeout(
            const Duration(milliseconds: 250),
            onTimeout: () => throw StateError(
              'stream cancellation hid the request timeout',
            ),
          );

      expect(response.statusCode, 500);
      expect(response.headers['X-Error-Type'], 'TimeoutException');
      expect(inner.callCount, 1);
      client.close();
    });

    test('GET retries a response body stream error and can recover', () async {
      final inner = _FailingBodyThenSucceedClient();
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.get(
        Uri.parse('https://example.com/body-error'),
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
      expect(inner.callCount, 2);
      client.close();
    });

    test('idempotent send retries when the response body never completes',
        () async {
      final inner = _HangingBodyClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 2,
        timeout: const Duration(milliseconds: 25),
      );

      final response = await client
          .send(
            http.Request(
              'GET',
              Uri.parse('https://example.com/streaming-response'),
            ),
          )
          .timeout(const Duration(seconds: 1));

      expect(response.statusCode, 500);
      expect(inner.callCount, 2);
      client.close();
    });

    test('AuthHttpClient BaseClient.get inherits the body timeout', () async {
      final inner = _HangingBodyClient();
      final retryClient = RetryHttpClient(
        inner,
        maxAttempts: 2,
        timeout: const Duration(milliseconds: 25),
      );
      final authClient = AuthHttpClient(
        'anon-key',
        retryClient,
        () async => null,
      );

      final response = await authClient
          .get(Uri.parse('https://example.com/rest/v1/banner'))
          .timeout(const Duration(seconds: 1));

      expect(response.statusCode, 500);
      expect(inner.callCount, 2);
      authClient.close();
    });

    test('non-idempotent send ends a stalled body without retrying', () async {
      final inner = _HangingBodyClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 3,
        timeout: const Duration(milliseconds: 25),
      );

      final response = await client.send(
        http.Request(
          'POST',
          Uri.parse('https://example.com/rest/v1/rpc/test'),
        ),
      );

      await expectLater(
        response.stream.drain<void>().timeout(
          const Duration(milliseconds: 250),
          onTimeout: () => throw StateError('response stream stayed pending'),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(inner.callCount, 1);
      client.close();
    });

    test('stream deadline includes time before body subscription', () async {
      final inner = _HangingBodyClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        timeout: const Duration(milliseconds: 250),
      );

      final response = await client.send(
        http.Request(
          'POST',
          Uri.parse('https://example.com/rest/v1/rpc/test'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await expectLater(
        response.stream.drain<void>().timeout(
          const Duration(milliseconds: 150),
          onTimeout: () => throw StateError(
            'deadline restarted when the body was subscribed',
          ),
        ),
        throwsA(isA<TimeoutException>()),
      );
      client.close();
    });

    test('known Supabase streaming responses return after headers', () async {
      final cases = {
        '/storage/v1/object/file': 'application/octet-stream',
        '/functions/v1/events': 'text/event-stream',
      };

      for (final entry in cases.entries) {
        final inner = _ChunkThenHangClient(entry.value);
        final client = RetryHttpClient(
          inner,
          maxAttempts: 2,
          timeout: const Duration(milliseconds: 250),
        );

        final response = await client
            .send(
              http.Request('GET', Uri.parse('https://example.com${entry.key}')),
            )
            .timeout(const Duration(milliseconds: 100));

        expect(await response.stream.first, [1, 2, 3]);
        expect(inner.callCount, 1);
        client.close();
      }
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

  group('postgrest invariant - response.request never null', () {
    // Regression guard for Sentry PICNIC-APP-T2 (279k events / 1363 users):
    // postgrest 2.6.0 / 2.7.0 do `response.request!.method` in
    // _parseResponse() on the non-2xx branch. If any layer of the http
    // stack yields a Response with `request == null`, postgrest throws
    // a `Null check operator used on a null value` TypeError that
    // bubbles up as an unhandled error and pollutes Sentry.
    //
    // RetryHttpClient.send rebuilds every StreamedResponse with the copied
    // request, so BaseClient.get/post and AuthHttpClient wrappers always
    // produce a request-bearing Response for postgrest.

    /// Inner client that simulates the buggy path: returns a
    /// StreamedResponse with `request: null` so we can verify our
    /// wrapper restores it.
    http.StreamedResponse buildResponseWithoutRequest(
      int statusCode, {
      String body = '{"err": "boom"}',
    }) {
      return http.StreamedResponse(
        Stream.fromIterable([utf8.encode(body)]),
        statusCode,
        // intentionally not setting `request:` -> simulates the wild bug
      );
    }

    test('GET response has request even if inner returns request: null',
        () async {
      final inner = _StubClient(
        (req) async => buildResponseWithoutRequest(503),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response =
          await client.get(Uri.parse('https://example.com/foo?bar=1'));

      expect(response.statusCode, equals(503));
      expect(response.request, isNotNull,
          reason: 'postgrest dereferences response.request!.method');
      expect(response.request!.method, equals('GET'));
      expect(response.request!.url.toString(),
          equals('https://example.com/foo?bar=1'));
      client.close();
    });

    test('POST response has request even if inner returns request: null',
        () async {
      final inner = _StubClient(
        (req) async => buildResponseWithoutRequest(500),
      );
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client.post(
        Uri.parse('https://example.com/insert'),
        body: '{"x": 1}',
        headers: {'Authorization': 'Bearer t'},
      );

      expect(response.statusCode, equals(500));
      expect(response.request, isNotNull);
      expect(response.request!.method, equals('POST'));
      client.close();
    });

    test('all postgrest verbs preserve request on non-2xx', () async {
      for (final method in ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE']) {
        final inner = _StubClient(
          (req) async => buildResponseWithoutRequest(503, body: ''),
        );
        final client = RetryHttpClient(inner, maxAttempts: 1);

        final url = Uri.parse('https://example.com/$method');
        late final http.Response response;
        switch (method) {
          case 'GET':
            response = await client.get(url);
            break;
          case 'HEAD':
            response = await client.head(url);
            break;
          case 'POST':
            response = await client.post(url, body: '{}');
            break;
          case 'PUT':
            response = await client.put(url, body: '{}');
            break;
          case 'PATCH':
            response = await client.patch(url, body: '{}');
            break;
          case 'DELETE':
            response = await client.delete(url);
            break;
        }

        expect(response.request, isNotNull,
            reason: '$method response must have non-null request');
        expect(response.request!.method, equals(method));
        client.close();
      }
    });

    test('inner response with valid request is passed through unchanged',
        () async {
      final inner = _StubClient((req) async {
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode('{"ok": true}')]),
          200,
          request: req, // inner sets request properly
        );
      });
      final client = RetryHttpClient(inner, maxAttempts: 1);

      final response = await client.get(Uri.parse('https://example.com/ok'));

      expect(response.statusCode, equals(200));
      expect(response.request, isNotNull);
      expect(response.request!.method, equals('GET'));
      client.close();
    });

    test('retry-exhausted error path yields request-bearing response',
        () async {
      // _createErrorResponse path: all retries fail -> 500 synthetic response
      final inner = _FailingClient(TimeoutException('always fails'));
      final client = RetryHttpClient(inner, maxAttempts: 2);

      final response = await client.get(Uri.parse('https://example.com/dead'));

      expect(response.statusCode, equals(500));
      expect(response.request, isNotNull);
      expect(response.request!.method, equals('GET'));
      client.close();
    });
  });

  group('upgrade-guard: postgrest version compatibility', () {
    // When postgrest_dart is upgraded, verify that:
    //   1. RetryHttpClient.send's request propagation still applies
    //      (postgrest's `_parseResponse` may have changed).
    //   2. The version is in the known-handled set; if not, manually re-audit
    //      `lib/src/postgrest_builder.dart` for `response.request!` patterns.
    //
    // To extend the set, audit the new version's source and add it here.
    test('postgrest version is known-handled by RetryHttpClient invariant',
        () {
      const knownHandledVersions = {'2.6.0', '2.7.0'};

      final lockFile = File('pubspec.lock');
      if (!lockFile.existsSync()) {
        // Test runs from picnic_lib root; pubspec.lock should exist there.
        // In CI variations, skip rather than fail.
        return;
      }
      final content = lockFile.readAsStringSync();
      final match = RegExp(
        r'  postgrest:\s*\n(?:    .*\n)*?    version: "([^"]+)"',
      ).firstMatch(content);
      final version = match?.group(1);

      expect(
        version,
        isNotNull,
        reason: 'postgrest dependency not found in pubspec.lock',
      );
      expect(
        knownHandledVersions.contains(version),
        isTrue,
        reason:
            'postgrest version "$version" is not in the known-handled set '
            '$knownHandledVersions. Re-audit '
            'lib/src/postgrest_builder.dart for `response.request!` '
            'patterns and confirm RetryHttpClient.send still ensures '
            'response.request != null. After audit, add the new '
            'version to knownHandledVersions in this test.',
      );
    });
  });
}

/// Inner client backed by a caller-supplied response builder.
/// Useful for simulating arbitrary StreamedResponse shapes.
class _StubClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  int callCount = 0;

  _StubClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    // Drain body to avoid request finalizer assertions.
    if (request is http.Request) {
      // ignore: unused_local_variable
      final _ = request.body;
    }
    return handler(request);
  }
}
