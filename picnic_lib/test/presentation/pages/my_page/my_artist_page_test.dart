import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_artist_page.dart';

/// Tests for MyArtistPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// overlay_support). We test importable production code:
/// constructor, MyArtistSearchQueryNotifier.
void main() {
  group('MyArtistPage widget', () {
    test('can be const-constructed', () {
      const page = MyArtistPage();
      expect(page, isA<MyArtistPage>());
    });

    test('with key can be constructed', () {
      const page = MyArtistPage(key: ValueKey('my_artist'));
      expect(page.key, equals(const ValueKey('my_artist')));
    });
  });

  group('MyArtistSearchQueryNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty string', () {
      final query = container.read(myArtistSearchQueryProvider);
      expect(query, '');
    });

    test('set updates query', () {
      container.read(myArtistSearchQueryProvider.notifier).set('jimin');
      expect(container.read(myArtistSearchQueryProvider), 'jimin');
    });

    test('set with empty string resets query', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      notifier.set('search term');
      expect(container.read(myArtistSearchQueryProvider), 'search term');
      notifier.set('');
      expect(container.read(myArtistSearchQueryProvider), '');
    });

    test('set with Korean text', () {
      container.read(myArtistSearchQueryProvider.notifier).set('지민');
      expect(container.read(myArtistSearchQueryProvider), '지민');
    });

    test('consecutive sets update correctly', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      notifier.set('a');
      notifier.set('ab');
      notifier.set('abc');
      expect(container.read(myArtistSearchQueryProvider), 'abc');
    });
  });

  group('myArtistSearchQueryProvider', () {
    test('provider is a NotifierProvider', () {
      expect(myArtistSearchQueryProvider,
          isA<NotifierProvider<MyArtistSearchQueryNotifier, String>>());
    });
  });
}
