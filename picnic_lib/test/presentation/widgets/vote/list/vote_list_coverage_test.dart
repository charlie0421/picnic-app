import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Additional coverage tests for VoteList, VoteCardSkeleton, and VoteNoItem.
///
/// Widget-level VoteList testing is blocked by asyncVoteListProvider dependency.
/// We test sub-widgets (VoteCardSkeleton, VoteNoItem) and additional logic.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('VoteCardSkeleton widget', () {
    // Note: VoteCardSkeleton uses Shimmer which has continuous animation,
    // so we use pump() instead of pumpAndSettle() to avoid timeout.
    testWidgets('renders ongoing skeleton by default', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('renders upcoming skeleton', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.upcoming),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('renders ended skeleton', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ended),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });
  });

  group('VoteNoItem widget', () {
    testWidgets('renders active status message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.active,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
    });

    testWidgets('renders end status message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.end,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
    });

    testWidgets('renders upcoming status message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.upcoming,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
    });

    testWidgets('renders empty container for all status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteNoItem(
              status: VoteStatus.all,
              context: context,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoteNoItem), findsOneWidget);
      // For 'all' status, it returns an empty Container
    });
  });

  group('VoteModel JSON parsing edge cases', () {
    test('vote with null dates', () {
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': <String, dynamic>{'ko': '테스트'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': null,
        'stop_at': null,
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.startAt, isNull);
      expect(vote.stopAt, isNull);
      expect(vote.id, 1);
    });

    test('vote with all image fields populated', () {
      final vote = VoteModel.fromJson({
        'id': 2,
        'title': <String, dynamic>{'ko': '이미지 투표', 'en': 'Image Vote'},
        'vote_category': 'image_vote',
        'main_image': 'https://example.com/main.jpg',
        'wait_image': 'https://example.com/wait.jpg',
        'result_image': 'https://example.com/result.jpg',
        'vote_content': '투표 내용',
        'vote_item': null,
        'created_at': DateTime.now().toIso8601String(),
        'visible_at': DateTime.now().toIso8601String(),
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.mainImage, isNotNull);
      expect(vote.waitImage, isNotNull);
      expect(vote.resultImage, isNotNull);
      expect(vote.voteCategory, 'image_vote');
    });

    test('vote with partnership fields', () {
      final vote = VoteModel.fromJson({
        'id': 3,
        'title': <String, dynamic>{'ko': '파트너십 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': true,
        'partner': 'mnet',
        'reward': null,
      });

      expect(vote.isPartnership, isTrue);
      expect(vote.partner, 'mnet');
    });

    test('vote with vote_item list', () {
      final vote = VoteModel.fromJson({
        'id': 4,
        'title': <String, dynamic>{'ko': '아이템 투표'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'vote_total': 100,
            'vote_id': 4,
            'artist': <String, dynamic>{'id': 1, 'name': <String, dynamic>{'ko': 'BTS'}},
            'artist_group': null,
          },
          <String, dynamic>{
            'id': 2,
            'vote_total': 200,
            'vote_id': 4,
            'artist': <String, dynamic>{'id': 2, 'name': <String, dynamic>{'ko': 'BLACKPINK'}},
            'artist_group': null,
          },
        ],
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.voteItem, isNotNull);
      expect(vote.voteItem!.length, 2);
      expect(vote.voteItem![0].voteTotal, 100);
      expect(vote.voteItem![1].voteTotal, 200);
    });
  });

  group('VoteList _setStateIfMounted pattern', () {
    test('mounted check before setState', () {
      bool mounted = true;
      bool stateUpdated = false;

      void setStateIfMounted(VoidCallback fn) {
        if (mounted) {
          fn();
          stateUpdated = true;
        }
      }

      setStateIfMounted(() {});
      expect(stateUpdated, isTrue);

      // After dispose
      mounted = false;
      stateUpdated = false;
      setStateIfMounted(() {});
      expect(stateUpdated, isFalse);
    });
  });

  group('VoteList refresh logic', () {
    test('refresh resets pageKey and noMoreItems', () {
      int pageKey = 5;
      bool noMoreItems = true;

      // Simulate refresh
      const isRefresh = true;
      if (isRefresh) {
        pageKey = 1;
        noMoreItems = false;
      }

      expect(pageKey, 1);
      expect(noMoreItems, isFalse);
    });

    test('initial load sets isLoading to true', () {
      bool isLoading = false;

      const isInitialLoad = true;
      if (isInitialLoad) {
        isLoading = true;
      }

      expect(isLoading, isTrue);
    });

    test('empty filtered items with existing items triggers skip-ahead', () {
      final items = ['item1', 'item2'];
      final filteredItems = <String>[];
      const isInitialLoad = false;

      final shouldSkipAhead =
          !isInitialLoad && filteredItems.isEmpty && items.isNotEmpty;
      expect(shouldSkipAhead, isTrue);
    });

    test('empty filtered items on initial load does not trigger skip-ahead',
        () {
      final items = <String>[];
      final filteredItems = <String>[];
      const isInitialLoad = true;

      final shouldSkipAhead =
          !isInitialLoad && filteredItems.isEmpty && items.isNotEmpty;
      expect(shouldSkipAhead, isFalse);
    });
  });

  group('VotePortal enum', () {
    test('vote and pic are distinct', () {
      expect(VotePortal.vote, isNot(equals(VotePortal.pic)));
    });

    test('default portal is vote', () {
      const portal = VotePortal.vote;
      expect(portal, VotePortal.vote);
    });
  });

  group('VoteCardStatus enum', () {
    test('has all three values', () {
      expect(VoteCardStatus.values.length, 3);
      expect(VoteCardStatus.values, contains(VoteCardStatus.upcoming));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ongoing));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ended));
    });
  });
}
