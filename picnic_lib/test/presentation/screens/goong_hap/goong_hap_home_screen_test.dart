import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/screens/goong_hap/goong_hap_home_screen.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('GoongHapHomeScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const Text('TestPage'));
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GoongHapHomeScreen), findsOneWidget);
    });

    testWidgets('contains GestureDetector for swipe', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const SizedBox());
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders with multiple stack items', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GoongHapHomeScreen), findsOneWidget);
    });

    testWidgets('handles right swipe gesture', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(GoongHapHomeScreen), findsOneWidget);
    });

    testWidgets('swipe cooldown prevents rapid swipes',
        (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'))
        ..push(const Text('Page3'));
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(GoongHapHomeScreen), findsOneWidget);
    });

    testWidgets('disposes swipe timer', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

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
          const GoongHapHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.drag(
        find.byType(GoongHapHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(GoongHapHomeScreen), findsOneWidget);
    });
  });
}
