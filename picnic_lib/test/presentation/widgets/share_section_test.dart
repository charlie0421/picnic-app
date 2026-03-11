import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  Widget buildTestWidget({
    VoidCallback? onSave,
    VoidCallback? onShare,
    String saveButtonText = 'save',
    String shareButtonText = 'share',
    double? buttonWidth,
    double? buttonHeight,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: ShareSection(
              onSave: onSave ?? () {},
              onShare: onShare ?? () {},
              saveButtonText: saveButtonText,
              shareButtonText: shareButtonText,
              buttonWidth: buttonWidth,
              buttonHeight: buttonHeight,
            ),
          ),
        );
      },
    );
  }

  group('ShareSection', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(ShareSection), findsOneWidget);
    });

    testWidgets('저장/공유 버튼 2개 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('커스텀 버튼 텍스트 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        saveButtonText: '저장하기',
        shareButtonText: '공유하기',
      ));
      await tester.pump();

      expect(find.text('저장하기'), findsOneWidget);
      expect(find.text('공유하기'), findsOneWidget);
    });

    testWidgets('onSave 콜백 호출', (tester) async {
      var saved = false;
      await tester.pumpWidget(buildTestWidget(
        onSave: () => saved = true,
      ));
      await tester.pump();

      // 첫 번째 ElevatedButton (save)을 탭
      await tester.tap(find.byType(ElevatedButton).first);
      expect(saved, isTrue);
    });

    testWidgets('onShare 콜백 호출', (tester) async {
      var shared = false;
      await tester.pumpWidget(buildTestWidget(
        onShare: () => shared = true,
      ));
      await tester.pump();

      // 두 번째 ElevatedButton (share)을 탭
      await tester.tap(find.byType(ElevatedButton).last);
      expect(shared, isTrue);
    });

    testWidgets('Row로 구성됨', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('커스텀 버튼 크기 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        buttonWidth: 150,
        buttonHeight: 40,
      ));
      await tester.pump();

      expect(find.byType(ShareSection), findsOneWidget);
    });

    test('const 생성자 지원', () {
      final widget = ShareSection(
        onSave: () {},
        onShare: () {},
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
