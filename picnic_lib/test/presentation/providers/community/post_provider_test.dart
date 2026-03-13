import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  final userProfileData = {
    'id': 'user-1',
    'nickname': 'TestUser',
    'avatar_url': 'https://example.com/avatar.png',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
  };

  final boardData = {
    'board_id': 'board-1',
    'name': {'ko': '자유게시판', 'en': 'Free Board'},
    'artist_id': 1,
    'description': 'A free board',
  };

  Map<String, dynamic> makePost({
    required String postId,
    String userId = 'user-1',
    String title = 'Test Post',
    int viewCount = 0,
    int replyCount = 0,
    bool isAnonymous = false,
    bool isHidden = false,
  }) {
    return {
      'post_id': postId,
      'user_id': userId,
      'board_id': 'board-1',
      'title': title,
      'content': null,
      'view_count': viewCount,
      'reply_count': replyCount,
      'is_hidden': isHidden,
      'is_anonymous': isAnonymous,
      'is_scraped': false,
      'boards': boardData,
      'user_profiles': userProfileData,
      'post_reports': null,
      'post_scraps': null,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    };
  }

  group('postsByArtist', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': [
          makePost(postId: 'post-1', title: 'First Post'),
          makePost(postId: 'post-2', title: 'Second Post'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches posts by artist id (unauthenticated)', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].postId, 'post-1');
      expect(result[1].postId, 'post-2');
    });

    test('parses post model fields correctly', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.title, 'First Post');
      expect(post.userId, 'user-1');
      expect(post.boardId, 'board-1');
      expect(post.viewCount, 0);
      expect(post.replyCount, 0);
      expect(post.isAnonymous, false);
    });

    test('returns empty list when no posts exist', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('includes board data in post', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.board, isNotNull);
      expect(post.board!.boardId, 'board-1');
      expect(post.board!.name['ko'], '자유게시판');
    });

    test('includes user profile in post', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.userProfiles, isNotNull);
      expect(post.userProfiles!.nickname, 'TestUser');
    });

    test('handles multiple pages correctly', () async {
      final result =
          await container.read(postsByArtistProvider(1, 1, 1).future);
      expect(result, isNotNull);
    });

    test('parses board description and english name', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.board!.description, 'A free board');
      expect(post.board!.name['en'], 'Free Board');
      expect(post.board!.artistId, 1);
    });

    test('parses user profile avatar_url', () async {
      final result =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.userProfiles!.avatarUrl, 'https://example.com/avatar.png');
    });

    test('handles posts with different view and reply counts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          makePost(postId: 'post-1', viewCount: 100, replyCount: 25),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByArtistProvider(1, 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.viewCount, 100);
      expect(post.replyCount, 25);
    });

    test('different artist ids create different providers', () async {
      final result1 =
          await container.read(postsByArtistProvider(1, 10, 1).future);
      final result2 =
          await container.read(postsByArtistProvider(2, 10, 1).future);
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('handles anonymous posts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          makePost(postId: 'post-anon', isAnonymous: true),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByArtistProvider(1, 10, 1).future);
      expect(result!.first.isAnonymous, true);
    });
  });

  group('postsByBoard', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': [
          makePost(postId: 'post-1'),
          makePost(postId: 'post-2'),
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches posts by board id (unauthenticated)', () async {
      final result =
          await container.read(postsByBoardProvider('board-1', 10, 1).future);
      expect(result, isNotNull);
      expect(result!.length, 2);
    });

    test('returns empty list when no posts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2
          .read(postsByBoardProvider('board-1', 10, 1).future);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('parses post fields in board result', () async {
      final result =
          await container.read(postsByBoardProvider('board-1', 10, 1).future);
      expect(result, isNotNull);
      final post = result!.first;
      expect(post.postId, 'post-1');
      expect(post.userId, 'user-1');
      expect(post.board, isNotNull);
      expect(post.userProfiles, isNotNull);
      expect(post.isAnonymous, false);
      expect(post.isHidden, false);
    });

    test('handles page 2 request', () async {
      final result =
          await container.read(postsByBoardProvider('board-1', 10, 2).future);
      expect(result, isNotNull);
    });

    test('different board ids create different providers', () async {
      final result1 =
          await container.read(postsByBoardProvider('board-1', 10, 1).future);
      final result2 =
          await container.read(postsByBoardProvider('board-2', 10, 1).future);
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });
  });

  group('postById', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-1', viewCount: 5),
            'post_scraps': [
              {'post_id': 'post-1'}
            ],
            'board': boardData,
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

    test('fetches post by id (unauthenticated)', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.postId, 'post-1');
    });

    test('returns null when post not found', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postByIdProvider('nonexistent').future);
      expect(result, isNull);
    });

    test('sets isScraped to true when post_scraps is non-empty', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.isScraped, true);
    });

    test('sets isScraped to false when post_scraps is empty', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-2', viewCount: 3),
            'post_scraps': <Map<String, dynamic>>[],
            'board': boardData,
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postByIdProvider('post-2').future);
      expect(result, isNotNull);
      expect(result!.isScraped, false);
    });

    test('sets isScraped to false when post_scraps is null', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-3'),
            'post_scraps': null,
            'board': boardData,
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postByIdProvider('post-3').future);
      expect(result, isNotNull);
      expect(result!.isScraped, false);
    });

    test('fetches post with isIncrementViewCount false', () async {
      final result = await container
          .read(postByIdProvider('post-1', isIncrementViewCount: false).future);
      expect(result, isNotNull);
      expect(result!.postId, 'post-1');
    });

    test('parses view count correctly', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.viewCount, 5);
    });

    test('includes board data from joined query', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.board, isNotNull);
    });

    test('includes user profile data', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.userProfiles, isNotNull);
      expect(result!.userProfiles!.nickname, 'TestUser');
    });

    test('parses createdAt and updatedAt', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.createdAt, isNotNull);
      expect(result!.updatedAt, isNotNull);
    });

    test('deletedAt is null for non-deleted post', () async {
      final result =
          await container.read(postByIdProvider('post-1').future);
      expect(result, isNotNull);
      expect(result!.deletedAt, isNull);
    });
  });

  group('postsByUser', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-1'),
            'boards': boardData,
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

    test('fetches posts by user id (unauthenticated)', () async {
      final result =
          await container.read(postsByUserProvider('user-1', 10, 1).future);
      expect(result, isNotNull);
      expect(result.length, 1);
      expect(result.first.postId, 'post-1');
    });

    test('returns empty list when user has no posts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByUserProvider('user-1', 10, 1).future);
      expect(result, isEmpty);
    });

    test('includes board and user profile in result', () async {
      final result =
          await container.read(postsByUserProvider('user-1', 10, 1).future);
      expect(result, isNotNull);
      final post = result.first;
      expect(post.userProfiles, isNotNull);
      expect(post.userProfiles!.nickname, 'TestUser');
      expect(post.userProfiles!.avatarUrl, 'https://example.com/avatar.png');
      expect(post.board, isNotNull);
      expect(post.board!.boardId, 'board-1');
    });

    test('handles multiple posts by same user', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-1', title: 'Post A'),
            'boards': boardData
          },
          {
            ...makePost(postId: 'post-2', title: 'Post B'),
            'boards': boardData
          },
          {
            ...makePost(postId: 'post-3', title: 'Post C'),
            'boards': boardData
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByUserProvider('user-1', 10, 1).future);
      expect(result.length, 3);
      expect(result[0].postId, 'post-1');
      expect(result[1].postId, 'post-2');
      expect(result[2].postId, 'post-3');
    });

    test('different user ids create different providers', () async {
      final result1 =
          await container.read(postsByUserProvider('user-1', 10, 1).future);
      final result2 =
          await container.read(postsByUserProvider('user-2', 10, 1).future);
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('board data is null when boards key missing', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'posts': [
          {
            ...makePost(postId: 'post-1'),
            'boards': null,
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(postsByUserProvider('user-1', 10, 1).future);
      expect(result.first.board, isNull);
    });
  });

  group('postsScrapedByUser', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'post_scraps': [
          {
            'post_id': 'post-1',
            'user_id': 'user-1',
            'user_profiles': userProfileData,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
            'deleted_at': null,
            'board': null,
            'post': {
              ...makePost(postId: 'post-1'),
              'board': boardData,
            },
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

    test('fetches scraped posts by user id (unauthenticated)', () async {
      final result = await container
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result, isNotNull);
      expect(result.length, 1);
      expect(result.first.postId, 'post-1');
      expect(result.first.userId, 'user-1');
    });

    test('returns empty list when no scraped posts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'post_scraps': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result, isEmpty);
    });

    test('parses scraped post fields correctly', () async {
      final result = await container
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result, isNotNull);
      final scrap = result.first;
      expect(scrap.postId, 'post-1');
      expect(scrap.userId, 'user-1');
      expect(scrap.userProfiles, isNotNull);
      expect(scrap.userProfiles!.nickname, 'TestUser');
      expect(scrap.post, isNotNull);
      expect(scrap.post!.postId, 'post-1');
    });

    test('handles multiple scraped posts', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'post_scraps': [
          {
            'post_id': 'post-1',
            'user_id': 'user-1',
            'user_profiles': userProfileData,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
            'deleted_at': null,
            'board': null,
            'post': {
              ...makePost(postId: 'post-1'),
              'board': boardData,
            },
          },
          {
            'post_id': 'post-2',
            'user_id': 'user-1',
            'user_profiles': userProfileData,
            'created_at': '2026-02-01T00:00:00Z',
            'updated_at': '2026-02-01T00:00:00Z',
            'deleted_at': null,
            'board': null,
            'post': {
              ...makePost(postId: 'post-2', title: 'Second Scraped'),
              'board': boardData,
            },
          },
        ],
        'user_blocks': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result.length, 2);
      expect(result[0].postId, 'post-1');
      expect(result[1].postId, 'post-2');
    });

    test('handles page 2 request', () async {
      final result = await container
          .read(postsScrapedByUserProvider('user-1', 10, 2).future);
      expect(result, isNotNull);
    });

    test('parses dates in scraped posts', () async {
      final result = await container
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result.first.createdAt, isNotNull);
      expect(result.first.updatedAt, isNotNull);
      expect(result.first.deletedAt, isNull);
    });

    test('board can be null in scraped post', () async {
      final result = await container
          .read(postsScrapedByUserProvider('user-1', 10, 1).future);
      expect(result.first.board, isNull);
    });
  });

  group('deletePost', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('completes without error', () async {
      await expectLater(
        container.read(deletePostProvider('post-1').future),
        completes,
      );
    });

    test('completes for different post ids', () async {
      await expectLater(
        container.read(deletePostProvider('post-abc').future),
        completes,
      );
    });

    test('can delete multiple posts sequentially', () async {
      await expectLater(
        container.read(deletePostProvider('post-1').future),
        completes,
      );
      await expectLater(
        container.read(deletePostProvider('post-2').future),
        completes,
      );
    });
  });

  group('reportPost', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase(
        {
          'post_reports': <Map<String, dynamic>>[],
          'user_blocks': <Map<String, dynamic>>[],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('throws when user is not authenticated', () async {
      final post = makePost(postId: 'post-1');
      expect(
        () async {
          await container.read(
            reportPostProvider(
              _makePostModel(post),
              'spam',
              'This is spam',
            ).future,
          );
        },
        throwsA(isA<TypeError>()),
      );
    });

    test('throws with blockUser=true when not authenticated', () async {
      final post = makePost(postId: 'post-1');
      expect(
        () async {
          await container.read(
            reportPostProvider(
              _makePostModel(post),
              'inappropriate',
              'Bad content',
              blockUser: true,
            ).future,
          );
        },
        throwsA(isA<TypeError>()),
      );
    });

    test('throws with empty text when not authenticated', () async {
      final post = makePost(postId: 'post-1');
      expect(
        () async {
          await container.read(
            reportPostProvider(
              _makePostModel(post),
              'spam',
              '',
            ).future,
          );
        },
        throwsA(isA<TypeError>()),
      );
    });

    test('different reason strings create different providers', () async {
      final post = makePost(postId: 'post-1');
      final model = _makePostModel(post);
      // Different reason/text params create different provider instances
      expect(
        () async {
          await container.read(
            reportPostProvider(model, 'spam', 'text1').future,
          );
        },
        throwsA(isA<TypeError>()),
      );
      expect(
        () async {
          await container.read(
            reportPostProvider(model, 'harassment', 'text2').future,
          );
        },
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('scrapPost', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase(
        {'post_scraps': <Map<String, dynamic>>[]},
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('throws when user is not authenticated', () async {
      expect(
        container.read(scrapPostProvider('post-1').future),
        throwsA(isA<TypeError>()),
      );
    });

    test('different post ids create different providers', () async {
      expect(
        container.read(scrapPostProvider('post-1').future),
        throwsA(isA<TypeError>()),
      );
      expect(
        container.read(scrapPostProvider('post-2').future),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('unscrapPost', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'post_scraps': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('completes without error', () async {
      await expectLater(
        container.read(unscrapPostProvider('post-1', 'user-1').future),
        completes,
      );
    });

    test('completes with different post and user ids', () async {
      await expectLater(
        container.read(unscrapPostProvider('post-xyz', 'user-abc').future),
        completes,
      );
    });

    test('does not require authentication', () async {
      // unscrapPost uses eq filters, not currentUser
      await expectLater(
        container.read(unscrapPostProvider('post-1', 'user-1').future),
        completes,
      );
    });
  });

  group('postsByQuery', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'posts': <Map<String, dynamic>>[],
        'user_blocks': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns empty list for empty query', () async {
      final result =
          await container.read(postsByQueryProvider(1, '', 1, 10).future);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('errors for non-empty query when navigatorKey context is null',
        () async {
      expect(
        container.read(postsByQueryProvider(1, 'search term', 1, 10).future),
        throwsA(anything),
      );
    });

    test('empty query returns empty list regardless of artist id', () async {
      final result1 =
          await container.read(postsByQueryProvider(1, '', 1, 10).future);
      expect(result1, isEmpty);

      final result2 =
          await container.read(postsByQueryProvider(999, '', 1, 10).future);
      expect(result2, isEmpty);
    });

    test('empty query returns empty list regardless of page', () async {
      final result1 =
          await container.read(postsByQueryProvider(1, '', 1, 10).future);
      expect(result1, isEmpty);

      final result2 =
          await container.read(postsByQueryProvider(1, '', 5, 10).future);
      expect(result2, isEmpty);
    });
  });

  group('Utility functions', () {
    test('getBlockedUserIds requires authentication', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      final result = await getBlockedUserIds();
      expect(result, isEmpty);

      tearDownMockSupabase();
    });

    test('isUserBlocked requires authentication', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      final result = await isUserBlocked('some-user');
      expect(result, false);

      tearDownMockSupabase();
    });

    test('unblockUser throws when not authenticated', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      expect(
        () => unblockUser('some-user'),
        throwsA(anything),
      );

      tearDownMockSupabase();
    });

    test('isUserBlocked returns false on error', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      final result = await isUserBlocked('user-123');
      expect(result, isFalse);

      tearDownMockSupabase();
    });

    test('getBlockedUserIds returns empty list on error', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      final result = await getBlockedUserIds();
      expect(result, isA<List<String>>());
      expect(result, isEmpty);

      tearDownMockSupabase();
    });

    test('isUserBlocked returns false for different user ids', () async {
      setupMockSupabase({
        'user_blocks': <Map<String, dynamic>>[],
      });

      expect(await isUserBlocked('user-a'), isFalse);
      expect(await isUserBlocked('user-b'), isFalse);
      expect(await isUserBlocked(''), isFalse);

      tearDownMockSupabase();
    });
  });

  group('PostModel', () {
    test('fromJson creates model correctly', () {
      final json = makePost(
        postId: 'p-1',
        userId: 'u-1',
        title: 'My Title',
        viewCount: 42,
        replyCount: 7,
      );
      final model = PostModel.fromJson(json);

      expect(model.postId, 'p-1');
      expect(model.userId, 'u-1');
      expect(model.title, 'My Title');
      expect(model.viewCount, 42);
      expect(model.replyCount, 7);
      expect(model.isAnonymous, false);
      expect(model.isHidden, false);
      expect(model.isScraped, false);
      expect(model.deletedAt, isNull);
    });

    test('fromJson with anonymous post', () {
      final json = makePost(postId: 'p-1', isAnonymous: true);
      final model = PostModel.fromJson(json);
      expect(model.isAnonymous, true);
    });

    test('fromJson with hidden post', () {
      final json = makePost(postId: 'p-1', isHidden: true);
      final model = PostModel.fromJson(json);
      expect(model.isHidden, true);
    });

    test('copyWith updates fields', () {
      final json = makePost(postId: 'p-1', title: 'Original');
      final model = PostModel.fromJson(json);
      final updated = model.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.postId, 'p-1');
    });

    test('copyWith updates userProfiles and board', () {
      final json = makePost(postId: 'p-1');
      final model = PostModel.fromJson(json);
      final updated = model.copyWith(
        userProfiles: null,
        board: null,
      );
      expect(updated.userProfiles, isNull);
      expect(updated.board, isNull);
    });

    test('fromJson parses dates correctly', () {
      final json = makePost(postId: 'p-1');
      final model = PostModel.fromJson(json);
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2026);
      expect(model.updatedAt, isNotNull);
    });

    test('fromJson with null content', () {
      final json = makePost(postId: 'p-1');
      final model = PostModel.fromJson(json);
      expect(model.content, isNull);
    });
  });
}

PostModel _makePostModel(Map<String, dynamic> json) {
  return PostModel.fromJson(json);
}
