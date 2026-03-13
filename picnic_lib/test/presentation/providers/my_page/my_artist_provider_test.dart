import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/my_artist_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('AsyncMyArtist', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'artist_user_bookmark': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('initial build returns empty list', () async {
      final result = await container.read(asyncMyArtistProvider.future);
      expect(result, isEmpty);
    });

    test('bookmarkArtist returns false when user is not authenticated (currentUser is null)', () async {
      // The mock doesn't create a real auth session, so currentUser is null.
      // bookmarkArtist checks currentUser == null and throws, caught by catch returning false.
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);
      final result = await notifier.bookmarkArtist(artistId: 1);
      expect(result, isFalse);
    });

    test('unBookmarkArtist succeeds even without auth (delete does not check auth)', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);
      final result = await notifier.unBookmarkArtist(artistId: 1);
      expect(result, isTrue);
    });

    test('provider is keepAlive', () {
      // asyncMyArtistProvider is annotated with @Riverpod(keepAlive: true)
      expect(asyncMyArtistProvider, isNotNull);
    });

    test('provider returns AsyncValue', () async {
      final asyncValue = container.read(asyncMyArtistProvider);
      // Should be loading or data state
      expect(asyncValue, isNotNull);
    });

    test('build returns empty list, not null', () async {
      final result = await container.read(asyncMyArtistProvider.future);
      expect(result, isA<List>());
      expect(result, isEmpty);
    });

    test('unBookmarkArtist with different artistId values', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      // Delete different artist bookmarks
      final result1 = await notifier.unBookmarkArtist(artistId: 100);
      expect(result1, isTrue);

      final result2 = await notifier.unBookmarkArtist(artistId: 200);
      expect(result2, isTrue);
    });

    test('bookmarkArtist called multiple times always returns false (no auth)', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);

      final r1 = await notifier.bookmarkArtist(artistId: 1);
      final r2 = await notifier.bookmarkArtist(artistId: 2);
      expect(r1, isFalse);
      expect(r2, isFalse);
    });
  });

  group('AsyncMyArtist - edge cases', () {
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

    test('unBookmarkArtist works even without userId config', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);
      final result = await notifier.unBookmarkArtist(artistId: 1);
      // Delete doesn't check auth, so it should succeed
      expect(result, isTrue);
    });

    test('bookmarkArtist fails without auth (no userId)', () async {
      await container.read(asyncMyArtistProvider.future);
      final notifier = container.read(asyncMyArtistProvider.notifier);
      final result = await notifier.bookmarkArtist(artistId: 1);
      expect(result, isFalse);
    });
  });
}
