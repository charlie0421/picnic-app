import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/common/comment.dart';

/// Pure helper methods extracted from CommentsNotifier for testability.
/// All methods are static and pure — no async, no Supabase, no Riverpod ref.
class CommentsProviderHelper {
  /// Parse a raw comment JSON row into a [CommentModel] with isLikedByMe
  /// and isReportedByMe flags set based on the current user.
  @visibleForTesting
  static CommentModel parseCommentRow(
    Map<String, dynamic> row,
    String? currentUserId,
  ) {
    final comment = CommentModel.fromJson(row);
    final commentLikes = row['comment_likes'] as List? ?? [];
    final likes = commentLikes.where((like) =>
        like['user_id'] == currentUserId && like['deleted_at'] == null);
    final commentReports = row['comment_reports'] as List? ?? [];

    return comment.copyWith(
      isReportedByMe: commentReports.isNotEmpty,
      isLikedByMe: likes.isNotEmpty,
    );
  }

  /// Build a comment tree from flat lists of root and child comments.
  ///
  /// Returns root comments with their children nested, sorted by
  /// createdAt descending.
  @visibleForTesting
  static List<CommentModel> buildCommentTree(
    List<CommentModel> rootComments,
    List<CommentModel> childComments,
  ) {
    final Map<String, CommentModel> commentMap = {};
    for (var comment in [...rootComments, ...childComments]) {
      if (comment.parentCommentId == null) {
        commentMap[comment.commentId] = comment.copyWith(children: []);
      } else {
        final parentComment = commentMap[comment.parentCommentId];
        if (parentComment != null) {
          final updatedReplies = [...parentComment.children!, comment];
          commentMap[parentComment.commentId] =
              parentComment.copyWith(children: updatedReplies);
        }
      }
    }

    final result = rootComments
        .map((comment) => commentMap[comment.commentId]!)
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  /// Filter out comments from blocked users.
  @visibleForTesting
  static List<CommentModel> filterBlockedUsers(
    List<CommentModel> comments,
    List<String> blockedUserIds,
  ) {
    return comments.where((comment) {
      return !blockedUserIds.contains(comment.userId);
    }).toList();
  }

  /// Mark a specific comment as reported by the current user.
  @visibleForTesting
  static List<CommentModel> markCommentAsReported(
    List<CommentModel> comments,
    String commentId,
  ) {
    return comments.map((c) {
      if (c.commentId == commentId) {
        return c.copyWith(isReportedByMe: true);
      }
      return c;
    }).toList();
  }

  /// Filter out all comments by a specific user (used after blocking).
  @visibleForTesting
  static List<CommentModel> filterCommentsByUserId(
    List<CommentModel> comments,
    String userId,
  ) {
    return comments.where((c) => c.userId != userId).toList();
  }

  /// Remove a comment by its ID from the list.
  @visibleForTesting
  static List<CommentModel> removeComment(
    List<CommentModel> comments,
    String commentId,
  ) {
    return comments.where((c) => c.commentId != commentId).toList();
  }
}
