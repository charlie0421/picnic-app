import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/prame/comment.dart';
import 'package:picnic_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

part 'comment_list_provider.g.dart';

@riverpod
class AsyncCommentList extends _$AsyncCommentList {
  @override
  Future<CommentState> build(
      {required int articleId,
      required PagingController<int, CommentModel> pagingController}) async {
    fetch(1, 10, 'article_comment.id', 'ASC', articleId: articleId);
    return CommentState(
      articleId: articleId,
      page: 1,
      limit: 10,
      sort: 'article_comment.id',
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
    final response = await Supabase.instance.client
        .from('article_comment')
        .select()
        .eq('article_id', articleId)
        .order('id', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    final commentCount = await Supabase.instance.client
        .from('article_comment')
        .select()
        .eq('article_id', articleId)
        .count(CountOption.exact);

    return CommentState(
        articleId: articleId,
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        pagingController: pagingController,
        commentCount: commentCount.count);
  }

  Future<void> submitComment({
    required int articleId,
    required String content,
    int? parentId,
  }) async {
    logger.i('submitComment articleId: $articleId, content: $content');
    final response =
        await Supabase.instance.client.from('article_comment').insert({
      'article_id': articleId,
      'content': content,
      'parent_id': parentId,
    });
    logger.i('submitComment response: $response');
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
