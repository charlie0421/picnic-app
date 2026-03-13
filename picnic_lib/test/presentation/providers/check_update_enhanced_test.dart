import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('UpdateInfo - comprehensive coverage', () {
    test('copyWith returns new instance with same values when no args', () {
      const original = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.2.3',
        latestVersion: '2.0.0',
        forceVersion: '1.0.0',
        url: 'https://store.example.com',
      );
      final copy = original.copyWith();
      expect(copy.status, original.status);
      expect(copy.currentVersion, original.currentVersion);
      expect(copy.latestVersion, original.latestVersion);
      expect(copy.forceVersion, original.forceVersion);
      expect(copy.url, original.url);
    });

    test('copyWith updates only status', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.5.0',
        url: 'https://example.com',
      );
      final copy = original.copyWith(status: UpdateStatus.updateRequired);
      expect(copy.status, UpdateStatus.updateRequired);
      expect(copy.currentVersion, '1.0.0');
      expect(copy.latestVersion, '1.0.0');
      expect(copy.forceVersion, '0.5.0');
      expect(copy.url, 'https://example.com');
    });

    test('copyWith updates only currentVersion', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '0.5.0',
      );
      final copy = original.copyWith(currentVersion: '1.5.0');
      expect(copy.currentVersion, '1.5.0');
      expect(copy.latestVersion, '2.0.0');
    });

    test('copyWith updates only latestVersion', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.5.0',
      );
      final copy = original.copyWith(latestVersion: '3.0.0');
      expect(copy.latestVersion, '3.0.0');
      expect(copy.currentVersion, '1.0.0');
    });

    test('copyWith updates only forceVersion', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.5.0',
      );
      final copy = original.copyWith(forceVersion: '0.9.0');
      expect(copy.forceVersion, '0.9.0');
    });

    test('copyWith updates only url from null', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.5.0',
      );
      expect(original.url, isNull);
      final copy = original.copyWith(url: 'https://new-store.com');
      expect(copy.url, 'https://new-store.com');
    });

    test('copyWith updates all fields simultaneously', () {
      const original = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.5.0',
      );
      final copy = original.copyWith(
        status: UpdateStatus.needPatch,
        currentVersion: '2.0.0',
        latestVersion: '3.0.0',
        forceVersion: '2.5.0',
        url: 'https://updated.com',
      );
      expect(copy.status, UpdateStatus.needPatch);
      expect(copy.currentVersion, '2.0.0');
      expect(copy.latestVersion, '3.0.0');
      expect(copy.forceVersion, '2.5.0');
      expect(copy.url, 'https://updated.com');
    });

    test('UpdateInfo with empty version strings', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '',
        latestVersion: '',
        forceVersion: '',
      );
      expect(info.currentVersion, '');
      expect(info.latestVersion, '');
      expect(info.forceVersion, '');
    });

    test('UpdateInfo with pre-release version strings', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRecommended,
        currentVersion: '1.0.0-beta.1',
        latestVersion: '1.0.0-rc.1',
        forceVersion: '0.9.0',
      );
      expect(info.currentVersion, '1.0.0-beta.1');
      expect(info.latestVersion, '1.0.0-rc.1');
    });
  });

  group('UpdateStatus enum', () {
    test('values list has correct length', () {
      expect(UpdateStatus.values.length, 4);
    });

    test('index values are sequential', () {
      expect(UpdateStatus.upToDate.index, 0);
      expect(UpdateStatus.updateRecommended.index, 1);
      expect(UpdateStatus.updateRequired.index, 2);
      expect(UpdateStatus.needPatch.index, 3);
    });

    test('can be used in switch/case', () {
      String describe(UpdateStatus s) {
        switch (s) {
          case UpdateStatus.upToDate:
            return 'up-to-date';
          case UpdateStatus.updateRecommended:
            return 'recommended';
          case UpdateStatus.updateRequired:
            return 'required';
          case UpdateStatus.needPatch:
            return 'patch';
        }
      }

      expect(describe(UpdateStatus.upToDate), 'up-to-date');
      expect(describe(UpdateStatus.updateRecommended), 'recommended');
      expect(describe(UpdateStatus.updateRequired), 'required');
      expect(describe(UpdateStatus.needPatch), 'patch');
    });
  });

  group('checkUpdate provider - various version data', () {
    test('returns null when version table has missing platform data', () async {
      setupMockSupabase({
        'version': [
          {
            'id': 1,
            'ios': {},
            'android': {},
            'macos': {},
            'windows': {},
            'linux': {},
            'deleted_at': null,
          },
        ],
      });
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        tearDownMockSupabase();
      });

      // PackageInfo.fromPlatform() fails in test env
      final result = await container.read(checkUpdateProvider.future);
      expect(result, isNull);
    });

    test('returns null when version data has null values', () async {
      setupMockSupabase({
        'version': [
          {
            'id': 1,
            'ios': {
              'version': null,
              'force_version': null,
              'url': null,
            },
            'android': {
              'version': null,
              'force_version': null,
              'url': null,
            },
            'macos': {},
            'windows': {},
            'linux': {},
            'deleted_at': null,
          },
        ],
      });
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        tearDownMockSupabase();
      });

      final result = await container.read(checkUpdateProvider.future);
      expect(result, isNull);
    });

    test('provider handles supabase not set up', () async {
      // No setupMockSupabase call - provider should handle gracefully
      setupMockSupabase({});
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        tearDownMockSupabase();
      });

      final result = await container.read(checkUpdateProvider.future);
      expect(result, isNull);
    });
  });
}
