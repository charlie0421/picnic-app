import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      await tester.pumpWidget(buildTestWidget(
        onSearchChanged: (q) => lastQuery = q,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '테스트');
      // 디바운싱 시간(300ms) 후에 콜백 호출
      await tester.pump(const Duration(milliseconds: 400));

      expect(lastQuery, equals('테스트'));
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
