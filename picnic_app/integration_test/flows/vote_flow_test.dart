// 투표 목록 조회, 투표 참여, 결과 확인 등 주요 사용자 플로우를 검증합니다.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/wallet_contract_fixtures.g.dart';
import '../helpers/test_app_setup.dart';
import '../helpers/mock_supabase_server.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('투표 플로우 테스트', () {
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
      // TODO: Portal에서 투표 탭으로 이동
      // TODO: 투표 목록이 로드되는지 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.verifyVoteListVisible();
    });

    testWidgets('투표 항목 탭 시 투표 상세 화면으로 이동해야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
      // TODO: 투표 목록에서 첫 번째 항목 탭
      // TODO: 투표 상세 화면 표시 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.tapFirstVote();
      // await voteRobot.verifyVoteDetailVisible();
    });

    testWidgets('투표 선택지를 선택하면 결과가 반영되어야 함', (tester) async {
      await TestAppSetup.pumpTestApp(tester);
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
      // TODO: 아래로 당겨서 새로고침 제스처
      // TODO: 목록이 갱신되는지 확인
      // await voteRobot.navigateToVoteTab();
      // await voteRobot.pullToRefresh();
      // await voteRobot.verifyVoteListVisible();
    });

    testWidgets('general vote sends v3 body through voting-v2', (tester) async {
      final client = SupabaseClient(
        TestAppSetup.mockServer.baseUrl,
        'integration-anon-key',
      );
      final repository = VoteTransactionRepository(
        client,
        delay: (_) async {},
      );
      final result = await repository.performGeneralVote(
        VoteTransactionRequest(
          voteId: 10,
          voteItemId: 20,
          amount: BigInt.from(17),
          requestId: '018f4f72-2ff0-7ae0-bf62-5b40d9855472',
        ),
      );
      final body = TestAppSetup.mockServer.lastVoteBody!;
      expect(body['request_id'], '018f4f72-2ff0-7ae0-bf62-5b40d9855472');
      expect(body, isNot(contains('star_candy_usage')));
      expect(body, isNot(contains('star_candy_bonus_usage')));
      expect(body, isNot(contains('cotton_candy_usage')));
      expect(result.usage.cottonCandy, BigInt.from(5));
      expect(result.usage.bonusStarCandy, BigInt.from(7));
      expect(result.usage.starCandy, BigInt.from(5));
      expect(result.wallet.star, BigInt.from(95));
      expect(result.wallet.cotton, BigInt.zero);
      expect(result.wallet.bonus, BigInt.from(23));
      expect(
        walletContractFixtureSha256['vote_result_v3.json'],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        walletContractFixtureSetSha256,
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        jsonDecode(walletContractFixtureJson['vote_result_v3.json']!),
        isA<Map<String, dynamic>>(),
      );
      const expectedWalletContractFixtureNames = <String>{
        'wallet_summary_v1.json',
        'currency_history_empty_v1.json',
        'currency_history_mixed_v1.json',
        'vote_result_v3.json',
        'ad_reward_pending_v1.json',
        'ad_reward_granted_v1.json',
        'promotion_surfaces_empty_v1.json',
        'promotion_surfaces_active_v1.json',
        'purchase_results_v1.json',
        'admin_cs_summary_v1.json',
        'admin_money_timeline_v1.json',
        'stable_error_v1.json',
      };
      expect(
        walletContractFixtureJson.keys.toSet(),
        expectedWalletContractFixtureNames,
      );
      expect(
        walletContractFixtureSha256.keys.toSet(),
        expectedWalletContractFixtureNames,
      );
      for (final checksum in walletContractFixtureSha256.values) {
        expect(checksum, matches(RegExp(r'^[0-9a-f]{64}$')));
      }
    });
  });
}
