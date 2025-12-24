import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../../generated/providers/my_page/my_artist_provider.g.dart';

@Riverpod(keepAlive: true)
class AsyncMyArtist extends _$AsyncMyArtist {
  @override
  Future<List<ArtistModel>> build() async {
    return [];
  }

  Future<bool> bookmarkArtist({required int artistId}) async {
    try {
      logger.d('🔖 bookmarkArtist 시작 - artistId: $artistId');

      if (supabase.auth.currentUser == null) {
        logger.e('🔖 사용자가 로그인되지 않음');
        throw Exception('User is not authenticated');
      }

      // DB에서 직접 현재 북마크 수 확인
      final countResponse = await supabase
          .from('artist_user_bookmark')
          .select('artist_id')
          .eq('user_id', supabase.auth.currentUser!.id);

      final currentCount = (countResponse as List).length;
      logger.d('🔖 현재 북마크 수 (DB 직접 조회): $currentCount');

      if (currentCount >= 5) {
        logger.w('🔖 북마크 최대 개수(5개) 도달');
        return false;
      }

      await supabase.from('artist_user_bookmark').upsert({
        'artist_id': artistId,
        'user_id': supabase.auth.currentUser!.id,
      });
      logger.d('🔖 DB에 북마크 추가 완료');

      logger.d('🔖 bookmarkArtist 성공');
      return true;
    } catch (e, s) {
      logger.e('🔖 Error adding bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<bool> unBookmarkArtist({required int artistId}) async {
    try {
      logger.d('🔖 unBookmarkArtist 시작 - artistId: $artistId');

      await supabase
          .from('artist_user_bookmark')
          .delete()
          .eq('artist_id', artistId);
      logger.d('🔖 DB에서 북마크 삭제 완료');

      logger.d('🔖 unBookmarkArtist 성공');
      return true;
    } catch (e, s) {
      logger.e('🔖 Error removing bookmark:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }
}
