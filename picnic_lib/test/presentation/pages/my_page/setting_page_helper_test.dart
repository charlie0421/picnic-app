import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page_helper.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // formatVersionInfoText
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.formatVersionInfoText', () {
    test('formats with patch number', () {
      final result = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: '최신 버전',
        latestVersion: '2.0.0',
        buildNumber: '42',
        patchNumber: 3,
        patchNumberFormatter: (n) => ' 패치 #$n',
      );
      expect(result, '최신 버전 (2.0.0) 빌드: 42 패치 #3');
    });

    test('formats without patch number when patchNumber is null', () {
      final result = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: '최신 버전',
        latestVersion: '2.0.0',
        buildNumber: '42',
        patchNumber: null,
        patchNumberFormatter: (n) => ' 패치 #$n',
      );
      expect(result, '최신 버전 (2.0.0) 빌드: 42');
    });

    test('formats without patch when formatter is null', () {
      final result = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: 'Latest',
        latestVersion: '1.5.0',
        buildNumber: '100',
        patchNumber: 5,
        patchNumberFormatter: null,
      );
      expect(result, 'Latest (1.5.0) 빌드: 100');
    });

    test('handles empty build number', () {
      final result = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: '최신 버전',
        latestVersion: '1.0.0',
        buildNumber: '',
      );
      expect(result, '최신 버전 (1.0.0) 빌드: ');
    });

    test('handles empty latest version', () {
      final result = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: '최신 버전',
        latestVersion: '',
        buildNumber: '1',
      );
      expect(result, '최신 버전 () 빌드: 1');
    });
  });

  // ---------------------------------------------------------------------------
  // formatUpToDateVersionText
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.formatUpToDateVersionText', () {
    test('formats with patch number', () {
      final result = SettingPageHelper.formatUpToDateVersionText(
        upToDateLabel: '최신 버전입니다',
        buildNumber: '42',
        patchNumber: 3,
        patchNumberFormatter: (n) => ' 패치 #$n',
      );
      expect(result, '최신 버전입니다 빌드: 42 패치 #3');
    });

    test('formats without patch number', () {
      final result = SettingPageHelper.formatUpToDateVersionText(
        upToDateLabel: '최신 버전입니다',
        buildNumber: '42',
      );
      expect(result, '최신 버전입니다 빌드: 42');
    });

    test('formats without patch when patchNumber is null', () {
      final result = SettingPageHelper.formatUpToDateVersionText(
        upToDateLabel: 'Up to date',
        buildNumber: '10',
        patchNumber: null,
        patchNumberFormatter: (n) => ' patch #$n',
      );
      expect(result, 'Up to date 빌드: 10');
    });

    test('formats without patch when formatter is null', () {
      final result = SettingPageHelper.formatUpToDateVersionText(
        upToDateLabel: 'Up to date',
        buildNumber: '10',
        patchNumber: 7,
        patchNumberFormatter: null,
      );
      expect(result, 'Up to date 빌드: 10');
    });
  });

  // ---------------------------------------------------------------------------
  // formatCurrentVersionLabel
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.formatCurrentVersionLabel', () {
    test('formats current version label', () {
      final result = SettingPageHelper.formatCurrentVersionLabel(
        currentVersionLabel: '현재 버전',
        currentVersion: '1.5.0',
      );
      expect(result, '현재 버전 1.5.0');
    });

    test('handles empty version string', () {
      final result = SettingPageHelper.formatCurrentVersionLabel(
        currentVersionLabel: '현재 버전',
        currentVersion: '',
      );
      expect(result, '현재 버전 ');
    });

    test('works with English labels', () {
      final result = SettingPageHelper.formatCurrentVersionLabel(
        currentVersionLabel: 'Current version',
        currentVersion: '3.2.1',
      );
      expect(result, 'Current version 3.2.1');
    });
  });

  // ---------------------------------------------------------------------------
  // getPatchStatusText
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.getPatchStatusText', () {
    test('returns formatted patch text when patch is non-null', () {
      final result = SettingPageHelper.getPatchStatusText(
        currentPatch: 5,
        currentPatchFormatter: (n) => '현재 패치: $n',
        noneLabel: '패치 없음',
      );
      expect(result, '현재 패치: 5');
    });

    test('returns none label when patch is null', () {
      final result = SettingPageHelper.getPatchStatusText(
        currentPatch: null,
        currentPatchFormatter: (n) => '현재 패치: $n',
        noneLabel: '패치 없음',
      );
      expect(result, '패치 없음');
    });

    test('returns formatter result for patch 0', () {
      final result = SettingPageHelper.getPatchStatusText(
        currentPatch: 0,
        currentPatchFormatter: (n) => 'Patch $n',
        noneLabel: 'None',
      );
      expect(result, 'Patch 0');
    });

    test('works with English labels', () {
      final result = SettingPageHelper.getPatchStatusText(
        currentPatch: 12,
        currentPatchFormatter: (n) => 'Current patch: $n',
        noneLabel: 'No patch',
      );
      expect(result, 'Current patch: 12');
    });
  });

  // ---------------------------------------------------------------------------
  // isUpdateTappable
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.isUpdateTappable', () {
    test('updateRequired is tappable', () {
      expect(
        SettingPageHelper.isUpdateTappable(UpdateStatus.updateRequired),
        isTrue,
      );
    });

    test('updateRecommended is tappable', () {
      expect(
        SettingPageHelper.isUpdateTappable(UpdateStatus.updateRecommended),
        isTrue,
      );
    });

    test('upToDate is not tappable', () {
      expect(
        SettingPageHelper.isUpdateTappable(UpdateStatus.upToDate),
        isFalse,
      );
    });

    test('needPatch is not tappable', () {
      expect(
        SettingPageHelper.isUpdateTappable(UpdateStatus.needPatch),
        isFalse,
      );
    });

    test('covers all UpdateStatus values', () {
      for (final status in UpdateStatus.values) {
        // Should not throw for any status value.
        expect(
          () => SettingPageHelper.isUpdateTappable(status),
          returnsNormally,
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // toggleSwitchValue
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.toggleSwitchValue', () {
    test('toggles false to true', () {
      expect(SettingPageHelper.toggleSwitchValue(false), isTrue);
    });

    test('toggles true to false', () {
      expect(SettingPageHelper.toggleSwitchValue(true), isFalse);
    });

    test('double toggle returns original value', () {
      const original = true;
      final toggled = SettingPageHelper.toggleSwitchValue(original);
      final doubleToggled = SettingPageHelper.toggleSwitchValue(toggled);
      expect(doubleToggled, original);
    });
  });

  // ---------------------------------------------------------------------------
  // isUpdateInfoValid
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.isUpdateInfoValid', () {
    test('returns false for null', () {
      expect(SettingPageHelper.isUpdateInfoValid(null), isFalse);
    });

    test('returns true for non-null UpdateInfo', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(SettingPageHelper.isUpdateInfoValid(info), isTrue);
    });

    test('returns true for UpdateInfo with url', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://apps.apple.com/app/id123',
      );
      expect(SettingPageHelper.isUpdateInfoValid(info), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // usesRecentVersionFormat
  // ---------------------------------------------------------------------------
  group('SettingPageHelper.usesRecentVersionFormat', () {
    test('needPatch uses recent version format', () {
      expect(
        SettingPageHelper.usesRecentVersionFormat(UpdateStatus.needPatch),
        isTrue,
      );
    });

    test('updateRequired uses recent version format', () {
      expect(
        SettingPageHelper.usesRecentVersionFormat(UpdateStatus.updateRequired),
        isTrue,
      );
    });

    test('updateRecommended uses recent version format', () {
      expect(
        SettingPageHelper.usesRecentVersionFormat(
          UpdateStatus.updateRecommended,
        ),
        isTrue,
      );
    });

    test('upToDate does NOT use recent version format', () {
      expect(
        SettingPageHelper.usesRecentVersionFormat(UpdateStatus.upToDate),
        isFalse,
      );
    });

    test('covers all UpdateStatus values', () {
      for (final status in UpdateStatus.values) {
        expect(
          () => SettingPageHelper.usesRecentVersionFormat(status),
          returnsNormally,
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Integration-style: combining helpers mirrors page logic
  // ---------------------------------------------------------------------------
  group('SettingPageHelper integration', () {
    test('full version display for updateRequired matches page pattern', () {
      const info = UpdateInfo(
        status: UpdateStatus.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.5.0',
        url: 'https://example.com',
      );

      final leading = SettingPageHelper.formatCurrentVersionLabel(
        currentVersionLabel: '현재 버전',
        currentVersion: info.currentVersion,
      );

      final usesRecent = SettingPageHelper.usesRecentVersionFormat(info.status);
      expect(usesRecent, isTrue);

      final trailing = SettingPageHelper.formatVersionInfoText(
        recentVersionLabel: '최신 버전',
        latestVersion: info.latestVersion,
        buildNumber: '55',
        patchNumber: 3,
        patchNumberFormatter: (n) => ' 패치 #$n',
      );

      expect(leading, '현재 버전 1.0.0');
      expect(trailing, '최신 버전 (2.0.0) 빌드: 55 패치 #3');
      expect(SettingPageHelper.isUpdateTappable(info.status), isTrue);
    });

    test('full version display for upToDate matches page pattern', () {
      const info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '2.0.0',
        latestVersion: '2.0.0',
        forceVersion: '1.0.0',
      );

      final leading = SettingPageHelper.formatCurrentVersionLabel(
        currentVersionLabel: '현재 버전',
        currentVersion: info.currentVersion,
      );

      final usesRecent = SettingPageHelper.usesRecentVersionFormat(info.status);
      expect(usesRecent, isFalse);

      final trailing = SettingPageHelper.formatUpToDateVersionText(
        upToDateLabel: '최신 버전입니다',
        buildNumber: '55',
      );

      expect(leading, '현재 버전 2.0.0');
      expect(trailing, '최신 버전입니다 빌드: 55');
      expect(SettingPageHelper.isUpdateTappable(info.status), isFalse);
    });

    test('patch status with no patch applied', () {
      final text = SettingPageHelper.getPatchStatusText(
        currentPatch: null,
        currentPatchFormatter: (n) => '현재 패치: $n',
        noneLabel: '패치 없음',
      );
      expect(text, '패치 없음');
    });

    test('patch status with patch applied', () {
      final text = SettingPageHelper.getPatchStatusText(
        currentPatch: 7,
        currentPatchFormatter: (n) => '현재 패치: $n',
        noneLabel: '패치 없음',
      );
      expect(text, '현재 패치: 7');
    });
  });
}
