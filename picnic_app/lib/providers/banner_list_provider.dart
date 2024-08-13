import 'package:picnic_app/models/common/banner.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'banner_list_provider.g.dart';

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    final response = await supabase
        .from('banner')
        .select()
        .eq('location', location)
        // .lt('start_at', DateTime.now().toUtc())
        .order('order', ascending: true)
        .order('start_at', ascending: false);

    List<BannerModel> bannerList =
        response.map((e) => BannerModel.fromJson(e)).toList();

    return bannerList;
  }
}
