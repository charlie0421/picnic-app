import 'package:picnic_app/data/models/common/banner.dart';
import 'package:picnic_app/supabase_options.dart';
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

    final response = await supabase
        .from('banner')
        .select('id, title, thumbnail, image, duration')
        .eq('location', location)
        .or('and(start_at.lte.${now.toIso8601String()},or(end_at.gte.${now.toIso8601String()},end_at.is.null)),and(start_at.is.null,end_at.is.null)')
        .order('order', ascending: true)
        .order('start_at', ascending: false);

    return response.map((e) => BannerModel.fromJson(e)).toList();
  }
}
