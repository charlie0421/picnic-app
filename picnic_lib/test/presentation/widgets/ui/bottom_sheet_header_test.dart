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
  });
}
