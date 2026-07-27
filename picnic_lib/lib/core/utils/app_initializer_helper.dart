/// Pure logic helpers extracted from [AppInitializer] for testability.
///
/// All methods are static and side-effect free.
class AppInitializerHelper {
  /// Sentry 가 [FlutterErrorDetails.silent] 프레임워크 에러를 리포팅할지 여부
  /// (`SentryFlutterOptions.reportSilentFlutterErrors` 로 그대로 들어간다).
  ///
  /// **false = 리포팅하지 않는다. 의도된 결정이다.**
  ///
  /// 상수로 빼 둔 이유는 이 값이 정책 결정이기 때문이다 — 프로덕션
  /// (`AppInitializer.initializeSentry`) 과 이 결정을 고정한 테스트
  /// (`app_initializer_global_error_handling_test.dart`) 가 같은 상수를 읽으므로,
  /// true 로 뒤집는 순간 테스트가 빨개진다.
  ///
  /// ## 왜 리포팅하지 않는가
  ///
  /// `silent` 는 "프레임워크가 스스로 노이즈라고 표시한 에러" 다. 이 앱에서
  /// 이 플래그를 다는 실질적 생산자는 이미지 파이프라인 하나뿐이다 —
  /// `MultiFrameImageStreamCompleter` 의 codec/chunk/frame 실패
  /// (`image_stream.dart:910,985,998,1085`) 와 `ImageProvider.resolve` 실패
  /// (`image_provider.dart:403`, 프레임워크 주석부터가
  /// `silent: true, // could be a network error or whatnot`). 즉 CDN/네트워크/
  /// 디스크 같은 사용자 환경 문제이고, 앱은 placeholder 로 graceful degrade
  /// 한다. 우리가 고칠 코드가 없다.
  ///
  /// 게다가 이건 [shouldFilterSentryEvent] 가 이미 걷어내고 있는 바로 그
  /// 부류다 — `ClientException`/`SocketException`/`HandshakeException`/
  /// `Failed host lookup`/`TimeoutException`, 그리고 `SqfliteDatabaseException`
  /// 의 "cache_store 의 image cache 쓰기 실패"(PICNIC-APP-547/52R/52S)까지.
  /// silent 를 리포팅하지 않는 것은 그 정책의 일반화이지 예외가 아니다.
  /// 반대로 `NetworkImageLoadException` 같은 타입은 그 어떤 필터 규칙에도
  /// 걸리지 않으므로, 켜 두면 CDN 장애 때 사용자 × 실패 이미지 수만큼
  /// 무필터로 쌓인다 (앱 전반이 `CachedNetworkImage` 기반이다).
  ///
  /// ## 무엇을 잃는가 (정직하게)
  ///
  /// release 빌드에서 이미지 로드 실패의 관측 수단이 **전부** 사라진다.
  /// Sentry 이벤트가 없고, `FlutterError.dumpErrorToConsole` 은 release 에서
  /// silent 를 건너뛰며, `logger` 의 `DevelopmentFilter` 는 release 에서 모든
  /// 로그를 버린다. debug 빌드에서는 콘솔에 그대로 다 보인다.
  ///
  /// 그 대가를 감수하는 이유: CDN 가용성은 CDN/uptime 모니터링이 볼 문제이지
  /// crash reporting 쿼터로 살 신호가 아니다. 필요해지면 이 상수 하나만
  /// true 로 바꾸면 되고, 그때는 `shouldFilterSentryEvent` 에 이미지 전용
  /// 필터를 함께 넣는 편이 낫다.
  ///
  /// 참고: 이 상수는 Sentry 리포팅만 통제한다. 프레임워크 기본 핸들러
  /// (`FlutterError.presentError`) 와 우리 `logger.e` 는 silent 여부와 무관하게
  /// 항상 호출된다 — `AppInitializer.initializeGlobalErrorHandling` 참조.
  static const bool reportSilentFlutterErrors = false;

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
    List<bool> stackFrameInApp = const [],
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

