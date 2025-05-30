import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/boards_provider.g.dart';

@riverpod
class BoardDetail extends _$BoardDetail {
  @override
  Future<BoardModel?> build(String boardId) {
    return _fetchBoardDetail(boardId);
  }

  Future<BoardModel?> _fetchBoardDetail(String boardId) async {
    return boardDetail(boardId);
  }

  Future<BoardModel?> boardDetail(String boardId) async {
    try {
      final response = await supabase
          .from('boards')
          .select()
          .eq('board_id', boardId)
          .maybeSingle();
      return response == null ? null : BoardModel.fromJson(response);
    } catch (e, s) {
      logger.e('Error fetching board detail:', error: e, stackTrace: s);
      rethrow;
    }
  }
}

@riverpod
class BoardsNotifier extends _$BoardsNotifier {
  @override
  Future<List<BoardModel>?> build(int artistId) async {
    return _fetchBoards(artistId);
  }

  Future<List<BoardModel>?> _fetchBoards(int artistId) async {
    try {
      List<Map<String, dynamic>> response;

      // 안전한 쿼리 실행 시도
      try {
        response = await supabase
            .from('boards')
            .select(
                'name, board_id, artist_id, description, is_official, features, status, creator_id, artist(*, artist_group(*))')
            .eq('artist_id', artistId)
            .eq('status', 'approved')
            .order('is_official', ascending: false)
            .order('order', ascending: true);
      } catch (queryError) {
        logger.w('Complex boards query failed, trying fallback query',
            error: queryError);

        // 폴백 쿼리: 단순한 형태
        response = await supabase
            .from('boards')
            .select(
                'name, board_id, artist_id, description, is_official, features, status, creator_id')
            .eq('artist_id', artistId)
            .eq('status', 'approved')
            .order('is_official', ascending: false)
            .order('order', ascending: true);
      }

      // 응답이 비어있으면 빈 리스트 반환
      if (response.isEmpty) {
        logger.i('No boards found for artistId: $artistId');
        return [];
      }

      // 안전한 JSON 변환
      List<BoardModel> boardList = [];
      for (final item in response) {
        try {
          if (item != null) {
            boardList.add(BoardModel.fromJson(item));
          }
        } catch (jsonError) {
          logger.w('Failed to parse board item: $item', error: jsonError);
          // 개별 아이템 파싱 실패는 무시하고 계속 진행
        }
      }

      return boardList;
    } catch (e, s) {
      logger.e('Error fetching boards:', error: e, stackTrace: s);
      return Future.error(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBoards(artistId));
  }
}

@riverpod
class BoardsByArtistNameNotifier extends _$BoardsByArtistNameNotifier {
  @override
  Future<List<BoardModel>?> build(String query, int page, int limit) async {
    return _fetchBoardsByArtistName(query, page, limit);
  }

  Future<List<BoardModel>?> _fetchBoardsByArtistName(
      String query, int page, int limit) async {
    try {
      if (query.isEmpty) {
        final response = await supabase
            .from('boards')
            .select(
                'name, board_id, artist_id, description, is_official, features, artist!inner(*, artist_group(*))')
            .neq('artist_id', 0)
            .eq('status', 'approved')
            .order('artist(name->>${getLocaleLanguage()})', ascending: true)
            .order('is_official', ascending: false)
            .order('order', ascending: true)
            .range(page * limit, (page + 1) * limit - 1);

        return response.map((data) => BoardModel.fromJson(data)).toList();
      }

      final response = await supabase
          .from('boards')
          .select(
              'name, board_id, artist_id, description, is_official, features, artist!inner(*, artist_group(*))')
          .neq('artist_id', 0)
          .eq('status', 'approved')
          .or('name->>ko.ilike.%$query%,name->>en.ilike.%$query%,name->>ja.ilike.%$query%,name->>zh.ilike.%$query%')
          .order('artist(name->>${getLocaleLanguage()})', ascending: true)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((data) => BoardModel.fromJson(data)).toList();
    } catch (e, s) {
      logger.e('Error fetching boards by artist name:',
          error: e, stackTrace: s);
      return Future.error(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _fetchBoardsByArtistName(query, page, limit));
  }
}

@riverpod
class BoardRequestNotifier extends _$BoardRequestNotifier {
  @override
  Future<BoardModel?> build() async {
    return _getPendingRequest();
  }

  Future<BoardModel?> _getPendingRequest() async {
    try {
      final response = await supabase
          .from('boards')
          .select(
              'name, board_id, artist_id, description, is_official, request_message')
          .eq('creator_id', supabase.auth.currentUser!.id)
          .eq('status', 'pending')
          .maybeSingle();

      return response == null ? null : BoardModel.fromJson(response);
    } catch (e, s) {
      logger.e('Error checking pending request:', error: e, stackTrace: s);
      return Future.error(e);
    }
  }

  Future<BoardModel?> checkDuplicateBoard(String title) async {
    try {
      final response = await supabase
          .from('boards')
          .select()
          .or('name->>ko.eq.$title,name->>en.eq.$title,name->>ja.eq.$title,name->>zh.eq.$title')
          .maybeSingle();

      return response == null ? null : BoardModel.fromJson(response);
    } catch (e, s) {
      logger.e('Error checking duplicate board:', error: e, stackTrace: s);
      return Future.error(e);
    }
  }

  Future<void> createBoard(int artistId, String title, String description,
      String requestMessage) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase.from('boards').upsert({
        'artist_id': artistId,
        'name': {
          'ko': title,
          'en': title,
          'ja': title,
          'zh': title,
        },
        'description': description,
        'status': 'pending',
        'request_message': requestMessage,
        'creator_id': user.id,
        'is_official': false,
        'order': 0,
        'features': [],
      });

      refresh();
    } catch (e, s) {
      logger.e('Error creating board:', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _getPendingRequest());
  }
}
