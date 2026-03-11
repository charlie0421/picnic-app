import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  group('AppInitializationState', () {
    test('default values', () {
      const state = AppInitializationState();
      expect(state.hasNetwork, isTrue);
      expect(state.isBanned, isFalse);
      expect(state.isInitialized, isFalse);
      expect(state.isUpdateRequired, isFalse);
      expect(state.updateInfo, isNull);
    });

    test('creates with custom values', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      const state = AppInitializationState(
        hasNetwork: false,
        isBanned: true,
        isInitialized: true,
        isUpdateRequired: true,
        updateInfo: info,
      );
      expect(state.hasNetwork, isFalse);
      expect(state.isBanned, isTrue);
      expect(state.isInitialized, isTrue);
      expect(state.isUpdateRequired, isTrue);
      expect(state.updateInfo, isNotNull);
    });

    test('copyWith updates single field', () {
      const state = AppInitializationState();
      final updated = state.copyWith(hasNetwork: false);
      expect(updated.hasNetwork, isFalse);
      expect(updated.isBanned, isFalse);
      expect(updated.isInitialized, isFalse);
    });

    test('copyWith updates multiple fields', () {
      const state = AppInitializationState();
      final updated = state.copyWith(
        isBanned: true,
        isInitialized: true,
      );
      expect(updated.isBanned, isTrue);
      expect(updated.isInitialized, isTrue);
      expect(updated.hasNetwork, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const state = AppInitializationState(
        hasNetwork: false,
        isBanned: true,
      );
      final updated = state.copyWith(isInitialized: true);
      expect(updated.hasNetwork, isFalse);
      expect(updated.isBanned, isTrue);
      expect(updated.isInitialized, isTrue);
    });

    test('copyWith with updateInfo', () {
      const state = AppInitializationState();
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      final updated = state.copyWith(updateInfo: info);
      expect(updated.updateInfo?.status, UpdateStatus.updateRequired);
      expect(updated.updateInfo?.latestVersion, '2.0.0');
    });
  });

  group('AppInitialization notifier', () {
    test('initial state is default AppInitializationState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(appInitializationProvider);
      expect(state.hasNetwork, isTrue);
      expect(state.isBanned, isFalse);
      expect(state.isInitialized, isFalse);
    });

    test('updateState updates single field', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(appInitializationProvider.notifier)
          .updateState(hasNetwork: false);
      final state = container.read(appInitializationProvider);
      expect(state.hasNetwork, isFalse);
      expect(state.isBanned, isFalse);
    });

    test('updateState updates multiple fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(appInitializationProvider.notifier)
          .updateState(isBanned: true, isInitialized: true);
      final state = container.read(appInitializationProvider);
      expect(state.isBanned, isTrue);
      expect(state.isInitialized, isTrue);
      expect(state.hasNetwork, isTrue);
    });

    test('updateState preserves unmentioned fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(appInitializationProvider.notifier)
          .updateState(hasNetwork: false);
      container
          .read(appInitializationProvider.notifier)
          .updateState(isBanned: true);
      final state = container.read(appInitializationProvider);
      expect(state.hasNetwork, isFalse);
      expect(state.isBanned, isTrue);
    });

    test('updateState with updateInfo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const info = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '1.5.0',
        forceVersion: '0.9.0',
      );
      container
          .read(appInitializationProvider.notifier)
          .updateState(updateInfo: info, isUpdateRequired: true);
      final state = container.read(appInitializationProvider);
      expect(state.isUpdateRequired, isTrue);
      expect(state.updateInfo?.status, UpdateStatus.updateRecommended);
    });
  });
}
