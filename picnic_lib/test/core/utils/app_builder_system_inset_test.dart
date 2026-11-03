import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/widgets/ui/system_navigation_bar_inset.dart';

import '../../helpers/test_environment.dart';

/// PICNIC-777: every MaterialPageRoute (home and pushed routes) and every
/// full-screen dialog must end above the Android system navigation bar without
/// per-page handling, and the reserved strip must live INSIDE each route so a
/// modal barrier dims it together with the rest of the page.
void main() {
  setUp(() => initTestColors());

  const homeKey = Key('home');
  const routeKey = Key('route');
  const dialogKey = Key('dialog');
  const bar = 48.0;

  Widget buildApp() {
    return MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        padding: EdgeInsets.only(bottom: bar),
        viewPadding: EdgeInsets.only(bottom: bar),
      ),
      child: MaterialApp(
        theme: AppBuilder.applySystemNavigationBarInset(ThemeData()),
        home: const Scaffold(body: SizedBox.expand(key: homeKey)),
      ),
    );
  }

  double screenBottom(WidgetTester tester) =>
      tester.getRect(find.byType(MaterialApp)).bottom;

  testWidgets(
    'home content ends above the system bar',
    (tester) async {
      await tester.pumpWidget(buildApp());
      expect(
        tester.getRect(find.byKey(homeKey)).bottom,
        screenBottom(tester) - bar,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a route pushed on the root Navigator ends above the system bar',
    (tester) async {
      await tester.pumpWidget(buildApp());
      final navigator = Navigator.of(tester.element(find.byKey(homeKey)));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox.expand(key: routeKey)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(routeKey)).bottom,
        screenBottom(tester) - bar,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a full-screen dialog ends above the system bar',
    (tester) async {
      await tester.pumpWidget(buildApp());
      showFullScreenDialog<void>(
        context: tester.element(find.byKey(homeKey)),
        builder: (_) =>
            const FullScreenDialog(child: SizedBox.expand(key: dialogKey)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(dialogKey)).bottom,
        screenBottom(tester) - bar,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'the reserved strip lives inside the Navigator so modal barriers cover it',
    (tester) async {
      await tester.pumpWidget(buildApp());
      expect(
        find.descendant(
          of: find.byType(Navigator),
          matching: find.byType(SystemNavigationBarInset),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byType(Navigator),
          matching: find.byType(SystemNavigationBarInset),
        ),
        findsNothing,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  test('applying the inset twice yields equal ThemeData', () {
    // MaterialApp receives a fresh ThemeData on every App rebuild. If the two
    // results are not equal, Theme notifies every dependent and Portal pages
    // re-run settingNavigation from didChangeDependencies (header/bottom nav
    // flip observed on device).
    final base = ThemeData();
    expect(
      AppBuilder.applySystemNavigationBarInset(base),
      equals(AppBuilder.applySystemNavigationBarInset(base)),
    );
  });

  testWidgets(
    'iOS keeps the full height',
    (tester) async {
      await tester.pumpWidget(buildApp());
      expect(tester.getRect(find.byKey(homeKey)).bottom, screenBottom(tester));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
