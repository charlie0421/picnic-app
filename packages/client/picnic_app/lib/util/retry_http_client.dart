import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_app/util/logger.dart';

class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxAttempts;
  final Duration timeout;
  final Duration keepAlive;

  // Connection pool 관리를 위한 변수들
  final Map<String, DateTime> _connectionPool = {};
  final Duration _connectionMaxAge = Duration(minutes: 5);
  static const int _maxConcurrentConnections = 6;
  final Random _random = Random();

  RetryHttpClient(
    this._inner, {
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 30),
    this.keepAlive = const Duration(seconds: 60),
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    int attempts = 0;
    Exception? lastException;
    final String hostKey = '${request.url.host}:${request.url.port}';

    while (attempts < maxAttempts) {
      attempts++;
      try {
        // Connection pool 관리
        _manageConnectionPool(hostKey);

        final newRequest = await _copyRequest(request);
        _setOptimizedHeaders(newRequest);

        final response = await _sendWithTimeout(newRequest);

        // 응답 스트림 최적화
        final optimizedStream =
            await _optimizeResponseStream(response, newRequest);

        // 성공적인 응답인 경우 connection pool 업데이트
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _updateConnectionPool(hostKey);
        }

        return optimizedStream;
      } on Exception catch (e) {
        lastException = e;
        if (_shouldRetry(e)) {
          final logMessage = _createDetailedErrorLog(e, attempts, request.url);
          logger.e(logMessage);

          if (attempts < maxAttempts) {
            await _handleRetryDelay(attempts);
            // Connection 재설정
            _resetConnection(hostKey);
            continue;
          }
        }
        break;
      }
    }

    logger.e('All attempts failed. Last error: $lastException');
    return _createErrorResponse(lastException);
  }

  void _manageConnectionPool(String hostKey) {
    final now = DateTime.now();

    // 오래된 연결 제거
    _connectionPool.removeWhere(
        (_, timestamp) => now.difference(timestamp) > _connectionMaxAge);

    // 최대 연결 수 제한
    if (_connectionPool.length >= _maxConcurrentConnections) {
      final oldestKey = _connectionPool.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _connectionPool.remove(oldestKey);
    }

    _connectionPool[hostKey] = now;
  }

  void _updateConnectionPool(String hostKey) {
    _connectionPool[hostKey] = DateTime.now();
  }

  void _setOptimizedHeaders(http.BaseRequest request) {
    final optimizedHeaders = {
      'Connection': 'keep-alive',
      'Keep-Alive': 'timeout=${keepAlive.inSeconds}',
      'Accept-Encoding': 'gzip, deflate',
      'Accept-Charset': 'utf-8',
      'X-DNS-Prefetch-Control': 'on',
    };

    request.headers.addAll(optimizedHeaders);
  }

  Future<http.StreamedResponse> _sendWithTimeout(
      http.BaseRequest request) async {
    try {
      // Content-Length 헤더 제거
      request.headers.remove('Content-Length');

      final response = await _inner.send(request).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Request timed out after ${timeout.inSeconds} seconds',
            timeout,
          );
        },
      );

      // chunked transfer encoding 사용
      if (response.contentLength == null || response.contentLength! < 0) {
        return http.StreamedResponse(
          response.stream,
          response.statusCode,
          headers: {
            ...response.headers,
            'Transfer-Encoding': 'chunked',
          },
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }

      return response;
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      throw ClientException('Failed to send request: $e', request.url);
    }
  }

  Future<http.StreamedResponse> _optimizeResponseStream(
      http.StreamedResponse response, http.BaseRequest request) async {
    final optimizedStream = response.stream
        .transform(utf8.decoder) // UTF-8 디코딩
        .transform(utf8.encoder) // UTF-8 인코딩
        .timeout(
      timeout,
      onTimeout: (EventSink<List<int>> sink) {
        sink.addError(TimeoutException(
          'Stream processing timed out',
          timeout,
        ));
        sink.close();
      },
    ).handleError((error) {
      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('content size exceeds') ||
          errorMessage.contains('connection closed') ||
          errorMessage.contains('connection reset')) {
        // 콘텐츠 크기 초과 에러를 무시하고 계속 진행
        return;
      }
      throw ClientException(
        'Stream processing error: $error',
        request.url,
      );
    });

    return http.StreamedResponse(
      optimizedStream,
      response.statusCode,
      contentLength: null,
      // chunked transfer encoding 사용
      request: request,
      headers: {
        ...response.headers,
        'Transfer-Encoding': 'chunked',
      },
      isRedirect: response.isRedirect,
      persistentConnection: true,
      reasonPhrase: response.reasonPhrase,
    );
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

  void _resetConnection(String hostKey) {
    _connectionPool.remove(hostKey);
  }

  http.StreamedResponse _createErrorResponse(Exception? lastException) {
    return http.StreamedResponse(
      Stream.fromIterable([]),
      500,
      contentLength: 0,
      reasonPhrase: 'Network Error: ${lastException?.toString()}',
      headers: {
        'X-Error-Type': lastException?.runtimeType.toString() ?? 'Unknown',
        'X-Error-Time': DateTime.now().toIso8601String(),
      },
    );
  }

  bool _shouldRetry(Exception error) {
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
        errorString.contains('content size exceeds') ||
        (error is HttpException &&
            (errorString.contains('connection closed') ||
                errorString.contains('connection reset')));
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
          'Unsupported request type: ${original.runtimeType}');
    }

    copy
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = true;

    return copy;
  }

  Future<List<int>> _collectResponseBytes(
      http.StreamedResponse response) async {
    final completer = Completer<List<int>>();
    final bytes = <int>[];

    response.stream.listen(
      (data) {
        bytes.addAll(data);
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(bytes);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  void close() {
    _connectionPool.clear();
    _inner.close();
    super.close();
  }
}
