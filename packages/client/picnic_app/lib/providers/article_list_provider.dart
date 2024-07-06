import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/models/pic/article_image.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  Future<void> clearItems() {
    state.value?.itemList?.clear();
    return Future.value();
  }

  Future<List<ArticleModel>?> fetch({
    required int page,
    required int galleryId,
    required int limit,
    required String sort,
    required String order,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        'sort': sort,
        'order': order,
      };

      final List<ArticleModel> response = await supabase
          .from('article')
          .select('*, article_image(*, article_image_user(*))')
          .eq('gallery_id', galleryId)
          .order(sort, ascending: order == 'ASC')
          .range((page - 1) * limit, page * limit)
          .then((value) => value.map((e) => ArticleModel.fromJson(e)).toList());

      for (var i = 0; i < response.length; i++) {
        response[i] = response[i].copyWith(
            article_image: List<ArticleImageModel>.from(response[i]
                .article_image!
                .map((e) => e.copyWith(
                    image:
                        'https://cdn-dev.picnic.fan/article/${response[i].id}/images/${e.id}/${e.image}'))));
      }
      _pagingController.appendPage(response, page + 1);
      return response;
    } catch (e, stackTrace) {
      _pagingController.error = e;
      logger.e(e, stackTrace: stackTrace);
    }
    return null;
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

@reflector
class SortOptionType {
  String sort = '';
  String order = '';

  SortOptionType(this.sort, this.order);
}

@riverpod
class CommentCount extends _$CommentCount {
  @override
  Future<int> build(int articleId) async {
    return 0;
  }

  setCount(int count) {
    state = AsyncValue.data(count);
  }

  increment() {
    state = AsyncValue.data(state.value! + 1);
  }

  decrement() {
    state = AsyncValue.data(state.value! - 1);
  }
}
