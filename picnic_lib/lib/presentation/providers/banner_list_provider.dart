import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/banner_list_provider.g.dart';

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    final now = DateTime.now().toUtc();

    final nowIso = now.toIso8601String();
    // "지금 유효한 배너": start_at/end_at 은 각각 NULL 이면 무제한으로
    // 해석한다. or 를 컬럼별로 나눠 AND 로 걸어야 (start_at IS NULL AND
    // end_at IS NOT NULL) 행이 누락되지 않는다.
    final response = await supabase
        .from('banner')
        .select('id, title, thumbnail, image, duration, link')
        .eq('location', location)
        .filter('deleted_at', 'is', null)
        .or('start_at.is.null,start_at.lte.$nowIso')
        .or('end_at.is.null,end_at.gte.$nowIso')
        .order('order', ascending: true)
        .order('start_at', ascending: false);

    return response.map((e) => BannerModel.fromJson(e)).toList();
  }
}
