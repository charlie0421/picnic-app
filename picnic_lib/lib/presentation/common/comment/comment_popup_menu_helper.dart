import 'package:flutter/foundation.dart';

/// Helper class containing extracted pure logic from CommentPopupMenu.
/// These methods were private in _CommentPopupMenuState but are now testable.
class CommentPopupMenuHelper {
  /// Determines whether the current user can delete the given comment.
  ///
  /// A comment can be deleted if:
  /// - The comment's userId matches the current user's id
  /// - The comment has not already been deleted (deletedAt is null)
  @visibleForTesting
  static bool canDeleteComment({
    required String? commentUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    return commentUserId == currentUserId &&
        currentUserId != null &&
        deletedAt == null;
  }

  /// Determines whether the current user can report the given comment.
  ///
  /// A comment can be reported if:
  /// - The comment's userId does NOT match the current user's id
  /// - The comment has not been deleted (deletedAt is null)
  @visibleForTesting
  static bool canReportComment({
    required String? commentUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    return commentUserId != currentUserId &&
        currentUserId != null &&
        deletedAt == null;
  }

  /// Returns the list of available menu actions for a comment.
  /// This is useful for determining which popup menu items to show.
  @visibleForTesting
  static List<CommentMenuAction> getAvailableActions({
    required String? commentUserId,
    required String? currentUserId,
    required DateTime? deletedAt,
  }) {
    final actions = <CommentMenuAction>[];

    if (canDeleteComment(
      commentUserId: commentUserId,
      currentUserId: currentUserId,
      deletedAt: deletedAt,
    )) {
      actions.add(CommentMenuAction.delete);
    }

    if (canReportComment(
      commentUserId: commentUserId,
      currentUserId: currentUserId,
      deletedAt: deletedAt,
    )) {
      actions.add(CommentMenuAction.report);
    }

    return actions;
  }
}

/// Enum representing available actions in the comment popup menu.
enum CommentMenuAction {
  delete,
  report,
}
