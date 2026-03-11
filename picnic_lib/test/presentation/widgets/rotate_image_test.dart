import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/rotate_image.dart';

void main() {
  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: RotationImage(
          image: Image.asset(
            'assets/app_icon_128.png',
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 50, height: 50),
          ),
        ),
      ),
    );
  }

  group('RotationImage', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(RotationImage), findsOneWidget);
    });

    testWidgets('Center로 감싸져 있음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('Transform이 포함됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('애니메이션 진행 후에도 정상', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 1초 후 (반 바퀴 회전)
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RotationImage), findsOneWidget);

      // 2초 후 (한 바퀴 완전 회전)
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RotationImage), findsOneWidget);
    });

    testWidgets('dispose 시 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });

    test('StatefulWidget임', () {
      final widget = RotationImage(
        image: Image.asset('test.png'),
      );
      expect(widget, isA<StatefulWidget>());
    });
  });
}
