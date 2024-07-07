import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:http/http.dart' as http;
import 'package:picnic_app/app.dart';
import 'package:picnic_app/firebase_options.dart';
// import 'package:picnic_app/logging_http_client.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util.dart';
import 'package:reflectable/reflectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseOptions.url,
    anonKey: supabaseOptions.anonKey,
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
    debug: true,
    // httpClient: kDebugMode ? LoggingHttpClient(http.Client()) : null)
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (isMobile()) {
    await initializeWidgetsAndDeviceOrientation(widgetsBinding);
  }

  initializeReflectable();

  // MobileAds.instance.initialize();

  runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
  requestAppTrackingTransparency();
}

Future<void> requestAppTrackingTransparency() async {
  final trackingStatus =
      await AppTrackingTransparency.trackingAuthorizationStatus;

  if (trackingStatus == TrackingStatus.notDetermined) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    if (status == TrackingStatus.authorized) {
      // IDFA 접근 권한이 부여된 경우 AdMob 초기화
      MobileAds.instance.initialize();
    } else {
      // 권한이 거부된 경우 초기화는 진행하되 비개인화 광고 설정
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      MobileAds.instance.initialize();
    }
  }
}

Future<void> initializeWidgetsAndDeviceOrientation(
    WidgetsBinding widgetsBinding) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
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
