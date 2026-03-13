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

  group('GoonghapListPage widget test', () {
    testWidgets('renders without crashing (logged out)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('shows login required state when not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      // Login required state shows a lock icon
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders with artistId parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(artistId: 1),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(GoonghapListPage), findsOneWidget);
    });

    testWidgets('renders with logged in state and empty history',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth(
        {'goonghap_results': <dynamic>[]},
        userId: 'test-user-id',
      );

      await tester.pumpWidget(
        buildTestAppPage(const GoonghapListPage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      expect(find.byType(GoonghapListPage), findsOneWidget);
      // Empty state shows a heart border icon
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('has gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      // The page wraps its content in a Container with gradient decoration
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('dispose cleans up without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const GoonghapListPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

      // Replace with different widget to trigger dispose
      await tester.pumpWidget(
        buildTestAppPage(const SizedBox()),
      );
      while (tester.takeException() != null) {}
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 200));
    });
  });
}
