import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from PostPopupMenu.
/// These methods were private in _PostPopupMenuState but are now testable.
class PostPopupMenuHelper {
  /// Determines whether the current user can delete the given post.
  ///
  /// A post can be deleted if:
  /// - The post's userId matches the current user's id
  /// - The post has not already been deleted (deletedAt is null)
  @visibleForTesting
  static bool canDeletePost({
    required String? postUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    return postUserId == currentUserId &&
        currentUserId != null &&
        deletedAt == null;
  }

  /// Determines whether the current user can report the given post.
  ///
  /// A post can be reported if:
  /// - The post's userId does NOT match the current user's id
  /// - The post has not been deleted (deletedAt is null)
  @visibleForTesting
  static bool canReportPost({
    required String? postUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    return postUserId != currentUserId &&
        currentUserId != null &&
        deletedAt == null;
  }

  /// Returns the list of available menu actions for a post.
  @visibleForTesting
  static List<PostMenuAction> getAvailableActions({
    required String? postUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    final actions = <PostMenuAction>[];

    if (canDeletePost(
      postUserId: postUserId,
      currentUserId: currentUserId,
      deletedAt: deletedAt,
    )) {
      actions.add(PostMenuAction.delete);
    }

    if (canReportPost(
      postUserId: postUserId,
      currentUserId: currentUserId,
      deletedAt: deletedAt,
    )) {
      actions.add(PostMenuAction.report);
    }

    return actions;
  }

  /// Determines the callback result based on the selected menu action.
  /// Returns 'refresh' if refreshFunction should be called after report,
  /// 'delete' if delete action, 'report' if report action, null otherwise.
  @visibleForTesting
  static String? resolveMenuAction({
    required String selectedValue,
    required bool hasReportFunction,
    required bool hasDeleteFunction,
    required bool hasRefreshFunction,
  }) {
    if (selectedValue == 'Report' && hasReportFunction) {
      return hasRefreshFunction ? 'report_and_refresh' : 'report';
    } else if (selectedValue == 'Delete' && hasDeleteFunction) {
      return 'delete';
    }
    return null;
  }
}

/// Enum representing available actions in the post popup menu.
enum PostMenuAction {
  delete,
  report,
}
