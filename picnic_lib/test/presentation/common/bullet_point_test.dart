import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/bullet_point.dart';

void main() {
  Widget buildTestWidget(String text) {
    return MaterialApp(
      home: Scaffold(
        body: BulletPoint(text),
      ),
    );
  }

  group('BulletPoint', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget('테스트 텍스트'));
      await tester.pump();

      expect(find.byType(BulletPoint), findsOneWidget);
    });

    testWidgets('bullet 문자(•)가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('항목 1'));
      await tester.pump();

      expect(find.text('• '), findsOneWidget);
    });

    testWidgets('전달된 텍스트가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('중요한 내용'));
      await tester.pump();

      expect(find.text('중요한 내용'), findsOneWidget);
    });

    testWidgets('Row와 Expanded로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('테스트'));
      await tester.pump();

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('빈 문자열도 렌더링 가능', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pump();

      expect(find.byType(BulletPoint), findsOneWidget);
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('긴 텍스트도 렌더링 가능', (tester) async {
      final longText = '이것은 매우 긴 텍스트입니다. ' * 20;
      await tester.pumpWidget(buildTestWidget(longText));
      await tester.pump();

      expect(find.byType(BulletPoint), findsOneWidget);
    });

    test('const 생성자 지원', () {
      const widget = BulletPoint('test');
      expect(widget, isA<StatelessWidget>());
    });
  });
}
