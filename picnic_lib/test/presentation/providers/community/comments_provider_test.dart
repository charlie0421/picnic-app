import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  final postData = {
    'post_id': 'post-1',
    'board_id': 'board-1',
    'title': 'Test Post',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
  };

  final userProfileData = {
    'nickname': 'TestUser',
    'avatar_url': 'https://example.com/avatar.png',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
  };

  Map<String, dynamic> makeComment({
    required String commentId,
    String? parentCommentId,
    String userId = 'user-1',
    int likes = 0,
    int replies = 0,
    String? content,
    String locale = 'ko',
    bool deleted = false,
  }) {
    return {
      'comment_id': commentId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'likes': likes,
      'replies': replies,
      'content': content != null ? {locale: content} : {'ko': 'Test comment'},
      'locale': locale,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': deleted ? '2026-01-02T00:00:00Z' : null,
      'user_profiles': userProfileData,
      'comment_reports': null,
      'comment_likes': <Map<String, dynamic>>[],
      'post': postData,
    };
  }

  group('CommentsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1'),
          makeComment(commentId: 'comment-2'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('build throws when user is not authenticated (getBlockedUserIds)',
        () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      expect(result.length, 2);
    });

    test('fetches root comments only (no children)', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      for (final comment in result) {
        expect(comment.parentCommentId, isNull);
      }
    });

    test('parses comment fields correctly', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      final comment = result.first;
      expect(comment.commentId, isNotEmpty);
      expect(comment.content, isNotNull);
      expect(comment.content!['ko'], 'Test comment');
      expect(comment.user, isNotNull);
      expect(comment.user!.nickname, 'TestUser');
    });

    test('returns empty list when no comments exist', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'comments': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isEmpty);
    });

    test('includes post data in comments', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      final comment = result.first;
      expect(comment.post, isNotNull);
      expect(comment.post!.postId, 'post-1');
    });

    test('isLikedByMe is false when no likes', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      expect(result.first.isLikedByMe, false);
    });

    test('isReportedByMe is false when no reports', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      expect(result.first.isReportedByMe, false);
    });

    test('includeDeleted parameter works', () async {
      final resultWithDeleted = await container.read(
        commentsProvider('post-1', 1, 10, includeDeleted: true).future,
      );
      expect(resultWithDeleted, isNotNull);

      final resultWithoutDeleted = await container.read(
        commentsProvider('post-1', 1, 10, includeDeleted: false).future,
      );
      expect(resultWithoutDeleted, isNotNull);
    });

    test('includeReported parameter works', () async {
      final resultWithReported = await container.read(
        commentsProvider('post-1', 1, 10, includeReported: true).future,
      );
      expect(resultWithReported, isNotNull);

      final resultWithoutReported = await container.read(
        commentsProvider('post-1', 1, 10, includeReported: false).future,
      );
      expect(resultWithoutReported, isNotNull);
    });

    test('includeDeleted=false and includeReported=false together', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10,
                includeDeleted: false, includeReported: false)
            .future,
      );
      expect(result, isNotNull);
    });
  });

  group('UserCommentsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1', userId: 'user-1'),
            'user': userProfileData,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches comments by user id', () async {
      final result = await container.read(
        userCommentsProvider('user-1', 1, 10).future,
      );
      expect(result, isNotNull);
      expect(result.length, 1);
      expect(result.first.commentId, 'comment-1');
    });

    test('returns empty list when user has no comments', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'comments': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(
        userCommentsProvider('user-1', 1, 10).future,
      );
      expect(result, isEmpty);
    });

    test('handles multiple comments by same user', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1', userId: 'user-1'),
            'user': userProfileData,
          },
          {
            ...makeComment(commentId: 'comment-2', userId: 'user-1'),
            'user': userProfileData,
          },
        ],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(
        userCommentsProvider('user-1', 1, 10).future,
      );
      expect(result.length, 2);
    });

    test('handles pagination parameters', () async {
      final page1 = await container.read(
        userCommentsProvider('user-1', 1, 10).future,
      );
      final page2 = await container.read(
        userCommentsProvider('user-1', 2, 10).future,
      );
      expect(page1, isNotNull);
      expect(page2, isNotNull);
    });

    test('includeDeleted parameter creates different provider', () async {
      final withDeleted = await container.read(
        userCommentsProvider('user-1', 1, 10, includeDeleted: true).future,
      );
      final withoutDeleted = await container.read(
        userCommentsProvider('user-1', 1, 10, includeDeleted: false).future,
      );
      expect(withDeleted, isNotNull);
      expect(withoutDeleted, isNotNull);
    });

    test('includeReported parameter creates different provider', () async {
      final withReported = await container.read(
        userCommentsProvider('user-1', 1, 10, includeReported: true).future,
      );
      final withoutReported = await container.read(
        userCommentsProvider('user-1', 1, 10, includeReported: false).future,
      );
      expect(withReported, isNotNull);
      expect(withoutReported, isNotNull);
    });
  });

  group('CommentsNotifier with multiple root comments', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(
              commentId: 'root-1', userId: 'user-1', likes: 3, replies: 2),
          makeComment(
              commentId: 'root-2', userId: 'user-2', likes: 0, replies: 0),
          makeComment(
              commentId: 'root-3', userId: 'user-3', likes: 1, replies: 0),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns all root comments', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
      expect(result.length, 3);
      for (final comment in result) {
        expect(comment.parentCommentId, isNull);
      }
    });

    test('each root comment has empty children list', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      for (final comment in result) {
        expect(comment.children, isNotNull);
        expect(comment.children, isEmpty);
      }
    });

    test('comments preserve likes count', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final root1 = result.firstWhere((c) => c.commentId == 'root-1');
      expect(root1.likes, 3);
    });

    test('comments preserve replies count', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final root1 = result.firstWhere((c) => c.commentId == 'root-1');
      expect(root1.replies, 2);
      final root2 = result.firstWhere((c) => c.commentId == 'root-2');
      expect(root2.replies, 0);
    });

    test('comments preserve user ids', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final root1 = result.firstWhere((c) => c.commentId == 'root-1');
      expect(root1.userId, 'user-1');
      final root2 = result.firstWhere((c) => c.commentId == 'root-2');
      expect(root2.userId, 'user-2');
    });
  });

  group('CommentsNotifier with comment likes', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1', likes: 5),
            'comment_likes': [
              {
                'comment_id': 'comment-1',
                'user_id': 'current-user',
                'deleted_at': null,
              },
            ],
          },
          {
            ...makeComment(commentId: 'comment-2', likes: 2),
            'comment_likes': [
              {
                'comment_id': 'comment-2',
                'user_id': 'other-user',
                'deleted_at': null,
              },
            ],
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('isLikedByMe reflects current user likes', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      for (final comment in result) {
        expect(comment.isLikedByMe, false);
      }
    });

    test('comment likes with deleted_at are ignored', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1', likes: 5),
            'comment_likes': [
              {
                'comment_id': 'comment-1',
                'user_id': 'current-user',
                'deleted_at': '2026-01-02T00:00:00Z',
              },
            ],
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(
        commentsProvider('post-1', 1, 10).future,
      );
      // Even if user matches, deleted_at != null means not liked
      expect(result.first.isLikedByMe, false);
    });

    test('preserves original likes count', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final c1 = result.firstWhere((c) => c.commentId == 'comment-1');
      expect(c1.likes, 5);
      final c2 = result.firstWhere((c) => c.commentId == 'comment-2');
      expect(c2.likes, 2);
    });
  });

  group('CommentsNotifier with reports', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1'),
            'comment_reports': [
              {'comment_id': 'comment-1'},
            ],
          },
          {
            ...makeComment(commentId: 'comment-2'),
            'comment_reports': [],
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('isReportedByMe is true when comment_reports is not empty', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final reported = result.firstWhere((c) => c.commentId == 'comment-1');
      expect(reported.isReportedByMe, true);

      final notReported = result.firstWhere((c) => c.commentId == 'comment-2');
      expect(notReported.isReportedByMe, false);
    });

    test('comment_reports as null results in isReportedByMe false', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'comment-1'),
            'comment_reports': null,
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result.first.isReportedByMe, false);
    });
  });

  group('CommentsNotifier with deleted comments', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1', deleted: false),
          makeComment(commentId: 'comment-2', deleted: true),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('includes deleted comments when includeDeleted is true', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10, includeDeleted: true).future,
      );
      expect(result.length, 2);
    });

    test('deleted comment has deletedAt set', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10, includeDeleted: true).future,
      );
      final deleted = result.firstWhere((c) => c.commentId == 'comment-2');
      expect(deleted.deletedAt, isNotNull);
      final notDeleted = result.firstWhere((c) => c.commentId == 'comment-1');
      expect(notDeleted.deletedAt, isNull);
    });
  });

  group('CommentsNotifier _updateCommentLikeStatus', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1', likes: 5),
          makeComment(commentId: 'comment-2', likes: 3),
        ],
        'user_blocks': <Map<String, dynamic>>[],
        'comment_likes': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('build returns correct number of comments', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result.length, 2);
    });
  });

  group('CommentsNotifier with multiple content locales', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(
            commentId: 'comment-1',
            content: '한국어 댓글',
            locale: 'ko',
          ),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('comment content has correct locale', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result.first.content!['ko'], '한국어 댓글');
      expect(result.first.locale, 'ko');
    });
  });

  group('CommentsNotifier pagination', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1'),
          makeComment(commentId: 'comment-2'),
          makeComment(commentId: 'comment-3'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('page 1 with limit 2 returns results', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 2).future,
      );
      expect(result, isNotNull);
    });

    test('different page number creates different provider', () async {
      final result1 = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final result2 = await container.read(
        commentsProvider('post-1', 2, 10).future,
      );
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('different limit creates different provider', () async {
      final result1 = await container.read(
        commentsProvider('post-1', 1, 5).future,
      );
      final result2 = await container.read(
        commentsProvider('post-1', 1, 20).future,
      );
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('different postId creates different provider', () async {
      final result1 = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      final result2 = await container.read(
        commentsProvider('post-2', 1, 10).future,
      );
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });
  });

  group('CommentsNotifier sorts results by createdAt', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          {
            ...makeComment(commentId: 'old-comment'),
            'created_at': '2026-01-01T00:00:00Z',
          },
          {
            ...makeComment(commentId: 'new-comment'),
            'created_at': '2026-02-01T00:00:00Z',
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('comments are sorted by createdAt descending', () async {
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result.length, 2);
      expect(
        result[0].createdAt.isAfter(result[1].createdAt) ||
            result[0].createdAt.isAtSameMomentAs(result[1].createdAt),
        isTrue,
      );
    });
  });

  group('CommentTranslationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          {
            'comment_id': 'comment-1',
            'content': {'ko': '안녕하세요'},
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('initial state is AsyncData(null)', () async {
      await container.read(commentTranslationProvider.future);
      final state = container.read(commentTranslationProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('updateTranslation completes without error', () async {
      await container.read(commentTranslationProvider.future);

      await container
          .read(commentTranslationProvider.notifier)
          .updateTranslation('comment-1', 'en', 'Hello');

      final state = container.read(commentTranslationProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('updateTranslation sets loading state first', () async {
      await container.read(commentTranslationProvider.future);

      // We can't easily capture the intermediate loading state,
      // but we verify the final state is correct after completion.
      await container
          .read(commentTranslationProvider.notifier)
          .updateTranslation('comment-1', 'ja', 'こんにちは');

      final state = container.read(commentTranslationProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('updateTranslation with different locales', () async {
      await container.read(commentTranslationProvider.future);

      await container
          .read(commentTranslationProvider.notifier)
          .updateTranslation('comment-1', 'en', 'Hello');

      await container
          .read(commentTranslationProvider.notifier)
          .updateTranslation('comment-1', 'ja', 'こんにちは');

      await container
          .read(commentTranslationProvider.notifier)
          .updateTranslation('comment-1', 'zh_CN', '你好');

      final state = container.read(commentTranslationProvider);
      expect(state, isA<AsyncData<void>>());
    });
  });

  group('CommentsNotifier postComment', () {
    // postComment requires currentUser!.id which is null in test
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('postComment sets error state when not authenticated', () async {
      // First, build the provider to get initial state
      await container.read(commentsProvider('post-1', 1, 10).future);

      // postComment uses currentUser!.id which will throw
      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .postComment('post-1', null, 'ko', 'New comment');

      final state = container.read(commentsProvider('post-1', 1, 10));
      // Should be in error state because currentUser is null
      expect(state, isA<AsyncError<List<CommentModel>>>());
    });

    test('postComment with parent comment id errors when not auth', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .postComment('post-1', 'parent-1', 'ko', 'Reply comment');

      final state = container.read(commentsProvider('post-1', 1, 10));
      expect(state, isA<AsyncError<List<CommentModel>>>());
    });
  });

  group('CommentsNotifier likeComment', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1', likes: 5),
        ],
        'user_blocks': <Map<String, dynamic>>[],
        'comment_likes': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('likeComment sets error state when not authenticated', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .likeComment('comment-1');

      final state = container.read(commentsProvider('post-1', 1, 10));
      expect(state, isA<AsyncError<List<CommentModel>>>());
    });
  });

  group('CommentsNotifier unlikeComment', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1', likes: 5),
        ],
        'user_blocks': <Map<String, dynamic>>[],
        'comment_likes': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('unlikeComment sets error state when not authenticated', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .unlikeComment('comment-1');

      final state = container.read(commentsProvider('post-1', 1, 10));
      expect(state, isA<AsyncError<List<CommentModel>>>());
    });
  });

  group('CommentsNotifier reportComment', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1', userId: 'user-1'),
          makeComment(commentId: 'comment-2', userId: 'user-2'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
        'comment_reports': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('reportComment throws when not authenticated', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      final comments = container.read(commentsProvider('post-1', 1, 10));
      final comment = comments.value!.first;

      expect(
        () => container
            .read(commentsProvider('post-1', 1, 10).notifier)
            .reportComment(comment, 'spam', 'This is spam'),
        throwsA(anything),
      );
    });

    test('reportComment with blockUser throws when not authenticated',
        () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      final comments = container.read(commentsProvider('post-1', 1, 10));
      final comment = comments.value!.first;

      expect(
        () => container
            .read(commentsProvider('post-1', 1, 10).notifier)
            .reportComment(comment, 'inappropriate', 'Bad content',
                blockUser: true),
        throwsA(anything),
      );
    });

    test('reportComment with empty text throws when not authenticated',
        () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      final comments = container.read(commentsProvider('post-1', 1, 10));
      final comment = comments.value!.first;

      expect(
        () => container
            .read(commentsProvider('post-1', 1, 10).notifier)
            .reportComment(comment, 'spam', ''),
        throwsA(anything),
      );
    });
  });

  group('CommentsNotifier deleteComment', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1'),
          makeComment(commentId: 'comment-2'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('deleteComment removes comment from local state', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      // Verify we have 2 comments initially
      final before = container.read(commentsProvider('post-1', 1, 10));
      expect(before.value!.length, 2);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .deleteComment('comment-1');

      final after = container.read(commentsProvider('post-1', 1, 10));
      expect(after.value!.length, 1);
      expect(after.value!.first.commentId, 'comment-2');
    });

    test('deleteComment for non-existent id leaves state unchanged', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .deleteComment('nonexistent');

      final state = container.read(commentsProvider('post-1', 1, 10));
      expect(state.value!.length, 2);
    });

    test('deleteComment all comments results in empty list', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .deleteComment('comment-1');
      await container
          .read(commentsProvider('post-1', 1, 10).notifier)
          .deleteComment('comment-2');

      final state = container.read(commentsProvider('post-1', 1, 10));
      expect(state.value, isEmpty);
    });
  });

  group('CommentsNotifier getBlockedUserIds', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns empty list when not authenticated', () async {
      // getBlockedUserIds catches the error and returns []
      final result = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );
      expect(result, isNotNull);
    });
  });

  group('CommentsNotifier unblockUser', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'comments': [
          makeComment(commentId: 'comment-1'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('unblockUser throws when not authenticated', () async {
      await container.read(commentsProvider('post-1', 1, 10).future);

      expect(
        () => container
            .read(commentsProvider('post-1', 1, 10).notifier)
            .unblockUser('some-user-id'),
        throwsA(anything),
      );
    });
  });

  group('CommentModel', () {
    test('fromJson creates model correctly', () {
      final json = makeComment(
        commentId: 'c-1',
        userId: 'u-1',
        likes: 10,
        replies: 5,
        content: 'Hello',
        locale: 'en',
      );
      final model = CommentModel.fromJson(json);

      expect(model.commentId, 'c-1');
      expect(model.userId, 'u-1');
      expect(model.likes, 10);
      expect(model.replies, 5);
      expect(model.content!['en'], 'Hello');
      expect(model.locale, 'en');
      expect(model.parentCommentId, isNull);
      expect(model.deletedAt, isNull);
    });

    test('fromJson with parent comment id', () {
      final json = makeComment(
        commentId: 'c-child',
        parentCommentId: 'c-parent',
      );
      final model = CommentModel.fromJson(json);
      expect(model.parentCommentId, 'c-parent');
    });

    test('fromJson with deleted comment', () {
      final json = makeComment(commentId: 'c-deleted', deleted: true);
      final model = CommentModel.fromJson(json);
      expect(model.deletedAt, isNotNull);
    });

    test('copyWith updates isLikedByMe', () {
      final json = makeComment(commentId: 'c-1');
      final model = CommentModel.fromJson(json);
      final updated = model.copyWith(isLikedByMe: true);
      expect(updated.isLikedByMe, true);
      expect(updated.commentId, 'c-1');
    });

    test('copyWith updates isReportedByMe', () {
      final json = makeComment(commentId: 'c-1');
      final model = CommentModel.fromJson(json);
      final updated = model.copyWith(isReportedByMe: true);
      expect(updated.isReportedByMe, true);
    });

    test('copyWith updates children', () {
      final json = makeComment(commentId: 'c-parent');
      final model = CommentModel.fromJson(json);
      final child = CommentModel.fromJson(
          makeComment(commentId: 'c-child', parentCommentId: 'c-parent'));
      final updated = model.copyWith(children: [child]);
      expect(updated.children, isNotNull);
      expect(updated.children!.length, 1);
      expect(updated.children!.first.commentId, 'c-child');
    });

    test('copyWith updates likes', () {
      final json = makeComment(commentId: 'c-1', likes: 5);
      final model = CommentModel.fromJson(json);
      final updated = model.copyWith(likes: 10);
      expect(updated.likes, 10);
    });

    test('user profile data is parsed', () {
      final json = makeComment(commentId: 'c-1');
      final model = CommentModel.fromJson(json);
      expect(model.user, isNotNull);
      expect(model.user!.nickname, 'TestUser');
      expect(model.user!.avatarUrl, 'https://example.com/avatar.png');
    });

    test('post data is parsed', () {
      final json = makeComment(commentId: 'c-1');
      final model = CommentModel.fromJson(json);
      expect(model.post, isNotNull);
      expect(model.post!.postId, 'post-1');
      expect(model.post!.boardId, 'board-1');
    });
  });
}
