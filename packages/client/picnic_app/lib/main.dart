import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/logging_observer.dart';
import 'package:picnic_app/util/privacy_consent_manager.dart';
import 'package:picnic_app/util/token_refresh_manager.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:url_strategy/url_strategy.dart';

void main() async {
  await runZonedGuarded(() async {
    try {
      logger.i('Starting app initialization...');
      BindingBase.debugZoneErrorsAreFatal = true;

      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      logger.i('Widget binding initialized');

      const String environment =
          String.fromEnvironment('ENVIRONMENT', defaultValue: 'prod');
      logger.i('Initializing environment config...');
      await Environment.initConfig(environment);
      logger.i('Environment config initialized');

      logger.i('Initializing Supabase...');
      await initializeSupabase();
      logger.i('Supabase initialized');

      if (isMobile()) {
        logger.i('Initializing WebP support...');
        await WebPSupportChecker.instance.initialize();
        logger.i('WebP support initialized');
      }

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
      }

      logger.i('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i('Firebase initialized');

      final authService = AuthService();
      logger.i('Attempting to recover session...');
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

      tz.initializeTimeZones();
      logger.i('Timezones initialized');

      if (isMobile()) {
        logger.i('Initializing mobile specific settings...');
        await initializeWidgetsAndDeviceOrientation(widgetsBinding);
        logger.i('Mobile settings initialized');
      }

      initializeReflectable();
      logger.i('Reflectable initialized');

      await requestAppTrackingTransparency();

      setPathUrlStrategy();
      logger.i('URL strategy set');

      logger.i('Initializing Sentry...');
      await SentryFlutter.init(
        (options) {
          options.dsn =
              kIsWeb ? Environment.sentryWebDsn : Environment.sentryAppDsn;
          options.tracesSampleRate = Environment.sentryTraceSampleRate;
          options.profilesSampleRate = Environment.sentryProfileSampleRate;
          options.experimental.replay.sessionSampleRate =
              Environment.sentrySessionSampleRate;
          options.experimental.replay.onErrorSampleRate =
              Environment.sentryErrorSampleRate;
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

      logger.i('Starting app...');
      runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
      logger.i('App started successfully');
    } catch (e, stackTrace) {
      logger.e('Error during initialization: $e');
      logger.e(stackTrace.toString());
      rethrow;
    }
  }, (Object error, StackTrace stackTrace) {
    logger.e('Uncaught error: $error');
    logger.e(stackTrace.toString());
    Sentry.captureException(error, stackTrace: stackTrace);
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

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
