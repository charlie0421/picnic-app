import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_artist_page.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    SearchService.clearAllCache();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
    SearchService.clearAllCache();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  /// Wraps with OverlaySupport required by MyArtistPage's _showToast
  Widget wrapWithOverlay(Widget child) {
    return OverlaySupport.global(child: child);
  }

  group('MyArtistPage render', () {
    testWidgets('renders with default state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(buildTestAppPage(const MyArtistPage())),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders when logged out', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(const MyArtistPage(), loggedIn: false),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(const MyArtistPage(), locale: const Locale('en')),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        wrapWithOverlay(
          buildTestAppPage(const MyArtistPage(), locale: const Locale('ja')),
        ),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets('renders with artist data available', (
      WidgetTester tester,
    ) async {
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
        wrapWithOverlay(buildTestAppPage(const MyArtistPage())),
      );

      expect(find.byType(MyArtistPage), findsOneWidget);
    });

    testWidgets(
      'same scope remount starts with matching empty input and query',
      (tester) async {
        final alphaResponse = Completer<http.Response>();
        final artistQueries = <String>[];
        testSupabaseClient = SupabaseClient(
          'http://localhost:54321',
          'test-anon-key-for-testing-purposes-only',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/auth/')) {
              return http.Response(
                jsonEncode({'error': 'not authenticated'}),
                401,
                request: request,
                headers: const {'content-type': 'application/json'},
              );
            }
            final table = request.url.path
                .split('/rest/v1/')
                .last
                .split('?')
                .first;
            if (table == 'artist_user_bookmark') {
              return http.Response(
                '[]',
                200,
                request: request,
                headers: const {'content-type': 'application/json'},
              );
            }
            if (table == 'artist') {
              final decodedUrl = Uri.decodeFull(request.url.toString());
              final query = decodedUrl.contains('Alpha') ? 'Alpha' : '';
              artistQueries.add(query);
              if (query == 'Alpha') return alphaResponse.future;
              return http.Response(
                '[]',
                200,
                request: request,
                headers: const {'content-type': 'application/json'},
              );
            }
            return http.Response(
              '[]',
              200,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }),
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );

        late StateSetter setHostState;
        var showPage = true;
        await pumpWidgetAndIgnoreErrors(
          tester,
          wrapWithOverlay(
            buildTestAppPage(
              StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return showPage
                      ? const MyArtistPage()
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Alpha');
        await tester.pump(const Duration(milliseconds: 301));
        final firstListContext = tester.element(
          find.byType(ArtistSelectListView),
        );
        final firstContainer = ProviderScope.containerOf(firstListContext);
        expect(firstContainer.read(myArtistSearchQueryProvider), 'Alpha');
        expect(find.text('Alpha'), findsOneWidget);
        expect(artistQueries, contains('Alpha'));

        setHostState(() => showPage = false);
        await tester.pump();
        final callsBeforeRemount = artistQueries.length;

        setHostState(() => showPage = true);
        await tester.pump();
        await tester.pump();

        final remountedListContext = tester.element(
          find.byType(ArtistSelectListView),
        );
        final remountedContainer = ProviderScope.containerOf(
          remountedListContext,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '',
        );
        expect(remountedContainer.read(myArtistSearchQueryProvider), '');
        expect(artistQueries.skip(callsBeforeRemount), ['']);

        alphaResponse.complete(
          http.Response(
            '[]',
            200,
            headers: const {'content-type': 'application/json'},
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('same element rebuild preserves the active search', (
      tester,
    ) async {
      late StateSetter rebuildHost;
      await pumpWidgetAndIgnoreErrors(
        tester,
        wrapWithOverlay(
          buildTestAppPage(
            StatefulBuilder(
              builder: (context, setState) {
                rebuildHost = setState;
                return MyArtistPage(
                  key: const ValueKey('stable-my-artist-page'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump();

      final pageElement = tester.element(find.byType(MyArtistPage));
      final listContext = tester.element(find.byType(ArtistSelectListView));
      final innerContainer = ProviderScope.containerOf(listContext);
      expect(innerContainer.read(myArtistSearchQueryProvider), 'Alpha');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Alpha',
      );

      final artistRequestCount = capturedMockRequests.where((request) {
        return request.path.endsWith('/rest/v1/artist');
      }).length;

      rebuildHost(() {});
      await tester.pump();
      await tester.pump();

      expect(
        identical(pageElement, tester.element(find.byType(MyArtistPage))),
        isTrue,
        reason: 'the test must rebuild, not remount, MyArtistPage',
      );
      final rebuiltListContext = tester.element(
        find.byType(ArtistSelectListView),
      );
      final rebuiltInnerContainer = ProviderScope.containerOf(
        rebuiltListContext,
      );
      expect(identical(innerContainer, rebuiltInnerContainer), isTrue);
      expect(rebuiltInnerContainer.read(myArtistSearchQueryProvider), 'Alpha');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Alpha',
      );

      final rebuildRequests = capturedMockRequests
          .where((request) => request.path.endsWith('/rest/v1/artist'))
          .skip(artistRequestCount)
          .toList();
      expect(
        rebuildRequests,
        isEmpty,
        reason: 'rebuilding must not issue an empty or duplicate HTTP search',
      );
      expect(tester.takeException(), isNull);
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
