import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_app/app.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/network.dart';
import 'package:picnic_app/util/token_refresh_manager.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/webp_support_checker.dart';
import 'package:reflectable/reflectable.dart';
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
      options.dsn =
          'https://2a10b0168b427bbdc6eb3a1f16a1f2a2@o4507695222685696.ingest.us.sentry.io/4507695242739712';
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

Future<void> checkSession() async {
  try {
    final session = supabase.auth.currentSession;
  } catch (e, s) {
    logger.e('세션 확인 중 오류 발생: $e', stackTrace: s);
    final authService = AuthService();
    await authService.signOut();
  }
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
}

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

class LoggingObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    if (previousValue == null || newValue == null) {
      return;
    }
    // logger.i('Provider ${provider.name} ');
    // logger.i('type of Object: ${provider.runtimeType}');
    // logger.i('type of Object: ${previousValue.runtimeType.toString()}');
    // logger.i('type of Object: ${newValue.runtimeType}');
    // logger.i('type of Object: ${container.runtimeType}');

    if (previousValue.runtimeType.toString().startsWith('Async') ||
        newValue.runtimeType.toString().startsWith('Async') ||
        previousValue.runtimeType.toString().startsWith('String') ||
        newValue.runtimeType.toString().startsWith('String')) {
      return;
    }

    detectChanges(previousValue, newValue);
  }

  void detectChanges(Object oldObj, Object newObj) {
    if (oldObj.runtimeType.toString().contains('Impl') ||
        newObj.runtimeType.toString().contains('Impl')) {
      return;
    }

    // 객체의 실제 타입에 기반한 리플렉션
    InstanceMirror oldMirror = reflector.reflect(oldObj);
    InstanceMirror newMirror = reflector.reflect(newObj);

    // oldObj의 타입을 가져옴
    Type oldType = oldObj.runtimeType;

    // 해당 타입의 선언을 가져옴
    ClassMirror classMirror = reflector.reflectType(oldType) as ClassMirror;

    // 필드를 순회하며 변경사항 감지
    for (var field
        in classMirror.declarations.values.whereType<VariableMirror>()) {
      var oldValue = oldMirror.invokeGetter(field.simpleName);
      var newValue = newMirror.invokeGetter(field.simpleName);

      if (kDebugMode) {
        if (oldValue != newValue) {
          print(
              'Field ${field.simpleName} changed from $oldValue to $newValue');
        }
      }
    }
  }
}
