import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/comments_provider.g.dart';

@riverpod
class CommentsNotifier extends _$CommentsNotifier {
  @override
  FutureOr<List<CommentModel>> build(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) async {
    final blockedUserIds = await getBlockedUserIds();
    final comments = await _fetchComments(
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );

    return comments.where((comment) {
      return !blockedUserIds.contains(comment.userId);
    }).toList();
  }

  Future<List<CommentModel>> _fetchComments(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) async {
    final currentUserId = supabase.auth.currentUser?.id;

    try {
      // 루트 댓글 조회를 위한 기본 쿼리
      var rootQuery = supabase.from('comments').select('''
        comment_id,
        parent_comment_id,
        likes,
        replies,
        content,
        locale,
        created_at,
        updated_at,
        deleted_at,
        user_profiles(nickname,avatar_url,created_at,updated_at,deleted_at),
        comment_reports!left(comment_id),
        comment_likes!left(comment_id, user_id, deleted_at),
        post:posts(post_id,board_id,title,created_at,updated_at,deleted_at)
      ''').eq('post_id', postId);

      if (!includeDeleted) rootQuery = rootQuery.isFilter('deleted_at', null);
      if (!includeReported) {
        rootQuery = rootQuery.isFilter('comment_reports', null);
      }

      final rootResponse = await rootQuery
          .isFilter('parent_comment_id', null)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final rootComments = rootResponse.map((row) {
        final comment = CommentModel.fromJson(row);
        final likes = (row['comment_likes'] as List).where((like) =>
            like['user_id'] == currentUserId && like['deleted_at'] == null);

        return comment.copyWith(
          isReportedByMe: row['comment_reports'].length > 0,
          isLikedByMe: likes.isNotEmpty,
        );
      }).toList();

      // 자식 댓글 조회를 위한 별도 쿼리
      final rootCommentIds = rootComments.map((c) => c.commentId).toList();
      if (rootCommentIds.isEmpty) return rootComments;

      var childQuery = supabase.from('comments').select('''
        comment_id,
        parent_comment_id,
        likes,
        replies,
        content,
        locale,
        created_at,
        updated_at,
        deleted_at,
        user_profiles(nickname,avatar_url,created_at,updated_at,deleted_at),
        comment_reports!left(comment_id),
        comment_likes!left(comment_id, user_id, deleted_at),
        post:posts(post_id,board_id,title,created_at,updated_at,deleted_at)
      ''').eq('post_id', postId);

      if (!includeDeleted) childQuery = childQuery.isFilter('deleted_at', null);
      if (!includeReported) {
        childQuery = childQuery.isFilter('comment_reports', null);
      }

      final childResponse = await childQuery
          .inFilter('parent_comment_id', rootCommentIds)
          .order('created_at', ascending: false);

      final childComments = childResponse.map((row) {
        final comment = CommentModel.fromJson(row);
        final likes = (row['comment_likes'] as List).where((like) =>
            like['user_id'] == currentUserId && like['deleted_at'] == null);

        return comment.copyWith(
          isReportedByMe: row['comment_reports'].length > 0,
          isLikedByMe: likes.isNotEmpty,
        );
      }).toList();

      // 댓글 트리 구성
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
      await supabase.from('comment_likes').upsert(
        {
          'comment_id': commentId,
          'user_id': supabase.auth.currentUser!.id,
          'deleted_at': null, // null로 설정하여 삭제 상태 해제
        },
        onConflict: 'comment_id,user_id', // 복합 키로 충돌 처리
      );

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
          .eq('user_id', supabase.auth.currentUser!.id)
          .isFilter('deleted_at', null); // 이미 삭제된 것은 제외

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
    String text, {
    bool blockUser = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final fullReason = reason + (text.isNotEmpty ? ' - $text' : '');

      // 1. 댓글 신고
      await supabase.from('comment_reports').upsert({
        'comment_id': comment.commentId,
        'user_id': userId,
        'reason': fullReason,
      });

      // 2. 사용자 차단 (옵션)
      if (blockUser) {
        await supabase.from('user_blocks').upsert({
          'user_id': userId,
          'blocked_user_id': comment.userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 로컬 상태 업데이트
      if (state.value != null) {
        final updatedComments = state.value!.map((c) {
          if (c.commentId == comment.commentId) {
            return c.copyWith(isReportedByMe: true);
          }
          return c;
        }).toList();

        // 사용자 차단 시 해당 사용자의 모든 댓글을 숨김 처리
        if (blockUser) {
          final filteredComments = updatedComments.where((c) {
            return c.userId != comment.userId;
          }).toList();
          state = AsyncValue.data(filteredComments);
        } else {
          state = AsyncValue.data(updatedComments);
        }
      }
    } catch (e, s) {
      logger.e('Error reporting comment:', error: e, stackTrace: s);
      rethrow;
    }
  }

// 차단된 사용자 목록을 조회하는 메서드 추가
  Future<List<String>> getBlockedUserIds() async {
    try {
      final response = await supabase
          .from('user_blocks')
          .select('blocked_user_id')
          .eq('user_id', supabase.auth.currentUser!.id)
          .isFilter('deleted_at', null);

      return response
          .map<String>((row) => row['blocked_user_id'] as String)
          .toList();
    } catch (e, s) {
      logger.e('Error fetching blocked users:', error: e, stackTrace: s);
      return [];
    }
  }

// 차단 해제하는 메서드 추가
  Future<void> unblockUser(String blockedUserId) async {
    try {
      await supabase
          .from('user_blocks')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('blocked_user_id', blockedUserId);

      // 차단 해제 후 댓글 목록 새로고침
      if (state.value != null) {
        state = await AsyncValue.guard(() => _fetchComments(
              state.value!.first.post!.postId,
              state.value!.length ~/ 10 + 1,
              10,
            ));
      }
    } catch (e, s) {
      logger.e('Error unblocking user:', error: e, stackTrace: s);
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
          .select('''
          *, post:posts(*, boards!inner(board_id,name, artist_id, description)), user:user_profiles!comments_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at)
          ''')
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
