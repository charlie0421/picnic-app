// 실제 Supabase/Firebase 연결 대신 Mock 서버를 사용하는 E2E 헬퍼입니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_lib/core/config/environment.dart';

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
    Environment.initTestConfig(
      {
        'supabase': {
          'url': mockServer.baseUrl,
          'anon_key': 'integration-local-anon-key',
          'storage': {
            'url': '${mockServer.baseUrl}/storage/v1',
            'anon_key': 'integration-local-anon-key',
          },
        },
        'theme': {
          'colors': {
            'primary': '0xFF9374FF',
            'secondary': '0xFF83FBC8',
            'sub': '0xFFCDFB5D',
            'point': '0xFFFFA9BD',
            'point_900': '0xFFEB4A71',
          },
        },
        'logging': {'level': 'off'},
      },
      environment: 'test-local',
    );
  }

  /// 테스트 환경 정리
  static Future<void> tearDown() async {
    await mockServer.stop();
  }

  /// 테스트용 앱 위젯 생성
  ///
  /// Riverpod ProviderScope에 테스트 오버라이드를 적용하여
  /// 실제 백엔드 없이 동작하는 앱 위젯을 반환합니다.
  static Widget createTestApp() {
    // TODO: 실제 프로바이더 오버라이드 구현
    // - Supabase 클라이언트를 Mock으로 교체
    // - Firebase 초기화 건너뛰기
    // - 소셜 로그인 Mock 처리
    return ProviderScope(
      overrides: const [],
      child: const App(),
    );
  }

  /// 테스트용 앱을 pump하고 초기 렌더링 대기
  ///
  /// [tester]에 앱을 마운트하고 초기 프레임이 렌더링될 때까지 대기합니다.
  static Future<void> pumpTestApp(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());

    // 초기 프레임 렌더링 대기
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
