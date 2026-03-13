import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

import '../../../helpers/test_environment.dart';

/// Tests that exercise production code from board_list_page.dart
/// and its direct dependencies (KoreanSearchUtils, BoardModel, ArtistModel, locale_utils).
///
/// Widget rendering is blocked by transitive picnic_cached_network_image / rxdart imports.
/// We focus on exercising production functions and model code.
void main() {
  setUpAll(() {
    initTestColors();
  });

  final testArtist1 = ArtistModel(
    id: 1,
    name: {'ko': 'BTS', 'en': 'BTS'},
    image: 'https://example.com/bts.jpg',
  );

  final testArtist2 = ArtistModel(
    id: 2,
    name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
    image: 'https://example.com/bp.jpg',
  );

  final boards = [
    BoardModel(
      boardId: 'b1',
      artistId: 1,
      name: {'ko': '자유게시판', 'en': 'Free Board'},
      description: 'Free',
      isOfficial: true,
      createdAt: null,
      updatedAt: null,
      artist: testArtist1,
      requestMessage: null,
      status: 'approved',
      creatorId: null,
      features: ['image', 'link'],
    ),
    BoardModel(
      boardId: 'b2',
      artistId: 1,
      name: {'ko': '팬아트', 'en': 'Fan Art'},
      description: 'Fan Art',
      isOfficial: false,
      createdAt: null,
      updatedAt: null,
      artist: testArtist1,
      requestMessage: null,
      status: 'approved',
      creatorId: null,
      features: ['image'],
    ),
    BoardModel(
      boardId: 'b3',
      artistId: 2,
      name: {'ko': '자유게시판', 'en': 'Free Board'},
      description: 'Free',
      isOfficial: true,
      createdAt: null,
      updatedAt: null,
      artist: testArtist2,
      requestMessage: null,
      status: 'approved',
      creatorId: null,
      features: [],
    ),
  ];

  group('KoreanSearchUtils (production)', () {
    test('extractKoreanInitials from Korean text', () {
      expect(KoreanSearchUtils.extractKoreanInitials('방탄소년단'), equals('ㅂㅌㅅㄴㄷ'));
    });

    test('extractKoreanInitials from English text', () {
      expect(KoreanSearchUtils.extractKoreanInitials('BTS'), equals('BTS'));
    });

    test('extractKoreanInitials from mixed text', () {
      expect(KoreanSearchUtils.extractKoreanInitials('블랙핑크 BLACKPINK'), equals('ㅂㄹㅍㅋ BLACKPINK'));
    });

    test('matchesKoreanInitials with Korean initials', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌㅅ'), isTrue);
    });

    test('matchesKoreanInitials with full text', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', '방탄'), isTrue);
    });

    test('matchesKoreanInitials with English text', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('BTS', 'bt'), isTrue);
    });

    test('matchesKoreanInitials returns false for non-matching', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅈㅈ'), isFalse);
    });

    test('matchesKoreanInitials with empty text returns false', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('', 'ㅂ'), isFalse);
    });

    test('matchesKoreanInitials with empty query returns false', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', ''), isFalse);
    });

    test('matchesKoreanInitials for 블랙핑크 with ㅂㄹㅍㅋ', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('블랙핑크', 'ㅂㄹㅍㅋ'), isTrue);
    });

    test('getMatchingText returns Korean match', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, 'ㅂㅌㅅ'), equals('방탄소년단'));
    });

    test('getMatchingText returns English match', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, 'bts'), equals('BTS'));
    });

    test('getMatchingText returns default when no match', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      final result = KoreanSearchUtils.getMatchingText(nameMap, 'TWICE');
      expect(result, isNotEmpty);
    });

    test('extractKoreanInitials handles single character', () {
      expect(KoreanSearchUtils.extractKoreanInitials('가'), equals('ㄱ'));
    });

    test('matchesKoreanInitials partial initial match', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('자유게시판', 'ㅈㅇ'), isTrue);
    });
  });

  group('getLocaleTextFromJsonWithLocale for board names (production)', () {
    test('returns Korean board name', () {
      expect(
        getLocaleTextFromJsonWithLocale(boards[0].name, 'ko'),
        equals('자유게시판'),
      );
    });

    test('returns English board name', () {
      expect(
        getLocaleTextFromJsonWithLocale(boards[0].name, 'en'),
        equals('Free Board'),
      );
    });

    test('falls back to en for unknown locale', () {
      expect(
        getLocaleTextFromJsonWithLocale(boards[1].name, 'de'),
        equals('Fan Art'),
      );
    });

    test('returns Korean artist name', () {
      expect(
        getLocaleTextFromJsonWithLocale(testArtist1.name, 'ko'),
        equals('BTS'),
      );
    });

    test('returns Korean artist name for BLACKPINK', () {
      expect(
        getLocaleTextFromJsonWithLocale(testArtist2.name, 'ko'),
        equals('블랙핑크'),
      );
    });
  });

  group('BoardModel constructor (production)', () {
    test('creates board with all fields', () {
      expect(boards[0].boardId, equals('b1'));
      expect(boards[0].artistId, equals(1));
      expect(boards[0].description, equals('Free'));
      expect(boards[0].isOfficial, isTrue);
      expect(boards[0].status, equals('approved'));
    });

    test('board has features list', () {
      expect(boards[0].features, isNotNull);
      expect(boards[0].features!.contains('image'), isTrue);
      expect(boards[0].features!.contains('link'), isTrue);
    });

    test('board with null features', () {
      final board = BoardModel(
        boardId: 'b-nf',
        artistId: 1,
        name: {'ko': 'Test'},
        description: '',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );
      expect(board.features, isNull);
    });

    test('board with empty features', () {
      expect(boards[2].features, isEmpty);
    });

    test('null isOfficial defaults to null', () {
      final board = BoardModel(
        boardId: 'b-null-official',
        artistId: 1,
        name: {'ko': 'Test'},
        description: '',
        isOfficial: null,
        createdAt: null,
        updatedAt: null,
        artist: testArtist1,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );
      expect(board.isOfficial, isNull);
    });

    test('board with empty name map', () {
      final board = BoardModel(
        boardId: 'b-empty',
        artistId: 1,
        name: {},
        description: '',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: testArtist1,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );
      expect(board.name.isEmpty, isTrue);
    });
  });

  group('BoardModel.fromJson (production)', () {
    test('parses board from JSON', () {
      final json = {
        'board_id': 'b-json',
        'artist_id': 1,
        'name': {'ko': '테스트', 'en': 'Test'},
        'description': 'Test board',
        'is_official': true,
        'status': 'approved',
        'features': ['image', 'youtube'],
      };

      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('b-json'));
      expect(board.artistId, equals(1));
      expect(board.name['ko'], equals('테스트'));
      expect(board.isOfficial, isTrue);
      expect(board.features, isNotNull);
      expect(board.features!.length, equals(2));
    });

    test('parses board with embedded artist', () {
      final json = {
        'board_id': 'b-with-artist',
        'artist_id': 1,
        'name': {'ko': '게시판'},
        'description': '',
        'artist': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}},
      };

      final board = BoardModel.fromJson(json);
      expect(board.artist, isNotNull);
      expect(board.artist!.id, equals(1));
      expect(board.artist!.name['ko'], equals('BTS'));
    });

    test('parses board with minimal JSON', () {
      final json = {
        'board_id': 'b-min',
        'artist_id': 0,
        'name': {'ko': 'Min'},
        'description': '',
      };

      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('b-min'));
      expect(board.artist, isNull);
      expect(board.features, isNull);
    });
  });

  group('BoardModel serialization round-trip (production)', () {
    test('toJson and fromJson produce equivalent model', () {
      final json = boards[0].toJson();
      expect(json, isNotNull);

      final restored = BoardModel.fromJson(json);
      expect(restored.boardId, equals(boards[0].boardId));
      expect(restored.artistId, equals(boards[0].artistId));
      expect(restored.name['ko'], equals(boards[0].name['ko']));
      expect(restored.isOfficial, equals(boards[0].isOfficial));
    });

    test('board with artist round-trips correctly', () {
      final json = boards[0].toJson();
      final restored = BoardModel.fromJson(json);
      expect(restored.artist, isNotNull);
      expect(restored.artist!.id, equals(testArtist1.id));
    });
  });

  group('ArtistModel (production)', () {
    test('artist with image', () {
      expect(testArtist1.image, equals('https://example.com/bts.jpg'));
    });

    test('artist without image', () {
      final noImageArtist = ArtistModel(id: 3, name: {'ko': 'Test'});
      expect(noImageArtist.image, isNull);
    });

    test('artist serialization round-trip', () {
      final json = testArtist1.toJson();
      final restored = ArtistModel.fromJson(json);
      expect(restored.id, equals(testArtist1.id));
      expect(restored.name['ko'], equals('BTS'));
      expect(restored.image, equals(testArtist1.image));
    });

    test('artist name map with multiple locales', () {
      final artist = ArtistModel(
        id: 5,
        name: {'ko': '방탄소년단', 'en': 'BTS', 'ja': '防弾少年団'},
      );
      expect(artist.name.length, equals(3));
      expect(getLocaleTextFromJsonWithLocale(artist.name, 'ja'), equals('防弾少年団'));
    });
  });

  group('Board filtering with KoreanSearchUtils (production integration)', () {
    // This tests the same pattern used in _getFilteredBoards but
    // calls production KoreanSearchUtils functions directly.
    List<BoardModel> filterBoards(List<BoardModel> boards, String query) {
      if (query.isEmpty) return boards;
      return boards.where((board) {
        final boardNameKo = board.name['ko']?.toString() ?? '';
        final boardNameEn = board.name['en']?.toString() ?? '';

        if (KoreanSearchUtils.matchesKoreanInitials(boardNameKo, query) ||
            boardNameEn.toLowerCase().contains(query.toLowerCase())) {
          return true;
        }

        if (board.artist?.name != null) {
          final artistNameKo = board.artist!.name['ko']?.toString() ?? '';
          final artistNameEn = board.artist!.name['en']?.toString() ?? '';
          if (KoreanSearchUtils.matchesKoreanInitials(artistNameKo, query) ||
              artistNameEn.toLowerCase().contains(query.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    test('returns all boards when query is empty', () {
      expect(filterBoards(boards, '').length, equals(3));
    });

    test('filters by board name (Korean)', () {
      final filtered = filterBoards(boards, '팬아트');
      expect(filtered.length, equals(1));
      expect(filtered[0].boardId, equals('b2'));
    });

    test('filters by board name (English)', () {
      final filtered = filterBoards(boards, 'Fan Art');
      expect(filtered.length, equals(1));
      expect(filtered[0].boardId, equals('b2'));
    });

    test('filters by artist name (Korean)', () {
      final filtered = filterBoards(boards, '블랙핑크');
      expect(filtered.length, equals(1));
      expect(filtered[0].boardId, equals('b3'));
    });

    test('filters by artist name (English)', () {
      final filtered = filterBoards(boards, 'BLACKPINK');
      expect(filtered.length, equals(1));
    });

    test('case insensitive search', () {
      final filtered = filterBoards(boards, 'bts');
      expect(filtered.length, equals(2));
    });

    test('returns empty for no match', () {
      final filtered = filterBoards(boards, 'TWICE');
      expect(filtered.length, equals(0));
    });

    test('filters by Korean initials for board name', () {
      final filtered = filterBoards(boards, 'ㅍㅇㅌ');
      expect(filtered.length, equals(1));
      expect(filtered[0].boardId, equals('b2'));
    });

    test('filters by Korean initials for artist name', () {
      final filtered = filterBoards(boards, 'ㅂㄹㅍㅋ');
      expect(filtered.length, equals(1));
      expect(filtered[0].boardId, equals('b3'));
    });

    test('partial match on board name', () {
      final filtered = filterBoards(boards, 'Free');
      expect(filtered.length, equals(2));
    });

    test('partial match on artist name', () {
      final filtered = filterBoards(boards, 'BLACK');
      expect(filtered.length, equals(1));
    });
  });
}
