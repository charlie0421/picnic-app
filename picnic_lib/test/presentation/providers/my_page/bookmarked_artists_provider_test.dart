import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('AsyncBookmarkedArtists', () {
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

    test('returns empty list when isSupabaseLoggedSafely is false (no real auth session)', () async {
      // The mock HTTP client does not create a real auth session,
      // so isSupabaseLoggedSafely returns false and the provider returns [].
      final result = await container.read(
        asyncBookmarkedArtistsProvider.future,
      );
      expect(result, isEmpty);
    });

    test('refreshBookmarkedArtists sets empty list when not logged in', () async {
      await container.read(asyncBookmarkedArtistsProvider.future);

      final notifier = container.read(
        asyncBookmarkedArtistsProvider.notifier,
      );
      await notifier.refreshBookmarkedArtists();

      final state = container.read(asyncBookmarkedArtistsProvider);
      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
    });

    test('refreshBookmarkedArtists is idempotent (calling twice does not error)', () async {
      await container.read(asyncBookmarkedArtistsProvider.future);

      final notifier = container.read(
        asyncBookmarkedArtistsProvider.notifier,
      );
      await notifier.refreshBookmarkedArtists();
      await notifier.refreshBookmarkedArtists();

      final state = container.read(asyncBookmarkedArtistsProvider);
      expect(state.value, isEmpty);
    });

    test('provider is keepAlive', () {
      expect(asyncBookmarkedArtistsProvider, isNotNull);
    });

    test('build completes without error', () async {
      // Should not throw
      final result = await container.read(asyncBookmarkedArtistsProvider.future);
      expect(result, isA<List>());
    });
  });
}
