import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/bottom_sheet_header.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  Widget buildTestWidget(String title) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: BottomSheetHeader(title: title),
          ),
        );
      },
    );
  }

  group('BottomSheetHeader', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget('제목'));
      await tester.pump();

      expect(find.byType(BottomSheetHeader), findsOneWidget);
    });

    testWidgets('title 텍스트가 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('바텀시트 헤더'));
      await tester.pump();

      expect(find.text('바텀시트 헤더'), findsOneWidget);
    });

    testWidgets('Column으로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('테스트'));
      await tester.pump();

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('핸들바(그레이 바)가 포함됨', (tester) async {
      await tester.pumpWidget(buildTestWidget('테스트'));
      await tester.pump();

      // 핸들바 Container + 외부 Container = 2개
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('빈 제목도 렌더링 가능', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pump();

      expect(find.byType(BottomSheetHeader), findsOneWidget);
    });

    testWidgets('다양한 제목 렌더링 가능', (tester) async {
      await tester.pumpWidget(buildTestWidget('짧은 제목'));
      await tester.pump();

      expect(find.byType(BottomSheetHeader), findsOneWidget);
      expect(find.text('짧은 제목'), findsOneWidget);
    });

    test('const 생성자 지원', () {
      const widget = BottomSheetHeader(title: 'test');
      expect(widget, isA<StatelessWidget>());
    });
  });
}
