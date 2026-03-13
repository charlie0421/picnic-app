import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/bottom_sheet_header.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('BottomSheetHeader', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: '설정'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('renders with Column layout', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: 'Test Title'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetHeader), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders drag handle container', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: 'Header'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with different titles', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: 'Long Title For Testing'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Long Title For Testing'), findsOneWidget);
    });

    testWidgets('renders with empty title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetHeader), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders with special characters in title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: '특수문자 !@#\$%'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('특수문자 !@#\$%'), findsOneWidget);
    });

    testWidgets('has correct container height of 70', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: '테스트'),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byType(BottomSheetHeader);
      expect(headerFinder, findsOneWidget);

      final headerSize = tester.getSize(headerFinder);
      expect(headerSize.height, equals(70.0));
    });

    testWidgets('title text is center-aligned', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: '중앙 정렬'),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('중앙 정렬'));
      expect(textWidget.textAlign, equals(TextAlign.center));
    });

    testWidgets('column has spaceBetween alignment', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const BottomSheetHeader(title: '정렬 테스트'),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Column inside BottomSheetHeader
      final columnFinder = find.descendant(
        of: find.byType(BottomSheetHeader),
        matching: find.byType(Column),
      );
      expect(columnFinder, findsOneWidget);

      final column = tester.widget<Column>(columnFinder);
      expect(
        column.mainAxisAlignment,
        equals(MainAxisAlignment.spaceBetween),
      );
    });
  });
}
