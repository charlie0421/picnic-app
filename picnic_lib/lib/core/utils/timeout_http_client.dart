import 'dart:io';
import 'package:http/http.dart' as http;

class TimeoutHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Duration timeout;

  TimeoutHttpClient({
    Duration? timeout,
    http.Client? innerClient,
  })  : timeout = timeout ?? const Duration(seconds: 30),
        _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _inner.send(request).timeout(
      timeout,
      onTimeout: () {
        throw const HttpException('이미지 로딩 타임아웃');
      },
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
