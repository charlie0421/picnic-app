/// 테스트용 앱 초기화 헬퍼
///
/// 실제 Supabase/Firebase 연결 대신 Mock 서버를 사용하여
/// 독립적인 E2E 테스트 환경을 구성합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/app.dart';

import 'mock_supabase_server.dart';

/// 테스트 앱 설정 클래스
///
/// E2E 테스트에서 사용할 앱 인스턴스를 생성하고
/// 필요한 Mock/Override를 적용합니다.
class TestAppSetup {
  /// Mock Supabase 서버 인스턴스
  static late MockSupabaseServer mockServer;

  /// 테스트 환경 초기화
  ///
  /// [scenario]를 통해 테스트 시나리오별 Mock 데이터를 설정합니다.
  static Future<void> initialize({
    MockScenario scenario = MockScenario.defaultScenario,
  }) async {
    // Mock 서버 초기화
    mockServer = MockSupabaseServer(scenario: scenario);
    await mockServer.start();
  }

  /// 테스트 환경 정리
  static Future<void> tearDown() async {
    await mockServer.stop();
  }

  /// 테스트용 앱 위젯 생성
  ///
  /// Riverpod ProviderScope에 테스트 오버라이드를 적용하여
  /// 실제 백엔드 없이 동작하는 앱 위젯을 반환합니다.
  static Widget createTestApp({
    List<Override> additionalOverrides = const [],
  }) {
    // TODO: 실제 프로바이더 오버라이드 구현
    // - Supabase 클라이언트를 Mock으로 교체
    // - Firebase 초기화 건너뛰기
    // - 소셜 로그인 Mock 처리
    final overrides = <Override>[
      // TODO: supabaseClientProvider.overrideWithValue(mockServer.client),
      // TODO: firebaseProvider.overrideWithValue(MockFirebase()),
      ...additionalOverrides,
    ];

    return ProviderScope(
      overrides: overrides,
      child: const App(),
    );
  }

  /// 테스트용 앱을 pump하고 초기 렌더링 대기
  ///
  /// [tester]에 앱을 마운트하고 초기 프레임이 렌더링될 때까지 대기합니다.
  static Future<void> pumpTestApp(
    WidgetTester tester, {
    List<Override> additionalOverrides = const [],
  }) async {
    await tester.pumpWidget(
      createTestApp(additionalOverrides: additionalOverrides),
    );

    // 초기 프레임 렌더링 대기
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
