import 'package:picnic_app/auth_dio.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/prame/celeb_banner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celeb_banner_list_provider.g.dart';

@riverpod
class AsyncCelebBannerList extends _$AsyncCelebBannerList {
  @override
  Future<CelebBannerListModel> build({required int celebId}) async {
    return _fetchCelebBannerList(celebId: celebId);
  }

  Future<CelebBannerListModel> _fetchCelebBannerList(
      {required int celebId}) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/celeb/banner/$celebId');

    return CelebBannerListModel.fromJson(response.data);
  }
}
