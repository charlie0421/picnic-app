import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_and_results_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Wraps SearchAndResultsSection in a Column so Expanded works correctly
Widget _wrapInColumn(Widget child) {
  return SizedBox(
    height: 600,
    child: Column(
      children: [child],
    ),
  );
}

void main() {
  setUp(() {
    initTestColors();
  });

  group('SearchAndResultsSection - showSearchBoxOnly', () {
    testWidgets('renders search box only mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SearchAndResultsSection(
            currentSearchQuery: '',
            onSearchChanged: (_) {},
            searchResults: const [],
            searchResultsInfo: const {},
            onSubmitApplication: (_) {},
            isSearching: false,
            showSearchBoxOnly: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('renders with external focus node',
        (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        buildTestApp(
          SearchAndResultsSection(
            currentSearchQuery: '',
            onSearchChanged: (_) {},
            searchResults: const [],
            searchResultsInfo: const {},
            onSubmitApplication: (_) {},
            isSearching: false,
            showSearchBoxOnly: true,
            searchFocusNode: focusNode,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);

      focusNode.dispose();
    });

    testWidgets('renders search box only with tap callback',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          SearchAndResultsSection(
            currentSearchQuery: '',
            onSearchChanged: (_) {},
            searchResults: const [],
            searchResultsInfo: const {},
            onSubmitApplication: (_) {},
            isSearching: false,
            showSearchBoxOnly: true,
            onSearchBoxTapped: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });
  });

  group('SearchAndResultsSection - expanded mode', () {
    testWidgets('renders searching/loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: 'test',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: true,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('renders empty results state when query has no results',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: 'nonexistent',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('renders initial state when no search query',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
    });

    testWidgets('renders close button in search mode',
        (WidgetTester tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
              onCloseSearch: () {
                closeCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(closeCalled, true);
    });

    testWidgets('renders expanded mode with search results',
        (WidgetTester tester) async {
      final artist1 = MockData.artist(id: 1, nameKo: '지민', nameEn: 'Jimin');
      final artist2 = MockData.artist(id: 2, nameKo: '뷔', nameEn: 'V');

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '지민',
              onSearchChanged: (_) {},
              searchResults: [artist1, artist2],
              searchResultsInfo: {
                '1': const ArtistApplicationInfo(
                  artistName: '지민',
                  applicationCount: 3,
                  applicationStatus: '신청 가능',
                  isAlreadyInVote: false,
                ),
                '2': const ArtistApplicationInfo(
                  artistName: '뷔',
                  applicationCount: 1,
                  applicationStatus: '신청 가능',
                  isAlreadyInVote: true,
                ),
              },
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('renders results with load more indicator',
        (WidgetTester tester) async {
      final artists = List.generate(
        5,
        (i) => MockData.artist(
            id: i + 1, nameKo: '아티스트$i', nameEn: 'Artist$i'),
      );

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: 'test',
              onSearchChanged: (_) {},
              searchResults: artists,
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              hasMoreResults: true,
              isLoadingMore: true,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('renders with whitespace-only search query as initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '   ',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
    });

    testWidgets('renders results without application info (loading info)',
        (WidgetTester tester) async {
      final artist = MockData.artist(id: 1, nameKo: '지민', nameEn: 'Jimin');

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '지민',
              onSearchChanged: (_) {},
              searchResults: [artist],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('renders with already-applied status',
        (WidgetTester tester) async {
      final artist = MockData.artist(id: 1, nameKo: '지민', nameEn: 'Jimin');

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '지민',
              onSearchChanged: (_) {},
              searchResults: [artist],
              searchResultsInfo: {
                '1': const ArtistApplicationInfo(
                  artistName: '지민',
                  applicationCount: 2,
                  applicationStatus: '대기중',
                  isAlreadyInVote: false,
                  isSubmitting: false,
                ),
              },
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);
    });

    testWidgets('handles didUpdateWidget with new focus node',
        (WidgetTester tester) async {
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
              searchFocusNode: focusNode1,
            ),
          ),
        ),
      );
      await tester.pump();

      // Update with new focus node
      await tester.pumpWidget(
        buildTestApp(
          _wrapInColumn(
            SearchAndResultsSection(
              currentSearchQuery: '',
              onSearchChanged: (_) {},
              searchResults: const [],
              searchResultsInfo: const {},
              onSubmitApplication: (_) {},
              isSearching: false,
              showSearchBoxOnly: false,
              searchFocusNode: focusNode2,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SearchAndResultsSection), findsOneWidget);

      focusNode1.dispose();
      focusNode2.dispose();
    });
  });
}
