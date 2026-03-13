import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';

/// Tests that exercise production code from post_view_page.dart
/// and its direct dependencies (PostModel, BoardModel, AlwaysDisabledFocusNode).
///
/// Widget rendering is blocked by transitive google_mobile_ads / flutter_quill imports.
/// We focus on exercising production constructors, models, and public classes.
void main() {
  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': 'BTS', 'en': 'BTS'},
  );

  final testBoard = BoardModel(
    boardId: 'board-1',
    artistId: 1,
    name: {'ko': '자유게시판', 'en': 'Free Board'},
    description: 'Test board',
    isOfficial: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    artist: testArtist,
    requestMessage: null,
    status: 'approved',
    creatorId: null,
    features: ['image', 'link', 'youtube'],
  );

  final testPost = PostModel(
    postId: 'post-1',
    userId: 'user-1',
    userProfiles: UserProfilesModel(
      id: 'user-1',
      nickname: 'TestUser',
      isAdmin: false,
      starCandy: 100,
      starCandyBonus: 10,
      jmaCandy: 50,
    ),
    boardId: 'board-1',
    title: 'Test Post Title',
    content: [
      {'insert': 'Hello, World!\n'}
    ],
    viewCount: 42,
    replyCount: 5,
    isHidden: false,
    board: testBoard,
    isAnonymous: false,
    isScraped: false,
    createdAt: DateTime(2026, 1, 15, 14, 30),
    updatedAt: DateTime(2026, 1, 15, 14, 30),
  );

  group('AlwaysDisabledFocusNode (production)', () {
    test('hasFocus is always false', () {
      final node = AlwaysDisabledFocusNode();
      expect(node.hasFocus, isFalse);
      node.dispose();
    });

    test('can be created without arguments', () {
      final node = AlwaysDisabledFocusNode();
      expect(node, isNotNull);
      expect(node, isA<AlwaysDisabledFocusNode>());
      node.dispose();
    });

    test('hasFocus remains false after creation', () {
      final node = AlwaysDisabledFocusNode();
      // Even if we check multiple times, it should stay false
      expect(node.hasFocus, isFalse);
      expect(node.hasFocus, isFalse);
      node.dispose();
    });
  });

  group('PostModel constructor (production)', () {
    test('creates post with all fields', () {
      expect(testPost.postId, equals('post-1'));
      expect(testPost.userId, equals('user-1'));
      expect(testPost.boardId, equals('board-1'));
      expect(testPost.title, equals('Test Post Title'));
      expect(testPost.viewCount, equals(42));
      expect(testPost.replyCount, equals(5));
      expect(testPost.isHidden, isFalse);
      expect(testPost.isAnonymous, isFalse);
      expect(testPost.isScraped, isFalse);
      expect(testPost.createdAt, equals(DateTime(2026, 1, 15, 14, 30)));
    });

    test('post with deleted date', () {
      final deletedPost = PostModel(
        postId: 'post-del',
        userId: 'user-1',
        userProfiles: null,
        boardId: 'board-1',
        title: 'Deleted Post',
        content: null,
        viewCount: 10,
        replyCount: 0,
        isHidden: false,
        board: null,
        isAnonymous: false,
        isScraped: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        deletedAt: DateTime(2026, 1, 5),
      );

      expect(deletedPost.deletedAt, isNotNull);
      expect(deletedPost.deletedAt, equals(DateTime(2026, 1, 5)));
    });

    test('post without deleted date', () {
      expect(testPost.deletedAt, isNull);
    });

    test('anonymous post', () {
      final anonymousPost = PostModel(
        postId: 'post-anon',
        userId: 'user-1',
        userProfiles: UserProfilesModel(
          id: 'user-1',
          nickname: 'TestUser',
          isAdmin: false,
          starCandy: 100,
          starCandyBonus: 10,
          jmaCandy: 50,
        ),
        boardId: 'board-1',
        title: 'Anonymous Post',
        content: [
          {'insert': 'Secret\n'}
        ],
        viewCount: 5,
        replyCount: 0,
        isHidden: false,
        board: null,
        isAnonymous: true,
        isScraped: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(anonymousPost.isAnonymous, isTrue);
    });

    test('hidden post', () {
      final hiddenPost = PostModel(
        postId: 'post-hidden',
        userId: 'user-1',
        userProfiles: null,
        boardId: 'board-1',
        title: 'Hidden Post',
        content: null,
        viewCount: 0,
        replyCount: 0,
        isHidden: true,
        board: null,
        isAnonymous: false,
        isScraped: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(hiddenPost.isHidden, isTrue);
    });

    test('scraped post', () {
      final scrapedPost = PostModel(
        postId: 'post-scraped',
        userId: 'user-1',
        userProfiles: null,
        boardId: 'board-1',
        title: 'Scraped Post',
        content: null,
        viewCount: 0,
        replyCount: 0,
        isHidden: false,
        board: null,
        isAnonymous: false,
        isScraped: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(scrapedPost.isScraped, isTrue);
    });

    test('post with null fields', () {
      final nullPost = PostModel(
        postId: 'post-null',
        userId: 'user-1',
        userProfiles: null,
        boardId: null,
        title: null,
        content: null,
        viewCount: null,
        replyCount: null,
        isHidden: null,
        board: null,
        isAnonymous: null,
        isScraped: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(nullPost.content, isNull);
      expect(nullPost.title, isNull);
      expect(nullPost.viewCount, isNull);
      expect(nullPost.boardId, isNull);
      expect(nullPost.userProfiles, isNull);
      expect(nullPost.createdAt, isNull);
    });

    test('post with zero counts', () {
      final emptyPost = PostModel(
        postId: 'post-empty',
        userId: 'user-1',
        userProfiles: null,
        boardId: null,
        title: 'Empty',
        content: null,
        viewCount: 0,
        replyCount: 0,
        isHidden: false,
        board: null,
        isAnonymous: false,
        isScraped: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(emptyPost.viewCount, equals(0));
      expect(emptyPost.replyCount, equals(0));
    });
  });

  group('PostModel.fromJson (production)', () {
    test('parses full post from JSON', () {
      final json = {
        'post_id': 'p1',
        'user_id': 'u1',
        'user_profiles': null,
        'board_id': 'b1',
        'title': 'Test',
        'content': [
          {'insert': 'content\n'}
        ],
        'view_count': 10,
        'reply_count': 3,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final post = PostModel.fromJson(json);
      expect(post.postId, equals('p1'));
      expect(post.userId, equals('u1'));
      expect(post.boardId, equals('b1'));
      expect(post.title, equals('Test'));
      expect(post.viewCount, equals(10));
      expect(post.replyCount, equals(3));
      expect(post.isHidden, isFalse);
      expect(post.isAnonymous, isFalse);
      expect(post.isScraped, isFalse);
    });

    test('parses post with deleted_at', () {
      final json = {
        'post_id': 'p2',
        'user_id': 'u1',
        'user_profiles': null,
        'board_id': null,
        'title': 'Deleted',
        'content': null,
        'view_count': 0,
        'reply_count': 0,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
        'deleted_at': '2026-01-05T00:00:00.000',
      };

      final post = PostModel.fromJson(json);
      expect(post.deletedAt, isNotNull);
    });

    test('parses post with embedded user profile', () {
      final json = {
        'post_id': 'p3',
        'user_id': 'u1',
        'user_profiles': {
          'id': 'u1',
          'nickname': 'Author',
          'is_admin': false,
          'star_candy': 50,
          'star_candy_bonus': 5,
          'jma_candy': 10,
        },
        'board_id': 'b1',
        'title': 'With Author',
        'content': [
          {'insert': 'text\n'}
        ],
        'view_count': 5,
        'reply_count': 1,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final post = PostModel.fromJson(json);
      expect(post.userProfiles, isNotNull);
      expect(post.userProfiles!.nickname, equals('Author'));
    });

    test('parses post with embedded board', () {
      final json = {
        'post_id': 'p4',
        'user_id': 'u1',
        'user_profiles': null,
        'board_id': 'b1',
        'title': 'With Board',
        'content': null,
        'view_count': 0,
        'reply_count': 0,
        'is_hidden': false,
        'boards': {
          'board_id': 'b1',
          'artist_id': 1,
          'name': {'ko': '자유게시판'},
          'description': 'Free',
          'is_official': true,
        },
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      };

      final post = PostModel.fromJson(json);
      expect(post.board, isNotNull);
      expect(post.board!.boardId, equals('b1'));
    });
  });

  group('PostModel serialization round-trip (production)', () {
    test('toJson and fromJson produce equivalent model', () {
      final json = testPost.toJson();
      expect(json, isNotNull);
      expect(json['post_id'], equals('post-1'));
      expect(json['title'], equals('Test Post Title'));
      expect(json['view_count'], equals(42));

      final restored = PostModel.fromJson(json);
      expect(restored.postId, equals(testPost.postId));
      expect(restored.title, equals(testPost.title));
      expect(restored.viewCount, equals(testPost.viewCount));
    });
  });

  group('PostModel board info access (production)', () {
    test('post has correct board name', () {
      expect(testPost.board, isNotNull);
      expect(testPost.board!.name['ko'], equals('자유게시판'));
      expect(testPost.board!.name['en'], equals('Free Board'));
    });

    test('post board is official', () {
      expect(testPost.board!.isOfficial, isTrue);
    });

    test('post board has features', () {
      expect(testPost.board!.features, isNotNull);
      expect(testPost.board!.features!, contains('image'));
      expect(testPost.board!.features!, contains('link'));
      expect(testPost.board!.features!, contains('youtube'));
    });

    test('post board has artist', () {
      expect(testPost.board!.artist, isNotNull);
      expect(testPost.board!.artist!.id, equals(1));
    });
  });

  group('PostModel user profiles access (production)', () {
    test('post has user profile', () {
      expect(testPost.userProfiles, isNotNull);
      expect(testPost.userProfiles!.nickname, equals('TestUser'));
    });

    test('post user profile admin flag', () {
      expect(testPost.userProfiles!.isAdmin, isFalse);
    });
  });

  group('BoardModel constructor (production)', () {
    test('creates board with all fields', () {
      expect(testBoard.boardId, equals('board-1'));
      expect(testBoard.artistId, equals(1));
      expect(testBoard.description, equals('Test board'));
      expect(testBoard.isOfficial, isTrue);
      expect(testBoard.status, equals('approved'));
    });

    test('board with null optional fields', () {
      final minBoard = BoardModel(
        boardId: 'b-min',
        artistId: 0,
        name: {'ko': 'Min'},
        description: '',
        isOfficial: null,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );

      expect(minBoard.artist, isNull);
      expect(minBoard.features, isNull);
      expect(minBoard.isOfficial, isNull);
      expect(minBoard.status, isNull);
    });

    test('board with empty features', () {
      final board = BoardModel(
        boardId: 'b-empty',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'empty features',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: [],
      );

      expect(board.features, isEmpty);
    });
  });

  group('BoardModel.fromJson (production)', () {
    test('parses board from JSON', () {
      final json = {
        'board_id': 'b1',
        'artist_id': 1,
        'name': {'ko': '팬아트', 'en': 'Fan Art'},
        'description': 'Fan Art Board',
        'is_official': false,
        'features': ['image'],
      };

      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('b1'));
      expect(board.artistId, equals(1));
      expect(board.name['ko'], equals('팬아트'));
      expect(board.isOfficial, isFalse);
    });

    test('parses board with minimal JSON', () {
      final json = {
        'board_id': 'b2',
        'artist_id': 0,
        'name': {'ko': 'Test'},
        'description': '',
      };

      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('b2'));
      expect(board.artist, isNull);
    });
  });

  group('BoardModel serialization round-trip (production)', () {
    test('toJson and fromJson produce equivalent model', () {
      final json = testBoard.toJson();
      expect(json, isNotNull);

      final restored = BoardModel.fromJson(json);
      expect(restored.boardId, equals(testBoard.boardId));
      expect(restored.artistId, equals(testBoard.artistId));
      expect(restored.name['ko'], equals(testBoard.name['ko']));
    });
  });

  group('PostViewPage constructor (production)', () {
    test('PostViewPage can be constructed with postId', () {
      const page = PostViewPage('test-post-id');
      expect(page.postId, equals('test-post-id'));
      expect(page.syncNavigation, isTrue);
    });

    test('PostViewPage can be constructed with syncNavigation false', () {
      const page = PostViewPage('test-post-id', syncNavigation: false);
      expect(page.postId, equals('test-post-id'));
      expect(page.syncNavigation, isFalse);
    });
  });
}
