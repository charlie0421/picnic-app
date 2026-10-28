import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_deadline_refresh.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
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

  Future<void> pumpPage(
    WidgetTester tester, {
    bool upcoming = false,
    int delaySeconds = 3,
    Map<String, int>? statusCodes,
    ValueNotifier<int>? voteId,
  }) async {
    setupMockSupabase({
      'vote': [
        _voteRow(
          startAt: upcoming ? now.add(const Duration(seconds: 10)) : null,
          stopAt: now.add(const Duration(seconds: 20)),
        ),
      ],
      'vote_item': [_voteItemRow(id: 1, voteTotal: 5000)],
    }, tableStatusCodes: statusCodes);
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        voteId == null
            ? const VoteDetailPage(voteId: 1)
            : ValueListenableBuilder<int>(
                valueListenable: voteId,
                builder: (_, id, _) => VoteDetailPage(voteId: id),
              ),
        extraOverrides: [
          voteDeadlineClockProvider.overrideWithValue(Clock(() => now)),
          voteDeadlineRefreshDelayProvider.overrideWithValue(
            () => Duration(seconds: delaySeconds),
          ),
        ],
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
    capturedMockRequests.clear();
  }

  Future<void> pump(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
    drainExpectedImageErrors(tester);
    await tester.pump();
    drainExpectedImageErrors(tester);
  }

  List<Uri> getRequests(String table) =>
      capturedMockRequests.where((u) => u.path.endsWith('/$table')).toList();
  VoidCallback expire(WidgetTester tester) {
    final callback = tester
        .widget<CountdownTimer>(find.byType(CountdownTimer))
        .onRefresh!;
    now = now.add(const Duration(seconds: 20));
    callback();
    return callback;
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets(
    'deadline closes locally before staggered detail and candidate requests',
    (tester) async {
      await pumpPage(tester);
      final callback = expire(tester);
      await pump(tester, Duration.zero);
      expect(
        tester.widget<CountdownTimer>(find.byType(CountdownTimer)).status,
        VoteStatus.end,
      );
      expect(getRequests('vote'), isEmpty);
      expect(getRequests('vote_item'), isEmpty);
      callback();
      await pump(tester, const Duration(milliseconds: 2999));
      expect(getRequests('vote'), isEmpty);
      expect(
        getRequests('vote_item'),
        isEmpty,
        reason: 'polling must not bypass the delay',
      );
      await pump(tester, const Duration(milliseconds: 1));
      expect(getRequests('vote'), hasLength(1));
      expect(
        getRequests(
          'vote_item',
        ).where((u) => u.queryParameters['select'] != 'id,vote_total'),
        hasLength(1),
      );
      callback();
      await pump(tester, const Duration(seconds: 1));
      expect(getRequests('vote'), hasLength(1));
      await dispose(tester);
    },
  );

  testWidgets('poll tick detects deadline before sending a totals request', (
    tester,
  ) async {
    await pumpPage(tester);
    now = now.add(const Duration(seconds: 20));
    await pump(tester, const Duration(seconds: 1));
    expect(
      tester.widget<CountdownTimer>(find.byType(CountdownTimer)).status,
      VoteStatus.end,
    );
    expect(getRequests('vote_item'), isEmpty);
    expect(getRequests('vote'), isEmpty);
    await dispose(tester);
  });

  testWidgets('disposing cancels the delayed final refresh', (tester) async {
    await pumpPage(tester);
    expire(tester);
    await pump(tester, Duration.zero);
    capturedMockRequests.clear();
    await dispose(tester);
    expect(getRequests('vote'), isEmpty);
    expect(getRequests('vote_item'), isEmpty);
  });

  testWidgets(
    'manual refresh is immediate and consumes the pending final refresh',
    (tester) async {
      await pumpPage(tester);
      expire(tester);
      await pump(tester, Duration.zero);
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await pump(tester, Duration.zero);
      await refresh;
      expect(getRequests('vote'), hasLength(1));
      await pump(tester, const Duration(seconds: 4));
      expect(getRequests('vote'), hasLength(1));
      await dispose(tester);
    },
  );

  testWidgets('upcoming start refresh is immediate', (tester) async {
    await pumpPage(tester, upcoming: true);
    now = now.add(const Duration(seconds: 10));
    tester.widget<CountdownTimer>(find.byType(CountdownTimer)).onRefresh!();
    await pump(tester, Duration.zero);
    expect(getRequests('vote'), hasLength(1));
    expect(
      tester.widget<CountdownTimer>(find.byType(CountdownTimer)).status,
      VoteStatus.active,
    );
    await dispose(tester);
  });
  for (final seconds in [1, 5]) {
    testWidgets('final refresh starts at the ${seconds}s jitter boundary', (
      tester,
    ) async {
      await pumpPage(tester, delaySeconds: seconds);
      expire(tester);
      await pump(tester, Duration(milliseconds: seconds * 1000 - 1));
      expect(getRequests('vote'), isEmpty);
      expect(getRequests('vote_item'), isEmpty);
      await pump(tester, const Duration(milliseconds: 1));
      expect(getRequests('vote'), hasLength(1));
      await dispose(tester);
    });
  }
  testWidgets(
    'manual refresh joins a slow final refresh without duplicate requests',
    (tester) async {
      await pumpPage(tester);
      tableResponseDelays['vote'] = const Duration(seconds: 2);
      tableResponseDelays['vote_item'] = const Duration(seconds: 2);
      expire(tester);
      await pump(tester, const Duration(seconds: 3));
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await pump(tester, const Duration(seconds: 2));
      await refresh;
      expect(getRequests('vote'), hasLength(1));
      expect(getRequests('vote_item'), hasLength(1));
      await dispose(tester);
    },
  );
  testWidgets('failed final requests release the automatic polling gate', (
    tester,
  ) async {
    final codes = <String, int>{};
    await pumpPage(tester, statusCodes: codes);
    codes['vote'] = 500;
    codes['vote_item'] = 500;
    expire(tester);
    await pump(tester, const Duration(seconds: 3));
    capturedMockRequests.clear();
    codes.clear();
    for (var i = 0; i < 6; i++) {
      await pump(tester, const Duration(seconds: 1));
    }
    expect(getRequests('vote_item'), isNotEmpty);
    await dispose(tester);
  });
  testWidgets('changing vote cancels the previous deadline reservation', (
    tester,
  ) async {
    final id = ValueNotifier(1);
    addTearDown(id.dispose);
    await pumpPage(tester, voteId: id);
    expire(tester);
    await pump(tester, Duration.zero);
    id.value = 2;
    await pump(tester, Duration.zero);
    await pump(tester, Duration.zero);
    capturedMockRequests.clear();
    await pump(tester, const Duration(seconds: 3));
    expect(
      getRequests('vote'),
      isEmpty,
      reason: 'old deadline callback must not refresh the new vote',
    );
    await dispose(tester);
  });
  testWidgets('pre-deadline refresh cannot consume the post-deadline refresh', (
    tester,
  ) async {
    await pumpPage(tester);
    tableResponseDelays['vote'] = const Duration(seconds: 6);
    tableResponseDelays['vote_item'] = const Duration(seconds: 6);
    final manual = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await pump(tester, Duration.zero);
    expect(getRequests('vote'), hasLength(1));
    expire(tester);
    await pump(tester, const Duration(seconds: 3));
    expect(
      getRequests('vote'),
      hasLength(2),
      reason: 'one request must start after the deadline',
    );
    await pump(tester, const Duration(seconds: 6));
    await manual;
    await dispose(tester);
  });

  testWidgets('scroll settling cannot bypass a pending deadline refresh', (
    tester,
  ) async {
    await pumpPage(tester);
    expire(tester);
    await pump(tester, Duration.zero);
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
    await pump(tester, const Duration(milliseconds: 500));
    expect(getRequests('vote'), isEmpty);
    expect(getRequests('vote_item'), isEmpty);
    await dispose(tester);
  });
  testWidgets(
    'manual refresh after the deadline replaces a pre-deadline request',
    (tester) async {
      await pumpPage(tester);
      tableResponseDelays['vote'] = const Duration(seconds: 6);
      tableResponseDelays['vote_item'] = const Duration(seconds: 6);
      final before = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await pump(tester, Duration.zero);
      expire(tester);
      await pump(tester, Duration.zero);
      final after = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await pump(tester, Duration.zero);
      expect(getRequests('vote'), hasLength(2));
      await pump(tester, const Duration(seconds: 6));
      await Future.wait([before, after]);
      await dispose(tester);
    },
  );
}
