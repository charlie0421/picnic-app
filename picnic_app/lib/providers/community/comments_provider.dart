import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_provider.g.dart';

@riverpod
class CommentsNotifier extends _$CommentsNotifier {
  @override
  FutureOr<List<CommentModel>> build(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) {
    return _fetchComments(
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  Future<List<CommentModel>> _fetchComments(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return [];
    }
    try {
      var query = supabase.from('comments').select('''
        comment_id,parent_comment_id,likes,replies,content,locale,created_at,updated_at,deleted_at,
        user_profiles(nickname,avatar_url,created_at,updated_at,deleted_at),
        comment_reports!left(comment_id),
        comment_likes!left(comment_id),
        post:posts(post_id,board_id,title,created_at,updated_at,deleted_at)
      ''').eq('post_id', postId);

      if (!includeDeleted) query = query.isFilter('deleted_at', null);
      if (!includeReported) query = query.isFilter('comment_reports', null);

      final rootResponse = await query
          .isFilter('parent_comment_id', null)
          .eq('comment_reports.user_id', currentUserId)
          .eq('comment_likes.user_id', currentUserId)
          .isFilter('comment_likes.deleted_at', null)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final rootComments = rootResponse.map((row) {
        final comment = CommentModel.fromJson(row);
        return comment.copyWith(
          isReportedByMe: row['comment_reports'].length > 0,
          isLikedByMe: row['comment_likes'].length > 0,
        );
      }).toList();

      final rootCommentIds = rootComments.map((c) => c.commentId).toList();

      final childResponse = await supabase
          .from('comments')
          .select('''
        comment_id,parent_comment_id,likes,replies,content,locale,created_at,updated_at,deleted_at,
        user_profiles(nickname,avatar_url,created_at,updated_at,deleted_at),
        comment_reports!left(comment_id),
        comment_likes!left(comment_id),
        post:posts(post_id,board_id,title,created_at,updated_at,deleted_at)
          ''')
          .eq('post_id', postId)
          .inFilter('parent_comment_id', rootCommentIds)
          .eq('comment_reports.user_id', currentUserId)
          .eq('comment_likes.user_id', currentUserId)
          .isFilter('comment_likes.deleted_at', null)
          .order('created_at', ascending: true);

      final childComments = childResponse.map((row) {
        final comment = CommentModel.fromJson(row);
        return comment.copyWith(
          isReportedByMe: row['comment_reports'].length > 0,
          isLikedByMe: row['comment_likes'].length > 0,
        );
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

      final result = rootComments
          .map((comment) => commentMap[comment.commentId]!)
          .toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return result;
    } catch (e, s) {
      logger.e('Error fetching comments:', error: e, stackTrace: s);
      return Future.error(e);
    }
  }

  Future<void> postComment(
    String postId,
    String? parentId,
    String locale,
    String content,
  ) async {
    state = const AsyncLoading();

    try {
      await supabase.from('comments').insert({
        'post_id': postId,
        'user_id': supabase.auth.currentUser!.id,
        'parent_comment_id': parentId,
        'locale': locale,
        'content': {locale: content},
      });

      // Refresh comments after posting
      state = await AsyncValue.guard(() => _fetchComments(
            postId,
            state.value!.length ~/ 10 + 1,
            10,
          ));
    } catch (e, s) {
      logger.e('Error posting comment:', error: e, stackTrace: s);
      state = AsyncError(e, s);
    }
  }

  Future<void> likeComment(String commentId) async {
    state = const AsyncLoading();
    try {
      await supabase.from('comment_likes').upsert({
        'comment_id': commentId,
        'user_id': supabase.auth.currentUser!.id,
      });

      // Update the local state to reflect the like
      if (state.value != null) {
        state = AsyncValue.data(
            _updateCommentLikeStatus(state.value!, commentId, true));
      }
    } catch (e, s) {
      logger.e('Error liking comment:', error: e, stackTrace: s);
      state = AsyncError(e, s);
    }
  }

  Future<void> unlikeComment(String commentId) async {
    state = const AsyncLoading();
    try {
      await supabase
          .from('comment_likes')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('comment_id', commentId)
          .eq('user_id', supabase.auth.currentUser!.id);

      // Update the local state to reflect the unlike
      if (state.value != null) {
        state = AsyncValue.data(
            _updateCommentLikeStatus(state.value!, commentId, false));
      }
    } catch (e, s) {
      logger.e('Error unliking comment:', error: e, stackTrace: s);
      state = AsyncError(e, s);
    }
  }

  List<CommentModel> _updateCommentLikeStatus(
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
              _updateCommentLikeStatus(comment.children!, commentId, isLiked),
        );
      }
      return comment;
    }).toList();
  }

  Future<void> reportComment(
    CommentModel comment,
    String reason,
    String text,
  ) async {
    try {
      await supabase.from('comment_reports').upsert({
        'comment_id': comment.commentId,
        'user_id': supabase.auth.currentUser!.id,
        'reason': reason + (text.isNotEmpty ? ' - $text' : ''),
      });

      // Update local state to reflect the report
      if (state.value != null) {
        final updatedComments = state.value!.map((c) {
          if (c.commentId == comment.commentId) {
            return c.copyWith(isReportedByMe: true);
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedComments);
      }
    } catch (e, s) {
      logger.e('Error reporting comment:', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await supabase.from('comments').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('comment_id', commentId);

      // Remove the comment from local state
      if (state.value != null) {
        final updatedComments =
            state.value!.where((c) => c.commentId != commentId).toList();
        state = AsyncValue.data(updatedComments);
      }
    } catch (e, s) {
      logger.e('Error deleting comment:', error: e, stackTrace: s);
      rethrow;
    }
  }
}

@riverpod
class UserCommentsNotifier extends _$UserCommentsNotifier {
  @override
  FutureOr<List<CommentModel>> build(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) async {
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
}

@riverpod
class CommentTranslationNotifier extends _$CommentTranslationNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> updateTranslation(
    String commentId,
    String locale,
    String translatedText,
  ) async {
    state = const AsyncLoading();
    try {
      logger.i(
          'commentId: $commentId, locale: $locale, translatedText: $translatedText');
      final response = await supabase
          .from('comments')
          .select('content')
          .eq('comment_id', commentId)
          .single();

      final content = response['content'] as Map<String, dynamic>? ?? {};
      content[locale] = translatedText;

      await supabase.from('comments').update({
        'content': content,
      }).eq('comment_id', commentId);

      state = const AsyncData(null);
    } catch (e, s) {
      logger.e('Error updating comment translation:', error: e, stackTrace: s);
      state = AsyncError(e, s);
    }
  }
}
