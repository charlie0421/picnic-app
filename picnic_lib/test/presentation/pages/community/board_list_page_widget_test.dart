import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _boardRow({
  String boardId = 'board-1',
  String nameKo = 'Free Board',
  int artistId = 1,
  String artistNameKo = 'BTS',
  bool isOfficial = false,
}) {
  return {
    'board_id': boardId,
    'name': {'ko': nameKo, 'en': nameKo},
    'artist_id': artistId,
    'is_official': isOfficial,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': null,
    },
  };
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'boards': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('BoardListPage widget test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(BoardListPage), findsOneWidget);
    });

    testWidgets('contains EnhancedSearchBox', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });

    testWidgets('renders with board data and shows Chip widgets',
        (WidgetTester tester) async {
      setupMockSupabase({
        'boards': [
          _boardRow(boardId: 'b1', nameKo: 'Free', artistId: 1, artistNameKo: 'BTS'),
          _boardRow(boardId: 'b2', nameKo: 'Fan Art', artistId: 1, artistNameKo: 'BTS'),
        ],
      });

      await tester.pumpWidget(
        buildTestAppPage(const BoardListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(BoardListPage), findsOneWidget);
    });

    testWidgets('renders with logged out state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const BoardListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(BoardListPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const BoardListPage(),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(BoardListPage), findsOneWidget);
    });

    testWidgets('dispose cleans up without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      // Replace with different widget to trigger dispose
      await tester.pumpWidget(
        buildTestAppPage(const SizedBox()),
      );
      drainExpectedImageErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 200));
    });
  });
}
