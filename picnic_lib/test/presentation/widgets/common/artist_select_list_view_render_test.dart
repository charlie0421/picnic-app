import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/common/artist_select_list_view.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Mock search query notifier for tests.
class _TestSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final _testSearchQueryProvider =
    NotifierProvider<_TestSearchQueryNotifier, String>(
  _TestSearchQueryNotifier.new,
);

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'artist': [
        {
          'id': 1,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'birth_date': null,
          'gender': null,
          'is_kpop': true,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
        {
          'id': 2,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'birth_date': null,
          'gender': null,
          'is_kpop': true,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
      ],
      'artist_user_bookmark': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('ArtistSelectListView render', () {
    testWidgets('renders with default config', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          ArtistSelectListView(
            searchQueryProvider: _testSearchQueryProvider,
            config: const ArtistSelectConfig(),
          ),
        ),
      );

      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders with bookmark toggle enabled',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          ArtistSelectListView(
            searchQueryProvider: _testSearchQueryProvider,
            config: const ArtistSelectConfig(showBookmarkToggle: true),
          ),
        ),
      );

      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders with custom section titles',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          ArtistSelectListView(
            searchQueryProvider: _testSearchQueryProvider,
            config: const ArtistSelectConfig(
              bookmarkSectionTitle: 'Favorites',
              generalSectionTitle: 'All Artists',
              emptyMessage: 'No artists found',
            ),
          ),
        ),
      );

      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders logged out', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          ArtistSelectListView(
            searchQueryProvider: _testSearchQueryProvider,
            config: const ArtistSelectConfig(),
          ),
          loggedIn: false,
        ),
      );

      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });

    testWidgets('renders with hideSectionHeaderOnSearch',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          ArtistSelectListView(
            searchQueryProvider: _testSearchQueryProvider,
            config: const ArtistSelectConfig(
              hideSectionHeaderOnSearch: true,
            ),
          ),
        ),
      );

      expect(find.byType(ArtistSelectListView), findsOneWidget);
    });
  });

  group('ArtistSelectConfig', () {
    test('has correct defaults', () {
      const config = ArtistSelectConfig();
      expect(config.showBookmarkToggle, isFalse);
      expect(config.hideSectionHeaderOnSearch, isFalse);
      expect(config.bookmarkSectionTitle, '북마크');
      expect(config.generalSectionTitle, '전체 아티스트');
    });

    test('accepts custom values', () {
      const config = ArtistSelectConfig(
        showBookmarkToggle: true,
        hideSectionHeaderOnSearch: true,
        bookmarkSectionTitle: 'My Picks',
        generalSectionTitle: 'Everyone',
        emptyMessage: 'Empty',
        searchEmptyMessageTemplate: 'No results for "{query}"',
        errorMessage: 'Error occurred',
      );
      expect(config.showBookmarkToggle, isTrue);
      expect(config.hideSectionHeaderOnSearch, isTrue);
      expect(config.bookmarkSectionTitle, 'My Picks');
      expect(config.generalSectionTitle, 'Everyone');
      expect(config.emptyMessage, 'Empty');
      expect(config.searchEmptyMessageTemplate, 'No results for "{query}"');
      expect(config.errorMessage, 'Error occurred');
    });
  });
}
