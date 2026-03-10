/// 투표 플로우 테스트
///
/// 투표 목록 조회, 투표 참여, 결과 확인 등
/// 투표 관련 주요 사용자 플로우를 검증합니다.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app_setup.dart';
import '../helpers/mock_supabase_server.dart';
import '../robots/vote_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('투표 플로우 테스트', () {
    late VoteRobot voteRobot;

    setUpAll(() async {
      await TestAppSetup.initialize(
        scenario: MockScenario.defaultScenario,
      );
    });

    tearDownAll(() async {
      await TestAppSetup.tearDown();
    });

    testWidgets('투표 탭에서 투표 목록이 표시되어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      voteRobot = VoteRobot(tester);

      // TODO: Portal에서 투표 탭으로 이동
      // TODO: 투표 목록이 로드되는지 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.verifyVoteListVisible();
    });

    testWidgets('투표 항목 탭 시 투표 상세 화면으로 이동해야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      voteRobot = VoteRobot(tester);

      // TODO: 투표 목록에서 첫 번째 항목 탭
      // TODO: 투표 상세 화면 표시 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.tapFirstVote();
      // await voteRobot.verifyVoteDetailVisible();
    });

    testWidgets('투표 선택지를 선택하면 결과가 반영되어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      voteRobot = VoteRobot(tester);

      // TODO: 투표 상세에서 선택지 탭
      // TODO: 투표 결과 화면 전환 확인
      // TODO: 선택한 옵션이 하이라이트 되는지 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.tapFirstVote();
      // await voteRobot.selectOption(0);
      // await voteRobot.verifyVoteResultVisible();
    });

    testWidgets('투표 목록이 비어있을 때 빈 상태 화면이 표시되어야 함', (tester) async {
      // TODO: MockScenario.emptyData로 재초기화 후 테스트
      // TODO: 빈 상태 안내 메시지 표시 확인
    });

    testWidgets('투표 새로고침(pull-to-refresh)이 동작해야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      voteRobot = VoteRobot(tester);

      // TODO: 아래로 당겨서 새로고침 제스처
      // TODO: 목록이 갱신되는지 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.pullToRefresh();
      // await voteRobot.verifyVoteListVisible();
    });
  });
}
