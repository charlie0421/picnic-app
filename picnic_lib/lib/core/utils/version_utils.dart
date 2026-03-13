import 'package:flutter/foundation.dart';

/// Utility class for version parsing and comparison.
/// Extracted from ShorebirdUtils for testability.
class VersionUtils {
  /// Parse the major version number from a version string like "26.2" or "18.4".
  ///
  /// Returns 0 if parsing fails.
  @visibleForTesting
  static int parseMajorVersion(String versionString) {
    return int.tryParse(versionString.split('.').first) ?? 0;
  }

  /// Check if the given iOS version is 26 or higher.
  @visibleForTesting
  static bool isIOSVersionAtLeast26(String systemVersion) {
    final majorVersion = parseMajorVersion(systemVersion);
    return majorVersion >= 26;
  }

  /// Check if the given iOS version is at least [minimumMajor].
  @visibleForTesting
  static bool isIOSVersionAtLeast(String systemVersion, int minimumMajor) {
    final majorVersion = parseMajorVersion(systemVersion);
    return majorVersion >= minimumMajor;
  }
}
