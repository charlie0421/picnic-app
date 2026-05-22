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
    List<String> stackFrameFunctions = const [],
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
      'HttpException',
      'SocketException',
      'HandshakeException', // TLS handshake failures (captive portal/MITM)
      'TlsException',
      'AuthRetryableFetchException',
    };
    if (networkNoiseTypes.contains(exceptionType)) {
      return true;
    }

    // Wrapped network/transport noise patterns — used by both
    // FunctionException and PostgrestException blocks below. The actual
    // wire-level error (timeout, DNS, TCP reset) is rendered into the
    // wrapping exception's message body, so the exact-type filter above
    // misses them.
    bool isWrappedNetworkNoise(String v) =>
        v.contains('NetworkError') ||
        v.contains('SocketException') ||
        v.contains('HandshakeException') ||
        v.contains('Failed host lookup') ||
        v.contains('Connection closed') ||
        v.contains('Connection reset') ||
        v.contains('Connection terminated') ||
        v.contains('TimeoutException') || // PICNIC-APP-4ZX: 30s request timeout
        v.contains('Software caused connection abort') || // Android net swap
        v.contains('Connection abort') ||
        v.contains('Connection failed') ||
        v.contains('Network is unreachable');

    // Soft-deleted account signal — handled reactively by
    // AccountDeletionHandler (sign-out side effect fires from beforeSend).
    // Drop the Sentry event so it does not flood as noise on every Edge
    // Function call before the sign-out completes (PICNIC-APP-4ZY in 1.2.28+).
    if (exceptionType == 'FunctionException' &&
        exceptionValue.contains('ACCOUNT_DELETED')) {
      return true;
    }

    // Email-unverified signup — Edge Function returns 403 + SIGNUP_UNVERIFIED
    // for users who haven't completed email verification (e.g. ad_shortform
    // reward gating). It's a business-rule signal handled by the UI, not a
    // bug (PICNIC-APP-4EN: 322 users / 868 events).
    if (exceptionType == 'FunctionException' &&
        exceptionValue.contains('SIGNUP_UNVERIFIED')) {
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

    // String-typed wrapping of typed exceptions
    // (PICNIC-APP-3R: PostgrestException + Failed host lookup,
    //  PICNIC-APP-4RP: AuthRetryableFetchException + HandshakeException).
    // Some code path stringifies the typed exception before re-throwing or
    // before passing to FlutterError.onError. The wire-level error is still
    // embedded in the message, so reuse the same wrapped-network patterns.
    if (exceptionType == 'String' && isWrappedNetworkNoise(exceptionValue)) {
      return true;
    }

    // Edge Function transient gateway errors (502/503/504)
    // 503 SUPABASE_EDGE_RUNTIME_ERROR is a Supabase platform-side outage
    // signal, not a picnic bug (PICNIC-APP-4ZY/4ZX/4EN).
    if (exceptionType == 'FunctionException' &&
        (exceptionValue.contains('502') ||
            exceptionValue.contains('503') ||
            exceptionValue.contains('504') ||
            exceptionValue.contains('SUPABASE_EDGE_RUNTIME_ERROR'))) {
      return true;
    }

    // Edge Function wrapping a user-side network drop / timeout
    // (PICNIC-APP-4ZX, 4ZY). supabase_flutter throws FunctionException with
    // status=500 and the underlying transport error (TimeoutException /
    // SocketException / Connection reset / Network is unreachable / etc.)
    // rendered into the details body. The status-based filter above only
    // catches gateway-side 5xx; this block catches client-side network noise.
    if (exceptionType == 'FunctionException' &&
        isWrappedNetworkNoise(exceptionValue)) {
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

    // Postgrest wrapping a user-side network drop / timeout (PICNIC-APP-47).
    // The wire-level error is rendered into the message, not the type, so
    // exact-type filters above miss it. Drop these as user-environment noise.
    if (exceptionType == 'PostgrestException' &&
        isWrappedNetworkNoise(exceptionValue)) {
      return true;
    }

    // Android Keystore BAD_DECRYPT (PICNIC-APP-B8)
    if (exceptionType == 'PlatformException' &&
        exceptionValue.contains('BAD_DECRYPT')) {
      return true;
    }

    // sqflite cache DB 가 사용자 단말 환경 때문에 실패하는 케이스 (PICNIC-APP-547/52R/52S).
    // - SQLITE_FULL / 'disk is full' : 디스크 거의 0. cache_store 의 image cache 쓰기 실패.
    // - 'unable to open database file' : iOS sandbox/권한/디스크 문제 (iPhone 7 등 old device).
    // 모두 사용자 storage 상태 문제이고 앱이 cache 누락 으로 graceful degrade 됨 — 노이즈.
    if (exceptionType == 'SqfliteDatabaseException' &&
        (exceptionValue.contains('SQLITE_FULL') ||
            exceptionValue.contains('disk is full') ||
            exceptionValue.contains('unable to open database file'))) {
      return true;
    }

    // Image picker double-tap (PICNIC-APP-VQ).
    // Plugin throws when the picker is invoked while a previous instance is
    // still mounted — pure UX noise, no app-side fix needed.
    if (exceptionType == 'PlatformException' &&
        exceptionValue.contains('already_active') &&
        exceptionValue.contains('Image picker')) {
      return true;
    }

    // PKCE OAuth flow: code verifier missing in local storage (PICNIC-APP-504).
    // Happens when the app is killed mid-OAuth or storage is cleared between
    // launch and callback. Self-heals on next sign-in attempt.
    if (exceptionType == 'AuthException' &&
        exceptionValue.contains('Code verifier could not be found')) {
      return true;
    }

    // Supabase refresh token rotation noise (PICNIC-APP-4GW / 56J).
    // - "Invalid Refresh Token: Already Used" — token rotation race; SDK
    //   auto-recovers by re-fetching the session.
    // - "Refresh Token Not Found" — session stale (logout elsewhere /
    //   reinstall); user is signed out and re-prompted to log in.
    // Both are transient self-recovering states, not actionable bugs.
    if (exceptionType == 'AuthApiException' &&
        (exceptionValue.contains('Invalid Refresh Token: Already Used') ||
            exceptionValue.contains('Refresh Token Not Found'))) {
      return true;
    }

    // User is banned (어드민 정책 차단) — UI 가 차단 안내 후 흐름 종료하는
    // 정상 응답. 차단 사용자가 재로그인을 시도할 때마다 누적 (PICNIC-APP-4RJ).
    if (exceptionType == 'AuthApiException' &&
        (exceptionValue.contains('User is banned') ||
            exceptionValue.contains('user_banned'))) {
      return true;
    }

    // Auth session missing — refreshSession() 호출 시 세션이 없는 정상 상태.
    // attendance 등 인증 필요 API 에서 401/403 → 세션 갱신 시도 → 세션 부재로
    // 401 → 사용자에게 재로그인 안내하는 self-healing 흐름의 일부 (PICNIC-APP-508).
    if (exceptionType == 'AuthSessionMissingException') {
      return true;
    }

    // App Hanging / ANR 의 stack 에 광고 SDK frame 이 있는 경우 — Pangle/
    // Tapjoy/AdMob/Branch SDK 가 main thread 를 차단하는 케이스. 우리가 직접
    // 호출하는 코드 경로가 아닌 SDK 내부 main loop / lifecycle 콜백에서 발생.
    // 우리 코드 자체의 hang 은 그대로 추적해야 하므로 stack 매칭 기반으로
    // 정확히 광고 SDK culprit 만 drop.
    if ((exceptionType == 'App Hanging' ||
            exceptionType == 'ApplicationNotResponding') &&
        _hasAdSdkFrame(stackFrameFunctions)) {
      return true;
    }

    return false;
  }

  /// 광고 SDK 의 internal frame prefix 매칭 — App Hanging/ANR culprit 검사용.
  static bool _hasAdSdkFrame(List<String> frames) {
    const adSdkPatterns = [
      'PAG', // Pangle (TikTok ByteDance SDK) - PAGWebView/PAGLBase/PAGDevice
      'GAD_', // Google AdMob native helpers (GAD_GADAudioSession 등)
      'GADAudio',
      'GADRewarded',
      'GADInterstitial',
      'Tapjoy',
      'TJPlacement',
      'Branch', // Branch SDK (BranchLogger, BranchSDK 등)
      'bytedance', // Pangle internal modules
    ];
    for (final fn in frames) {
      for (final pattern in adSdkPatterns) {
        if (fn.contains(pattern)) return true;
      }
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
