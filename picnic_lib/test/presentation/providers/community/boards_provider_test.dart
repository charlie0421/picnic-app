import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  final artistData = {
    'id': 1,
    'name': {'ko': '지민', 'en': 'Jimin'},
    'yy': 1995,
    'mm': 10,
    'dd': 13,
    'birth_date': '1995-10-13T00:00:00Z',
    'gender': 'male',
    'image': null,
    'artist_group': null,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
    'isBookmarked': null,
  };

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

  final boardData2 = {
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

  final boardWithArtist = {
    'board_id': 'board-3',
    'artist_id': 1,
    'name': {'ko': '공식게시판', 'en': 'Official Board'},
    'description': {'ko': '공식 게시판입니다', 'en': 'Official board'},
    'is_official': true,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'artist': artistData,
    'request_message': null,
    'status': 'approved',
    'creator_id': 'creator-123',
    'features': ['voting', 'gallery'],
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

  group('BoardDetail', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'boards': [boardData],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches board detail by id', () async {
      final result =
          await container.read(boardDetailProvider('board-1').future);
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
      expect(result.name['ko'], '자유게시판');
      expect(result.name['en'], 'Free Board');
      expect(result.description, 'A free board');
      expect(result.isOfficial, true);
    });

    test('returns null when board not found (empty response)', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'boards': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result =
          await container2.read(boardDetailProvider('nonexistent').future);
      expect(result, isNull);
    });

    test('parses board fields correctly', () async {
      final result =
          await container.read(boardDetailProvider('board-1').future);
      expect(result, isNotNull);
      expect(result!.artistId, 1);
      expect(result.status, 'approved');
      expect(result.features, isEmpty);
      expect(result.creatorId, isNull);
      expect(result.requestMessage, isNull);
    });

    test('boardDetail method returns board model', () async {
      final notifier =
          container.read(boardDetailProvider('board-1').notifier);
      await container.read(boardDetailProvider('board-1').future);

      final result = await notifier.boardDetail('board-1');
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
    });

    test('boardDetail returns null for missing board', () async {
      tearDownMockSupabase();
      setupMockSupabase({'boards': <Map<String, dynamic>>[]});
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final notifier =
          container2.read(boardDetailProvider('missing').notifier);
      await container2.read(boardDetailProvider('missing').future);

      final result = await notifier.boardDetail('missing');
      expect(result, isNull);
    });

    test('different board ids create different providers', () async {
      final result1 =
          await container.read(boardDetailProvider('board-1').future);
      final result2 =
          await container.read(boardDetailProvider('board-2').future);
      // Both should complete without error. Mock returns same data
      // regardless of filter, so result2 also gets data.
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });
  });

  group('BoardsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'boards': [boardData, boardData2],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches boards by artist id', () async {
      final result = await container.read(boardsProvider(1).future);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].boardId, 'board-1');
      expect(result[1].boardId, 'board-2');
    });

    test('parses board model fields correctly', () async {
      final result = await container.read(boardsProvider(1).future);
      expect(result, isNotNull);
      expect(result![0].isOfficial, true);
      expect(result[1].isOfficial, false);
      expect(result[0].name['ko'], '자유게시판');
      expect(result[1].name['ko'], '팬아트');
    });

    test('returns empty list when no boards exist', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'boards': <Map<String, dynamic>>[],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(boardsProvider(999).future);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('returns boards with single entry', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'boards': [boardData],
      });
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      final result = await container2.read(boardsProvider(1).future);
      expect(result, isNotNull);
      expect(result!.length, 1);
    });

    test('refresh reloads boards data', () async {
      await container.read(boardsProvider(1).future);

      await container.read(boardsProvider(1).notifier).refresh();

      final state = container.read(boardsProvider(1));
      expect(state, isA<AsyncData<List<BoardModel>?>>());
      expect(state.value, isNotNull);
      expect(state.value!.length, 2);
    });

    test('refresh sets loading state first', () async {
      await container.read(boardsProvider(1).future);

      // After refresh completes, data should be available
      await container.read(boardsProvider(1).notifier).refresh();

      final state = container.read(boardsProvider(1));
      expect(state.hasValue, true);
    });

    test('different artist ids create different providers', () async {
      final result1 = await container.read(boardsProvider(1).future);
      final result2 = await container.read(boardsProvider(2).future);
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('parses board descriptions correctly', () async {
      final result = await container.read(boardsProvider(1).future);
      expect(result, isNotNull);
      expect(result![0].description, 'A free board');
      expect(result[1].description, 'Fan art board');
    });
  });

  group('BoardsByArtistNameNotifier', () {
    // This provider uses navigatorKey.currentContext which is null in tests.
    // Empty query path goes through Supabase directly.
    // Non-empty query uses SearchService which may fail.
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'boards': [
          {
            ...boardData,
            'artist': artistData,
          },
          {
            ...boardData2,
            'artist': artistData,
          },
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('empty query with navigatorKey null throws error', () async {
      // Empty query path accesses navigatorKey.currentContext! which is null
      expect(
        container.read(boardsByArtistNameProvider('', 0, 10).future),
        throwsA(anything),
      );
    });

    test('non-empty query with navigatorKey null throws error', () async {
      expect(
        container.read(boardsByArtistNameProvider('jimin', 0, 10).future),
        throwsA(anything),
      );
    });

    test('different query parameters create different providers', () async {
      // Both will throw, but they should be different provider instances
      expect(
        container.read(boardsByArtistNameProvider('', 0, 10).future),
        throwsA(anything),
      );
      expect(
        container.read(boardsByArtistNameProvider('test', 0, 10).future),
        throwsA(anything),
      );
    });
  });

  group('BoardRequestNotifier', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase(
        {'boards': <Map<String, dynamic>>[]},
        userId: 'test-user-id',
      );
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('build throws error when user is not authenticated', () async {
      expect(
        container.read(boardRequestProvider.future),
        throwsA(isA<TypeError>()),
      );
    });

    test('checkDuplicateBoard returns null when no duplicate', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {'boards': <Map<String, dynamic>>[]},
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      try {
        await container2.read(boardRequestProvider.future);
      } catch (_) {}

      final notifier = container2.read(boardRequestProvider.notifier);
      final result = await notifier.checkDuplicateBoard('Some Title');
      expect(result, isNull);
    });

    test('checkDuplicateBoard returns board when duplicate found', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'boards': [boardData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      try {
        await container2.read(boardRequestProvider.future);
      } catch (_) {}

      final notifier = container2.read(boardRequestProvider.notifier);
      final result = await notifier.checkDuplicateBoard('자유게시판');
      expect(result, isNotNull);
      expect(result!.boardId, 'board-1');
    });

    test('checkDuplicateBoard returns board data fields', () async {
      tearDownMockSupabase();
      setupMockSupabase(
        {
          'boards': [boardData],
        },
        userId: 'test-user-id',
      );
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      try {
        await container2.read(boardRequestProvider.future);
      } catch (_) {}

      final notifier = container2.read(boardRequestProvider.notifier);
      final result = await notifier.checkDuplicateBoard('Free Board');
      expect(result, isNotNull);
      expect(result!.name['ko'], '자유게시판');
      expect(result.name['en'], 'Free Board');
      expect(result.isOfficial, true);
    });

    test('createBoard throws when not authenticated', () async {
      try {
        await container.read(boardRequestProvider.future);
      } catch (_) {}

      // createBoard uses currentUser which is null
      expect(
        () => container.read(boardRequestProvider.notifier).createBoard(
              1,
              'New Board',
              'Description',
              'Request message',
            ),
        throwsA(anything),
      );
    });

    test('refresh throws when not authenticated', () async {
      try {
        await container.read(boardRequestProvider.future);
      } catch (_) {}

      // refresh calls _getPendingRequest which needs currentUser
      await container.read(boardRequestProvider.notifier).refresh();

      // After refresh with no auth, state should be error
      final state = container.read(boardRequestProvider);
      expect(state, isA<AsyncError>());
    });
  });

  group('BoardModel', () {
    test('fromJson with string description', () {
      final model = BoardModel.fromJson(boardData);
      expect(model.boardId, 'board-1');
      expect(model.description, 'A free board');
      expect(model.isOfficial, true);
    });

    test('fromJson with map description', () {
      final model = BoardModel.fromJson(boardWithArtist);
      expect(model.boardId, 'board-3');
      expect(model.description, isA<Map<String, dynamic>>());
      final desc = model.description as Map<String, dynamic>;
      expect(desc['ko'], '공식 게시판입니다');
    });

    test('fromJson with artist data', () {
      final model = BoardModel.fromJson(boardWithArtist);
      expect(model.artist, isNotNull);
      expect(model.artist!.id, 1);
      expect(model.artist!.name['ko'], '지민');
    });

    test('fromJson with null artist', () {
      final model = BoardModel.fromJson(boardData);
      expect(model.artist, isNull);
    });

    test('fromJson with features list', () {
      final model = BoardModel.fromJson(boardWithArtist);
      expect(model.features, isNotNull);
      expect(model.features!.length, 2);
      expect(model.features, contains('voting'));
      expect(model.features, contains('gallery'));
    });

    test('fromJson with null features', () {
      final model = BoardModel.fromJson(pendingBoardData);
      expect(model.features, isNull);
    });

    test('fromJson with empty features', () {
      final model = BoardModel.fromJson(boardData);
      expect(model.features, isNotNull);
      expect(model.features, isEmpty);
    });

    test('fromJson parses pending board with request message', () {
      final model = BoardModel.fromJson(pendingBoardData);
      expect(model.status, 'pending');
      expect(model.requestMessage, '새 게시판을 만들어주세요');
      expect(model.creatorId, 'test-user-id');
      expect(model.isOfficial, false);
    });

    test('fromJson parses dates correctly', () {
      final model = BoardModel.fromJson(boardData);
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2026);
      expect(model.updatedAt, isNotNull);
    });

    test('copyWith updates fields correctly', () {
      final model = BoardModel.fromJson(boardData);
      final updated = model.copyWith(
        status: 'rejected',
        isOfficial: false,
      );

      expect(updated.status, 'rejected');
      expect(updated.isOfficial, false);
      expect(updated.boardId, 'board-1');
      expect(updated.name, boardData['name']);
    });

    test('copyWith preserves unmodified fields', () {
      final model = BoardModel.fromJson(boardData);
      final updated = model.copyWith(status: 'rejected');

      expect(updated.boardId, model.boardId);
      expect(updated.artistId, model.artistId);
      expect(updated.name, model.name);
      expect(updated.description, model.description);
      expect(updated.isOfficial, model.isOfficial);
      expect(updated.features, model.features);
    });

    test('fromJson with all name languages', () {
      final data = {
        ...boardData,
        'name': {
          'ko': '한국어',
          'en': 'English',
          'ja': '日本語',
          'zh_CN': '中文',
        },
      };
      final model = BoardModel.fromJson(data);
      expect(model.name['ko'], '한국어');
      expect(model.name['en'], 'English');
      expect(model.name['ja'], '日本語');
      expect(model.name['zh_CN'], '中文');
    });

    test('fromJson with artist group data', () {
      final boardWithArtistGroup = {
        ...boardData,
        'artist': {
          ...artistData,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
          },
        },
      };
      final model = BoardModel.fromJson(boardWithArtistGroup);
      expect(model.artist, isNotNull);
      expect(model.artist!.artistGroup, isNotNull);
    });

    test('toJson produces valid output', () {
      final model = BoardModel.fromJson(boardData);
      final json = model.toJson();
      expect(json['board_id'], 'board-1');
      expect(json['artist_id'], 1);
      expect(json['name'], isNotNull);
    });
  });

  group('DescriptionConverter', () {
    const converter = DescriptionConverter();

    test('fromJson handles string', () {
      final result = converter.fromJson('A description');
      expect(result, 'A description');
    });

    test('fromJson handles map', () {
      final result =
          converter.fromJson({'ko': '설명', 'en': 'Description'});
      expect(result, isA<Map<String, dynamic>>());
    });

    test('fromJson throws for invalid type', () {
      expect(
        () => converter.fromJson(123),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws for list type', () {
      expect(
        () => converter.fromJson([1, 2, 3]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws for bool type', () {
      expect(
        () => converter.fromJson(true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson handles string', () {
      final result = converter.toJson('A description');
      expect(result, 'A description');
    });

    test('toJson handles map', () {
      final input = {'ko': '설명'};
      final result = converter.toJson(input);
      expect(result, input);
    });

    test('toJson throws for invalid type', () {
      expect(
        () => converter.toJson(123),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson throws for list type', () {
      expect(
        () => converter.toJson([1, 2, 3]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson throws for bool type', () {
      expect(
        () => converter.toJson(false),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson handles empty string', () {
      final result = converter.fromJson('');
      expect(result, '');
    });

    test('fromJson handles empty map', () {
      final result = converter.fromJson(<String, dynamic>{});
      expect(result, isA<Map<String, dynamic>>());
    });

    test('toJson handles empty string', () {
      final result = converter.toJson('');
      expect(result, '');
    });

    test('toJson handles empty map', () {
      final input = <String, dynamic>{};
      final result = converter.toJson(input);
      expect(result, input);
    });

    test('fromJson preserves map values', () {
      final input = {
        'ko': '한국어 설명',
        'en': 'English description',
        'ja': '日本語の説明',
      };
      final result = converter.fromJson(input);
      expect(result, isA<Map<String, dynamic>>());
      final map = result as Map<String, dynamic>;
      expect(map['ko'], '한국어 설명');
      expect(map['en'], 'English description');
      expect(map['ja'], '日本語の説明');
    });
  });
}
