import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/article/comment/comment_item.dart';
import 'package:picnic_app/components/article/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/ui/bottom-sheet-header.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/models/pic/comment.dart';
import 'package:picnic_app/providers/article_list_provider.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';

import 'comment_input.dart';

class Comment extends ConsumerStatefulWidget {
  final ArticleModel articleModel;
  final int? commentId;

  const Comment({super.key, required this.articleModel, this.commentId});

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);
  late final ScrollController _scrollController; // Add this line
  late int _scrollToIndex; // Add this line

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Add this line
    _scrollToIndex = -1; // Add this line
    _pagingController.addPageRequestListener((pageKey) {
      fetchPage(pageKey);
    });
  }

  void fetchPage(int pageKey) async {
    final asyncCommentList = ref.read(asyncCommentListProvider(
            articleId: widget.articleModel.id,
            pagingController: _pagingController)
        .notifier);
    ref
        .read(asyncCommentListProvider(
                articleId: widget.articleModel.id,
                pagingController: _pagingController)
            .notifier)
        .fetch(pageKey, 1000, 'article_comment.id', 'DESC',
            articleId: widget.articleModel.id);

    // final page = await asyncCommentNotifier;
    // if (page.meta.currentPage < page.meta.totalPages) {
    //   _pagingController.appendPage(page.items, pageKey + 1);
    // } else {
    //   _pagingController.appendLastPage(page.items);
    // }

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (widget.commentId != -1) {
    //     for (int i = 0; i < page.items.length; i++) {
    //       if (page.items[i].id == widget.commentId) {
    //         _scrollToIndex =
    //             _pagingController.itemList!.length - page.items.length + i;
    //         WidgetsBinding.instance.addPostFrameCallback((_) {
    //           _scrollController.animateTo(_scrollToIndex * 100.0,
    //               duration: const Duration(seconds: 1),
    //               curve: Curves.easeInOut);
    //         });
    //         break;
    //       }
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCommentList = ref.watch(asyncCommentListProvider(
        articleId: widget.articleModel.id,
        pagingController: _pagingController));

    final commentCountNotifier =
        ref.watch(commentCountProvider(widget.articleModel.id).notifier);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   commentCountNotifier.setCount(commentCount);
    // });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeyboardDismissOnTap(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BottomSheetHeader(
              title:
                  '${widget.articleModel.title_ko} (${asyncCommentList.value?.commentCount})'),
          Flexible(
            flex: 1,
            child: PagedListView<int, CommentModel>(
              scrollController: _scrollController,
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
                    logger.i('item: $item');
                    return Column(
                      children: [
                        CommentItem(
                          commentModel: item,
                          pagingController: _pagingController,
                          articleId: widget.articleModel.id,
                          shouldHighlight:
                              item.id == widget.commentId, // Add this line
                        ),
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
                                      shouldHighlight:
                                          item.children?[index].id ==
                                              widget.commentId,
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
