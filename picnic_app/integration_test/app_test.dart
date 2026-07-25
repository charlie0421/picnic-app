// 모든 E2E 플로우 테스트의 통합 진입점입니다.
import 'package:integration_test/integration_test.dart';

import 'flows/app_launch_test.dart' as app_launch;
import 'flows/login_flow_test.dart' as login_flow;
import 'flows/vote_flow_test.dart' as vote_flow;
import 'flows/search_flow_test.dart' as search_flow;
import 'flows/mypage_flow_test.dart' as mypage_flow;
import 'flows/ad_reward_recovery_flow_test.dart' as ad_reward_recovery_flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 앱 실행 테스트
  app_launch.main();

  // 로그인 플로우 테스트
  login_flow.main();

  // 투표 플로우 테스트
  vote_flow.main();

  // 검색 플로우 테스트
  search_flow.main();

  // 마이페이지 플로우 테스트
  mypage_flow.main();

  ad_reward_recovery_flow.main();
}
