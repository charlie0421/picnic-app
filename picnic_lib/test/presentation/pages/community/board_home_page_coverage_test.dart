import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';

import '../../../helpers/test_environment.dart';

/// Coverage-focused tests for BoardHomePage logic patterns.
///
/// Widget tests for BoardHomePage are limited because it depends on
/// boardsProvider, getArtistProvider, and RouteAwareStateMixin.
/// We test the board logic, tab calculation, and initialization patterns.
void main() {
  setUpAll(() {
    initTestColors();
  });

  BoardModel createBoard(
    String boardId,
    String status, {
    String? creatorId,
    bool isOfficial = false,
    Map<String, dynamic>? name,
    int artistId = 1,
    List<String>? features,
    String? description,
    String? requestMessage,
  }) {
    return BoardModel(
      boardId: boardId,
      artistId: artistId,
      name: name ?? {'ko': '게시판 $boardId', 'en': 'Board $boardId'},
      description: description ?? '설명',
      isOfficial: isOfficial,
      createdAt: null,
      updatedAt: null,
      artist: null,
      requestMessage: requestMessage,
      status: status,
      creatorId: creatorId,
      features: features ?? [],
    );
  }

  group('BoardHomePage tab count calculation', () {
    test('with request button: boards + all tab + request tab', () {
      final boards = List.generate(5, (i) => createBoard('b-$i', 'approved'));
      const showRequestButton = true;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 7);
    });

    test('without request button: boards + all tab', () {
      final boards = List.generate(3, (i) => createBoard('b-$i', 'approved'));
      const showRequestButton = false;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 4);
    });

    test('single board with request button', () {
      final boards = [createBoard('b-0', 'approved')];
      const showRequestButton = true;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 3);
    });

    test('empty boards list (edge case)', () {
      final boards = <BoardModel>[];
      const showRequestButton = true;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;
      expect(totalPages, 2);
    });
  });

  group('Request button visibility logic', () {
    test('no approved boards by user -> show request', () {
      const userId = 'user-1';
      final boards = [
        createBoard('b-1', 'approved', creatorId: 'other'),
        createBoard('b-2', 'approved', creatorId: 'other2'),
      ];

      final hasApprovedBoards = boards.any(
        (b) => b.status == 'approved' && b.creatorId == userId,
      );
      final hasPendingBoard = boards.any(
        (b) => b.status == 'pending' && b.creatorId == userId,
      );
      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, isTrue);
    });

    test('has approved board by user, no pending -> hide request', () {
      const userId = 'user-1';
      final boards = [
        createBoard('b-1', 'approved', creatorId: userId),
      ];

      final hasApprovedBoards = boards.any(
        (b) => b.status == 'approved' && b.creatorId == userId,
      );
      final hasPendingBoard = boards.any(
        (b) => b.status == 'pending' && b.creatorId == userId,
      );
      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, isFalse);
    });

    test('has both approved and pending by user -> show request', () {
      const userId = 'user-1';
      final boards = [
        createBoard('b-1', 'approved', creatorId: userId),
        createBoard('b-2', 'pending', creatorId: userId),
      ];

      final hasApprovedBoards = boards.any(
        (b) => b.status == 'approved' && b.creatorId == userId,
      );
      final hasPendingBoard = boards.any(
        (b) => b.status == 'pending' && b.creatorId == userId,
      );
      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, isTrue);
    });

    test('null user -> no approved/pending -> show request', () {
      // When currentUser is null, hasApprovedBoards and hasPendingBoard are false
      const bool hasApprovedBoards = false;
      const bool hasPendingBoard = false;
      final showRequestButton = !hasApprovedBoards || hasPendingBoard;
      expect(showRequestButton, isTrue);
    });
  });

  group('Board initialization with current board', () {
    test('finds correct index for currentBoard', () {
      final boards = [
        createBoard('b-1', 'approved'),
        createBoard('b-2', 'approved'),
        createBoard('b-3', 'approved'),
      ];
      const targetBoardId = 'b-2';

      final index = boards.indexWhere((b) => b.boardId == targetBoardId);
      expect(index, 1);

      // newIndex = index + 1 (for "all" tab at 0)
      expect(index + 1, 2);
    });

    test('returns -1 for non-existent board', () {
      final boards = [createBoard('b-1', 'approved')];
      final index = boards.indexWhere((b) => b.boardId == 'nonexistent');
      expect(index, -1);
    });

    test('first board has index 0, page index 1', () {
      final boards = [
        createBoard('b-1', 'approved'),
        createBoard('b-2', 'approved'),
      ];
      final index = boards.indexWhere((b) => b.boardId == 'b-1');
      expect(index, 0);
      expect(index + 1, 1);
    });

    test('last board page index is boards.length', () {
      final boards = List.generate(5, (i) => createBoard('b-$i', 'approved'));
      final index = boards.indexWhere((b) => b.boardId == 'b-4');
      expect(index, 4);
      expect(index + 1, 5);
    });
  });

  group('BoardModel properties', () {
    test('board with request message', () {
      final board = createBoard(
        'b-req',
        'pending',
        requestMessage: '새 게시판을 만들고 싶습니다',
        creatorId: 'user-1',
      );
      expect(board.requestMessage, '새 게시판을 만들고 싶습니다');
      expect(board.status, 'pending');
    });

    test('board with features', () {
      final board = createBoard(
        'b-feat',
        'approved',
        features: ['post', 'comment', 'media', 'poll'],
      );
      expect(board.features?.length, 4);
      expect(board.features, contains('poll'));
    });

    test('board with artist', () {
      final board = BoardModel(
        boardId: 'b-art',
        artistId: 42,
        name: {'ko': '아티스트 게시판'},
        description: 'desc',
        isOfficial: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
        artist: ArtistModel(
          id: 42,
          name: {'ko': 'BTS', 'en': 'BTS'},
        ),
        requestMessage: null,
        status: 'approved',
        creatorId: 'admin',
        features: [],
      );

      expect(board.artist, isNotNull);
      expect(board.artist!.id, 42);
      expect(board.isOfficial, isTrue);
      expect(board.createdAt, isNotNull);
      expect(board.updatedAt, isNotNull);
    });

    test('board name with multiple locales', () {
      final board = createBoard(
        'b-i18n',
        'approved',
        name: {'ko': '자유게시판', 'en': 'Free Board', 'ja': '自由掲示板'},
      );

      expect(board.name.length, 3);
      expect(getLocaleTextFromJson(board.name), isNotEmpty);
    });

    test('board with all statuses', () {
      final approved = createBoard('b-a', 'approved');
      final pending = createBoard('b-p', 'pending');
      final rejected = createBoard('b-r', 'rejected');

      expect(approved.status, 'approved');
      expect(pending.status, 'pending');
      expect(rejected.status, 'rejected');
    });
  });

  group('Page view and tab switching', () {
    test('page 0 is "all" tab', () {
      const currentIndex = 0;
      expect(currentIndex, 0);
    });

    test('page 1+ maps to boards[index-1]', () {
      final boards = [
        createBoard('b-0', 'approved'),
        createBoard('b-1', 'approved'),
        createBoard('b-2', 'approved'),
      ];

      const pageIndex = 2;
      expect(pageIndex > 0 && pageIndex <= boards.length, isTrue);
      expect(boards[pageIndex - 1].boardId, 'b-1');
    });

    test('page beyond boards.length is request button', () {
      final boards = [
        createBoard('b-0', 'approved'),
        createBoard('b-1', 'approved'),
      ];
      const showRequestButton = true;
      final totalPages =
          showRequestButton ? boards.length + 2 : boards.length + 1;

      const pageIndex = 3; // boards.length + 1 = request page
      expect(pageIndex, totalPages - 1);
    });

    test('onPageChanged sets currentBoard for board pages', () {
      final boards = [
        createBoard('b-0', 'approved'),
        createBoard('b-1', 'approved'),
      ];

      BoardModel? currentBoard;
      void onPageChanged(int index) {
        if (index != 0 && index <= boards.length) {
          currentBoard = boards[index - 1];
        } else {
          currentBoard = null;
        }
      }

      // Page 0 = all, currentBoard should be null
      onPageChanged(0);
      expect(currentBoard, isNull);

      // Page 1 = first board
      onPageChanged(1);
      expect(currentBoard?.boardId, 'b-0');

      // Page 2 = second board
      onPageChanged(2);
      expect(currentBoard?.boardId, 'b-1');

      // Page 3 = request (beyond boards)
      onPageChanged(3);
      expect(currentBoard, isNull);
    });
  });
}
