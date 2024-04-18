import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/models/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../pages/article_page.dart';

part 'article_list_provider.g.dart';

@riverpod
class AsyncArticleList extends _$AsyncArticleList {
  AsyncArticleList() : super();

  @override
  Future<ArticleListModel?> build() async {
    return Future.value(null);
  }

  Future<void> addItems(ArticleListModel articleListModel) {
    final newState = state.copyWithPrevious(state);
    newState.value?.items.addAll(articleListModel.items);
    state = newState;
    return Future.value();
  }

  Future<void> clearItems() {
    final newState = state.copyWithPrevious(state);
    newState.value?.items.clear();
    state = newState;
    return Future.value();
  }

  Future<ArticleListModel?> fetch({
    required int page,
    required int galleryId,
    int? limit,
    String? sort,
    String? order,
  }) async {
    final params = {
      'page': page,
      'limit': limit,
      'sort': sort,
      'order': order,
    };

    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response =
        await dio.get('/gallery/articles/$galleryId', queryParameters: params);
    // logger.d(response.data);
    return ArticleListModel.fromJson(response.data);
  }

  void setSortOption(
      {required int galleryId,
      required int limit,
      required String sort,
      required String order}) {
    state = AsyncData(ArticleListModel(
        items: [],
        meta: MetaModel(
            currentPage: 0,
            itemCount: 0,
            itemsPerPage: 0,
            totalItems: 0,
            totalPages: 0)));
    ref.read(sortOptionProvider.notifier).setSortOption(sort);
    // fetch(galleryId: 1, limit: limit, page: 1, sort: sort, order: order);
  }
}

@riverpod
class SortOption extends _$SortOption {
  @override
  String build() {
    return 'id';
  }

  void setSortOption(String sort) {
    ref.read(asyncArticleListProvider.notifier).clearItems();
    state = sort;
  }
}
