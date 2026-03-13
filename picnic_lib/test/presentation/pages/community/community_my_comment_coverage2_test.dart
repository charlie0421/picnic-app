import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_comment.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() async {
    initTestColors();
    await setupMockSupabaseWithAuth(
      {'comments': <dynamic>[]},
      userId: 'test-user-id',
    );
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('CommentListItem render', () {
    testWidgets('renders a comment list item', (WidgetTester tester) async {
      final comment = CommentModel(
        commentId: 'c-1',
        userId: 'u-1',
        children: null,
        myLike: null,
        content: {'ko': '테스트 댓글입니다'},
        locale: 'ko',
        likes: 0,
        replies: 0,
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        parentCommentId: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
        deletedAt: null,
        user: UserProfilesModel(
          id: 'u-1',
          nickname: 'TestUser',
          avatarUrl: null,
          isAdmin: false,
          starCandy: 0,
          starCandyBonus: 0,
          jmaCandy: 0,
        ),
        post: PostModel(
          postId: 'p-1',
          userId: 'u-1',
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
            name: {'ko': '자유게시판'},
            description: null,
            isOfficial: false,
            createdAt: null,
            updatedAt: null,
            artist: null,
            requestMessage: null,
            status: 'approved',
            creatorId: null,
            features: null,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentListItem(
            item: comment,
            onDelete: () {},
            onRefresh: () {},
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(CommentListItem), findsOneWidget);
      expect(find.text('TestUser'), findsOneWidget);
      expect(find.text('자유게시판'), findsOneWidget);
    });
  });

  group('CommentContents render', () {
    testWidgets('renders comment content text', (WidgetTester tester) async {
      final comment = CommentModel(
        commentId: 'c-2',
        userId: 'u-1',
        children: null,
        myLike: null,
        content: {'ko': '짧은 댓글'},
        locale: 'ko',
        likes: 0,
        replies: 0,
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        parentCommentId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
        user: null,
        post: null,
      );

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 300,
            child: CommentContents(item: comment),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders long comment with overflow', (WidgetTester tester) async {
      final longContent = 'A' * 500;
      final comment = CommentModel(
        commentId: 'c-3',
        userId: 'u-1',
        children: null,
        myLike: null,
        content: {'ko': longContent},
        locale: 'ko',
        likes: 0,
        replies: 0,
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        parentCommentId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
        user: null,
        post: null,
      );

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 200,
            child: CommentContents(item: comment),
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(CommentContents), findsOneWidget);
    });
  });

  group('CommunityMyComment page render', () {
    testWidgets('renders empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const CommunityMyComment()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

      expect(find.byType(CommunityMyComment), findsOneWidget);
    });
  });
}
