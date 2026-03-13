import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/screens/novel/novel_home_screen.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('NovelHomeScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final stack = NavigationStack()..push(const Text('TestPage'));
      await tester.pumpWidget(
        buildTestAppPage(
          const NovelHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NovelHomeScreen), findsOneWidget);
    });

    testWidgets('renders with multiple stack items', (WidgetTester tester) async {
      final stack = NavigationStack()
        ..push(const Text('Page1'))
        ..push(const Text('Page2'));
      await tester.pumpWidget(
        buildTestAppPage(
          const NovelHomeScreen(),
          navigation: Navigation(
            voteNavigationStack: stack,
            showBottomNavigation: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NovelHomeScreen), findsOneWidget);
    });
  });
}
