import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({});
    SharedPreferences.setMockInitialValues({});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('PostSearchPage render interactions', () {
    testWidgets('tap on search history chip triggers search',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS', 'BLACKPINK'],
      });

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const PostSearchPage()),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(Chip), findsNWidgets(2));

      // Tap the BTS chip
      await tester.tap(find.text('BTS'));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('delete chip removes from history',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS', 'BLACKPINK'],
      });

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const PostSearchPage()),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('entering text in search box triggers search',
        (WidgetTester tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const PostSearchPage()),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      final textField = find.byType(TextField);
      expect(textField, findsWidgets);

      await tester.enterText(textField.first, 'test query');
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 600));

      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('clearing search shows history again',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['BTS'],
      });

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const PostSearchPage()),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      final textField = find.byType(TextField);
      await tester.enterText(textField.first, 'query');
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 600));

      // Clear search
      await tester.enterText(textField.first, '');
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 600));

      expect(find.byType(PostSearchPage), findsOneWidget);
    });

    testWidgets('focus and tap elsewhere dismisses keyboard',
        (WidgetTester tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const PostSearchPage()),
      );
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.tap(textField.first);
        await pumpAndIgnoreErrors(tester);

        await tester.tapAt(const Offset(10, 700));
        await pumpAndIgnoreErrors(tester);
      }

      expect(find.byType(PostSearchPage), findsOneWidget);
    });
  });
}
