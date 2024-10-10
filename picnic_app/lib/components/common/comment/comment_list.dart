import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/comment_input.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/ui/bottom_sheet_header.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/util/ui.dart';

class CommentList extends ConsumerStatefulWidget {
  const CommentList(this.title,
      {required this.id,
      this.openCommentsModal,
      this.openReportModal,
      super.key});
  final String title;
  final String id;
  final Function? openCommentsModal;
  final Function? openReportModal;

  @override
  ConsumerState<CommentList> createState() => _CommentListState();
}

class _CommentListState extends ConsumerState<CommentList> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await comments(ref, widget.id, pageKey, 10);
      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> _refreshComments() async {
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final parentComment = ref.watch(parentItemProvider);
    final bool isReplyMode =
        parentComment != null && parentComment.commentId.isNotEmpty;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                BottomSheetHeader(title: widget.title),
                Expanded(
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (scrollNotification) {
                      _dismissKeyboard();
                      return true;
                    },
                    child: RefreshIndicator(
                      onRefresh: _refreshComments,
                      child: PagedListView<int, CommentModel>(
                        pagingController: _pagingController,
                        builderDelegate:
                            PagedChildBuilderDelegate<CommentModel>(
                          noItemsFoundIndicatorBuilder: (context) => Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                S.of(context).label_article_comment_empty,
                                style: const TextStyle(
                                    fontSize: 30, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          firstPageErrorIndicatorBuilder: (context) => Center(
                            child: Text(
                                'Error loading comments: ${_pagingController.error}'),
                          ),
                          newPageErrorIndicatorBuilder: (context) => Center(
                            child: Text(
                                'Error loading more comments: ${_pagingController.error}'),
                          ),
                          itemBuilder: (context, item, index) {
                            return Column(
                              children: [
                                CommentItem(
                                  commentModel: item,
                                  pagingController: _pagingController,
                                  openCommentsModal: widget.openCommentsModal,
                                  openReportModal: widget.openReportModal,
                                ),
                                if (item.children != null &&
                                    item.children!.isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: item.children!.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(left: 40.cw),
                                        child: CommentItem(
                                          commentModel: item.children![index],
                                          pagingController: _pagingController,
                                          openCommentsModal:
                                              widget.openCommentsModal,
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (isReplyMode)
                  CommentReplyLayer(
                      parentComment: parentComment,
                      pagingController: _pagingController),
                CommentInput(
                    id: widget.id, pagingController: _pagingController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
