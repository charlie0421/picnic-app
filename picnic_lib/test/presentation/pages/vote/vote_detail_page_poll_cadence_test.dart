import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// `is_ended`/`is_upcoming` 은 서버 컬럼이 아니라 `AsyncVoteDetail.fetch` 가
/// `start_at`/`stop_at` 에서 로컬 계산해 써 넣는다 — 종료/예정 상태는 반드시
/// 시각으로 만들어야 한다.
Map<String, dynamic> _voteRow({DateTime? startAt, DateTime? stopAt}) {
  final now = DateTime.now().toUtc();
  return {
    'id': 1,
    'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': (startAt ?? now.subtract(const Duration(days: 1)))
        .toIso8601String(),
    'stop_at': (stopAt ?? now.add(const Duration(days: 7))).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow({required int id, required int voteTotal}) =>
    {
      'id': id,
      'vote_id': 1,
      'vote_total': voteTotal,
      'artist': {
        'id': id + 10,
        'name': {'ko': '아티스트$id', 'en': 'Artist$id'},
        'image': null,
        'artist_group': {
          'id': 1,
          'name': {'ko': '그룹', 'en': 'Group'},
          'image': null,
        },
      },
      'artist_group': null,
    };

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(const VoteDetailPage(voteId: 1)),
    );
    // 상세 → 아이템 목록 순차 해결 + 첫 렌더까지.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 이후 [seconds]초 동안의 폴링 **tick 수**.
  ///
  /// 한 tick 은 요청 2개를 만든다(전체 목록 + `select=id,vote_total` 경량
  /// totals diff). tick 수를 세려면 둘 중 하나만 세야 하므로 경량 쿼리를
  /// 표식으로 쓴다.
  Future<int> pollTicksOver(WidgetTester tester, int seconds) async {
    capturedMockRequests.clear();
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
    }
    return capturedMockRequests
        .where((u) =>
            u.path.endsWith('/vote_item') &&
            u.queryParameters['select'] == 'id,vote_total')
        .length;
  }

  group('VoteDetailPage poll cadence', () {
    testWidgets('live vote polls every second', (tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
          _voteItemRow(id: 2, voteTotal: 3000),
        ],
      });
      await pumpPage(tester);

      final polls = await pollTicksOver(tester, 5);
      expect(
        polls,
        greaterThanOrEqualTo(4),
        reason: '진행 중 투표는 1초 주기로 폴링해야 한다 (5초에 ~5회)',
      );
    });

    testWidgets('ended vote polls every 5th tick, decided per tick', (
      tester,
    ) async {
      // 케이던스 판정이 initState 의 1회 평가면 이 테스트가 잡는다: 그 시점엔
      // isEnded 가 아직 false 라 종료 투표도 1초 주기로 돌았다 (리뷰에서
      // 런타임 실측 — 3.5초에 3회). 판정은 tick 마다 이뤄져야 한다.
      setupMockSupabase({
        'vote': [
          _voteRow(
            stopAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
          ),
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
          _voteItemRow(id: 2, voteTotal: 3000),
        ],
      });
      await pumpPage(tester);

      final polls = await pollTicksOver(tester, 5);
      expect(
        polls,
        lessThanOrEqualTo(1),
        reason: '종료된 투표는 5번째 tick 에만 폴링해야 한다 (5초에 ≤1회)',
      );
    });
  });
}
