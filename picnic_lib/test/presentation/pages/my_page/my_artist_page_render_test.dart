import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_artist_page.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'artist_user_bookmark': <dynamic>[],
      'artists': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  /// Wraps with OverlaySupport required by MyArtistPage's _showToast
  Widget wrapWithOverlay(Widget child) {
    return OverlaySupport.global(child: child);
  }

  group('MyArtistPage render', () {
    testWidgets('renders with default state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(const MyArtistPage()),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders when logged out', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(
            const MyArtistPage(),
            loggedIn: false,
          ),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(
            const MyArtistPage(),
            locale: const Locale('en'),
          ),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(
            const MyArtistPage(),
            locale: const Locale('ja'),
          ),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with artist data available',
        (WidgetTester tester) async {
      setupMockSupabase({
        'artist_user_bookmark': [
          {'artist_id': 1, 'user_id': 'test-user-id'},
        ],
        'artists': [
          {
            'id': 1,
            'name': {'ko': 'BTS 지민', 'en': 'BTS Jimin'},
            'image': null,
            'artist_group': null,
            'is_bookmarked': true,
          },
          {
            'id': 2,
            'name': {'ko': '아이유', 'en': 'IU'},
            'image': null,
            'artist_group': null,
            'is_bookmarked': false,
          },
        ],
      });

      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(const MyArtistPage()),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });
  });

  group('MyArtistSearchQueryNotifier extended', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('handles special characters in search query', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      notifier.set('아이유 (IU)');
      expect(container.read(myArtistSearchQueryProvider), '아이유 (IU)');
    });

    test('handles whitespace-only query', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      notifier.set('   ');
      expect(container.read(myArtistSearchQueryProvider), '   ');
    });

    test('handles very long query', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      final longQuery = 'a' * 500;
      notifier.set(longQuery);
      expect(container.read(myArtistSearchQueryProvider), longQuery);
    });

    test('handles emoji in search query', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      notifier.set('BTS ⭐');
      expect(container.read(myArtistSearchQueryProvider), 'BTS ⭐');
    });

    test('rapid consecutive updates settle to final value', () {
      final notifier = container.read(myArtistSearchQueryProvider.notifier);
      for (int i = 0; i < 100; i++) {
        notifier.set('query_$i');
      }
      expect(container.read(myArtistSearchQueryProvider), 'query_99');
    });
  });
}
