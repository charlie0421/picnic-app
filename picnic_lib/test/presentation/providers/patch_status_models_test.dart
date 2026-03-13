import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/patch_status_provider.dart';

void main() {
  group('PatchStatus', () {
    test('has all expected values', () {
      expect(PatchStatus.values.length, equals(5));
      expect(PatchStatus.values, contains(PatchStatus.checking));
      expect(PatchStatus.values, contains(PatchStatus.upToDate));
      expect(PatchStatus.values, contains(PatchStatus.downloading));
      expect(PatchStatus.values, contains(PatchStatus.restartRequired));
      expect(PatchStatus.values, contains(PatchStatus.error));
    });
  });

  group('PatchStatusInfo', () {
    test('constructor stores all fields', () {
      const info = PatchStatusInfo(
        status: PatchStatus.upToDate,
        currentPatchNumber: 5,
        nextPatchNumber: 6,
        errorMessage: null,
        dialogShown: false,
      );
      expect(info.status, equals(PatchStatus.upToDate));
      expect(info.currentPatchNumber, equals(5));
      expect(info.nextPatchNumber, equals(6));
      expect(info.errorMessage, isNull);
      expect(info.dialogShown, isFalse);
    });

    test('dialogShown defaults to false', () {
      const info = PatchStatusInfo(status: PatchStatus.checking);
      expect(info.dialogShown, isFalse);
    });

    test('optional fields default to null', () {
      const info = PatchStatusInfo(status: PatchStatus.upToDate);
      expect(info.currentPatchNumber, isNull);
      expect(info.nextPatchNumber, isNull);
      expect(info.errorMessage, isNull);
    });

    group('needsRestart', () {
      test('returns true when status is restartRequired', () {
        const info = PatchStatusInfo(status: PatchStatus.restartRequired);
        expect(info.needsRestart, isTrue);
      });

      test('returns false when status is upToDate', () {
        const info = PatchStatusInfo(status: PatchStatus.upToDate);
        expect(info.needsRestart, isFalse);
      });

      test('returns false when status is checking', () {
        const info = PatchStatusInfo(status: PatchStatus.checking);
        expect(info.needsRestart, isFalse);
      });

      test('returns false when status is downloading', () {
        const info = PatchStatusInfo(status: PatchStatus.downloading);
        expect(info.needsRestart, isFalse);
      });

      test('returns false when status is error', () {
        const info = PatchStatusInfo(status: PatchStatus.error);
        expect(info.needsRestart, isFalse);
      });
    });

    group('shouldShowDialog', () {
      test('returns true when restart required and dialog not shown', () {
        const info = PatchStatusInfo(
          status: PatchStatus.restartRequired,
          dialogShown: false,
        );
        expect(info.shouldShowDialog, isTrue);
      });

      test('returns false when restart required but dialog already shown', () {
        const info = PatchStatusInfo(
          status: PatchStatus.restartRequired,
          dialogShown: true,
        );
        expect(info.shouldShowDialog, isFalse);
      });

      test('returns false when upToDate', () {
        const info = PatchStatusInfo(
          status: PatchStatus.upToDate,
          dialogShown: false,
        );
        expect(info.shouldShowDialog, isFalse);
      });
    });

    group('copyWith', () {
      const original = PatchStatusInfo(
        status: PatchStatus.downloading,
        currentPatchNumber: 3,
        nextPatchNumber: 4,
        errorMessage: 'test',
        dialogShown: false,
      );

      test('copies with new status', () {
        final copied = original.copyWith(status: PatchStatus.restartRequired);
        expect(copied.status, equals(PatchStatus.restartRequired));
        expect(copied.currentPatchNumber, equals(3));
        expect(copied.nextPatchNumber, equals(4));
        expect(copied.errorMessage, equals('test'));
        expect(copied.dialogShown, isFalse);
      });

      test('copies with new dialogShown', () {
        final copied = original.copyWith(dialogShown: true);
        expect(copied.dialogShown, isTrue);
        expect(copied.status, equals(PatchStatus.downloading));
      });

      test('copies with new errorMessage', () {
        final copied = original.copyWith(errorMessage: 'new error');
        expect(copied.errorMessage, equals('new error'));
      });

      test('copies with new patch numbers', () {
        final copied = original.copyWith(
          currentPatchNumber: 10,
          nextPatchNumber: 11,
        );
        expect(copied.currentPatchNumber, equals(10));
        expect(copied.nextPatchNumber, equals(11));
      });

      test('preserves all fields when no args', () {
        final copied = original.copyWith();
        expect(copied.status, equals(original.status));
        expect(copied.currentPatchNumber, equals(original.currentPatchNumber));
        expect(copied.nextPatchNumber, equals(original.nextPatchNumber));
        expect(copied.errorMessage, equals(original.errorMessage));
        expect(copied.dialogShown, equals(original.dialogShown));
      });
    });
  });
}
