/// Pure logic helpers extracted from [AppInitializer] for testability.
///
/// All methods are static and side-effect free.
class AppInitializerHelper {
  /// Determines whether a Sentry event should be filtered (dropped).
  ///
  /// Returns `true` if the event should be discarded (not sent to Sentry).
  /// This mirrors the `beforeSend` filter logic in [AppInitializer.initializeSentry].
  ///
  /// [sentryEnabled] - whether Sentry is globally enabled.
  /// [isDebugMode] - whether the app is running in debug mode.
  /// [exceptionType] - the exception type string (e.g. 'HTTPClientError').
  /// [exceptionValue] - the exception value/message string.
  static bool shouldFilterSentryEvent({
    required bool sentryEnabled,
    required bool isDebugMode,
    required String exceptionType,
    required String exceptionValue,
  }) {
    // Drop everything when Sentry is disabled or in debug mode
    if (!sentryEnabled || isDebugMode) {
      return true;
    }

    // Network/infra noise filtering (user environment issues)
    const networkNoiseTypes = {
      'HTTPClientError',
      'NetworkError',
      'ClientException',
      'OSError',
      'AuthRetryableFetchException',
    };
    if (networkNoiseTypes.contains(exceptionType)) {
      return true;
    }

    // Supabase SDK internal TypeError (PICNIC-APP-T2)
    if (exceptionType == 'TypeError' &&
        exceptionValue.contains('Null check operator used on a null value')) {
      return true;
    }

    // Ad SDK noise filtering
    const adNoiseTypes = {'LoadAdError', 'AdError'};
    if (adNoiseTypes.contains(exceptionType)) {
      return true;
    }
    if (exceptionType == 'String' &&
        (exceptionValue.contains('광고 로드 실패') ||
            exceptionValue.contains('광고 로드 시간 초과'))) {
      return true;
    }

    // Edge Function 502 Bad Gateway
    if (exceptionType == 'FunctionException' &&
        exceptionValue.contains('502')) {
      return true;
    }

    // RLS policy violation noise (PICNIC-APP-47)
    if (exceptionType == 'PostgrestException' &&
        exceptionValue.contains('row-level security policy')) {
      return true;
    }

    // Supabase 502 Bad Gateway (PICNIC-APP-47)
    if (exceptionType == 'PostgrestException' &&
        (exceptionValue.contains('DOCTYPE') ||
            exceptionValue.contains('502'))) {
      return true;
    }

    // JWT expired (PICNIC-APP-47R)
    if (exceptionType == 'PostgrestException' &&
        exceptionValue.contains('JWT expired')) {
      return true;
    }

    // Android Keystore BAD_DECRYPT (PICNIC-APP-B8)
    if (exceptionType == 'PlatformException' &&
        exceptionValue.contains('BAD_DECRYPT')) {
      return true;
    }

    return false;
  }

  /// Checks whether a deep link URL should be treated as a duplicate
  /// of a recently-handled link.
  ///
  /// Returns `true` if [url] matches [lastUrl] and the time elapsed since
  /// [lastTime] is less than [threshold] (default 2 seconds).
  static bool isDuplicateDeepLink({
    required String url,
    required String? lastUrl,
    required DateTime? lastTime,
    required DateTime now,
    Duration threshold = const Duration(milliseconds: 2000),
  }) {
    if (lastUrl != url) return false;
    if (lastTime == null) return false;
    return now.difference(lastTime).inMilliseconds < threshold.inMilliseconds;
  }

  /// Parses a deep link URL and returns structured route information.
  ///
  /// Returns `null` for invalid or empty URLs.
  /// Otherwise returns a map with:
  /// - `portal`: first path segment (e.g. 'vote', 'community', 'notice')
  /// - `page`: second path segment (e.g. 'detail', 'list', 'home')
  /// - `id`: third path segment if present (e.g. vote ID, artist ID)
  /// - `queryParams`: all query parameters
  static DeepLinkParseResult? parseDeepLinkUrl(String url) {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return null;
    }

    if (uri.pathSegments.isEmpty) return null;

    final portal = uri.pathSegments[0];
    final page = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    final id = uri.pathSegments.length > 2 ? uri.pathSegments[2] : null;
    final queryParams = uri.queryParameters;

    return DeepLinkParseResult(
      portal: portal,
      page: page,
      id: id,
      queryParams: queryParams,
    );
  }

  /// Calculates remaining splash screen wait time.
  ///
  /// Returns [Duration.zero] if [elapsed] >= [minDuration].
  static Duration calculateSplashRemainingTime({
    required Duration elapsed,
    required Duration minDuration,
  }) {
    if (elapsed >= minDuration) return Duration.zero;
    return minDuration - elapsed;
  }
}

/// Result of [AppInitializerHelper.parseDeepLinkUrl].
class DeepLinkParseResult {
  final String portal;
  final String? page;
  final String? id;
  final Map<String, String> queryParams;

  const DeepLinkParseResult({
    required this.portal,
    this.page,
    this.id,
    this.queryParams = const {},
  });
}
