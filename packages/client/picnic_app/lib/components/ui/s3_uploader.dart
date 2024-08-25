import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class S3Uploader {
  final String accessKey;
  final String secretKey;
  final String region;
  final String bucketName;

  S3Uploader({
    required this.accessKey,
    required this.secretKey,
    required this.region,
    required this.bucketName,
  });

  Future<String> uploadFile(
      File file, Function(double) progressCallback) async {
    final fileName = path.basename(file.path);
    final uri = Uri.parse(
        'https://$bucketName.s3.$region.amazonaws.com/uploads/$fileName');
    final fileLength = await file.length();

    final now = DateTime.now().toUtc();
    final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    final dateStamp = DateFormat("yyyyMMdd").format(now);

    final headers = <String, String>{
      'Content-Type': 'application/octet-stream',
      'host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
    };

    final canonicalRequest =
        _createCanonicalRequest('PUT', uri.path, headers, 'UNSIGNED-PAYLOAD');
    print('Canonical Request: $canonicalRequest');

    final stringToSign =
        _createStringToSign(dateStamp, region, 's3', canonicalRequest, amzDate);
    print('String to Sign: $stringToSign');

    final signature =
        _calculateSignature(dateStamp, region, 's3', stringToSign);
    print('Calculated Signature: $signature');

    headers['Authorization'] =
        _buildAuthorizationHeader(dateStamp, region, 's3', headers, signature);
    print('Authorization Header: ${headers['Authorization']}');

    try {
      final request = http.StreamedRequest('PUT', uri);
      headers.forEach((key, value) => request.headers[key] = value);
      request.contentLength = fileLength;

      var bytesSent = 0;
      final inputStream = file.openRead();
      final transformedStream = inputStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            progressCallback(bytesSent / fileLength);
            sink.add(data);
          },
        ),
      );

      unawaited(request.sink
          .addStream(transformedStream)
          .then((_) => request.sink.close()));

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        print('File uploaded successfully');
        return 'https://$bucketName.s3.$region.amazonaws.com/uploads/$fileName';
      } else {
        print('Error Response: ${response.body}');
        throw Exception(
            'Failed to upload file: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  String _createCanonicalRequest(String method, String uri,
      Map<String, String> headers, String payloadHash) {
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}\n')
        .toList()
      ..sort();
    final signedHeaders = headers.keys.map((e) => e.toLowerCase()).toList()
      ..sort();
    final signedHeadersString = signedHeaders.join(';');

    return '$method\n$uri\n\n${canonicalHeaders.join()}\n$signedHeadersString\n$payloadHash';
  }

  String _createStringToSign(String dateStamp, String region, String service,
      String canonicalRequest, String amzDate) {
    final credential = '$dateStamp/$region/$service/aws4_request';
    final hash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    return 'AWS4-HMAC-SHA256\n$amzDate\n$credential\n$hash';
  }

  String _calculateSignature(
      String dateStamp, String region, String service, String stringToSign) {
    final kDate = Hmac(sha256, utf8.encode('AWS4$secretKey'))
        .convert(utf8.encode(dateStamp));
    final kRegion = Hmac(sha256, kDate.bytes).convert(utf8.encode(region));
    final kService = Hmac(sha256, kRegion.bytes).convert(utf8.encode(service));
    final kSigning =
        Hmac(sha256, kService.bytes).convert(utf8.encode('aws4_request'));
    return Hmac(sha256, kSigning.bytes)
        .convert(utf8.encode(stringToSign))
        .toString();
  }

  String _buildAuthorizationHeader(String dateStamp, String region,
      String service, Map<String, String> headers, String signature) {
    final credential = '$accessKey/$dateStamp/$region/$service/aws4_request';
    final signedHeaders = headers.keys.map((e) => e.toLowerCase()).toList()
      ..sort();
    final signedHeadersString = signedHeaders.join(';');
    return 'AWS4-HMAC-SHA256 Credential=$credential,SignedHeaders=$signedHeadersString,Signature=$signature';
  }
}
