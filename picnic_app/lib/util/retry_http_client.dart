import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/logger.dart';

class RetryHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxAttempts;
  final Duration timeout;
  final Duration keepAlive;

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

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final newRequest = await _copyRequest(request);

        // Connection 설정 추가
        newRequest.headers.addAll({
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=${keepAlive.inSeconds}',
          if (newRequest is http.Request && newRequest.body.isNotEmpty)
            'Content-Length': newRequest.body.length.toString(),
        });

        final response = await _inner.send(newRequest).timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
                'Request timed out after ${timeout.inSeconds} seconds');
          },
        );

        // 스트림 버퍼링 처리
        final stream = response.stream.handleError((error) {
          throw ClientException(
            'Error while receiving data: $error',
            newRequest.url,
          );
        });

        return http.StreamedResponse(
          stream,
          response.statusCode,
          contentLength: response.contentLength,
          request: newRequest,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      } on Exception catch (e) {
        lastException = e;
        if (_shouldRetry(e)) {
          logger.e('Attempt $attempts failed: $e');
          if (attempts < maxAttempts) {
            final waitTime = Duration(milliseconds: 200 * attempts * attempts);
            await Future.delayed(waitTime);
            continue;
          }
        }
        break;
      }
    }

    logger.e('All attempts failed. Last error: $lastException');
    return http.StreamedResponse(
      Stream.fromIterable([]),
      500,
      reasonPhrase: 'Network Error: ${lastException?.toString()}',
    );
  }

  bool _shouldRetry(Exception error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is ClientException ||
        (error is HttpException &&
            error.toString().contains('Connection closed'));
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
      ..persistentConnection = true; // 연결 유지 설정

    return copy;
  }

  // 대용량 응답을 위한 스트림 처리 메서드
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
    _inner.close();
    super.close();
  }
}
