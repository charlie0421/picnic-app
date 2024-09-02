import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_app/app.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/logging_observer.dart';
import 'package:picnic_app/util/network.dart';
import 'package:picnic_app/util/token_refresh_manager.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'prod');
  await Environment.initConfig(environment);
  await WebPSupportChecker.instance.initialize();

  logger.i('WebP support: ${WebPSupportChecker.instance.supportsWebP}');

  final customHttpClient = RetryHttpClient(http.Client());
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true, detectSessionInUri: false),
    debug: true,
    httpClient: customHttpClient,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kDebugMode) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } else {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  logStorageData();
  final authService = AuthService();
  final isSessionRecovered = await authService.recoverSession();
  if (!isSessionRecovered) {
    authService.signOut();
  }
  logStorageData();

  final tokenRefreshManager = TokenRefreshManager(authService);
  tokenRefreshManager.startPeriodicRefresh();

  tz.initializeTimeZones();

  if (isMobile()) {
    await initializeWidgetsAndDeviceOrientation(widgetsBinding);
  }

  initializeReflectable();

  // MobileAds.instance.initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = Environment.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.beforeSend = (event, hint) {
        if (!Environment.enableSentry || kDebugMode) {
          logger.i(
              'Sentry event in local environment (not sent): ${event.eventId}');
          return null; // null을 반환하면 이벤트가 Sentry로 전송되지 않습니다.
        }
        return event;
      };
    },
    appRunner: () => runApp(
        ProviderScope(observers: [LoggingObserver()], child: const App())),
  );

  requestAppTrackingTransparency();
}

void logStorageData() async {
  const storage = FlutterSecureStorage();
  final storageData = await storage.readAll();

  storageData.forEach((key, value) {
    FirebaseCrashlytics.instance.log('key: $key, value: $value');
    logger.i('key: $key, value: $value');
  });
}

Future<void> requestAppTrackingTransparency() async {
  final trackingStatus =
      await AppTrackingTransparency.trackingAuthorizationStatus;

  if (trackingStatus == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  final gmaMediationUnity = GmaMediationUnity();
  gmaMediationUnity.setGDPRConsent(true);
  gmaMediationUnity.setCCPAConsent(true);

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
}

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
