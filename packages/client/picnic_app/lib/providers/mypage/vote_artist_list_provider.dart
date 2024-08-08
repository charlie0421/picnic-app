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

  Future<List<ArtistModel>> fetchArtists({
    required int page,
    required String query,
    String language = 'en',
  }) async {
    query = query.trim();
    try {
      //TODO 나중에 artist_group도 검색해야함
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

      List<ArtistModel> artistList =
          response.map((e) => ArtistModel.fromJson(e)).toList();

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
