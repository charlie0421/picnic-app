import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  group('UpdateStatus', () {
    test('has all expected values', () {
      expect(UpdateStatus.values.length, 4);
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRecommended));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRequired));
      expect(UpdateStatus.values, contains(UpdateStatus.needPatch));
    });
  });

  group('UpdateInfo', () {
    test('creates with required fields', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(info.status, UpdateStatus.upToDate);
      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion, '1.0.0');
      expect(info.forceVersion, '0.9.0');
      expect(info.url, isNull);
    });

    test('creates with optional url', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://example.com',
      );
      expect(info.url, 'https://example.com');
    });

    test('copyWith updates status', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(status: UpdateStatus.updateRequired);
      expect(updated.status, UpdateStatus.updateRequired);
      expect(updated.currentVersion, '1.0.0');
    });

    test('copyWith updates url', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(url: 'https://store.example.com');
      expect(updated.url, 'https://store.example.com');
    });

    test('copyWith preserves unchanged fields', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '1.5.0',
        forceVersion: '0.9.0',
        url: 'https://store.com',
      );
      final updated = info.copyWith(latestVersion: '2.0.0');
      expect(updated.status, UpdateStatus.updateRecommended);
      expect(updated.currentVersion, '1.0.0');
      expect(updated.latestVersion, '2.0.0');
      expect(updated.forceVersion, '0.9.0');
      expect(updated.url, 'https://store.com');
    });
  });
}
