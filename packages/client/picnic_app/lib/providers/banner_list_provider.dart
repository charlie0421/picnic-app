import 'package:picnic_app/models/common/banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'banner_list_provider.g.dart';

@riverpod
class AsyncBannerList extends _$AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    return _fetchBannerList(location: location);
  }

  Future<List<BannerModel>> _fetchBannerList({required String location}) async {
    final response = await Supabase.instance.client
        .from('banner')
        .select()
        .eq('location', location)
        .order('start_at', ascending: false);
    List<BannerModel> bannerList =
        List<BannerModel>.from(response.map((e) => BannerModel.fromJson(e)));
    for (var i = 0; i < bannerList.length; i++) {
      bannerList[i] = bannerList[i].copyWith(
          thumbnail:
              'https://cdn-dev.picnic.fan/banner/$location/${bannerList[i].id}/${bannerList[i].thumbnail}');
    }
    return bannerList;
  }
}
