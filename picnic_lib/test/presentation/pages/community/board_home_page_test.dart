import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

/// Tests for BoardHomePage logic patterns and data models.
///
/// Widget rendering tests for BoardHomePage are limited because
/// it requires boardsProvider (which calls Supabase), getArtistProvider,
/// RouteAwareStateMixin, and supabase.auth.currentUser.
/// Instead we test the board filtering, tab logic, and model patterns
/// that the page relies on.
void main() {
  group('BoardHomePage tab logic', () {
    test('calculates total pages with request button', () {
      final boards = [
        _createBoard('b-1', 'approved'),
        _createBoard('b-2', 'approved'),
        _createBoard('b-3', 'approved'),
      ];

      const showRequestButton = true;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 5); // 3 boards + "all" tab + request tab
    });

    test('calculates total pages without request button', () {
      final boards = [
        _createBoard('b-1', 'approved'),
        _createBoard('b-2', 'approved'),
      ];

      const showRequestButton = false;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 3); // 2 boards + "all" tab
    });

    test('hasApprovedBoards returns true when user has approved board', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'approved', creatorId: currentUserId),
        _createBoard('b-2', 'pending', creatorId: 'other'),
      ];

      final hasApprovedBoards = boards.any(
        (board) =>
            board.status == 'approved' && board.creatorId == currentUserId,
      );
      expect(hasApprovedBoards, true);
    });

    test('hasApprovedBoards returns false when no approved boards', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'pending', creatorId: currentUserId),
        _createBoard('b-2', 'approved', creatorId: 'other'),
      ];

      final hasApprovedBoards = boards.any(
        (board) =>
            board.status == 'approved' && board.creatorId == currentUserId,
      );
      expect(hasApprovedBoards, false);
    });

    test('hasPendingBoard returns true when user has pending board', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'approved', creatorId: 'other'),
        _createBoard('b-2', 'pending', creatorId: currentUserId),
      ];

      final hasPendingBoard = boards.any(
        (board) =>
            board.status == 'pending' && board.creatorId == currentUserId,
      );
      expect(hasPendingBoard, true);
    });

    test('showRequestButton logic - no approved boards', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'approved', creatorId: 'other'),
      ];

      final hasApprovedBoards = boards.any(
        (board) =>
            board.status == 'approved' && board.creatorId == currentUserId,
      );
      final hasPendingBoard = boards.any(
        (board) =>
            board.status == 'pending' && board.creatorId == currentUserId,
      );

      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, true);
    });

    test('showRequestButton logic - has approved boards and no pending', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'approved', creatorId: currentUserId),
      ];

      final hasApprovedBoards = boards.any(
        (board) =>
            board.status == 'approved' && board.creatorId == currentUserId,
      );
      final hasPendingBoard = boards.any(
        (board) =>
            board.status == 'pending' && board.creatorId == currentUserId,
      );

      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, false);
    });

    test('showRequestButton logic - has both approved and pending', () {
      const currentUserId = 'user-1';
      final boards = [
        _createBoard('b-1', 'approved', creatorId: currentUserId),
        _createBoard('b-2', 'pending', creatorId: currentUserId),
      ];

      final hasApprovedBoards = boards.any(
        (board) =>
            board.status == 'approved' && board.creatorId == currentUserId,
      );
      final hasPendingBoard = boards.any(
        (board) =>
            board.status == 'pending' && board.creatorId == currentUserId,
      );

      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, true);
    });
  });

  group('BoardHomePage board initialization', () {
    test('finds board index by boardId', () {
      final boards = [
        _createBoard('b-1', 'approved'),
        _createBoard('b-2', 'approved'),
        _createBoard('b-3', 'approved'),
      ];

      const targetBoardId = 'b-2';
      final index = boards.indexWhere(
        (board) => board.boardId == targetBoardId,
      );
      expect(index, 1);
      // The actual page index is index + 1 (because of "all" tab at 0)
      expect(index + 1, 2);
    });

    test('returns -1 when board not found', () {
      final boards = [
        _createBoard('b-1', 'approved'),
      ];

      const targetBoardId = 'nonexistent';
      final index = boards.indexWhere(
        (board) => board.boardId == targetBoardId,
      );
      expect(index, -1);
    });
  });

  group('BoardModel for board home', () {
    test('creates official board', () {
      final board = _createBoard('b-1', 'approved', isOfficial: true);
      expect(board.isOfficial, true);
    });

    test('creates non-official board', () {
      final board = _createBoard('b-1', 'approved', isOfficial: false);
      expect(board.isOfficial, false);
    });

    test('board with features', () {
      final board = BoardModel(
        boardId: 'b-1',
        artistId: 1,
        name: {'ko': '게시판'},
        description: '설명',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: 'approved',
        creatorId: null,
        features: ['post', 'comment', 'media'],
      );
      expect(board.features?.length, 3);
      expect(board.features, contains('post'));
      expect(board.features, contains('comment'));
      expect(board.features, contains('media'));
    });

    test('board with artist', () {
      final board = BoardModel(
        boardId: 'b-1',
        artistId: 42,
        name: {'ko': '게시판', 'en': 'Board'},
        description: '설명',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: ArtistModel(
          id: 42,
          name: {'ko': 'BTS', 'en': 'BTS'},
        ),
        requestMessage: null,
        status: 'approved',
        creatorId: null,
        features: [],
      );
      expect(board.artist, isNotNull);
      expect(board.artist!.id, 42);
    });
  });
}

BoardModel _createBoard(
  String boardId,
  String status, {
  String? creatorId,
  bool? isOfficial,
}) {
  return BoardModel(
    boardId: boardId,
    artistId: 1,
    name: {'ko': '게시판 $boardId'},
    description: '설명',
    isOfficial: isOfficial ?? false,
    createdAt: null,
    updatedAt: null,
    artist: null,
    requestMessage: null,
    status: status,
    creatorId: creatorId,
    features: [],
  );
}
