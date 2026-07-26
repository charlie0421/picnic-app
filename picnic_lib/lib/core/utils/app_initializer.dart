import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/account_deletion_handler.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/core/utils/app_initializer_helper.dart';
import 'package:picnic_lib/core/utils/deep_link_handler.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/core/utils/system_ui_initializer.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:picnic_lib/core/utils/token_refresh_manager.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/core/utils/firebase_analytics_utils.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:timezone/data/latest.dart' as tz;

class AppInitializer {
  static Future<void> initializeBasics() async {
    WidgetsFlutterBinding.ensureInitialized();
    logger.i('Widget binding initialized');
    BindingBase.debugZoneErrorsAreFatal = true;
    await initializeGlobalErrorHandling();

  }

  /// MaterialApp 초기화 대기
  static Future<void> _waitForMaterialAppInitialization(
    BuildContext context,
  ) async {
    // MaterialApp이 초기화될 때까지 잠시 대기
    await Future.delayed(const Duration(milliseconds: 200));
    logger.d('MaterialApp 초기화 대기 완료');
  }

  static Future<void> initializeEnvironment(String environment) async {
    logger.i('Initializing environment config...');
    await Environment.initConfig(environment);
    logger.i('Environment config initialized');
  }

  static Future<void> initializeSentry() async {
    logger.i('Initializing Sentry...');
    await SentryFlutter.init((options) {
      options.dsn = kIsWeb
          ? Environment.sentryWebDsn
          : Environment.sentryAppDsn;
      options.tracesSampleRate = Environment.sentryTraceSampleRate;
      options.profilesSampleRate = Environment.sentryProfileSampleRate;
      options.enableAutoSessionTracking = !kDebugMode;
      // Session replay는 Sentry 9.0.0에서 API가 변경됨 - 추후 업데이트 필요
      // options.experimental.replay.sessionSampleRate = Environment.sentrySessionSampleRate;
      // options.experimental.replay.onErrorSampleRate = Environment.sentryErrorSampleRate;
      options.debug = kDebugMode;
      options.maxBreadcrumbs = 50;
      options.attachStacktrace = true;
      options.enableAutoNativeBreadcrumbs = true;
      options.enableNativeCrashHandling = true;
      options.enableTimeToFullDisplayTracing = false;
      options.addInAppInclude('sentry-debug-meta.properties');

      // ANR 진단 강화 (PICNIC-APP-45E 등)
      // - attachThreads: ANR/crash 시점에 모든 thread stack 을 함께 캡처해
      //   main thread 가 어디서 블로킹됐는지 식별 가능하게 만든다.
      // - anrEnabled/anrTimeoutInterval 은 default true/5s 이지만, 의도를
      //   명시적으로 둬 향후 옵션 변경 가능성을 readable 하게 유지.
      options.attachThreads = true;
      options.anrEnabled = true;
      options.anrTimeoutInterval = const Duration(seconds: 5);

      // iOS AppHang threshold 를 default 2s → 3s 로 상향 (PICNIC-APP-4YV 등).
      // 4YV (46u/124e) 의 culprit 이 ChangeNotifier._removeAt, Subtype6TestCache,
      // DefaultNullableTypeTest, CallBootstrapNative 등으로 매우 분산 — 단일 코드
      // 버그가 아니라 메모리 부족 iOS 단말(예: iPhone X free_memory 60MB)의 burst
      // CPU 정체가 다양한 hot path 에서 잡힌 결과. 2s 는 iOS watchdog kill 임계
      // (~4-6s) 대비 과민 — 3s 는 사용자가 체감하는 freeze 만 추적하면서 노이즈
      // 큰 폭 감소. 4s+ 는 watchdog 와 가까워 진짜 hang 을 놓칠 위험이 있어 3s 가 균형점.
      options.appHangTimeoutInterval = const Duration(seconds: 3);

      // 네이티브 SDK 의 URLSession/OkHttp 자동 5xx 캡쳐(SentryNetworkTracker)
      // 를 끈다. 이 경로는 Flutter beforeSend 를 우회하므로 광고 SDK
      // (Pangle/AdMob/Branch 등) 의 텔레메트리 5xx 가 그대로 누적된다
      // (PICNIC-APP-9E: 8216 events / 323 users). 우리 백엔드 5xx 는
      // PostgrestException / FunctionException 같은 SDK 별 exception 으로
      // 이미 캡쳐되므로 시야 손실 없음.
      //
      // sentry_flutter 9.14+ 의 captureNativeFailedRequests 만 false 로 두어
      // Dart-side (SentryHttpClient/dio) 캡쳐 동작은 그대로 유지한다.
      options.captureNativeFailedRequests = false;

      options.beforeSend = (event, hint) {
        final exception = event.exceptions?.firstOrNull;
        final exceptionValue = exception?.value ?? '';
        final exceptionType = exception?.type ?? '';

        // App Hanging / ANR culprit 매칭용 — stack 의 광고 SDK frame 검출
        // (PICNIC-APP-45E/45S/56S 등의 PAG/GAD/Tapjoy/Branch 노이즈 차단).
        final stackFrameFunctions = exception?.stackTrace?.frames
                .map((f) => f.function ?? '')
                .toList() ??
            const <String>[];

        // system-only ANR 판별용 — stack 이 전부 system frame (inApp=false) 이면
        // 우리가 분석할 수 있는 정보가 없는 ANR (PICNIC-APP-45E 등).
        final stackFrameInApp = exception?.stackTrace?.frames
                .map((f) => f.inApp ?? false)
                .toList() ??
            const <bool>[];

        // Reactive ACCOUNT_DELETED handling: any Edge Function 403 with
        // code ACCOUNT_DELETED triggers a one-shot local sign-out so the
        // soft-deleted user stops generating repeated 403s on subsequent
        // provider builds. Idempotent within the app session — safe to
        // fire on every matching event.
        if (exceptionType == 'FunctionException' &&
            AccountDeletionHandler.isAccountDeleted(
              sentryValue: exceptionValue,
            )) {
          unawaited(AccountDeletionHandler.signOutForAccountDeleted());
        }

        final shouldFilter = AppInitializerHelper.shouldFilterSentryEvent(
          sentryEnabled: Environment.enableSentry,
          isDebugMode: kDebugMode,
          exceptionType: exceptionType,
          exceptionValue: exceptionValue,
          stackFrameFunctions: stackFrameFunctions,
          stackFrameInApp: stackFrameInApp,
        );

        if (shouldFilter) return null;

        // all-system ANR (PICNIC-APP-45E): 심볼화 불가한 OS 사후(AppExitInfo)
        // ANR. route/current_screen 태그로만 유의미하므로, 전량 드롭 대신
        // 볼륨 측정용 ~10% 결정론적 샘플(event id 해시 기반, 균일 분포)만
        // 유지하고 나머지는 드롭한다.
        if (AppInitializerHelper.isAllSystemAnr(
              exceptionType,
              stackFrameInApp,
            ) &&
            !AppInitializerHelper.shouldSampleKeep(
              event.eventId.toString(),
              0.10,
            )) {
          return null;
        }

        return event;
      };
    });
    logger.i('Sentry initialized');

    // Shorebird 패치 번호를 Sentry tag 로 등록.
    // release tag(예: 1.2.27+122701) 만으로는 사용자가 OTA 패치를 적용
    // 받았는지(=어느 patch 번호인지) 구분 불가. 별도 tag 로 노출해 Sentry
    // 대시보드에서 patch 번호로 group-by/filter 가능하게 만든다.
    // SDK init 을 블로킹하지 않도록 fire-and-forget 으로 실행.
    unawaited(_tagSentryWithShorebirdPatch());
  }

