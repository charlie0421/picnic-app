import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_list_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('GoonghapList with authenticated user', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'goonghap_results': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('loadInitial with auth returns empty list and sets hasMore false',
        () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      final state = container.read(goonghapListProvider());
      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('loadMore after loadInitial with empty result does nothing', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      // hasMore is false, loadMore should exit early
      await notifier.loadMore();
      final state = container.read(goonghapListProvider());
      expect(state.items, isEmpty);
    });

    test('loadInitial with artistId filter works with auth', () async {
      final notifier =
          container.read(goonghapListProvider(artistId: 99).notifier);
      await notifier.loadInitial();

      final state = container.read(goonghapListProvider(artistId: 99));
      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
    });
  });

  group('GoonghapList with data', () {
    late ProviderContainer container;

    setUp(() async {
      // Provide mock data with enough items to test pagination
      final mockItems = List.generate(
        10,
        (i) => {
          'id': 'goonghap-${i + 1}',
          'user_id': 'test-user-id',
          'artist_id': 1,
          'user_birth_date': '1995-01-01',
          'user_birth_time': '12:00',
          'status': 'completed',
          'gender': 'male',
          'score': 85,
          'goonghap_summary': '요약',
          'created_at': DateTime.now()
              .subtract(Duration(hours: i))
              .toIso8601String(),
          'artist': {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
          },
          'i18n': <Map<String, dynamic>>[],
        },
      );
      await setupMockSupabaseWithAuth({
        'goonghap_results': mockItems,
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('loadInitial loads items and sets hasMore true when full page',
        () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      final state = container.read(goonghapListProvider());
      expect(state.items.length, 10);
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('loadMore appends items after loadInitial', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      final stateBefore = container.read(goonghapListProvider());
      expect(stateBefore.items.length, 10);
      expect(stateBefore.hasMore, isTrue);

      await notifier.loadMore();
      final stateAfter = container.read(goonghapListProvider());
      // Items should be appended (mock returns same 10 items again)
      expect(stateAfter.items.length, 20);
    });

    test('concurrent loadInitial calls are guarded by isLoading', () async {
      final notifier = container.read(goonghapListProvider().notifier);

      // Fire both concurrently
      final f1 = notifier.loadInitial();
      final f2 = notifier.loadInitial();
      await Future.wait([f1, f2]);

      final state = container.read(goonghapListProvider());
      // Only one loadInitial should actually run
      expect(state.items.length, 10);
      expect(state.isLoading, isFalse);
    });

    test('concurrent loadMore calls are guarded by isLoading', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      final f1 = notifier.loadMore();
      final f2 = notifier.loadMore();
      await Future.wait([f1, f2]);

      final state = container.read(goonghapListProvider());
      // Only one loadMore should run (guard: isLoading || !hasMore)
      expect(state.items.length, 20);
    });
  });

  group('GoonghapList error handling', () {
    late ProviderContainer container;

    setUp(() {
      // Setup without auth -- but setupMockSupabase with a userId
      // that returns an error response
      setupMockSupabase({
        'goonghap_results': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('loadInitial without auth returns empty list', () async {
      final notifier = container.read(goonghapListProvider().notifier);
      await notifier.loadInitial();

      // Without auth session, userId is null, returns empty
      final state = container.read(goonghapListProvider());
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
    });
  });
}
