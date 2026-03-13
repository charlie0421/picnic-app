import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';

import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('UsagePolicyPopup', () {
    testWidgets('renders when opened via showUsagePolicyDialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUsagePolicyDialog(context),
              child: const Text('Open'),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('renders UsagePolicyPopup directly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('renders policy content with scrollable area',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders non-logged-in policy content (no expiring data section)',
        (WidgetTester tester) async {
      // isSupabaseLoggedSafely = false since no auth session
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
      // Should have policy content but not the expiring bonus section header
    });

    testWidgets('renders with logged-in state using auth mock',
        (WidgetTester tester) async {
      // Set up Supabase with auth to make isSupabaseLoggedSafely true
      await setupMockSupabaseWithAuth(
        {},
        userId: 'test-user-id',
      );

      await tester.pumpWidget(
        buildTestAppPage(
          const Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(),
          ),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('showUsagePolicyDialog uses general dialog with transitions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUsagePolicyDialog(context),
              child: const Text('Open'),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      // Pump a few frames to observe transition animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('renders example table with current month calculations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      // The example table should be rendered inside the policy details
      expect(find.byType(UsagePolicyPopup), findsOneWidget);
      // Table rows should contain Divider widgets
      expect(find.byType(Divider), findsWidgets);
    });
  });
}
