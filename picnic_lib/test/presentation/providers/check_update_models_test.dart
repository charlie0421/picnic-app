import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  group('UpdateStatus', () {
    test('has all expected enum values', () {
      expect(UpdateStatus.values, hasLength(4));
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRecommended));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRequired));
      expect(UpdateStatus.values, contains(UpdateStatus.needPatch));
    });
  });

  group('UpdateInfo', () {
    test('constructor sets all fields including url', () {
      final info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://example.com/update',
      );

      expect(info.status, UpdateStatus.updateRequired);
      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion, '2.0.0');
      expect(info.forceVersion, '1.5.0');
      expect(info.url, 'https://example.com/update');
    });

    test('constructor with null url', () {
      final info = UpdateInfo(
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

    group('copyWith', () {
      late UpdateInfo original;

      setUp(() {
        original = UpdateInfo(
          status: UpdateStatus.upToDate,
          currentVersion: '1.0.0',
          latestVersion: '1.0.0',
          forceVersion: '0.9.0',
          url: 'https://example.com',
        );
      });

      test('changing status only', () {
        final copied = original.copyWith(status: UpdateStatus.updateRequired);

        expect(copied.status, UpdateStatus.updateRequired);
        expect(copied.currentVersion, original.currentVersion);
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, original.url);
      });

      test('changing currentVersion only', () {
        final copied = original.copyWith(currentVersion: '0.8.0');

        expect(copied.status, original.status);
        expect(copied.currentVersion, '0.8.0');
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, original.url);
      });

      test('changing latestVersion only', () {
        final copied = original.copyWith(latestVersion: '2.0.0');

        expect(copied.status, original.status);
        expect(copied.currentVersion, original.currentVersion);
        expect(copied.latestVersion, '2.0.0');
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, original.url);
      });

      test('changing forceVersion only', () {
        final copied = original.copyWith(forceVersion: '1.5.0');

        expect(copied.status, original.status);
        expect(copied.currentVersion, original.currentVersion);
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, '1.5.0');
        expect(copied.url, original.url);
      });

      test('changing url only', () {
        final copied = original.copyWith(url: 'https://new-url.com');

        expect(copied.status, original.status);
        expect(copied.currentVersion, original.currentVersion);
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, 'https://new-url.com');
      });

      test('changing multiple fields at once', () {
        final copied = original.copyWith(
          status: UpdateStatus.needPatch,
          currentVersion: '1.1.0',
          url: 'https://patch.com',
        );

        expect(copied.status, UpdateStatus.needPatch);
        expect(copied.currentVersion, '1.1.0');
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, 'https://patch.com');
      });

      test('with no changes returns equivalent values', () {
        final copied = original.copyWith();

        expect(copied.status, original.status);
        expect(copied.currentVersion, original.currentVersion);
        expect(copied.latestVersion, original.latestVersion);
        expect(copied.forceVersion, original.forceVersion);
        expect(copied.url, original.url);
      });
    });
  });
}
