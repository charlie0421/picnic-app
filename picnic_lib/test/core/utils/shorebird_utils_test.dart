import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';

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
    test('hasPendingPatch defaults to false', () {
      // Reset state
      ShorebirdUtils.setPendingPatch(false);
      expect(ShorebirdUtils.hasPendingPatch, isFalse);
    });

    test('setPendingPatch updates state', () {
      ShorebirdUtils.setPendingPatch(true);
      expect(ShorebirdUtils.hasPendingPatch, isTrue);
      // Reset
      ShorebirdUtils.setPendingPatch(false);
    });

    test('setOnPatchStatusChanged accepts callback', () {
      ShorebirdPatchEvent? received;
      ShorebirdUtils.setOnPatchStatusChanged((event) => received = event);
      // Clean up
      ShorebirdUtils.setOnPatchStatusChanged(null);
      expect(received, isNull);
    });

    test('setDownloadCompleteMessage accepts string', () {
      // Just verify it doesn't throw
      ShorebirdUtils.setDownloadCompleteMessage('Update ready!');
    });

    test('showRestartNotification completes without error', () async {
      // This method is a no-op (notification disabled)
      await ShorebirdUtils.showRestartNotification(
        title: 'Test',
        body: 'Test body',
      );
    });
  });
}
