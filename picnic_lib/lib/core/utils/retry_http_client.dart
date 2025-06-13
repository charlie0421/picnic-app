import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:universal_platform/universal_platform.dart';

class NetworkError extends Error {
  final String message;
  final bool isRetryable;

  NetworkError(this.message, {this.isRetryable = true});

  static bool isRetryableError(String message) {
    return !message.contains('content size exceeds') &&
        !message.contains('connection closed') &&
        !message.contains('connection reset');
  }
}

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
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        logger.d('Request attempt $attempt/$maxAttempts to ${request.url}');
        
        final hostKey = request.url.host;
        _cleanupOldConnections();
        
        if (_connectionPool.containsKey(hostKey)) {
          final lastUsed = _connectionPool[hostKey]!;
          if (DateTime.now().difference(lastUsed) > _connectionMaxAge) {
            _resetConnection(hostKey);
          }
        }

        final copiedRequest = await _copyRequest(request);
        
        try {
          final response = await _sendWithTimeout(copiedRequest);
          
          // 성공적인 응답 처리 - 연결 풀 업데이트
          _connectionPool[hostKey] = DateTime.now();
          
          return response;
        } catch (e) {
          // 네트워크 오류 발생 시 연결 리셋
          if (_shouldResetConnection(e as Exception)) {
            _resetConnection(hostKey);
          }
          throw e;
        }
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        final detailedLog = _createDetailedErrorLog(lastException!, attempt, request.url);
        logger.w(detailedLog);

        if (attempt == maxAttempts || !_shouldRetry(lastException!)) {
          break;
        }

        await _handleRetryDelay(attempt);
      }
    }

    logger.e('All retry attempts failed for ${request.url}');
    return _createErrorResponse(lastException);
  }

  void _cleanupOldConnections() {
    final now = DateTime.now();
    _connectionPool.removeWhere(
        (_, timestamp) => now.difference(timestamp) > _connectionMaxAge);
  }

  void _resetConnection(String hostKey) {
    _connectionPool.remove(hostKey);
  }

  void _setOptimizedHeaders(http.BaseRequest request) {
    // 웹 환경에서는 브라우저가 제한하는 헤더를 설정하지 않음
    if (UniversalPlatform.isWeb) {
      // 웹에서 안전한 헤더만 설정
      final webSafeHeaders = {
        'X-DNS-Prefetch-Control': 'on',
        // 다른 안전한 헤더가 필요하면 여기에 추가
      };
      request.headers.addAll(webSafeHeaders);
    } else {
      // 네이티브 환경에서는 모든 최적화 헤더 사용
      final optimizedHeaders = {
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=${keepAlive.inSeconds}',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Charset': 'utf-8',
        'X-DNS-Prefetch-Control': 'on',
      };
      request.headers.addAll(optimizedHeaders);
    }
  }

  Future<http.StreamedResponse> _sendWithTimeout(http.BaseRequest request) async {
    try {
      // Content-Length 헤더 제거하여 chunked transfer encoding 사용
      request.headers.remove('Content-Length');
      request.headers['Connection'] = 'keep-alive';

      final response = await _inner.send(request).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Request timed out after ${timeout.inSeconds} seconds',
            timeout,
          );
        },
      );

      // 안전한 응답 처리
      return http.StreamedResponse(
        response.stream.handleError((error, stackTrace) {
          logger.e('Stream error during response processing', 
                   error: error, stackTrace: stackTrace);
          throw NetworkError('Stream processing error: $error', isRetryable: true);
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
    } catch (e, s) {
      logger.e('Error sending request', error: e, stackTrace: s);
      if (e is SocketException || e.toString().contains('connection')) {
        throw NetworkError('Network connection error: $e', isRetryable: true);
      }
      throw ClientException('Failed to send request: $e', request.url);
    }
  }

  Future<http.StreamedResponse> _optimizeResponseStream(
      http.StreamedResponse response, http.BaseRequest request) async {
    final optimizedStream =
        response.stream.transform(utf8.decoder).transform(utf8.encoder).timeout(
      timeout,
      onTimeout: (EventSink<List<int>> sink) {
        sink.addError(TimeoutException(
          'Stream processing timed out',
          timeout,
        ));
        sink.close();
      },
    ).handleError((error, StackTrace stackTrace) {
      // 에러 로깅 추가
      logger.e('Stream processing error', error: error, stackTrace: stackTrace);

      final errorMessage = error.toString().toLowerCase();
      if (NetworkError.isRetryableError(errorMessage)) {
        throw NetworkError(
          'Stream processing error: $error',
          isRetryable: true,
        );
      }
      // 재시도 불가능한 에러는 그대로 전파
      throw error;
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

  http.StreamedResponse _createErrorResponse(Exception? lastException) {
    final errorMessage = lastException?.toString() ?? 'Unknown network error';
    final errorBytes = utf8.encode('{"error": "$errorMessage"}');
    
    return http.StreamedResponse(
      Stream.fromIterable([errorBytes]),
      500,
      contentLength: errorBytes.length,
      reasonPhrase: 'Network Error',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
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
