import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

void main() {
  group('ShorebirdPatchEvent', () {
    test('has all expected values', () {
      expect(ShorebirdPatchEvent.values.length, 6);
      expect(ShorebirdPatchEvent.checking, isNotNull);
      expect(ShorebirdPatchEvent.downloading, isNotNull);
      expect(ShorebirdPatchEvent.downloadCompleted, isNotNull);
      expect(ShorebirdPatchEvent.restartPending, isNotNull);
      expect(ShorebirdPatchEvent.upToDate, isNotNull);
      expect(ShorebirdPatchEvent.error, isNotNull);
    });

    test('each value has correct name', () {
      expect(ShorebirdPatchEvent.checking.name, 'checking');
      expect(ShorebirdPatchEvent.downloading.name, 'downloading');
      expect(ShorebirdPatchEvent.downloadCompleted.name, 'downloadCompleted');
      expect(ShorebirdPatchEvent.restartPending.name, 'restartPending');
      expect(ShorebirdPatchEvent.upToDate.name, 'upToDate');
      expect(ShorebirdPatchEvent.error.name, 'error');
    });
  });

  group('PatchStatusError', () {
    test('has expected values', () {
      expect(PatchStatusError.values.length, 2);
      expect(PatchStatusError.webUnsupported, isNotNull);
      expect(PatchStatusError.generic, isNotNull);
    });

    test('has correct names', () {
      expect(PatchStatusError.webUnsupported.name, 'webUnsupported');
      expect(PatchStatusError.generic.name, 'generic');
    });
  });

  group('PatchStatusException', () {
    test('creates with code and message', () {
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: 'test error',
      );
      expect(exception.code, PatchStatusError.generic);
      expect(exception.message, 'test error');
    });

    test('creates with code only', () {
      const exception = PatchStatusException(PatchStatusError.webUnsupported);
      expect(exception.code, PatchStatusError.webUnsupported);
      expect(exception.message, isNull);
    });

    test('toString includes code and message', () {
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: 'some error',
      );
      final str = exception.toString();
      expect(str, contains('PatchStatusException'));
      expect(str, contains('generic'));
      expect(str, contains('some error'));
    });

    test('toString with null message', () {
      const exception = PatchStatusException(PatchStatusError.webUnsupported);
      final str = exception.toString();
      expect(str, contains('webUnsupported'));
      expect(str, contains('null'));
    });

    test('implements Exception', () {
      const exception = PatchStatusException(PatchStatusError.generic);
      expect(exception, isA<Exception>());
    });
  });

  group('ShorebirdUtils static methods', () {
    test('setOnPatchStatusChanged accepts callback', () {
      bool called = false;
      ShorebirdUtils.setOnPatchStatusChanged((event) {
        called = true;
      });
      // Cleanup
      ShorebirdUtils.setOnPatchStatusChanged(null);
      expect(called, isFalse);
    });

    test('setOnPatchStatusChanged accepts null', () {
      ShorebirdUtils.setOnPatchStatusChanged(null);
      // Should not throw
    });

    test('hasPendingPatch defaults correctly after reset', () {
      ShorebirdUtils.setPendingPatch(false);
      expect(ShorebirdUtils.hasPendingPatch, isFalse);
    });

    test('setPendingPatch changes hasPendingPatch to true', () {
      ShorebirdUtils.setPendingPatch(true);
      expect(ShorebirdUtils.hasPendingPatch, isTrue);
      // Reset
      ShorebirdUtils.setPendingPatch(false);
    });

    test('setPendingPatch changes hasPendingPatch to false', () {
      ShorebirdUtils.setPendingPatch(true);
      ShorebirdUtils.setPendingPatch(false);
      expect(ShorebirdUtils.hasPendingPatch, isFalse);
    });

    test('setDownloadCompleteMessage accepts string', () {
      ShorebirdUtils.setDownloadCompleteMessage('Update complete');
      // Should not throw
    });

    test('showRestartNotification completes without error', () async {
      await ShorebirdUtils.showRestartNotification(
        title: 'Test',
        body: 'Test body',
      );
      // Should complete without throwing (function is a no-op)
    });
  });

  group('PatchStatusCheckResult', () {
    test('creates with all fields', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
        currentPatchNumber: 5,
        nextPatchNumber: 6,
      );
      expect(result.status, shorebird.UpdateStatus.upToDate);
      expect(result.currentPatchNumber, 5);
      expect(result.nextPatchNumber, 6);
    });

    test('creates with null optional fields', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
      );
      expect(result.status, shorebird.UpdateStatus.upToDate);
      expect(result.currentPatchNumber, isNull);
      expect(result.nextPatchNumber, isNull);
    });

    test('different status values', () {
      const outdated = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.outdated,
        currentPatchNumber: 1,
      );
      expect(outdated.status, shorebird.UpdateStatus.outdated);
      expect(outdated.currentPatchNumber, 1);

      const restartRequired = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.restartRequired,
        nextPatchNumber: 2,
      );
      expect(restartRequired.status, shorebird.UpdateStatus.restartRequired);
      expect(restartRequired.nextPatchNumber, 2);
    });
  });

  group('PatchStatusCallback typedef', () {
    test('callback type works correctly', () {
      ShorebirdPatchEvent? receivedEvent;
      final PatchStatusCallback callback = (event) {
        receivedEvent = event;
      };

      callback(ShorebirdPatchEvent.checking);
      expect(receivedEvent, ShorebirdPatchEvent.checking);

      callback(ShorebirdPatchEvent.error);
      expect(receivedEvent, ShorebirdPatchEvent.error);
    });
  });
}
