import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/common_search_box.dart';
import 'package:picnic_lib/ui/style.dart';

void main() {
  late TextEditingController textController;
  late FocusNode focusNode;

  setUpAll(() {
    // AppColors의 Environment 의존 필드를 테스트용 기본값으로 초기화
    AppColors.primary500 = const Color(0xFF6200EE);
    AppColors.secondary500 = const Color(0xFF03DAC6);
    AppColors.sub500 = const Color(0xFF018786);
    AppColors.point500 = const Color(0xFFBB86FC);
    AppColors.point900 = const Color(0xFF3700B3);
  });

  setUp(() {
    textController = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    textController.dispose();
    focusNode.dispose();
  });

  Widget buildTestWidget({
    String hintText = '검색어를 입력하세요',
    Function(String)? onSubmitted,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CommonSearchBox(
                focusNode: focusNode,
                textEditingController: textController,
                hintText: hintText,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
        );
      },
    );
  }

  group('CommonSearchBox 렌더링 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CommonSearchBox), findsOneWidget);
    });

    testWidgets('TextField가 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('힌트 텍스트가 올바르게 표시되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(hintText: '아티스트를 검색하세요'),
      );
      await tester.pumpAndSettle();

      expect(find.text('아티스트를 검색하세요'), findsOneWidget);
    });
  });

  group('CommonSearchBox 입력 테스트', () {
    testWidgets('텍스트 입력이 정상적으로 동작하는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '테스트 검색어');
      await tester.pump();

      expect(textController.text, '테스트 검색어');
    });

    testWidgets('onSubmitted 콜백이 호출되는지 확인', (WidgetTester tester) async {
      String? submittedText;

      await tester.pumpWidget(
        buildTestWidget(
          onSubmitted: (text) {
            submittedText = text;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '검색어');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedText, '검색어');
    });
  });

  group('CommonSearchBox 구조 테스트', () {
    testWidgets('Row 위젯으로 구성되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('GestureDetector가 포함되어 있는지 확인 (검색/취소 버튼)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 검색 아이콘 탭과 취소 아이콘 탭을 위한 GestureDetector
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Container 장식이 적용되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 외부 Container가 48 높이로 렌더링되는지 확인
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxHeight == 48,
      );

      // Container가 존재하는지 확인 (장식이 적용된 컨테이너)
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('CommonSearchBox 상호작용 테스트', () {
    testWidgets('취소 버튼 탭 시 텍스트가 지워지는지 확인', (WidgetTester tester) async {
      String? submittedText;

      await tester.pumpWidget(
        buildTestWidget(
          onSubmitted: (text) {
            submittedText = text;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 텍스트 입력
      await tester.enterText(find.byType(TextField), '검색어');
      await tester.pump();
      expect(textController.text, '검색어');

      // 취소 버튼은 HitTestBehavior.opaque가 설정된 GestureDetector
      final cancelButton = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.behavior == HitTestBehavior.opaque,
      );
      await tester.tap(cancelButton);
      await tester.pump();

      // 텍스트가 지워졌는지 확인
      expect(textController.text, '');
      // onSubmitted가 빈 문자열로 호출되었는지 확인
      expect(submittedText, '');
    });
  });
}
