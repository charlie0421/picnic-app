import 'dart:ui';

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

    test('stores gradient correctly', () {
      const gradient = LinearGradient(
        colors: [Colors.green, Colors.yellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      final painter = GradientBorderPainter(
        borderRadius: 8,
        gradient: gradient,
        borderWidth: 1,
      );
      expect(painter.gradient, gradient);
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

    test('shouldRepaint returns false even with same instance', () {
      final painter = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('shouldRepaint returns false with identical parameters', () {
      final painter1 = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      final painter2 = GradientBorderPainter(
        borderRadius: 10,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('paint does not crash with typical values', () {
      final painter = GradientBorderPainter(
        borderRadius: 12,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );

      final canvas = _TestCanvas();
      painter.paint(canvas, const Size(100, 50));
      expect(canvas.drawnRRects, 1);
    });

    test('paint does not crash with zero border radius', () {
      final painter = GradientBorderPainter(
        borderRadius: 0,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 1,
      );

      final canvas = _TestCanvas();
      painter.paint(canvas, const Size(50, 50));
      expect(canvas.drawnRRects, 1);
    });

    test('paint does not crash with large border width', () {
      final painter = GradientBorderPainter(
        borderRadius: 20,
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.orange, Colors.cyan],
        ),
        borderWidth: 10,
      );

      final canvas = _TestCanvas();
      painter.paint(canvas, const Size(200, 100));
      expect(canvas.drawnRRects, 1);
    });

    test('paint uses stroke style with correct width', () {
      final painter = GradientBorderPainter(
        borderRadius: 8,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 3,
      );

      final canvas = _TestCanvas();
      painter.paint(canvas, const Size(100, 50));

      expect(canvas.lastPaint?.style, PaintingStyle.stroke);
      expect(canvas.lastPaint?.strokeWidth, 3);
      expect(canvas.lastPaint?.shader, isNotNull);
    });

    test('paint creates RRect with correct border radius', () {
      final painter = GradientBorderPainter(
        borderRadius: 15,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );

      final canvas = _TestCanvas();
      painter.paint(canvas, const Size(100, 50));

      expect(canvas.lastRRect, isNotNull);
      expect(canvas.lastRRect!.blRadius, const Radius.circular(15));
      expect(canvas.lastRRect!.trRadius, const Radius.circular(15));
    });

    test('constructor accepts various gradient types', () {
      // RadialGradient
      final painter1 = GradientBorderPainter(
        borderRadius: 10,
        gradient: const RadialGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      expect(painter1.gradient, isA<RadialGradient>());

      // SweepGradient
      final painter2 = GradientBorderPainter(
        borderRadius: 10,
        gradient: const SweepGradient(
          colors: [Colors.red, Colors.blue],
        ),
        borderWidth: 2,
      );
      expect(painter2.gradient, isA<SweepGradient>());
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

    testWidgets('renders with RadialGradient in widget tree', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomPaint(
            painter: GradientBorderPainter(
              borderRadius: 20,
              gradient: const RadialGradient(
                colors: [Colors.orange, Colors.purple],
              ),
              borderWidth: 3,
            ),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

/// A test canvas that tracks drawRRect calls.
class _TestCanvas extends Fake implements Canvas {
  int drawnRRects = 0;
  Paint? lastPaint;
  RRect? lastRRect;

  @override
  void drawRRect(RRect rrect, Paint paint) {
    drawnRRects++;
    lastPaint = paint;
    lastRRect = rrect;
  }
}
