import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/link_service_helper.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class LinkPreviewException implements Exception {
  final String message;
  final int? statusCode;

  LinkPreviewException(this.message, {this.statusCode});

  @override
  String toString() =>
      'LinkPreviewException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class LinkPreview {
  final String title;
  final String description;
  final String? imageUrl;
  final String? favicon;
  final String url;

  LinkPreview({
    required this.title,
    required this.description,
    this.imageUrl,
    this.favicon,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'favicon': favicon,
      'url': url,
    };
  }

  @override
  String toString() {
    return 'LinkPreview{title: $title, description: $description, imageUrl: $imageUrl, favicon: $favicon, url: $url}';
  }

  factory LinkPreview.fromJson(Map<String, dynamic> json, String originalUrl) {
    return LinkPreview(
      title: json['title'] ?? Uri.parse(originalUrl).host,
      description: json['description'] ?? 'Click to visit the website',
      imageUrl: json['image'] ?? json['imageUrl'],
      favicon: json['favicon'],
      url: originalUrl,
    );
  }

  factory LinkPreview.fallback(String url) {
    return LinkPreview(
      title: Uri.parse(url).host,
      description: 'Click to visit the website',
      url: url,
    );
  }
}

class LinkService {
  static final LinkService _instance = LinkService._internal();
  static const timeout = Duration(seconds: 10);

  factory LinkService() => _instance;

  LinkService._internal();

  String normalizeUrl(String url) =>
      LinkServiceHelper.normalizeUrl(url);

  bool isValidUrl(String url) {
    try {
      return LinkServiceHelper.isValidUrl(url);
    } catch (e, s) {
      logger.e('Error', error: e, stackTrace: s);
      return false;
    }
  }

  Map<String, String> _getHeaders() {
    return LinkServiceHelper.buildHeaders(
      anonKey: Environment.supabaseAnonKey,
    );
  }

  Future<LinkPreview> fetchLinkPreview(String rawUrl) async {
    final url = normalizeUrl(rawUrl);
    debugPrint('Normalized URL: $url');

    if (!isValidUrl(url)) {
      throw LinkPreviewException('Invalid URL format');
    }

    try {
      return kIsWeb
          ? await _fetchLinkPreviewWeb(url)
          : await _fetchLinkPreviewNative(url);
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);
      debugPrint('Error fetching link preview: $e');
      throw LinkServiceHelper.wrapException(e);
    }
  }

  Future<LinkPreview> _fetchLinkPreviewWeb(String url) async {
    final endpoint = LinkServiceHelper.buildEndpointUrl(Environment.supabaseUrl);
    debugPrint('Fetching from web endpoint: $endpoint');

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _getHeaders(),
            body: json.encode({'url': url}),
          )
          .timeout(timeout);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      LinkServiceHelper.validateStatusCode(response.statusCode);

      final data = json.decode(response.body);
      return LinkServiceHelper.parseResponseData(data, url, handleFallback: true);
    } on http.ClientException catch (e) {
      debugPrint('HTTP client error: $e');
      throw LinkPreviewException('Network error: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      throw LinkPreviewException('Request timed out');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return LinkPreview.fallback(url);
    }
  }

  Future<LinkPreview> _fetchLinkPreviewNative(String url) async {
    final endpoint = LinkServiceHelper.buildEndpointUrl(Environment.supabaseUrl);
    debugPrint('Fetching from native endpoint: $endpoint');

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _getHeaders(),
            body: json.encode({'url': url}),
          )
          .timeout(timeout);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      LinkServiceHelper.validateStatusCode(response.statusCode);

      final data = json.decode(response.body);
      return LinkServiceHelper.parseResponseData(data, url);
    } on http.ClientException catch (e, s) {
      logger.e('Error', error: e, stackTrace: s);
      throw LinkPreviewException('Network error: ${e.message}');
    } on TimeoutException catch (e, s) {
      logger.e('Error', error: e, stackTrace: s);
      throw LinkPreviewException('Request timed out');
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);
      return LinkPreview.fallback(url);
    }
  }
}
