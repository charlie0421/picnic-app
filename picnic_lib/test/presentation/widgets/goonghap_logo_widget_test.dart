import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_logo_widget.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: GoonghapLogoWidget(),
      ),
    );
  }

  group('GoonghapLogoWidget', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(GoonghapLogoWidget), findsOneWidget);
    });

    testWidgets('SizedBox로 감싸져 있음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    test('const 생성자 지원', () {
      const widget = GoonghapLogoWidget();
      expect(widget, isA<StatelessWidget>());
    });
  });
}
