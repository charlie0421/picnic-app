/// 로그인 플로우 테스트
///
/// 다양한 소셜 로그인 방식과 인증 흐름을 검증합니다.
/// 실제 소셜 로그인 SDK는 Mock으로 대체됩니다.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app_setup.dart';
import '../helpers/mock_supabase_server.dart';
import '../robots/login_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('로그인 플로우 테스트', () {
    late LoginRobot loginRobot;

    setUpAll(() async {
      await TestAppSetup.initialize(
        scenario: MockScenario.unauthenticated,
      );
    });

    tearDownAll(() async {
      await TestAppSetup.tearDown();
    });

    testWidgets('비로그인 상태에서 로그인 화면이 표시되어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      loginRobot = LoginRobot(tester);

      // TODO: 로그인 화면 표시 검증
      // - 로그인 버튼들이 표시되는지 확인 (카카오, Apple, Google)
      // await loginRobot.verifyLoginScreenVisible();
    });

    testWidgets('카카오 로그인 버튼 탭 시 로그인 처리되어야 함', (tester) async {
      // TODO: 카카오 로그인 SDK Mock 처리 필요
      // - KakaoSdk.login()을 Mock으로 대체
      // - Mock에서 성공 토큰 반환
      // - Supabase 인증 완료 후 메인 화면 전환 확인

      await TestAppSetup.pumpTestApp(tester);
      loginRobot = LoginRobot(tester);

      // TODO: 카카오 로그인 플로우 구현
      // await loginRobot.tapKakaoLogin();
      // await loginRobot.verifyMainScreen();
    });

    testWidgets('Apple 로그인 버튼 탭 시 로그인 처리되어야 함', (tester) async {
      // TODO: Apple Sign In Mock 처리 필요
      // - SignInWithApple.getAppleIDCredential()을 Mock으로 대체
      // - iOS 시뮬레이터에서만 실행 가능

      await TestAppSetup.pumpTestApp(tester);
      loginRobot = LoginRobot(tester);

      // TODO: Apple 로그인 플로우 구현
      // await loginRobot.tapAppleLogin();
      // await loginRobot.verifyMainScreen();
    });

    testWidgets('Google 로그인 버튼 탭 시 로그인 처리되어야 함', (tester) async {
      // TODO: Google Sign In Mock 처리 필요
      // - GoogleSignIn().signIn()을 Mock으로 대체

      await TestAppSetup.pumpTestApp(tester);
      loginRobot = LoginRobot(tester);

      // TODO: Google 로그인 플로우 구현
      // await loginRobot.tapGoogleLogin();
      // await loginRobot.verifyMainScreen();
    });

    testWidgets('로그인 실패 시 에러 메시지가 표시되어야 함', (tester) async {
      // TODO: 인증 실패 시나리오 테스트
      // - Mock 서버에서 401 반환 시 에러 처리 확인
      // - 사용자에게 적절한 에러 메시지 표시 확인

      await TestAppSetup.pumpTestApp(tester);
      loginRobot = LoginRobot(tester);

      // TODO: 로그인 실패 시나리오 구현
    });
  });
}
