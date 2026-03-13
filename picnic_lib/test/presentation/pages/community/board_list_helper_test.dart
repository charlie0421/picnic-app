import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_helper.dart';

BoardModel _makeBoard({
  required String boardId,
  Map<String, dynamic> name = const {'ko': '', 'en': ''},
  ArtistModel? artist,
  bool? isOfficial,
  int artistId = 1,
}) {
  return BoardModel(
    boardId: boardId,
    artistId: artistId,
    name: name,
    description: '',
    isOfficial: isOfficial,
    createdAt: null,
    updatedAt: null,
    artist: artist,
    requestMessage: null,
    status: null,
    creatorId: null,
    features: null,
  );
}

ArtistModel _makeArtist({
  int id = 1,
  Map<String, dynamic> name = const {'ko': '', 'en': ''},
  String? image,
}) {
  return ArtistModel(
    id: id,
    name: name,
    image: image,
  );
}

void main() {
  // ── filterBoards ──────────────────────────────────────────────────────

  group('BoardListHelper.filterBoards', () {
    test('returns all boards when query is empty', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '자유게시판', 'en': 'Free'}),
        _makeBoard(boardId: '2', name: {'ko': '팬아트', 'en': 'Fan Art'}),
      ];
      expect(BoardListHelper.filterBoards(boards, ''), boards);
    });

    test('filters by English board name (case-insensitive)', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '자유게시판', 'en': 'Free Board'}),
        _makeBoard(boardId: '2', name: {'ko': '팬아트', 'en': 'Fan Art'}),
      ];
      final result = BoardListHelper.filterBoards(boards, 'free');
      expect(result.length, 1);
      expect(result.first.boardId, '1');
    });

    test('filters by Korean board name', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '자유게시판', 'en': 'Free Board'}),
        _makeBoard(boardId: '2', name: {'ko': '팬아트', 'en': 'Fan Art'}),
      ];
      final result = BoardListHelper.filterBoards(boards, '팬아트');
      expect(result.length, 1);
      expect(result.first.boardId, '2');
    });

    test('filters by Korean initials of board name', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '자유게시판', 'en': 'Free Board'}),
        _makeBoard(boardId: '2', name: {'ko': '팬아트', 'en': 'Fan Art'}),
      ];
      final result = BoardListHelper.filterBoards(boards, 'ㅍㅇㅌ');
      expect(result.length, 1);
      expect(result.first.boardId, '2');
    });

    test('filters by English artist name', () {
      final artist = _makeArtist(id: 10, name: {'ko': '방탄소년단', 'en': 'BTS'});
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '보드A', 'en': 'A'}, artist: artist),
        _makeBoard(
            boardId: '2',
            name: {'ko': '보드B', 'en': 'B'},
            artist: _makeArtist(id: 20, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'})),
      ];
      final result = BoardListHelper.filterBoards(boards, 'bts');
      expect(result.length, 1);
      expect(result.first.boardId, '1');
    });

    test('filters by Korean artist name', () {
      final artist = _makeArtist(id: 10, name: {'ko': '방탄소년단', 'en': 'BTS'});
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '보드A', 'en': 'A'}, artist: artist),
      ];
      final result = BoardListHelper.filterBoards(boards, '방탄');
      expect(result.length, 1);
    });

    test('filters by Korean initials of artist name', () {
      final artist = _makeArtist(id: 10, name: {'ko': '방탄소년단', 'en': 'BTS'});
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '보드A', 'en': 'A'}, artist: artist),
        _makeBoard(boardId: '2', name: {'ko': '보드B', 'en': 'B'}),
      ];
      final result = BoardListHelper.filterBoards(boards, 'ㅂㅌㅅㄴㄷ');
      expect(result.length, 1);
      expect(result.first.boardId, '1');
    });

    test('returns empty when no match found', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '자유게시판', 'en': 'Free'}),
      ];
      expect(BoardListHelper.filterBoards(boards, 'xyz'), isEmpty);
    });

    test('handles boards without artist gracefully', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'ko': '보드', 'en': 'Board'}),
      ];
      // Should not throw, only board name is checked
      final result = BoardListHelper.filterBoards(boards, 'NoArtist');
      expect(result, isEmpty);
    });

    test('handles missing locale keys gracefully', () {
      final boards = [
        _makeBoard(boardId: '1', name: {'en': 'Only English'}),
      ];
      // ko key is missing; should not throw
      final result = BoardListHelper.filterBoards(boards, 'english');
      expect(result.length, 1);
    });

    test('returns empty list when input is empty', () {
      expect(BoardListHelper.filterBoards([], 'test'), isEmpty);
    });
  });

  // ── groupBoardsByArtist ───────────────────────────────────────────────

  group('BoardListHelper.groupBoardsByArtist', () {
    test('returns empty map for empty list', () {
      expect(BoardListHelper.groupBoardsByArtist([]), isEmpty);
    });

    test('groups boards by artist id', () {
      final artist1 = _makeArtist(id: 1, name: {'en': 'A'});
      final artist2 = _makeArtist(id: 2, name: {'en': 'B'});
      final boards = [
        _makeBoard(boardId: '1', artist: artist1),
        _makeBoard(boardId: '2', artist: artist1),
        _makeBoard(boardId: '3', artist: artist2),
      ];
      final grouped = BoardListHelper.groupBoardsByArtist(boards);
      expect(grouped.keys.length, 2);
      expect(grouped['1']!.length, 2);
      expect(grouped['2']!.length, 1);
    });

    test('excludes boards without artist', () {
      final artist = _makeArtist(id: 1, name: {'en': 'A'});
      final boards = [
        _makeBoard(boardId: '1', artist: artist),
        _makeBoard(boardId: '2'), // no artist
      ];
      final grouped = BoardListHelper.groupBoardsByArtist(boards);
      expect(grouped.keys.length, 1);
      expect(grouped['1']!.length, 1);
    });

    test('returns empty map when all boards lack artist', () {
      final boards = [
        _makeBoard(boardId: '1'),
        _makeBoard(boardId: '2'),
      ];
      expect(BoardListHelper.groupBoardsByArtist(boards), isEmpty);
    });
  });

  // ── deduplicateBoards ─────────────────────────────────────────────────

  group('BoardListHelper.deduplicateBoards', () {
    test('on refresh, uses only new boards', () {
      final existing = [_makeBoard(boardId: '1'), _makeBoard(boardId: '2')];
      final incoming = [_makeBoard(boardId: '3')];
      final result = BoardListHelper.deduplicateBoards(
        existingBoards: existing,
        newBoards: incoming,
        isRefresh: true,
      );
      expect(result.length, 1);
      expect(result.first.boardId, '3');
    });

    test('on refresh, removes duplicates within new boards', () {
      final incoming = [_makeBoard(boardId: '1'), _makeBoard(boardId: '1')];
      final result = BoardListHelper.deduplicateBoards(
        existingBoards: [],
        newBoards: incoming,
        isRefresh: true,
      );
      expect(result.length, 1);
    });

    test('on paginate, appends new boards after existing', () {
      final existing = [_makeBoard(boardId: '1')];
      final incoming = [_makeBoard(boardId: '2')];
      final result = BoardListHelper.deduplicateBoards(
        existingBoards: existing,
        newBoards: incoming,
        isRefresh: false,
      );
      expect(result.length, 2);
      expect(result[0].boardId, '1');
      expect(result[1].boardId, '2');
    });

    test('on paginate, skips duplicates between existing and new', () {
      final existing = [_makeBoard(boardId: '1'), _makeBoard(boardId: '2')];
      final incoming = [_makeBoard(boardId: '2'), _makeBoard(boardId: '3')];
      final result = BoardListHelper.deduplicateBoards(
        existingBoards: existing,
        newBoards: incoming,
        isRefresh: false,
      );
      expect(result.length, 3);
      expect(result.map((b) => b.boardId).toList(), ['1', '2', '3']);
    });

    test('handles both lists empty', () {
      final result = BoardListHelper.deduplicateBoards(
        existingBoards: [],
        newBoards: [],
        isRefresh: false,
      );
      expect(result, isEmpty);
    });
  });

  // ── hasMoreData ───────────────────────────────────────────────────────

  group('BoardListHelper.hasMoreData', () {
    test('returns true when result count equals page size', () {
      expect(BoardListHelper.hasMoreData(20, 20), isTrue);
    });

    test('returns true when result count exceeds page size', () {
      expect(BoardListHelper.hasMoreData(25, 20), isTrue);
    });

    test('returns false when result count is less than page size', () {
      expect(BoardListHelper.hasMoreData(15, 20), isFalse);
    });

    test('returns false for zero results', () {
      expect(BoardListHelper.hasMoreData(0, 20), isFalse);
    });
  });

  // ── boardChipColorKey ─────────────────────────────────────────────────

  group('BoardListHelper.boardChipColorKey', () {
    test('returns primary for official board', () {
      expect(BoardListHelper.boardChipColorKey(true), 'primary');
    });

    test('returns default for non-official board', () {
      expect(BoardListHelper.boardChipColorKey(false), 'default');
    });

    test('returns default for null', () {
      expect(BoardListHelper.boardChipColorKey(null), 'default');
    });
  });
}
