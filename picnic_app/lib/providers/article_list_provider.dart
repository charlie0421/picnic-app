import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'article_list_provider.g.dart';

@riverpod
Future<List<ArticleModel>?> fetchArticleList(
  FetchArticleListRef ref, {
  required int page,
  required int galleryId,
  required int limit,
  required String sort,
  required String order,
}) async {
  try {
    final int from = (page - 1) * limit;
    final int to = page * limit;

    final response = await supabase
        .from('article')
        .select('*, article_image(*, article_image_user(*))')
        .eq('gallery_id', galleryId)
        .order(sort, ascending: order == 'ASC')
        .range(from, to)
        .count();

    return response.data.map((e) => ArticleModel.fromJson(e)).toList();
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);
  }
  return null;
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
