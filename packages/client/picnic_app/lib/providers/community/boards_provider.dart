import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/board.dart';
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
        .eq('artist_id', artistId);

    logger.d('response: $response');

    return response.map((data) => BoardModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching boards:', error: e, stackTrace: s);
    return Future.error(e);
  }
}
