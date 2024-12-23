import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_app/models/common/app_version.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:version/version.dart';

part '../generated/providers/update_checker.freezed.dart';
part '../generated/providers/update_checker.g.dart';

enum UpdateStatus { upToDate, updateRecommended, updateRequired }

@freezed
class UpdateInfo with _$UpdateInfo {
  const UpdateInfo._();

  const factory UpdateInfo({
    required UpdateStatus status,
    required String currentVersion,
    required String latestVersion,
    required String forceVersion,
    String? url,
  }) = _UpdateInfo;
}

@riverpod
class UpdateChecker extends _$UpdateChecker {
  @override
  Future<UpdateInfo?> build() async => null;

  Future<void> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final response = await supabase
          .from("version")
          .select()
          .filter('deleted_at', 'is', null)
          .limit(1)
          .single();
      final appVersionModel = AppVersionModel.fromJson(response);
      final platformInfo =
          _getPlatformInfo(appVersionModel, _getPlatformName());

      if (platformInfo == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final latestVersion = platformInfo['version'];
      final forceVersion = platformInfo['force_version'];
      final url = platformInfo['url'];

      if (latestVersion == null || forceVersion == null || url == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final status = _isNewerThan(currentVersion, forceVersion)
          ? UpdateStatus.updateRequired
          : _isNewerThan(currentVersion, latestVersion)
              ? UpdateStatus.updateRecommended
              : UpdateStatus.upToDate;

      state = AsyncValue.data(UpdateInfo(
        status: status,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        forceVersion: forceVersion,
        url: url,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  Map<String, dynamic>? _getPlatformInfo(
      AppVersionModel model, String platformName) {
    return platformName == 'android' ? model.android : model.ios;
  }

  bool _isNewerThan(String currentVersion, String marketVersion) {
    final current = Version.parse(currentVersion);
    final market = Version.parse(marketVersion);

    return market > current;
  }
}
