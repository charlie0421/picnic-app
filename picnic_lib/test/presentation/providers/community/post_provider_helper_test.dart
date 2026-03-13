import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider_helper.dart';

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
    dynamic postScraps,
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
      'post_scraps': postScraps,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    };
  }

  group('extractBlockedUserIds', () {
    test('returns empty list for empty input', () {
      final result = PostProviderHelper.extractBlockedUserIds([]);
      expect(result, isEmpty);
    });

    test('extracts single blocked user id', () {
      final result = PostProviderHelper.extractBlockedUserIds([
        {'blocked_user_id': 'user-abc'},
      ]);
      expect(result, ['user-abc']);
    });

    test('extracts multiple blocked user ids', () {
      final result = PostProviderHelper.extractBlockedUserIds([
        {'blocked_user_id': 'user-1'},
        {'blocked_user_id': 'user-2'},
        {'blocked_user_id': 'user-3'},
      ]);
      expect(result, ['user-1', 'user-2', 'user-3']);
    });

    test('preserves order of blocked user ids', () {
      final result = PostProviderHelper.extractBlockedUserIds([
        {'blocked_user_id': 'z-user'},
        {'blocked_user_id': 'a-user'},
        {'blocked_user_id': 'm-user'},
      ]);
      expect(result, ['z-user', 'a-user', 'm-user']);
    });

    test('handles UUIDs', () {
      final result = PostProviderHelper.extractBlockedUserIds([
        {'blocked_user_id': '550e8400-e29b-41d4-a716-446655440000'},
      ]);
      expect(result, ['550e8400-e29b-41d4-a716-446655440000']);
    });
  });

  group('buildBlockedUserFilter', () {
    test('returns null for empty list', () {
      final result = PostProviderHelper.buildBlockedUserFilter([]);
      expect(result, isNull);
    });

    test('builds filter with single user id', () {
      final result = PostProviderHelper.buildBlockedUserFilter(['user-1']);
      expect(result, 'and(user_id.not.in.(user-1))');
    });

    test('builds filter with multiple user ids', () {
      final result = PostProviderHelper.buildBlockedUserFilter(
          ['user-1', 'user-2', 'user-3']);
      expect(result, 'and(user_id.not.in.(user-1,user-2,user-3))');
    });

    test('builds filter with UUID-style ids', () {
      final result = PostProviderHelper.buildBlockedUserFilter([
        '550e8400-e29b-41d4-a716-446655440000',
        '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
      ]);
      expect(
        result,
        'and(user_id.not.in.(550e8400-e29b-41d4-a716-446655440000,6ba7b810-9dad-11d1-80b4-00c04fd430c8))',
      );
    });
  });

  group('buildReportReason', () {
    test('returns reason only when text is empty', () {
      final result = PostProviderHelper.buildReportReason('spam', '');
      expect(result, 'spam');
    });

    test('combines reason and text with separator', () {
      final result =
          PostProviderHelper.buildReportReason('spam', 'This is spam content');
      expect(result, 'spam - This is spam content');
    });

    test('handles empty reason with non-empty text', () {
      final result = PostProviderHelper.buildReportReason('', 'details');
      expect(result, ' - details');
    });

    test('handles both empty reason and text', () {
      final result = PostProviderHelper.buildReportReason('', '');
      expect(result, '');
    });

    test('handles Korean text', () {
      final result =
          PostProviderHelper.buildReportReason('스팸', '스팸 게시물입니다');
      expect(result, '스팸 - 스팸 게시물입니다');
    });

    test('handles special characters in text', () {
      final result = PostProviderHelper.buildReportReason(
          'inappropriate', 'contains <script> & "quotes"');
      expect(result, 'inappropriate - contains <script> & "quotes"');
    });
  });

  group('determineIsScraped', () {
    test('returns false for null', () {
      expect(PostProviderHelper.determineIsScraped(null), false);
    });

    test('returns false for empty list', () {
      expect(PostProviderHelper.determineIsScraped([]), false);
    });

    test('returns true for non-empty list', () {
      expect(
        PostProviderHelper.determineIsScraped([
          {'post_id': 'post-1'}
        ]),
        true,
      );
    });

    test('returns true for list with multiple items', () {
      expect(
        PostProviderHelper.determineIsScraped([
          {'post_id': 'post-1'},
          {'post_id': 'post-2'},
        ]),
        true,
      );
    });

    test('returns false for non-list non-null value', () {
      // A string is not a List, so it should return false
      expect(PostProviderHelper.determineIsScraped('not-a-list'), false);
    });

    test('returns false for integer value', () {
      expect(PostProviderHelper.determineIsScraped(42), false);
    });
  });

  group('addIsScrapedToResponse', () {
    test('adds is_scraped true when post_scraps is non-empty', () {
      final response = makePost(
        postId: 'post-1',
        postScraps: [
          {'post_id': 'post-1'}
        ],
      );
      final result = PostProviderHelper.addIsScrapedToResponse(response);
      expect(result['is_scraped'], true);
    });

    test('adds is_scraped false when post_scraps is null', () {
      final response = makePost(postId: 'post-1', postScraps: null);
      final result = PostProviderHelper.addIsScrapedToResponse(response);
      expect(result['is_scraped'], false);
    });

    test('adds is_scraped false when post_scraps is empty list', () {
      final response = makePost(postId: 'post-1', postScraps: []);
      final result = PostProviderHelper.addIsScrapedToResponse(response);
      expect(result['is_scraped'], false);
    });

    test('preserves all original fields', () {
      final response = makePost(postId: 'post-1', title: 'Keep This');
      final result = PostProviderHelper.addIsScrapedToResponse(response);
      expect(result['post_id'], 'post-1');
      expect(result['title'], 'Keep This');
      expect(result['user_id'], 'user-1');
      expect(result['board_id'], 'board-1');
      expect(result['boards'], isNotNull);
      expect(result['user_profiles'], isNotNull);
    });

    test('overrides existing is_scraped value', () {
      final response = makePost(postId: 'post-1', postScraps: [
        {'post_id': 'post-1'}
      ]);
      // makePost sets is_scraped to false by default
      expect(response['is_scraped'], false);
      final result = PostProviderHelper.addIsScrapedToResponse(response);
      // Should be overridden to true based on post_scraps
      expect(result['is_scraped'], true);
    });
  });

  group('calculateRange', () {
    test('page 1 with limit 10', () {
      final (start, end) = PostProviderHelper.calculateRange(1, 10);
      expect(start, 0);
      expect(end, 9);
    });

    test('page 2 with limit 10', () {
      final (start, end) = PostProviderHelper.calculateRange(2, 10);
      expect(start, 10);
      expect(end, 19);
    });

    test('page 3 with limit 10', () {
      final (start, end) = PostProviderHelper.calculateRange(3, 10);
      expect(start, 20);
      expect(end, 29);
    });

    test('page 1 with limit 1', () {
      final (start, end) = PostProviderHelper.calculateRange(1, 1);
      expect(start, 0);
      expect(end, 0);
    });

    test('page 1 with limit 20', () {
      final (start, end) = PostProviderHelper.calculateRange(1, 20);
      expect(start, 0);
      expect(end, 19);
    });

    test('page 5 with limit 5', () {
      final (start, end) = PostProviderHelper.calculateRange(5, 5);
      expect(start, 20);
      expect(end, 24);
    });

    test('large page number', () {
      final (start, end) = PostProviderHelper.calculateRange(100, 10);
      expect(start, 990);
      expect(end, 999);
    });

    test('limit of 50', () {
      final (start, end) = PostProviderHelper.calculateRange(2, 50);
      expect(start, 50);
      expect(end, 99);
    });
  });

  group('parsePostWithUserAndBoard', () {
    test('parses post with user profile and board', () {
      final data = makePost(
        postId: 'post-1',
        userId: 'user-1',
        title: 'Test Post',
        viewCount: 42,
        replyCount: 7,
      );
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);

      expect(result.postId, 'post-1');
      expect(result.userId, 'user-1');
      expect(result.title, 'Test Post');
      expect(result.viewCount, 42);
      expect(result.replyCount, 7);
      expect(result.userProfiles, isNotNull);
      expect(result.userProfiles!.nickname, 'TestUser');
      expect(
          result.userProfiles!.avatarUrl, 'https://example.com/avatar.png');
      expect(result.board, isNotNull);
      expect(result.board!.boardId, 'board-1');
    });

    test('sets board to null when boards key is null', () {
      final data = makePost(postId: 'post-1');
      data['boards'] = null;
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);

      expect(result.board, isNull);
      expect(result.userProfiles, isNotNull);
    });

    test('parses anonymous post correctly', () {
      final data = makePost(postId: 'post-1', isAnonymous: true);
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.isAnonymous, true);
    });

    test('parses hidden post correctly', () {
      final data = makePost(postId: 'post-1', isHidden: true);
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.isHidden, true);
    });

    test('parses post with zero counts', () {
      final data = makePost(postId: 'post-1', viewCount: 0, replyCount: 0);
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.viewCount, 0);
      expect(result.replyCount, 0);
    });

    test('parses post with large counts', () {
      final data = makePost(
        postId: 'post-1',
        viewCount: 999999,
        replyCount: 50000,
      );
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.viewCount, 999999);
      expect(result.replyCount, 50000);
    });

    test('parses board name in multiple languages', () {
      final data = makePost(postId: 'post-1');
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.board!.name['ko'], '자유게시판');
      expect(result.board!.name['en'], 'Free Board');
    });

    test('parses board artistId and description', () {
      final data = makePost(postId: 'post-1');
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.board!.artistId, 1);
      expect(result.board!.description, 'A free board');
    });

    test('parses dates correctly', () {
      final data = makePost(postId: 'post-1');
      final result = PostProviderHelper.parsePostWithUserAndBoard(data);
      expect(result.createdAt, isNotNull);
      expect(result.createdAt!.year, 2026);
      expect(result.updatedAt, isNotNull);
      expect(result.deletedAt, isNull);
    });
  });
}
