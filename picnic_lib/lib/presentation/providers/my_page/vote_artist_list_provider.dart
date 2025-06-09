import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../../generated/providers/my_page/vote_artist_list_provider.g.dart';

@riverpod
class AsyncVoteArtistList extends _$AsyncVoteArtistList {
  @override
  Future<List<ArtistModel>> build() async {
    return [];
  }

  Future<bool> bookmarkArtist({required int artistId}) async {
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      if (bookmarkedArtists.length >= 5) return false;
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      await supabase
          .from('artist_user_bookmark')
          .upsert({'artist_id': artistId});
      await ref
          .read(asyncBookmarkedArtistsProvider.notifier)
          .refreshBookmarkedArtists();

      state = AsyncValue.data(state.value!.map((artist) {
        return artist.id == artistId
            ? artist.copyWith(isBookmarked: true)
            : artist;
      }).toList());

      _resortArtists();
      ref.notifyListeners();
      return true;
    } catch (e, s) {
      logger.e('Error adding bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<bool> unBookmarkArtist(
      {required int artistId,
      required AsyncBookmarkedArtists bookmarkedArtistsRef}) async {
    try {
      await supabase
          .from('artist_user_bookmark')
          .delete()
          .eq('artist_id', artistId);
      await bookmarkedArtistsRef.refreshBookmarkedArtists();

      state = AsyncValue.data(state.value!.map((artist) {
        return artist.id == artistId
            ? artist.copyWith(isBookmarked: false)
            : artist;
      }).toList());

      _resortArtists();
      ref.notifyListeners();
      return true;
    } catch (e, s) {
      logger.e('Error removing bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  void _resortArtists() {
    state = AsyncValue.data(state.value!
      ..sort((a, b) {
        if (a.isBookmarked != b.isBookmarked) {
          return (a.isBookmarked ?? false) ? -1 : 1;
        }
        return (a.name['en'] as String? ?? '')
            .compareTo(b.name['en'] as String? ?? '');
      }));
  }

  Future<List<ArtistModel>> fetchArtists(
      {required int page,
      required String query,
      String language = 'en'}) async {
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      final bookmarkedArtistIds = bookmarkedArtists.map((a) => a.id).toSet();

      // 새로운 SearchService를 사용하여 아티스트 이름과 그룹명을 함께 검색
      // 캐싱 기능을 활용하여 성능 최적화
      List<ArtistModel> nonBookmarkedArtists = await SearchService.searchArtists(
        query: query,
        page: page,
        limit: 20,
        language: language,
        excludeIds: bookmarkedArtistIds.toList(),
        useCache: true, // 캐싱 활성화
      );

      List<ArtistModel> allArtists = [
        ...bookmarkedArtists,
        ...nonBookmarkedArtists
      ];
      
      // 북마크된 아티스트를 먼저 표시하고, 그 다음 언어별로 정렬
      allArtists.sort((a, b) {
        if (a.isBookmarked != b.isBookmarked) {
          return (a.isBookmarked ?? false) ? -1 : 1;
        }
        return (a.name[language] as String? ?? a.name['en'] as String? ?? '')
            .compareTo(
                b.name[language] as String? ?? b.name['en'] as String? ?? '');
      });

      state = AsyncValue.data(allArtists);
      return allArtists;
    } catch (e, s) {
      logger.e('Error fetching artists:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return [];
    }
  }
}
