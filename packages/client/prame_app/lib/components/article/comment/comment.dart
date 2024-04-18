import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/comment/comment_item.dart';
import 'package:prame_app/components/article/comment/comment_reply_layer.dart';
import 'package:prame_app/components/ui/bottom-sheet-header.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';
import 'package:prame_app/ui/style.dart';

import 'comment_input.dart';

class Comment extends ConsumerStatefulWidget {
  final ArticleModel articleModel;

  const Comment({super.key, required this.articleModel});

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  late final PagingController<int, CommentModel> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, CommentModel>(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      fetchPage(pageKey);
    });
  }

  void fetchPage(int pageKey) async {
    final asyncCommentList = ref.read(asyncCommentListProvider.notifier).fetch(
        pageKey, 10, 'comment.created_at', 'DESC',
        articleId: widget.articleModel.id);

    final page = await asyncCommentList;
    if (page.meta.currentPage < page.meta.totalPages) {
      _pagingController.appendPage(page.items, pageKey + 1);
    } else {
      _pagingController.appendLastPage(page.items);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCommentListState = ref.watch(asyncCommentListProvider);
    asyncCommentListState.value?.meta.totalItems;

    final commentCount = asyncCommentListState.value != null &&
            asyncCommentListState.value!.meta.totalItems != null
        ? asyncCommentListState.value!.meta.totalItems
        : 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeyboardDismissOnTap(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BottomSheetHeader(
              title: '${widget.articleModel.titleKo} ($commentCount)'),
          Flexible(
            flex: 1,
            child: PagedListView<int, CommentModel>(
              physics: const ScrollPhysics(),
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<CommentModel>(
                  noItemsFoundIndicatorBuilder: (context) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            Intl.message('label_article_comment_empty'),
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  itemBuilder: (context, item, index) {
                    return Column(
                      children: [
                        CommentItem(
                            commentModel: item,
                            pagingController: _pagingController,
                            articleId: widget.articleModel.id),
                        item.children != null
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: item.children!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.only(left: 50),
                                    child: CommentItem(
                                      commentModel: item.children![index],
                                      pagingController: _pagingController,
                                      articleId: widget.articleModel.id,
                                    ),
                                  );
                                })
                            : const Text('aaaa'),
                      ],
                    );
                  }),
            ),
          ),
          Column(
            children: [
              Consumer(builder:
                  (BuildContext context, WidgetRef ref, Widget? child) {
                final parentComment = ref.watch(parentItemProvider);
                return parentComment != null && parentComment.id != 0
                    ? CommentReplyLayer(
                        parentComment: parentComment,
                        pagingController: _pagingController)
                    : Container();
              }),
              CommentInput(
                articleId: widget.articleModel.id,
                pagingController: _pagingController,
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
