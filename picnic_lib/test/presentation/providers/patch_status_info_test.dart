import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/patch_status_provider.dart';

void main() {
  group('PatchStatus enum', () {
    test('5개의 상태값이 정의됨', () {
      expect(PatchStatus.values.length, equals(5));
    });

    test('모든 상태값 존재 확인', () {
      expect(PatchStatus.checking, isNotNull);
      expect(PatchStatus.upToDate, isNotNull);
      expect(PatchStatus.downloading, isNotNull);
      expect(PatchStatus.restartRequired, isNotNull);
      expect(PatchStatus.error, isNotNull);
    });

    test('index 순서 확인', () {
      expect(PatchStatus.checking.index, equals(0));
      expect(PatchStatus.upToDate.index, equals(1));
      expect(PatchStatus.downloading.index, equals(2));
      expect(PatchStatus.restartRequired.index, equals(3));
      expect(PatchStatus.error.index, equals(4));
    });
  });

  group('PatchStatusInfo', () {
    test('기본 생성', () {
      const info = PatchStatusInfo(status: PatchStatus.upToDate);
      expect(info.status, equals(PatchStatus.upToDate));
      expect(info.currentPatchNumber, isNull);
      expect(info.nextPatchNumber, isNull);
      expect(info.errorMessage, isNull);
      expect(info.dialogShown, isFalse);
    });

    test('전체 파라미터 생성', () {
      const info = PatchStatusInfo(
        status: PatchStatus.restartRequired,
        currentPatchNumber: 3,
        nextPatchNumber: 4,
        errorMessage: 'test error',
        dialogShown: true,
      );
      expect(info.status, equals(PatchStatus.restartRequired));
      expect(info.currentPatchNumber, equals(3));
      expect(info.nextPatchNumber, equals(4));
      expect(info.errorMessage, equals('test error'));
      expect(info.dialogShown, isTrue);
    });

    test('copyWith - status 변경', () {
      const original = PatchStatusInfo(status: PatchStatus.upToDate);
      final copied = original.copyWith(status: PatchStatus.downloading);
      expect(copied.status, equals(PatchStatus.downloading));
      expect(copied.dialogShown, isFalse); // 기존 값 유지
    });

    test('copyWith - 여러 필드 변경', () {
      const original = PatchStatusInfo(
        status: PatchStatus.upToDate,
        currentPatchNumber: 1,
      );
      final copied = original.copyWith(
        status: PatchStatus.restartRequired,
        nextPatchNumber: 2,
        dialogShown: true,
      );
      expect(copied.status, equals(PatchStatus.restartRequired));
      expect(copied.currentPatchNumber, equals(1)); // 기존 값 유지
      expect(copied.nextPatchNumber, equals(2));
      expect(copied.dialogShown, isTrue);
    });

    test('copyWith - 변경 없으면 동일 값 유지', () {
      const original = PatchStatusInfo(
        status: PatchStatus.error,
        errorMessage: 'something went wrong',
      );
      final copied = original.copyWith();
      expect(copied.status, equals(PatchStatus.error));
      expect(copied.errorMessage, equals('something went wrong'));
    });
  });

  group('PatchStatusInfo 계산 속성', () {
    test('needsRestart - restartRequired 상태일 때 true', () {
      const info = PatchStatusInfo(status: PatchStatus.restartRequired);
      expect(info.needsRestart, isTrue);
    });

    test('needsRestart - 다른 상태일 때 false', () {
      for (final status in PatchStatus.values) {
        if (status == PatchStatus.restartRequired) continue;
        final info = PatchStatusInfo(status: status);
        expect(info.needsRestart, isFalse,
            reason: '$status should not need restart');
      }
    });

    test('shouldShowDialog - 재시작 필요 + 다이얼로그 미표시 시 true', () {
      const info = PatchStatusInfo(
        status: PatchStatus.restartRequired,
        dialogShown: false,
      );
      expect(info.shouldShowDialog, isTrue);
    });

    test('shouldShowDialog - 재시작 필요 + 다이얼로그 표시됨 시 false', () {
      const info = PatchStatusInfo(
        status: PatchStatus.restartRequired,
        dialogShown: true,
      );
      expect(info.shouldShowDialog, isFalse);
    });

    test('shouldShowDialog - 재시작 불필요 시 false', () {
      const info = PatchStatusInfo(
        status: PatchStatus.upToDate,
        dialogShown: false,
      );
      expect(info.shouldShowDialog, isFalse);
    });
  });
}
