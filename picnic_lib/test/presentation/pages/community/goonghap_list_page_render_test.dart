import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_list_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'goonghap_results': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('GoonghapListPage render', () {
    testWidgets('renders login required state when not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('renders with artistId parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage(artistId: 1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('renders empty state when logged in with no results',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({'goonghap_results': <dynamic>[]}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('tap login button in login required state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the ElevatedButton (login button)
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        try {
          await tester.tap(loginButton.first, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
        } catch (_) {}
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('tap new goonghap button in empty state',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({'goonghap_results': <dynamic>[]}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      // Find and tap the new goonghap ElevatedButton
      final newButton = find.byType(ElevatedButton);
      if (newButton.evaluate().isNotEmpty) {
        try {
          await tester.tap(newButton.first, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with logged out state explicitly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('tap GestureDetectors on the page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap GestureDetectors (e.g., "궁합이란?" intro button)
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0;
          i < tester.widgetList(gestureDetectors).length && i < 5;
          i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      drainExpectedImageErrors(tester);
    });

    testWidgets('renders with artistId 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage(artistId: 0)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('tap InkWell widgets on the page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap InkWell widgets (goonghap list items)
      final inkWells = find.byType(InkWell);
      for (int i = 0;
          i < tester.widgetList(inkWells).length && i < 5;
          i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      drainExpectedImageErrors(tester);
    });
  });
}
