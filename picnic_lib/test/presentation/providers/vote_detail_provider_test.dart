import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncVoteDetail', () {
    late ProviderContainer container;

    final voteData = {
      'id': 1,
      'title': {'ko': '인기 투표', 'en': 'Popular Vote'},
      'vote_category': 'idol',
      'main_image': 'https://example.com/main.png',
      'wait_image': null,
      'result_image': null,
      'vote_content': null,
      'start_at': '2025-01-01T00:00:00Z',
      'stop_at': '2099-12-31T23:59:59Z',
      'visible_at': '2025-01-01T00:00:00Z',
      'created_at': '2025-01-01T00:00:00Z',
      'is_ended': false,
      'is_upcoming': false,
      'is_partnership': false,
      'partner': null,
      'vote_item': [],
      'reward': [],
    };

    setUp(() {
      setupMockSupabase({
        'vote': [voteData],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches vote detail from supabase', () async {
      final result = await container.read(
        asyncVoteDetailProvider(voteId: 1).future,
      );
      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.title['ko'], '인기 투표');
      expect(result.voteCategory, 'idol');
    });

    test('fetches vote detail for pic portal', () async {
      tearDownMockSupabase();
      container.dispose();

      final picVoteData = {
        ...voteData,
        'id': 2,
        'title': {'ko': 'PIC 투표'},
      };
      setupMockSupabase({
        'pic_vote': [picVoteData],
      });
      container = ProviderContainer();

      final result = await container.read(
        asyncVoteDetailProvider(
          voteId: 2,
          votePortal: VotePortal.pic,
        ).future,
      );
      expect(result, isNotNull);
      expect(result!.id, 2);
    });
  });

  group('AsyncVoteDetail - error handling', () {
    late ProviderContainer container;

    setUp(() {
      // No vote data configured -> will cause an error when .single() is called
      // on an empty result (the mock returns null for single on empty list)
      setupMockSupabase({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns null when fetch fails (error path)', () async {
      final result = await container.read(
        asyncVoteDetailProvider(voteId: 9999).future,
      );
      // The catch block should return null
      expect(result, isNull);
    });

    test('returns null on error for pic portal', () async {
      final result = await container.read(
        asyncVoteDetailProvider(
          voteId: 9999,
          votePortal: VotePortal.pic,
        ).future,
      );
      expect(result, isNull);
    });
  });

  group('AsyncVoteDetail - ended vote', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          {
            'id': 3,
            'title': {'ko': '종료된 투표'},
            'vote_category': 'birthday',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'start_at': '2020-01-01T00:00:00Z',
            'stop_at': '2020-12-31T23:59:59Z',
            'visible_at': '2020-01-01T00:00:00Z',
            'created_at': '2020-01-01T00:00:00Z',
            'is_ended': true,
            'is_upcoming': false,
            'is_partnership': true,
            'partner': 'TestPartner',
            'vote_item': [],
            'reward': [],
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches ended vote and sets is_ended correctly', () async {
      final result = await container.read(
        asyncVoteDetailProvider(voteId: 3).future,
      );
      expect(result, isNotNull);
      expect(result!.id, 3);
      // The provider recalculates is_ended based on stop_at vs now
      // Since stop_at is 2020-12-31, it should be ended
      expect(result.isEnded, isTrue);
      expect(result.isPartnership, isTrue);
      expect(result.partner, 'TestPartner');
    });
  });

  group('AsyncVoteDetail - upcoming vote', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote': [
          {
            'id': 4,
            'title': {'ko': '예정 투표'},
            'vote_category': 'comeback',
            'main_image': null,
            'wait_image': null,
            'result_image': null,
            'vote_content': null,
            'start_at': '2099-01-01T00:00:00Z',
            'stop_at': '2099-12-31T23:59:59Z',
            'visible_at': '2099-01-01T00:00:00Z',
            'created_at': '2025-01-01T00:00:00Z',
            'is_ended': false,
            'is_upcoming': true,
            'is_partnership': false,
            'partner': null,
            'vote_item': [],
            'reward': [],
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches upcoming vote and sets is_upcoming correctly', () async {
      final result = await container.read(
        asyncVoteDetailProvider(voteId: 4).future,
      );
      expect(result, isNotNull);
      expect(result!.id, 4);
      // start_at is 2099, so is_upcoming should be true
      expect(result.isUpcoming, isTrue);
      expect(result.isEnded, isFalse);
    });
  });

  group('AsyncVoteItemList', () {
    late ProviderContainer container;

    final voteItems = [
      {
        'id': 10,
        'vote_id': 1,
        'vote_total': 500,
        'artist': {
          'id': 100,
          'name': {'ko': '아이유', 'en': 'IU'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
        'deleted_at': null,
      },
      {
        'id': 11,
        'vote_id': 1,
        'vote_total': 300,
        'artist': {
          'id': 101,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS'},
            'image': null,
          },
        },
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS'},
          'image': null,
        },
        'deleted_at': null,
      },
    ];

    setUp(() {
      setupMockSupabase({
        'vote_item': voteItems,
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches vote item list from supabase', () async {
      final result = await container.read(
        asyncVoteItemListProvider(voteId: 1).future,
      );
      expect(result, isNotNull);
      expect(result.length, 2);
      expect(result[0]!.id, 10);
      expect(result[0]!.voteTotal, 500);
      expect(result[1]!.artist!.id, 101);
    });

    test('returns items sorted by vote_total descending', () async {
      final result = await container.read(
        asyncVoteItemListProvider(voteId: 1).future,
      );
      expect(result[0]!.voteTotal! >= result[1]!.voteTotal!, isTrue);
    });
  });

  group('AsyncVoteItemList - pic portal', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'pic_vote_item': [
          {
            'id': 20,
            'vote_id': 5,
            'vote_total': 100,
            'artist': {
              'id': 200,
              'name': {'ko': '리사', 'en': 'Lisa'},
              'image': null,
              'artist_group': null,
            },
            'artist_group': null,
            'deleted_at': null,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches pic vote items', () async {
      final result = await container.read(
        asyncVoteItemListProvider(
          voteId: 5,
          votePortal: VotePortal.pic,
        ).future,
      );
      expect(result, isNotNull);
      expect(result.length, 1);
      expect(result[0]!.id, 20);
    });
  });

  group('AsyncVoteItemList - error handling', () {
    late ProviderContainer container;

    setUp(() {
      // Empty mock - queries will return empty but shouldn't throw
      setupMockSupabase({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns empty list when no items found', () async {
      final result = await container.read(
        asyncVoteItemListProvider(voteId: 999).future,
      );
      expect(result, isEmpty);
    });
  });

  group('AsyncVoteItemList - setVoteItem', () {
    late ProviderContainer container;

    final voteItems = [
      {
        'id': 10,
        'vote_id': 1,
        'vote_total': 500,
        'artist': {
          'id': 100,
          'name': {'ko': '아이유', 'en': 'IU'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
        'deleted_at': null,
      },
      {
        'id': 11,
        'vote_id': 1,
        'vote_total': 300,
        'artist': {
          'id': 101,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
        'deleted_at': null,
      },
    ];

    setUp(() {
      setupMockSupabase({
        'vote_item': voteItems,
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('setVoteItem updates vote total for matching item', () async {
      // First, wait for the initial fetch to complete
      await container.read(
        asyncVoteItemListProvider(voteId: 1).future,
      );

      final notifier = container.read(
        asyncVoteItemListProvider(voteId: 1).notifier,
      );

      // Update vote total for item id=11
      await notifier.setVoteItem(id: 11, voteTotal: 1000);

      final state = container.read(
        asyncVoteItemListProvider(voteId: 1),
      );
      expect(state.value, isNotNull);
      // After setVoteItem, item 11 should have voteTotal=1000
      final item11 = state.value!.firstWhere((i) => i!.id == 11);
      expect(item11!.voteTotal, 1000);
    });

    test('setVoteItem re-sorts by vote_total descending', () async {
      await container.read(
        asyncVoteItemListProvider(voteId: 1).future,
      );

      final notifier = container.read(
        asyncVoteItemListProvider(voteId: 1).notifier,
      );

      // Make item 11 have higher vote total than item 10
      await notifier.setVoteItem(id: 11, voteTotal: 1000);

      final state = container.read(
        asyncVoteItemListProvider(voteId: 1),
      );
      // Item 11 (1000) should now be first, item 10 (500) second
      expect(state.value![0]!.voteTotal, 1000);
      expect(state.value![1]!.voteTotal, 500);
    });

    test('setVoteItem with non-matching id does not change totals', () async {
      await container.read(
        asyncVoteItemListProvider(voteId: 1).future,
      );

      final notifier = container.read(
        asyncVoteItemListProvider(voteId: 1).notifier,
      );

      // Update a non-existent item
      await notifier.setVoteItem(id: 999, voteTotal: 9999);

      final state = container.read(
        asyncVoteItemListProvider(voteId: 1),
      );
      // Original values should be unchanged
      expect(state.value![0]!.voteTotal, 500);
      expect(state.value![1]!.voteTotal, 300);
    });
  });

  group('fetchVoteAchieve', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'vote_achieve': [
          {
            'id': 1,
            'vote_id': 1,
            'reward_id': 10,
            'order': 1,
            'amount': 100,
            'reward': {
              'id': 10,
              'title': {'ko': '포토카드'},
              'thumbnail': null,
            },
            'vote': {
              'id': 1,
              'title': {'ko': '인기 투표'},
              'vote_category': 'idol',
              'main_image': null,
              'wait_image': null,
              'result_image': null,
              'vote_content': null,
              'start_at': '2025-01-01T00:00:00Z',
              'stop_at': '2099-12-31T23:59:59Z',
              'visible_at': '2025-01-01T00:00:00Z',
              'created_at': '2025-01-01T00:00:00Z',
              'is_ended': false,
              'is_upcoming': false,
              'is_partnership': false,
              'partner': null,
              'vote_item': [],
              'reward': [],
            },
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches vote achievements from supabase', () async {
      final result = await container.read(
        fetchVoteAchieveProvider(voteId: 1).future,
      );
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].id, 1);
      expect(result[0].amount, 100);
      expect(result[0].order, 1);
      expect(result[0].reward.id, 10);
    });
  });
}
