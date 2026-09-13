import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

const _recommended = UpdateInfo(
  status: UpdateStatus.updateRecommended,
  currentVersion: '1.0.0',
  latestVersion: '2.0.0',
  forceVersion: '0.9.0',
  url: 'https://example.com/update',
);

void main() {
  setUp(initTestColors);

  Future<ProviderContainer> pumpDialog(
    WidgetTester tester, {
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      buildTestApp(UpdateDialog(enabled: enabled, child: const Text('portal'))),
    );
    return ProviderScope.containerOf(tester.element(find.byType(UpdateDialog)));
  }

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('late recommended result is shown once after three seconds', (
    tester,
  ) async {
    final container = await pumpDialog(tester);
    await tester.pump(const Duration(seconds: 3));
    container
        .read(appInitializationProvider.notifier)
        .updateState(
          isInitialized: true,
          hasNetwork: true,
          isBanned: false,
          updateInfo: _recommended,
        );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('2.0.0'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('does not consume a recommendation until Portal is ready', (
    tester,
  ) async {
    final container = await pumpDialog(tester, enabled: false);
    container
        .read(appInitializationProvider.notifier)
        .updateState(isInitialized: true, updateInfo: _recommended);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsNothing);

    await tester.pumpWidget(
      buildTestApp(const UpdateDialog(enabled: true, child: Text('portal'))),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('offline recommendation waits for healthy recovery', (
    tester,
  ) async {
    final container = await pumpDialog(tester);
    container
        .read(appInitializationProvider.notifier)
        .updateState(
          isInitialized: true,
          hasNetwork: false,
          updateInfo: _recommended,
        );
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsNothing);

    container
        .read(appInitializationProvider.notifier)
        .updateState(hasNetwork: true);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('force update supersedes a queued recommendation', (
    tester,
  ) async {
    final container = await pumpDialog(tester, enabled: false);
    container
        .read(appInitializationProvider.notifier)
        .updateState(isInitialized: true, updateInfo: _recommended);
    await tester.pump();
    container
        .read(appInitializationProvider.notifier)
        .updateState(
          updateInfo: const UpdateInfo(
            status: UpdateStatus.updateRequired,
            currentVersion: '1.0.0',
            latestVersion: '2.0.0',
            forceVersion: '1.5.0',
          ),
        );
    await tester.pumpWidget(
      buildTestApp(const UpdateDialog(enabled: true, child: Text('portal'))),
    );
    await tester.pump();

    expect(find.textContaining('2.0.0'), findsNothing);
  });

  testWidgets('deduplicates the same version pair but shows a newer pair', (
    tester,
  ) async {
    final container = await pumpDialog(tester);
    final notifier = container.read(appInitializationProvider.notifier);
    notifier.updateState(isInitialized: true, updateInfo: _recommended);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsOneWidget);
    await drain(tester);

    notifier.updateState(updateInfo: _recommended);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('2.0.0'), findsNothing);

    notifier.updateState(
      updateInfo: const UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '3.0.0',
        forceVersion: '0.9.0',
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('3.0.0'), findsOneWidget);
    await drain(tester);
  });
}
