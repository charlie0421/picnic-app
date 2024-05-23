import 'package:picnic_app/models/prame/celeb_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'celeb_banner_list_provider.g.dart';

@riverpod
class AsyncCelebBannerList extends _$AsyncCelebBannerList {
  @override
  Future<List<CelebBannerModel>> build({required int celebId}) async {
    return _fetchCelebBannerList(celebId: celebId);
  }

  Future<List<CelebBannerModel>> _fetchCelebBannerList(
      {required int celebId}) async {
    final response = await Supabase.instance.client
        .from('celeb_banner')
        .select()
        .eq('celeb_id', celebId);
    List<CelebBannerModel> celebList = List<CelebBannerModel>.from(
        response.map((e) => CelebBannerModel.fromJson(e)));
    celebList.forEach((element) {
      element.thumbnail =
          'https://cdn-dev.picnic.fan/celeb_banner/${element.id}/${element.thumbnail}';
    });
    return celebList;
  }
}
