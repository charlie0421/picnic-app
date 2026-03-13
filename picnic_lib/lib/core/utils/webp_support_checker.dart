import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/webp_support_helper.dart';

class WebPSupportInfo {
  final bool webp;
  final bool animatedWebp;

  const WebPSupportInfo({
    this.webp = false,
    this.animatedWebp = false,
  });
}

class WebPSupportChecker {
  WebPSupportChecker._();

  static final WebPSupportChecker instance = WebPSupportChecker._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  WebPSupportInfo? _supportInfo;

  // 캐시된 지원 정보 반환
  WebPSupportInfo? get supportInfo => _supportInfo;

  // WebP 지원 여부 확인
  Future<WebPSupportInfo> checkSupport() async {
    // 이미 확인된 정보가 있다면 캐시된 정보 반환
    if (_supportInfo != null) {
      return _supportInfo!;
    }

    try {
      if (kIsWeb) {
        _supportInfo = WebPSupportHelper.getWebSupport();
        return _supportInfo!;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _supportInfo =
            WebPSupportHelper.determineIOSSupport(iosInfo.systemVersion);
        return _supportInfo!;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _supportInfo =
            WebPSupportHelper.determineAndroidSupport(androidInfo.version.sdkInt);
        return _supportInfo!;
      }

      // 기타 플랫폼
      _supportInfo = WebPSupportHelper.getUnknownPlatformSupport();
      return _supportInfo!;
    } catch (e, s) {
      logger.e('WebP 지원 확인 중 오류 발생', error: e, stackTrace: s);
      rethrow;
    }
  }

  void reset() {
    _supportInfo = null;
  }
}
