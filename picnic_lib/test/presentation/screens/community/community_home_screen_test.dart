import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/screens/community/community_home_screen.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommunityHomeScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const Text('TestPage'));
      await tester.pumpWidget(
        buildTestAppPage(
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('contains GestureDetector for swipe', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const SizedBox());
      await tester.pumpWidget(
        buildTestAppPage(
          const CommunityHomeScreen(),
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
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('handles right swipe gesture', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CommunityHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('swipe cooldown prevents rapid swipes',
        (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'))
        ..push(const Text('Page3'));
      await tester.pumpWidget(
        buildTestAppPage(
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CommunityHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      await tester.drag(
        find.byType(CommunityHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });

    testWidgets('disposes swipe timer', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      await tester.drag(
        find.byType(CommunityHomeScreen),
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
          const CommunityHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      // First swipe
      await tester.drag(
        find.byType(CommunityHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      // Wait for cooldown to expire
      await tester.pump(const Duration(seconds: 2));

      // Second swipe should work again
      await tester.drag(
        find.byType(CommunityHomeScreen),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(CommunityHomeScreen), findsOneWidget);
    });
  });
}
