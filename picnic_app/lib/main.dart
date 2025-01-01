import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/core/config/environment.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/core/services/auth/auth_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/core/utils/logger.dart';
import 'package:picnic_app/core/utils/logging_observer.dart';
import 'package:picnic_app/core/utils/privacy_consent_manager.dart';
import 'package:picnic_app/core/utils/token_refresh_manager.dart';
import 'package:picnic_app/core/utils/ui.dart';
import 'package:picnic_app/core/utils/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:url_strategy/url_strategy.dart';

void main() async {
  await runZonedGuarded(() async {
    try {
      logger.i('Starting app initialization...');

      WidgetsFlutterBinding.ensureInitialized();
      logger.i('Widget binding initialized');

      logger.i('Initializing environment config...');
      const String environment =
          String.fromEnvironment('ENVIRONMENT', defaultValue: 'prod');
      await Environment.initConfig(environment);
      logger.i('Environment config initialized');

      BindingBase.debugZoneErrorsAreFatal = true;

      logger.i('Initializing Sentry...');
      await SentryFlutter.init(
        (options) {
          options.dsn =
              kIsWeb ? Environment.sentryWebDsn : Environment.sentryAppDsn;

          // 성능 모니터링 설정
          options.tracesSampleRate = Environment.sentryTraceSampleRate;
          options.profilesSampleRate = Environment.sentryProfileSampleRate;

          // 디버그 모드 최적화
          options.enableAutoSessionTracking = !kDebugMode;
          options.autoAppStart = !kDebugMode;

          // 실험적 기능 설정
          options.experimental.replay.sessionSampleRate =
              Environment.sentrySessionSampleRate;
          options.experimental.replay.onErrorSampleRate =
              Environment.sentryErrorSampleRate;

          // 환경 설정
          options.debug = kDebugMode;

          // 성능 최적화
          options.maxBreadcrumbs = 50;
          options.attachStacktrace = true;

          // 디버그 메타데이터 활성화
          options.enableAutoNativeBreadcrumbs = true;

          // Native SDK 통합 활성화
          options.enableNativeCrashHandling = true;

          options.enableTimeToFullDisplayTracing = false; // 옵션 1: 비활성화

          // 디버그 메타데이터 경로 설정
          options.addInAppInclude('sentry-debug-meta.properties');

          options.beforeSend = (event, hint) {
            if (!Environment.enableSentry || kDebugMode) {
              event.exceptions?.forEach((element) {
                if (element.stackTrace != null) {
                  final frames = element.stackTrace?.frames;
                  if (frames != null && frames.isNotEmpty) {
                    final stackTraceString = frames
                        .map((frame) =>
                            '${frame.fileName}:${frame.lineNo} - ${frame.function}')
                        .join('\n');
                    logger
                        .e('${element.value}\nStacktrace:\n$stackTraceString');
                  } else {
                    logger.e('Stacktrace: No frames available');
                  }
                }
              });
              return null;
            }
            return event;
          };
        },
      );
      logger.i('Sentry initialized');

      logger.i('Initializing Supabase...');
      await initializeSupabase();
      logger.i('Supabase initialized');

      logger.i('Initializing WebP support...');
      final supportInfo = await WebPSupportChecker.instance.checkSupport();
      logger
          .i('WebP support: ${supportInfo.webp}, ${supportInfo.animatedWebp}');
      logger.i('WebP support initialized');

      if (isMobile()) {
        logger.i('Initializing Tapjoy...');
        final Map<String, dynamic> optionFlags = {};
        Tapjoy.setDebugEnabled(true);
        await Tapjoy.connect(
          sdkKey: isIOS()
              ? Environment.tapjoyIosSdkKey
              : Environment.tapjoyAndroidSdkKey,
          options: optionFlags,
          onConnectSuccess: () async {
            logger.i('Tapjoy connected');
            Tapjoy.getPrivacyPolicy().setSubjectToGDPR(TJStatus.trueStatus);
            Tapjoy.getPrivacyPolicy().setUserConsent(TJStatus.falseStatus);
            Tapjoy.getPrivacyPolicy()
                .setBelowConsentAge(TJStatus.unknownStatus);
            Tapjoy.getPrivacyPolicy().setUSPrivacy('1---');
            logger.i(Tapjoy.getPluginVersion());
          },
          onConnectFailure: (int code, String? error) async {
            logger.e('Tapjoy connect failed: $code, $error');
          },
          onConnectWarning: (int code, String? warning) async {
            logger.w('Tapjoy connect warning: $code, $warning');
          },
        );
        logger.i('Tapjoy initialized');
      }

      logger.i('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase initialized');

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

      logStorageData();

      final tokenRefreshManager = TokenRefreshManager(authService);
      tokenRefreshManager.startPeriodicRefresh();
      logger.i('Token refresh manager started');

      logger.i('Initializing timezones...');
      tz.initializeTimeZones();
      logger.i('Timezones initialized');

      logger.i('Initializing reflectable...');
      initializeReflectable();
      logger.i('Reflectable initialized');

      await requestAppTrackingTransparency();

      setPathUrlStrategy();
      logger.i('URL strategy set');

      logger.i('Starting app...');
      runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
      logger.i('App started successfully');
    } catch (e, s) {
      logger.e('Error during initialization', error: e, stackTrace: s);
      rethrow;
    }
  }, (Object error, StackTrace s) async {
    logger.e('Main Uncaught error', error: error, stackTrace: s);
    await Sentry.captureException(error, stackTrace: s);
  });
}

void logStorageData() async {
  const storage = FlutterSecureStorage();
  final storageData = await storage.readAll();

  final storageDataString =
      storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  logger.i(storageDataString);
}

Future<void> requestAppTrackingTransparency() async {
  await PrivacyConsentManager.initialize();
}
