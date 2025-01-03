import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../../generated/providers/my_page/bookmarked_artists_provider.g.dart';

@riverpod
class AsyncBookmarkedArtists extends _$AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async {
    return _fetchBookmarkedArtists();
  }

  Future<List<ArtistModel>> _fetchBookmarkedArtists() async {
    try {
      final response = await supabase.from('artist_user_bookmark').select(
          'artist_id, artist(id, name, image, gender, birth_date, artist_group(id, name, image))');

      List<ArtistModel> bookmarkedArtists =
          (response as List<dynamic>).map((data) {
        final artist =
            ArtistModel.fromJson(data['artist'] as Map<String, dynamic>);
        return artist.copyWith(isBookmarked: true);
      }).toList();

      return bookmarkedArtists;
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return [];
    }
  }

  Future<void> refreshBookmarkedArtists() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBookmarkedArtists());
  }
}
