import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:picnic_app/util/logger.dart';

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
        _supportInfo = const WebPSupportInfo(
          webp: true,
          animatedWebp: true,
        );
        return _supportInfo!;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final List<String> versionParts = iosInfo.systemVersion.split('.');
        final int majorVersion = int.parse(versionParts[0]);

        _supportInfo = WebPSupportInfo(
          webp: majorVersion >= 14,
          animatedWebp: majorVersion >= 14,
        );
        return _supportInfo!;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        final int sdkVersion = androidInfo.version.sdkInt;

        _supportInfo = WebPSupportInfo(
          webp: sdkVersion >= 14,
          animatedWebp: sdkVersion >= 17, // Android 4.2부터 animated WebP 지원
        );
        return _supportInfo!;
      }

      // 기타 플랫폼
      _supportInfo = const WebPSupportInfo(
        webp: false,
        animatedWebp: false,
      );
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
