import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_app/picnic_app.dart';
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
    debug: true,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (isMobile()) {
    await initializeWidgetsAndDeviceOrientation(widgetsBinding);
  }

  initializeReflectable();

  MobileAds.instance.initialize();

  runApp(
      ProviderScope(observers: [LoggingObserver()], child: const PicnicApp()));

  FlutterNativeSplash.remove();
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
