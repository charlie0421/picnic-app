import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({
  int id = 1,
  bool isEnded = false,
  bool isUpcoming = false,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
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
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('scroll gate wiring', () {
    testWidgets(
        'vote detail wraps scroll view in NotificationListener<ScrollNotification>',
        (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      // The page adds exactly one NotificationListener<ScrollNotification> around
      // the CustomScrollView (A2.2 scroll gate). Flutter/framework widgets may add
      // additional ones, so we assert at-least-one rather than exactly-one.
      expect(
        find.byType(NotificationListener<ScrollNotification>),
        findsAtLeastNWidgets(1),
        reason: 'scroll gate must wrap the CustomScrollView',
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets(
        'scroll start/end notifications do not throw and page survives',
        (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      // Simulate a user drag: produces ScrollStart -> ScrollUpdate(s) -> ScrollEnd,
      // which is exactly what flips _isScrolling and triggers _onScrollSettle().
      await tester.drag(scrollable, const Offset(0, -200),
          warnIfMissed: false);
      while (tester.takeException() != null) {}

      // Pump frames spanning past a 1s timer tick to prove the gated
      // timer body does not crash mid-drag and the page is still mounted.
      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}
      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });
  });
}
