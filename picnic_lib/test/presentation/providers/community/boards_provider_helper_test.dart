import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider_helper.dart';

void main() {
  final boardJson = {
    'board_id': 'board-1',
    'artist_id': 1,
    'name': {'ko': '자유게시판', 'en': 'Free Board'},
    'description': 'A free board',
    'is_official': true,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'artist': null,
    'request_message': null,
    'status': 'approved',
    'creator_id': null,
    'features': <String>[],
  };

  final boardJson2 = {
    'board_id': 'board-2',
    'artist_id': 1,
    'name': {'ko': '팬아트', 'en': 'Fan Art'},
    'description': 'Fan art board',
    'is_official': false,
    'created_at': '2026-01-02T00:00:00Z',
    'updated_at': '2026-01-02T00:00:00Z',
    'artist': null,
    'request_message': null,
    'status': 'approved',
    'creator_id': null,
    'features': <String>[],
  };

  group('BoardsProviderHelper.parseBoardDetail', () {
    test('returns BoardModel when response is not null', () {
      final result = BoardsProviderHelper.parseBoardDetail(boardJson);
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
      expect(result.name['ko'], '자유게시판');
      expect(result.isOfficial, true);
    });

    test('returns null when response is null', () {
      final result = BoardsProviderHelper.parseBoardDetail(null);
      expect(result, isNull);
    });

    test('parses all fields correctly', () {
      final result = BoardsProviderHelper.parseBoardDetail(boardJson);
      expect(result!.artistId, 1);
      expect(result.description, 'A free board');
      expect(result.status, 'approved');
      expect(result.creatorId, isNull);
      expect(result.requestMessage, isNull);
      expect(result.features, isEmpty);
      expect(result.artist, isNull);
    });
  });

  group('BoardsProviderHelper.parseBoardList', () {
    test('parses empty list', () {
      final result =
          BoardsProviderHelper.parseBoardList(<Map<String, dynamic>>[]);
      expect(result, isEmpty);
    });

    test('parses single item', () {
      final result = BoardsProviderHelper.parseBoardList([boardJson]);
      expect(result.length, 1);
      expect(result[0].boardId, 'board-1');
    });

    test('parses multiple items preserving order', () {
      final result =
          BoardsProviderHelper.parseBoardList([boardJson, boardJson2]);
      expect(result.length, 2);
      expect(result[0].boardId, 'board-1');
      expect(result[1].boardId, 'board-2');
      expect(result[0].isOfficial, true);
      expect(result[1].isOfficial, false);
    });
  });

  group('BoardsProviderHelper.buildCreateBoardData', () {
    test('builds correct data map', () {
      final data = BoardsProviderHelper.buildCreateBoardData(
        artistId: 42,
        title: 'New Board',
        description: 'A description',
        requestMessage: 'Please approve',
        userId: 'user-123',
      );

      expect(data['artist_id'], 42);
      expect(data['description'], 'A description');
      expect(data['status'], 'pending');
      expect(data['request_message'], 'Please approve');
      expect(data['creator_id'], 'user-123');
      expect(data['is_official'], false);
      expect(data['order'], 0);
      expect(data['features'], isEmpty);
    });

    test('sets name in all four languages to the same title', () {
      final data = BoardsProviderHelper.buildCreateBoardData(
        artistId: 1,
        title: 'My Board',
        description: '',
        requestMessage: '',
        userId: 'u1',
      );

      final name = data['name'] as Map<String, String>;
      expect(name['ko'], 'My Board');
      expect(name['en'], 'My Board');
      expect(name['ja'], 'My Board');
      expect(name['zh_CN'], 'My Board');
    });

    test('handles empty strings', () {
      final data = BoardsProviderHelper.buildCreateBoardData(
        artistId: 0,
        title: '',
        description: '',
        requestMessage: '',
        userId: '',
      );

      expect(data['artist_id'], 0);
      expect(data['creator_id'], '');
      expect((data['name'] as Map)['ko'], '');
    });

    test('handles special characters in title', () {
      final data = BoardsProviderHelper.buildCreateBoardData(
        artistId: 1,
        title: '게시판 <특수> & "문자"',
        description: 'desc',
        requestMessage: 'msg',
        userId: 'u1',
      );

      expect((data['name'] as Map)['ko'], '게시판 <특수> & "문자"');
    });
  });
}
