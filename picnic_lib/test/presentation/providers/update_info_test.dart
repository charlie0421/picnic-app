import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  group('UpdateStatus enum', () {
    test('4개의 상태값이 정의됨', () {
      expect(UpdateStatus.values.length, equals(4));
    });

    test('모든 상태값 존재 확인', () {
      expect(UpdateStatus.upToDate, isNotNull);
      expect(UpdateStatus.updateRecommended, isNotNull);
      expect(UpdateStatus.updateRequired, isNotNull);
      expect(UpdateStatus.needPatch, isNotNull);
    });

    test('index 순서 확인', () {
      expect(UpdateStatus.upToDate.index, equals(0));
      expect(UpdateStatus.updateRecommended.index, equals(1));
      expect(UpdateStatus.updateRequired.index, equals(2));
      expect(UpdateStatus.needPatch.index, equals(3));
    });
  });

  group('UpdateInfo', () {
    test('필수 파라미터로 생성', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(info.status, equals(UpdateStatus.upToDate));
      expect(info.currentVersion, equals('1.0.0'));
      expect(info.latestVersion, equals('1.0.0'));
      expect(info.forceVersion, equals('0.9.0'));
      expect(info.url, isNull);
    });

    test('URL 포함 생성', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://example.com/update',
      );
      expect(info.url, equals('https://example.com/update'));
    });

    test('copyWith - status 변경', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final copied = original.copyWith(status: UpdateStatus.updateRecommended);
      expect(copied.status, equals(UpdateStatus.updateRecommended));
      expect(copied.currentVersion, equals('1.0.0')); // 유지
    });

    test('copyWith - 여러 필드 변경', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final copied = original.copyWith(
        latestVersion: '2.0.0',
        url: 'https://example.com',
      );
      expect(copied.latestVersion, equals('2.0.0'));
      expect(copied.url, equals('https://example.com'));
      expect(copied.currentVersion, equals('1.0.0')); // 유지
      expect(copied.forceVersion, equals('0.9.0')); // 유지
    });

    test('copyWith - 변경 없으면 동일 값', () {
      const original = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://example.com',
      );
      final copied = original.copyWith();
      expect(copied.status, equals(original.status));
      expect(copied.currentVersion, equals(original.currentVersion));
      expect(copied.latestVersion, equals(original.latestVersion));
      expect(copied.forceVersion, equals(original.forceVersion));
      expect(copied.url, equals(original.url));
    });
  });
}
