import 'dart:convert';

import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('Request: ${request.method} ${request.url}');
    request.headers.forEach((key, value) {
      print('$key: $value');
    });

    if (request is http.Request) {
      print('Body: ${request.body}');
    }

    final response = await _inner.send(request);

    print('Response: ${response.statusCode}');
    response.headers.forEach((key, value) {
      print('$key: $value');
    });

    final responseBody = await response.stream.bytesToString();
    print('Body: $responseBody');

    return http.StreamedResponse(
      http.ByteStream.fromBytes(utf8.encode(responseBody)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }
}
