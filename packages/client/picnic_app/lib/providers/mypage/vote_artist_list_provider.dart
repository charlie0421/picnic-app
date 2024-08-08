import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/mypage/bookmarked_artists_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'vote_artist_list_provider.g.dart';

@riverpod
class AsyncVoteArtistList extends _$AsyncVoteArtistList {
  @override
  Future<List<ArtistModel>> build() async {
    return [];
  }

  Future<bool> unBookmarkArtist({
    required int artistId,
    required AsyncBookmarkedArtists bookmarkedArtistsRef,
  }) async {
    try {
      await supabase
          .from('artist_user_bookmark')
          .delete()
          .eq('artist_id', artistId);

      state = AsyncValue.data(state.value!.map((artist) {
        if (artist.id == artistId) {
          return artist.copyWith(isBookmarked: false);
        }
        return artist;
      }).toList());

      // 북마크 리스트 갱신
      await bookmarkedArtistsRef.refreshBookmarkedArtists();

      ref.notifyListeners();
      logger.d('북마크 상태 변경: artistId=$artistId, isBookmarked=false');

      return true;
    } catch (e, s) {
      logger.e('북마크 제거 중 오류 발생:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<bool> bookmarkArtist({required int artistId}) async {
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      if (bookmarkedArtists.length >= 5) {
        return false;
      }

      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      await supabase.from('artist_user_bookmark').upsert({
        'artist_id': artistId,
      });

      state = AsyncValue.data(state.value!.map((artist) {
        if (artist.id == artistId) {
          return artist.copyWith(isBookmarked: true);
        }
        return artist;
      }).toList());

      // 북마크 리스트 갱신
      await ref
          .read(asyncBookmarkedArtistsProvider.notifier)
          .refreshBookmarkedArtists();

      ref.notifyListeners();
      logger.d('북마크 상태 변경: artistId=$artistId, isBookmarked=true');
      return true;
    } catch (e, s) {
      logger.e('북마크 추가 중 오류 발생:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<List<ArtistModel>> fetchArtists({
    required int page,
    required String query,
    String language = 'en',
  }) async {
    query = query.trim();
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      final bookmarkedArtistIds = bookmarkedArtists.map((a) => a.id).toSet();

      final response = await supabase
          .from('artist')
          .select('id,name,image,gender, artist_group(id,name)')
          .or('name->>ko.ilike.%$query%,'
              'name->>en.ilike.%$query%,'
              'name->>ja.ilike.%$query%,'
              'name->>zh.ilike.%$query%')
          .order('name->>$language', ascending: true)
          .limit(20)
          .range(page * 20, (page + 1) * 20 - 1);

      List<ArtistModel> artistList = response.map((artistData) {
        return ArtistModel.fromJson({
          ...artistData,
          'isBookmarked': bookmarkedArtistIds.contains(artistData['id']),
        });
      }).toList();

      artistList.sort((a, b) {
        if (a.isBookmarked != b.isBookmarked) {
          return (a.isBookmarked ?? false) ? -1 : 1;
        }
        String aName =
            (a.name[language] as String?) ?? a.name['en'] as String? ?? '';
        String bName =
            (b.name[language] as String?) ?? b.name['en'] as String? ?? '';
        return aName.compareTo(bName);
      });

      state = AsyncValue.data(artistList);

      return artistList;
    } catch (e, s) {
      logger.e('아티스트 목록 가져오기 중 오류 발생:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return [];
    }
  }
}
