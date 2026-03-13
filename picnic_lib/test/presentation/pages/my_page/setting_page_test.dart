import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';

/// Tests for SettingPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// PackageInfo.fromPlatform, DefaultCacheManager, LoadSwitch, url_launcher).
/// We test all importable production code: UpdateInfo, UpdateStatus,
/// PatchInfo, Setting, parseThemeMode, and widget constructor.
void main() {
  group('SettingPage widget', () {
    test('can be const-constructed', () {
      const page = SettingPage();
      expect(page, isA<SettingPage>());
    });

    test('with key can be constructed', () {
      const page = SettingPage(key: ValueKey('settings'));
      expect(page.key, equals(const ValueKey('settings')));
    });
  });

  group('UpdateStatus enum', () {
    test('has 4 values', () {
      expect(UpdateStatus.values.length, equals(4));
    });

    test('contains all expected statuses', () {
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRecommended));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRequired));
      expect(UpdateStatus.values, contains(UpdateStatus.needPatch));
    });
  });

  group('UpdateInfo model', () {
    UpdateInfo buildUpdateInfo({
      required UpdateStatus status,
      String currentVersion = '1.0.0',
      String latestVersion = '1.1.0',
      String forceVersion = '0.9.0',
      String? url = 'https://example.com/update',
    }) {
      return UpdateInfo(
        status: status,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        forceVersion: forceVersion,
        url: url,
      );
    }

    test('upToDate status', () {
      final info = buildUpdateInfo(status: UpdateStatus.upToDate);
      expect(info.status, equals(UpdateStatus.upToDate));
    });

    test('updateRecommended status', () {
      final info = buildUpdateInfo(status: UpdateStatus.updateRecommended);
      expect(info.status, equals(UpdateStatus.updateRecommended));
    });

    test('updateRequired status', () {
      final info = buildUpdateInfo(status: UpdateStatus.updateRequired);
      expect(info.status, equals(UpdateStatus.updateRequired));
    });

    test('needPatch status', () {
      final info = buildUpdateInfo(status: UpdateStatus.needPatch);
      expect(info.status, equals(UpdateStatus.needPatch));
    });

    test('currentVersion is accessible', () {
      final info = buildUpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '2.5.0',
      );
      expect(info.currentVersion, equals('2.5.0'));
    });

    test('latestVersion is accessible', () {
      final info = buildUpdateInfo(
        status: UpdateStatus.updateRecommended,
        latestVersion: '2.5.0',
      );
      expect(info.latestVersion, equals('2.5.0'));
    });

    test('forceVersion is accessible', () {
      final info = buildUpdateInfo(
        status: UpdateStatus.updateRequired,
        forceVersion: '2.0.0',
      );
      expect(info.forceVersion, equals('2.0.0'));
    });

    test('url can be null', () {
      final info = buildUpdateInfo(status: UpdateStatus.upToDate, url: null);
      expect(info.url, isNull);
    });

    test('url can be non-null', () {
      final info = buildUpdateInfo(
        status: UpdateStatus.updateRequired,
        url: 'https://apps.apple.com/app/id123',
      );
      expect(info.url, isNotNull);
      expect(info.url, isNotEmpty);
    });

    test('copyWith changes status', () {
      final info = buildUpdateInfo(status: UpdateStatus.upToDate);
      final updated = info.copyWith(status: UpdateStatus.updateRequired);
      expect(updated.status, UpdateStatus.updateRequired);
      expect(updated.currentVersion, info.currentVersion);
    });

    test('copyWith changes url', () {
      final info = buildUpdateInfo(status: UpdateStatus.upToDate, url: null);
      final updated = info.copyWith(url: 'https://new.url');
      expect(updated.url, 'https://new.url');
    });

    test('copyWith preserves unmodified fields', () {
      final info = buildUpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
      );
      final updated = info.copyWith(status: UpdateStatus.needPatch);
      expect(updated.currentVersion, '1.0.0');
      expect(updated.latestVersion, '2.0.0');
    });
  });

  group('PatchInfo model', () {
    test('default PatchInfo has expected defaults', () {
      const info = PatchInfo();
      expect(info.hasUpdate, isFalse);
      expect(info.updateDownloaded, isFalse);
      expect(info.needsRestart, isFalse);
      expect(info.currentPatch, isNull);
      expect(info.newPatch, isNull);
      expect(info.statusMessage, 'No updates available');
      expect(info.lastChecked, isNull);
    });

    test('constructor with currentPatch', () {
      const info = PatchInfo(currentPatch: 3);
      expect(info.currentPatch, equals(3));
    });

    test('constructor with all fields', () {
      final now = DateTime.now();
      final info = PatchInfo(
        hasUpdate: true,
        updateDownloaded: true,
        needsRestart: true,
        currentPatch: 5,
        newPatch: 7,
        statusMessage: 'custom',
        lastChecked: now,
      );
      expect(info.hasUpdate, isTrue);
      expect(info.updateDownloaded, isTrue);
      expect(info.needsRestart, isTrue);
      expect(info.currentPatch, 5);
      expect(info.newPatch, 7);
      expect(info.statusMessage, 'custom');
      expect(info.lastChecked, now);
    });

    test('displayInfo shows "No patch applied" when no patch', () {
      const info = PatchInfo();
      expect(info.displayInfo, contains('No patch'));
    });

    test('displayInfo shows patch number for applied patch', () {
      const info = PatchInfo(currentPatch: 5);
      expect(info.displayInfo, contains('5'));
    });

    test('displayInfo shows restart message when needsRestart', () {
      const info = PatchInfo(needsRestart: true);
      expect(info.displayInfo, contains('restart'));
    });

    test('displayInfo shows downloaded message', () {
      const info = PatchInfo(updateDownloaded: true);
      expect(info.displayInfo, contains('downloaded'));
    });

    test('displayInfo shows available message', () {
      const info = PatchInfo(hasUpdate: true);
      expect(info.displayInfo, contains('available'));
    });

    test('displayInfo priority: needsRestart > downloaded > available > patch > none', () {
      // needsRestart has highest priority
      const restartInfo = PatchInfo(
        needsRestart: true,
        updateDownloaded: true,
        hasUpdate: true,
        currentPatch: 5,
      );
      expect(restartInfo.displayInfo, contains('restart'));

      // updateDownloaded next
      const downloadedInfo = PatchInfo(
        updateDownloaded: true,
        hasUpdate: true,
        currentPatch: 5,
      );
      expect(downloadedInfo.displayInfo, contains('downloaded'));

      // hasUpdate next
      const availableInfo = PatchInfo(hasUpdate: true, currentPatch: 5);
      expect(availableInfo.displayInfo, contains('available'));

      // currentPatch next
      const patchInfo = PatchInfo(currentPatch: 5);
      expect(patchInfo.displayInfo, contains('5'));
    });

    test('canRestart is true when needsRestart', () {
      const info = PatchInfo(needsRestart: true);
      expect(info.canRestart, isTrue);
    });

    test('canRestart is false when not needsRestart', () {
      const info = PatchInfo();
      expect(info.canRestart, isFalse);
    });

    test('copyWith changes fields correctly', () {
      const info = PatchInfo();
      final updated = info.copyWith(
        hasUpdate: true,
        currentPatch: 3,
        statusMessage: 'Update available',
      );
      expect(updated.hasUpdate, isTrue);
      expect(updated.currentPatch, equals(3));
      expect(updated.statusMessage, equals('Update available'));
    });

    test('copyWith preserves unmodified fields', () {
      const info = PatchInfo(currentPatch: 5, hasUpdate: true);
      final updated = info.copyWith(statusMessage: 'New status');
      expect(updated.currentPatch, equals(5));
      expect(updated.hasUpdate, isTrue);
      expect(updated.statusMessage, equals('New status'));
    });

    test('newPatch field works correctly', () {
      const info = PatchInfo(newPatch: 7);
      expect(info.newPatch, equals(7));
    });
  });

  group('Setting model from production code', () {
    test('default Setting', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.language, 'ko');
    });

    test('copyWith language', () {
      const setting = Setting();
      final updated = setting.copyWith(language: 'en');
      expect(updated.language, 'en');
    });

    test('copyWith themeMode', () {
      const setting = Setting();
      final updated = setting.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
    });

    test('supportedLanguages', () {
      final languages = Setting.supportedLanguages;
      expect(languages.isNotEmpty, isTrue);
      expect(languages, contains('ko'));
    });
  });

  group('parseThemeMode from production code', () {
    test('parses light', () {
      expect(parseThemeMode('light'), ThemeMode.light);
    });

    test('parses dark', () {
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test('parses system', () {
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('unknown defaults to system', () {
      expect(parseThemeMode(''), ThemeMode.system);
    });
  });

  group('Constants from production code', () {
    test('Constants values', () {
      expect(Constants.webWidth, 375);
      expect(Constants.webHeight, 812);
    });

    test('NavBarConstants values', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
      expect(NavBarConstants.bottomNavOuterMargin, 16.0);
    });
  });
}
