import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';
import 'package:picnic_lib/presentation/providers/check_update_helper.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  group('CheckUpdateHelper.isNewerThan', () {
    test('returns true when market version is higher', () {
      expect(CheckUpdateHelper.isNewerThan('1.0.0', '2.0.0'), isTrue);
    });

    test('returns false when versions are equal', () {
      expect(CheckUpdateHelper.isNewerThan('1.0.0', '1.0.0'), isFalse);
    });

    test('returns false when current version is higher', () {
      expect(CheckUpdateHelper.isNewerThan('2.0.0', '1.0.0'), isFalse);
    });

    test('handles minor version differences', () {
      expect(CheckUpdateHelper.isNewerThan('1.0.0', '1.1.0'), isTrue);
      expect(CheckUpdateHelper.isNewerThan('1.1.0', '1.0.0'), isFalse);
    });

    test('handles patch version differences', () {
      expect(CheckUpdateHelper.isNewerThan('1.0.0', '1.0.1'), isTrue);
      expect(CheckUpdateHelper.isNewerThan('1.0.1', '1.0.0'), isFalse);
    });

    test('handles complex version comparisons', () {
      expect(CheckUpdateHelper.isNewerThan('1.9.9', '2.0.0'), isTrue);
      expect(CheckUpdateHelper.isNewerThan('0.99.99', '1.0.0'), isTrue);
    });
  });

  group('CheckUpdateHelper.getPlatformInfo', () {
    late AppVersionModel model;

    setUp(() {
      model = const AppVersionModel(
        id: 1,
        ios: {
          'version': '2.0.0',
          'force_version': '1.5.0',
          'url': 'https://apps.apple.com/app/123',
        },
        android: {
          'version': '2.1.0',
          'force_version': '1.6.0',
          'url': 'https://play.google.com/store/apps/123',
        },
        macos: {},
        windows: {},
        linux: {},
      );
    });

    test('returns android info for android platform', () {
      final info = CheckUpdateHelper.getPlatformInfo(model, 'android');
      expect(info, isNotNull);
      expect(info!['version'], '2.1.0');
      expect(info['force_version'], '1.6.0');
      expect(info['url'], contains('play.google.com'));
    });

    test('returns ios info for ios platform', () {
      final info = CheckUpdateHelper.getPlatformInfo(model, 'ios');
      expect(info, isNotNull);
      expect(info!['version'], '2.0.0');
      expect(info['force_version'], '1.5.0');
      expect(info['url'], contains('apps.apple.com'));
    });

    test('returns ios info for unknown platform name', () {
      // Non-android falls through to ios
      final info = CheckUpdateHelper.getPlatformInfo(model, 'unknown');
      expect(info, isNotNull);
      expect(info!['version'], '2.0.0');
    });
  });

  group('CheckUpdateHelper.determineUpdateStatus', () {
    test('returns updateRequired when current < forceVersion', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      expect(status, UpdateStatus.updateRequired);
    });

    test('returns updateRecommended when current >= force but < latest', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.5.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      expect(status, UpdateStatus.updateRecommended);
    });

    test('returns upToDate when current >= latest', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '2.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      expect(status, UpdateStatus.upToDate);
    });

    test('returns upToDate when current > latest', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '3.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      expect(status, UpdateStatus.upToDate);
    });

    test('returns updateRequired when force equals latest and current is below',
        () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '2.0.0',
      );
      expect(status, UpdateStatus.updateRequired);
    });

    test('returns upToDate when all versions are equal', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '1.0.0',
      );
      expect(status, UpdateStatus.upToDate);
    });

    test('returns updateRequired even with minor version difference', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.4.9',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
      );
      expect(status, UpdateStatus.updateRequired);
    });

    test('returns updateRecommended with patch version difference', () {
      final status = CheckUpdateHelper.determineUpdateStatus(
        currentVersion: '1.5.0',
        latestVersion: '1.5.1',
        forceVersion: '1.0.0',
      );
      expect(status, UpdateStatus.updateRecommended);
    });
  });
}
