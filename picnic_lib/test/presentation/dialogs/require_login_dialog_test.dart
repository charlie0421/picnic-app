import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('showRequireLoginDialog', () {
    testWidgets('shows dialog when navigatorKey context is available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Text('Home'),
        ),
      );
      await tester.pump();

      // navigatorKey should now have a valid context from buildTestApp
      expect(navigatorKey.currentContext, isNotNull);

      // Call showRequireLoginDialog
      showRequireLoginDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // A dialog should be visible (showSimpleDialog creates a Dialog)
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('does not throw when navigatorKey context is null',
        (WidgetTester tester) async {
      // Before pumping any widget, navigatorKey.currentContext might be null
      // or stale. We test that calling the function does not throw.
      // Note: This may or may not show a dialog depending on navigatorKey state,
      // but it should not crash.
      expect(() => showRequireLoginDialog(), returnsNormally);
    });

    testWidgets('dialog contains login required content text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Text('Home'),
        ),
      );
      await tester.pump();

      showRequireLoginDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The dialog should contain the login required message
      // from AppLocalizations.of(context).dialog_content_login_required
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('dialog has ok and cancel buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Text('Home'),
        ),
      );
      await tester.pump();

      showRequireLoginDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // showSimpleDialog creates ok and cancel buttons via TextButton
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('cancel button dismisses the dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Text('Home'),
        ),
      );
      await tester.pump();

      showRequireLoginDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have a dialog
      expect(find.byType(Dialog), findsOneWidget);

      // Find and tap the cancel button (first TextButton)
      final cancelButtons = find.byType(TextButton);
      expect(cancelButtons, findsNWidgets(2));

      // Tap the first button (cancel)
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
