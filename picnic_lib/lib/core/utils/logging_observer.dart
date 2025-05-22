import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/reflector.dart';
import 'package:reflectable/reflectable.dart';

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

    // Locale 관련 Provider 또는 Locale 객체 처리 건너뛰기
    if (provider.name?.contains('locale') == true ||
        provider.name?.contains('Locale') == true ||
        previousValue is Locale ||
        newValue is Locale) {
      return;
    }

    if (previousValue.runtimeType.toString().startsWith('Async') ||
        newValue.runtimeType.toString().startsWith('Async') ||
        previousValue.runtimeType.toString().startsWith('String') ||
        newValue.runtimeType.toString().startsWith('String') ||
        previousValue.runtimeType.toString().startsWith('minified:') ||
        newValue.runtimeType.toString().startsWith('minified:') ||
        previousValue is MediaQueryData ||
        newValue is MediaQueryData) {
      return;
    }

    detectChanges(previousValue, newValue);
  }

  void detectChanges(Object oldObj, Object newObj) {
    if (oldObj.runtimeType.toString().contains('Impl') ||
        newObj.runtimeType.toString().contains('Impl') ||
        oldObj.runtimeType.toString().contains('bool') ||
        newObj.runtimeType.toString().contains('bool') ||
        oldObj is Locale || // Locale 타입에 대한 reflection 방지
        newObj is Locale) {
      // Locale 타입에 대한 reflection 방지
      return;
    }

    try {
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
    } catch (e) {
      // 안전하게 오류 처리 - reflection 오류 무시
      if (kDebugMode) {
        print('Reflection error ignored: $e');
      }
    }
  }
}
