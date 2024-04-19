import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/models/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../pages/article_page.dart';

part 'article_list_provider.g.dart';

@riverpod
class AsyncArticleList extends _$AsyncArticleList {
  final PagingController<int, ArticleModel> _pagingController =
      PagingController(firstPageKey: 1);
  late int galleryId;
  @override
  Future<PagingController<int, ArticleModel>> build(galleyId) async {
    galleryId = galleyId;
    final sortOption = ref.read(sortOptionProvider);
    fetch(
        page: 1,
        galleryId: galleryId,
        limit: 10,
        sort: sortOption.sort,
        order: sortOption.order);
    return _pagingController;
  }

  PagingController<int, ArticleModel> get pagingController => _pagingController;

  // Future<void> addItems(ArticleListModel articleListModel) {
  //   final newState = state.copyWithPrevious(state);
  //   newState.value?.items.addAll(articleListModel.items);
  //   state = newState;
  //   return Future.value();
  // }

  Future<void> clearItems() {
    state.value?.itemList?.clear();
    return Future.value();
  }

  Future<void> fetch({
    required int page,
    required int galleryId,
    required int limit,
    required String sort,
    required String order,
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
    final ArticleListModel articleListModel =
        ArticleListModel.fromJson(response.data);
    if (articleListModel.meta.currentPage >= articleListModel.meta.totalPages) {
      _pagingController.appendLastPage(articleListModel.items);
    } else {
      _pagingController.appendPage(
          articleListModel.items, articleListModel.meta.currentPage + 1);
    }

    // logger.d(response.data);
    // return ArticleListModel.fromJson(response.data);
  }
}

@riverpod
class SortOption extends _$SortOption {
  SortOptionType sortOptions = SortOptionType('id', 'DESC');

  @override
  SortOptionType build() {
    sortOptions = SortOptionType('id', 'DESC');
    return sortOptions;
  }

  void setSortOption(String sort, String order) {
    state = SortOptionType(sort, order);
  }
}

class SortOptionType {
  String sort = '';
  String order = '';

  SortOptionType(this.sort, this.order);
}
