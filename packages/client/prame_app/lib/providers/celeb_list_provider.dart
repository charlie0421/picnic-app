import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/prame/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celeb_list_provider.g.dart';

@riverpod
class AsyncCelebList extends _$AsyncCelebList {
  @override
  Future<CelebListModel> build() async {
    return _fetchCelebList();
  }

  Future<CelebListModel> _fetchCelebList() async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/celeb');
    return CelebListModel.fromJson(response.data);
  }

  Future<void> addBookmark(CelebModel celeb) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.post('/celeb/${celeb.id}/bookmark');
    final updatedList = CelebListModel.fromJson(response.data);
    state = AsyncValue.data(updatedList);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }

  Future<void> removeBookmark(CelebModel celeb) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.delete('/celeb/${celeb.id}/bookmark');
    final updatedList = CelebListModel.fromJson(response.data);
    state = AsyncValue.data(updatedList);

    ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
  }
}

@riverpod
class AsyncMyCelebList extends _$AsyncMyCelebList {
  @override
  Future<CelebListModel> build() async {
    return fetchMyCelebList();
  }

  Future<CelebListModel> fetchMyCelebList() async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/celeb/me');
    return CelebListModel.fromJson(response.data);
  }
}

@riverpod
class SelectedCeleb extends _$SelectedCeleb {
  CelebModel? selectedCeleb; // 초기 값이 필요하다면 임시로 할당

  @override
  CelebModel? build() => selectedCeleb;

  void setSelectedCeleb(CelebModel? celebModel) {
    state = celebModel;
  }
}
