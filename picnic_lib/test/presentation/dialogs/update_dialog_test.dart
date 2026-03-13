import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  Widget buildUpdateDialog({
    AppInitializationState? initState,
    Widget? child,
  }) {
    return buildTestApp(
      UpdateDialog(child: child ?? const Text('Child Content')),
      extraOverrides: [
        appInitializationProvider.overrideWithValue(
          initState ?? const AppInitializationState(),
        ),
      ],
    );
  }

  /// Drains all pending timers from the OverlayNotification countdown.
  /// The overlay counts down for 5 seconds, then reverses an animation (300ms).
  Future<void> drainOverlayTimers(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    // Drain the reverse animation (300ms)
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  group('UpdateDialog', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildUpdateDialog());
      // Advance past the 2-second Future.delayed to drain the pending timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildUpdateDialog());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('shows update overlay when updateRecommended',
        (tester) async {
      final updateInfo = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '0.9.0',
        url: 'https://example.com/update',
      );

      await tester.pumpWidget(buildUpdateDialog(
        initState: AppInitializationState(updateInfo: updateInfo),
      ));

      // Advance past the 2-second Future.delayed in initState
      await tester.pump(const Duration(seconds: 2));
      // Advance for the addPostFrameCallback
      await tester.pump();

      // The overlay should show the version text
      expect(find.textContaining('2.0.0'), findsOneWidget);

      // Drain remaining overlay timers to avoid pending timer assertion
      await drainOverlayTimers(tester);
    });

    testWidgets('does not show notification when no update info',
        (tester) async {
      await tester.pumpWidget(buildUpdateDialog());

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Only the child should be visible, no overlay
      expect(find.text('Child Content'), findsOneWidget);
      // No TextButton from overlay
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('update overlay contains update button', (tester) async {
      final updateInfo = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '0.9.0',
        url: 'https://example.com/update',
      );

      await tester.pumpWidget(buildUpdateDialog(
        initState: AppInitializationState(updateInfo: updateInfo),
      ));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byType(TextButton), findsOneWidget);

      // Drain remaining overlay timers
      await drainOverlayTimers(tester);
    });

    testWidgets('countdown timer decrements over time', (tester) async {
      final updateInfo = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '0.9.0',
        url: 'https://example.com/update',
      );

      await tester.pumpWidget(buildUpdateDialog(
        initState: AppInitializationState(updateInfo: updateInfo),
      ));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // The SmoothCircularCountdown starts with remainingSeconds=5
      expect(find.text('5'), findsOneWidget);

      // Advance 1 second for the OverlayNotification countdown
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('4'), findsOneWidget);

      // Drain remaining timers (4 more seconds + animation)
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    });
  });
}
