import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';

void main() {
  group('PatchInfo', () {
    test('default values', () {
      const info = PatchInfo();
      expect(info.hasUpdate, isFalse);
      expect(info.updateDownloaded, isFalse);
      expect(info.needsRestart, isFalse);
      expect(info.currentPatch, isNull);
      expect(info.newPatch, isNull);
      expect(info.statusMessage, 'No updates available');
      expect(info.lastChecked, isNull);
    });

    test('copyWith updates fields', () {
      const info = PatchInfo();
      final now = DateTime.now();
      final updated = info.copyWith(
        hasUpdate: true,
        currentPatch: 5,
        newPatch: 6,
        statusMessage: 'Update found',
        lastChecked: now,
      );
      expect(updated.hasUpdate, isTrue);
      expect(updated.updateDownloaded, isFalse);
      expect(updated.currentPatch, 5);
      expect(updated.newPatch, 6);
      expect(updated.statusMessage, 'Update found');
      expect(updated.lastChecked, now);
    });

    test('copyWith preserves unchanged fields', () {
      final info = PatchInfo(hasUpdate: true, currentPatch: 3);
      final updated = info.copyWith(statusMessage: 'test');
      expect(updated.hasUpdate, isTrue);
      expect(updated.currentPatch, 3);
      expect(updated.statusMessage, 'test');
    });

    group('displayInfo', () {
      test('returns restart message when needsRestart', () {
        const info = PatchInfo(needsRestart: true);
        expect(info.displayInfo, 'Update ready (restart required)');
      });

      test('returns downloaded message when updateDownloaded', () {
        const info = PatchInfo(updateDownloaded: true);
        expect(info.displayInfo, 'Update downloaded');
      });

      test('returns available message when hasUpdate', () {
        const info = PatchInfo(hasUpdate: true);
        expect(info.displayInfo, 'Update available');
      });

      test('returns current patch when patch exists', () {
        const info = PatchInfo(currentPatch: 42);
        expect(info.displayInfo, 'Current patch: 42');
      });

      test('returns no patch message when no state', () {
        const info = PatchInfo();
        expect(info.displayInfo, 'No patch applied');
      });

      test('priority: needsRestart > updateDownloaded', () {
        const info = PatchInfo(needsRestart: true, updateDownloaded: true);
        expect(info.displayInfo, 'Update ready (restart required)');
      });

      test('priority: updateDownloaded > hasUpdate', () {
        const info = PatchInfo(updateDownloaded: true, hasUpdate: true);
        expect(info.displayInfo, 'Update downloaded');
      });

      test('priority: hasUpdate > currentPatch', () {
        const info = PatchInfo(hasUpdate: true, currentPatch: 5);
        expect(info.displayInfo, 'Update available');
      });
    });

    group('canRestart', () {
      test('true when needsRestart', () {
        const info = PatchInfo(needsRestart: true);
        expect(info.canRestart, isTrue);
      });

      test('false when not needsRestart', () {
        const info = PatchInfo();
        expect(info.canRestart, isFalse);
      });
    });
  });

  group('PatchInfoNotifier', () {
    test('initial state is default PatchInfo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final info = container.read(patchInfoProvider);
      expect(info.hasUpdate, isFalse);
      expect(info.statusMessage, 'No updates available');
    });

    test('updatePatchInfo updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(patchInfoProvider.notifier).updatePatchInfo({
        'hasUpdate': true,
        'currentPatch': 10,
        'statusMessage': 'New patch',
      });
      final info = container.read(patchInfoProvider);
      expect(info.hasUpdate, isTrue);
      expect(info.currentPatch, 10);
      expect(info.statusMessage, 'New patch');
      expect(info.lastChecked, isNotNull);
    });

    test('updatePatchInfo preserves unmentioned fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(patchInfoProvider.notifier).updatePatchInfo({
        'hasUpdate': true,
      });
      container.read(patchInfoProvider.notifier).updatePatchInfo({
        'updateDownloaded': true,
      });
      final info = container.read(patchInfoProvider);
      expect(info.hasUpdate, isTrue);
      expect(info.updateDownloaded, isTrue);
    });

    test('reset returns to default state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(patchInfoProvider.notifier).updatePatchInfo({
        'hasUpdate': true,
        'currentPatch': 5,
      });
      container.read(patchInfoProvider.notifier).reset();
      final info = container.read(patchInfoProvider);
      expect(info.hasUpdate, isFalse);
      expect(info.currentPatch, isNull);
      expect(info.statusMessage, 'No updates available');
    });
  });
}
