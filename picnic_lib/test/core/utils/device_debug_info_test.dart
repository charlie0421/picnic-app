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
}
