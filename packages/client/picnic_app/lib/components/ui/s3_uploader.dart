import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

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
      String folder, dynamic file, Function(double) progressCallback) async {
    late String fileName;
    late int fileLength;
    late Stream<List<int>> fileStream;
    late String contentType;

    if (kIsWeb) {
      if (file is Uint8List) {
        // 웹 환경에서 파일 처리
        fileName = DateTime.now().millisecondsSinceEpoch.toString();
        fileLength = file.length;
        fileStream = Stream.fromIterable([file]);
        contentType = lookupMimeType(fileName) ?? 'application/octet-stream';
      } else {
        throw Exception('Web environment requires Uint8List file format');
      }
    } else {
      if (file is File) {
        // 모바일/데스크톱 환경에서 파일 처리
        fileName = path.basename(file.path);
        fileLength = await file.length();
        fileStream = file.openRead();
        contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
      } else {
        throw Exception('Native environment requires File object');
      }
    }

    final uri = Uri.parse(
        'https://$bucketName.s3.$region.amazonaws.com/$folder/$fileName');

    final now = DateTime.now().toUtc();
    final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    final dateStamp = DateFormat("yyyyMMdd").format(now);

    final headers = <String, String>{
      'Content-Type': contentType,
      'Content-Length': fileLength.toString(),
      'host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
    };

    final canonicalRequest =
        _createCanonicalRequest('PUT', uri.path, headers, 'UNSIGNED-PAYLOAD');
    final stringToSign =
        _createStringToSign(dateStamp, region, 's3', canonicalRequest, amzDate);
    final signature =
        _calculateSignature(dateStamp, region, 's3', stringToSign);

    headers['Authorization'] =
        _buildAuthorizationHeader(dateStamp, region, 's3', headers, signature);

    final request = http.StreamedRequest('PUT', uri);
    headers.forEach((key, value) => request.headers[key] = value);
    request.contentLength = fileLength;

    var bytesSent = 0;

    // 파일 스트림 처리
    fileStream.listen(
      (List<int> chunk) {
        request.sink.add(chunk);
        bytesSent += chunk.length;
        progressCallback(bytesSent / fileLength);
      },
      onDone: () {
        request.sink.close();
      },
      onError: (error) {
        throw Exception('Error reading file: $error');
      },
    );

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      final url = '$folder/$fileName';
      return url;
    } else {
      throw Exception(
          'Failed to upload file: ${response.statusCode}, ${response.body}');
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
