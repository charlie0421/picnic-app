import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_app/config/environment.dart';

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

  String normalizeUrl(String url) {
    url = url.trim();
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    return url;
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Environment.supabaseAnonKey}',
      // 필요한 경우 추가 헤더
      'apikey': Environment.supabaseAnonKey,
    };
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
    } catch (e) {
      debugPrint('Error fetching link preview: $e');
      if (e is LinkPreviewException) {
        rethrow;
      }
      throw LinkPreviewException(e.toString());
    }
  }

  Future<LinkPreview> _fetchLinkPreviewWeb(String url) async {
    final endpoint = '${Environment.supabaseUrl}/functions/v1/link-preview';
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

      if (response.statusCode == 401) {
        throw LinkPreviewException('Authentication failed', statusCode: 401);
      }

      if (response.statusCode != 200) {
        throw LinkPreviewException(
          'Failed to fetch preview',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);

      if (data['error'] != null && data['fallback'] != null) {
        debugPrint('Using fallback data');
        final fallback = data['fallback'];
        return LinkPreview.fromJson(fallback, url);
      }

      return LinkPreview.fromJson(data, url);
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
    final endpoint = '${Environment.supabaseUrl}/functions/v1/link-preview';
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

      if (response.statusCode == 401) {
        throw LinkPreviewException('Authentication failed', statusCode: 401);
      }

      if (response.statusCode != 200) {
        throw LinkPreviewException(
          'Failed to fetch preview',
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);
      return LinkPreview.fromJson(data, url);
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
}
