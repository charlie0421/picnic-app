import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/fortune.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/fortune_provider.g.dart';

@riverpod
Future<FortuneModel> getFortune(
  Ref ref, {
  required int artistId,
  required int year,
  String language = 'ko',
}) async {
  try {
    if (language == 'ko') {
      final fortune = await supabase
          .from("fortune_telling")
          .select('*, artist(*)')
          .eq('artist_id', artistId)
          .eq('year', year)
          .maybeSingle();

      logger.d('fortune: $fortune');
      return FortuneModel.fromJson(fortune!);
    }

    // i18n 테이블에서 번역된 데이터 조회
    final translation = await supabase
        .from("fortune_telling_i18n")
        .select('*, artist(*)')
        .eq('artist_id', artistId)
        .eq('year', year)
        .eq('language', language)
        .maybeSingle();

    if (translation != null) {
      logger.d('translation found: $translation');
      // artist 정보를 fortune_telling 테이블에서 가져와서 병합
      final translatedFortune = {
        ...translation,
        'artist': translation['artist'],
      };
      return FortuneModel.fromJson(translatedFortune);
    }

    // 번역이 없는 경우 기본 한국어 데이터 반환
    final fortune = await supabase
        .from("fortune_telling")
        .select('*, artist(*)')
        .eq('artist_id', artistId)
        .eq('year', year)
        .maybeSingle();

    logger.d('fallback to Korean: $fortune');
    return FortuneModel.fromJson(fortune!);
  } catch (e, s) {
    logger.e('Error getting fortune:$e', stackTrace: s);
    rethrow;
  }
}
