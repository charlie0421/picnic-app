import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

void main() {
  group('ShorebirdPatchEvent', () {
    test('has all expected values', () {
      expect(ShorebirdPatchEvent.values.length, 6);
      expect(ShorebirdPatchEvent.values, contains(ShorebirdPatchEvent.checking));
      expect(
          ShorebirdPatchEvent.values, contains(ShorebirdPatchEvent.downloading));
      expect(ShorebirdPatchEvent.values,
          contains(ShorebirdPatchEvent.downloadCompleted));
      expect(ShorebirdPatchEvent.values,
          contains(ShorebirdPatchEvent.restartPending));
      expect(
          ShorebirdPatchEvent.values, contains(ShorebirdPatchEvent.upToDate));
      expect(ShorebirdPatchEvent.values, contains(ShorebirdPatchEvent.error));
    });
  });

  group('PatchStatusError', () {
    test('has expected values', () {
      expect(PatchStatusError.values.length, 2);
      expect(PatchStatusError.values, contains(PatchStatusError.webUnsupported));
      expect(PatchStatusError.values, contains(PatchStatusError.generic));
    });
  });

  group('PatchStatusException', () {
    test('creates with code only', () {
      const exception =
          PatchStatusException(PatchStatusError.webUnsupported);
      expect(exception.code, PatchStatusError.webUnsupported);
      expect(exception.message, isNull);
    });

    test('creates with code and message', () {
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: 'Something went wrong',
      );
      expect(exception.code, PatchStatusError.generic);
      expect(exception.message, 'Something went wrong');
    });

    test('toString includes code and message', () {
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: 'test error',
      );
      final str = exception.toString();
      expect(str, contains('PatchStatusException'));
      expect(str, contains('generic'));
      expect(str, contains('test error'));
    });

    test('implements Exception', () {
      const exception =
          PatchStatusException(PatchStatusError.webUnsupported);
      expect(exception, isA<Exception>());
    });
  });

  group('ShorebirdUtils static methods', () {
    test('setOnPatchStatusChanged accepts callback', () {
      ShorebirdPatchEvent? received;
      ShorebirdUtils.setOnPatchStatusChanged((event) => received = event);
      // Clean up
      ShorebirdUtils.setOnPatchStatusChanged(null);
      expect(received, isNull);
    });

    test('setDownloadCompleteMessage accepts string', () {
      ShorebirdUtils.setDownloadCompleteMessage('Update ready!');
    });

    test('setDownloadCompleteMessage accepts empty string', () {
      ShorebirdUtils.setDownloadCompleteMessage('');
    });

    test('isPatchingAvailable returns true on non-web platform', () async {
      final available = await ShorebirdUtils.isPatchingAvailable();
      expect(available, isTrue);
    });

    test('setOnPatchStatusChanged receives events', () {
      ShorebirdPatchEvent? received;
      ShorebirdUtils.setOnPatchStatusChanged((event) => received = event);
      ShorebirdUtils.setOnPatchStatusChanged(null);
      expect(received, isNull);
    });
  });

  group('PatchStatusCheckResult', () {
    test('creates with required status only', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
      );
      expect(result.status, shorebird.UpdateStatus.upToDate);
      expect(result.currentPatchNumber, isNull);
      expect(result.nextPatchNumber, isNull);
    });

    test('creates with all fields', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.outdated,
        currentPatchNumber: 5,
        nextPatchNumber: 6,
      );
      expect(result.status, shorebird.UpdateStatus.outdated);
      expect(result.currentPatchNumber, 5);
      expect(result.nextPatchNumber, 6);
    });

    test('creates with restartRequired status', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.restartRequired,
        currentPatchNumber: 3,
        nextPatchNumber: 4,
      );
      expect(result.status, shorebird.UpdateStatus.restartRequired);
    });

    test('creates with unavailable status', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.unavailable,
      );
      expect(result.status, shorebird.UpdateStatus.unavailable);
    });

    test('creates with only currentPatchNumber', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
        currentPatchNumber: 10,
      );
      expect(result.currentPatchNumber, 10);
      expect(result.nextPatchNumber, isNull);
    });

    test('creates with only nextPatchNumber', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.restartRequired,
        nextPatchNumber: 7,
      );
      expect(result.currentPatchNumber, isNull);
      expect(result.nextPatchNumber, 7);
    });
  });
}
