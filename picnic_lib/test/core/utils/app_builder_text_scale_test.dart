import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';

/// PICNIC-2750: the app honours system text scale only up to
/// [kAppMaxTextScaleFactor] — on the home route, in dialogs and in
/// OverlaySupport toasts, which draw outside MaterialApp. Smaller settings
/// must pass through untouched.
void main() {
  const homeKey = Key('home');
  const dialogKey = Key('dialog');
  const toastKey = Key('toast');

  // Same nesting as AppBuilder: cap → OverlaySupport → MaterialApp.
  Future<void> pump(WidgetTester tester, double systemScale) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(systemScale)),
        child: Builder(
          builder: (context) => AppBuilder.clampTextScale(
            context,
            const OverlaySupport.global(
              child: MaterialApp(home: SizedBox(key: homeKey)),
            ),
          ),
        ),
      ),
    );
  }

  double scaleAt(WidgetTester tester, Key key) =>
      MediaQuery.textScalerOf(tester.element(find.byKey(key))).scale(10) / 10;

  for (final (system, expected) in const [
    (1.0, 1.0),
    (2.0, 2.0),
    (2.6, 2.6),
    (3.1, kAppMaxTextScaleFactor),
  ]) {
    testWidgets('system ${system}x draws at ${expected}x', (tester) async {
      await pump(tester, system);
      expect(scaleAt(tester, homeKey), closeTo(expected, 1e-9));

      showDialog<void>(
        context: tester.element(find.byKey(homeKey)),
        builder: (_) => const SizedBox(key: dialogKey),
      );
      await tester.pumpAndSettle();
      expect(
        scaleAt(tester, dialogKey),
        closeTo(expected, 1e-9),
        reason: 'dialogs are pushed under the cap and must be capped too',
      );

      final toast = showSimpleNotification(
        const SizedBox(key: toastKey),
        duration: const Duration(seconds: 1),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        scaleAt(tester, toastKey),
        closeTo(expected, 1e-9),
        reason: 'toasts draw outside MaterialApp and must be capped too',
      );
      toast.dismiss(animate: false);
      await tester.pumpAndSettle();
    });
  }
}
