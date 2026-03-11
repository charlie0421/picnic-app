import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_score_widget.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());

  Widget buildTestWidget({int score = 75, String message = '좋은 궁합!'}) {
    return MaterialApp(
      home: Scaffold(
        body: AnimatedGoonghapBar(
          score: score,
          message: message,
        ),
      ),
    );
  }

  group('AnimatedGoonghapBar', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);
    });

    testWidgets('점수 퍼센트가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(score: 85));
      await tester.pump();

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('메시지가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(message: '환상의 궁합'));
      await tester.pump();

      expect(find.text('환상의 궁합'), findsOneWidget);
    });

    testWidgets('LayoutBuilder 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('TweenAnimationBuilder 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('score 0일 때 렌더링', (tester) async {
      await tester.pumpWidget(buildTestWidget(score: 0));
      await tester.pump();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('score 100일 때 렌더링', (tester) async {
      await tester.pumpWidget(buildTestWidget(score: 100));
      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('애니메이션 진행 후에도 정상', (tester) async {
      await tester.pumpWidget(buildTestWidget(score: 50));
      await tester.pump();

      // 애니메이션 중간
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);

      // 애니메이션 완료
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedGoonghapBar), findsOneWidget);
    });

    test('const 생성자 지원', () {
      const widget = AnimatedGoonghapBar(score: 75, message: 'test');
      expect(widget, isA<StatelessWidget>());
    });
  });
}
