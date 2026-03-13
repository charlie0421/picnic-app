import 'package:flutter/foundation.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

/// Pure helper functions for SettingPage logic.
///
/// All methods are static and have no Flutter/widget dependencies,
/// making them easy to unit test.
@visibleForTesting
class SettingPageHelper {
  SettingPageHelper._();

  /// Formats the version info string shown when an update is available.
  ///
  /// Example output: "최신 버전 (2.0.0) 빌드: 42 패치 #3"
  /// When [patchNumber] is null the patch suffix is omitted.
  @visibleForTesting
  static String formatVersionInfoText({
    required String recentVersionLabel,
    required String latestVersion,
    required String buildNumber,
    int? patchNumber,
    String Function(int)? patchNumberFormatter,
  }) {
    final patchSuffix =
        (patchNumber != null && patchNumberFormatter != null)
            ? patchNumberFormatter(patchNumber)
            : '';
    return '$recentVersionLabel ($latestVersion) 빌드: $buildNumber$patchSuffix';
  }

  /// Formats the version info string shown when the app is up to date.
  ///
  /// Example output: "최신 버전입니다 빌드: 42 패치 #3"
  @visibleForTesting
  static String formatUpToDateVersionText({
    required String upToDateLabel,
    required String buildNumber,
    int? patchNumber,
    String Function(int)? patchNumberFormatter,
  }) {
    final patchSuffix =
        (patchNumber != null && patchNumberFormatter != null)
            ? patchNumberFormatter(patchNumber)
            : '';
    return '$upToDateLabel 빌드: $buildNumber$patchSuffix';
  }

  /// Formats the current version label shown on the leading side.
  ///
  /// Example output: "현재 버전 1.5.0"
  @visibleForTesting
  static String formatCurrentVersionLabel({
    required String currentVersionLabel,
    required String currentVersion,
  }) {
    return '$currentVersionLabel $currentVersion';
  }

  /// Returns the patch status display text.
  ///
  /// If [currentPatch] is non-null, returns [currentPatchFormatter] result;
  /// otherwise returns [noneLabel].
  @visibleForTesting
  static String getPatchStatusText({
    required int? currentPatch,
    required String Function(int) currentPatchFormatter,
    required String noneLabel,
  }) {
    if (currentPatch != null) {
      return currentPatchFormatter(currentPatch);
    }
    return noneLabel;
  }

  /// Determines whether the given [UpdateStatus] should allow the user
  /// to tap and navigate to the app store.
  @visibleForTesting
  static bool isUpdateTappable(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.updateRequired:
      case UpdateStatus.updateRecommended:
        return true;
      case UpdateStatus.upToDate:
      case UpdateStatus.needPatch:
        return false;
    }
  }

  /// Returns the toggled value of a push notification switch.
  ///
  /// This mirrors the pure logic of `_getFuture1` / `_getFuture2` in the
  /// page: given the current value, return the opposite.
  @visibleForTesting
  static bool toggleSwitchValue(bool current) {
    return !current;
  }

  /// Determines whether update info is considered valid enough to display.
  ///
  /// Returns `false` when [info] is null.
  @visibleForTesting
  static bool isUpdateInfoValid(UpdateInfo? info) {
    return info != null;
  }

  /// Returns `true` when the update status shows a version string that
  /// uses the "recent version (x.y.z)" format (as opposed to the "up to date"
  /// format).
  @visibleForTesting
  static bool usesRecentVersionFormat(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.needPatch:
      case UpdateStatus.updateRequired:
      case UpdateStatus.updateRecommended:
        return true;
      case UpdateStatus.upToDate:
        return false;
    }
  }
}
