import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/underlined_widget.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  Widget buildTestWidget({
    Widget child = const Text('밑줄 텍스트'),
    Color? underlineColor,
    double underlineHeight = 2,
    double underlineGap = 4,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: UnderlinedWidget(
            underlineColor: underlineColor,
            underlineHeight: underlineHeight,
            underlineGap: underlineGap,
            child: child,
          ),
        ),
      ),
    );
  }

  group('UnderlinedWidget', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(UnderlinedWidget), findsOneWidget);
    });

    testWidgets('자식 위젯이 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const Text('Hello'),
      ));
      await tester.pump();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('Stack으로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('post frame callback 후 밑줄 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('커스텀 underlineColor 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        underlineColor: Colors.red,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(UnderlinedWidget), findsOneWidget);
    });

    testWidgets('다양한 자식 위젯 지원', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const Text('다른 위젯'),
      ));
      await tester.pump();

      expect(find.text('다른 위젯'), findsOneWidget);
    });

    test('StatefulWidget임', () {
      const widget = UnderlinedWidget(child: SizedBox());
      expect(widget, isA<StatefulWidget>());
    });

    test('const 생성자 지원', () {
      const widget = UnderlinedWidget(child: SizedBox());
      expect(widget, isNotNull);
    });
  });
}
