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

  /// Pumps [widget] and drains any pre-existing infrastructure exceptions
  /// (e.g. "No Material ancestor for TextField" from EnhancedSearchBox).
  /// Any exception that is NOT the known pre-existing Material/TextField error
  /// is re-asserted as null to surface unexpected failures.
  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    final ex1 = tester.takeException();
    if (ex1 != null) {
      expect(ex1.toString(), contains('No Material widget found'),
          reason: 'unexpected exception during initial pumpWidget');
    }
    await tester.pump(const Duration(seconds: 1));
    final ex2 = tester.takeException();
    if (ex2 != null) {
      expect(ex2.toString(), contains('No Material widget found'),
          reason: 'unexpected exception after 1s pump');
    }
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
        'scroll gate arms on ScrollStart and disarms on ScrollEnd',
        (tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailPage(voteId: 1),
        ),
      );

      final scrollable = find.byType(CustomScrollView);
      expect(scrollable, findsOneWidget);

      // Locate the State to inspect the gate.
      final state = tester.state<VoteDetailPageState>(
        find.byType(VoteDetailPage),
      );

      // Gate should be disarmed before any scroll.
      expect(state.isScrollingForTest, isFalse,
          reason: 'gate must be disarmed before scrolling starts');

      // Start an in-progress gesture (produces ScrollStart + ScrollUpdate).
      final center = tester.getCenter(scrollable);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, -200));
      await tester.pump();

      expect(state.isScrollingForTest, isTrue,
          reason: 'gate must be armed while drag is in progress');
      // Drain any pre-existing EnhancedSearchBox/Material infrastructure
      // exception that surfaces during renders; assert it is only that known
      // issue, not a gate-introduced crash.
      final exDuringDrag = tester.takeException();
      if (exDuringDrag != null) {
        expect(exDuringDrag.toString(), contains('No Material widget found'),
            reason: 'unexpected exception during in-progress drag');
      }

      // Complete the gesture (produces ScrollEnd).
      await gesture.up();
      // pumpAndSettle may surface a pre-existing "No Material ancestor for
      // TextField" from EnhancedSearchBox; that is unrelated to the gate under
      // test. Drain it, but assert it is ONLY that known error (not a new one
      // from the gate logic).
      await tester.pump(const Duration(milliseconds: 100));
      final exAfterUp = tester.takeException();
      if (exAfterUp != null) {
        expect(
          exAfterUp.toString(),
          contains('No Material widget found'),
          reason:
              'only the known pre-existing EnhancedSearchBox/Material error '
              'is acceptable here; any other exception is a gate-introduced bug',
        );
      }

      expect(state.isScrollingForTest, isFalse,
          reason: 'gate must be disarmed after drag completes');

      // Page must still be mounted.
      expect(find.byType(VoteDetailPage), findsOneWidget);

      // Pump frames spanning past a 1s timer tick to prove the gated timer
      // body does not crash after settle.
      await tester.pump(const Duration(milliseconds: 500));
      final ex500 = tester.takeException();
      if (ex500 != null) {
        expect(ex500.toString(), contains('No Material widget found'),
            reason: 'unexpected exception at 500ms post-settle');
      }
      await tester.pump(const Duration(seconds: 1));
      final ex1s = tester.takeException();
      if (ex1s != null) {
        expect(ex1s.toString(), contains('No Material widget found'),
            reason: 'unexpected exception at 1s post-settle');
      }

      expect(find.byType(VoteDetailPage), findsOneWidget);
    });
  });
}
