import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/patch_status_provider.dart';

void main() {
  group('PatchStatus', () {
    test('has all expected values', () {
      expect(PatchStatus.values.length, 5);
      expect(PatchStatus.values, contains(PatchStatus.checking));
      expect(PatchStatus.values, contains(PatchStatus.upToDate));
      expect(PatchStatus.values, contains(PatchStatus.downloading));
      expect(PatchStatus.values, contains(PatchStatus.restartRequired));
      expect(PatchStatus.values, contains(PatchStatus.error));
    });
  });

  group('PatchStatusInfo', () {
    test('default values', () {
      const info = PatchStatusInfo(status: PatchStatus.upToDate);
      expect(info.status, PatchStatus.upToDate);
      expect(info.currentPatchNumber, isNull);
      expect(info.nextPatchNumber, isNull);
      expect(info.errorMessage, isNull);
      expect(info.dialogShown, isFalse);
    });

    test('creates with all fields', () {
      const info = PatchStatusInfo(
        status: PatchStatus.restartRequired,
        currentPatchNumber: 5,
        nextPatchNumber: 6,
        errorMessage: null,
        dialogShown: true,
      );
      expect(info.status, PatchStatus.restartRequired);
      expect(info.currentPatchNumber, 5);
      expect(info.nextPatchNumber, 6);
      expect(info.dialogShown, isTrue);
    });

    test('copyWith updates status', () {
      const info = PatchStatusInfo(status: PatchStatus.upToDate);
      final updated = info.copyWith(status: PatchStatus.downloading);
      expect(updated.status, PatchStatus.downloading);
    });

    test('copyWith preserves unchanged fields', () {
      const info = PatchStatusInfo(
        status: PatchStatus.restartRequired,
        currentPatchNumber: 5,
        dialogShown: true,
      );
      final updated = info.copyWith(nextPatchNumber: 6);
      expect(updated.status, PatchStatus.restartRequired);
      expect(updated.currentPatchNumber, 5);
      expect(updated.nextPatchNumber, 6);
      expect(updated.dialogShown, isTrue);
    });

    group('needsRestart', () {
      test('true when restartRequired', () {
        const info = PatchStatusInfo(status: PatchStatus.restartRequired);
        expect(info.needsRestart, isTrue);
      });

      test('false for other statuses', () {
        for (final status in [
          PatchStatus.checking,
          PatchStatus.upToDate,
          PatchStatus.downloading,
          PatchStatus.error,
        ]) {
          final info = PatchStatusInfo(status: status);
          expect(info.needsRestart, isFalse);
        }
      });
    });

    group('shouldShowDialog', () {
      test('true when restart required and dialog not shown', () {
        const info = PatchStatusInfo(
          status: PatchStatus.restartRequired,
          dialogShown: false,
        );
        expect(info.shouldShowDialog, isTrue);
      });

      test('false when dialog already shown', () {
        const info = PatchStatusInfo(
          status: PatchStatus.restartRequired,
          dialogShown: true,
        );
        expect(info.shouldShowDialog, isFalse);
      });

      test('false when not restart required', () {
        const info = PatchStatusInfo(
          status: PatchStatus.upToDate,
          dialogShown: false,
        );
        expect(info.shouldShowDialog, isFalse);
      });
    });
  });

  group('PatchStatusNotifier', () {
    test('initial state is upToDate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final info = container.read(patchStatusProvider);
      expect(info.status, PatchStatus.upToDate);
    });

    test('setUpToDate resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(patchStatusProvider.notifier)
          .setUpToDate(currentPatchNumber: 3);
      final info = container.read(patchStatusProvider);
      expect(info.status, PatchStatus.upToDate);
      expect(info.currentPatchNumber, 3);
    });

    test('setDownloading changes status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(patchStatusProvider.notifier).setDownloading();
      final info = container.read(patchStatusProvider);
      expect(info.status, PatchStatus.downloading);
    });

    test('setRestartRequired changes status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(patchStatusProvider.notifier)
          .setRestartRequired(nextPatchNumber: 7);
      final info = container.read(patchStatusProvider);
      expect(info.status, PatchStatus.restartRequired);
      expect(info.nextPatchNumber, 7);
    });

    test('setError stores message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(patchStatusProvider.notifier)
          .setError('Network error');
      final info = container.read(patchStatusProvider);
      expect(info.status, PatchStatus.error);
      expect(info.errorMessage, 'Network error');
    });

    test('markDialogShown sets dialogShown to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(patchStatusProvider.notifier)
          .setRestartRequired();
      container
          .read(patchStatusProvider.notifier)
          .markDialogShown();
      final info = container.read(patchStatusProvider);
      expect(info.dialogShown, isTrue);
      expect(info.shouldShowDialog, isFalse);
    });

    test('setUpToDate after setRestartRequired preserves patch number flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(patchStatusProvider.notifier)
          .setUpToDate(currentPatchNumber: 5);
      container
          .read(patchStatusProvider.notifier)
          .setRestartRequired(nextPatchNumber: 6);
      final info = container.read(patchStatusProvider);
      expect(info.currentPatchNumber, 5);
      expect(info.nextPatchNumber, 6);
    });
  });
}
