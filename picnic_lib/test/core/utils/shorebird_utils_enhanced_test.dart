import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

void main() {
  group('PatchStatusCheckResult - additional coverage', () {
    test('status field is accessible', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
      );
      expect(result.status, equals(shorebird.UpdateStatus.upToDate));
    });

    test('all UpdateStatus values work', () {
      for (final status in shorebird.UpdateStatus.values) {
        final result = PatchStatusCheckResult(status: status);
        expect(result.status, status);
      }
    });

    test('currentPatchNumber and nextPatchNumber with zero', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.outdated,
        currentPatchNumber: 0,
        nextPatchNumber: 0,
      );
      expect(result.currentPatchNumber, 0);
      expect(result.nextPatchNumber, 0);
    });

    test('currentPatchNumber with large number', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.upToDate,
        currentPatchNumber: 999999,
      );
      expect(result.currentPatchNumber, 999999);
    });

    test('nextPatchNumber larger than currentPatchNumber', () {
      const result = PatchStatusCheckResult(
        status: shorebird.UpdateStatus.restartRequired,
        currentPatchNumber: 5,
        nextPatchNumber: 10,
      );
      expect(result.nextPatchNumber! > result.currentPatchNumber!, isTrue);
    });
  });

  group('PatchStatusException - additional coverage', () {
    test('toString without message', () {
      const exception =
          PatchStatusException(PatchStatusError.webUnsupported);
      final str = exception.toString();
      expect(str, contains('PatchStatusException'));
      expect(str, contains('webUnsupported'));
      expect(str, contains('null'));
    });

    test('toString with empty message', () {
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: '',
      );
      final str = exception.toString();
      expect(str, contains('PatchStatusException'));
      expect(str, contains('generic'));
    });

    test('toString with long message', () {
      const longMsg = 'A very long error message that describes the issue in detail';
      const exception = PatchStatusException(
        PatchStatusError.generic,
        message: longMsg,
      );
      expect(exception.toString(), contains(longMsg));
    });

    test('can be caught as Exception', () {
      try {
        throw const PatchStatusException(PatchStatusError.webUnsupported);
      } on Exception catch (e) {
        expect(e, isA<PatchStatusException>());
      }
    });

    test('webUnsupported and generic are distinct', () {
      const e1 = PatchStatusException(PatchStatusError.webUnsupported);
      const e2 = PatchStatusException(PatchStatusError.generic);
      expect(e1.code, isNot(e2.code));
    });
  });

  group('ShorebirdPatchEvent - additional coverage', () {
    test('enum values have correct indices', () {
      expect(ShorebirdPatchEvent.checking.index, 0);
      expect(ShorebirdPatchEvent.downloading.index, 1);
      expect(ShorebirdPatchEvent.downloadCompleted.index, 2);
      expect(ShorebirdPatchEvent.restartPending.index, 3);
      expect(ShorebirdPatchEvent.upToDate.index, 4);
      expect(ShorebirdPatchEvent.error.index, 5);
    });

    test('enum name property', () {
      expect(ShorebirdPatchEvent.checking.name, 'checking');
      expect(ShorebirdPatchEvent.downloading.name, 'downloading');
      expect(ShorebirdPatchEvent.downloadCompleted.name, 'downloadCompleted');
      expect(ShorebirdPatchEvent.restartPending.name, 'restartPending');
      expect(ShorebirdPatchEvent.upToDate.name, 'upToDate');
      expect(ShorebirdPatchEvent.error.name, 'error');
    });
  });

  group('ShorebirdUtils callback tests', () {
    test('setOnPatchStatusChanged with callback and then null', () {
      final events = <ShorebirdPatchEvent>[];
      ShorebirdUtils.setOnPatchStatusChanged((event) => events.add(event));
      // Clean up
      ShorebirdUtils.setOnPatchStatusChanged(null);
      expect(events, isEmpty);
    });

    test('setDownloadCompleteMessage with unicode', () {
      ShorebirdUtils.setDownloadCompleteMessage('업데이트 준비 완료! 🎉');
      // No error expected
    });

    test('setPendingPatch multiple toggles', () {
      ShorebirdUtils.setPendingPatch(true);
      expect(ShorebirdUtils.hasPendingPatch, isTrue);
      ShorebirdUtils.setPendingPatch(true);
      expect(ShorebirdUtils.hasPendingPatch, isTrue);
      ShorebirdUtils.setPendingPatch(false);
      expect(ShorebirdUtils.hasPendingPatch, isFalse);
      ShorebirdUtils.setPendingPatch(false);
      expect(ShorebirdUtils.hasPendingPatch, isFalse);
    });

    test('showRestartNotification with unicode content', () async {
      await ShorebirdUtils.showRestartNotification(
        title: '업데이트',
        body: '앱을 재시작해 주세요',
      );
    });

    test('showRestartNotification with very long strings', () async {
      await ShorebirdUtils.showRestartNotification(
        title: 'A' * 1000,
        body: 'B' * 5000,
      );
    });

    test('isPatchingAvailable returns bool', () async {
      final result = await ShorebirdUtils.isPatchingAvailable();
      expect(result, isA<bool>());
    });
  });

  group('PatchStatusError', () {
    test('values contain expected entries', () {
      expect(PatchStatusError.values, hasLength(2));
      expect(PatchStatusError.webUnsupported.index, 0);
      expect(PatchStatusError.generic.index, 1);
    });

    test('name property', () {
      expect(PatchStatusError.webUnsupported.name, 'webUnsupported');
      expect(PatchStatusError.generic.name, 'generic');
    });
  });
}
