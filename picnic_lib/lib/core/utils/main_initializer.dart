import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/core/utils/firebase_analytics_utils.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';

import 'package:picnic_lib/core/utils/supabase_health_check.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/services/branch_link_service.dart';
import 'package:picnic_lib/core/utils/admob_test_device_policy.dart';

/// Prevents Group 2 from immediately repeating a failed Group 1 UMP attempt.
///
/// This guard has no retry state. Later ad requests call the underlying
/// retryable initializer directly and can therefore make a fresh UMP attempt.
class StartupAdMobInitializationGuard {
  const StartupAdMobInitializationGuard({
    required this.didConsentInitializationFail,
    required this.initializeAdMob,
    this.onSkipped,
  });

  final bool Function() didConsentInitializationFail;
  final Future<bool> Function() initializeAdMob;
  final void Function()? onSkipped;

  Future<bool> initialize() {
    if (didConsentInitializationFail()) {
      onSkipped?.call();
      return Future<bool>.value(false);
    }
    return Future<bool>.sync(initializeAdMob);
  }
}

class _AdMobStartupDeferred implements Exception {
  const _AdMobStartupDeferred();
}

/// main.dart 파일에서 공통으로 사용되는 초기화 로직을 담은 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)의 main.dart 파일에서 중복되는 초기화 로직을
/// 추출하여 재사용성을 높이고 코드 중복을 줄입니다.
class MainInitializer {
  static final StartupReadinessController _sdkReadiness =
      StartupReadinessController();
  static final RetryableStartupStages _sdkStages = RetryableStartupStages();
  static FirebaseOptions? _firebaseOptions;
  static final RetryableAdMobInitializer _adMobInitializer =
      RetryableAdMobInitializer(initialize: _initializeAdMobAttempt);
  static final StartupAdMobInitializationGuard _startupAdMobInitializer =
      StartupAdMobInitializationGuard(
        didConsentInitializationFail: () => ConsentService().lastAttemptFailed,
        initializeAdMob: _adMobInitializer.initialize,
        onSkipped: () {
          logger.w('AdMob 스타트업 초기화 보류: Group 1 UMP 시도 실패');
        },
      );
  static final AdRequestReadinessGate _adRequestGate = AdRequestReadinessGate(
    waitForAdMob: _adMobInitializer.waitForReady,
    canRequestAds: ConsentService().canRequestAds,
  );

  /// SDK 초기화의 명시적인 성공/실패 결과를 대기하는 Future
  /// App 위젯에서 await MainInitializer.sdkReady 로 사용
  static Future<StartupReadinessResult> get sdkReady => _sdkReadiness.ready;

  /// Retries only failed SDK stages and joins any authentic work still running.
  static Future<StartupReadinessResult> retrySdkInitialization() =>
      _sdkReadiness.run(() => _initializeSDKs(_firebaseOptions));

  /// The unbounded, authentic Mobile Ads initialization attempt.
  ///
  /// Splash observes this through a separate timeout. Ad request sites use
  /// [runAdRequestWhenReady], which joins this attempt and may retry a prior
  /// transient failure without duplicating an in-flight initialization.
  static Future<bool> get adMobReady => _adMobInitializer.initialize();

