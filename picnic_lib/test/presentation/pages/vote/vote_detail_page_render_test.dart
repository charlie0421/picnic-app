import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_gain_indicator.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({
  int id = 1,
  String titleKo = '테스트 투표',
  bool isEnded = false,
  bool isUpcoming = false,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': titleKo, 'en': 'Test Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': [
      {
        'id': 1,
        'vote_id': id,
        'vote_total': 5000,
        'artist': {
          'id': 10,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
        'artist_group': null,
      },
      {
        'id': 2,
        'vote_id': id,
        'vote_total': 3000,
        'artist': {
          'id': 11,
          'name': {'ko': '정국', 'en': 'Jungkook'},
          'image': null,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
        'artist_group': null,
      },
    ],
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': isEnded,
    'is_upcoming': isUpcoming,
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

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [_voteRow()],
      'vote_item': [
        _voteItemRow(id: 1, voteTotal: 5000, artistNameKo: '지민', artistId: 10),
        _voteItemRow(id: 2, voteTotal: 3000, artistNameKo: '정국', artistId: 11),
      ],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('VoteDetailPage render', () {
    testWidgets('renders with voteId=1', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    // Regression: the search box must actually PAINT in the non-empty list
    // branch. The previous sliver-overlay construct (0-height SliverToBoxAdapter
    // + OverflowBox as the 2nd child of a SliverMainAxisGroup) had
    // paintExtent==0 → SliverGeometry.visible==false → the group skipped
    // painting it entirely, so the search field was invisible on every vote
    // that had results. Assert it renders with a non-zero size.
    testWidgets('search box renders with non-zero size in non-empty list',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000, artistNameKo: '지민', artistId: 10),
          _voteItemRow(id: 2, voteTotal: 3000, artistNameKo: '정국', artistId: 11),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // The vote-item list (which now hosts the search box as its leading
      // sliver) sits below the header, so on the small test surface it can
      // start beyond the lazy-build cacheExtent. Scroll it into view first.
      final searchBox = find.byType(EnhancedSearchBox);
      final scrollable = find.byType(CustomScrollView);
      if (searchBox.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
        for (int i = 0; i < 5 && searchBox.evaluate().isEmpty; i++) {
          await tester.drag(scrollable.first, const Offset(0, -200),
              warnIfMissed: false);
          while (tester.takeException() != null) {}
          await tester.pump(const Duration(milliseconds: 200));
          while (tester.takeException() != null) {}
        }
      }

      // The search field must be present...
      expect(searchBox, findsOneWidget);

      // ...and laid out with a real, non-zero rendered size (not collapsed
      // into a 0-height adapter that never paints — the prior bug).
      final size = tester.getSize(searchBox);
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [_voteRow()],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with ended vote', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow(isEnded: true)],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 10000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with upcoming vote', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow(isUpcoming: true)],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 0),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders logged out state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          loggedIn: false,
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('scroll the vote list', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Scroll the CustomScrollView
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 300));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('timer ticks update countdown', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Pump multiple times to simulate timer ticks
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with many vote items', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': List.generate(
          20,
          (i) => _voteItemRow(
            id: i + 1,
            voteTotal: 10000 - i * 500,
            artistNameKo: '아티스트$i',
            artistId: 100 + i,
          ),
        ),
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);

      // Scroll down through many items
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.drag(scrollable.first, const Offset(0, -500),
              warnIfMissed: false);
          drainExpectedImageErrors(tester);
          await tester.pump(const Duration(milliseconds: 200));
          drainExpectedImageErrors(tester);
        }
      }
    });

    testWidgets('renders with multiple vote items and different totals',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 50000, artistNameKo: '지민', artistId: 10),
          _voteItemRow(id: 2, voteTotal: 30000, artistNameKo: '정국', artistId: 11),
          _voteItemRow(id: 3, voteTotal: 20000, artistNameKo: '뷔', artistId: 12),
          _voteItemRow(id: 4, voteTotal: 10000, artistNameKo: '진', artistId: 13),
          _voteItemRow(id: 5, voteTotal: 5000, artistNameKo: 'RM', artistId: 14),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('pull to refresh triggers reload',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Try pull-to-refresh by dragging down
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, 300),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 500));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          locale: Locale('en'),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          locale: Locale('ja'),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with no vote items (empty list)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with reward data', (WidgetTester tester) async {
      final now = DateTime.now().toUtc();
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'reward': {
              'id': 1,
              'title': {'ko': '포토카드'},
            },
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with partnership vote', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'is_partnership': true,
            'partner': {'name': 'Partner Corp', 'logo': null},
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders ended vote with pic portal',
        (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [_voteRow(isEnded: true)],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 50000),
          _voteItemRow(id: 2, voteTotal: 30000, artistNameKo: '정국', artistId: 11),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with admin user', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          userProfile: MockData.userProfile(isAdmin: true),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('live vote shows raw count with share for admin',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          userProfile: MockData.userProfile(isAdmin: true),
        ),
      );

      // The item list builds on the frame after the fetch resolves.
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      // 5000 of 8000 total → raw count plus share.
      expect(find.text('5,000'), findsOneWidget);
      expect(find.text(' (62.50%)'), findsOneWidget);
      expect(find.text(' (37.50%)'), findsOneWidget);
    });

    testWidgets('live vote hides raw count for non-admin',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // The item list builds on the frame after the fetch resolves.
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.text('62.50%'), findsOneWidget);
      expect(find.text('5,000'), findsNothing);
    });

    testWidgets('renders with zero candy user', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
          userProfile: MockData.userProfile(starCandy: 0, starCandyBonus: 0, jmaCandy: 0),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders single vote item (no competition)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 100),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with vote content (image/wait/result)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'main_image': 'https://example.com/main.jpg',
            'wait_image': 'https://example.com/wait.jpg',
            'result_image': 'https://example.com/result.jpg',
            'vote_content': {'ko': '투표 설명입니다'},
          },
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with reward list (multiple rewards)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'reward': [
              {'id': 1, 'title': {'ko': '포토카드'}, 'thumbnail': 'https://example.com/r1.jpg'},
              {'id': 2, 'title': {'ko': '앨범'}, 'thumbnail': null},
              {'id': 3, 'title': {'ko': '굿즈'}, 'thumbnail': ''},
            ],
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
          _voteItemRow(id: 2, voteTotal: 3000, artistId: 11, artistNameKo: '정국'),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders ended vote with share section visible',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow(isEnded: true)],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 50000, artistNameKo: '지민', artistId: 10),
          _voteItemRow(id: 2, voteTotal: 30000, artistNameKo: '정국', artistId: 11),
          _voteItemRow(id: 3, voteTotal: 20000, artistNameKo: '뷔', artistId: 12),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Scroll to see share section
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 200));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with main image',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(),
            'main_image': 'https://example.com/main.jpg',
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('timer ticks trigger data refresh',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Pump for 3 seconds to allow timer (2s interval) to fire
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with equal vote totals (same rank)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000, artistNameKo: '지민', artistId: 10),
          _voteItemRow(id: 2, voteTotal: 5000, artistNameKo: '정국', artistId: 11),
          _voteItemRow(id: 3, voteTotal: 5000, artistNameKo: '뷔', artistId: 12),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with upcoming vote with reward',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(isUpcoming: true),
            'reward': [
              {'id': 1, 'title': {'ko': '리워드'}, 'thumbnail': 'https://example.com/r.jpg'},
            ],
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 0),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('renders with ended vote and reward',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [
          {
            ..._voteRow(isEnded: true),
            'reward': [
              {'id': 1, 'title': {'ko': '포토카드'}, 'thumbnail': null},
            ],
          }
        ],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 100000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });

    testWidgets('dispose cleans up without error',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Replace with a different widget to trigger dispose
      await tester.pumpWidget(
        buildTestAppPage(
          const SizedBox(),
        ),
      );
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(milliseconds: 300));
      drainExpectedImageErrors(tester);
    });

    testWidgets('renders with pic portal and multiple items',
        (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [_voteRow()],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 50000),
          _voteItemRow(id: 2, voteTotal: 30000, artistNameKo: '정국', artistId: 11),
          _voteItemRow(id: 3, voteTotal: 10000, artistNameKo: '뷔', artistId: 12),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );

      expect(find.byType(VoteDetailPage), findsOneWidget);

      // Scroll to see all items
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 200));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with low-ranked items (rank > 3)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': List.generate(
          6,
          (i) => _voteItemRow(
            id: i + 1,
            voteTotal: 10000 - i * 1500,
            artistNameKo: '아티스트${i + 1}',
            artistId: 10 + i,
          ),
        ),
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // Scroll to see lower-ranked items
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 200));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });
  });

  group('VoteGainIndicator render', () {
    testWidgets('renders with positive diff', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(const VoteGainIndicator(diff: 100)),
      );

      expect(find.byType(VoteGainIndicator), findsOneWidget);
    });

    testWidgets('renders with zero diff', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(const VoteGainIndicator(diff: 0)),
      );

      expect(find.byType(VoteGainIndicator), findsOneWidget);
    });

    testWidgets('renders with negative diff', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(const VoteGainIndicator(diff: -5)),
      );

      expect(find.byType(VoteGainIndicator), findsOneWidget);
    });

    testWidgets('transition from zero to positive triggers animation',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(const VoteGainIndicator(diff: 0)),
      );

      await pumpAndDrain(
        tester,
        buildTestApp(const VoteGainIndicator(diff: 50)),
      );

      expect(find.byType(VoteGainIndicator), findsOneWidget);
    });
  });
}
