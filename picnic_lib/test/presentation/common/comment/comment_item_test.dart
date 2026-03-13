import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/common/comment/comment_item.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

CommentModel _createComment({
  String commentId = 'c-1',
  String? nickname = 'TestUser',
  String? avatarUrl,
  int likes = 5,
  int replies = 2,
  Map<String, dynamic>? content,
  bool? isLikedByMe = false,
  bool? isBlindedByAdmin = false,
  String? locale = 'ko',
  String? parentCommentId,
  List<CommentModel>? children,
}) {
  return CommentModel(
    commentId: commentId,
    children: children,
    myLike: null,
    user: nickname != null
        ? UserProfilesModel(
            id: 'u1',
            nickname: nickname,
            avatarUrl: avatarUrl,
            isAdmin: null,
            starCandy: null,
            starCandyBonus: null,
            jmaCandy: null,
          )
        : null,
    likes: likes,
    replies: replies,
    content: content ?? {'ko': 'test comment content'},
    isLikedByMe: isLikedByMe,
    isReportedByMe: false,
    isBlindedByAdmin: isBlindedByAdmin,
    isRepliedByMe: false,
    post: null,
    locale: locale,
    parentCommentId: parentCommentId,
    createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommentItem', () {
    testWidgets('renders with basic comment data',
        (WidgetTester tester) async {
      final comment = _createComment();
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with shouldHighlight true',
        (WidgetTester tester) async {
      final comment = _createComment();
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
            shouldHighlight: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with showReplyButton false',
        (WidgetTester tester) async {
      final comment = _createComment();
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
            showReplyButton: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with null user (anonymous comment)',
        (WidgetTester tester) async {
      final comment = _createComment(nickname: null);
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with liked comment',
        (WidgetTester tester) async {
      final comment = _createComment(isLikedByMe: true, likes: 10);
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with multilingual content',
        (WidgetTester tester) async {
      final comment = _createComment(
        content: {'ko': '안녕하세요', 'en': 'Hello'},
        locale: 'ko',
      );
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with zero likes and replies',
        (WidgetTester tester) async {
      final comment = _createComment(likes: 0, replies: 0);
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with callbacks provided',
        (WidgetTester tester) async {
      final comment = _createComment();
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
            onLike: () {},
            onDelete: () {},
            onReport: (reason, text) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with blinded comment',
        (WidgetTester tester) async {
      final comment = _createComment(isBlindedByAdmin: true);
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });

    testWidgets('renders with parent comment id (reply)',
        (WidgetTester tester) async {
      final comment = _createComment(parentCommentId: 'parent-1');
      final pagingController = PagingController<int, CommentModel>(
        getNextPageKey: (state) => null,
        fetchPage: (_) async => [],
      );

      await tester.pumpWidget(
        buildTestApp(
          CommentItem(
            postId: 'post-1',
            commentModel: comment,
            pagingController: pagingController,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentItem), findsOneWidget);
      pagingController.dispose();
    });
  });
}