  static Future<T> runAdRequestWhenReady<T>({
    required Future<T> Function() request,
    bool Function()? isRequestActive,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _adRequestGate.run(
      request: request,
      isRequestActive: isRequestActive,
      timeout: timeout,
    );
  }

  /// 앱 초기화를 위한 main 함수 래퍼
  ///
  /// ANR 방지를 위해 runApp()을 최대한 빠르게 호출하고,
  /// SDK 초기화는 UI 표시 후 병렬로 진행합니다.
  static Future<void> initializeApp({
    required String environment,
    FirebaseOptions? firebaseOptions,
    required Widget Function() appBuilder,
  }) async {
    _firebaseOptions = firebaseOptions;
    await runZonedGuarded(
      () async {
        try {
          logger.i('앱 초기화 시작...');

          // === Phase 1: runApp 전 최소 초기화 (ANR 방지) ===
          await _runStartupStage('basics', AppInitializer.initializeBasics);
          await _runStartupStage(
            'environment',
            () => AppInitializer.initializeEnvironment(environment),
          );
          await _runStartupStage('sentry', AppInitializer.initializeSentry);

          // 즉시 UI 표시 - SplashImage 위젯이 렌더링됨
          logger.i('앱 시작 중...');
          final appWidget = ProviderScope(
            observers: [LoggingObserver()],
            child: appBuilder(),
          );
          runApp(appWidget);
          logger.i('앱 UI 시작 완료 - SDK 초기화 계속 진행');

          // === Phase 2: runApp 후 SDK 병렬 초기화 ===
          final readiness = await retrySdkInitialization();
          if (!readiness.isReady) {
            logger.e(
              'SDK 초기화 실패 - 앱에서 재시도 가능 상태로 전환',
              error: readiness.error,
              stackTrace: readiness.stackTrace,
            );
          }
        } catch (e, s) {
          logger.e('초기화 중 오류 발생', error: e, stackTrace: s);
          rethrow;
        }
      },
      (Object error, StackTrace s) async {
        logger.e('치명적 오류 발생', error: error, stackTrace: s);
        await Sentry.captureException(error, stackTrace: s);
      },
    );
  }

  /// runApp() 이후 SDK 초기화를 병렬로 실행
  ///
  /// Group 1: 독립적인 SDK (Supabase, Firebase, Timezone, Privacy)
  /// Group 2: Group 1에 의존하는 SDK (Auth, Tapjoy, Branch, AdMob)
  static Future<void> _initializeSDKs(FirebaseOptions? firebaseOptions) async {
    await initializeCoreSdkGroup(
      stages: _sdkStages,
      machineStages: {
        'supabase': initializeSupabase,
        if (firebaseOptions != null)
          'firebase': () async {
            await Firebase.initializeApp(options: firebaseOptions);
          },
        if (UniversalPlatform.isMobile)
          'timezone': AppInitializer.initializeTimezone,
      },
      initializePrivacyConsent: UniversalPlatform.isMobile
          ? AppInitializer.initializePrivacyConsent
          : null,
    );
    logger.i('SDK Group 1 초기화 완료 (Supabase, Firebase, Timezone, Privacy)');

    // Firebase가 준비된 첫 시점에 이전 프로세스의 미전송 GA4 payload를
    // 재시도한다. drain은 SDK/화면 초기화를 막지 않으며 각 sink 호출은 자체
    // timeout을 가진다. auth 항목은 captured user로 보낸 뒤 이 reader의 현재
    // 사용자(B 또는 logout)를 복원한다.
    await _sdkStages.run('analytics-outbox-launch', () async {
      AnalyticsOutbox.configureActiveUserContext(
        userIdReader: () => supabase.auth.currentUser?.id,
        languageReader: Intl.getCurrentLocale,
      );
      unawaited(AnalyticsOutbox.instance.flush());
    });

    // Debug diagnostics are observed in the background and never hold splash.
    if (kDebugMode) {
      await _sdkStages.run('supabase-health-check-launch', () async {
        unawaited(
          _runBestEffortStartupStage(
            'supabase-health-check',
            SupabaseHealthCheck.runHealthCheckOnAppStart,
          ),
        );
      });
    }

    await BoundedNonAuthStartupGate(
      nonAuthWaitLimit: const Duration(seconds: 5),
      onNonAuthError: (error, stackTrace) {
        logger.e(
          'SDK Group 2 (non-auth) 초기화 실패',
          error: error,
          stackTrace: stackTrace,
        );
      },
      onNonAuthTimeout: (limit) {
        logger.w(
          '[Startup] stage=non-auth-sdks observation_timeout_ms='
          '${limit.inMilliseconds}',
        );
      },
    ).wait(
      initializeAuth: () =>
          _runRetryableStartupStage('auth', AppInitializer.initializeAuth),
      initializeNonAuth: () async {
        if (!UniversalPlatform.isMobile) return;
        await Future.wait<void>([
          _runRetryableStartupStage('tapjoy', AppInitializer.initializeTapjoy),
          _runRetryableStartupStage('branch', () async {
            await FlutterBranchSdk.init(
              enableLogging: true,
              branchAttributionLevel: BranchAttributionLevel.NONE,
            );
            await BranchLinkService.instance.start();
          }),
          _runRetryableStartupStage('admob', () async {
            if (!await _startupAdMobInitializer.initialize()) {
              throw const _AdMobStartupDeferred();
            }
          }),
        ]);
      },
    );
    logger.i('SDK Group 2 splash gate 완료 (Auth + bounded non-auth)');

    // PICNIC-2682: Auth 와 Tapjoy connect 는 위에서 병렬로 시작하므로 어느 쪽이
    // 먼저 끝날지 보장이 없다. 둘 다 끝난 지금 SDK 사용자 ID 를 한 번 맞춰 둔다.
    // best-effort 이며(실패해도 앱 시작을 막지 않는다) 오퍼월 진입에서 다시
    // 확인한다.
    unawaited(
      _runBestEffortStartupStage(
        'tapjoy-user-sync',
        AppInitializer.syncTapjoyUserAfterAuth,
      ),
    );

    // Analytics 사용자 속성 설정 (Auth 완료 후).
    //
    // 여기서는 사용자 속성만 세팅하고 login 이벤트는 보내지 않는다.
    // 이 경로는 앱 시작 시 "복원된 세션"이라 로그인 통신 시점이 아니다
    // (택소노미 §2-1 트리거는 로그인 완료 통신 시점). login/sign_up 은
    // AppInitializer.setupSupabaseAuthListener 가 담당한다.
    unawaited(
      _runBestEffortStartupStage(
        'analytics-user-properties',
        _configureAnalyticsUserProperties,
      ),
    );

    // Shorebird 패치 체크는 SplashImage 위젯에서 처리됨

    logger.i('모든 SDK 초기화 완료');
  }

  /// Bounds machine waits while preserving raw SDK work and user consent.
  @visibleForTesting
  static Future<void> initializeCoreSdkGroup({
    required RetryableStartupStages stages,
    required Map<String, AsyncInitializer> machineStages,
    AsyncInitializer? initializePrivacyConsent,
    Duration machineWaitLimit = const Duration(seconds: 10),
  }) => Future.wait<void>([
    for (final stage in machineStages.entries)
      stages.observe(
        stage.key,
        () => _runStartupStage(stage.key, stage.value),
        timeout: machineWaitLimit,
      ),
    if (initializePrivacyConsent != null)
      stages.run(
        'privacy-consent',
        () => _runStartupStage('privacy-consent', initializePrivacyConsent),
      ),
  ], eagerError: true);

  static Future<void> _runRetryableStartupStage(
    String name,
    AsyncInitializer operation,
  ) => _sdkStages.run(name, () => _runStartupStage(name, operation));

  static Future<T> _runStartupStage<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      logger.i(
        '[Startup] stage=$name elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );
    }
  }

