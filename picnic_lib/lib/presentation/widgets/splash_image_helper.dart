import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// Pure logic helper for SplashImage widget.
/// All methods are static and free of widget/state dependencies.
@visibleForTesting
class SplashImageHelper {
  SplashImageHelper._();

  /// Parse a date value from JSON.
  /// Returns null if the value is null, not a non-empty String, or unparseable.
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Parse a version value that may be a num, a numeric String, or null.
  static int? parseVersion(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  /// Resolve an image URL from a CDN URL and/or CDN path.
  /// [cdnUrlValue] takes priority over [cdnPathValue].
  /// [baseCdnUrl] is the base CDN URL (e.g. from Environment.cdnUrl).
  static String? resolveImageUrl(
    dynamic cdnUrlValue,
    dynamic cdnPathValue,
    String baseCdnUrl,
  ) {
    final cdnUrl = cdnUrlValue is String ? cdnUrlValue.trim() : '';
    if (cdnUrl.isNotEmpty) return cdnUrl;

    final cdnPath = cdnPathValue is String ? cdnPathValue.trim() : '';
    if (cdnPath.isEmpty) return null;

    if (cdnPath.startsWith('http://') || cdnPath.startsWith('https://')) {
      return cdnPath;
    }

    final sanitizedBase = baseCdnUrl.endsWith('/')
        ? baseCdnUrl.substring(0, baseCdnUrl.length - 1)
        : baseCdnUrl;

    var sanitizedPath = cdnPath;
    if (sanitizedPath.startsWith(sanitizedBase)) {
      sanitizedPath = sanitizedPath.substring(sanitizedBase.length);
    }
    if (sanitizedPath.startsWith('/')) {
      sanitizedPath = sanitizedPath.substring(1);
    }

    return '$sanitizedBase/$sanitizedPath';
  }

  /// Parse a raw JSON string into splash config fields.
  /// Returns null if parsing fails or the result is invalid.
  /// Returns a map with keys: imageUrl, version, expiresAt, enabled.
  static Map<String, dynamic>? parseSplashConfig(
    String? raw,
    String baseCdnUrl,
  ) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final versionValue =
          decoded['version'] ?? decoded['Version'] ?? decoded['VERSION'];
      final version = parseVersion(versionValue) ?? 1;

      final imageUrl = resolveImageUrl(
        decoded['cdnUrl'] ?? decoded['cdn_url'],
        decoded['cdnPath'] ?? decoded['cdn_path'],
        baseCdnUrl,
      );
      if (imageUrl == null || imageUrl.isEmpty) return null;

      final expiresValue = decoded['expiresAt'] ?? decoded['expires_at'];
      DateTime? expiresAt;
      if (expiresValue is String && expiresValue.isNotEmpty) {
        expiresAt = DateTime.tryParse(expiresValue);
      }

      final enabledValue = decoded['enabled'];
      final enabled = enabledValue is bool ? enabledValue : true;

      return {
        'imageUrl': imageUrl,
        'version': version,
        'expiresAt': expiresAt,
        'enabled': enabled,
      };
    } catch (e, stack) {
      logger.w('스플래시 config 파싱 실패: $e', stackTrace: stack);
      return null;
    }
  }

  /// Check whether a cached platform matches the current platform.
  static bool isPlatformMatch(String? cachedPlatform, String currentPlatform) {
    return cachedPlatform == null ||
        cachedPlatform == 'all' ||
        cachedPlatform == currentPlatform;
  }

  /// Determine whether the status overlay should be shown.
  static bool shouldShowStatus({
    required bool enablePatchCheck,
    required bool isCheckingUpdate,
    required String updateStatus,
    required String? externalStatusMessage,
  }) {
    return (enablePatchCheck &&
            (isCheckingUpdate || updateStatus.isNotEmpty)) ||
        (externalStatusMessage != null && externalStatusMessage.isNotEmpty);
  }

  /// Determine the current status message to display.
  /// External message takes priority over internal update status.
  static String resolveStatusMessage({
    required String? externalStatusMessage,
    required String updateStatus,
  }) {
    return externalStatusMessage ?? updateStatus;
  }

  /// Check if a splash image data entry is expired based on its endDate.
  static bool isExpired(DateTime? endDate, {DateTime? now}) {
    if (endDate == null) return false;
    return endDate.isBefore(now ?? DateTime.now());
  }
}
