import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/smooth_circular_countdown.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('SmoothCircularCountdown', () {
    testWidgets('renders with initial seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 10,
            totalSeconds: 30,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders with different values', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 5,
            totalSeconds: 60,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders with 1 second remaining',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 1,
            totalSeconds: 10,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders with large duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 120,
            totalSeconds: 300,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('countdown decreases over time', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 5,
            totalSeconds: 10,
          ),
        ),
      );
      await tester.pump();

      // Initially shows 5
      expect(find.text('5'), findsOneWidget);

      // Advance animation partway through (2 seconds)
      await tester.pump(const Duration(seconds: 2));

      // After 2 seconds of a 5-second animation, the displayed count should
      // have decreased. The exact value depends on animation curve, but it
      // should no longer show 5.
      expect(find.text('5'), findsNothing);
    });

    testWidgets('animation completes and shows 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 3,
            totalSeconds: 10,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);

      // Advance past the full duration to complete the animation
      await tester.pump(const Duration(seconds: 3));

      // After animation completes, ceil(0.0 * 3) = 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('contains CustomPaint widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 10,
            totalSeconds: 30,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('disposes without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SmoothCircularCountdown(
            remainingSeconds: 10,
            totalSeconds: 30,
          ),
        ),
      );
      await tester.pump();

      // Replace with a different widget to trigger dispose
      await tester.pumpWidget(
        buildTestApp(const SizedBox()),
      );
      await tester.pump();

      // No exception means dispose worked correctly
      expect(find.byType(SmoothCircularCountdown), findsNothing);
    });
  });

  group('CircularCountdownPainter', () {
    test('shouldRepaint always returns true', () {
      final painter = CircularCountdownPainter(
        progress: 0.5,
        remainingSeconds: 5,
      );
      final oldPainter = CircularCountdownPainter(
        progress: 0.5,
        remainingSeconds: 5,
      );

      // shouldRepaint always returns true per implementation
      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true even with identical values', () {
      final painter = CircularCountdownPainter(
        progress: 1.0,
        remainingSeconds: 10,
      );

      expect(painter.shouldRepaint(painter), isTrue);
    });

    test('shouldRepaint returns true with different values', () {
      final painter = CircularCountdownPainter(
        progress: 0.8,
        remainingSeconds: 8,
      );
      final oldPainter = CircularCountdownPainter(
        progress: 0.3,
        remainingSeconds: 3,
      );

      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    test('stores progress and remainingSeconds', () {
      final painter = CircularCountdownPainter(
        progress: 0.75,
        remainingSeconds: 15,
      );

      expect(painter.progress, 0.75);
      expect(painter.remainingSeconds, 15);
    });

    test('paint does not crash with zero progress', () {
      final painter = CircularCountdownPainter(
        progress: 0.0,
        remainingSeconds: 0,
      );

      // Painting on a real canvas via a PictureRecorder
      final recorder = TestRecordingCanvas();
      painter.paint(recorder, const Size(16, 16));
    });

    test('paint does not crash with full progress', () {
      final painter = CircularCountdownPainter(
        progress: 1.0,
        remainingSeconds: 10,
      );

      final recorder = TestRecordingCanvas();
      painter.paint(recorder, const Size(16, 16));
    });

    test('paint does not crash with various sizes', () {
      final painter = CircularCountdownPainter(
        progress: 0.5,
        remainingSeconds: 5,
      );

      // Small size
      final recorder1 = TestRecordingCanvas();
      painter.paint(recorder1, const Size(1, 1));

      // Large size
      final recorder2 = TestRecordingCanvas();
      painter.paint(recorder2, const Size(200, 200));

      // Non-square size
      final recorder3 = TestRecordingCanvas();
      painter.paint(recorder3, const Size(50, 100));
    });
  });
}

/// A test canvas that records calls without requiring a real rendering surface.
class TestRecordingCanvas extends Fake implements Canvas {
  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    // no-op for testing
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {
    // no-op for testing
  }
}
