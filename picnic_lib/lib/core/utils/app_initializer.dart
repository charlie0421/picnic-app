import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/core/utils/token_refresh_manager.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/board_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_list_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:universal_platform/universal_platform.dart';
import 'package:logger/logger.dart';

class AppInitializer {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static Logger? _logger;

  static Logger get logger {
    _logger ??= Logger(
      printer: LongMessagePrinter(),
      output: LongOutputHandler(),
      level: Level.all,
    );
    return _logger!;
  }

  static Future<void> initializeBasics() async {
    WidgetsFlutterBinding.ensureInitialized();
    logger.i('Widget binding initialized');
    BindingBase.debugZoneErrorsAreFatal = true;
  }

  static Future<void> initializeEnvironment(String environment) async {
    logger.i('Initializing environment config...');
    await Environment.initConfig(environment);
    logger.i('Environment config initialized');
  }

  static Future<void> initializeSentry() async {
    logger.i('Initializing Sentry...');
    await SentryFlutter.init(
      (options) {
        options.dsn =
            kIsWeb ? Environment.sentryWebDsn : Environment.sentryAppDsn;
        options.tracesSampleRate = Environment.sentryTraceSampleRate;
        options.profilesSampleRate = Environment.sentryProfileSampleRate;
        options.enableAutoSessionTracking = !kDebugMode;
        options.experimental.replay.sessionSampleRate =
            Environment.sentrySessionSampleRate;
        options.experimental.replay.onErrorSampleRate =
            Environment.sentryErrorSampleRate;
        options.debug = kDebugMode;
        options.maxBreadcrumbs = 50;
        options.attachStacktrace = true;
        options.enableAutoNativeBreadcrumbs = true;
        options.enableNativeCrashHandling = true;
        options.enableTimeToFullDisplayTracing = false;
        options.addInAppInclude('sentry-debug-meta.properties');

        options.beforeSend = (event, hint) {
          if (!Environment.enableSentry || kDebugMode) {
            try {
              _logSentryException(event);
            } catch (e) {
              // logger가 초기화되지 않은 경우 무시
              if (kDebugMode) {
                print('Error logging Sentry event: $e');
              }
            }
            return null;
          }
          return event;
        };
      },
    );
    logger.i('Sentry initialized');
  }

  static void _logSentryException(SentryEvent event) {
    event.exceptions?.forEach((element) {
      if (element.stackTrace != null) {
        final frames = element.stackTrace?.frames;
        if (frames != null && frames.isNotEmpty) {
          final stackTraceString = frames
              .map((frame) =>
                  '${frame.fileName}:${frame.lineNo} - ${frame.function}')
              .join('\n');
          logger.e('${element.value}\nStacktrace:\n$stackTraceString');
        } else {
          logger.e('Stacktrace: No frames available');
        }
      }
    });
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
    await Tapjoy.setDebugEnabled(true);
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

    final storageDataString =
        storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    logger.i(storageDataString);
  }

  static Future<void> requestAppTrackingTransparency() async {
    await PrivacyConsentManager.initialize();
  }

  static Future<void> initializeAppWithSplash(
      BuildContext context, WidgetRef ref) async {
    await Future.wait([
      initializeApp(context, ref),
      Future.delayed(const Duration(milliseconds: 3000)),
    ]);
  }

  static Future<void> initializeWebApp(
      BuildContext context, WidgetRef ref) async {
    await Future.wait([
      initializeApp(context, ref),
    ]);
  }

