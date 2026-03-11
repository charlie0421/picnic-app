import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/gradient_border_painter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('GradientBorderPainter', () {
    test('creates with required parameters', () {
      final painter = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      expect(painter.borderRadius, 10);
      expect(painter.borderWidth, 2);
    });

    test('shouldRepaint returns false', () {
      final painter = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      final oldPainter = GradientBorderPainter(
        borderRadius: 5,
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.yellow],
        ),
        borderWidth: 1,
      );
      expect(painter.shouldRepaint(oldPainter), isFalse);
    });

    testWidgets('renders inside CustomPaint widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomPaint(
            painter: GradientBorderPainter(
              borderRadius: 12,
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.blue],
              ),
              borderWidth: 2,
            ),
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