  /// Reads the active Shorebird patch number and sets it as a Sentry tag.
  ///
  /// On web, Shorebird is not supported — skips silently.
  /// Failures (e.g. shorebird CLI not installed in test env) are logged
  /// but never thrown.
  static Future<void> _tagSentryWithShorebirdPatch() async {
    try {
      if (kIsWeb) return;
      final patch = await ShorebirdUtils.checkPatch();
      final patchNumber = patch?.number;
      Sentry.configureScope((scope) {
        scope.setTag(
          'shorebird.patch_number',
          patchNumber?.toString() ?? 'none',
        );
        scope.setTag(
          'shorebird.has_patch',
          patchNumber != null ? 'yes' : 'no',
        );
      });
      logger.i('🏷️ Sentry shorebird tag set: patch_number=$patchNumber');
    } catch (e, st) {
      logger.w('Sentry shorebird tag 설정 실패: $e', stackTrace: st);
    }
  }

  /// 전역 에러 핸들러 설치. [initializeBasics] 에서 호출되므로
  /// [initializeSentry] 보다 **먼저** 실행된다.
  ///
  /// ## 호출 순서 계약
  ///
  /// `SentryFlutter.init` 은 `FlutterErrorIntegration` 과
  /// `OnErrorIntegration` 을 설치하는데, 둘 다 *체이닝* 방식이다 — init 시점의
  /// 핸들러를 보관했다가 자기 리포팅을 마친 뒤 그 핸들러를 호출한다. 따라서
  /// 최종 호출 순서는
  ///
  ///   framework → Sentry integration (리포팅) → 이 핸들러 (진단 출력)
  ///
  /// 이 되고, 리포팅은 Sentry 통합이, 로컬 진단은 이 핸들러가 담당한다.
  ///
  /// ## 왜 [FlutterError.presentError] 를 덮어쓰면 안 되는가
  ///
  /// [FlutterError.onError] 의 기본값은 [FlutterError.presentError] 다. 여기에
  /// 그냥 대입해 버리면 실패한 위젯을 지목하는 정보가 전부 사라진다 —
  /// `details.context`, `details.library`, 그리고 결정적으로
  /// `details.informationCollector` (debugCreator 위젯 체인
  /// "Row ← SizedBox ← Center ← MyScreen ← …" 를 담고 있다). 이게 없으면
  /// `RenderFlex overflowed by N pixels` 를 어느 위젯이 냈는지 특정할 수 없다.
  /// 게다가 overflow 리포팅 자체가 `RenderFlex.paint` 의 `assert` 안에 있어
  /// debug 빌드에서만 발생하므로, 콘솔이 이 정보를 볼 수 있는 유일한 경로다.
  static Future<void> initializeGlobalErrorHandling() async {
    // 기존 핸들러(기본값 = FlutterError.presentError)를 보관해 두고 감싼다.
    // null 인 경우(누군가 의도적으로 에러 출력을 껐을 때)에도 진단을 잃지
    // 않도록 presentError 로 폴백한다.
    final previousFlutterOnError = FlutterError.onError;

    FlutterError.onError = (details) {
      // Flutter 프레임워크 에러.
      // 1) 프레임워크 기본 진단 출력 — debug 빌드에서 에러 박스에
      //    "The relevant error-causing widget was: …" 와 위젯 생성 체인을 찍는다.
      (previousFlutterOnError ?? FlutterError.presentError)(details);

      // 2) 우리 구조화 로그.
      logger.e(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );

      // 3) Sentry.captureException 을 여기서 호출하지 않는 것은 의도적이다.
      //    SentryFlutter.init 이 설치하는 FlutterErrorIntegration 이 이 핸들러를
      //    감싸고 있고, 이미 FlutterErrorDetails 전체(context/library/
      //    informationCollector)와 `FlutterError` mechanism 을 붙여 리포팅한다.
      //    여기서 또 캡쳐하면 mechanism/context 가 없는 빈약한 두 번째 이벤트가
      //    생기고, 그게 DeduplicationEventProcessor 경합에서 지기 때문에
      //    "안 보일 뿐" 실제로는 이중 캡쳐다.
    };

    final previousPlatformOnError = PlatformDispatcher.instance.onError;

    PlatformDispatcher.instance.onError = (error, stack) {
      // Dart Isolate 에러 (비동기 등)
      previousPlatformOnError?.call(error, stack);

      logger.e('Unhandled Asynchronous Error', error: error, stackTrace: stack);

      // FlutterError 경로와 같은 이유로 기본적으로는 캡쳐하지 않는다 —
      // OnErrorIntegration 이 이 핸들러를 감싸고 직접 리포팅한다.
      // 단 web 에서는 PlatformDispatcher.onError 가 지원되지 않아
      // OnErrorIntegration 이 아예 설치되지 않으므로, 안전망으로 남긴다.
      if (kIsWeb) {
        Sentry.captureException(error, stackTrace: stack);
      }
      return true; // 에러가 처리되었음을 알림
    };
  }

