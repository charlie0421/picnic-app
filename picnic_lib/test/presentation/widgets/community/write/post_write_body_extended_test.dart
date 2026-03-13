import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

/// Tests that exercise production code from post_write_body.dart
/// and its direct dependencies (BoardModel, ArtistModel, locale_utils).
///
/// Widget rendering is blocked by transitive flutter_quill / flutter_svg /
/// keyboard_height_plugin / image_picker imports.
/// We focus on exercising production model code and serialization.
void main() {
  group('BoardModel features for write toolbar (production)', () {
    test('board with all features', () {
      final board = BoardModel(
        boardId: 'b1',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: ['image', 'link', 'youtube', 'attachment'],
      );

      expect(board.features, isNotNull);
      expect(board.features!.contains('image'), isTrue);
      expect(board.features!.contains('link'), isTrue);
      expect(board.features!.contains('youtube'), isTrue);
      expect(board.features!.contains('attachment'), isTrue);
      expect(board.features!.length, equals(4));
    });

    test('board with no features (null)', () {
      final board = BoardModel(
        boardId: 'b2',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
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
      expect(board.features != null && board.features!.contains('image'), isFalse);
    });

    test('board with empty features list', () {
      final board = BoardModel(
        boardId: 'b3',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
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
      expect(board.features != null && board.features!.contains('image'), isFalse);
    });

    test('board with only image and youtube', () {
      final board = BoardModel(
        boardId: 'b4',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: ['image', 'youtube'],
      );

      expect(board.features!.contains('image'), isTrue);
      expect(board.features!.contains('link'), isFalse);
      expect(board.features!.contains('youtube'), isTrue);
      expect(board.features!.contains('attachment'), isFalse);
    });

    test('board with only link feature', () {
      final board = BoardModel(
        boardId: 'b5',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: ['link'],
      );

      expect(board.features!.contains('link'), isTrue);
      expect(board.features!.length, equals(1));
    });
  });

  group('BoardModel.fromJson for write context (production)', () {
    test('parses board with features from JSON', () {
      final json = {
        'board_id': 'b-json',
        'artist_id': 1,
        'name': {'ko': '자유게시판', 'en': 'Free Board'},
        'description': 'Free Board',
        'is_official': true,
        'features': ['image', 'link', 'youtube'],
      };

      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('b-json'));
      expect(board.features, isNotNull);
      expect(board.features!.length, equals(3));
      expect(board.features!.contains('image'), isTrue);
    });

    test('parses board without features from JSON', () {
      final json = {
        'board_id': 'b-json2',
        'artist_id': 1,
        'name': {'ko': '테스트'},
        'description': '',
      };

      final board = BoardModel.fromJson(json);
      expect(board.features, isNull);
    });

    test('parses board with artist from JSON', () {
      final json = {
        'board_id': 'b-json3',
        'artist_id': 1,
        'name': {'ko': '게시판'},
        'description': '',
        'artist': {'id': 1, 'name': {'ko': 'BTS', 'en': 'BTS'}},
        'features': ['image'],
      };

      final board = BoardModel.fromJson(json);
      expect(board.artist, isNotNull);
      expect(board.artist!.name['ko'], equals('BTS'));
    });
  });

  group('BoardModel serialization round-trip (production)', () {
    test('round-trip preserves features', () {
      final board = BoardModel(
        boardId: 'b-rt',
        artistId: 1,
        name: {'ko': '테스트', 'en': 'Test'},
        description: 'Round trip test',
        isOfficial: true,
        createdAt: null,
        updatedAt: null,
        artist: ArtistModel(id: 1, name: {'ko': 'BTS'}),
        requestMessage: null,
        status: 'approved',
        creatorId: null,
        features: ['image', 'link', 'youtube'],
      );

      final json = board.toJson();
      final restored = BoardModel.fromJson(json);

      expect(restored.boardId, equals(board.boardId));
      expect(restored.features, isNotNull);
      expect(restored.features!.length, equals(3));
      expect(restored.features!.contains('image'), isTrue);
      expect(restored.isOfficial, equals(board.isOfficial));
      expect(restored.artist, isNotNull);
    });
  });

  group('BoardModel name locale access for write page (production)', () {
    test('gets Korean board name', () {
      final board = BoardModel(
        boardId: 'b-name',
        artistId: 1,
        name: {'ko': '자유게시판', 'en': 'Free Board'},
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

      expect(
        getLocaleTextFromJsonWithLocale(board.name, 'ko'),
        equals('자유게시판'),
      );
    });

    test('gets English board name', () {
      final board = BoardModel(
        boardId: 'b-name2',
        artistId: 1,
        name: {'ko': '팬아트', 'en': 'Fan Art'},
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

      expect(
        getLocaleTextFromJsonWithLocale(board.name, 'en'),
        equals('Fan Art'),
      );
    });

    test('falls back to en for unknown locale', () {
      final board = BoardModel(
        boardId: 'b-name3',
        artistId: 1,
        name: {'ko': '공지', 'en': 'Notice'},
        description: '',
        isOfficial: true,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );

      expect(
        getLocaleTextFromJsonWithLocale(board.name, 'de'),
        equals('Notice'),
      );
    });
  });

  group('ArtistModel for write context (production)', () {
    test('artist serialization round-trip', () {
      final artist = ArtistModel(
        id: 1,
        name: {'ko': 'BTS', 'en': 'BTS'},
        image: 'https://example.com/bts.jpg',
      );

      final json = artist.toJson();
      final restored = ArtistModel.fromJson(json);

      expect(restored.id, equals(artist.id));
      expect(restored.name['ko'], equals('BTS'));
      expect(restored.image, equals(artist.image));
    });

    test('artist from JSON', () {
      final json = {
        'id': 2,
        'name': {'ko': '블랙핑크', 'en': 'BLACKPINK'},
      };

      final artist = ArtistModel.fromJson(json);
      expect(artist.id, equals(2));
      expect(artist.name['ko'], equals('블랙핑크'));
    });
  });

  group('Link embed data encoding (production jsonEncode/jsonDecode)', () {
    test('encodes link embed data correctly', () {
      final name = 'Example Site';
      final url = 'https://example.com';
      final embedData = jsonEncode({'name': name, 'url': url});
      final decoded = jsonDecode(embedData) as Map<String, dynamic>;

      expect(decoded['name'], equals('Example Site'));
      expect(decoded['url'], equals('https://example.com'));
    });

    test('encodes link with null name', () {
      String? name;
      final url = 'https://example.com';
      final embedData = jsonEncode({'name': name, 'url': url});
      final decoded = jsonDecode(embedData) as Map<String, dynamic>;

      expect(decoded['name'], isNull);
      expect(decoded['url'], equals('https://example.com'));
    });

    test('encodes link with special characters in URL', () {
      final url = 'https://example.com/path?key=value&foo=bar#section';
      final embedData = jsonEncode({'name': null, 'url': url});
      final decoded = jsonDecode(embedData) as Map<String, dynamic>;

      expect(decoded['url'], equals(url));
    });

    test('round-trips complex embed data', () {
      final original = {
        'name': 'YouTube Video',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'type': 'youtube',
      };

      final encoded = jsonEncode(original);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['name'], equals(original['name']));
      expect(decoded['url'], equals(original['url']));
      expect(decoded['type'], equals(original['type']));
    });
  });

  group('BoardModel constructor edge cases (production)', () {
    test('board with all null optional fields', () {
      final board = BoardModel(
        boardId: 'b-edge',
        artistId: 0,
        name: {},
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

      expect(board.boardId, equals('b-edge'));
      expect(board.name, isEmpty);
      expect(board.isOfficial, isNull);
      expect(board.artist, isNull);
      expect(board.features, isNull);
    });

    test('board with timestamps', () {
      final now = DateTime.now();
      final board = BoardModel(
        boardId: 'b-ts',
        artistId: 1,
        name: {'ko': 'Time'},
        description: 'With timestamps',
        isOfficial: true,
        createdAt: now,
        updatedAt: now,
        artist: null,
        requestMessage: 'Please approve',
        status: 'pending',
        creatorId: 'user-1',
        features: ['image'],
      );

      expect(board.createdAt, equals(now));
      expect(board.updatedAt, equals(now));
      expect(board.requestMessage, equals('Please approve'));
      expect(board.creatorId, equals('user-1'));
    });
  });

  group('getLocaleTextFromJsonWithLocale for write context (production)', () {
    test('handles zh_CN normalization', () {
      final json = {'zh': '中文', 'en': 'English'};
      expect(getLocaleTextFromJsonWithLocale(json, 'zh_CN'), equals('中文'));
    });

    test('handles zh_TW normalization', () {
      final json = {'zh-TW': '繁體', 'en': 'English'};
      expect(getLocaleTextFromJsonWithLocale(json, 'zh_TW'), equals('繁體'));
    });

    test('handles bn normalization', () {
      final json = {'bn': 'বাংলা', 'en': 'Bengali'};
      expect(getLocaleTextFromJsonWithLocale(json, 'bn_BD'), equals('বাংলা'));
    });

    test('handles empty json', () {
      expect(getLocaleTextFromJsonWithLocale({}, 'ko'), equals(''));
    });

    test('handles ko locale', () {
      final json = {'ko': '한국어', 'en': 'Korean'};
      expect(getLocaleTextFromJsonWithLocale(json, 'ko'), equals('한국어'));
    });
  });
}