    // Supabase refresh token 회전/만료 노이즈 (PICNIC-APP-4GW / 56J).
    // 모든 변형을 케이스-무관하게 포섭:
    // - "Invalid Refresh Token: Already Used" (refresh_token_already_used)
    //   — token rotation race; SDK 가 세션 재발급으로 자가복구.
    // - "Refresh Token Not Found" (refresh_token_not_found)
    //   — 세션 stale(다른 기기 로그아웃/재설치); 재로그인 안내.
    // - "Refresh token is not valid" (validation_failed)
    //   — 실제 4GW 최신 시그니처(400). 위 리터럴 매칭에서 새던 변형.
    // 전부 transient·self-recovering 상태이지 actionable 버그가 아니다.
    if (exceptionType == 'AuthApiException' &&
        exceptionValue.toLowerCase().contains('refresh token')) {
      return true;
    }

    // Auth rate limit (PICNIC-APP-4RJ). GoTrue/anti-abuse 가 로그인·가입 시도
    // 폭주에 429 를 반환하는 정상 rate-limit ("가입 시도가 너무 많습니다.
    // 잠시 후 다시 시도해주세요."). self-recovering. statusCode 매칭이라
    // 메시지 로케일(번역)과 무관하게 견고하며, 429 auth 는 항상 rate-limit 이라
    // 진짜 인증 버그를 가릴 위험이 없다.
    if (exceptionType == 'AuthApiException' &&
        exceptionValue.contains('statusCode: 429')) {
      return true;
    }

    // User is banned (어드민 정책 차단) — UI 가 차단 안내 후 흐름 종료하는
    // 정상 응답. 차단 사용자가 재로그인을 시도할 때마다 누적.
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

    // NOTE: all-system ANR (PICNIC-APP-45E) 는 더 이상 여기서 전량 드롭하지
    // 않는다. [isAllSystemAnr] 로 분류만 하고, 실제 드롭/샘플 유지는
    // AppInitializer.beforeSend 에서 [shouldSampleKeep] 로 ~10% 만 남긴다.
    // 심볼화 불가한 OS 사후(AppExitInfo) ANR 이지만 route/current_screen 태그가
    // 붙어 화면별 분류가 가능해졌고, 전량 드롭하면 볼륨 측정 자체가 불가하기
    // 때문. 우리 코드 frame 이 있는 ANR 은 애초에 all-system 이 아니라 그대로
    // 통과된다.

    return false;
  }

  /// all-system ANR 판별 — 우리 코드 frame 이 stack 에 단 한 개도 없는
  /// [ApplicationNotResponding] (mechanism=AppExitInfo 로 Android OS 가 사후
  /// 보고하는, stack 이 전부 Looper/nativePollOnce/pollInner 인 ANR).
  /// PICNIC-APP-45E. 심볼화 불가라 route/screen 태그로만 유의미하며, drop 여부는
  /// 호출측(beforeSend)이 [shouldSampleKeep] 로 결정한다.
  ///
  /// [stackFrameInApp] 가 비어 있으면(정보 부족) false — 보수적으로 all-system
  /// 으로 단정하지 않는다.
  static bool isAllSystemAnr(
    String exceptionType,
    List<bool> stackFrameInApp,
  ) {
    return exceptionType == 'ApplicationNotResponding' &&
        stackFrameInApp.isNotEmpty &&
        !stackFrameInApp.any((inApp) => inApp);
  }

  /// 결정론적 샘플 게이트. [seed] (예: Sentry event id) 의 안정적 해시를
  /// `[0, 1)` 로 매핑해 [rate] 미만이면 true(유지). `Math.random` 을 쓰지 않아
  /// 순수·테스트 가능하며, seed 가 이벤트마다 달라 대략 [rate] 비율로 유지된다.
  ///
  /// [rate] <= 0 이면 항상 false, [rate] >= 1 이면 항상 true.
  static bool shouldSampleKeep(String seed, double rate) {
    if (rate <= 0) return false;
    if (rate >= 1) return true;
    // FNV-1a 32-bit hash → [0, 1)
    var hash = 0x811c9dc5;
    for (final codeUnit in seed.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final normalized = hash / 0x100000000; // [0, 1)
    return normalized < rate;
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
