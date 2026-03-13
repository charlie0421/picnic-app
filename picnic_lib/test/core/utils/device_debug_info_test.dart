import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  group('SafeAreaDebugOverlay', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('shows only child when showDebugInfo is false', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SafeAreaDebugOverlay(
            showDebugInfo: false,
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('SafeArea Debug'), findsNothing);
    });

    testWidgets('shows debug overlay when showDebugInfo is true', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SafeAreaDebugOverlay(
            showDebugInfo: true,
            child: Text('Hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('SafeArea Debug'), findsOneWidget);
    });

    testWidgets('shows bottom padding info', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SafeAreaDebugOverlay(
            showDebugInfo: true,
            child: SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bottom:'), findsOneWidget);
      expect(find.textContaining('Screen:'), findsOneWidget);
    });
  });

  group('SafeAreaPainter', () {
    test('shouldRepaint returns false', () {
      final painter = SafeAreaPainter(EdgeInsets.zero);
      expect(painter.shouldRepaint(SafeAreaPainter(EdgeInsets.zero)), isFalse);
    });

    test('creates with padding', () {
      final painter = SafeAreaPainter(const EdgeInsets.all(10));
      expect(painter.padding, equals(const EdgeInsets.all(10)));
    });
  });

  group('DeviceDebugInfo', () {
    test('logSystemUIStatus does not throw', () {
      expect(() => DeviceDebugInfo.logSystemUIStatus(), returnsNormally);
    });

    setUp(() {
      initTestColors();
    });

    testWidgets('isGalaxyS25Like returns bool', (tester) async {
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

      expect(result, isA<bool>());
    });

    testWidgets('logSafeAreaInfo does not throw', (tester) async {
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
  });

  group('DeviceDebugInfo.checkGalaxyS25Like', () {
    test('returns true for Galaxy S25-like specs', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.50, 3.5),
        isTrue,
      );
    });

    test('returns false when height is too low', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2000, 0.50, 3.5),
        isFalse,
      );
    });

    test('returns false when ratio is too low', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.40, 3.5),
        isFalse,
      );
    });

    test('returns false when ratio is too high', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.60, 3.5),
        isFalse,
      );
    });

    test('returns false when pixel ratio is too low', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.50, 2.5),
        isFalse,
      );
    });

    test('returns false at boundary height 2800', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2800, 0.50, 3.5),
        isFalse,
      );
    });

    test('returns false at boundary ratio 0.45', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.45, 3.5),
        isFalse,
      );
    });

    test('returns false at boundary ratio 0.55', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.55, 3.5),
        isFalse,
      );
    });

    test('returns false at boundary pixel ratio 3.0', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2900, 0.50, 3.0),
        isFalse,
      );
    });

    test('returns true just above all boundaries', () {
      expect(
        DeviceDebugInfo.checkGalaxyS25Like(2801, 0.451, 3.01),
        isTrue,
      );
    });
  });

  group('DeviceDebugInfo.classifyBottomPadding', () {
    test('returns excessive for padding > 30', () {
      expect(DeviceDebugInfo.classifyBottomPadding(31), 'excessive');
    });

    test('returns excessive for large padding', () {
      expect(DeviceDebugInfo.classifyBottomPadding(50), 'excessive');
    });

    test('returns none for zero padding', () {
      expect(DeviceDebugInfo.classifyBottomPadding(0), 'none');
    });

    test('returns normal for padding between 0 and 30', () {
      expect(DeviceDebugInfo.classifyBottomPadding(15), 'normal');
    });

    test('returns normal for padding exactly 30', () {
      expect(DeviceDebugInfo.classifyBottomPadding(30), 'normal');
    });

    test('returns normal for padding of 1', () {
      expect(DeviceDebugInfo.classifyBottomPadding(1), 'normal');
    });

    test('returns excessive at boundary 30.1', () {
      expect(DeviceDebugInfo.classifyBottomPadding(30.1), 'excessive');
    });
  });
}
