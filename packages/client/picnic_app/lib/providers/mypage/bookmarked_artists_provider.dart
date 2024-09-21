import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'bookmarked_artists_provider.g.dart';

@riverpod
class AsyncBookmarkedArtists extends _$AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async {
    return _fetchBookmarkedArtists();
  }

  Future<List<ArtistModel>> _fetchBookmarkedArtists() async {
    try {
      final response = await supabase.from('artist_user_bookmark').select(
          'artist_id, artist(id, name, image, gender, artist_group(id, name, image))');

      logger.i('북마크된 아티스트 가져오기 응답: $response');

      List<ArtistModel> bookmarkedArtists = response.map((data) {
        final artistData = data['artist'] as Map<String, dynamic>;
        return ArtistModel.fromJson({
          ...artistData,
          'isBookmarked': true,
        });
      }).toList();

      return bookmarkedArtists;
    } catch (e, s) {
      logger.e('북마크된 아티스트 가져오기 중 오류 발생:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return [];
    }
  }

  Future<void> refreshBookmarkedArtists() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBookmarkedArtists());
  }
}
