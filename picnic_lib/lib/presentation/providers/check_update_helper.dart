import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:version/version.dart';

/// Pure helper functions extracted from check_update_provider for testability.
class CheckUpdateHelper {
  const CheckUpdateHelper._();

  /// Returns true if [marketVersion] is newer than [currentVersion].
  @visibleForTesting
  static bool isNewerThan(String currentVersion, String marketVersion) {
    final current = Version.parse(currentVersion);
    final market = Version.parse(marketVersion);
    return market > current;
  }

  /// Returns the platform-specific version info map from the model.
  @visibleForTesting
  static Map<String, dynamic>? getPlatformInfo(
      AppVersionModel model, String platformName) {
    return platformName == 'android' ? model.android : model.ios;
  }

  /// Determines the [UpdateStatus] based on current, latest, and force versions.
  @visibleForTesting
  static UpdateStatus determineUpdateStatus({
    required String currentVersion,
    required String latestVersion,
    required String forceVersion,
  }) {
    if (isNewerThan(currentVersion, forceVersion)) {
      return UpdateStatus.updateRequired;
    }
    if (isNewerThan(currentVersion, latestVersion)) {
      return UpdateStatus.updateRecommended;
    }
    return UpdateStatus.upToDate;
  }
}
