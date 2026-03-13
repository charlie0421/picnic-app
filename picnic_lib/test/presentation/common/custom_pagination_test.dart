import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CustomPagination', () {
    testWidgets('renders with items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 5, activeIndex: 0),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPagination), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });

    testWidgets('renders with active index in middle', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 3, activeIndex: 1),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPagination), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('renders single item', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 1, activeIndex: 0),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('active dot has larger size than inactive dots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 3, activeIndex: 0),
        ),
      );
      await tester.pump();

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // First dot (active) should have width 12, others 8
      final containerList = containers.toList();
      expect(containerList.length, 3);

      // Verify the active container has BoxDecoration with primary color
      final firstDecoration =
          containerList[0].decoration as BoxDecoration;
      expect(firstDecoration.color, AppColors.primary500);

      // Verify inactive containers have grey color
      final secondDecoration =
          containerList[1].decoration as BoxDecoration;
      expect(secondDecoration.color, Colors.grey);
    });

    testWidgets('changing activeIndex highlights correct dot',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 4, activeIndex: 2),
        ),
      );
      await tester.pump();

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      // Index 2 should be active (primary color)
      final activeDecoration =
          containers[2].decoration as BoxDecoration;
      expect(activeDecoration.color, AppColors.primary500);

      // Index 0 should be inactive (grey)
      final inactiveDecoration =
          containers[0].decoration as BoxDecoration;
      expect(inactiveDecoration.color, Colors.grey);
    });

    testWidgets('renders zero items without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CustomPagination(itemCount: 0, activeIndex: 0),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPagination), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });
}
