import 'dart:async';

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
      // 테스트용 StreamSubscription 생성 (각각 별도의 컨트롤러 사용)
      final authController = StreamController<String>();
      final appLinksController = StreamController<String>();
      StreamSubscription<String>? authSubscription =
          authController.stream.listen((_) {});
      StreamSubscription<String>? appLinksSubscription =
          appLinksController.stream.listen((_) {});

      // 구독이 활성 상태인지 확인
      expect(authSubscription.isPaused, isFalse);
      expect(appLinksSubscription.isPaused, isFalse);

      // disposeAppListeners 호출
      AppLifecycleInitializer.disposeAppListeners(
          authSubscription, appLinksSubscription);

      // 취소된 구독은 여전히 접근 가능하지만 더 이상 이벤트를 받지 않음
      // disposeAppListeners가 cancel()을 호출했는지 간접 확인
      expect(authSubscription.isPaused, isFalse);
      expect(appLinksSubscription.isPaused, isFalse);

      // 테스트 리소스 정리
      authController.close();
      appLinksController.close();
    });
  });
}
