import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from AppBadgeService.
/// Makes badge-related decisions testable without platform dependencies.
class AppBadgeHelper {
  /// Determines the badge update action based on count.
  ///
  /// Returns [BadgeUpdateAction.remove] if count <= 0,
  /// [BadgeUpdateAction.update] if count > 0.
  @visibleForTesting
  static BadgeUpdateAction determineBadgeAction(int count) {
    if (count <= 0) return BadgeUpdateAction.remove;
    return BadgeUpdateAction.update;
  }

  /// Determines if badge operations should proceed based on platform.
  ///
  /// Returns true if the platform supports badge operations (iOS or Android, not web).
  @visibleForTesting
  static bool shouldProceedWithBadge({
    required bool isWeb,
    required bool isIOS,
    required bool isAndroid,
  }) {
    if (isWeb) return false;
    return isIOS || isAndroid;
  }

  /// Determines whether the cached support status should be used.
  /// Returns true if a previous check has been performed.
  @visibleForTesting
  static bool shouldUseCachedSupport({
    required bool checkedSupport,
  }) {
    return checkedSupport;
  }

  /// Calculates the badge count from a list of unread notification rows.
  /// Returns 0 if user is null, otherwise returns the row count.
  @visibleForTesting
  static int calculateBadgeCount({
    required bool hasUser,
    required int rowCount,
  }) {
    if (!hasUser) return 0;
    return rowCount;
  }

  /// Validates badge count value.
  /// Ensures count is not negative.
  @visibleForTesting
  static int normalizeBadgeCount(int count) {
    return count < 0 ? 0 : count;
  }
}

/// Represents the action to take when updating a badge.
enum BadgeUpdateAction {
  /// Remove the badge (count is 0 or negative)
  remove,

  /// Update the badge with a new count
  update,
}
