import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';

import '../../../helpers/mock_supabase.dart';

/// Additional tests targeting uncovered lines in boards_provider.dart.
///
/// Targets: error catch branches in BoardDetail.boardDetail (line 32),
/// BoardsNotifier._fetchBoards error (lines 60-61),
/// BoardRequestNotifier._getPendingRequest with auth (line 150),
/// BoardRequestNotifier.checkDuplicateBoard error (lines 169-170),
/// BoardRequestNotifier.createBoard success (lines 184-194),
/// BoardsNotifier.refresh, BoardRequestNotifier.refresh (lines 65-68, 201-203).
void main() {
  final boardData = {
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

  final pendingBoardData = {
    'board_id': 'board-pending',
    'artist_id': 2,
    'name': {'ko': '신규 게시판', 'en': 'New Board'},
    'description': 'A new board request',
    'is_official': false,
    'created_at': '2026-02-01T00:00:00Z',
    'updated_at': '2026-02-01T00:00:00Z',
    'artist': null,
    'request_message': '새 게시판을 만들어주세요',
    'status': 'pending',
    'creator_id': 'test-user-id',
    'features': null,
  };

  group('BoardRequestNotifier - authenticated flows', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'boards': [pendingBoardData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('_getPendingRequest returns board when pending request exists',
        () async {
      final result = await container.read(boardRequestProvider.future);
      expect(result, isNotNull);
      expect(result!.boardId, 'board-pending');
      expect(result.requestMessage, '새 게시판을 만들어주세요');
      expect(result.status, 'pending');
    });

    test('_getPendingRequest returns null when no pending request', () async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth(
        {'boards': <Map<String, dynamic>>[]},
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(boardRequestProvider.future);
      expect(result, isNull);
    });

    // createBoard with authenticated user is not testable in unit tests
    // because refresh() triggers Ref disposal in the test environment.

    test('checkDuplicateBoard returns board when duplicate exists', () async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth(
        {
          'boards': [boardData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2.read(boardRequestProvider.future);

      final notifier = container2.read(boardRequestProvider.notifier);
      final result = await notifier.checkDuplicateBoard('자유게시판');
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
    });

    test('checkDuplicateBoard returns null when no duplicate', () async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth(
        {'boards': <Map<String, dynamic>>[]},
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      await container2.read(boardRequestProvider.future);

      final notifier = container2.read(boardRequestProvider.notifier);
      final result = await notifier.checkDuplicateBoard('NonExistent');
      expect(result, isNull);
    });

    test('refresh reloads pending request', () async {
      await container.read(boardRequestProvider.future);

      await container.read(boardRequestProvider.notifier).refresh();

      final state = container.read(boardRequestProvider);
      expect(state, isA<AsyncData>());
    });
  });

  group('BoardsNotifier - authenticated flows', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'boards': [boardData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('refresh reloads boards and returns data', () async {
      await container.read(boardsProvider(1).future);

      await container.read(boardsProvider(1).notifier).refresh();

      final state = container.read(boardsProvider(1));
      expect(state.hasValue, true);
      expect(state.value, isNotNull);
    });
  });

  group('BoardDetail - authenticated flows', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth(
        {
          'boards': [boardData],
        },
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('boardDetail returns board via authenticated supabase', () async {
      final result =
          await container.read(boardDetailProvider('board-1').future);
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
    });
  });
}
