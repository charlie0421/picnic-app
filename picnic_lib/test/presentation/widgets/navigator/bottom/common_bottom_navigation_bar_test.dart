import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommonBottomNavigationBar', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonBottomNavigationBar(),
        ),
      );
      await tester.pump();

      expect(find.byType(CommonBottomNavigationBar), findsOneWidget);
    });

    testWidgets('renders with specific navigation state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonBottomNavigationBar(),
          navigation: Navigation(
            showBottomNavigation: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommonBottomNavigationBar), findsOneWidget);
    });
  });
}
