import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure helper utilities for PushTokenService.
///
/// All methods are static, pure, and have no platform/Flutter/Supabase
/// dependencies, making them easy to unit test independently.
@visibleForTesting
class PushTokenHelper {
  // ---------------------------------------------------------------------------
  // Token validation
  // ---------------------------------------------------------------------------

  /// Returns `true` if [token] is non-null and non-empty.
  static bool isTokenValid(String? token) {
    return token != null && token.isNotEmpty;
  }

  /// Returns `true` if two tokens differ (i.e. a refresh is meaningful).
  /// A `null` or empty old token always counts as "changed".
  static bool hasTokenChanged(String? oldToken, String? newToken) {
    if (oldToken == null || oldToken.isEmpty) return true;
    if (newToken == null || newToken.isEmpty) return false;
    return oldToken != newToken;
  }

  // ---------------------------------------------------------------------------
  // Token preview formatting
  // ---------------------------------------------------------------------------

  /// Returns a privacy-safe preview of [token] for logging.
  ///
  /// - `null` token  -> `'null'`
  /// - length <= 12   -> full token
  /// - length > 12    -> first 12 chars + `'...'`
  static String tokenPreview(String? token) {
    if (token == null) return 'null';
    if (token.length > 12) return '${token.substring(0, 12)}...';
    return token;
  }

  // ---------------------------------------------------------------------------
  // Platform string
  // ---------------------------------------------------------------------------

  /// Maps a platform name to the string sent in the registration payload.
  ///
  /// Accepted inputs: `'ios'`, `'android'`, `'macos'`, `'windows'`.
  /// Everything else (including `'linux'`, `'web'`, `'fuchsia'`) returns `'web'`.
  static String platformString(String platformName) {
    switch (platformName) {
      case 'ios':
        return 'ios';
      case 'android':
        return 'android';
      case 'macos':
        return 'macos';
      case 'windows':
        return 'windows';
      default:
        return 'web';
    }
  }

  // ---------------------------------------------------------------------------
  // App language resolution
  // ---------------------------------------------------------------------------

  /// Resolves the language code to send with the push-token registration.
  ///
  /// Priority:
  /// 1. [appLanguage] from LocaleService (if non-empty).
  /// 2. Parsed from [deviceLocaleName] (e.g. `'ko_KR'`, `'en_US'`).
  /// 3. Fallback `'en'`.
  ///
  /// Traditional-Chinese variants (`zh-TW`, `zh_TW`, `zh_HK`, `zh-HK`,
  /// anything containing `'hant'`) are normalised to `'zh-TW'`.
  static String resolveAppLanguage(String appLanguage, String deviceLocaleName) {
    try {
      // 1. App language
      if (appLanguage.isNotEmpty) {
        if (appLanguage == 'zh-TW' || appLanguage == 'zh_TW') {
          return 'zh-TW';
        }
        return appLanguage.toLowerCase();
      }

      // 2. Device locale fallback
      if (deviceLocaleName.isEmpty) return 'en';

      final lowerName = deviceLocaleName.toLowerCase();
      if (lowerName.startsWith('zh_tw') ||
          lowerName.startsWith('zh-tw') ||
          lowerName.startsWith('zh_hk') ||
          lowerName.startsWith('zh-hk') ||
          lowerName.contains('hant')) {
        return 'zh-TW';
      }

      final parts = deviceLocaleName.split(RegExp(r'[_-]'));
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].toLowerCase();
      }

      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  // ---------------------------------------------------------------------------
  // Notification payload construction
  // ---------------------------------------------------------------------------

