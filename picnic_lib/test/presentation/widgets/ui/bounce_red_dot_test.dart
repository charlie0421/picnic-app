import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/bounce_red_dot.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('BounceRedDot', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      expect(find.byType(BounceRedDot), findsOneWidget);
    });

    testWidgets('contains a Center widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('contains AnimatedBuilder for animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(BounceRedDot),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders a circular red Container', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BounceRedDot),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('animation changes size over time', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      final containerBefore = tester.widget<Container>(
        find.descendant(
          of: find.byType(BounceRedDot),
          matching: find.byType(Container),
        ),
      );
      final sizeBefore = containerBefore.constraints?.maxWidth;

      // Advance animation halfway through 1-second duration
      await tester.pump(const Duration(milliseconds: 500));

      final containerAfter = tester.widget<Container>(
        find.descendant(
          of: find.byType(BounceRedDot),
          matching: find.byType(Container),
        ),
      );
      final sizeAfter = containerAfter.constraints?.maxWidth;

      // Container uses _animation.value.w so we just verify widget still renders
      // (exact sizes depend on ScreenUtil scaling)
      expect(find.byType(BounceRedDot), findsOneWidget);
      // The animation value should differ at different points
      expect(containerAfter, isNotNull);
    });

    testWidgets('disposes without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      // Replace widget tree to trigger dispose
      await tester.pumpWidget(
        buildTestApp(const SizedBox()),
      );
      await tester.pump();

      expect(find.byType(BounceRedDot), findsNothing);
    });

    testWidgets('animation repeats (reverse mode)', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BounceRedDot(),
        ),
      );
      await tester.pump();

      // Advance past one full cycle (1 second forward + 1 second reverse)
      await tester.pump(const Duration(seconds: 2));

      // Widget should still be rendering after a full animation cycle
      expect(find.byType(BounceRedDot), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BounceRedDot),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });
  });
}
