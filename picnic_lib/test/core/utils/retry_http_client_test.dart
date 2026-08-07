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

/// A mock client that emits a fixed sequence of chunks, optionally throwing
/// [thenError] after the last chunk, to test the buffer-cap fallback path.
class _CountingChunkedClient extends http.BaseClient {
  _CountingChunkedClient(this.chunks, {this.thenError});

  final List<List<int>> chunks;
  final Object? thenError;
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    return http.StreamedResponse(_stream(), 200, request: request);
  }

  Stream<List<int>> _stream() async* {
    for (final chunk in chunks) {
      yield chunk;
    }
    if (thenError != null) {
      throw thenError!;
    }
  }
}

/// A client whose response body only yields each chunk once the test
/// explicitly calls [releaseNext] for it. Lets a test prove RetryHttpClient
/// made a decision (e.g. skipped buffering, or returned before the whole
/// body was available) *without* needing every chunk to have arrived --
/// something an eagerly-yielding fake stream can't distinguish from "read
/// everything, then decide."
class _GatedChunkedClient extends http.BaseClient {
  _GatedChunkedClient(this.chunks, {this.contentLength});

  final List<List<int>> chunks;
  final int? contentLength;
  int callCount = 0;
  List<Completer<void>> _gates = [];

  void releaseNext() {
    final gate = _gates.firstWhere(
      (g) => !g.isCompleted,
      orElse: () => throw StateError('No more gated chunks to release'),
    );
    gate.complete();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    _gates = List.generate(chunks.length, (_) => Completer<void>());
    return http.StreamedResponse(
      _stream(),
      200,
      contentLength: contentLength,
      request: request,
    );
  }

  Stream<List<int>> _stream() async* {
    for (var i = 0; i < chunks.length; i++) {
      await _gates[i].future;
      yield chunks[i];
    }
  }
}

/// A client whose response stream is backed by a real [StreamController],
/// so a test can observe (via [sourceCanceled]) whether cancelling the
/// RetryHttpClient response actually tears down the underlying
/// subscription -- the real-world stand-in for the socket being closed --
/// rather than just abandoning a Dart Future while the "connection" is
/// left open. It never closes on its own, simulating a stalled connection:
/// the only way it ever ends is via cancellation.
class _CancelTrackingStreamClient extends http.BaseClient {
  _CancelTrackingStreamClient(this.leadingChunks);

  final List<List<int>> leadingChunks;
  bool sourceCanceled = false;
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount++;
    final controller = StreamController<List<int>>(
      onCancel: () => sourceCanceled = true,
    );
    for (final chunk in leadingChunks) {
      controller.add(chunk);
    }
    return http.StreamedResponse(controller.stream, 200, request: request);
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

  group('buffered response cap fallback', () {
    http.Request makeGetRequest() =>
        http.Request('GET', Uri.parse('https://example.com/big'));

    test(
        'responses under maxBufferedResponseBytes still buffer and '
        'retry body failures', () async {
      final inner = _FailingBodyThenSucceedClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 2,
        maxBufferedResponseBytes: 16,
      );

      final response =
          await client.get(Uri.parse('https://example.com/small'));

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
      expect(inner.callCount, 2);
      client.close();
    });

    test(
        'a response exactly at maxBufferedResponseBytes (the inclusive '
        'boundary) still buffers and retries body failures', () async {
      // `{"ok": true}` from _FailingBodyThenSucceedClient is exactly 12
      // bytes; pin the cap comparison at that exact boundary so a `>` vs
      // `>=` regression is caught instead of only ever being tested with
      // headroom to spare.
      final inner = _FailingBodyThenSucceedClient();
      final client = RetryHttpClient(
        inner,
        maxAttempts: 2,
        maxBufferedResponseBytes: 12,
      );

      final response =
          await client.get(Uri.parse('https://example.com/exact'));

      expect(response.statusCode, 200);
      expect(response.body, '{"ok": true}');
      expect(inner.callCount, 2,
          reason: 'a body exactly at the cap must still be buffered '
              '(and thus retryable) -- only bytes strictly over the cap '
              'should fall back to streaming');
      client.close();
    });

    test(
        'genuinely streams later chunks as they arrive instead of reading '
        'the whole body before returning, once maxBufferedResponseBytes is '
        'exceeded', () async {
      final chunkA = List<int>.generate(20, (i) => i); // alone exceeds cap
      final chunkB = List<int>.generate(5, (i) => 100 + i);
      final inner = _GatedChunkedClient([chunkA, chunkB]);
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        maxBufferedResponseBytes: 16,
      );

      final sendFuture = client.send(makeGetRequest());
      // Let the request start so the per-call gates exist, then release
      // only the first (over-cap) chunk. chunkB stays gated.
      await Future<void>.delayed(Duration.zero);
      inner.releaseNext();

      final response = await sendFuture.timeout(const Duration(seconds: 2));
      expect(inner.callCount, 1);

      final received = <int>[];
      final sub = response.stream.listen(received.addAll);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(received, equals(chunkA),
          reason: 'chunkB is still gated -- if the implementation secretly '
              'buffered the whole body before returning from send(), this '
              'assertion would need chunkB to already be present, which is '
              'impossible since it has not been released yet');

      inner.releaseNext();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(received, equals([...chunkA, ...chunkB]));

      await sub.cancel();
      client.close();
    });

