import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from AppLifecycleInitializer.
/// Makes the URI handling and validation logic testable without Riverpod.
class AppLifecycleHelper {
  /// App URI scheme constant
  static const String appUriScheme = 'picnic';

  /// Classifies a URI into an action type for the app to handle.
  ///
  /// Returns [BranchUriAction.deeplink] if the URI matches the app scheme,
  /// [BranchUriAction.unsupported] if the scheme doesn't match,
  /// or [BranchUriAction.ignore] if the URI is null.
  @visibleForTesting
  static BranchUriAction classifyBranchUri(Uri? uri) {
    if (uri == null) return BranchUriAction.ignore;
    if (uri.scheme == appUriScheme) return BranchUriAction.deeplink;
    return BranchUriAction.unsupported;
  }

  /// Validates whether a URI is a valid app deep link.
  @visibleForTesting
  static bool isAppDeepLink(Uri? uri) {
    return classifyBranchUri(uri) == BranchUriAction.deeplink;
  }

  /// Extracts the path from a valid app deep link URI.
  /// Returns null if the URI is not a valid app deep link.
  @visibleForTesting
  static String? extractDeepLinkPath(Uri? uri) {
    if (!isAppDeepLink(uri)) return null;
    return uri!.path;
  }

  /// Validates route map configuration.
  /// Returns true if the routes map is valid (non-empty).
  @visibleForTesting
  static bool isValidRouteMap(Map<String, dynamic> routes) {
    return routes.isNotEmpty;
  }

  /// Returns the number of routes in the configuration.
  @visibleForTesting
  static int getRouteCount(Map<String, dynamic> routes) {
    return routes.length;
  }
}

/// Represents the classification of a Branch URI.
enum BranchUriAction {
  /// URI matches the app scheme and should be handled as a deep link
  deeplink,

  /// URI has an unsupported scheme
  unsupported,

  /// URI is null and should be ignored
  ignore,
}
