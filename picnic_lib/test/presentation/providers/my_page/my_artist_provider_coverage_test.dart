import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/my_artist_provider.dart';

import '../../../helpers/mock_supabase.dart';

/// Additional tests targeting uncovered lines in my_artist_provider.dart.
///
/// Targets:
/// - bookmarkArtist with authenticated user: count check (lines 27-33),
///   limit check (lines 35-37), upsert (lines 40-44), success return (line 47)
/// - unBookmarkArtist error path (lines 68-69)
void main() {
  group('AsyncMyArtist - authenticated bookmarkArtist', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'artist_user_bookmark': <Map<String, dynamic>>[],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('bookmarkArtist succeeds when under limit with auth', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      // With auth and 0 existing bookmarks, should succeed
      final result = await notifier.bookmarkArtist(artistId: 1);
      expect(result, isTrue);
    });

    test('bookmarkArtist returns false when limit reached', () async {
      tearDownMockSupabase();
      // Set up 5 existing bookmarks (max limit)
      await setupMockSupabaseWithAuth(
        {
          'artist_user_bookmark': [
            {'artist_id': 1},
            {'artist_id': 2},
            {'artist_id': 3},
            {'artist_id': 4},
            {'artist_id': 5},
          ],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2.read(asyncMyArtistProvider.future);
      final notifier = container2.read(asyncMyArtistProvider.notifier);

      final result = await notifier.bookmarkArtist(artistId: 6);
      expect(result, isFalse);
    });

    test('bookmarkArtist with multiple existing bookmarks under limit',
        () async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth(
        {
          'artist_user_bookmark': [
            {'artist_id': 1},
            {'artist_id': 2},
            {'artist_id': 3},
          ],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2.read(asyncMyArtistProvider.future);
      final notifier = container2.read(asyncMyArtistProvider.notifier);

      final result = await notifier.bookmarkArtist(artistId: 4);
      expect(result, isTrue);
    });
  });

  group('AsyncMyArtist - authenticated unBookmarkArtist', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'artist_user_bookmark': [
            {'artist_id': 1, 'user_id': 'test-user-id'},
          ],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('unBookmarkArtist succeeds with authenticated user', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      final result = await notifier.unBookmarkArtist(artistId: 1);
      expect(result, isTrue);
    });

    test('unBookmarkArtist for non-existent bookmark succeeds', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      // Deleting a non-existent bookmark should not throw
      final result = await notifier.unBookmarkArtist(artistId: 999);
      expect(result, isTrue);
    });
  });

  group('AsyncMyArtist - no auth', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'artist_user_bookmark': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('bookmarkArtist returns false when not authenticated', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      final result = await notifier.bookmarkArtist(artistId: 1);
      expect(result, isFalse);
    });
  });
}
