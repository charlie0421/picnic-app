import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
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

  Future<List<ArtistModel>> fetchArtists({
    required int page,
    required String query,
    required String language,
  }) async {
    logger.d(
        '🔥🔥🔥 [VoteArtistListProvider] fetchArtists called with page: $page, query: "$query", language: $language');
    logger.d(
        '🎯 [VoteArtistListProvider] fetchArtists called with page: $page, query: "$query", language: $language');

    try {
      // SearchService를 통해 아티스트 검색 (한국어 초성 검색 포함)
      final searchResponse = await SearchService.searchArtists(
        query: query,
        page: page,
        limit: 20,
        language: language,
        supportKoreanInitials: true, // 한국어 초성 검색 활성화
      );

      // 비동기 작업 후 provider가 dispose되었는지 확인
      if (!ref.mounted) {
        logger.d('🔥🔥🔥 [VoteArtistListProvider] Provider disposed after search, returning empty list');
        return [];
      }

      logger.d(
          '🔥🔥🔥 [VoteArtistListProvider] 서버 응답 받음 - 아이템 수: ${searchResponse.length}');
      logger.i(
          '🎯 [VoteArtistListProvider] Search response received with ${searchResponse.length} items');

      if (searchResponse.isEmpty) {
        logger.d('🔥🔥🔥 [VoteArtistListProvider] 서버에서 빈 결과 반환');
        logger.w('🎯 [VoteArtistListProvider] Empty search result from server');
        return [];
      }

      // 북마크된 아티스트 목록 가져오기
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);

      // 북마크 조회 후 다시 mounted 확인
      if (!ref.mounted) {
        logger.d('🔥🔥🔥 [VoteArtistListProvider] Provider disposed after bookmark fetch, returning search results only');
        return searchResponse;
      }
      final bookmarkedArtistIds = bookmarkedArtists.map((a) => a.id).toSet();
      logger.d(
          '🔥🔥🔥 [VoteArtistListProvider] 북마크된 아티스트 수: ${bookmarkedArtistIds.length}');
      logger.d(
          '🔥🔥🔥 [VoteArtistListProvider] 북마크된 아티스트 ID들: $bookmarkedArtistIds');
      logger.i(
          '🎯 [VoteArtistListProvider] Bookmarked artists count: ${bookmarkedArtistIds.length}');

      // 아티스트 리스트에 북마크 상태 적용
      final artistsWithBookmarks = searchResponse.map((artist) {
        final isBookmarked = bookmarkedArtistIds.contains(artist.id);
        final updatedArtist = artist.copyWith(isBookmarked: isBookmarked);

        if (isBookmarked) {
          logger.d(
              '🔥🔥🔥 [VoteArtistListProvider] 북마크된 아티스트 발견: ${getLocaleTextFromJson(artist.name)} (ID: ${artist.id})');
        }

        return updatedArtist;
      }).toList();

      logger.d(
          '🔥🔥🔥 [VoteArtistListProvider] 검색 결과에서 발견된 북마크 아티스트 수: ${artistsWithBookmarks.where((a) => a.isBookmarked == true).length}');

      // 첫 번째 페이지(page=0)이고 검색어가 비어있을 때만 북마크된 아티스트를 상단에 추가
      if (page == 0 && query.isEmpty) {
        // 검색 결과에 포함되지 않은 북마크된 아티스트들 확인
        final foundBookmarkedIds = artistsWithBookmarks
            .where((a) => a.isBookmarked == true)
            .map((a) => a.id)
            .toSet();
        final missingBookmarkedIds =
            bookmarkedArtistIds.difference(foundBookmarkedIds);

        if (missingBookmarkedIds.isNotEmpty) {
          logger.d(
              '🔥🔥🔥 [VoteArtistListProvider] 검색 결과에 없는 북마크된 아티스트 ID들: $missingBookmarkedIds');

          // 누락된 북마크 아티스트들을 bookmarkedArtists에서 찾아서 추가
          final missingBookmarkedArtists = bookmarkedArtists
              .where((artist) => missingBookmarkedIds.contains(artist.id))
              .map((artist) => artist.copyWith(isBookmarked: true))
              .toList();

          logger.d(
              '🔥🔥🔥 [VoteArtistListProvider] 추가할 누락된 북마크 아티스트 수: ${missingBookmarkedArtists.length}');

          // 누락된 북마크 아티스트들을 리스트 앞쪽에 추가
          artistsWithBookmarks.insertAll(0, missingBookmarkedArtists);

          logger.d('🔥🔥🔥 [VoteArtistListProvider] 누락된 북마크 아티스트 추가 완료');
        }

        // 북마크된 아티스트를 상단으로 정렬
        artistsWithBookmarks.sort((a, b) {
          // 북마크된 아티스트가 상단에 오도록 정렬
          if (a.isBookmarked == true && b.isBookmarked != true) return -1;
          if (a.isBookmarked != true && b.isBookmarked == true) return 1;
          return 0;
        });
      } else {
        // 첫 페이지가 아니거나 검색어가 있을 때는 북마크 상태만 적용하고 정렬하지 않음
        // (검색 결과 순서 유지)
      }

      logger.d('🔥🔥🔥 [VoteArtistListProvider] 정렬 후 첫 3개 아티스트:');
      for (int i = 0; i < artistsWithBookmarks.length && i < 3; i++) {
        final artist = artistsWithBookmarks[i];
        logger.d(
            '🔥🔥🔥 [VoteArtistListProvider] [$i] ${getLocaleTextFromJson(artist.name)} (ID: ${artist.id}, 북마크: ${artist.isBookmarked})');
      }

      logger.d(
          '🔥🔥🔥 [VoteArtistListProvider] 정렬된 결과 수: ${artistsWithBookmarks.length}');
      logger.i(
          '🎯 [VoteArtistListProvider] Sorted results count: ${artistsWithBookmarks.length}');

      return artistsWithBookmarks;
    } catch (e, s) {
      logger.d('🔥🔥🔥 [VoteArtistListProvider] 에러 발생: $e');
      logger.e('🎯 [VoteArtistListProvider] Error occurred',
          error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return [];
    }
  }

  /// 아티스트가 검색어와 매칭되는지 확인 (한국어 초성 검색 포함)
}
