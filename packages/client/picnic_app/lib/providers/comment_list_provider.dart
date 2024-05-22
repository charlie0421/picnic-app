import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/main.dart';
import 'package:picnic_app/models/prame/comment.dart';
import 'package:picnic_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_list_provider.g.dart';

@riverpod
class AsyncCommentList extends _$AsyncCommentList {
  @override
  Future<CommentState> build(
      {required int articleId,
      required PagingController<int, CommentModel> pagingController}) async {
    fetch(1, 10, 'article', 'ASC', articleId: articleId);
    return CommentState(
      articleId: articleId,
      page: 1,
      limit: 10,
      sort: 'article',
      order: 'ASC',
      pagingController: pagingController,
      commentCount: 0,
    );
  }

  Future<CommentState> fetch(
    int page,
    int limit,
    String sort,
    String order, {
    required int articleId,
  }) async {
    final response = await supabase
        .from('comment')
        .select()
        .eq('article_id', articleId)
        .range((page - 1) * limit, page * limit - 1)
        .order(sort, ascending: order == 'ASC');

    final commentCount = await supabase
        .from('comment')
        .select('count(*)')
        .eq('article_id', articleId)
        .single();

    return CommentState(
      articleId: articleId,
      page: page,
      limit: limit,
      sort: sort,
      order: order,
      pagingController: pagingController,
      commentCount: commentCount['count'] as int,
    );
  }

  Future<void> submitComment({
    required int articleId,
    required String content,
    int? parentId,
  }) async {
    final response = await supabase.from('comment').insert({
      'article_id': articleId,
      'content': content,
      'parent_id': parentId,
    });
  }
}

@reflector
class CommentState {
  final int articleId;
  final int page;
  final int limit;
  final String sort;
  final String order;
  final PagingController<int, CommentModel> pagingController;
  final int commentCount;

  CommentState({
    required this.articleId,
    required this.page,
    required this.limit,
    required this.sort,
    required this.order,
    required this.pagingController,
    required this.commentCount,
  });
}

@riverpod
class ParentItem extends _$ParentItem {
  @override
  CommentModel? build() {
    return null;
  }

  void setParentItem(CommentModel? commentModel) {
    state = commentModel;
  }
}
