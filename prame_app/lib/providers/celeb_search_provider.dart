import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/models/prame/celeb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celeb_search_provider.g.dart';

@riverpod
class AsyncCelebSearch extends _$AsyncCelebSearch {
  String? _lastQuery;

  @override
  Future<CelebListModel> build() async {
    return CelebListModel(
        items: [],
        meta: MetaModel(
            currentPage: 0,
            itemCount: 0,
            itemsPerPage: 0,
            totalItems: 0,
            totalPages: 0));
  }

  Future<void> searchCeleb(String query) async {
    logger.d('Searching for $query');
    _lastQuery = query; // 쿼리 저장
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/celeb/search?q=$query');
    state = AsyncValue.data(CelebListModel.fromJson(response.data));
  }

  Future<void> repeatSearch() async {
    if (_lastQuery == null) {
      return;
    }
    await searchCeleb(_lastQuery!);
  }

  Future<void> reset() async {
    state = AsyncValue.data(CelebListModel(
        items: [],
        meta: MetaModel(
            currentPage: 0,
            itemCount: 0,
            itemsPerPage: 0,
            totalItems: 0,
            totalPages: 0)));
  }
}
