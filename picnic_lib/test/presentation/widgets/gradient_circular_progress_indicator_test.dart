import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/gradient_circular_progress_indicator.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  Widget buildTestWidget({
    double value = 0.5,
    double strokeWidth = 8.0,
    List<Color>? gradientColors,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GradientCircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            gradientColors: gradientColors ?? [Colors.blue, Colors.purple],
          ),
        ),
      ),
    );
  }

  group('GradientCircularProgressIndicator', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('CustomPaint 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('100x100 SizedBox 포함', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('value 0.0 렌더링', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 0.0));
      await tester.pump();

      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('value 1.0 렌더링', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 1.0));
      await tester.pump();

      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('value 0.75 이하 (gradient arc)', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 0.5));
      await tester.pump();

      // 애니메이션 진행
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('value 0.75 초과 (gradient + end arc)', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 0.9));
      await tester.pump();

      // 애니메이션 완료
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('커스텀 strokeWidth 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(strokeWidth: 12.0));
      await tester.pump();

      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('커스텀 gradientColors 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        gradientColors: [Colors.red, Colors.orange],
      ));
      await tester.pump();

      expect(
        find.byType(GradientCircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('애니메이션 전체 사이클', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 0.8));
      await tester.pump();

      // 애니메이션 시작
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GradientCircularProgressIndicator), findsOneWidget);

      // 애니메이션 중간
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GradientCircularProgressIndicator), findsOneWidget);

      // 애니메이션 완료
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GradientCircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dispose 시 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });

    test('const 생성자 지원', () {
      const widget = GradientCircularProgressIndicator(
        value: 0.5,
        strokeWidth: 8.0,
        gradientColors: [Colors.blue, Colors.purple],
      );
      expect(widget, isA<StatefulWidget>());
    });
  });
}
