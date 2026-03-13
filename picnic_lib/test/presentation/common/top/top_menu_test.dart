import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/common/top/top_menu.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('TopMenu', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopMenu(),
        ),
      );
      await tester.pump();

      expect(find.byType(TopMenu), findsOneWidget);
    });

    testWidgets('renders with page title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopMenu(),
          navigation: Navigation(
            pageTitle: 'Test Title',
            showTopMenu: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders without back button at root', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopMenu(),
          navigation: Navigation(
            showTopMenu: true,
            showMyPoint: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TopMenu), findsOneWidget);
    });

    testWidgets('renders with topRightMenu none', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopMenu(),
          navigation: Navigation(
            topRightMenu: TopRightType.none,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TopMenu), findsOneWidget);
    });
  });
}
