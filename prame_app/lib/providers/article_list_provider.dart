import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'article_list_provider.g.dart';

@riverpod
class AsyncArticleList extends _$AsyncArticleList {
  @override
  Future<ArticleListModel> build(
    int? page,
    int? limit,
    String? sort,
    String? order, {
    required int galleryId,
  }) async {
    return fetch(
      page = 1,
      limit = 10,
      sort = 'article.created_at',
      order = 'DESC',
      galleryId: galleryId,
    );
  }

  Future<ArticleListModel> fetch(
    int page,
    int limit,
    String sort,
    String order, {
    required int galleryId,
  }) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get('/gallery/articles/$galleryId');
    return ArticleListModel.fromJson(response.data);
  }
}

@riverpod
class SortOption extends _$SortOption {
  @override
  String build() {
    return 'club.created_at';
  }

  void setSortOption(String sort) {
    state = sort;
  }
}