  /// Builds the string payload stored in a local notification.
  ///
  /// If [data] contains an `action_url` key the payload is
  /// `'action_url: <url>'`; otherwise it falls back to `data.toString()`.
  /// Returns `null` when [data] is `null`.
  static String? buildNotificationPayload(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data.containsKey('action_url')) {
      return 'action_url: ${data['action_url']}';
    }
    return data.toString();
  }

  // ---------------------------------------------------------------------------
  // Action URL extraction
  // ---------------------------------------------------------------------------

  /// Extracts the first HTTP(S) URL from a local-notification [payload].
  ///
  /// The payload format produced by [buildNotificationPayload] is
  /// `"action_url: https://..."`.  This method will also match any URL
  /// embedded in a stringified map.
  ///
  /// Returns `null` when no URL is found or the payload is empty/null.
  static String? extractActionUrl(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    if (!payload.contains('action_url')) return null;
    final match = RegExp(r'https?://[^\s}]+').firstMatch(payload);
    return match?.group(0);
  }

  // ---------------------------------------------------------------------------
  // Foreground notification fields
  // ---------------------------------------------------------------------------

  /// Resolves the notification title from [notificationTitle] (from
  /// `RemoteMessage.notification?.title`) and [dataTitle] (from
  /// `RemoteMessage.data['title']`).
  ///
  /// Falls back to `'(no-title)'`.
  static String resolveNotificationTitle(
    String? notificationTitle,
    String? dataTitle,
  ) {
    return notificationTitle ?? dataTitle ?? '(no-title)';
  }

  /// Resolves the notification body from [notificationBody] and [dataBody].
  /// Falls back to empty string.
  static String resolveNotificationBody(
    String? notificationBody,
    String? dataBody,
  ) {
    return notificationBody ?? dataBody ?? '';
  }

  /// Returns `true` when a foreground notification should be displayed.
  ///
  /// The notification is shown when the title is not the fallback and the
  /// body is non-empty.
  static bool shouldShowForegroundNotification(String title, String body) {
    return title != '(no-title)' && body.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Notification ID generation
  // ---------------------------------------------------------------------------

  /// Generates a notification ID from a [DateTime] (deterministic for testing).
  ///
  /// Uses `millisecondsSinceEpoch % 100000` to keep the value within Android's
  /// 32-bit int limit.
  static int generateNotificationId(DateTime timestamp) {
    return timestamp.millisecondsSinceEpoch.remainder(100000);
  }

  // ---------------------------------------------------------------------------
  // Registration response classification
  // ---------------------------------------------------------------------------

  /// Returns `true` when the Edge Function response [statusCode] indicates
  /// a successful registration (i.e. < 300).
  static bool isRegistrationSuccess(int statusCode) {
    return statusCode < 300;
  }

  // ---------------------------------------------------------------------------
  // Error classification
  // ---------------------------------------------------------------------------

  /// Classifies an error into a human-readable category for logging.
  ///
  /// Known categories:
  /// - `'timeout'` for [TimeoutException]-like type names
  /// - `'network'` for `SocketException`
  /// - `'auth'` for function errors with status 401
  /// - `'function_error'` for other function errors
  /// - `'unknown'` otherwise
  static String classifyError(String errorTypeName, {int? statusCode}) {
    final lower = errorTypeName.toLowerCase();
    if (lower.contains('timeout')) return 'timeout';
    if (lower.contains('socket')) return 'network';
    if (lower.contains('function')) {
      if (statusCode == 401) return 'auth';
      return 'function_error';
    }
    return 'unknown';
  }

  /// Returns `true` when the error is retriable.
  ///
  /// Timeout and auth (401) errors trigger a single retry in the service.
  static bool isRetriableError(String errorCategory) {
    return errorCategory == 'timeout' || errorCategory == 'auth';
  }

  // ---------------------------------------------------------------------------
  // Registration payload construction
  // ---------------------------------------------------------------------------

  /// Builds the JSON body sent to the `register-push-token` Edge Function.
  static Map<String, dynamic> buildRegistrationPayload({
    required String platform,
    required String token,
    required String deviceLocale,
  }) {
    return {
      'platform': platform,
      'token': token,
      'device_locale': deviceLocale,
    };
  }

  /// Builds the Authorization header map for the Edge Function call.
  static Map<String, String> buildAuthHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }
}
