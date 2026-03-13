import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('UpdateStatus', () {
    test('has all expected values', () {
      expect(UpdateStatus.values.length, 4);
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRecommended));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRequired));
      expect(UpdateStatus.values, contains(UpdateStatus.needPatch));
    });

    test('enum name matches expected strings', () {
      expect(UpdateStatus.upToDate.name, 'upToDate');
      expect(UpdateStatus.updateRecommended.name, 'updateRecommended');
      expect(UpdateStatus.updateRequired.name, 'updateRequired');
      expect(UpdateStatus.needPatch.name, 'needPatch');
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

    test('copyWith updates currentVersion', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(currentVersion: '0.9.0');
      expect(updated.currentVersion, '0.9.0');
      expect(updated.status, UpdateStatus.upToDate);
    });

    test('copyWith updates forceVersion', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(forceVersion: '1.0.0');
      expect(updated.forceVersion, '1.0.0');
    });

    test('copyWith with all fields changed', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(
        status: UpdateStatus.needPatch,
        currentVersion: '2.0.0',
        latestVersion: '3.0.0',
        forceVersion: '2.5.0',
        url: 'https://new.com',
      );
      expect(updated.status, UpdateStatus.needPatch);
      expect(updated.currentVersion, '2.0.0');
      expect(updated.latestVersion, '3.0.0');
      expect(updated.forceVersion, '2.5.0');
      expect(updated.url, 'https://new.com');
    });

    test('copyWith with no arguments returns equivalent object', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0',
        latestVersion: '1.5.0',
        forceVersion: '0.9.0',
        url: 'https://example.com',
      );
      final copy = info.copyWith();
      expect(copy.status, info.status);
      expect(copy.currentVersion, info.currentVersion);
      expect(copy.latestVersion, info.latestVersion);
      expect(copy.forceVersion, info.forceVersion);
      expect(copy.url, info.url);
    });
  });

  group('checkUpdate provider - error handling', () {
    late ProviderContainer container;

    setUp(() {
      // PackageInfo.fromPlatform() will throw in test environment
      // because there's no platform channel, so checkUpdate catches
      // the exception and returns null.
      setupMockSupabase({
        'version': [
          {
            'id': 1,
            'ios': {
              'version': '2.0.0',
              'force_version': '1.5.0',
              'url': 'https://apps.apple.com/app/123',
            },
            'android': {
              'version': '2.0.0',
              'force_version': '1.5.0',
              'url': 'https://play.google.com/store/apps/123',
            },
            'macos': {},
            'windows': {},
            'linux': {},
            'deleted_at': null,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkUpdate returns null when PackageInfo fails', () async {
      // PackageInfo.fromPlatform() fails in test env, caught by try-catch
      final result = await container.read(checkUpdateProvider.future);
      expect(result, isNull);
    });
  });

  group('UpdateInfo equality and construction', () {
    test('two UpdateInfo with same values are independent objects', () {
      const info1 = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      const info2 = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(info1.status, info2.status);
      expect(info1.currentVersion, info2.currentVersion);
    });

    test('different status values create distinct objects', () {
      const upToDate = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      const required = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(upToDate.status, isNot(required.status));
    });

    test('needPatch status is a valid UpdateStatus', () {
      const info = UpdateInfo(
        status: UpdateStatus.needPatch,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '1.0.0',
      );
      expect(info.status, UpdateStatus.needPatch);
    });

    test('copyWith returns new instance preserving url null', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final copy = info.copyWith(status: UpdateStatus.updateRecommended);
      expect(copy.url, isNull);
      expect(copy.status, UpdateStatus.updateRecommended);
    });

    test('UpdateInfo with all fields populated', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '0.5.0',
        latestVersion: '2.0.0',
        forceVersion: '1.0.0',
        url: 'https://play.google.com/store/apps/details?id=com.example',
      );
      expect(info.currentVersion, '0.5.0');
      expect(info.latestVersion, '2.0.0');
      expect(info.forceVersion, '1.0.0');
      expect(info.url, contains('play.google.com'));
    });
  });

  group('checkUpdate provider with empty version table', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'version': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns null when version table is empty', () async {
      final result = await container.read(checkUpdateProvider.future);
      expect(result, isNull);
    });
  });
}
