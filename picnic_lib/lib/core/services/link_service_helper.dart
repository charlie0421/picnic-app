import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/services/link_service.dart';

/// Pure helper methods extracted from [LinkService] for testability.
class LinkServiceHelper {
  /// Normalizes a URL by trimming whitespace and adding https:// if no protocol is present.
  @visibleForTesting
  static String normalizeUrl(String url) {
    url = url.trim();
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    return url;
  }

  /// Validates whether a string is a valid URL with an authority component.
  @visibleForTesting
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  /// Builds the request headers map for the link preview API call.
  @visibleForTesting
  static Map<String, String> buildHeaders({
    required String anonKey,
  }) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $anonKey',
      'apikey': anonKey,
    };
  }

  /// Builds the full endpoint URL for the link preview function.
  @visibleForTesting
  static String buildEndpointUrl(String supabaseUrl) {
    return '$supabaseUrl/functions/v1/link-preview';
  }

  /// Parses a successful response body into a [LinkPreview].
  ///
  /// For web responses, if the data contains an 'error' key with a 'fallback' key,
  /// the fallback data is used instead.
  @visibleForTesting
  static LinkPreview parseResponseData(
    Map<String, dynamic> data,
    String url, {
    bool handleFallback = false,
  }) {
    if (handleFallback && data['error'] != null && data['fallback'] != null) {
      final fallback = data['fallback'] as Map<String, dynamic>;
      return LinkPreview.fromJson(fallback, url);
    }
    return LinkPreview.fromJson(data, url);
  }

  /// Validates an HTTP status code and throws appropriate [LinkPreviewException]
  /// for error codes.
  ///
  /// Returns normally if status code is 200.
  @visibleForTesting
  static void validateStatusCode(int statusCode) {
    if (statusCode == 401) {
      throw LinkPreviewException('Authentication failed', statusCode: 401);
    }
    if (statusCode != 200) {
      throw LinkPreviewException(
        'Failed to fetch preview',
        statusCode: statusCode,
      );
    }
  }

  /// Wraps an arbitrary exception as a [LinkPreviewException].
  /// If the exception is already a [LinkPreviewException], it is returned as-is.
  @visibleForTesting
  static LinkPreviewException wrapException(Object error) {
    if (error is LinkPreviewException) {
      return error;
    }
    return LinkPreviewException(error.toString());
  }
}
