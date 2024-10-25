import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/comment_input.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/ui/bottom_sheet_header.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/util/ui.dart';

class CommentList extends ConsumerStatefulWidget {
  const CommentList(
    this.title, {
    required this.id,
    this.openCommentsModal,
    this.openReportModal,
    super.key,
  });

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
      final commentsNotifier =
          ref.read(commentsNotifierProvider(widget.id, pageKey, 10).notifier);
      final newItemsValue =
          await commentsNotifier.build(widget.id, pageKey, 10);

      final isLastPage = newItemsValue.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItemsValue);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItemsValue, nextPageKey);
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

  Future<void> _handleLikeComment(
      String commentId, bool currentLikeStatus) async {
    final commentsNotifier =
        ref.read(commentsNotifierProvider(widget.id, 1, 10).notifier);
    if (currentLikeStatus) {
      await commentsNotifier.unlikeComment(commentId);
    } else {
      await commentsNotifier.likeComment(commentId);
    }
  }

  Future<void> _handleReportComment(
      CommentModel comment, String reason, String text) async {
    final commentsNotifier =
        ref.read(commentsNotifierProvider(widget.id, 1, 10).notifier);
    await commentsNotifier.reportComment(comment, reason, text);
  }

  Future<void> _handleDeleteComment(String commentId) async {
    final commentsNotifier =
        ref.read(commentsNotifierProvider(widget.id, 1, 10).notifier);
    await commentsNotifier.deleteComment(commentId);
    _refreshComments();
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
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
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
                          noItemsFoundIndicatorBuilder: (context) =>
                              NoItemContainer(
                            message: S.of(context).label_article_comment_empty,
                          ),
                          firstPageErrorIndicatorBuilder: (context) =>
                              ErrorView(
                            context,
                            error: _pagingController.error,
                            retryFunction: _refreshComments,
                            stackTrace: null,
                          ),
                          newPageErrorIndicatorBuilder: (context) => Center(
                            child: Text(
                                'Error loading more comments: ${_pagingController.error}'),
                          ),
                          itemBuilder: (context, item, index) {
                            return Column(
                              children: [
                                CommentItem(
                                  postId: widget.id,
                                  commentModel: item,
                                  pagingController: _pagingController,
                                  openCommentsModal: widget.openCommentsModal,
                                  openReportModal: widget.openReportModal,
                                  onLike: () => _handleLikeComment(
                                      item.commentId, item.isLiked ?? false),
                                  onReport: (String reason, String text) =>
                                      _handleReportComment(item, reason, text),
                                  onDelete: () =>
                                      _handleDeleteComment(item.commentId),
                                ),
                                if (item.children != null &&
                                    item.children!.isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: item.children!.length,
                                    itemBuilder: (context, index) {
                                      final childItem = item.children![index];
                                      return Container(
                                        padding: EdgeInsets.only(left: 40.cw),
                                        child: CommentItem(
                                          postId: widget.id,
                                          commentModel: childItem,
                                          pagingController: _pagingController,
                                          openCommentsModal:
                                              widget.openCommentsModal,
                                          onLike: () => _handleLikeComment(
                                            childItem.commentId,
                                            childItem.isLiked ?? false,
                                          ),
                                          onReport: (reason, text) =>
                                              _handleReportComment(
                                                  childItem, reason, text),
                                          onDelete: () => _handleDeleteComment(
                                              childItem.commentId),
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
                    pagingController: _pagingController,
                  ),
                CommentInput(
                  id: widget.id,
                  pagingController: _pagingController,
                  onPostComment: (String postId, String? parentId,
                      String locale, String content) async {
                    final commentsNotifier = ref.read(
                      commentsNotifierProvider(widget.id, 1, 10).notifier,
                    );

                    await commentsNotifier.postComment(
                        postId, parentId, locale, content);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
