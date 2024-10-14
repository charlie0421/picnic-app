import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_provider.g.dart';

@riverpod
Future<List<CommentModel>> comments(ref, String postId, int page, int limit,
    {bool includeDeleted = true, bool includeReported = true}) async {
  final currentUserId = supabase.auth.currentUser?.id;
  try {
    var query = supabase.from('comments').select('''
      *,
      comment_likes:comment_likes(count),
      user:user_profiles(*),
      comment_reports!left(comment_id),
      user_likes:comment_likes!left(comment_id),
      post:posts(*)
    ''').eq('post_id', postId);

    if (!includeDeleted) query = query.isFilter('deleted_at', null);
    if (!includeReported) query = query.isFilter('comment_reports', null);

    final rootResponse = await query
        .isFilter('parent_comment_id', null)
        .eq('comment_reports.user_id', currentUserId!)
        .eq('user_likes.user_id', currentUserId)
        .isFilter('user_likes.deleted_at', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    final rootComments = rootResponse.map((row) {
      final comment = CommentModel.fromJson(row);
      return comment.copyWith(
        user: UserProfilesModel.fromJson(row['user']),
        isReportedByUser: row['comment_reports'].length > 0,
        isLiked: row['user_likes'].length > 0,
        likes: (row['comment_likes'] as List).first['count'] as int,
      );
    }).toList();

    final rootCommentIds = rootComments.map((c) => c.commentId).toList();

    final childResponse = await supabase
        .from('comments')
        .select('''
          *,
          comment_likes:comment_likes(count),
          user:user_profiles(*),
          comment_reports!left(comment_id),
          user_likes:comment_likes!left(comment_id)
        ''')
        .eq('post_id', postId)
        .inFilter('parent_comment_id', rootCommentIds)
        .eq('comment_reports.user_id', currentUserId)
        .eq('user_likes.user_id', currentUserId)
        .isFilter('user_likes.deleted_at', null)
        .order('created_at', ascending: true);

    final childComments = childResponse.map((row) {
      final comment = CommentModel.fromJson(row);
      return comment.copyWith(
          user: UserProfilesModel.fromJson(row['user']),
          isReportedByUser: row['comment_reports'].length > 0,
          isLiked: row['user_likes'].length > 0,
          likes: (row['comment_likes'] as List).first['count'] as int);
    }).toList();

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

    final result =
        rootComments.map((comment) => commentMap[comment.commentId]!).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  } catch (e, s) {
    logger.e('Error fetching comments:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<CommentModel>> commentsByUser(
    ref, String userId, int page, int limit,
    {bool includeDeleted = true, bool includeReported = true}) async {
  try {
    final response = await supabase
        .from('comments')
        .select('*, post:posts(*, board:boards(*)), user:user_profiles(*)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) => CommentModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching comments:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> postComment(
    ref, String postId, String? parentId, String content) async {
  try {
    await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
      'parent_comment_id': parentId,
      'content': content,
    });
  } catch (e, s) {
    logger.e('Error posting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> likeComment(ref, String commentId) async {
  try {
    await supabase.from('comment_likes').upsert({
      'comment_id': commentId,
      'user_id': supabase.auth.currentUser!.id,
    });
  } catch (e, s) {
    logger.e('Error liking comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> unlikeComment(ref, String commentId) async {
  try {
    await supabase
        .from('comment_likes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('comment_id', commentId)
        .eq('user_id', supabase.auth.currentUser!.id);
  } catch (e, s) {
    logger.e('Error unliking comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> reportComment(
    ref, CommentModel comment, String reason, String text) async {
  try {
    await supabase.from('comment_reports').upsert({
      'comment_id': comment.commentId,
      'user_id': supabase.auth.currentUser!.id,
      'reason': reason + (text.isNotEmpty ? ' - $text' : ''),
    });
  } catch (e, s) {
    logger.e('Error reporting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> deleteComment(ref, String commentId) async {
  try {
    await supabase.from('comments').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('comment_id', commentId);
  } catch (e, s) {
    logger.e('Error deleting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}
