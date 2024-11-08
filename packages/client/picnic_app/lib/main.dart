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
import 'package:picnic_app/util/auth_service.dart';
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
    BindingBase.debugZoneErrorsAreFatal = true;

    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    const String environment =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'prod');
    await Environment.initConfig(environment);

    if (isMobile()) {
      await WebPSupportChecker.instance.initialize();
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    logStorageData();
    final authService = AuthService();
    final isSessionRecovered = await authService.recoverSession();
    if (!isSessionRecovered) {
      // authService.signOut();
    }
    logStorageData();

    final tokenRefreshManager = TokenRefreshManager(authService);
    tokenRefreshManager.startPeriodicRefresh();

    tz.initializeTimeZones();

    if (isMobile()) {
      await initializeWidgetsAndDeviceOrientation(widgetsBinding);
    }

    initializeReflectable();

    if (isMobile()) {
      requestAppTrackingTransparency();
    }

    setPathUrlStrategy();

    SentryFlutter.init(
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
              logger.e('Exception: ${element.value}');
              if (element.stackTrace != null) {
                final frames = element.stackTrace?.frames;
                if (frames != null && frames.isNotEmpty) {
                  final stackTraceString = frames
                      .map((frame) =>
                          '${frame.fileName}:${frame.lineNo} - ${frame.function}')
                      .join('\n');
                  logger.e('Stacktrace:\n$stackTraceString');
                } else {
                  logger.e('Stacktrace: No frames available');
                }
              }
            });
            return null; // null을 반환하면 이벤트가 Sentry로 전송되지 않습니다.
          }
          return event;
        };
      },
    );
    runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
  }, (Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  });
}

void logStorageData() async {
  const storage = FlutterSecureStorage();
  final storageData = await storage.readAll();

  storageData.forEach((key, value) {
    logger.i('key: $key, value: $value');
  });
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
