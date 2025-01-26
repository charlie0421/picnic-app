import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/artist_provider.g.dart';

@riverpod
Future<ArtistModel> getArtist(ref, int artistId) async {
  try {
    final response = await supabase
        .from('artist')
        .select('*')
        .eq('id', artistId)
        .maybeSingle();

    logger.i('response: $response');

    if (response == null) {
      throw Exception('Artist not found');
    }

    return ArtistModel.fromJson(response);
  } catch (e) {
    throw Exception('Failed to fetch artist');
  }
}
