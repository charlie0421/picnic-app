import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/custom_dropdown_button.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_app.dart';
import '../../helpers/load_test_fonts.dart';

void main() {
  setUpAll(() => initTestColors());
  setUpAll(loadTestFonts);

  testWidgets(
    'long category remains readable and selectable at 320px and 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const label = '보너스 스타캔디 적립 및 투표기능 관련 문의';
      String? selected;
      await tester.pumpWidget(
        buildTestApp(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomDropdown(
              value: 'long',
              onChanged: (value) => selected = value,
              items: [
                CustomDropdownMenuItem(value: 'long', text: label),
                CustomDropdownMenuItem(value: 'general', text: '일반 문의'),
              ],
            ),
          ),
          designSize: const Size(393, 892),
          splitScreenMode: true,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bounds = tester.getRect(find.byType(CustomDropdown));
      final textBounds = tester.getRect(find.text(label));
      expect(textBounds.left, greaterThanOrEqualTo(bounds.left));
      expect(textBounds.right, lessThanOrEqualTo(bounds.right));
      expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일반 문의').last);
      await tester.pumpAndSettle();
      expect(selected, 'general');
      expect(tester.takeException(), isNull);
    },
  );

  group('CustomDropdownMenuItem', () {
    test('생성 확인', () {
      final item = CustomDropdownMenuItem(value: 'v1', text: '옵션 1');
      expect(item.value, equals('v1'));
      expect(item.text, equals('옵션 1'));
    });

    test('빈 값으로 생성', () {
      final item = CustomDropdownMenuItem(value: '', text: '선택하세요');
      expect(item.value, isEmpty);
      expect(item.text, equals('선택하세요'));
    });
  });

  group('CustomDropdown', () {
    Widget buildTestWidget({
      String value = 'option1',
      ValueChanged<String?>? onChanged,
      List<CustomDropdownMenuItem>? items,
    }) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) {
          return MaterialApp(
            home: Scaffold(
              body: CustomDropdown(
                value: value,
                onChanged: onChanged ?? (_) {},
                items:
                    items ??
                    [
                      CustomDropdownMenuItem(value: 'option1', text: '옵션 1'),
                      CustomDropdownMenuItem(value: 'option2', text: '옵션 2'),
                      CustomDropdownMenuItem(value: 'option3', text: '옵션 3'),
                    ],
              ),
            ),
          );
        },
      );
    }

    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CustomDropdown), findsOneWidget);
    });

    testWidgets('DropdownButtonFormField 포함', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('선택된 값이 표시됨', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: 'option1'));
      await tester.pump();

      expect(find.text('옵션 1'), findsOneWidget);
    });

    testWidgets('빈 값(placeholder)으로 렌더링', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          value: '',
          items: [
            CustomDropdownMenuItem(value: '', text: '선택하세요'),
            CustomDropdownMenuItem(value: 'a', text: 'A'),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CustomDropdown), findsOneWidget);
    });

    testWidgets('IntrinsicWidth로 감싸져 있음', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(IntrinsicWidth), findsOneWidget);
    });

    test('const 생성자 지원', () {
      final widget = CustomDropdown(
        value: 'test',
        onChanged: (_) {},
        items: const [],
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}
