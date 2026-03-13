import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_comment.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Coverage-focused tests for CommunityMyComment.
///
/// The main CommunityMyComment page requires supabase.auth.currentUser,
/// so we focus on testing the sub-widgets: CommentContents and CommentListItem.
void main() {
  setUpAll(() {
    initTestColors();
  });

  CommentModel createComment({
    String id = 'c-1',
    String content = '테스트 댓글',
    String locale = 'ko',
    String? nickname = 'TestUser',
    String? avatarUrl,
    int likes = 5,
    int replies = 2,
    String? boardName,
    String? postId,
    DateTime? createdAt,
  }) {
    return CommentModel(
      commentId: id,
      children: null,
      myLike: null,
      user: UserProfilesModel(
        id: 'u1',
        nickname: nickname,
        avatarUrl: avatarUrl,
        isAdmin: false,
        starCandy: 100,
        starCandyBonus: 10,
        jmaCandy: 50,
      ),
      likes: likes,
      replies: replies,
      content: {locale: content},
      isLikedByMe: false,
      isReportedByMe: false,
      isBlindedByAdmin: false,
      isRepliedByMe: false,
      post: postId != null
          ? PostModel(
              postId: postId,
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
                name: {'ko': boardName ?? '게시판'},
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
            )
          : null,
      locale: locale,
      parentCommentId: null,
      createdAt: createdAt ?? DateTime(2025, 6, 15),
      updatedAt: DateTime(2025, 6, 15),
    );
  }

  group('CommentContents widget', () {
    testWidgets('renders short comment text', (tester) async {
      final comment = createComment(content: '짧은 댓글');

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(item: comment),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('짧은 댓글'), findsOneWidget);
    });

    testWidgets('renders comment with different locale', (tester) async {
      final comment = CommentModel(
        commentId: 'c-2',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'en': 'English comment', 'ko': '한국어 댓글'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'en',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(item: comment),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('English comment'), findsOneWidget);
    });

    testWidgets('renders comment with empty content map', (tester) async {
      final comment = CommentModel(
        commentId: 'c-3',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': ''},
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

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(item: comment),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders long comment with overflow', (tester) async {
      final longText = 'A' * 500; // Very long text
      final comment = createComment(content: longText);

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 200,
            child: CommentContents(item: comment),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommentContents), findsOneWidget);
    });
  });

  group('CommentModel data patterns', () {
    test('comment with all boolean flags set', () {
      final comment = CommentModel(
        commentId: 'c-flags',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'ko': 'test'},
        isLikedByMe: true,
        isReportedByMe: true,
        isBlindedByAdmin: true,
        isRepliedByMe: true,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.isLikedByMe, isTrue);
      expect(comment.isReportedByMe, isTrue);
      expect(comment.isBlindedByAdmin, isTrue);
      expect(comment.isRepliedByMe, isTrue);
    });

    test('comment with children', () {
      final child = CommentModel(
        commentId: 'c-child',
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
        parentCommentId: 'c-parent',
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      final parent = CommentModel(
        commentId: 'c-parent',
        children: [child],
        myLike: null,
        user: null,
        likes: 0,
        replies: 1,
        content: {'ko': '부모 댓글'},
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

      expect(parent.children, isNotNull);
      expect(parent.children!.length, 1);
      expect(parent.children![0].parentCommentId, 'c-parent');
    });

    test('comment with myLike null', () {
      final comment = CommentModel(
        commentId: 'c-like',
        children: null,
        myLike: null,
        user: null,
        likes: 5,
        replies: 0,
        content: {'ko': '좋아요 댓글'},
        isLikedByMe: true,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 6, 15),
        updatedAt: DateTime(2025, 6, 15),
      );

      expect(comment.myLike, isNull);
      expect(comment.isLikedByMe, isTrue);
    });

    test('comment user with admin flag', () {
      final user = UserProfilesModel(
        id: 'admin-user',
        nickname: 'Admin',
        avatarUrl: 'https://example.com/avatar.jpg',
        isAdmin: true,
        starCandy: 0,
        starCandyBonus: 0,
        jmaCandy: 0,
      );

      expect(user.isAdmin, isTrue);
      expect(user.avatarUrl, isNotNull);
    });

    test('comment with post reference containing board features', () {
      final comment = createComment(
        postId: 'p-features',
        boardName: '미디어 게시판',
      );

      expect(comment.post, isNotNull);
      expect(comment.post!.board, isNotNull);
      expect(comment.post!.board!.name['ko'], '미디어 게시판');
      expect(comment.post!.board!.features, isEmpty);
    });

    test('comment with empty content map for locale', () {
      final comment = CommentModel(
        commentId: 'c-empty',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'en': 'Only English'},
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

      // Accessing ko locale returns null since only en exists
      expect(comment.content?['ko'], isNull);
      expect(comment.content?['en'], 'Only English');
    });

    test('comment with deletedAt set', () {
      final comment = CommentModel(
        commentId: 'c-deleted',
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
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        deletedAt: DateTime(2025, 6, 15),
      );

      expect(comment.deletedAt, isNotNull);
      expect(comment.deletedAt!.year, 2025);
      expect(comment.deletedAt!.month, 6);
      expect(comment.deletedAt!.day, 15);
    });
  });
}