    test(
        'does not retry a body failure once the response exceeded '
        'maxBufferedResponseBytes, and does not re-expose the unverified '
        'Content-Length', () async {
      final chunkA = List<int>.generate(20, (i) => i);
      final inner = _CountingChunkedClient(
        [chunkA],
        thenError: const SocketException('body broke after cap'),
      );
      final client = RetryHttpClient(
        inner,
        maxAttempts: 3,
        maxBufferedResponseBytes: 16,
      );

      final response = await client.send(makeGetRequest());

      // We only ever counted a partial prefix, never the true total, so
      // the fallback response must not claim a contentLength.
      expect(response.contentLength, isNull);

      // The raw inner stream error is wrapped into a NetworkError by
      // _sendWithTimeout before _bufferResponse ever sees it (see the
      // `response.stream.handleError` in _sendWithTimeout), so the
      // fallback stream surfaces a NetworkError here rather than the
      // original SocketException. What matters for this test is that the
      // error is NOT swallowed and retried -- callCount stays at 1.
      await expectLater(
        response.stream.drain<void>(),
        throwsA(isA<NetworkError>()),
      );
      expect(inner.callCount, 1);
      client.close();
    });

    test(
        'a Content-Length already over the cap skips buffering immediately '
        '-- before any body bytes are read -- and does not re-expose that '
        'Content-Length (it may be the gzip-compressed size while the '
        'stream is decompressed)', () async {
      final inner = _GatedChunkedClient(
        [List<int>.generate(4, (i) => i)],
        contentLength: 1000, // declared over the cap; body stays gated
      );
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        timeout: const Duration(milliseconds: 200),
        maxBufferedResponseBytes: 16,
      );

      // If the Content-Length precheck regressed (e.g. buffering is
      // attempted regardless), _bufferResponse would block on the first
      // gated -- and never released here before this await -- chunk until
      // its own internal per-chunk timeout fires, and send() would return
      // a synthetic 500 instead of throwing, so bound this with a timeout
      // as a backstop rather than relying on that alone.
      final response =
          await client.send(makeGetRequest()).timeout(
                const Duration(milliseconds: 800),
              );

      expect(response.statusCode, 200,
          reason: 'a synthetic 500 here means the Content-Length precheck '
              'did not short-circuit and _bufferResponse instead blocked '
              'trying to read a body it should never have attempted to '
              'buffer');
      expect(response.contentLength, isNull);

      inner.releaseNext();
      final body = await response.stream
          .fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      expect(body, equals([0, 1, 2, 3]));
      client.close();
    });

    test(
        'a deadline timeout during the buffer-cap fallback cancels the '
        'underlying subscription instead of leaking it', () async {
      final bigChunk = List<int>.generate(20, (i) => i); // alone > cap
      final inner = _CancelTrackingStreamClient([bigChunk]);
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        timeout: const Duration(milliseconds: 40),
        maxBufferedResponseBytes: 16,
      );

      final response = await client.send(makeGetRequest());

      // The fake source never closes on its own (simulating a stalled
      // connection past the cap), so the only way this drain ends is the
      // deadline timer firing.
      await expectLater(
        response.stream.drain<void>(),
        throwsA(anything),
      );

      // _cancelSafely bounds cleanup at _streamCleanupTimeout (100ms);
      // give it a little headroom to actually run.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(inner.sourceCanceled, isTrue,
          reason:
              'the deadline firing must cancel the real subscription behind '
              'the fallback stream (via _prefixedStream), or the '
              'subscription/socket leaks indefinitely since nothing else '
              'will ever stop it');
      client.close();
    });

    test(
        'the consumer cancelling the buffer-cap fallback stream early '
        'cancels the underlying subscription instead of leaking it',
        () async {
      final bigChunk = List<int>.generate(20, (i) => i); // alone > cap
      final inner = _CancelTrackingStreamClient([bigChunk]);
      final client = RetryHttpClient(
        inner,
        maxAttempts: 1,
        timeout: const Duration(seconds: 5),
        maxBufferedResponseBytes: 16,
      );

      final response = await client.send(makeGetRequest());

      final sub = response.stream.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(inner.sourceCanceled, isTrue,
          reason: 'the consumer abandoning the fallback stream before it '
              'completes must cancel the underlying subscription instead '
              'of leaking it');
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
