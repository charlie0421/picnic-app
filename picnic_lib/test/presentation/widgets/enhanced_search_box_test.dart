import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());

  Widget buildTestWidget({
    String hintText = '검색어를 입력하세요',
    ValueChanged<String>? onSearchChanged,
    ValueChanged<String>? onSearchSubmitted,
    VoidCallback? onClear,
    bool showClearButton = true,
    bool showSearchIcon = true,
    bool autofocus = false,
    bool enabled = true,
    String? initialValue,
    TextEditingController? controller,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: EnhancedSearchBox(
              hintText: hintText,
              onSearchChanged: onSearchChanged,
              onSearchSubmitted: onSearchSubmitted,
              onClear: onClear,
              showClearButton: showClearButton,
              showSearchIcon: showSearchIcon,
              autofocus: autofocus,
              enabled: enabled,
              initialValue: initialValue,
              controller: controller,
            ),
          ),
        );
      },
    );
  }

  group('EnhancedSearchBox', () {
    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });

    testWidgets('TextField 포함', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('힌트 텍스트 표시', (tester) async {
      await tester.pumpWidget(buildTestWidget(hintText: '아티스트 검색'));
      await tester.pump();

      expect(find.text('아티스트 검색'), findsOneWidget);
    });

    testWidgets('텍스트 입력 가능', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'BTS');
      await tester.pump();

      expect(find.text('BTS'), findsOneWidget);
    });

    testWidgets('onSearchChanged 디바운싱 콜백', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        buildTestWidget(onSearchChanged: (q) => lastQuery = q),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '테스트');
      // 디바운싱 시간(300ms) 후에 콜백 호출
      await tester.pump(const Duration(milliseconds: 400));

      expect(lastQuery, equals('테스트'));
    });

    testWidgets('검색 액션은 대기 중인 변경값을 즉시 한 번 전달한다', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(buildTestWidget(onSearchChanged: changes.add));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(changes, ['Alpha']);

      await tester.pump(const Duration(milliseconds: 300));
      expect(changes, ['Alpha']);
    });

    testWidgets('디바운스가 이미 끝난 값은 검색 액션에서 중복 전달하지 않는다', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(buildTestWidget(onSearchChanged: changes.add));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 301));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(changes, ['Alpha']);
    });

    testWidgets('대기 중 검색 액션은 변경과 제출 콜백을 모두 한 번씩 호출한다', (tester) async {
      final changes = <String>[];
      final submissions = <String>[];
      await tester.pumpWidget(
        buildTestWidget(
          onSearchChanged: changes.add,
          onSearchSubmitted: submissions.add,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));

      expect(changes, ['Alpha']);
      expect(submissions, ['Alpha']);
    });

    testWidgets('지우기는 대기 중인 검색어 대신 빈 변경값만 한 번 전달한다', (tester) async {
      final changes = <String>[];
      var clears = 0;
      await tester.pumpWidget(
        buildTestWidget(onSearchChanged: changes.add, onClear: () => clears++),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(SvgPicture).last);
      await tester.pump(const Duration(milliseconds: 400));

      expect(changes, ['']);
      expect(clears, 1);
    });

    testWidgets('외부 컨트롤러는 위젯 해제 후에 변경해도 상태를 갱신하지 않는다', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      controller.text = 'after dispose';

      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    testWidgets('외부 컨트롤러 교체 시 리스너를 새 컨트롤러로 옮긴다', (tester) async {
      final firstController = TextEditingController();
      final secondController = TextEditingController();
      final changes = <String>[];
      late StateSetter setHostState;
      var activeController = firstController;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return buildTestWidget(
              controller: activeController,
              onSearchChanged: changes.add,
            );
          },
        ),
      );
      await tester.pump();

      setHostState(() => activeController = secondController);
      await tester.pump();
      firstController.text = 'old';
      secondController.text = 'new';
      await tester.pump(const Duration(milliseconds: 301));

      expect(changes, ['new']);
      firstController.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      secondController.dispose();
    });

    testWidgets('initialValue 변경 리빌드는 사용자 입력을 덮어쓰지 않는다', (tester) async {
      late StateSetter setHostState;
      var initialValue = 'Seed';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return buildTestWidget(initialValue: initialValue);
          },
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'typed');
      setHostState(() => initialValue = 'replacement');
      await tester.pump();

      expect(find.text('typed'), findsOneWidget);
      expect(find.text('replacement'), findsNothing);
    });

    testWidgets('초기값 설정', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialValue: '초기검색어'));
      await tester.pump();

      expect(find.text('초기검색어'), findsOneWidget);
    });

    testWidgets('비활성화 상태', (tester) async {
      await tester.pumpWidget(buildTestWidget(enabled: false));
      await tester.pump();

      expect(find.byType(EnhancedSearchBox), findsOneWidget);
    });

    testWidgets('dispose 시 에러 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });

    test('기본값 확인', () {
      const widget = EnhancedSearchBox(hintText: 'test');
      expect(widget.debounceTime, equals(const Duration(milliseconds: 300)));
      expect(widget.showClearButton, isTrue);
      expect(widget.showSearchIcon, isTrue);
      expect(widget.autofocus, isFalse);
      expect(widget.enabled, isTrue);
      expect(widget.textInputAction, equals(TextInputAction.search));
      expect(widget.keyboardType, equals(TextInputType.text));
    });

    test('StatefulWidget임', () {
      const widget = EnhancedSearchBox(hintText: 'test');
      expect(widget, isA<StatefulWidget>());
    });
  });
}
