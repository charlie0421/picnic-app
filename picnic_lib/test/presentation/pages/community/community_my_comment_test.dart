import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

/// Tests for CommunityMyComment data patterns and logic.
///
/// Widget rendering tests are limited because CommunityMyComment requires
/// supabase.auth.currentUser (which needs authenticated session) and
/// RouteAwareStateMixin which requires RouteObserver setup.
/// Instead we test the CommentModel and related model patterns
/// that the page depends on.
void main() {
  group('CommentModel for my comments', () {
    test('creates comment with all fields', () {
      final comment = CommentModel(
        commentId: 'c-1',
        children: null,
        myLike: null,
        user: UserProfilesModel(
          id: 'u1',
          nickname: 'TestUser',
          avatarUrl: null,
          isAdmin: false,
          starCandy: 100,
          starCandyBonus: 10,
          jmaCandy: 50,
        ),
        likes: 5,
        replies: 2,
        content: {'ko': '테스트 댓글'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.commentId, 'c-1');
      expect(comment.user?.nickname, 'TestUser');
      expect(comment.likes, 5);
      expect(comment.replies, 2);
      expect(comment.content?['ko'], '테스트 댓글');
      expect(comment.locale, 'ko');
    });

    test('creates comment with post reference', () {
      final post = PostModel(
        postId: 'p-1',
        userId: 'u1',
        userProfiles: null,
        boardId: 'b-1',
        title: '게시글 제목',
        content: null,
        viewCount: 0,
        replyCount: 0,
        isHidden: false,
        isAnonymous: false,
        isScraped: false,
        board: BoardModel(
          boardId: 'b-1',
          artistId: 1,
          name: {'ko': '게시판'},
          description: '설명',
          isOfficial: false,
          createdAt: null,
          updatedAt: null,
          artist: null,
          requestMessage: null,
          status: 'approved',
          creatorId: null,
          features: [],
        ),
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      final comment = CommentModel(
        commentId: 'c-2',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': '댓글'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: post,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.post, isNotNull);
      expect(comment.post!.postId, 'p-1');
      expect(comment.post!.board, isNotNull);
      expect(comment.post!.board!.boardId, 'b-1');
    });

    test('creates comment with parent (reply)', () {
      final comment = CommentModel(
        commentId: 'c-3',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': '대댓글'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: 'c-1',
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.parentCommentId, 'c-1');
    });

    test('creates comment with deleted_at', () {
      final comment = CommentModel(
        commentId: 'c-4',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': '삭제된 댓글'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
        deletedAt: DateTime(2025, 6, 16),
      );

      expect(comment.deletedAt, isNotNull);
      expect(comment.deletedAt!.day, 16);
    });

    test('creates comment with multilingual content', () {
      final comment = CommentModel(
        commentId: 'c-5',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': '한국어', 'en': 'English', 'ja': '日本語'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.content?.length, 3);
      expect(comment.content?['ko'], '한국어');
      expect(comment.content?['en'], 'English');
      expect(comment.content?['ja'], '日本語');
    });
  });

  group('BoardModel for my comments', () {
    test('creates board with all fields', () {
      final board = BoardModel(
        boardId: 'b-1',
        artistId: 42,
        name: {'ko': '자유게시판', 'en': 'Free Board'},
        description: '자유롭게 글을 작성하세요',
        isOfficial: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
        artist: null,
        requestMessage: null,
        status: 'approved',
        creatorId: 'admin',
        features: ['post', 'comment'],
      );

      expect(board.boardId, 'b-1');
      expect(board.artistId, 42);
      expect(board.name['ko'], '자유게시판');
      expect(board.isOfficial, true);
      expect(board.status, 'approved');
      expect(board.features?.length, 2);
    });
  });
}
