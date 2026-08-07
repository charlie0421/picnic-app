import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class NetworkError implements Exception {
  final String message;
  final bool isRetryable;

  NetworkError(this.message, {this.isRetryable = true});

  @override
  String toString() => 'NetworkError: $message';
}

class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxAttempts;
  final Duration timeout;
  final Duration bodyInactivityTimeout;

  final Random _random = Random();

  RetryHttpClient(
    this._inner, {
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
    this.bodyInactivityTimeout = const Duration(seconds: 30),
  });

  // postgrest 2.6.0/2.7.0 dereferences `response.request!.method` in
  // _parseResponse on non-2xx paths. If `request` is null on the http.Response
  // reaching postgrest, a TypeError is thrown to the user. We override the
  // high-level methods used by postgrest (get/post/put/patch/delete/head) so
  // we can convert StreamedResponse -> Response ourselves and guarantee that
  // the resulting Response always carries a non-null `request`.
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamedSafe('GET', url, headers, null, null);

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamedSafe('HEAD', url, headers, null, null);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamedSafe('POST', url, headers, body, encoding);

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamedSafe('PUT', url, headers, body, encoding);

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamedSafe('PATCH', url, headers, body, encoding);

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) =>
      _sendUnstreamedSafe('DELETE', url, headers, body, encoding);

  Future<http.Response> _sendUnstreamedSafe(
    String method,
    Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  ) async {
    final request = http.Request(method, url);
    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }
    final streamed = await send(request);
    return _ensureRequestPresent(
      await http.Response.fromStream(streamed),
      request,
    );
  }

  /// Guarantees [response.request] is non-null.
  ///
  /// postgrest's `_parseResponse` does `response.request!.method` on the
  /// error branch. If the underlying http stack ever yields a Response with
  /// `request == null` (observed on Android in production), we rebuild it
  /// here using [fallback] so postgrest can never throw a null-check error.
  http.Response _ensureRequestPresent(
    http.Response response,
    http.BaseRequest fallback,
  ) {
    if (response.request != null) return response;
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      request: fallback,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Exception? lastException;
    // 비멱등 요청(예: POST/PUT/PATCH/DELETE)은 재시도하지 않음
    final int attemptsAllowed = _isIdempotent(request.method) ? maxAttempts : 1;

    for (int attempt = 1; attempt <= attemptsAllowed; attempt++) {
      try {
        if (attempt > 1) {
          logger.d('Request attempt $attempt/$maxAttempts to ${request.url}');
        }

        final copiedRequest = await _copyRequest(request);
        return await _sendWithTimeout(copiedRequest);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

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
    return _createErrorResponse(lastException, request);
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
              throw TimeoutException(
                'Request timed out after ${timeout.inSeconds} seconds',
                timeout,
              );
            },
          );

      // 안전한 응답 처리.
      //
      // `timeout` 은 헤더 수신(_inner.send)까지만 감싼다. 헤더 이후 본문이
      // 멈추면 Response.fromStream 이 영원히 완료되지 않아 provider 가
      // loading 에 갇힌다. 그래서 본문 스트림에는 별도의 inactivity 예산을
      // 건다: 마지막 바이트 이후 bodyInactivityTimeout 동안 아무 데이터도
      // 오지 않을 때만 실패한다. 총 소요시간 상한이 아니므로 바이트가 계속
      // 흐르는 느린 회선은 실패하지 않는다. Stream.timeout 은 이벤트마다
      // 타이머를 리셋하고, sink.close() 로 하류가 done 을 받으면 원본
      // 구독과 타이머가 함께 정리된다.
      //
      // 이 시점에 send() 는 이미 반환된 뒤라 본문 타임아웃 에러는 재시도
      // 루프를 다시 타지 않는다. 특히 비멱등(결제) 요청이 본문 스톨로
      // 재전송되는 일은 구조적으로 불가능하다.
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
        }).timeout(
          bodyInactivityTimeout,
          onTimeout: (sink) {
            logger.e(
              'Response body stalled: no data for '
              '${bodyInactivityTimeout.inSeconds}s from ${request.url}',
            );
            sink.addError(
              NetworkError(
                'Response body timed out after '
                '${bodyInactivityTimeout.inSeconds}s of inactivity',
                isRetryable: true,
              ),
            );
            sink.close();
          },
        ),
        response.statusCode,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
        request: request,
      );
    } on TimeoutException {
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
    // _sendWithTimeout 은 SocketException 을 NetworkError 로 감싸서 던진다.
    // 이 분기가 없으면 감싸진 예외가 아래 타입 검사에도, 문자열 검사에도
    // 걸리지 않아 콜드스타트의 "Failed host lookup" 이 재시도 없이 즉시
    // _createErrorResponse 의 가짜 500 으로 떨어진다.
    if (error is NetworkError) {
      return error.isRetryable;
    }

    if (error is SocketException ||
        error is TimeoutException ||
        error is ClientException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    // 'content size exceeds' 는 재시도 대상이 맞다: 통신사 프록시의
    // Android gzip/Content-Length 불일치는 연결 종속적이라 새 연결로
    // 재시도하면 대개 복구된다.
    return errorString.contains('connection closed') ||
        errorString.contains('connection reset') ||
        errorString.contains('broken pipe') ||
        errorString.contains('before full header was received') ||
        errorString.contains('content size exceeds');
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
    _inner.close();
    super.close();
  }
}
