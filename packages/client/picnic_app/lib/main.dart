import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/logging_observer.dart';
import 'package:picnic_app/util/token_refresh_manager.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

      if (isMobile()) {
        logger.i('Requesting app tracking transparency...');
        await requestAppTrackingTransparency();
        logger.i('App tracking transparency completed');
      }

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
  final trackingStatus =
      await AppTrackingTransparency.trackingAuthorizationStatus;

  if (trackingStatus == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // 권한 상태와 관계없이 항상 광고 초기화
  if (trackingStatus == TrackingStatus.authorized) {
    // IDFA 접근 권한이 부여된 경우 AdMob 초기화
    await MobileAds.instance.initialize();
  } else {
    // 권한이 거부되거나 결정되지 않은 경우 비개인화 광고 설정
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    await MobileAds.instance.initialize();
  }
  logger.i('AppTrackingTransparency: $trackingStatus');
}

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
