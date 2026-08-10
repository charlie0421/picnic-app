import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/banner_list_provider.g.dart';

/// "지금 유효한 배너" PostgREST 술어 (or= 파라미터 2개, AND 결합).
///
/// 컬럼별로 NULL=무제한 해석을 유지해야 (start_at IS NULL AND end_at IS NOT
/// NULL) 행이 누락되지 않는다. 단일 or 술어로 합치면 그 조합이 빠진다.
List<String> bannerActiveWindowOrFilters(DateTime nowUtc) {
  final nowIso = nowUtc.toIso8601String();
  return [
    'start_at.is.null,start_at.lte.$nowIso',
    'end_at.is.null,end_at.gte.$nowIso',
  ];
}

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    final now = DateTime.now().toUtc();

    final windowFilters = bannerActiveWindowOrFilters(now);
    var query = supabase
        .from('banner')
        .select('id, title, thumbnail, image, duration, link')
        .eq('location', location)
        .filter('deleted_at', 'is', null);
    for (final filter in windowFilters) {
      query = query.or(filter);
    }
    final response = await query
        .order('order', ascending: true)
        .order('start_at', ascending: false);

    return response.map((e) => BannerModel.fromJson(e)).toList();
  }
}
