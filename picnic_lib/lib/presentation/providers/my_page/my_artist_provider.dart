import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../../generated/providers/my_page/my_artist_provider.g.dart';

@riverpod
class AsyncMyArtist extends _$AsyncMyArtist {
  @override
  Future<List<ArtistModel>> build() async {
    return [];
  }

  Future<bool> bookmarkArtist({required int artistId}) async {
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      if (!ref.mounted) return false;
      if (bookmarkedArtists.length >= 5) return false;
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      await supabase.from('artist_user_bookmark').upsert({
        'artist_id': artistId,
        'user_id': supabase.auth.currentUser!.id,
      });
      if (!ref.mounted) return false;

      await ref
          .read(asyncBookmarkedArtistsProvider.notifier)
          .refreshBookmarkedArtists();

      return true;
    } catch (e, s) {
      logger.e('Error adding bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<bool> unBookmarkArtist({required int artistId}) async {
    try {
      await supabase
          .from('artist_user_bookmark')
          .delete()
          .eq('artist_id', artistId);
      if (!ref.mounted) return false;

      await ref
          .read(asyncBookmarkedArtistsProvider.notifier)
          .refreshBookmarkedArtists();

      return true;
    } catch (e, s) {
      logger.e('Error removing bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }
}
