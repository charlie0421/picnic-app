import 'dart:io';

import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'vote_artist_list_provider.g.dart';

@riverpod
class AsyncVoteArtistList extends _$AsyncVoteArtistList {
  @override
  Future<List<ArtistModel>> build() async {
    return [];
  }

  Future<bool> unBookmarkArtist({required int artistId}) async {
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

      ref.notifyListeners();
      logger.d('북마크 상태 변경: artistId=$artistId, isBookmarked=false');

      return true; // 북마크 제거 성공
    } on PostgrestException catch (error, s) {
      logger.e('Postgrest 에러 발생:', error: error, stackTrace: s);
      logger.e('에러 메시지: ${error.message}');
      logger.e('에러 세부사항: ${error.details}');
      logger.e('힌트: ${error.hint}');
      logger.e('HTTP 상태 코드: ${error.code}');
      return false; // 북마크 제거 성공
    } on SocketException catch (error) {
      logger.e('네트워크 에러 발생:', error: error);
      return false; // 북마크 제거 성공
    } catch (e, s) {
      logger.e(s, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return false; // 북마크 제거 실패
    }
  }

  Future<int> getBookmarkCount() async {
    final response =
        await supabase.from('artist_user_bookmark').select('id').count();
    return response.count;
  }

  Future<bool> bookmarkArtist({required int artistId}) async {
    try {
      final bookmarkCount = await getBookmarkCount();
      if (bookmarkCount >= 5) {
        return false; // 북마크 추가 실패
      }

      // 현재 사용자가 인증되어 있는지 확인
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      // 이미 존재하는 북마크 확인
      final existing = await supabase
          .from('artist_user_bookmark')
          .select()
          .eq('artist_id', artistId)
          .maybeSingle();

      if (existing == null) {
        // 북마크가 존재하지 않으면 새로 생성
        await supabase.from('artist_user_bookmark').insert({
          'artist_id': artistId,
        });
      }

      // 로컬 상태 업데이트
      state = AsyncValue.data(state.value!.map((artist) {
        if (artist.id == artistId) {
          return artist.copyWith(isBookmarked: true);
        }
        return artist;
      }).toList());

      ref.notifyListeners();
      logger.d('북마크 상태 변경: artistId=$artistId, isBookmarked=true');
      return true; // 북마크 추가 성공
    } catch (e, s) {
      logger.e('북마크 추가 중 오류 발생:', error: e, stackTrace: s);
      state = AsyncValue.error(e, s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return false; // 북마크 추가 실패
    }
  }

  Future<List<ArtistModel>> fetchArtists({
    required int page,
    required String query,
    String language = 'en',
  }) async {
    query = query.trim();
    try {
      // 1. 북마크된 아티스트 ID 목록 가져오기
      final responseBookmarked =
          await supabase.from('artist_user_bookmark').select('artist_id');

      final bookmarkedArtistIds = (responseBookmarked as List<dynamic>)
          .map((e) => e['artist_id'] as int)
          .toSet();

      logger.i('bookmarkedArtistIds: $bookmarkedArtistIds');

      // 2. 모든 아티스트 검색
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

      logger.i('response: $response');

      // 3. 검색 결과를 ArtistModel로 변환하고 isBookmarked 설정
      List<ArtistModel> artistList = response.map((artistData) {
        return ArtistModel.fromJson({
          ...artistData,
          'isBookmarked': bookmarkedArtistIds.contains(artistData['id']),
        });
      }).toList();

      // 4. 북마크된 아티스트를 앞으로 정렬하고, 같은 북마크 상태 내에서는 이름으로 정렬
      artistList.sort((a, b) {
        if (a.isBookmarked != b.isBookmarked) {
          return (a.isBookmarked ?? false) ? -1 : 1;
        }
        // 같은 북마크 상태일 경우 지정된 언어의 이름으로 정렬
        String aName =
            (a.name[language] as String?) ?? a.name['en'] as String? ?? '';
        String bName =
            (b.name[language] as String?) ?? b.name['en'] as String? ?? '';
        return aName.compareTo(bName);
      });

      state = AsyncValue.data(artistList);

      return artistList;
    } on PostgrestException catch (error, s) {
      logger.e('Postgrest 에러 발생:', error: error, stackTrace: s);
      logger.e('에러 메시지: ${error.message}');
      logger.e('에러 세부사항: ${error.details}');
      logger.e('힌트: ${error.hint}');
      logger.e('HTTP 상태 코드: ${error.code}');
    } on SocketException catch (error) {
      logger.e('네트워크 에러 발생:', error: error);
    } catch (e, s) {
      logger.e(s, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
    }
    return [];
  }
}
