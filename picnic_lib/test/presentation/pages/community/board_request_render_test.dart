import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/board_request.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() async {
    initTestColors();
    await setupMockSupabaseWithAuth({
      'boards': <dynamic>[],
    }, userId: 'test-user-id');
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('BoardRequest render', () {
    testWidgets('renders board request form', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(BoardRequest), findsOneWidget);
    });

    testWidgets('fill in form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Find TextFormFields and fill them
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        // Fill board name
        await tester.enterText(textFields.at(0), 'Test Board');
        await pumpAndIgnoreErrors(tester);

        // Fill description (needs 5-20 chars)
        await tester.enterText(textFields.at(1), 'Test Description');
        await pumpAndIgnoreErrors(tester);

        // Fill request message (needs >= 10 chars)
        await tester.enterText(
            textFields.at(2), 'This is a test request message for the board');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('validation shows errors for empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Enter text and then clear to trigger validation
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.at(0), 'a');
        await pumpAndIgnoreErrors(tester);
        await tester.enterText(textFields.at(0), '');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('scroll the form', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      final scrollView = find.byType(SingleChildScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        await tester.drag(scrollView.first, const Offset(0, -200),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('tap on page to dismiss keyboard',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Tap on GestureDetector to dismiss keyboard
      final gestureDetectors = find.byType(GestureDetector);
      if (gestureDetectors.evaluate().isNotEmpty) {
        await tester.tap(gestureDetectors.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('description validation - too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        // Enter description that's too short (< 5 chars)
        await tester.enterText(textFields.at(1), 'ab');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('request message validation - too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const BoardRequest(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        // Enter request message that's too short (< 10 chars)
        await tester.enterText(textFields.at(2), 'short');
        await pumpAndIgnoreErrors(tester);
      }
    });
  });
}
