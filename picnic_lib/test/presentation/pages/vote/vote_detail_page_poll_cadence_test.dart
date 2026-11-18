import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_deadline_refresh.dart';
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
  /// 화면이 마감 여부와 유예 창을 판정할 때 읽는 시계. 테스트가 직접 옮긴다 —
  /// `tester.pump` 는 타이머만 흘려보내고 이 시각은 그대로 둔다.
  late DateTime now;
  late void Function() restore;

  setUp(() {
    now = DateTime.now().toUtc();
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
      buildTestAppPage(
        const VoteDetailPage(voteId: 1),
        extraOverrides: [
          voteDeadlineClockProvider.overrideWithValue(Clock(() => now)),
        ],
      ),
    );
    // 상세 → 아이템 목록 순차 해결 + 첫 렌더까지.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  bool isTotalsPoll(Uri u) =>
      u.path.endsWith('/vote_item') &&
      u.queryParameters['select'] == 'id,vote_total';

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
    return capturedMockRequests.where(isTotalsPoll).length;
  }

  /// 스크롤이 멎은 직후 0.5초 동안 나간 득표 조회 수. 1초 폴링 tick 이 끼지
  /// 않도록 [pumpPage] 직후(0.4초 시점)에만 부른다.
  Future<int> totalsFetchesOnScrollSettle(WidgetTester tester) async {
    capturedMockRequests.clear();
    final context = tester.element(find.byType(CustomScrollView));
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 200,
      viewportDimension: 400,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    ScrollStartNotification(
      metrics: metrics,
      context: context,
    ).dispatch(context);
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump(const Duration(milliseconds: 500));
    drainExpectedImageErrors(tester);
    return capturedMockRequests.where(isTotalsPoll).length;
  }

  void setupVote({DateTime? stopAt}) {
    setupMockSupabase({
      'vote': [_voteRow(stopAt: stopAt)],
      'vote_item': [
        _voteItemRow(id: 1, voteTotal: 5000),
        _voteItemRow(id: 2, voteTotal: 3000),
      ],
    });
  }

  group('VoteDetailPage poll cadence', () {
    testWidgets('live vote polls every second', (tester) async {
      setupVote();
      await pumpPage(tester);

      final polls = await pollTicksOver(tester, 5);
      expect(
        polls,
        greaterThanOrEqualTo(4),
        reason: '진행 중 투표는 1초 주기로 폴링해야 한다 (5초에 ~5회)',
      );
    });

    testWidgets(
      'ended vote polls every 5th tick inside the grace window, decided per tick',
      (tester) async {
        // 케이던스 판정이 initState 의 1회 평가면 이 테스트가 잡는다: 그 시점엔
        // isEnded 가 아직 false 라 종료 투표도 1초 주기로 돌았다 (리뷰에서
        // 런타임 실측 — 3.5초에 3회). 판정은 tick 마다 이뤄져야 한다.
        setupVote(stopAt: now.subtract(const Duration(seconds: 10)));
        await pumpPage(tester);

        final polls = await pollTicksOver(tester, 10);
        expect(
          polls,
          inInclusiveRange(1, 2),
          reason:
              '마감 직후에는 늦게 반영되는 득표를 받아야 하므로 폴링을 끊지 않되, '
              '5번째 tick 에만 폴링한다 (10초에 2회)',
        );
      },
    );

    testWidgets('ended vote stops polling when the grace window closes', (
      tester,
    ) async {
      final stopAt = now.subtract(const Duration(seconds: 10));
      setupVote(stopAt: stopAt);
      await pumpPage(tester);

      now = stopAt
          .add(voteEndedPollGrace)
          .subtract(const Duration(milliseconds: 1));
      expect(
        await pollTicksOver(tester, 10),
        greaterThanOrEqualTo(1),
        reason: '유예 창이 닫히기 직전까지는 폴링한다',
      );

      now = stopAt.add(voteEndedPollGrace);
      expect(
        await pollTicksOver(tester, 10),
        0,
        reason: '유예 창이 지나면 득표는 더 바뀌지 않는다 — 조회할 것이 없다',
      );
    });

    testWidgets('vote that ended before the grace window never polls', (
      tester,
    ) async {
      setupVote(stopAt: now.subtract(const Duration(days: 1)));
      await pumpPage(tester);

      expect(
        await pollTicksOver(tester, 10),
        0,
        reason: '오래전에 끝난 투표는 화면을 열어 둬도 득표를 다시 묻지 않는다',
      );
    });
  });

  group('VoteDetailPage scroll-settle refresh', () {
    testWidgets('live vote fetches totals once when scrolling settles', (
      tester,
    ) async {
      setupVote();
      await pumpPage(tester);

      expect(await totalsFetchesOnScrollSettle(tester), 1);
    });

    testWidgets('vote past the grace window fetches nothing on scroll settle', (
      tester,
    ) async {
      setupVote(stopAt: now.subtract(const Duration(days: 1)));
      await pumpPage(tester);

      expect(await totalsFetchesOnScrollSettle(tester), 0);
    });
  });
}
