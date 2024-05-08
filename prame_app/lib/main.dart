import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/main.reflectable.dart';
import 'package:prame_app/prame_app.dart';
import 'package:prame_app/reflector.dart';
import 'package:prame_app/util.dart';
import 'package:reflectable/reflectable.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (isMobile()) {
    await initializeWidgetsAndDeviceOrientation(widgetsBinding);
  }

  const reflector = const Reflector();

  initializeReflectable();

  runApp(ProviderScope(observers: [LoggingObserver()], child: PrameApp()));

  globalStorage.saveData('ACCESS_TOKEN',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJpcm9ubG92ZTc3QGdtYWlsLmNvbSIsIm5pY2tuYW1lIjoi7JaR7J6s64-Z6rCc67Cc66i47IugIiwicHJvZmlsZUltYWdlIjoiaHR0cHM6Ly9jZG4tZGV2Lmljb25jYXN0aW5nLmlvL3VzZXIvMS9lNDMwMTNjMi0yNzk4LTRhMzEtYTRlZS1lMzJmMjI1OTMwYTMuanBnIiwicm9sZSI6InVzZXIiLCJpc3MiOiJwcmFtZSIsInR5cGUiOiJBQ0NFU1NfVE9LRU4iLCJpYXQiOjE3MTUxNjk2MDQsImV4cCI6MTcxNTI1NjAwNH0.pwU7vcTMli586eLrMjK0AAvmWWWWLAkVW1H4PstFz3o');
  globalStorage.saveData('REFRESH_TOKEN',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJpcm9ubG92ZTc3QGdtYWlsLmNvbSIsIm5pY2tuYW1lIjoi7JaR7J6s64-Z6rCc67Cc66i47IugIiwicHJvZmlsZUltYWdlIjoiaHR0cHM6Ly9jZG4tZGV2Lmljb25jYXN0aW5nLmlvL3VzZXIvMS9lNDMwMTNjMi0yNzk4LTRhMzEtYTRlZS1lMzJmMjI1OTMwYTMuanBnIiwicm9sZSI6InVzZXIiLCJpc3MiOiJwcmFtZSIsInR5cGUiOiJSRUZSRVNIX1RPS0VOIiwiaWF0IjoxNzE1MTY5NjA0LCJleHAiOjE3NDY3MDU2MDR9.ILGqqrNH6lbdayjLB5GziO0f0toKplaLi2w6utdT2iI');

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

      if (oldValue != newValue) {
        print('Field ${field.simpleName} changed from $oldValue to $newValue');
      }
    }
  }
}
