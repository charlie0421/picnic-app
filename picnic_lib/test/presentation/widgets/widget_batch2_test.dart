import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('SafeAreaDebugOverlay', () {
    testWidgets('showDebugInfo false returns child directly', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SafeAreaDebugOverlay(
          showDebugInfo: false,
          child: Text('Hello'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('SafeArea Debug'), findsNothing);
    });

    testWidgets('showDebugInfo true shows debug overlay', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SafeAreaDebugOverlay(
          showDebugInfo: true,
          child: Text('Content'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Content'), findsOneWidget);
      expect(find.text('SafeArea Debug'), findsOneWidget);
    });

    testWidgets('shows screen size info', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SafeAreaDebugOverlay(
          showDebugInfo: true,
          child: SizedBox.shrink(),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show Screen: and Bottom: info
      expect(find.textContaining('Bottom:'), findsOneWidget);
      expect(find.textContaining('Screen:'), findsOneWidget);
    });

    testWidgets('default showDebugInfo is false', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SafeAreaDebugOverlay(
          child: Text('Default'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('SafeArea Debug'), findsNothing);
    });
  });

  group('SafeAreaPainter', () {
    test('shouldRepaint returns false', () {
      final painter = SafeAreaPainter(EdgeInsets.zero);
      expect(painter.shouldRepaint(SafeAreaPainter(EdgeInsets.zero)), isFalse);
    });

    test('paint with zero padding', () {
      final painter = SafeAreaPainter(EdgeInsets.zero);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Should not throw
      painter.paint(canvas, const Size(375, 812));
      recorder.endRecording();
    });

    test('paint with bottom padding', () {
      final painter = SafeAreaPainter(const EdgeInsets.only(bottom: 34, top: 44));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Should not throw - draws both border rect and bottom fill
      painter.paint(canvas, const Size(375, 812));
      recorder.endRecording();
    });
  });

  group('DeviceDebugInfo', () {
    testWidgets('isGalaxyS25Like with small screen returns false', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            devicePixelRatio: 2.0,
          ),
          child: Builder(builder: (context) {
            expect(DeviceDebugInfo.isGalaxyS25Like(context), isFalse);
            return const SizedBox.shrink();
          }),
        ),
      );
    });

    testWidgets('isGalaxyS25Like with large screen returns true', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1440, 3088),
            devicePixelRatio: 3.5,
          ),
          child: Builder(builder: (context) {
            expect(DeviceDebugInfo.isGalaxyS25Like(context), isTrue);
            return const SizedBox.shrink();
          }),
        ),
      );
    });

    testWidgets('logSafeAreaInfo does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            DeviceDebugInfo.logSafeAreaInfo(context);
            return const SizedBox.shrink();
          }),
        ),
      );
    });

    testWidgets('logSafeAreaInfo with large bottom padding', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(bottom: 40, top: 44),
          ),
          child: MaterialApp(
            home: Builder(builder: (context) {
              DeviceDebugInfo.logSafeAreaInfo(context);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
    });

    testWidgets('logSafeAreaInfo with zero bottom padding', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.zero,
          ),
          child: MaterialApp(
            home: Builder(builder: (context) {
              DeviceDebugInfo.logSafeAreaInfo(context);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
    });

    test('logSystemUIStatus does not throw', () {
      DeviceDebugInfo.logSystemUIStatus();
    });
  });
}
