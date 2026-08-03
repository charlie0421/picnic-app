import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/fortune_divider.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_error.dart';
import 'package:picnic_lib/presentation/widgets/stroked_text.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('FortuneDivider', () {
    testWidgets('renders with given color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const FortuneDivider(color: Colors.red),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with different color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const FortuneDivider(color: Colors.blue),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
    });
  });

  group('GoonghapErrorView', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const GoonghapErrorView(error: '테스트 에러 메시지'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('테스트 에러 메시지'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays long error message', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const GoonghapErrorView(error: '이것은 매우 긴 에러 메시지입니다. 여러 줄에 걸쳐 표시될 수 있습니다.'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
    });
  });

  group('StrokedText', () {
    testWidgets('renders text with stroke', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: '테스트',
          textStyle: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ));
      await tester.pumpAndSettle();

      // Stack contains two Text widgets (stroke + fill)
      expect(find.text('테스트'), findsNWidgets(2));
    });

    testWidgets('renders with custom stroke color and width', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: 'Hello',
          textStyle: const TextStyle(fontSize: 16, color: Colors.black),
          strokeColor: Colors.red,
          strokeWidth: 3,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNWidgets(2));
    });

    testWidgets('uses default stroke color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: 'Default',
          textStyle: const TextStyle(fontSize: 14),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StrokedText), findsOneWidget);
    });
  });


}
