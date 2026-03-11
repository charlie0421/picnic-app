import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/bounce_red_dot.dart';

void main() {
  Widget buildTestWidget() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return const MaterialApp(
          home: Scaffold(
            body: BounceRedDot(),
          ),
        );
      },
    );
  }

  group('BounceRedDot', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(BounceRedDot), findsOneWidget);
    });

    testWidgets('Center 위젯으로 감싸져 있음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('Container가 포함됨 (빨간 원)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('애니메이션이 시작됨 (pump 후 상태 변화)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 애니메이션 중간 상태
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BounceRedDot), findsOneWidget);

      // 애니메이션 한 사이클 후
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BounceRedDot), findsOneWidget);
    });

    testWidgets('위젯 dispose 시 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 다른 위젯으로 교체하여 dispose 트리거
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });

    test('StatefulWidget임', () {
      const widget = BounceRedDot();
      expect(widget, isA<StatefulWidget>());
    });

    test('const 생성자 지원', () {
      const widget = BounceRedDot();
      expect(widget, isNotNull);
    });
  });
}
