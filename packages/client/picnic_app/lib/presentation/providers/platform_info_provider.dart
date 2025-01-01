import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/platform_info_provider.g.dart';

@riverpod
class PlatformInfo extends _$PlatformInfo {
  @override
  Future<PackageInfo> build() async {
    return await _getAppInfo();
  }

  Future<PackageInfo> _getAppInfo() async {
    return await PackageInfo.fromPlatform();
  }
}
