import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/core/utils/token_refresh_manager.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

class AppInitializer {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

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
        options.autoAppStart = !kDebugMode;
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
            _logSentryException(event);
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

  static Future<void> initializeTapjoy() async {
    if (!isMobile()) return;

    logger.i('Initializing Tapjoy...');
    final Map<String, dynamic> optionFlags = {};
    await Tapjoy.setDebugEnabled(true);
    await Tapjoy.connect(
      sdkKey: isIOS()
          ? Environment.tapjoyIosSdkKey
          : Environment.tapjoyAndroidSdkKey,
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

    await _logStorageData();

    final tokenRefreshManager = TokenRefreshManager(authService);
    tokenRefreshManager.startPeriodicRefresh();
    logger.i('Token refresh manager started');
  }

  static Future<void> _logStorageData() async {
    const storage = FlutterSecureStorage();
    final storageData = await storage.readAll();
    final storageDataString =
        storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    logger.i(storageDataString);
  }

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

  static Future<void> initializeApp(BuildContext context, WidgetRef ref) async {
    try {
      logger.i('앱 초기화 시작');

      // 기본 초기화
      await precacheImage(const AssetImage("assets/splash.webp"), context);
      ref.read(appSettingProvider.notifier);
      ref
          .read(globalMediaQueryProvider.notifier)
          .updateMediaQueryData(MediaQuery.of(context));

      if (isMobile()) {
        await _initializeMobileApp(ref);
      } else {
        await _loadProducts(ref);
        logger.i('제품 정보 로드 완료');
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
        final isBanned = await DeviceManager.isDeviceBanned();
        logger.i('디바이스 밴 상태: $isBanned');

        ref.read(appInitializationProvider.notifier).updateState(
              isBanned: isBanned,
            );

        final updateInfo = await checkForUpdates(ref);
        logger.i('Update info: $updateInfo');

        ref.read(appInitializationProvider.notifier).updateState(
              updateInfo: updateInfo,
            );

        if (!isBanned && updateInfo?.status == UpdateStatus.updateRequired) {
          await _loadProducts(ref);
        }
      } catch (e) {
        logger.e('모바일 초기화 중 오류: $e');
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

    int? androidSdkVersion;
    if (UniversalPlatform.isAndroid) {
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        androidSdkVersion = androidInfo.version.sdkInt;
        logger.i('Android SDK Version: $androidSdkVersion');
      } catch (e, s) {
        logger.i('Failed to get Android SDK version: $e', stackTrace: s);
      }
    }

    if (UniversalPlatform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      if (androidSdkVersion != null && androidSdkVersion < 30) {
        // Android 11 미만
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      } else {
        // Android 11 이상
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
        );
      }
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

  static void setupAppLinksListener(WidgetRef ref) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri uri) {
      logger.i('Incoming link: $uri');
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
    }, onError: (err) {
      logger.e('Error: $err');
    });
  }
}
