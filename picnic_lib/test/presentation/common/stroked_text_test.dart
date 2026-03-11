import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/stroked_text.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());

  Widget buildTestWidget({
    String text = 'Hello',
    TextStyle? textStyle,
    Color? strokeColor,
    double strokeWidth = 1,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StrokedText(
          text: text,
          textStyle: textStyle ?? const TextStyle(fontSize: 20),
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }

  group('StrokedText', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(StrokedText), findsOneWidget);
    });

    testWidgets('텍스트가 2개 표시됨 (stroke + main)', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: '테스트'));
      await tester.pump();

      expect(find.text('테스트'), findsNWidgets(2));
    });

    testWidgets('Stack으로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('커스텀 strokeColor 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        strokeColor: Colors.red,
      ));
      await tester.pump();

      expect(find.byType(StrokedText), findsOneWidget);
    });

    testWidgets('커스텀 strokeWidth 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        strokeWidth: 3.0,
      ));
      await tester.pump();

      expect(find.byType(StrokedText), findsOneWidget);
    });

    testWidgets('빈 텍스트 렌더링', (tester) async {
      await tester.pumpWidget(buildTestWidget(text: ''));
      await tester.pump();

      expect(find.byType(StrokedText), findsOneWidget);
    });

    test('StatelessWidget임', () {
      final widget = StrokedText(
        text: 'test',
        textStyle: const TextStyle(),
        strokeColor: Colors.blue,
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
