import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/models/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_list_provider.g.dart';

@riverpod
class AsyncCommentList extends _$AsyncCommentList {
  @override
  Future<CommentListModel> build() async {
    return Future.value(CommentListModel(
        items: [],
        meta: MetaModel(
            currentPage: 0,
            itemCount: 0,
            itemsPerPage: 0,
            totalItems: 0,
            totalPages: 0)));
  }

  Future<CommentListModel> fetch(
    int page,
    int limit,
    String sort,
    String order, {
    required int articleId,
  }) async {
    final dio = await authDio(baseUrl: Constants.userApiUrl);
    final response = await dio.get(
        '/comment/article/$articleId?page=$page&limit=$limit&sort=$sort&order=$order');
    state = AsyncData(CommentListModel.fromJson(response.data));
    return CommentListModel.fromJson(response.data);
  }

  Future<void> submitComment({
    required int articleId,
    required String content,
    int? parentId,
  }) async {
    var dio = await authDio(baseUrl: Constants.userApiUrl);
    try {
      parentId == 0 ? parentId = null : parentId;
      final response = parentId != null
          ? await dio
              .post('/comment/article/$articleId/comment/$parentId', data: {
              'articleId': articleId,
              'content': content,
            })
          : await dio.post('/comment/article/$articleId', data: {
              'articleId': articleId,
              'content': content,
            });
      if (response.statusCode == 201) {
        logger.i('response.data: ${response.data}');
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e, stacTrace) {
      logger.i(stacTrace);
    }
  }
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
