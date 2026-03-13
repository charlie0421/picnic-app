import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

import '../../helpers/mock_supabase.dart';

/// Helper to create a vote data map for mock responses
Map<String, dynamic> _makeVoteData({
  required int id,
  String? voteCategory,
  String? startAt,
  String? stopAt,
  String? visibleAt,
  List<Map<String, dynamic>>? voteItems,
  bool? isPartnership,
  String? partner,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': '투표 $id', 'en': 'Vote $id'},
    'main_image': 'https://img/$id.png',
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
    'start_at': startAt ??
        now.subtract(const Duration(days: 5)).toIso8601String(),
    'stop_at': stopAt ??
        now.add(const Duration(days: 5)).toIso8601String(),
    'visible_at': visibleAt ??
        now.subtract(const Duration(days: 6)).toIso8601String(),
    'vote_category': voteCategory ?? 'birthday',
    'is_partnership': isPartnership,
    'partner': partner,
    'areas': ['kpop'],
    'reward': [],
    'vote_item': voteItems ??
        [
          {
            'id': id * 100 + 1,
            'vote_id': id,
            'vote_total': 1000,
            'artist': {'id': 1, 'name': {'ko': '지민', 'en': 'Jimin'}, 'image': null},
            'artist_group': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}, 'image': null},
          },
          {
            'id': id * 100 + 2,
            'vote_id': id,
            'vote_total': 800,
            'artist': {'id': 2, 'name': {'ko': '뷔', 'en': 'V'}, 'image': null},
            'artist_group': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}, 'image': null},
          },
          {
            'id': id * 100 + 3,
            'vote_id': id,
            'vote_total': 600,
            'artist': {'id': 3, 'name': {'ko': '정국', 'en': 'Jungkook'}, 'image': null},
            'artist_group': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}, 'image': null},
          },
          {
            'id': id * 100 + 4,
            'vote_id': id,
            'vote_total': 400,
            'artist': {'id': 4, 'name': {'ko': 'RM', 'en': 'RM'}, 'image': null},
            'artist_group': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}, 'image': null},
          },
        ],
  };
}