  // static Future<void> initializeMetaAudienceNetwork() async {
  //   if (!isMobile()) return;
  //   logger.i('Initializing Meta Audience Network...');
  //   FacebookAudienceNetwork.init();
  // }

  static Future<void> initializeTapjoy() async {
    if (isIOS() && Environment.tapjoyIosSdkKey == null) return;
    if (isAndroid() && Environment.tapjoyAndroidSdkKey == null) return;

    if (!isMobile()) return;

    logger.i('Initializing Tapjoy...');
    final Map<String, dynamic> optionFlags = {};
    // Tapjoy setLoggingLevel이 버전 14.2.1에서 정의되지 않음 - 일시적으로 주석 처리
    // await Tapjoy.setLoggingLevel(TJLoggingLevel.debug);
    await Tapjoy.connect(
      sdkKey: isIOS()
          ? Environment.tapjoyIosSdkKey!
          : Environment.tapjoyAndroidSdkKey!,
      options: optionFlags,
      onConnectSuccess: _onTapjoyConnectSuccess,
      onConnectFailure: _onTapjoyConnectFailure,
      onConnectWarning: _onTapjoyConnectWarning,
    );
    logger.i('Tapjoy initialized');
  }

  static Future<void> _onTapjoyConnectSuccess() async {
    logger.i('Tapjoy connected');
    Tapjoy.getPrivacyPolicy().setSubjectToGDPR(TJStatus.trueStatus);
    Tapjoy.getPrivacyPolicy().setUserConsent(TJStatus.falseStatus);
    Tapjoy.getPrivacyPolicy().setBelowConsentAge(TJStatus.unknownStatus);
    Tapjoy.getPrivacyPolicy().setUSPrivacy('1---');
    logger.i(Tapjoy.getPluginVersion());
  }

