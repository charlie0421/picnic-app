import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';

import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

const _longTitle = '매우 긴 마이페이지 상세 화면 제목입니다';
const _widths = <double>[320, 375, 430];

Future<void> _pumpScreen(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 700 * 3);
  addTearDown(tester.view.reset);

  final drawerStack = NavigationStack()
    ..push(const SizedBox(key: ValueKey('drawer-page')));
  await tester.pumpWidget(
    buildTestApp(
      const MyPageScreen(),
      navigation: Navigation(
        drawerNavigationStack: drawerStack,
        myPageTitle: _longTitle,
      ),
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      textScaler: const TextScaler.linear(2),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  for (final width in _widths) {
    testWidgets(
      'back target and long 200% title fit atomically at ${width.toInt()}px',
      (tester) async {
        await _pumpScreen(tester, width);

        expect(tester.takeException(), isNull);
        final appBarFinder = find.byType(AppBar);
        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.leadingWidth, greaterThanOrEqualTo(60));

        final backTarget = find.descendant(
          of: appBarFinder,
          matching: find.byType(InkWell),
        );
        expect(backTarget, findsOneWidget);
        final appBarRect = tester.getRect(appBarFinder);
        final backRect = tester.getRect(backTarget);
        expect(backRect.width, greaterThanOrEqualTo(48));
        expect(backRect.height, greaterThanOrEqualTo(48));
        expect(backRect.left - appBarRect.left, closeTo(12, 0.01));

        final title = find.text(_longTitle);
        expect(title, findsOneWidget);
        final titleRect = tester.getRect(title);
        expect(titleRect.left, greaterThanOrEqualTo(backRect.right));
        expect(titleRect.right, lessThanOrEqualTo(appBarRect.right));
        expect(titleRect.top, greaterThanOrEqualTo(appBarRect.top));
        expect(titleRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
      },
    );
  }
}
