import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'boards_provider.g.dart';

@riverpod
Future<List<BoardModel>?> boards(ref, int artistId) async {
  try {
    final response = await supabase
        .schema('community')
        .from('boards')
        .select()
        .eq('artist_id', artistId)
        .eq('status', 'approved')
        .order('is_official', ascending: false);

    logger.d('response: $response');

    return response.map((data) => BoardModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching boards:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<BoardModel>?> boardsByArtistName(
    ref, String query, int page, int limit) async {
  try {
    List<BoardModel> boardData = [];
    if (query.isEmpty) {
      final response = await supabase
          .schema('community')
          .from('boards')
          .select()
          .neq('artist_id', 0)
          .eq('status', 'approved')
          .range(page * limit, (page + 1) * limit - 1)
          .order('is_official', ascending: false)
          .order('name->>${Intl.getCurrentLocale()}', ascending: true);

      boardData = response.map(BoardModel.fromJson).toList();
    } else {
      final response = await supabase
          .schema('community')
          .from('boards')
          .select()
          .neq('artist_id', 0)
          .or('name->>ko.ilike.%$query%,name->>en.ilike.%$query%,name->>ja.ilike.%$query%,name->>zh.ilike.%$query%')
          .range(page * limit, (page + 1) * limit - 1)
          .order('name->>${Intl.getCurrentLocale()}', ascending: true);
      boardData = response.map(BoardModel.fromJson).toList();
    }

    final artistIds =
        boardData.map((board) => board.artist_id).toSet().toList();

    logger.d('artistIds: $artistIds');

    final artistData = await supabase
        .from('artist')
        .select('*, artist_group(*)')
        .inFilter('id', artistIds);

    if (artistData.isEmpty) {
      return [];
    }

    return boardData.map((board) {
      logger.d('board: $board');
      logger.d('artistData: $artistData');
      return board.copyWith(
          artist: ArtistModel.fromJson(artistData.firstWhere((artist) {
        logger.d('artist: ${artist['id']}');
        logger.d('board.artist_id: ${board.artist_id}');

        return artist['id'] == board.artist_id;
      })));
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching boards:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<BoardModel?> checkPendingRequest(ref) async {
  try {
    final response = await supabase
        .schema('community')
        .from('boards')
        .select()
        .eq('creator_id', supabase.auth.currentUser!.id)
        .eq('status', 'pending')
        .maybeSingle();

    logger.d('response: $response');

    return response == null ? null : BoardModel.fromJson(response);
  } catch (e, s) {
    logger.e('Error checking pending request:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<BoardModel?> checkDuplicateBoard(ref, String title) async {
  try {
    final response = await supabase
        .schema('community')
        .from('boards')
        .select()
        .or('name->>ko.eq.$title,name->>en.eq.$title,name->>ja.eq.$title,name->>zh.eq.$title')
        .maybeSingle();

    logger.d('response: $response');

    return response == null ? null : BoardModel.fromJson(response);
  } catch (e, s) {
    logger.e('Error checking duplicate board:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<BoardModel?> createBoard(
    ref, int artistId, String title, String description, requestMessage) async {
  try {
    final response = await supabase.schema('community').from('boards').insert([
      {
        'artist_id': artistId,
        'name': {
          'minor': title,
        },
        'description': description,
        'status': 'pending',
        'request_message': requestMessage,
        'creator_id': supabase.auth.currentUser!.id,
      }
    ]).maybeSingle();

    logger.d('response: $response');

    return response == null ? null : BoardModel.fromJson(response);
  } catch (e, s) {
    logger.e('Error creating board:', error: e, stackTrace: s);
    return Future.error(e);
  }
}
