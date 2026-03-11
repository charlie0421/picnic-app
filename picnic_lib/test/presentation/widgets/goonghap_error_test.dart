import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_error.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());

  Widget buildTestWidget(String error) {
    return MaterialApp(
      home: Scaffold(
        body: GoonghapErrorView(error: error),
      ),
    );
  }

  group('GoonghapErrorView', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget('오류 발생'));
      await tester.pump();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
    });

    testWidgets('에러 메시지가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('네트워크 오류'));
      await tester.pump();

      expect(find.text('네트워크 오류'), findsOneWidget);
    });

    testWidgets('에러 아이콘이 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('오류'));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Column으로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('오류'));
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('빈 에러 메시지도 렌더링 가능', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pump();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
    });

    test('const 생성자 지원', () {
      const widget = GoonghapErrorView(error: 'test');
      expect(widget, isA<StatelessWidget>());
    });
  });
}
