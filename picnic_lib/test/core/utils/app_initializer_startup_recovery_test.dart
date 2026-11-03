import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  const forced = UpdateInfo(
    status: UpdateStatus.updateRequired,
    currentVersion: '1.0.0',
    latestVersion: '2.0.0',
    forceVersion: '1.5.0',
  );
  const current = UpdateInfo(
    status: UpdateStatus.upToDate,
    currentVersion: '2.0.0',
    latestVersion: '2.0.0',
    forceVersion: '1.5.0',
  );

  Future<(ProviderContainer, WidgetRef)> mountRef(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, widgetRef, child) {
              ref = widgetRef;
              widgetRef.watch(appInitializationProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return (container, ref);
  }

  testWidgets(
    'online retry publishes network, force-update and ban only after both checks',
    (tester) async {
      final (container, ref) = await mountRef(tester);
      container
          .read(appInitializationProvider.notifier)
          .updateState(hasNetwork: false, updateInfo: current);
      final network = Completer<bool>();
      final update = Completer<UpdateInfo>();
      final ban = Completer<bool>();
      final checks = StartupConnectionChecks<UpdateInfo>();
      final requiredChecksStarted = Completer<void>();
      var networkCalls = 0;
      var updateCalls = 0;
      var banCalls = 0;

      final operations = StartupCheckOperations(
        checkNetwork: () {
          networkCalls++;
          return network.future;
        },
        checkUpdate: ({required forceRefresh}) {
          expect(forceRefresh, isTrue);
          updateCalls++;
          if (banCalls == 1 && !requiredChecksStarted.isCompleted) {
            requiredChecksStarted.complete();
          }
          return update.future;
        },
        checkBan: () {
          banCalls++;
          if (updateCalls == 1 && !requiredChecksStarted.isCompleted) {
            requiredChecksStarted.complete();
          }
          return ban.future;
        },
      );

      final first = AppInitializer.retryConnection(
        ref,
        connectionChecks: checks,
        operations: operations,
      );
      final duplicate = AppInitializer.retryConnection(
        ref,
        connectionChecks: checks,
        operations: operations,
      );
      await tester.pump();

      expect(networkCalls, 1);
      expect(updateCalls, 0);
      expect(banCalls, 0);
      expect(container.read(appInitializationProvider).hasNetwork, isFalse);

      network.complete(true);
      await requiredChecksStarted.future;
      expect(updateCalls, 1);
      expect(banCalls, 1);
      expect(container.read(appInitializationProvider).hasNetwork, isFalse);
      expect(
        container.read(appInitializationProvider).updateInfo,
        same(current),
      );

      update.complete(forced);
      await tester.pump();
      expect(container.read(appInitializationProvider).hasNetwork, isFalse);

      ban.complete(true);
      await tester.pump();
      await first;
      await duplicate;

      final state = container.read(appInitializationProvider);
      expect(state.hasNetwork, isTrue);
      expect(state.updateInfo, same(forced));
      expect(state.isBanned, isTrue);
    },
  );

  testWidgets('failed fresh provider read is retried and stale force clears', (
    tester,
  ) async {
    final (container, ref) = await mountRef(tester);
    container
        .read(appInitializationProvider.notifier)
        .updateState(hasNetwork: false, updateInfo: forced);
    final checks = StartupConnectionChecks<UpdateInfo>();
    var updateCalls = 0;

    final operations = StartupCheckOperations(
      checkNetwork: () async => true,
      checkUpdate: ({required forceRefresh}) async {
        expect(forceRefresh, isTrue);
        updateCalls++;
        if (updateCalls == 1) throw StateError('fresh read failed');
        return current;
      },
      checkBan: () async => false,
    );

    await expectLater(
      AppInitializer.retryConnection(
        ref,
        connectionChecks: checks,
        operations: operations,
      ),
      throwsA(isA<StateError>()),
    );
    expect(container.read(appInitializationProvider).hasNetwork, isFalse);
    expect(container.read(appInitializationProvider).updateInfo, same(forced));

    await AppInitializer.retryConnection(
      ref,
      connectionChecks: checks,
      operations: operations,
    );

    final recovered = container.read(appInitializationProvider);
    expect(updateCalls, 2);
    expect(recovered.hasNetwork, isTrue);
    expect(recovered.updateInfo, same(current));
    expect(recovered.isBanned, isFalse);
  });
}
