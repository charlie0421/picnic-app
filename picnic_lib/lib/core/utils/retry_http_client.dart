import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class NetworkError implements Exception {
  final String message;
  final bool isRetryable;

  NetworkError(this.message, {this.isRetryable = true});

  @override
  String toString() => 'NetworkError: $message';

  static bool isRetryableError(String message) {
    return !message.toLowerCase().contains('content size exceeds');
  }
}

class RetryHttpClient extends http.BaseClient {
  static const _streamCleanupTimeout = Duration(milliseconds: 100);

  final http.Client _inner;
  final int maxAttempts;
  final Duration timeout;
  final Duration keepAlive;

  // Connection pool 관리를 위한 변수들
  final Map<String, DateTime> _connectionPool = {};
  final Duration _connectionMaxAge = Duration(minutes: 5);
  final Random _random = Random();

  RetryHttpClient(
    this._inner, {
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
    this.keepAlive = const Duration(seconds: 60),
  });

  Future<http.StreamedResponse> _sendAttempt(
    http.BaseRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final streamed = await _sendWithTimeout(request);
    final remaining = timeout - stopwatch.elapsed;

    // Buffer idempotent JSON-style responses so body failures can retry before
    // any bytes escape. Storage downloads and SSE stay streamed to avoid
    // buffering large or unbounded payloads; their streams still get a total
    // request deadline below.
    if (_isIdempotent(request.method) &&
        !_requiresStreamingResponse(request, streamed)) {
      return _bufferResponse(streamed, remaining);
    }

    return _copyStreamedResponse(
      streamed,
      _withDeadline(streamed.stream, remaining),
    );
  }

  Future<http.StreamedResponse> _bufferResponse(
    http.StreamedResponse response,
    Duration remaining,
  ) async {
    final bytes = BytesBuilder(copy: false);
    final iterator = StreamIterator<List<int>>(response.stream);
    final stopwatch = Stopwatch()..start();
    var completed = false;

    try {
      while (true) {
        final timeLeft = remaining - stopwatch.elapsed;
        if (timeLeft <= Duration.zero) {
          throw _requestTimeoutException();
        }
        final hasNext = await iterator.moveNext().timeout(
          timeLeft,
          onTimeout: () => throw _requestTimeoutException(),
        );
        if (!hasNext) {
          completed = true;
          break;
        }
        bytes.add(iterator.current);
      }
    } finally {
      stopwatch.stop();
      if (!completed) {
        await _cancelSafely(iterator.cancel);
      }
    }

    final body = bytes.takeBytes();
    return http.StreamedResponse(
      Stream.value(body),
      response.statusCode,
      contentLength: body.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  bool _requiresStreamingResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
  ) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    return request.url.path.startsWith('/storage/v1/') ||
        contentType.startsWith('text/event-stream');
  }

