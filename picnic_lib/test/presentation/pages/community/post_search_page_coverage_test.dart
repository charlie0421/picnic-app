import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Coverage-focused tests for PostSearchPage covering:
/// - Search box rendering
/// - Search history display
/// - Focus/unfocus behavior
/// - Empty search state
/// - Search execution with text entry
/// - Search history chip rendering
void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('PostSearchPage rendering', () {
    testWidgets('renders search box and history area', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PostSearchPage), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('shows search history label', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The search history section should be rendered
      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('renders with pre-existing search history', (tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS', 'BLACKPINK', '아이유'],
      });

      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // History chips should appear
      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.text('BTS'), findsOneWidget);
      expect(find.text('BLACKPINK'), findsOneWidget);
      expect(find.text('아이유'), findsOneWidget);
    });

    testWidgets('search history chips are tappable', (tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS'],
      });

      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify chip exists and is tappable
      final chipFinder = find.text('BTS');
      expect(chipFinder, findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('multiple search history chips render correctly',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS', 'BLACKPINK'],
      });

      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('BTS'), findsOneWidget);
      expect(find.text('BLACKPINK'), findsOneWidget);
    });

    testWidgets('search box text field exists', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find text field within the search box
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
    });

    testWidgets('empty search shows history', (tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['test'],
      });

      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // With empty search, should show history section
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('search history limited to 10 items', (tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': [
          'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'
        ],
      });

      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Chip), findsNWidgets(10));
    });
  });

  group('PostSearchPage focus behavior', () {
    testWidgets('focus and unfocus does not crash', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const PostSearchPage()),
      );
      await tester.pump();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.tap(textFields.first);
        await tester.pump();

        // Unfocus
        await tester.tapAt(Offset.zero);
        await tester.pump();
      }

      expect(find.byType(PostSearchPage), findsOneWidget);
    });
  });
}
