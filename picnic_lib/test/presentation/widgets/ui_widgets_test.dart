import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/bounce_red_dot.dart';
import 'package:picnic_lib/presentation/widgets/ui/gradient_border_painter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('GradientBorderPainter', () {
    test('shouldRepaint returns false', () {
      final painter = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
        borderWidth: 2,
      );
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('constructor stores values', () {
      final painter = GradientBorderPainter(
        borderRadius: 15,
        gradient: const LinearGradient(colors: [Colors.green, Colors.yellow]),
        borderWidth: 3,
      );
      expect(painter.borderRadius, 15);
      expect(painter.borderWidth, 3);
    });
  });

  group('BounceRedDot', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const BounceRedDot()),
      );
      // Just pump one frame (animated widget)
      await tester.pump();

      expect(find.byType(BounceRedDot), findsOneWidget);
    });

    testWidgets('contains red circle decoration', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const BounceRedDot()),
      );
      await tester.pump();

      // Find container with circle shape
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRedCircle = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == Colors.red &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(hasRedCircle, isTrue);
    });
  });
}