  http.StreamedResponse _copyStreamedResponse(
    http.StreamedResponse response,
    Stream<List<int>> stream,
  ) {
    return http.StreamedResponse(
      stream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  Stream<List<int>> _withDeadline(
    Stream<List<int>> source,
    Duration remaining,
  ) {
    late StreamController<List<int>> controller;
    StreamSubscription<List<int>>? subscription;
    Timer? deadline;
    final subscriptionDelay = Stopwatch()..start();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      deadline?.cancel();
      unawaited(controller.close());
    }

    controller = StreamController<List<int>>(
      sync: true,
      onListen: () {
        final timeLeft = remaining - subscriptionDelay.elapsed;
        subscriptionDelay.stop();
        if (timeLeft <= Duration.zero) {
          controller.addError(_requestTimeoutException());
          finish();
          return;
        }

        deadline = Timer(timeLeft, () {
          if (finished) return;
          controller.addError(_requestTimeoutException());
          final activeSubscription = subscription;
          if (activeSubscription != null) {
            unawaited(_cancelSafely(activeSubscription.cancel));
          }
          finish();
        });
        subscription = source.listen(
          controller.add,
          onError: (Object error, StackTrace stackTrace) {
            if (finished) return;
            controller.addError(error, stackTrace);
            finish();
          },
          onDone: finish,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        deadline?.cancel();
        final activeSubscription = subscription;
        if (activeSubscription == null) return null;
        return _cancelSafely(activeSubscription.cancel);
      },
    );

    return controller.stream;
  }

  Future<void> _cancelSafely(Future<void> Function() cancel) async {
    try {
      await cancel().timeout(_streamCleanupTimeout);
    } catch (_) {
      // Cleanup is best-effort and must never replace the request failure.
    }
  }

  TimeoutException _requestTimeoutException() => TimeoutException(
    'Request timed out after ${timeout.inSeconds} seconds',
    timeout,
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _sendWithRetry<http.StreamedResponse>(
        request,
        sendAttempt: _sendAttempt,
        createErrorResponse: _createErrorResponse,
      );

  Future<T> _sendWithRetry<T>(
    http.BaseRequest request, {
    required Future<T> Function(http.BaseRequest request) sendAttempt,
    required FutureOr<T> Function(
      Exception? lastException,
      http.BaseRequest request,
    )
    createErrorResponse,
  }) async {
    Exception? lastException;
    // 비멱등 요청(예: POST/PUT/PATCH/DELETE)은 재시도하지 않음
    final int attemptsAllowed = _isIdempotent(request.method) ? maxAttempts : 1;

    for (int attempt = 1; attempt <= attemptsAllowed; attempt++) {
      try {
        if (attempt > 1) {
          logger.d('Request attempt $attempt/$maxAttempts to ${request.url}');
        }

        final hostKey = request.url.host;
        _cleanupOldConnections();

        if (_connectionPool.containsKey(hostKey)) {
          final lastUsed = _connectionPool[hostKey]!;
          if (DateTime.now().difference(lastUsed) > _connectionMaxAge) {
            _resetConnection(hostKey);
          }
        }

        final copiedRequest = await _copyRequest(request);

        final response = await sendAttempt(copiedRequest);

        // 성공적인 응답 처리 - 연결 풀 업데이트
        _connectionPool[hostKey] = DateTime.now();

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (_shouldResetConnection(lastException)) {
          _resetConnection(request.url.host);
        }

        final detailedLog = _createDetailedErrorLog(
          lastException,
          attempt,
          request.url,
        );
        logger.w(detailedLog);

        if (attempt == attemptsAllowed || !_shouldRetry(lastException)) {
          break;
        }

        await _handleRetryDelay(attempt);
      }
    }

    logger.e('All retry attempts failed for ${request.url}');
    return createErrorResponse(lastException, request);
  }

  void _cleanupOldConnections() {
    final now = DateTime.now();
    _connectionPool.removeWhere(
      (_, timestamp) => now.difference(timestamp) > _connectionMaxAge,
    );
  }

  void _resetConnection(String hostKey) {
    _connectionPool.remove(hostKey);
  }

  Future<http.StreamedResponse> _sendWithTimeout(
    http.BaseRequest request,
  ) async {
    try {
      // Content-Length 헤더 제거하여 chunked transfer encoding 사용
      request.headers.remove('Content-Length');
      request.headers['Connection'] = 'keep-alive';

      final response = await _inner
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              throw _requestTimeoutException();
            },
          );

      // 안전한 응답 처리
      return http.StreamedResponse(
        response.stream.handleError((error, stackTrace) {
          logger.e(
            'Stream error during response processing',
            error: error,
            stackTrace: stackTrace,
          );
          throw NetworkError(
            'Stream processing error: $error',
            isRetryable: true,
          );
        }),
        response.statusCode,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
        request: request,
      );
    } on TimeoutException {
      rethrow;
    } on NetworkError {
      rethrow;
    } catch (e, s) {
      logger.e('Error sending request', error: e, stackTrace: s);
      if (e is SocketException || e.toString().contains('connection')) {
        throw NetworkError('Network connection error: $e', isRetryable: true);
      }
      throw ClientException('Failed to send request: $e', request.url);
    }
  }

  String _createDetailedErrorLog(Exception error, int attempt, Uri url) {
    return '''
Attempt $attempt failed:
URL: $url
Error Type: ${error.runtimeType}
Error Message: $error
Timestamp: ${DateTime.now().toIso8601String()}
Headers: ${error is ClientException ? error.uri : 'N/A'}
''';
  }

  Future<void> _handleRetryDelay(int attempt) async {
    // 지수 백오프 with 약간의 랜덤성 추가
    final baseDelay = Duration(milliseconds: 200 * attempt * attempt);
    final jitter = Duration(milliseconds: (_random.nextDouble() * 50).round());
    await Future.delayed(baseDelay + jitter);
  }

  http.StreamedResponse _createErrorResponse(
    Exception? lastException,
    http.BaseRequest request,
  ) {
    final errorMessage = lastException?.toString() ?? 'Unknown network error';
    final errorBytes = utf8.encode('{"error": "$errorMessage"}');

    return http.StreamedResponse(
      Stream.fromIterable([errorBytes]),
      500,
      contentLength: errorBytes.length,
      reasonPhrase: 'Network Error',
      request: request,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'X-Error-Type': lastException?.runtimeType.toString() ?? 'Unknown',
        'X-Error-Time': DateTime.now().toIso8601String(),
      },
    );
  }

  bool _shouldRetry(Exception error) {
    if (!NetworkError.isRetryableError(error.toString())) {
      return false;
    }

    if (error is NetworkError) {
      return error.isRetryable;
    }

    if (error is SocketException ||
        error is TimeoutException ||
        error is ClientException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection closed') ||
        errorString.contains('connection reset') ||
        errorString.contains('broken pipe') ||
        errorString.contains('before full header was received') ||
        (error is HttpException &&
            (errorString.contains('connection closed') ||
                errorString.contains('connection reset')));
  }

  bool _isIdempotent(String method) {
    final m = method.toUpperCase();
    return m == 'GET' || m == 'HEAD' || m == 'OPTIONS';
  }

  Future<http.BaseRequest> _copyRequest(http.BaseRequest original) async {
    http.BaseRequest copy;
    if (original is http.Request) {
      copy = http.Request(original.method, original.url)
        ..encoding = original.encoding
        ..body = original.body;
    } else if (original is http.MultipartRequest) {
      copy = http.MultipartRequest(original.method, original.url)
        ..fields.addAll(original.fields)
        ..files.addAll(original.files);
    } else {
      throw UnsupportedError(
        'Unsupported request type: ${original.runtimeType}',
      );
    }

    copy
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = true;

    return copy;
  }

  @override
  void close() {
    _connectionPool.clear();
    _inner.close();
    super.close();
  }

  bool _shouldResetConnection(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('network');
  }
}
