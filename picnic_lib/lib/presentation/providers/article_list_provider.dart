import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../generated/providers/article_list_provider.g.dart';

@riverpod
Future<List<ArticleModel>?> fetchArticleList(
  Ref ref, {
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
  } catch (e, s) {
    logger.e('error', error: e, stackTrace: s);
    Sentry.captureException(
      e,
      stackTrace: s,
    );
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

  void setCount(int count) {
    state = AsyncValue.data(count);
  }

  void increment() {
    state = AsyncValue.data(state.value! + 1);
  }

  void decrement() {
    state = AsyncValue.data(state.value! - 1);
  }
}
