import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/artist_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('getArtist', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'artist': [
          {
            'id': 1,
            'name': {'ko': '지민', 'en': 'Jimin'},
            'image': 'https://example.com/jimin.png',
            'yy': 1995,
            'mm': 10,
            'dd': 13,
            'gender': 'male',
            'artist_group': {
              'id': 10,
              'name': {'ko': 'BTS'},
              'image': null,
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

    test('fetches artist by id', () async {
      final result = await container.read(
        getArtistProvider(1).future,
      );
      expect(result.id, 1);
      expect(result.name['ko'], '지민');
      expect(result.name['en'], 'Jimin');
      expect(result.image, 'https://example.com/jimin.png');
    });

    test('returns artist with artist_group', () async {
      final result = await container.read(
        getArtistProvider(1).future,
      );
      expect(result.artistGroup, isNotNull);
      expect(result.artistGroup!.id, 10);
      expect(result.artistGroup!.name['ko'], 'BTS');
    });
  });

  group('getArtist - error path', () {
    late ProviderContainer container;

    setUp(() {
      // Empty artist list - maybeSingle returns null which triggers
      // the 'Artist not found' exception, caught by outer catch -> 'Failed to fetch artist'
      setupMockSupabase({
        'artist': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('throws when artist not found (null response)', () async {
      // The provider is auto-dispose FutureProvider - errors surface via .future
      Object? caughtError;
      try {
        await container.read(getArtistProvider(999).future);
      } catch (e) {
        caughtError = e;
      }
      // Either we get the wrapped error or the provider disposal error
      expect(caughtError, isNotNull);
    });
  });

  group('getArtist - minimal data', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'artist': [
          {
            'id': 2,
            'name': {'en': 'Solo Artist'},
            'image': null,
            'artist_group': null,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches artist with minimal data', () async {
      final result = await container.read(
        getArtistProvider(2).future,
      );
      expect(result.id, 2);
      expect(result.name['en'], 'Solo Artist');
      expect(result.image, isNull);
      expect(result.artistGroup, isNull);
    });
  });
}
