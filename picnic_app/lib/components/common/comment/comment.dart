import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/comment_input.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/ui/bottom_sheet_header.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/util/ui.dart';

class Comment extends ConsumerStatefulWidget {
  final ArticleModel articleModel;
  final String? commentId;
  final Function? openCommentsModal;

  const Comment(
      {super.key,
      required this.articleModel,
      this.commentId,
      this.openCommentsModal});

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);
  late final ScrollController _scrollController; // Add this line

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Add this line
    _pagingController.addPageRequestListener((pageKey) {
      fetchPage(pageKey);
    });
  }

  void fetchPage(int pageKey) async {
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
                  noItemsFoundIndicatorBuilder: (context) => NoItemContainer(
                        message: S.of(context).label_article_comment_empty,
                      ),
                  itemBuilder: (context, item, index) {
                    logger.i('item: $item');
                    return Column(
                      children: [
                        CommentItem(
                          commentModel: item,
                          pagingController: _pagingController,
                          shouldHighlight: item.commentId ==
                              widget.commentId, // Add this line
                          openCommentsModal: widget.openCommentsModal,
                        ),
                        item.children != null
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: item.children!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: EdgeInsets.only(left: 50.cw),
                                    child: CommentItem(
                                      commentModel: item.children![index],
                                      pagingController: _pagingController,
                                      shouldHighlight:
                                          item.children?[index].commentId ==
                                              widget.commentId,
                                      openCommentsModal:
                                          widget.openCommentsModal,
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
                return parentComment != null &&
                        parentComment.commentId.isNotEmpty
                    ? CommentReplyLayer(
                        parentComment: parentComment,
                        pagingController: _pagingController)
                    : Container();
              }),
              CommentInput(
                id: widget.articleModel.id.toString(),
                pagingController: _pagingController,
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
