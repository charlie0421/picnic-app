import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('PicnicAnimatedSwitcher 테스트', () {
    testWidgets('renders with non-empty stack', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const Text('Page1'));
      await tester.pumpWidget(
        buildTestApp(
          const PicnicAnimatedSwitcher(),
          navigation: Navigation(
            voteNavigationStack: stack,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PicnicAnimatedSwitcher), findsOneWidget);
      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.text('Page1'), findsOneWidget);
    });

    testWidgets('shows Container with padding when bottom nav visible', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const SizedBox());
      await tester.pumpWidget(
        buildTestApp(
          const PicnicAnimatedSwitcher(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows multiple pages in IndexedStack', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestApp(
          const PicnicAnimatedSwitcher(),
          navigation: Navigation(
            voteNavigationStack: stack,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(IndexedStack), findsOneWidget);
    });
  });

  group('DrawerAnimatedSwitcher 테스트', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const DrawerAnimatedSwitcher()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DrawerAnimatedSwitcher), findsOneWidget);
    });

    testWidgets('shows AnimatedSwitcher', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const DrawerAnimatedSwitcher()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });

  group('SignUpAnimatedSwitcher 테스트', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const SignUpAnimatedSwitcher()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignUpAnimatedSwitcher), findsOneWidget);
    });

    testWidgets('shows AnimatedSwitcher', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const SignUpAnimatedSwitcher()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