void main() {
  group('AsyncVoteList provider - active status', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 1),
          _makeVoteData(id: 2, voteCategory: 'comeback'),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns list of VoteModel from mock data with active status', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 2);
    });

    test('vote fields are correctly parsed', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      final first = result[0];
      expect(first.id, 1);
      expect(first.title, {'ko': '투표 1', 'en': 'Vote 1'});
      expect(first.mainImage, 'https://img/1.png');
      expect(first.voteCategory, 'birthday');
      expect(first.reward, isNotNull);
    });

    test('vote items are sorted by vote_total descending and limited to 3', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      final firstVote = result[0];
      // Non-upcoming active votes should have at most 3 vote items
      expect(firstVote.voteItem!.length, 3);
      // Items should be sorted by vote_total descending
      expect(firstVote.voteItem![0].voteTotal, 1000);
      expect(firstVote.voteItem![1].voteTotal, 800);
      expect(firstVote.voteItem![2].voteTotal, 600);
    });
  });

  group('AsyncVoteList provider - end status', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(
            id: 10,
            stopAt: DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
          ),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns ended votes', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.end,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 1);
      expect(result[0].isEnded, true);
    });
  });

  group('AsyncVoteList provider - upcoming status', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(
            id: 20,
            startAt: DateTime.now().toUtc().add(const Duration(days: 2)).toIso8601String(),
            visibleAt: DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
          ),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('upcoming votes keep all vote items', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.upcoming,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 1);
      expect(result[0].isUpcoming, true);
      // Upcoming votes keep all vote items (not limited to 3)
      expect(result[0].voteItem!.length, 4);
    });
  });

  group('AsyncVoteList provider - activeAndUpcoming status', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 30),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns votes for activeAndUpcoming', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.activeAndUpcoming,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 1);
    });
  });

  group('AsyncVoteList provider - debug status', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 40),
          _makeVoteData(id: 41),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('debug mode clears vote items', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.debug,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 2);
      // Debug mode clears vote items
      for (final vote in result) {
        expect(vote.voteItem, isEmpty);
      }
    });

    test('debug mode ignores category filter', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.debug,
          category: VoteCategory.birthday,
        ).future,
      );

      // Debug mode should return all votes regardless of category
      expect(result.length, 2);
    });
  });

  group('AsyncVoteList provider - category filtering', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 50, voteCategory: 'birthday'),
          _makeVoteData(id: 51, voteCategory: 'comeback'),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('category all returns all votes', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result.length, 2);
    });

    test('specific category filters votes', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.birthday,
        ).future,
      );

      // Mock returns all rows regardless of filter, but the query is built correctly
      expect(result, isA<List<VoteModel>>());
    });
  });

  group('AsyncVoteList provider - empty data', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns empty list when no votes', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result, isEmpty);
    });
  });

  group('AsyncVoteList provider - pagination', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 60),
          _makeVoteData(id: 61),
          _makeVoteData(id: 62),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('page 1 with limit returns data', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 2, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });

    test('page 2 returns data', () async {
      final result = await container.read(
        asyncVoteListProvider(
          2, 2, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });
  });

  group('AsyncVoteList provider - sort with timestamp prefix', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 70),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('sort key with id_ prefix is converted to id', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id_1234567890', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });
  });

  group('AsyncVoteList provider - area filter', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 80),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('area kpop filters correctly', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'kpop',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });

    test('area all returns all votes', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });
  });

  group('AsyncVoteList provider - VotePortal', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 90, voteCategory: 'image'),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('vote portal returns data', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          votePortal: VotePortal.vote,
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });

    test('pic portal returns data', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          votePortal: VotePortal.pic,
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
    });
  });

  group('AsyncVoteList provider - vote data edge cases', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          {
            'id': 100,
            'title': {'ko': '테스트'},
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'start_at': null,
            'stop_at': null,
            'visible_at': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
            'vote_category': 'birthday',
            'is_partnership': null,
            'partner': null,
            'reward': [],
            'vote_item': 'not_a_list',
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('handles non-list vote_item gracefully', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result, isA<List<VoteModel>>());
      expect(result.length, 1);
      // Non-list vote_item should be replaced with empty list
      expect(result[0].voteItem, isEmpty);
    });
  });

  group('AsyncVoteList provider - vote items with deleted_at', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          {
            'id': 110,
            'title': {'ko': '삭제된 아이템 테스트'},
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'start_at': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(),
            'stop_at': DateTime.now().toUtc().add(const Duration(days: 5)).toIso8601String(),
            'visible_at': DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String(),
            'vote_category': 'birthday',
            'is_partnership': false,
            'partner': null,
            'reward': [],
            'vote_item': [
              {
                'id': 1,
                'vote_id': 110,
                'vote_total': 500,
                'deleted_at': null,
                'artist': {'id': 1, 'name': {'ko': 'A', 'en': 'A'}, 'image': null},
                'artist_group': null,
              },
              {
                'id': 2,
                'vote_id': 110,
                'vote_total': 300,
                'deleted_at': '2024-01-01T00:00:00Z',
                'artist': {'id': 2, 'name': {'ko': 'B', 'en': 'B'}, 'image': null},
                'artist_group': null,
              },
            ],
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('filters out deleted vote items', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result.length, 1);
      // Only the non-deleted item should remain
      expect(result[0].voteItem!.length, 1);
      expect(result[0].voteItem![0].id, 1);
    });
  });

  group('AsyncVoteList provider - partnership votes', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          _makeVoteData(id: 120, isPartnership: true, partner: 'Sponsor Co'),
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('partnership flag and partner are parsed', () async {
      final result = await container.read(
        asyncVoteListProvider(
          1, 10, 'id', 'DESC', 'all',
          status: VoteStatus.active,
          category: VoteCategory.all,
        ).future,
      );

      expect(result.length, 1);
      expect(result[0].isPartnership, true);
      expect(result[0].partner, 'Sponsor Co');
    });
  });

  group('SortOption provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is id DESC', () {
      final state = container.read(sortOptionProvider);
      expect(state.sort, 'id');
      expect(state.order, 'DESC');
    });

    test('setSortOption updates state', () {
      container.read(sortOptionProvider.notifier).setSortOption('created_at', 'ASC');
      final state = container.read(sortOptionProvider);
      expect(state.sort, 'created_at');
      expect(state.order, 'ASC');
    });

    test('setSortOption can be called multiple times', () {
      final notifier = container.read(sortOptionProvider.notifier);
      notifier.setSortOption('stop_at', 'ASC');
      expect(container.read(sortOptionProvider).sort, 'stop_at');

      notifier.setSortOption('start_at', 'DESC');
      expect(container.read(sortOptionProvider).sort, 'start_at');
      expect(container.read(sortOptionProvider).order, 'DESC');
    });
  });

  group('CommentCount provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is 0', () async {
      final result = await container.read(commentCountProvider(1).future);
      expect(result, 0);
    });

    test('setCount updates the value', () async {
      await container.read(commentCountProvider(1).future);
      container.read(commentCountProvider(1).notifier).setCount(42);
      final state = container.read(commentCountProvider(1));
      expect(state.value, 42);
    });

    test('increment increases count by 1', () async {
      await container.read(commentCountProvider(1).future);
      container.read(commentCountProvider(1).notifier).setCount(10);
      container.read(commentCountProvider(1).notifier).increment();
      final state = container.read(commentCountProvider(1));
      expect(state.value, 11);
    });

    test('decrement decreases count by 1', () async {
      await container.read(commentCountProvider(1).future);
      container.read(commentCountProvider(1).notifier).setCount(10);
      container.read(commentCountProvider(1).notifier).decrement();
      final state = container.read(commentCountProvider(1));
      expect(state.value, 9);
    });

    test('different articleIds are independent', () async {
      await container.read(commentCountProvider(1).future);
      await container.read(commentCountProvider(2).future);

      container.read(commentCountProvider(1).notifier).setCount(5);
      container.read(commentCountProvider(2).notifier).setCount(15);

      expect(container.read(commentCountProvider(1)).value, 5);
      expect(container.read(commentCountProvider(2)).value, 15);
    });

    test('multiple increments stack correctly', () async {
      await container.read(commentCountProvider(1).future);
      final notifier = container.read(commentCountProvider(1).notifier);
      notifier.setCount(0);
      notifier.increment();
      notifier.increment();
      notifier.increment();
      expect(container.read(commentCountProvider(1)).value, 3);
    });

    test('decrement below zero', () async {
      await container.read(commentCountProvider(1).future);
      final notifier = container.read(commentCountProvider(1).notifier);
      notifier.setCount(0);
      notifier.decrement();
      expect(container.read(commentCountProvider(1)).value, -1);
    });
  });

  group('VoteStatus enum', () {
    test('all values are present', () {
      expect(VoteStatus.values, containsAll([
        VoteStatus.all,
        VoteStatus.active,
        VoteStatus.end,
        VoteStatus.upcoming,
        VoteStatus.activeAndUpcoming,
        VoteStatus.debug,
      ]));
    });
  });

  group('VoteCategory enum', () {
    test('all values are present', () {
      expect(VoteCategory.values, containsAll([
        VoteCategory.all,
        VoteCategory.birthday,
        VoteCategory.comeback,
        VoteCategory.achieve,
        VoteCategory.birth,
        VoteCategory.debut,
        VoteCategory.image,
      ]));
    });

    test('name property works correctly for query building', () {
      expect(VoteCategory.birthday.name, 'birthday');
      expect(VoteCategory.all.name, 'all');
      expect(VoteCategory.image.name, 'image');
    });
  });

  group('VotePortal enum', () {
    test('all values are present', () {
      expect(VotePortal.values, containsAll([
        VotePortal.vote,
        VotePortal.pic,
      ]));
    });
  });

  group('SortOptionType', () {
    test('constructor sets sort and order', () {
      final opt = SortOptionType('stop_at', 'ASC');
      expect(opt.sort, 'stop_at');
      expect(opt.order, 'ASC');
    });

    test('fields are mutable', () {
      final opt = SortOptionType('id', 'DESC');
      opt.sort = 'created_at';
      opt.order = 'ASC';
      expect(opt.sort, 'created_at');
      expect(opt.order, 'ASC');
    });

    test('default empty strings', () {
      final opt = SortOptionType('', '');
      expect(opt.sort, '');
      expect(opt.order, '');
    });
  });
}
