import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_provider.g.dart';

@riverpod
Future<List<CommentModel>> comments(
    ref, String postId, int page, int limit) async {
  final currentUserId = supabase.auth.currentUser?.id;
  logger.i('Fetching comments for post: $postId, page: $page, limit: $limit');
  try {
    // 1. 사용자가 신고한 댓글 ID 목록 가져오기
    final reportedCommentsResponse = await supabase
        .schema('community')
        .from('comment_reports')
        .select('comment_id')
        .eq('user_id', currentUserId!);

    final reportedCommentIds = reportedCommentsResponse
        .map((row) => row['comment_id'] as String)
        .toSet();

    // 2. 루트 댓글 가져오기
    final rootResponse = await supabase
        .schema('community')
        .from('comments')
        .select('*, comment_likes(count)')
        .eq('post_id', postId)
        .isFilter('parent_comment_id', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    final rootComments = rootResponse.map((row) {
      final comment = CommentModel.fromJson(row);
      return comment.copyWith(
        isReportedByUser: reportedCommentIds.contains(comment.commentId),
        likes: (row['comment_likes'] as List).first['count'] as int,
      );
    }).toList();

    final rootCommentIds = rootComments.map((c) => c.commentId).toList();

    // 3. 자식 댓글 가져오기
    final childResponse = await supabase
        .schema('community')
        .from('comments')
        .select('*, comment_likes(count)')
        .eq('post_id', postId)
        .inFilter('parent_comment_id', rootCommentIds)
        .order('created_at', ascending: true);

    final childComments = childResponse.map((row) {
      final comment = CommentModel.fromJson(row);
      return comment.copyWith(
        isReportedByUser: reportedCommentIds.contains(comment.commentId),
        likes: (row['comment_likes'] as List).first['count'] as int,
      );
    }).toList();

    // 4. 대댓글 수 계산
    final replyCounts = {};
    for (var child in childComments) {
      replyCounts[child.parentCommentId] =
          (replyCounts[child.parentCommentId] ?? 0) + 1;
    }

    // 5. 현재 사용자가 좋아요를 누른 댓글 ID 목록 가져오기
    final likedCommentsResponse = await supabase
        .schema('community')
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', currentUserId)
        .isFilter('deleted_at', null)
        .inFilter('comment_id',
            [...rootCommentIds, ...childComments.map((c) => c.commentId)]);

    final likedCommentIds =
        likedCommentsResponse.map((row) => row['comment_id'] as String).toSet();

    // 6. 모든 댓글의 사용자 ID 수집
    final allComments = [...rootComments, ...childComments];
    final userIds =
        allComments.map((comment) => comment.userId).toSet().toList();

    // 7. 사용자 프로필 정보 가져오기
    final userProfiles =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    // 8. 댓글에 사용자 정보 추가 및 자식 댓글 그룹화
    final Map<String, CommentModel> commentMap = {};

    for (var comment in allComments) {
      final userProfile =
          userProfiles.firstWhere((profile) => profile['id'] == comment.userId);
      final commentWithUser = comment.copyWith(
        user: UserProfilesModel.fromJson(userProfile),
        isLiked: likedCommentIds.contains(comment.commentId),
        replies: replyCounts[comment.commentId] ?? 0,
      );

      if (comment.parentCommentId == null) {
        commentMap[comment.commentId] = commentWithUser.copyWith(children: []);
      } else {
        final parentComment = commentMap[comment.parentCommentId];
        if (parentComment != null) {
          final updatedReplies = [...parentComment.children!, commentWithUser];
          commentMap[parentComment.commentId] =
              parentComment.copyWith(children: updatedReplies);
        }
      }
    }

    // 9. 최종 결과 정렬 및 반환
    final result =
        rootComments.map((comment) => commentMap[comment.commentId]!).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    logger.i('Returned root comments: ${result.length}');
    return result;
  } catch (e, s) {
    logger.e('Error fetching comments:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> postComment(
    ref, String postId, String? parentId, String content) async {
  try {
    final response =
        await supabase.schema('community').from('comments').insert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
      'parent_comment_id': parentId,
      'content': content,
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error posting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> likeComment(ref, String commentId) async {
  logger.d('Liking comment: $commentId');
  try {
    final response =
        await supabase.schema('community').from('comment_likes').upsert({
      'comment_id': commentId,
      'user_id': supabase.auth.currentUser!.id,
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error liking comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> unlikeComment(ref, String commentId) async {
  try {
    final response = await supabase
        .schema('community')
        .from('comment_likes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('comment_id', commentId)
        .eq('user_id', supabase.auth.currentUser!.id);

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error unliking comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> reportComment(
    ref, CommentModel comment, String reason, String text) async {
  try {
    final response =
        await supabase.schema('community').from('comment_reports').upsert({
      'comment_id': comment.commentId,
      'user_id': supabase.auth.currentUser!.id,
      'reason': reason + (text.isNotEmpty ? ' - $text' : ''),
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error reporting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> deleteComment(ref, String commentId) async {
  try {
    final response =
        await supabase.schema('community').from('comments').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('comment_id', commentId);

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error deleting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}
