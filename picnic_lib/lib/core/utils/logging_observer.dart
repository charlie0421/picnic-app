import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// reflectable 제거로 인해 reflection 기반 비교를 안전한 필드 비교로 대체

base class LoggingObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (previousValue == null || newValue == null) {
      return;
    }
    // logger.i('Provider ${context.provider.name} ');
    // logger.i('type of Object: ${context.provider.runtimeType}');
    // logger.i('type of Object: ${previousValue.runtimeType.toString()}');
    // logger.i('type of Object: ${newValue.runtimeType}');
    // logger.i('type of Object: ${context.container.runtimeType}');

    final provider = context.provider;
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

    // 간단 비교: 객체의 문자열 표현과 해시코드를 이용한 변경 탐지
    // (필요시 개별 도메인 타입에 대한 커스텀 비교 로직을 추가 권장)
    final oldDesc =
        '${oldObj.runtimeType}:${oldObj.hashCode}:${oldObj.toString()}';
    final newDesc =
        '${newObj.runtimeType}:${newObj.hashCode}:${newObj.toString()}';
    if (kDebugMode && oldDesc != newDesc) {
      // 개발 중 변경 감지 로그는 debugPrint 사용
      debugPrint('Object changed: $oldDesc -> $newDesc');
    }
  }
}
