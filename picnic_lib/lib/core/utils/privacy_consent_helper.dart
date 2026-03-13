import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from PrivacyConsentManager.
/// Platform-dependent methods remain in PrivacyConsentManager; this helper
/// provides testable decision-making logic.
class PrivacyConsentHelper {
  /// Determines if personalized ads can be shown based on ATT and UMP statuses.
  ///
  /// [attAuthorized] - whether App Tracking Transparency is authorized
  /// [umpStatus] - the UMP consent status string ('obtained', 'notRequired', etc.)
  @visibleForTesting
  static bool canShowPersonalizedAds({
    required bool attAuthorized,
    required String umpStatus,
  }) {
    return attAuthorized &&
        (umpStatus == 'obtained' || umpStatus == 'notRequired');
  }

  /// Determines if the ATT consent was granted.
  ///
  /// [status] - the TrackingStatus string representation
  @visibleForTesting
  static bool isAttAuthorized(String status) {
    return status == 'authorized';
  }

  /// Determines if ATT consent needs to be requested.
  ///
  /// [status] - the TrackingStatus string representation
  @visibleForTesting
  static bool shouldRequestAttConsent(String status) {
    return status == 'notDetermined';
  }

  /// Determines whether ads should be initialized as non-personalized.
  ///
  /// Non-personalized ads are used when:
  /// - ATT is not authorized, OR
  /// - UMP consent is neither obtained nor notRequired
  @visibleForTesting
  static bool shouldUseNonPersonalizedAds({
    required bool attAuthorized,
    required String umpStatus,
  }) {
    return !attAuthorized ||
        (umpStatus != 'obtained' && umpStatus != 'notRequired');
  }

  /// Determines the initialization flow based on platform.
  ///
  /// Returns the ordered steps for privacy consent initialization.
  /// iOS: ATT first, then UMP, then AdMob
  /// Android: UMP first, then ATT, then AdMob
  @visibleForTesting
  static List<String> getInitializationOrder({required bool isIOS}) {
    if (isIOS) {
      return ['att', 'ump', 'admob'];
    }
    return ['ump', 'att', 'admob'];
  }

  /// Determines if platform supports mobile ad features.
  @visibleForTesting
  static bool isPlatformSupported({
    required bool isWeb,
    required bool isIOS,
    required bool isAndroid,
  }) {
    if (isWeb) return false;
    return isIOS || isAndroid;
  }
}
