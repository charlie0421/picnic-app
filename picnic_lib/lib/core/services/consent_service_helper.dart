import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from ConsentService.
/// Platform-dependent methods remain in ConsentService; this helper
/// provides testable decision logic.
class ConsentServiceHelper {
  /// Determines if GDPR is applicable based on a consent status string.
  /// GDPR applies if status is 'required' or 'obtained'.
  @visibleForTesting
  static bool isGdprApplicableForStatus(String status) {
    return status == 'required' || status == 'obtained';
  }

  /// Determines if a consent form needs to be shown.
  /// A form is needed when it is available AND the status is 'required'.
  @visibleForTesting
  static bool shouldShowConsentForm({
    required bool isFormAvailable,
    required String consentStatus,
  }) {
    return isFormAvailable && consentStatus == 'required';
  }

  /// Determines if privacy options form should be shown.
  /// Only required when the privacy options requirement status is 'required'.
  @visibleForTesting
  static bool shouldShowPrivacyOptionsForm(String requirementStatus) {
    return requirementStatus == 'required';
  }

  /// Determines if initialization should proceed.
  /// Returns false if already initialized and a completer exists.
  @visibleForTesting
  static bool shouldInitialize({
    required bool isInitialized,
    required bool hasCompleter,
  }) {
    return !(isInitialized && hasCompleter);
  }

  /// Returns descriptive label for a consent status string.
  @visibleForTesting
  static String getConsentStatusLabel(String status) {
    switch (status) {
      case 'required':
        return 'Consent Required';
      case 'obtained':
        return 'Consent Obtained';
      case 'notRequired':
        return 'Consent Not Required';
      case 'unknown':
        return 'Unknown Status';
      default:
        return 'Unrecognized: $status';
    }
  }
}