  static Future<void> _onTapjoyConnectFailure(int code, String? error) async {
    logger.e('Tapjoy connect failed: $code, $error');
  }

  static Future<void> _onTapjoyConnectWarning(int code, String? warning) async {
    logger.w('Tapjoy connect warning: $code, $warning');
  }

  static Future<void> initializeAuth() async {
    logger.i('Attempting to recover session...');
    final authService = AuthService();
    final isSessionRecovered = await authService.recoverSession().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        logger.e('Session recovery timed out');
        return false;
      },
    );
    logger.i('Session recovery completed: $isSessionRecovered');

    // await _logStorageData();

    final tokenRefreshManager = TokenRefreshManager(authService);
    tokenRefreshManager.startPeriodicRefresh();
    logger.i('Token refresh manager started');
  }

  // static Future<void> _logStorageData() async {
  //   const storage = FlutterSecureStorage();
  //   try {
  //     final storageData = await storage.readAll();
  //     final storageDataString =
  //         storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  //     logger.i('보안 저장소 데이터:\n$storageDataString');
  //   } catch (e, s) {
  //     if (e is PlatformException &&
  //         (e.message?.contains('BAD_DECRYPT') == true ||
  //             e.message?.contains('error:1e000065') == true)) {
  //       logger.e('보안 저장소 복호화 오류 발생. 데이터 초기화 시도:', error: e, stackTrace: s);
  //       try {
  //         await storage.deleteAll();
  //         logger.i('보안 저장소 데이터 초기화 완료');

  //         // 새로운 보안 저장소 인스턴스 생성 시도
  //         await storage.write(key: 'test_key', value: 'test_value');
  //         await storage.delete(key: 'test_key');
  //         logger.i('새로운 보안 저장소 초기화 성공');
  //       } catch (deleteError, deleteStack) {
  //         logger.e('보안 저장소 초기화 실패:',
  //             error: deleteError, stackTrace: deleteStack);
  //         rethrow; // 상위 레벨에서 처리하도록 에러 전파
  //       }
  //     } else {
  //       logger.e('보안 저장소 읽기 실패:', error: e, stackTrace: s);
  //       rethrow;
  //     }
  //   }
  // }

  static Future<void> initializeWebP() async {
    logger.i('Initializing WebP support...');
    final supportInfo = await WebPSupportChecker.instance.checkSupport();
    logger.i('WebP support: ${supportInfo.webp}, ${supportInfo.animatedWebp}');
    logger.i('WebP support initialized');
  }

  static Future<void> initializeTimezone() async {
    logger.i('Initializing timezones...');
    tz.initializeTimeZones();
    logger.i('Timezones initialized');
  }

  static Future<void> initializePrivacyConsent() async {
    await PrivacyConsentManager.initialize();
  }

  static Future<void> logStorageData() async {
    const storage = FlutterSecureStorage();
    final storageData = await storage.readAll();

    final storageDataString = storageData.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    logger.i(storageDataString);
  }

  static Future<void> requestAppTrackingTransparency() async {
    await PrivacyConsentManager.initialize();
  }

  static Future<void> initializeAppWithSplash(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final startTime = DateTime.now();
      logger.i('앱 초기화 시작: ${startTime.toString()}');

      // MaterialApp이 완전히 초기화될 때까지 대기
      await _waitForMaterialAppInitialization(context);

      // 앱 초기화 작업 수행
      final initFuture = initializeApp(navigatorKey.currentContext!, ref);

      // 최소 표시 시간 설정 (기본 2초)
      const minSplashDuration = Duration(milliseconds: 2000);

      // 초기화 완료
      await initFuture;

      // 현재까지 소요된 시간 계산
      final elapsedTime = DateTime.now().difference(startTime);
      logger.i('앱 초기화 소요 시간: ${elapsedTime.inMilliseconds}ms');

      // 최소 표시 시간보다 빨리 초기화가 완료된 경우, 차이만큼 대기
      if (elapsedTime < minSplashDuration) {
        final remainingTime = minSplashDuration - elapsedTime;
        logger.i('스플래시 화면 추가 대기 시간: ${remainingTime.inMilliseconds}ms');
        await Future.delayed(remainingTime);
      }

      logger.i('앱 초기화 및 스플래시 표시 완료');
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> initializeWebApp(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await Future.wait([initializeApp(context, ref)]);
  }

  static Future<void> initializeApp(BuildContext context, WidgetRef ref) async {
    try {
      logger.i('앱 초기화 시작');

      if (!context.mounted) {
        logger.w('Context가 마운트되지 않아 초기화를 중단합니다.');
        return;
      }

      // MediaQuery 데이터를 안전하게 가져와서 업데이트
      try {
        final mediaQueryData = MediaQuery.maybeOf(context);
        if (mediaQueryData != null) {
          ref
              .read(globalMediaQueryProvider.notifier)
              .updateMediaQueryData(mediaQueryData);
        }
      } catch (e) {
        logger.w('MediaQuery 데이터 업데이트 중 오류: $e');
      }

      if (!context.mounted) return;

      // 필수 블로킹 초기화: 네트워크 + 업데이트 + 밴 체크
      // (결과에 따라 화면 전환이 필요하므로 Portal 표시 전에 완료)
      if (isMobile()) {
        await _initializeMobileApp(ref);
      }

      if (!context.mounted) return;

      // Supabase 인증 상태 변경 리스너 설정 (세션 복원 이벤트를 UI에 반영)
      setupSupabaseAuthListener(ref);

      // 리스너 설정 전에 세션이 이미 복원된 경우, signedIn 이벤트를 놓쳤으므로
      // userInfoProvider를 invalidate하여 로그인 상태를 UI에 반영
      if (isSupabaseLoggedSafely) {
        logger.i('세션이 이미 복원됨 - userInfoProvider 갱신');
        ref.invalidate(userInfoProvider);
      }

      ref
          .read(appInitializationProvider.notifier)
          .updateState(isInitialized: true);

      // 백그라운드 초기화: Portal 표시 후 비동기로 진행
      // (메인 화면 진입을 블로킹하지 않음)
      if (isMobile()) {
        _initializeBackgroundTasks(ref);
      }

      logger.i('앱 초기화 완료');
    } catch (e, s) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: s);
      if (context.mounted) {
        ref
            .read(appInitializationProvider.notifier)
            .updateState(hasNetwork: false, isInitialized: true);
      }
    }
  }

  /// Portal 표시 후 백그라운드에서 실행되는 비필수 초기화
  static void _initializeBackgroundTasks(WidgetRef ref) {
    Future.microtask(() async {
      try {
        // 푸시 토큰 등록
        await PushTokenService.initialize(
          onNotificationTap: (RemoteMessage msg) {
            final actionUrl = msg.data['action_url'];
            if (actionUrl != null &&
                actionUrl is String &&
                actionUrl.isNotEmpty) {
              logger.i(
                '[AppInitializer] Handling push notification tap: $actionUrl',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                handleDeepLink(ref, actionUrl);
              });
            }
          },
          onActionUrlTap: (String actionUrl) {
            logger.i('[AppInitializer] Handling action URL tap: $actionUrl');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              handleDeepLink(ref, actionUrl);
            });
          },
        );
        logger.i('백그라운드: 푸시 토큰 등록 완료');

        // 앱 배지 동기화
        AppBadgeService.syncBadgeWithUnreadCount();

        // 제품 정보 로드
        await _loadProducts(ref);
        logger.i('백그라운드: 제품 정보 로드 완료');
      } catch (e, s) {
        logger.e('백그라운드 초기화 중 오류 발생', error: e, stackTrace: s);
      }
    });
  }

  static Future<void> _initializeMobileApp(WidgetRef ref) async {
    final networkService = NetworkConnectivityService();
    final hasNetwork = await networkService.checkOnlineStatus();
    logger.i('네트워크 상태 확인: $hasNetwork');

    ref
        .read(appInitializationProvider.notifier)
        .updateState(hasNetwork: hasNetwork);

    if (hasNetwork) {
      try {
        // 업데이트 체크와 밴 체크를 병렬로 실행
        final results = await Future.wait([
          checkForUpdates(ref),
          if (!kDebugMode) _checkBanStatus(ref) else Future.value(false),
        ]);

        final updateInfo = results[0] as dynamic;
        final isBanned = !kDebugMode ? results[1] as bool : false;

        logger.i('업데이트 정보: $updateInfo, 밴 상태: $isBanned');

        ref
            .read(appInitializationProvider.notifier)
            .updateState(
              updateInfo: updateInfo,
              isBanned: isBanned,
            );
      } catch (e, s) {
        logger.e('모바일 초기화 중 오류 발생:', error: e, stackTrace: s);
      }
    }
  }

  /// 밴 상태 체크 (VM 감지 + 디바이스 밴 확인)
  static Future<bool> _checkBanStatus(WidgetRef ref) async {
    try {
      final isVirtualDevice = await VirtualMachineDetector.detect(ref);
      final isDeviceBanned = await DeviceManager.isDeviceBanned();
      final isBanned = isVirtualDevice || isDeviceBanned;

      logger.i('디바이스 상태 - 가상머신: $isVirtualDevice, 차단: $isBanned');

      if (isBanned) {
        // Sentry 로깅은 결과에 영향 없으므로 fire-and-forget
        _logBanToSentry(isVirtualDevice);
      }

      return isBanned;
    } catch (e, s) {
      logger.e('밴 체크 중 오류 발생:', error: e, stackTrace: s);
      return false;
    }
  }

  /// 밴 감지 시 Sentry에 로깅 (비동기, fire-and-forget)
  static void _logBanToSentry(bool isVirtualDevice) {
    Future.microtask(() async {
      try {
        final deviceId = await DeviceManager.getDeviceId();
        await Sentry.captureMessage(
          'Device banned detected',
          withScope: (scope) async {
            scope.setTag('ban.virtual_device', isVirtualDevice.toString());
            scope.setTag('ban.device_id', deviceId);
            try {
              final info = await DeviceInfoPlugin().androidInfo;
              scope.setContexts('device', {
                'manufacturer': info.manufacturer,
                'model': info.model,
                'hardware': info.hardware,
                'sdk': info.version.sdkInt,
                'release': info.version.release,
                'is_physical_device': info.isPhysicalDevice,
              });
            } catch (_) {}
          },
        );
      } catch (e, s) {
        logger.e('Sentry ban log failed', error: e, stackTrace: s);
      }
    });
  }

  static Future<void> _loadProducts(WidgetRef ref) async {
    try {
      await Future.wait([
        ref.read(serverProductsProvider.future),
        ref.read(storeProductsProvider.future),
      ]);
    } catch (e, s) {
      logger.e('Failed to load products', error: e, stackTrace: s);
    }
  }

  static Future<void> retryConnection(WidgetRef ref) async {
    final networkService = NetworkConnectivityService();
    final isOnline = await networkService.checkOnlineStatus();
    logger.i('Network check: $isOnline');

    ref
        .read(appInitializationProvider.notifier)
        .updateState(hasNetwork: isOnline);
  }

  static Future<void> initializeSystemUI() =>
      SystemUIInitializer.initialize();

  static void setupSupabaseAuthListener(WidgetRef ref) {
    supabase.auth.onAuthStateChange.listen((data) async {
      try {
        final session = data.session;
        if (session != null) {
          logger.i('jwtToken: ${session.accessToken}');
        }

        if (data.event == AuthChangeEvent.signedIn) {
          try {
            final userInfoState = ref.read(userInfoProvider);
            final shouldFetchProfile = userInfoState.maybeWhen(
              loading: () => false,
              data: (profile) => profile == null,
              orElse: () => true,
            );

            if (shouldFetchProfile) {
              await ref.read(userInfoProvider.notifier).getUserProfiles();
            } else {
              logger.i('프로필 데이터가 이미 로드되어 중복 호출을 생략합니다.');
            }
          } catch (e) {
            logger.e('getUserProfiles 호출 중 오류: $e');
            // ref가 더 이상 유효하지 않을 수 있으므로 무시
          }
          try {
            ref.invalidate(attendanceProvider);
          } catch (e) {
            logger.e('attendanceProvider invalidate 중 오류: $e');
          }
          try {
            final user = supabase.auth.currentUser;
            if (user != null) {
              String? userRole;
              try {
                final p = ref.read(userInfoProvider).value;
                if (p != null) {
                  userRole = p.isAdmin == true ? 'admin' : 'user';
                }
              } catch (_) {}

              String? locale;
              try {
                final appSetting = ref.read(appSettingProvider);
                if (appSetting.language.isNotEmpty) {
                  locale = appSetting.language;
                }
              } catch (_) {}

              await AppAnalytics.setUserAndSessionProperties(
                userId: user.id,
                userRole: userRole,
                locale: locale,
                isTester: kDebugMode,
              );
            }
          } catch (_) {}
        } else if (data.event == AuthChangeEvent.signedOut) {
          logger.i('User signed out');
          try {
            ref.invalidate(attendanceProvider);
          } catch (e) {
            logger.e('attendanceProvider invalidate 중 오류: $e');
          }
          await AppAnalytics.clearUserAndSessionProperties();
        }
      } catch (e, s) {
        logger.e('인증 상태 변경 처리 중 오류:', error: e, stackTrace: s);
      }
    });

    // 필요한 경우 나중에 구독 취소 로직 추가
    // (dispose 메서드가 있는 위젯 내에서 호출될 경우)
  }

  static void setupBranchListener(WidgetRef ref) {
    FlutterBranchSdk.listSession().listen(
      (data) async {
        try {
          logger.i('Incoming Branch link data: $data');
          if (data.containsKey("+clicked_branch_link") &&
              data["+clicked_branch_link"] == true) {
            // 링크 클릭 시 처리 로직
            final longUrl = data["\$desktop_url"];
            // longUrl을 사용하여 원하는 페이지로 이동
            await handleDeepLink(ref, longUrl);
          }
        } catch (e, s) {
          logger.e('Branch link 처리 중 오류:', error: e, stackTrace: s);
        }
      },
      onError: (error) {
        logger.e('Branch link error: $error');
      },
    );

    // 필요한 경우 나중에 구독 취소 로직 추가
  }

  /// Deep link URL 라우팅 처리.
  /// 실제 로직은 [DeepLinkHandler]에 위임됩니다.
  static Future<void> handleDeepLink(WidgetRef ref, String longUrl) =>
      DeepLinkHandler.handleDeepLink(ref, longUrl);

  /// Shorebird 패치 체크를 포함한 통합 초기화
  /// ⚠️ DEPRECATED: 이제 SplashImage에서 패치 체크를 담당합니다.
  /// 중복 체크를 방지하기 위해 이 메서드는 더 이상 사용되지 않습니다.
  @Deprecated('Use SplashImage with enablePatchCheck=true instead')
  static Future<bool> initializeWithPatchCheck({
    Function(String)? onStatusUpdate,
  }) async {
    try {
      logger.i('⚠️ DEPRECATED: initializeWithPatchCheck - SplashImage를 사용하세요');
      onStatusUpdate?.call('Initializing app...');

      // 패치 체크는 더 이상 여기서 하지 않고 SplashImage에서 담당
      logger.i('패치 체크는 SplashImage에서 수행됩니다');
      onStatusUpdate?.call('App initialized');

      return true;
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생: $e', stackTrace: stackTrace);
      onStatusUpdate?.call('Initialization failed');
      return true; // 패치 체크 실패해도 앱은 계속 실행
    }
  }

  /// 백그라운드 패치 체크 (재시작 없이)
  /// ⚠️ DEPRECATED: 이제 SplashImage에서 패치 체크를 담당합니다.
  @Deprecated('Use SplashImage for patch checking')
  static Future<Map<String, dynamic>> checkPatchInBackground({
    Function(String)? onStatusUpdate,
  }) async {
    logger.w('⚠️ DEPRECATED: checkPatchInBackground는 더 이상 사용되지 않습니다');
    onStatusUpdate?.call('Patch check moved to SplashImage');

    return {
      'updateAvailable': false,
      'updateDownloaded': false,
      'needsRestart': false,
      'message': 'Use SplashImage for patch checking',
    };
  }
}
