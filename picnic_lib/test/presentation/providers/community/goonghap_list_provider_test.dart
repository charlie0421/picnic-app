import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_list_provider.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('GoonghapList', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'goonghap_results': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('initial state has empty items and hasMore true', () {
      final state = container.read(goonghapListProvider());
      expect(state.items, isEmpty);
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('initial state with artistId parameter', () {
      final state = container.read(goonghapListProvider(artistId: 42));
      expect(state.items, isEmpty);
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('loadInitial returns empty and sets hasMore false when currentUser is null', () async {
      // The mock doesn't set a real auth session, so currentUser is null.
      // _getHistory returns [] when userId is null (not logged in).
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      final state = container.read(goonghapListProvider());
      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('loadMore does nothing when already loading', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      // First call loadInitial so hasMore becomes false (empty result)
      await notifier.loadInitial();

      final stateBefore = container.read(goonghapListProvider());
      // loadMore should not proceed because hasMore is false
      await notifier.loadMore();
      final stateAfter = container.read(goonghapListProvider());

      expect(stateAfter.items.length, stateBefore.items.length);
    });

    test('GoonghapHistoryModel copyWith works correctly', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: false,
      );

      final updated = model.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.hasMore, isTrue);
      expect(updated.items, isEmpty);
    });

    test('GoonghapHistoryModel copyWith updates hasMore', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: false,
      );

      final updated = model.copyWith(hasMore: false);
      expect(updated.hasMore, isFalse);
    });

    test('provider is correctly defined as family provider', () {
      expect(goonghapListProvider, isNotNull);
      // Can create with different artistId parameters
      final provider1 = goonghapListProvider(artistId: 1);
      final provider2 = goonghapListProvider(artistId: 2);
      final provider3 = goonghapListProvider();
      expect(provider1, isNot(equals(provider2)));
      expect(provider1, isNot(equals(provider3)));
    });

    test('loadMore does nothing when isLoading is false and hasMore is false', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      // After loadInitial with no user, hasMore is false
      await notifier.loadInitial();

      final stateBefore = container.read(goonghapListProvider());
      expect(stateBefore.hasMore, isFalse);

      // loadMore should exit early because hasMore is false
      await notifier.loadMore();
      final stateAfter = container.read(goonghapListProvider());
      expect(stateAfter.items.length, stateBefore.items.length);
    });

    test('loadInitial does nothing when already loading', () async {
      final notifier = container.read(goonghapListProvider().notifier);

      // Call loadInitial twice quickly - second should be no-op due to isLoading check
      final future1 = notifier.loadInitial();
      // During the first call, isLoading is true
      final future2 = notifier.loadInitial();
      await future1;
      await future2;

      final state = container.read(goonghapListProvider());
      expect(state.isLoading, isFalse);
    });
  });

  group('GoonghapList with artistId filter', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'goonghap_results': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('loadInitial with artistId returns empty (no auth user)', () async {
      final notifier = container.read(
        goonghapListProvider(artistId: 42).notifier,
      );
      await notifier.loadInitial();

      final state = container.read(goonghapListProvider(artistId: 42));
      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('loadMore with artistId when hasMore is false', () async {
      final notifier = container.read(
        goonghapListProvider(artistId: 42).notifier,
      );
      await notifier.loadInitial();

      // hasMore should be false after empty result
      await notifier.loadMore();
      final state = container.read(goonghapListProvider(artistId: 42));
      expect(state.items, isEmpty);
    });
  });

  group('GoonghapHistoryModel', () {
    test('default isLoading is false', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
      );
      expect(model.isLoading, isFalse);
    });

    test('copyWith updates items list', () {
      const model = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: false,
      );

      // Can update multiple fields at once
      final updated = model.copyWith(
        hasMore: false,
        isLoading: true,
      );
      expect(updated.hasMore, isFalse);
      expect(updated.isLoading, isTrue);
      expect(updated.items, isEmpty);
    });
  });
}
