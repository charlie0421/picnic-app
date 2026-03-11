import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('DrawerAnimatedSwitcher', () {
    testWidgets('renders SizedBox.shrink when drawer stack is empty', (tester) async {
      final nav = MockData.navigation();
      // navigation에 drawerNavigationStack이 없거나 비어있는 경우
      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const DrawerAnimatedSwitcher(),
          navigation: nav,
        ),
      );
      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byType(DrawerAnimatedSwitcher), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('renders drawer content when stack has items', (tester) async {
      final drawerStack = NavigationStack();
      drawerStack.push(const Text('Drawer Content'));
      final nav = MockData.navigation().copyWith(
        drawerNavigationStack: drawerStack,
      );

      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const DrawerAnimatedSwitcher(),
          navigation: nav,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drawer Content'), findsOneWidget);
    });
  });

  group('SignUpAnimatedSwitcher', () {
    testWidgets('renders SizedBox.shrink when signup stack is empty', (tester) async {
      final nav = MockData.navigation().copyWith(
        signUpNavigationStack: NavigationStack(),
      );
      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const SignUpAnimatedSwitcher(),
          navigation: nav,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignUpAnimatedSwitcher), findsOneWidget);
    });

    testWidgets('renders signup content when stack has items', (tester) async {
      final signUpStack = NavigationStack();
      signUpStack.push(const Text('SignUp Step 1'));
      final nav = MockData.navigation().copyWith(
        signUpNavigationStack: signUpStack,
      );

      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const SignUpAnimatedSwitcher(),
          navigation: nav,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SignUp Step 1'), findsOneWidget);
    });
  });
}
