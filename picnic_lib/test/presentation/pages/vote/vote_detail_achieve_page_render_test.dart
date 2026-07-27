import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({int id = 1}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': '달성 투표', 'en': 'Achievement Vote'},
    'vote_category': 'achieve',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  int artistId = 10,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': null,
      },
    },
    'artist_group': null,
  };
}

/// [nullTitle] 은 운영자가 보상 제목을 비워둔 행을 재현한다.
/// `RewardModel.title` 은 `thumbnail` 과 같은 순수 nullable 컬럼이다.
Map<String, dynamic> _voteAchieveRow({
  int id = 1,
  int voteId = 1,
  int rewardId = 1,
  int order = 1,
  int amount = 10000,
  bool nullTitle = false,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'reward_id': rewardId,
    'order': order,
    'amount': amount,
    'reward': {
      'id': rewardId,
      'title': nullTitle ? null : {'ko': '포토카드'},
      'thumbnail': null,
    },
    'vote': _voteRow(id: voteId),
  };
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [_voteRow()],
      'vote_item': [
        _voteItemRow(id: 1, voteTotal: 5000),
        _voteItemRow(id: 2, voteTotal: 3000, artistId: 11, artistNameKo: '정국'),
      ],
      'vote_achieve': [
        _voteAchieveRow(id: 1, order: 1, amount: 10000),
        _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
      ],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  /// 실제 콘텐츠를 단언하는 테스트용. provider 두 개가 순차로(바깥 → 안쪽)
  /// 구독되므로 프레임을 몇 번 더 돌려야 둘 다 resolve 된다.
  ///
  /// 100ms 씩 굴리는 것은 의도적이다 — 1초를 넘기면 `_updateTimer` 주기와
  /// `BannerAdWidget._scheduleRetry` 의 취소 불가 재시도가 발화해 테스트 종료
  /// 시점에 `!timersPending` 단언이 터진다.
  Future<void> pumpUntilContent(WidgetTester tester, widget) async {
    await pumpWidgetAndIgnoreErrors(tester, widget);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 콘텐츠가 실제로 그려지면 [BannerAdWidget] 이 마운트되고, 그 `_scheduleRetry`
  /// 는 취소 불가능한 `Future.delayed` 를 남긴다 (최대 25초). 언마운트한 뒤
  /// 만료시키지 않으면 테스트 종료 시 `!timersPending` 이 터진다.
  ///
  /// 기존 테스트들이 이걸 안 겪는 이유는 1회 pump 로는 페이지가 아직 비어 있어
  /// 배너 자체가 마운트되지 않기 때문이다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  Future<void> pumpAndDrain(WidgetTester tester, widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('VoteDetailAchievePage render', () {
    testWidgets('renders with voteId=1', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [_voteRow()],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
        ],
      });

      await pumpUntilContent(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      // 페이지가 존재한다는 것만으로는 부족하다. 상세 provider 에 votePortal 을
      // 넘기지 않으면 `pic_vote` 대신 `vote` 를 조회해 상세가 널로 돌아오고,
      // 상세가 바깥 게이트이므로 페이지 전체가 SizedBox.shrink() 가 된다.
      // 위 단언만으로는 그 백지 상태도 그대로 통과한다.
      expect(find.text('리워드1'), findsOneWidget);
      expect(find.text('포토카드'), findsOneWidget);

      await settle(tester);
    });

    testWidgets('reward with null title does not crash the milestone ladder', (
      WidgetTester tester,
    ) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [_voteItemRow(id: 1, voteTotal: 5000)],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000, nullTitle: true),
        ],
      });

      await pumpUntilContent(
        tester,
        buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
      );

      // 제목이 널이면 빈 문자열로 접히고 사다리는 계속 그려져야 한다.
      // `reward.title!` 로 되돌리면 여기서 널 단언이 터진다.
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      expect(find.text('리워드1'), findsOneWidget);
      expect(find.text('포토카드'), findsNothing);

      await settle(tester);
    });

    testWidgets('renders logged out state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
          loggedIn: false,
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('scroll the achieve page', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -400),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 300));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('timer ticks for countdown', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      // Pump multiple times to simulate timer ticks
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
        drainExpectedImageErrors(tester);
      }
      // Pump with zero duration to let confetti/animation controllers settle
      await tester.pump(Duration.zero);
      drainExpectedImageErrors(tester);

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    }, skip: true);

    testWidgets('renders with multiple achieve milestones',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
          _voteItemRow(id: 2, voteTotal: 3000, artistId: 11, artistNameKo: '정국'),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
          _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
          _voteAchieveRow(id: 3, order: 3, rewardId: 3, amount: 100000),
          _voteAchieveRow(id: 4, order: 4, rewardId: 4, amount: 500000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);

      // Scroll down through milestones
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -600),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 200));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with ended vote in achieve page',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'is_ended': true,
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 100000),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
          _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with no achieve milestones',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
        'vote_achieve': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with partially achieved milestones',
        (WidgetTester tester) async {
      // Vote total of 15000 surpasses first milestone (10000) but not second (50000)
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 15000),
          _voteItemRow(id: 2, voteTotal: 8000, artistId: 11, artistNameKo: '정국'),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
          _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
          _voteAchieveRow(id: 3, order: 3, rewardId: 3, amount: 100000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with all milestones achieved',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 600000),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
          _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
          _voteAchieveRow(id: 3, order: 3, rewardId: 3, amount: 100000),
          _voteAchieveRow(id: 4, order: 4, rewardId: 4, amount: 500000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      // Scroll to see all milestones
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.drag(scrollable.first, const Offset(0, -400),
              warnIfMissed: false);
          drainExpectedImageErrors(tester);
          await tester.pump(const Duration(milliseconds: 200));
          drainExpectedImageErrors(tester);
        }
      }

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with upcoming vote in achieve page',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'is_upcoming': true,
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 0),
        ],
        'vote_achieve': [
          _voteAchieveRow(id: 1, order: 1, amount: 10000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with single vote item and many achievements',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 1000),
        ],
        'vote_achieve': List.generate(
          5,
          (i) => _voteAchieveRow(
            id: i + 1,
            order: i + 1,
            rewardId: i + 1,
            amount: (i + 1) * 10000,
          ),
        ),
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('dispose cleans up without error',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        buildTestAppPage(
          const SizedBox(),
        ),
      );
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(milliseconds: 300));
      drainExpectedImageErrors(tester);
    });

    testWidgets('renders with English locale',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
          locale: const Locale('en'),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
          locale: const Locale('ja'),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with reward that has thumbnail',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
        'vote_achieve': [
          {
            ..._voteAchieveRow(id: 1, order: 1, amount: 10000),
            'reward': {
              'id': 1,
              'title': {'ko': '포토카드'},
              'thumbnail': 'https://example.com/thumb.jpg',
            },
          },
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('pull to refresh', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
        ),
      );

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, 300),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 500));
        drainExpectedImageErrors(tester);
      }
    });
  });
}
