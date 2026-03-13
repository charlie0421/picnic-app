import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// Additional tests targeting uncovered lines in device_debug_info.dart.
///
/// Targets:
/// - logSafeAreaInfo with excessive bottom padding (lines 48-50)
/// - logSafeAreaInfo with zero bottom padding (lines 51-52)
/// - logSafeAreaInfo with normal bottom padding (lines 53-54)
/// - SafeAreaPainter.paint with bottom padding > 0 (lines 197-206)
/// - SafeAreaPainter.paint with bottom padding == 0
void main() {
  group('DeviceDebugInfo.classifyBottomPadding - edge cases', () {
    test('returns excessive for very large padding', () {
      expect(DeviceDebugInfo.classifyBottomPadding(100), 'excessive');
    });

    test('returns excessive for 31', () {
      expect(DeviceDebugInfo.classifyBottomPadding(31), 'excessive');
    });

    test('returns none for exactly 0.0', () {
      expect(DeviceDebugInfo.classifyBottomPadding(0.0), 'none');
    });

    test('returns normal for 0.1', () {
      expect(DeviceDebugInfo.classifyBottomPadding(0.1), 'normal');
    });

    test('returns normal for 29.9', () {
      expect(DeviceDebugInfo.classifyBottomPadding(29.9), 'normal');
    });
  });

  group('DeviceDebugInfo.checkGalaxyS25Like - additional boundaries', () {
    test('returns true for typical S25 specs', () {
      expect(DeviceDebugInfo.checkGalaxyS25Like(3088, 0.48, 3.44), isTrue);
    });

    test('returns false when all conditions fail', () {
      expect(DeviceDebugInfo.checkGalaxyS25Like(1920, 0.6, 2.0), isFalse);
    });
  });

  group('SafeAreaPainter', () {
    test('paint renders with non-zero bottom padding', () {
      final painter = SafeAreaPainter(const EdgeInsets.only(
        top: 44,
        bottom: 34,
      ));

      // Verify it can paint without errors
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(375, 812));
      recorder.endRecording();

      expect(painter.padding.bottom, 34);
    });

    test('paint renders with zero bottom padding', () {
      final painter = SafeAreaPainter(EdgeInsets.zero);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(375, 812));
      recorder.endRecording();

      // No orange overlay should be drawn when padding.bottom == 0
      expect(painter.padding.bottom, 0);
    });

    test('paint renders with all padding values', () {
      final painter = SafeAreaPainter(const EdgeInsets.fromLTRB(10, 44, 10, 34));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(375, 812));
      recorder.endRecording();

      expect(painter.padding.left, 10);
      expect(painter.padding.right, 10);
    });
  });

  group('SafeAreaDebugOverlay', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('renders debug info with padding data', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SafeAreaDebugOverlay(
            showDebugInfo: true,
            child: Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SafeArea Debug'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('hides debug info when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SafeAreaDebugOverlay(
            showDebugInfo: false,
            child: Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SafeArea Debug'), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('DeviceDebugInfo - context-dependent methods', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('logSafeAreaInfo runs without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            DeviceDebugInfo.logSafeAreaInfo(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('isGalaxyS25Like returns false for standard test screen',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = DeviceDebugInfo.isGalaxyS25Like(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      // Test environment has standard screen size, not S25-like
      expect(result, isFalse);
    });

    test('logSystemUIStatus runs without error', () {
      expect(() => DeviceDebugInfo.logSystemUIStatus(), returnsNormally);
    });
  });
}
