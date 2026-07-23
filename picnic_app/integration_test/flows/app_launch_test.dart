// 앱 실행 플로우 테스트
//
// 앱이 정상적으로 시작되고 초기 화면이 표시되는지 검증합니다.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app_setup.dart';
import '../helpers/mock_supabase_server.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('앱 실행 테스트', () {
    setUpAll(() async {
      await TestAppSetup.initialize(
        scenario: MockScenario.defaultScenario,
      );
    });

    tearDownAll(() async {
      await TestAppSetup.tearDown();
    });

    testWidgets('앱이 크래시 없이 정상 시작되어야 함', (tester) async {
      // TODO: 실제 앱 초기화 로직에 맞게 구현 필요
      // - MainInitializer 의존성 Mock 처리
      // - Firebase/Supabase 초기화 건너뛰기

      await TestAppSetup.pumpTestApp(tester);

      // 앱이 크래시 없이 위젯 트리가 생성되었는지 확인
      expect(find.byType(TestAppSetup.createTestApp().runtimeType), findsAny);
    });

    testWidgets('스플래시 화면이 표시되어야 함', (tester) async {
      // TODO: 스플래시 화면 위젯 키 또는 타입으로 검색
      // - splash.webp 이미지가 포함된 화면이 표시되는지 확인

      await TestAppSetup.pumpTestApp(tester);

      // TODO: 스플래시 화면 검증 구현
      // expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('초기화 완료 후 메인 화면으로 전환되어야 함', (tester) async {
      // TODO: 초기화 완료 후 Portal 또는 로그인 화면으로 전환되는지 확인
      // - 충분한 시간 대기 (pumpAndSettle)
      // - Portal 위젯 또는 로그인 화면 검색

      await TestAppSetup.pumpTestApp(tester);

      // 초기화 완료 대기
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // TODO: 메인 화면 전환 검증 구현
      // expect(find.byType(Portal), findsOneWidget);
    });

    testWidgets('네트워크 오류 시 오류 화면이 표시되어야 함', (tester) async {
      // TODO: MockScenario.networkError로 재초기화 후 테스트
      // - NetworkErrorScreen이 표시되는지 확인
      // - 재시도 버튼이 존재하는지 확인

      // TODO: 네트워크 오류 시나리오 테스트 구현
    });
  });
}