  static Future<void> _runBestEffortStartupStage(
    String name,
    Future<void> Function() operation,
  ) async {
    try {
      await _runStartupStage(name, operation);
    } catch (error, stackTrace) {
      logger.e(
        '[Startup] best-effort stage failed: $name',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _configureAnalyticsUserProperties() async {
    final user = supabase.auth.currentUser;
    final currentLocale = Intl.getCurrentLocale();
    if (user != null) {
      await AppAnalytics.setUserAndSessionProperties(
        userId: user.id,
        locale: currentLocale,
        language: currentLocale,
        isLogin: true,
      );
    } else {
      await PicnicAnalytics.instance.setUserProperties(
        userId: null,
        isLogin: false,
        language: currentLocale,
      );
    }
  }

  /// 언어 초기화를 비동기로 실행하는 유틸리티 메서드
  ///
  /// [ref] Riverpod WidgetRef
  /// [context] BuildContext
  /// [loadGeneratedTranslations] 앱별 생성된 번역 파일 로드 함수
  /// [callback] 초기화 완료 후 실행할 콜백 함수
  static Future<void> initializeLanguageAsync(
    WidgetRef ref,
    BuildContext context,
    Future<void> Function(Locale) loadGeneratedTranslations,
    Function(bool, String) callback,
  ) async {
    try {
      logger.i('언어 초기화 시작');

      // 앱 설정에서 현재 언어 가져오기 (또는 기본값으로 'ko' 사용)
      String language = 'ko';
      try {
        final appSetting = ref.read(appSettingProvider);
        if (appSetting.language.isNotEmpty) {
          language = appSetting.language;
        }
        logger.i('설정에서 언어 로드: $language');
      } catch (e) {
        logger.e('앱 설정에서 언어 로드 실패, 기본값 사용', error: e);
      }

      // 언어 초기화 실행
      final success = await LanguageInitializer.changeLanguage(
        ref,
        language,
        loadGeneratedTranslations,
      );

      // 콜백 함수 호출 (non-nullable이므로 null 체크 불필요)
      callback(success, language);

      logger.i('언어 초기화 ${success ? '성공' : '실패'}: $language');
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생', error: e, stackTrace: stackTrace);

      // 오류 발생 시에도 콜백 호출
      callback(false, 'ko');
    }
  }

  /// AdMob 및 미디에이션 초기화의 실제 단일 시도.
  static Future<bool> _initializeAdMobAttempt() async {
    if (!UniversalPlatform.isMobile) return false;

    try {
      logger.i('AdMob 초기화 시작');

      final consentService = ConsentService();
      final consentInitialized = await consentService.initialize();
      if (!consentInitialized) {
        logger.w('AdMob 초기화 보류: UMP 초기화 실패');
        return false;
      }
      logger.i('UMP 동의 확인 완료');

      final canRequestAds = await consentService.canRequestAds();
      if (!canRequestAds) {
        logger.w('AdMob 초기화 보류: UMP가 광고 요청을 허용하지 않음');
        return false;
      }

      // 디버그 빌드 전용: --dart-define=ADMOB_TEST_DEVICE_IDS 테스트 디바이스 등록.
      // 릴리스 빌드 또는 미설정 시 no-op (기존 동작 유지).
      await AdMobTestDevicePolicy.apply();

      // AdMob SDK 초기화
      final initStatus = await MobileAds.instance.initialize();

      // 미디에이션 어댑터 상태 로깅
      initStatus.adapterStatuses.forEach((adapter, status) {
        logger.i(
          '[AdMob] Adapter: $adapter, '
          'State: ${status.state}, '
          'Description: ${status.description}',
        );
      });

      logger.i('AdMob 초기화 완료 (어댑터 ${initStatus.adapterStatuses.length}개)');
      return true;
    } catch (e, s) {
      logger.e('AdMob 초기화 실패', error: e, stackTrace: s);
      return false;
    }
  }
}
