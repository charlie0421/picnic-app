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
import 'package:picnic_lib/presentation/common/navigator_key.dart';
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

    // 앱 초기화 상태 확인을 위한 지연
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// MaterialApp 초기화 대기
  static Future<void> _waitForMaterialAppInitialization(
      BuildContext context) async {
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
    await SentryFlutter.init(
      (options) {
        options.dsn =
            kIsWeb ? Environment.sentryWebDsn : Environment.sentryAppDsn;
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
    try {
      event.exceptions?.forEach((element) {
        if (element.stackTrace != null) {
          final frames = element.stackTrace?.frames;
          if (frames != null && frames.isNotEmpty) {
            final stackTraceString = frames
                .map((frame) =>
                    '${frame.fileName}:${frame.lineNo} - ${frame.function}')
                .join('\n');

            final errorMessage = element.value ?? 'Unknown error';

            // 렌더링 관련 일반적인 오류들은 로그 레벨을 낮춤
            if (errorMessage.contains('RenderBox was not laid out') ||
                errorMessage.contains('hasSize') ||
                errorMessage.contains('Directionality widget') ||
                errorMessage.contains('No Directionality widget found') ||
                errorMessage.contains('semantics.parentDataDirty') ||
                errorMessage.contains('!semantics.parentDataDirty') ||
                errorMessage.contains('Failed assertion') ||
                errorMessage.contains('RenderObject') ||
                errorMessage.contains('rendering/object.dart')) {
              logger.w(
                  'UI 렌더링 경고 (무시됨): $errorMessage\nStacktrace:\n$stackTraceString');
            } else {
              logger.e('$errorMessage\nStacktrace:\n$stackTraceString');
            }
          } else {
            logger.e('Stacktrace: No frames available');
          }
        } else {
          // 스택 트레이스가 없는 경우
          final errorMessage = element.value ?? 'Unknown error';
          if (errorMessage.contains('Directionality widget') ||
              errorMessage.contains('No Directionality widget found') ||
              errorMessage.contains('semantics.parentDataDirty') ||
              errorMessage.contains('!semantics.parentDataDirty') ||
              errorMessage.contains('Failed assertion') ||
              errorMessage.contains('RenderObject') ||
              errorMessage.contains('rendering/object.dart')) {
            logger.w('UI 렌더링 경고 (무시됨): $errorMessage');
          } else {
            logger.e('오류 (스택 트레이스 없음): $errorMessage');
          }
        }
      });
    } catch (e) {
      // 로그 출력 중 오류 발생 시 무시
      if (kDebugMode) {
        print('Error in _logSentryException: $e');
      }
    }
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

    final storageDataString =
        storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    logger.i(storageDataString);
  }

  static Future<void> requestAppTrackingTransparency() async {
    await PrivacyConsentManager.initialize();
  }

  static Future<void> initializeAppWithSplash(
      BuildContext context, WidgetRef ref) async {
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
      BuildContext context, WidgetRef ref) async {
    await Future.wait([
      initializeApp(context, ref),
    ]);
  }

  static Future<void> initializeApp(BuildContext context, WidgetRef ref) async {
    try {
      logger.i('앱 초기화 시작');

      // 위젯 마운트 상태 확인
      if (!context.mounted) {
        logger.w('Context가 마운트되지 않아 초기화를 중단합니다.');
        return;
      }

      // MaterialApp/WidgetsApp이 초기화되었는지 확인
      try {
        final directionality = Directionality.maybeOf(context);
        if (directionality == null) {
          logger.w('Directionality가 아직 초기화되지 않았습니다. MaterialApp 초기화를 기다립니다.');
          // 짧은 지연 후 다시 시도
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          logger.d('Directionality 확인 완료: ${directionality.toString()}');
        }
      } catch (e) {
        logger.w('Directionality 확인 중 오류 발생: $e');
      }

      // MediaQuery 데이터를 안전하게 확인
      try {
        final mediaQuery = MediaQuery.maybeOf(navigatorKey.currentContext!);
        if (mediaQuery != null) {
          logger.d('MediaQuery 데이터 확인 완료: ${mediaQuery.size}');
        } else {
          logger.w('MediaQuery 데이터를 가져올 수 없습니다.');
        }
      } catch (e) {
        logger.w('MediaQuery 데이터 확인 중 오류 발생: $e');
      }

      if (!context.mounted) return;

      // 기본 초기화 - 안전하게 처리
      try {
        await precacheImage(const AssetImage("assets/splash.webp"), context);
      } catch (e) {
        logger.w('스플래시 이미지 프리캐시 실패: $e');
      }

      if (!context.mounted) return;

      // 위젯 마운트 상태 확인 후 ref 사용
      if (!context.mounted) return;

      try {
        ref.read(appSettingProvider.notifier);
      } catch (e) {
        logger.w('AppSettingProvider 초기화 중 오류: $e');
      }

      // 위젯 마운트 상태 확인 후 ref 사용
      if (!context.mounted) return;

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

      if (isMobile()) {
        await _initializeMobileApp(ref);
        if (!context.mounted) return;
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
          if (androidSdkVersion >= 35) {
            // Android 15+ (갤럭시 S25 등 최신 기기)
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.edgeToEdge,
            );

            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                systemNavigationBarContrastEnforced: false,
                // 최신 기기에서 gesture navigation 지원
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            );
          } else if (androidSdkVersion >= 30) {
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
      try {
        final session = data.session;
        if (session != null) {
          logger.i('jwtToken: ${session.accessToken}');
        }

        if (data.event == AuthChangeEvent.signedIn) {
          try {
            await ref.read(userInfoProvider.notifier).getUserProfiles();
          } catch (e) {
            logger.e('getUserProfiles 호출 중 오류: $e');
            // ref가 더 이상 유효하지 않을 수 있으므로 무시
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          logger.i('User signed out');
        }
      } catch (e, s) {
        logger.e('인증 상태 변경 처리 중 오류:', error: e, stackTrace: s);
      }
    });

    // 필요한 경우 나중에 구독 취소 로직 추가
    // (dispose 메서드가 있는 위젯 내에서 호출될 경우)
  }

  static void setupBranchListener(WidgetRef ref) {
    FlutterBranchSdk.listSession().listen((data) {
      try {
        logger.i('Incoming Branch link data: $data');
        if (data.containsKey("+clicked_branch_link") &&
            data["+clicked_branch_link"] == true) {
          // 링크 클릭 시 처리 로직
          final longUrl = data["\$desktop_url"];
          // longUrl을 사용하여 원하는 페이지로 이동
          handleDeepLink(ref, longUrl);
        }
      } catch (e, s) {
        logger.e('Branch link 처리 중 오류:', error: e, stackTrace: s);
      }
    }, onError: (error) {
      logger.e('Branch link error: $error');
    });

    // 필요한 경우 나중에 구독 취소 로직 추가
  }

  static void handleDeepLink(WidgetRef ref, String longUrl) {
    try {
      final uri = Uri.parse(longUrl);

      // 네비게이션 로직을 캡처하여 나중에 위젯이 dispose 되어도 문제가 없도록 함
      final navigationNotifier = ref.read(navigationInfoProvider.notifier);

      if (uri.pathSegments.isNotEmpty) {
        final portal = uri.pathSegments[0];
        final page = uri.pathSegments[1];
        switch (portal) {
          case 'vote':
            switch (page) {
              case 'list':
                navigationNotifier.setCurrentPage(
                  const VoteListPage(),
                );
                break;
              case 'detail':
                final voteId = uri.pathSegments[2];
                final type = uri.queryParameters['type'];
                if (type == 'achieve') {
                  navigationNotifier.setCurrentPage(
                    VoteDetailAchievePage(voteId: int.parse(voteId)),
                  );
                } else {
                  navigationNotifier.setCurrentPage(
                    VoteDetailPage(voteId: int.parse(voteId)),
                  );
                }
                break;
            }
            break;
          case 'community':
            navigationNotifier.setPortal(PortalType.community);
            switch (page) {
              case 'home':
                navigationNotifier.setCurrentPage(
                  const CommunityHomePage(),
                );
                break;
              case 'board_list':
                navigationNotifier.setCurrentPage(
                  const BoardListPage(),
                );
                break;
              case 'board_detail':
                final artistId = uri.pathSegments[2];
                logger.i('artistId: $artistId');
                navigationNotifier.setCurrentPage(
                  BoardHomePage(int.parse(artistId)),
                );
                break;
              case 'fortune':
                final artistId = uri.pathSegments[2];
                navigationNotifier.setCurrentPage(
                  CompatibilityListPage(artistId: int.parse(artistId)),
                );
                break;
              case 'compatibility':
                final artistId = uri.pathSegments[2];
                navigationNotifier.setCurrentPage(
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
        try {
          final userInfoNotifier = ref.read(userInfoProvider.notifier);
          userInfoNotifier.getUserProfiles();
        } catch (e) {
          logger.e('getUserProfiles 호출 중 오류: $e');
          // ref가 더 이상 유효하지 않을 수 있으므로 무시
        }
      }
    } catch (e, s) {
      logger.e('딥링크 처리 중 오류:', error: e, stackTrace: s);
    }
  }

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
