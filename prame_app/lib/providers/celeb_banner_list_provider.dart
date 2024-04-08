import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/celeb_banner.dart';
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

    logger.i('response.data: ${response.data}');

    return CelebBannerListModel.fromJson(response.data);
  }
}
