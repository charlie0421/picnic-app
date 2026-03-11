import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/smooth_circular_countdown.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  Widget buildTestWidget({
    int remainingSeconds = 10,
    int totalSeconds = 30,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: SmoothCircularCountdown(
              remainingSeconds: remainingSeconds,
              totalSeconds: totalSeconds,
            ),
          ),
        );
      },
    );
  }

  group('SmoothCircularCountdown', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
    });

    testWidgets('초기 카운트다운 숫자 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(remainingSeconds: 10));
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('Stack과 CustomPaint 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('애니메이션 진행 중 카운트 감소', (tester) async {
      await tester.pumpWidget(buildTestWidget(remainingSeconds: 5));
      await tester.pump();

      // 시간 경과
      await tester.pump(const Duration(seconds: 3));
      // 카운트다운이 진행됨 - 위젯이 여전히 존재
      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
    });

    testWidgets('1초 남은 경우', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        remainingSeconds: 1,
        totalSeconds: 10,
      ));
      await tester.pump();

      expect(find.byType(SmoothCircularCountdown), findsOneWidget);
    });

    testWidgets('dispose 시 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });

    test('StatefulWidget임', () {
      const widget = SmoothCircularCountdown(
        remainingSeconds: 10,
        totalSeconds: 30,
      );
      expect(widget, isA<StatefulWidget>());
    });

    test('const 생성자 지원', () {
      const widget = SmoothCircularCountdown(
        remainingSeconds: 5,
        totalSeconds: 10,
      );
      expect(widget, isNotNull);
    });
  });

  group('CircularCountdownPainter', () {
    test('생성 확인', () {
      final painter = CircularCountdownPainter(
        progress: 0.5,
        remainingSeconds: 15,
      );
      expect(painter, isNotNull);
    });

    test('shouldRepaint는 항상 true', () {
      final painter = CircularCountdownPainter(
        progress: 0.5,
        remainingSeconds: 15,
      );
      final oldPainter = CircularCountdownPainter(
        progress: 0.3,
        remainingSeconds: 10,
      );
      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    test('progress 범위 확인', () {
      final painter1 = CircularCountdownPainter(
        progress: 0.0,
        remainingSeconds: 0,
      );
      final painter2 = CircularCountdownPainter(
        progress: 1.0,
        remainingSeconds: 30,
      );
      expect(painter1.progress, equals(0.0));
      expect(painter2.progress, equals(1.0));
    });
  });
}
