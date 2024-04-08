import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_celeb_list_provider.g.dart';

@riverpod
class AsyncMyCelebList extends _$AsyncMyCelebList {
  @override
  Future<CelebListModel> build() async {
    return _fetchMyCelebList();
  }

  Future<CelebListModel> _fetchMyCelebList() async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/celeb/me');
    return CelebListModel.fromJson(response.data);
  }
}
