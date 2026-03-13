import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/common/comment.dart';

/// Helper for updating comment like status in a comment tree.
/// Extracted from CommentsNotifier._updateCommentLikeStatus for testability.
class CommentLikeHelper {
  /// Recursively update the like status of a comment in a comment list.
  ///
  /// Finds the comment with [commentId] and updates its [isLikedByMe] flag
  /// and increments/decrements the [likes] count. Also recurses into children.
  @visibleForTesting
  static List<CommentModel> updateCommentLikeStatus(
    List<CommentModel> comments,
    String commentId,
    bool isLiked,
  ) {
    return comments.map((comment) {
      if (comment.commentId == commentId) {
        return comment.copyWith(
          isLikedByMe: isLiked,
          likes: isLiked ? comment.likes + 1 : comment.likes - 1,
        );
      }
      if (comment.children != null && comment.children!.isNotEmpty) {
        return comment.copyWith(
          children:
              updateCommentLikeStatus(comment.children!, commentId, isLiked),
        );
      }
      return comment;
    }).toList();
  }
}
