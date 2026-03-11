import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';

void main() {
  Widget buildTestWidget({
    String leading = '설정',
    String assetPath = 'assets/icons/arrow_right.svg',
    VoidCallback? onTap,
    Widget? tailing,
    Widget? title,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PicnicListItem(
          leading: leading,
          assetPath: assetPath,
          onTap: onTap,
          tailing: tailing,
          title: title,
        ),
      ),
    );
  }

  group('PicnicListItem', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(PicnicListItem), findsOneWidget);
    });

    testWidgets('leading 텍스트가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(leading: '내 프로필'));
      await tester.pump();

      expect(find.text('내 프로필'), findsOneWidget);
    });

    testWidgets('InkWell이 포함됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('onTap 콜백 호출', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestWidget(
        onTap: () => tapped = true,
      ));
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('커스텀 tailing 위젯 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tailing: const Icon(Icons.check),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('커스텀 title 위젯 사용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: const Text('서브타이틀'),
      ));
      await tester.pump();

      expect(find.text('서브타이틀'), findsOneWidget);
    });

    testWidgets('Divider가 포함됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('onTap이 null이면 탭 가능하지만 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget(onTap: null));
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      // 에러 없이 완료
    });

    test('const 생성자 지원', () {
      const widget = PicnicListItem(
        leading: 'test',
        assetPath: 'test.svg',
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
