import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';

/// Helper class containing extracted pure logic from WebPSupportChecker.
/// Makes WebP support determination testable without device dependencies.
class WebPSupportHelper {
  /// Determines WebP support for iOS based on the system version string.
  ///
  /// iOS 14+ supports both static and animated WebP.
  @visibleForTesting
  static WebPSupportInfo determineIOSSupport(String systemVersion) {
    final versionParts = systemVersion.split('.');
    if (versionParts.isEmpty) {
      return const WebPSupportInfo(webp: false, animatedWebp: false);
    }

    final majorVersion = int.tryParse(versionParts[0]);
    if (majorVersion == null) {
      return const WebPSupportInfo(webp: false, animatedWebp: false);
    }

    return WebPSupportInfo(
      webp: majorVersion >= 14,
      animatedWebp: majorVersion >= 14,
    );
  }

  /// Determines WebP support for Android based on SDK version.
  ///
  /// Android SDK 14+ supports static WebP.
  /// Android SDK 17+ (4.2) supports animated WebP.
  @visibleForTesting
  static WebPSupportInfo determineAndroidSupport(int sdkVersion) {
    return WebPSupportInfo(
      webp: sdkVersion >= 14,
      animatedWebp: sdkVersion >= 17,
    );
  }

  /// Returns WebP support info for web platform (always supported).
  @visibleForTesting
  static WebPSupportInfo getWebSupport() {
    return const WebPSupportInfo(webp: true, animatedWebp: true);
  }

  /// Returns WebP support info for unknown platforms.
  @visibleForTesting
  static WebPSupportInfo getUnknownPlatformSupport() {
    return const WebPSupportInfo(webp: false, animatedWebp: false);
  }

  /// Determines if the cached support info should be returned.
  @visibleForTesting
  static bool shouldUseCachedInfo(WebPSupportInfo? cachedInfo) {
    return cachedInfo != null;
  }
}
