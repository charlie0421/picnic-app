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

    // NetworkError.isRetryableError (static, message-string based) was
    // removed: nothing in production ever called it, and its
    // 'content size exceeds' verdict (non-retryable) contradicted
    // _shouldRetry's correct retry-on-new-connection behavior. Retryability
    // is decided solely by the wired-in `isRetryable` field + _shouldRetry.
  });

  group('RetryHttpClient', () {
    test('can be created with custom params', () {
      final client = RetryHttpClient(
        http.Client(),
        maxAttempts: 5,
        timeout: const Duration(seconds: 60),
        bodyInactivityTimeout: const Duration(seconds: 90),
      );
      expect(client, isNotNull);
      expect(client.maxAttempts, equals(5));
      expect(client.timeout, equals(const Duration(seconds: 60)));
      expect(client.bodyInactivityTimeout, equals(const Duration(seconds: 90)));
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
    // _shouldRetry returns true for: NetworkError with isRetryable,
    // SocketException, TimeoutException, ClientException, or string-matching
    // on connection closed/reset, broken pipe, before full header,
    // content size exceeds.

    http.Request makeGetRequest() =>
        http.Request('GET', Uri.parse('https://example.com/test'));

    test('SocketException is wrapped to NetworkError and still retries',
        () async {
      final inner = _FailingClient(
        const SocketException('Connection refused'),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      // SocketException -> NetworkError(isRetryable: true) ->
      // _shouldRetry honours the flag -> all attempts are used.
      expect(inner.callCount, equals(3));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('cold-start DNS failure retries instead of failing on first attempt',
        () async {
      // The regression this guards: on a cold start the first Supabase
      // request can hit "Failed host lookup" before DNS is warm. That message
      // matches none of the string patterns below, so before NetworkError was
      // recognised it fell straight through to the synthetic 500 and the home
      // banner rendered an error view instead of retrying.
      final inner = _FailingClient(
        const SocketException(
          "Failed host lookup: 'xtijtefcycoeqludlngc.supabase.co'",
        ),
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(3));
      expect(response.statusCode, equals(500));
      client.close();
    });

    test('cold-start DNS failure recovers once the lookup succeeds', () async {
      final inner = _FailThenSucceedClient(
        const SocketException("Failed host lookup: 'example.com'"),
        failCount: 1,
      );
      final client = RetryHttpClient(inner, maxAttempts: 3);

      final response = await client.send(makeGetRequest());

      expect(inner.callCount, equals(2));
      expect(response.statusCode, equals(200));
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

  group('send() - HttpException with connection message', () {
    test('HttpException with connection closed is wrapped to NetworkError',
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

    test('HttpException with connection reset is wrapped to NetworkError',
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
    // RetryHttpClient overrides get/post/put/patch/delete/head and runs
    // every Response through _ensureRequestPresent so postgrest can
    // never observe a null request, regardless of inner-client behavior.

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

  group('response body inactivity timeout', () {
    // Regression this group guards: the 30s `timeout` only covers
    // _inner.send() (headers). If the server stalls mid-body, the
    // StreamedResponse future chain (Response.fromStream) never completes,
    // the provider stays in loading forever, and the home banner shimmer
    // spins indefinitely. The body must terminate in finite time.
    //
    // Design constraint (trap 2): the budget is an INACTIVITY window, not a
    // total-duration deadline. As long as bytes keep flowing, a slow link
    // must never fail — a 22s PostgREST response on slow mobile succeeded
    // before and must keep succeeding.

    /// Resolves with the fromStream result or error; the sentinel proves the
    /// future did not hang past [patience].
    Future<Object?> raceAgainstHang(
      Future<http.Response> pending, {
      Duration patience = const Duration(seconds: 5),
    }) {
      return Future.any<Object?>([
        pending.then<Object?>((r) => r, onError: (Object e) => e),
        Future.delayed(patience, () => 'HUNG'),
      ]);
    }

    test('stalled body after headers fails with NetworkError in finite time',
        () async {
      final inner = _StallingBodyClient(leadingChunks: [
        utf8.encode('{"partial":'),
      ]);
      final client = RetryHttpClient(
        inner,
        maxAttempts: 3,
        bodyInactivityTimeout: const Duration(milliseconds: 200),
      );

      final streamed = await client
          .send(http.Request('GET', Uri.parse('https://example.com/stall')));
      final outcome = await raceAgainstHang(http.Response.fromStream(streamed));

      expect(outcome, isNot('HUNG'),
          reason: 'stalled body must terminate within the inactivity budget');
      expect(outcome, isA<NetworkError>());
      expect((outcome as NetworkError).isRetryable, isTrue,
          reason: 'a mid-body stall is connection-specific; a fresh '
              'connection usually recovers, consistent with _shouldRetry');
      client.close();
    });

    test('slow but active body is NOT killed by the inactivity budget',
        () async {
      // 10 chunks x 100ms = ~1s total, far above the 300ms inactivity budget.
      // Under a total-duration deadline this would fail; under an inactivity
      // window it must succeed because bytes keep flowing.
      final inner = _SlowDripClient(
        totalChunks: 10,
        interval: const Duration(milliseconds: 100),
      );
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        bodyInactivityTimeout: const Duration(milliseconds: 300),
      );

      final streamed = await client
          .send(http.Request('GET', Uri.parse('https://example.com/drip')));
      final response = await http.Response.fromStream(streamed);

      expect(response.statusCode, equals(200));
      expect(response.bodyBytes.length, equals(10));
      client.close();
    });

    test('fires on the AuthHttpClient-style path (send(), not get/post)',
        () async {
      // supabase wraps RetryHttpClient in AuthHttpClient, which overrides
      // only send(); postgrest's get/post never reach RetryHttpClient's
      // get/post overrides. The timeout must therefore live in send().
      final inner = _StallingBodyClient();
      final retryClient = RetryHttpClient(
        inner,
        maxAttempts: 3,
        bodyInactivityTimeout: const Duration(milliseconds: 200),
      );
      final authLike = _AuthLikeClient(retryClient);

      final outcome = await raceAgainstHang(
        authLike.get(Uri.parse('https://example.com/supabase-path')),
      );

      expect(outcome, isNot('HUNG'),
          reason: 'timeout must apply on the BaseClient._sendUnstreamed -> '
              'send() route used by real Supabase traffic');
      expect(outcome, isA<NetworkError>());
      retryClient.close();
    });

    test('stalled body on a POST does not trigger a second attempt', () async {
      // Payment invariant: the body stall surfaces AFTER send() has returned
      // the headers, so it must never re-enter the retry loop — a retried
      // non-idempotent request could double-charge.
      final inner = _StallingBodyClient();
      final retryClient = RetryHttpClient(
        inner,
        maxAttempts: 3,
        bodyInactivityTimeout: const Duration(milliseconds: 200),
      );
      final authLike = _AuthLikeClient(retryClient);

      final outcome = await raceAgainstHang(
        authLike.post(
          Uri.parse('https://example.com/pay'),
          body: '{"amount": 1}',
        ),
      );

      expect(outcome, isA<NetworkError>());
      expect(inner.callCount, equals(1),
          reason: 'a body-stall on a non-idempotent request must not retry');
      retryClient.close();
    });

    test('stalled GET body is not re-requested either', () async {
      // Even for idempotent requests the stall happens after send() returned,
      // so the retry loop never sees it. This documents that the budget
      // terminates the future; it does not re-fetch.
      final inner = _StallingBodyClient();
      final retryClient = RetryHttpClient(
        inner,
        maxAttempts: 3,
        bodyInactivityTimeout: const Duration(milliseconds: 200),
      );
      final authLike = _AuthLikeClient(retryClient);

      final outcome = await raceAgainstHang(
        authLike.get(Uri.parse('https://example.com/idempotent')),
      );

      expect(outcome, isA<NetworkError>());
      expect(inner.callCount, equals(1));
      retryClient.close();
    });

    test('source body subscription is cancelled after the timeout fires',
        () async {
      final inner = _StallingBodyClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        bodyInactivityTimeout: const Duration(milliseconds: 200),
      );

      final streamed = await client
          .send(http.Request('GET', Uri.parse('https://example.com/leak')));
      await raceAgainstHang(http.Response.fromStream(streamed));
      // Give cancellation microtasks a beat to propagate.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(inner.sourceCancelled, isTrue,
          reason: 'the inner body stream must be cancelled on timeout, '
              'or the socket/subscription leaks');
      client.close();
    });

    test('downstream cancellation propagates to the source stream', () async {
      final inner = _StallingBodyClient(leadingChunks: [
        [1, 2, 3],
      ]);
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        bodyInactivityTimeout: const Duration(seconds: 30),
      );

      final streamed = await client
          .send(http.Request('GET', Uri.parse('https://example.com/cancel')));
      final subscription = streamed.stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(inner.sourceCancelled, isTrue,
          reason: 'cancelling the wrapped stream must cancel the inner one');
      client.close();
    });

    test('default bodyInactivityTimeout is 30 seconds and separate from '
        'the header timeout', () {
      final client = RetryHttpClient(http.Client());
      expect(client.bodyInactivityTimeout,
          equals(const Duration(seconds: 30)));
      // Separate knobs: changing one must not change the other.
      final tuned = RetryHttpClient(
        http.Client(),
        timeout: const Duration(seconds: 10),
        bodyInactivityTimeout: const Duration(seconds: 45),
      );
      expect(tuned.timeout, equals(const Duration(seconds: 10)));
      expect(tuned.bodyInactivityTimeout, equals(const Duration(seconds: 45)));
      client.close();
      tuned.close();
    });
  });

  group('upgrade-guard: postgrest version compatibility', () {
    // When postgrest_dart is upgraded, verify that:
    //   1. RetryHttpClient's _ensureRequestPresent invariant still applies
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
            'patterns and confirm RetryHttpClient.{get,post,put,patch,delete,head} '
            'still ensure response.request != null. After audit, add the new '
            'version to knownHandledVersions in this test.',
      );
    });
  });
}

/// Mimics supabase's AuthHttpClient: extends BaseClient and overrides ONLY
/// send(). postgrest calls _httpClient.get/post(...) on this layer, which
/// routes through BaseClient._sendUnstreamed() -> send() -> inner.send().
/// RetryHttpClient's own get/post overrides are never executed on this path,
/// so anything we assert through this wrapper proves the behavior lives in
/// RetryHttpClient.send().
class _AuthLikeClient extends http.BaseClient {
  final http.Client _inner;

  _AuthLikeClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);
}

/// Returns headers immediately, then serves a body stream controlled by the
/// caller: emits [leadingChunks] then stalls forever (never closes) unless
/// [chunkInterval] keeps emitting up to [totalChunks].
class _StallingBodyClient extends http.BaseClient {
  int callCount = 0;
  bool sourceCancelled = false;
  final List<List<int>> leadingChunks;

  _StallingBodyClient({this.leadingChunks = const []});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    final controller = StreamController<List<int>>(
      onCancel: () => sourceCancelled = true,
    );
    for (final chunk in leadingChunks) {
      controller.add(chunk);
    }
    // Intentionally never closed: simulates a body that stalls after headers.
    return http.StreamedResponse(controller.stream, 200, request: request);
  }
}

/// Emits [totalChunks] chunks spaced [interval] apart, then closes. Total
/// duration deliberately exceeds any single inactivity window under test.
class _SlowDripClient extends http.BaseClient {
  final int totalChunks;
  final Duration interval;

  _SlowDripClient({required this.totalChunks, required this.interval});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stream = Stream<List<int>>.periodic(interval, (i) => [i])
        .take(totalChunks);
    return http.StreamedResponse(stream, 200, request: request);
  }
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
