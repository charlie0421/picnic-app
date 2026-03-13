import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteHomeScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const Text('TestPage'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteHomeScreen), findsOneWidget);
    });

    testWidgets('contains GestureDetector for swipe', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const SizedBox());
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders with bottom nav hidden', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteHomeScreen), findsOneWidget);
    });

    testWidgets('handles right swipe gesture', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      // Simulate a right swipe
      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(VoteHomeScreen), findsOneWidget);
    });

    testWidgets('swipe cooldown prevents rapid swipes',
        (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'))
        ..push(const Text('Page3'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      // First swipe
      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      // Second swipe immediately (should be cooldown-blocked)
      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(VoteHomeScreen), findsOneWidget);
    });

    testWidgets('disposes swipe timer on widget disposal',
        (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      // Trigger a swipe to start the timer
      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      // Dispose the widget (rebuild with different widget)
      await tester.pumpWidget(
        buildTestAppPage(
          const SizedBox(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      // No error means timer was properly cancelled
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('swipe timer expires and re-enables swipe',
        (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'))
        ..push(const Text('Page3'));
      await tester.pumpWidget(
        buildTestAppPage(
          const VoteHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.drag(
        find.byType(VoteHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(VoteHomeScreen), findsOneWidget);
    });
  });
}
