/// 검색 플로우 테스트
///
/// 검색 기능의 주요 사용자 플로우를 검증합니다.
/// 검색어 입력, 결과 표시, 결과 항목 탭 등을 테스트합니다.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app_setup.dart';
import '../helpers/mock_supabase_server.dart';
import '../robots/search_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('검색 플로우 테스트', () {
    late SearchRobot searchRobot;

    setUpAll(() async {
      await TestAppSetup.initialize(
        scenario: MockScenario.defaultScenario,
      );
    });

    tearDownAll(() async {
      await TestAppSetup.tearDown();
    });

    testWidgets('검색 화면으로 진입할 수 있어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      searchRobot = SearchRobot(tester);

      // TODO: 검색 아이콘/버튼 탭하여 검색 화면 진입
      // await searchRobot.navigateToSearch();
      // await searchRobot.verifySearchScreenVisible();
    });

    testWidgets('검색어 입력 시 결과가 표시되어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      searchRobot = SearchRobot(tester);

      // TODO: 검색 필드에 텍스트 입력
      // TODO: 검색 결과 목록 표시 확인
      // await searchRobot.navigateToSearch();
      // await searchRobot.enterSearchQuery('테스트');
      // await searchRobot.verifySearchResultsVisible();
    });

    testWidgets('검색 결과 항목 탭 시 상세 화면으로 이동해야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      searchRobot = SearchRobot(tester);

      // TODO: 검색 결과에서 항목 탭
      // TODO: 해당 항목의 상세 화면 표시 확인
      // await searchRobot.navigateToSearch();
      // await searchRobot.enterSearchQuery('테스트');
      // await searchRobot.tapFirstResult();
    });

    testWidgets('검색 결과가 없을 때 빈 상태 안내가 표시되어야 함', (tester) async {
      // TODO: MockScenario.emptyData로 재초기화 후 테스트
      // TODO: 검색 결과 없음 메시지 표시 확인
    });

    testWidgets('검색어 지우기 버튼이 동작해야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      searchRobot = SearchRobot(tester);

      // TODO: 검색어 입력 후 지우기 버튼 탭
      // TODO: 검색 필드가 비워지는지 확인
      // await searchRobot.navigateToSearch();
      // await searchRobot.enterSearchQuery('테스트');
      // await searchRobot.clearSearch();
      // await searchRobot.verifySearchFieldEmpty();
    });
  });
}
