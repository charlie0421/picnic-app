import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';

void main() {
  group('AppLifecycleInitializer', () {
    test('AppLifecycleInitializer 클래스의 정적 속성 확인', () {
      // URI 스키마 상수 확인
      expect(AppLifecycleInitializer.appUriScheme, equals('picnic'));
    });

    test('AppLifecycleInitializer 클래스의 정적 메서드 타입 확인', () {
      // 정적 메서드들의 존재 여부 확인
      expect(AppLifecycleInitializer.setupAppInitializers, isA<Function>());
      expect(AppLifecycleInitializer.disposeAppListeners, isA<Function>());
      expect(AppLifecycleInitializer.setupAppRoutes, isA<Function>());
      expect(AppLifecycleInitializer.markAppInitialized, isA<Function>());
      expect(AppLifecycleInitializer.handleBranchUri, isA<Function>());
    });

    test('disposeAppListeners 메서드가 StreamSubscription을 취소하는지 확인', () {
      // 테스트용 StreamSubscription 생성
      final testController = StreamController<String>();
      StreamSubscription<String>? authSubscription =
          testController.stream.listen((_) {});
      StreamSubscription<String>? appLinksSubscription =
          testController.stream.listen((_) {});

      // 구독이 활성 상태인지 확인
      expect(authSubscription.isPaused, isFalse);
      expect(appLinksSubscription.isPaused, isFalse);

      // disposeAppListeners 호출
      AppLifecycleInitializer.disposeAppListeners(
          authSubscription, appLinksSubscription);

      // authSubscription이 취소되었는지 확인을 시도하면 예외 발생
      // (취소된 구독에 대한 isPaused 접근은 오류 발생)
      expect(() => authSubscription.isPaused, throwsStateError);
      expect(() => appLinksSubscription.isPaused, throwsStateError);

      // 테스트 리소스 정리
      testController.close();
    });
  });
}