  static Future<void> initializeApp(BuildContext context, WidgetRef ref) async {
    try {
      logger.i('앱 초기화 시작');

      // MediaQuery 데이터를 미리 캐시
      final mediaQueryData = MediaQuery.of(context);
      if (!context.mounted) return;

      // 기본 초기화
      await precacheImage(const AssetImage("assets/splash.webp"), context);
      if (!context.mounted) return;

      ref.read(appSettingProvider.notifier);
      ref
          .read(globalMediaQueryProvider.notifier)
          .updateMediaQueryData(mediaQueryData);

      if (isMobile()) {
        await _initializeMobileApp(ref);
        await _loadProducts(ref);

        logger.i('제품 정보 로드 완료');
      } else {
        logger.i('데스크탑 앱 초기화 완료');
      }

      if (!context.mounted) return;

      ref.read(appInitializationProvider.notifier).updateState(
            isInitialized: true,
          );
    } catch (e, s) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: s);
      if (context.mounted) {
        ref.read(appInitializationProvider.notifier).updateState(
              hasNetwork: false,
              isInitialized: true,
            );
      }
    }
  }

  static Future<void> _initializeMobileApp(WidgetRef ref) async {
    final networkService = NetworkConnectivityService();
    final hasNetwork = await networkService.checkOnlineStatus();
    logger.i('네트워크 상태 확인: $hasNetwork');

    ref.read(appInitializationProvider.notifier).updateState(
          hasNetwork: hasNetwork,
        );

    if (hasNetwork) {
      try {
        // 먼저 업데이트 체크
        final updateInfo = await checkForUpdates(ref);
        logger.i('업데이트 정보: $updateInfo');

        ref
            .read(appInitializationProvider.notifier)
            .updateState(updateInfo: updateInfo
                // 강업 테스트
                // updateInfo?.copyWith(status: UpdateStatus.updateRequired),
                );

        // 강제 업데이트가 필요한 경우, 밴 체크를 하지 않고 바로 업데이트 화면으로
        if (updateInfo?.status == UpdateStatus.updateRequired) {
          await _loadProducts(ref);
          return;
        }

        // 강제 업데이트가 필요하지 않은 경우에만 밴 체크
        bool isBanned = false;
        if (!kDebugMode) {
          final isVirtualDevice = await VirtualMachineDetector.detect(ref);
          isBanned = isVirtualDevice || await DeviceManager.isDeviceBanned();
          logger.i('디바이스 상태 - 가상머신: $isVirtualDevice, 차단: $isBanned');
        }

        ref.read(appInitializationProvider.notifier).updateState(
              isBanned: isBanned,
            );
      } catch (e, s) {
        logger.e('모바일 초기화 중 오류 발생:', error: e, stackTrace: s);
      }
    }
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

    ref.read(appInitializationProvider.notifier).updateState(
          hasNetwork: isOnline,
        );
  }

  static Future<void> initializeSystemUI() async {
    if (kIsWeb) return;

    try {
      int? androidSdkVersion;
      if (UniversalPlatform.isAndroid) {
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          androidSdkVersion = androidInfo.version.sdkInt;
          logger.i('Android SDK Version: $androidSdkVersion');
        } catch (e, s) {
          logger.e('안드로이드 SDK 버전 확인 실패:', error: e, stackTrace: s);
          androidSdkVersion = 29;
        }

        try {
          // 시스템 UI 스타일 설정
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
          );

          // Android 버전별 SystemUiMode 설정
          if (androidSdkVersion >= 30) {
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [
                SystemUiOverlay.top,
                SystemUiOverlay.bottom,
              ],
            );

            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                systemNavigationBarContrastEnforced: false,
              ),
            );
          } else {
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [
                SystemUiOverlay.top,
                SystemUiOverlay.bottom,
              ],
            );
          }
        } catch (e, s) {
          logger.e('시스템 UI 설정 실패:', error: e, stackTrace: s);
          // 기본 설정으로 폴백
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
        }
      }

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e, s) {
        logger.e('화면 방향 설정 실패:', error: e, stackTrace: s);
      }
    } catch (e, s) {
      logger.e('시스템 UI 초기화 중 오류 발생:', error: e, stackTrace: s);
    }
  }

  static void setupSupabaseAuthListener(WidgetRef ref) {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        logger.i('jwtToken: ${session.accessToken}');
      }

      if (data.event == AuthChangeEvent.signedIn) {
        await ref.read(userInfoProvider.notifier).getUserProfiles();
      } else if (data.event == AuthChangeEvent.signedOut) {
        logger.i('User signed out');
      }
    });
  }

  static void setupBranchListener(ref) {
    FlutterBranchSdk.listSession().listen((data) {
      logger.i('Incoming Branch link data: $data');
      if (data.containsKey("+clicked_branch_link") &&
          data["+clicked_branch_link"] == true) {
        // 링크 클릭 시 처리 로직
        final longUrl = data["\$desktop_url"];
        // longUrl을 사용하여 원하는 페이지로 이동
        handleDeepLink(ref, longUrl);
      }
    }, onError: (error) {
      logger.e('Branch link error: $error');
    });
  }

  static void handleDeepLink(WidgetRef ref, String longUrl) {
    final uri = Uri.parse(longUrl);

    if (uri.pathSegments.isNotEmpty) {
      final portal = uri.pathSegments[0];
      final page = uri.pathSegments[1];
      switch (portal) {
        case 'vote':
          switch (page) {
            case 'list':
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    const VoteListPage(),
                  );
              break;
            case 'detail':
              final voteId = uri.pathSegments[2];
              final type = uri.queryParameters['type'];
              if (type == 'achieve') {
                ref.read(navigationInfoProvider.notifier).setCurrentPage(
                      VoteDetailAchievePage(voteId: int.parse(voteId)),
                    );
              } else {
                ref.read(navigationInfoProvider.notifier).setCurrentPage(
                      VoteDetailPage(voteId: int.parse(voteId)),
                    );
              }
              break;
          }
          break;
        case 'community':
          ref
              .read(navigationInfoProvider.notifier)
              .setPortal(PortalType.community);
          switch (page) {
            case 'home':
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    const CommunityHomePage(),
                  );
              break;
            case 'board_list':
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    const BoardListPage(),
                  );
              break;
            case 'board_detail':
              final artistId = uri.pathSegments[2];
              logger.i('artistId: $artistId');
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    BoardHomePage(int.parse(artistId)),
                  );
              break;
            case 'fortune':
              final artistId = uri.pathSegments[2];
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    CompatibilityListPage(artistId: int.parse(artistId)),
                  );
              break;
            case 'compatibility':
              final artistId = uri.pathSegments[2];
              ref.read(navigationInfoProvider.notifier).setCurrentPage(
                    CompatibilityListPage(artistId: int.parse(artistId)),
                  );
              break;
          }
      }
    }
    if (uri.pathSegments.contains('terms')) {
      uri.pathSegments.contains('ko')
          ? const TermsScreen(language: 'ko')
          : const TermsScreen(language: 'en');
    } else if (uri.pathSegments.contains('privacy')) {
      uri.pathSegments.contains('ko')
          ? const PrivacyScreen(language: 'ko')
          : const PrivacyScreen(language: 'en');
    } else {
      ref.read(userInfoProvider.notifier).getUserProfiles();
    }
  }
}
