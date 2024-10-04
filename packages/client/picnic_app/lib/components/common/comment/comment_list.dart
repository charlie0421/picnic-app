import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/comment_input.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/ui/bottom_sheet_header.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/util/ui.dart';

class CommentList extends ConsumerStatefulWidget {
  const CommentList(this.fetchComments, this.title, this.postComment,
      {required this.id, super.key});
  final Function fetchComments;
  final Function postComment;
  final String title;
  final String id;

  @override
  ConsumerState<CommentList> createState() => _CommentListState();
}

class _CommentListState extends ConsumerState<CommentList> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);
  late final ScrollController _scrollController; // Add this line

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Add this line
    _pagingController.addPageRequestListener((pageKey) async {
      List<CommentModel>? newItems =
          await comments(ref, widget.id, pageKey, 10);
      if (newItems == null) {
        _pagingController.error = S.of(context).error_title;
        return;
      }
      logger.i('newItems: $newItems');
      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(title: widget.title),
        Expanded(
          child: PagedListView<int, CommentModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<CommentModel>(
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
                child:
                    Text('Error loading comments: ${_pagingController.error}'),
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
                    ),
                    if (item.children != null && item.children!.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: item.children!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            padding: EdgeInsets.only(left: 50.cw),
                            child: CommentItem(
                              commentModel: item.children![index],
                              pagingController: _pagingController,
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
        Column(
          children: [
            Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final parentComment = ref.watch(parentItemProvider);
              return parentComment != null && parentComment.commentId.isNotEmpty
                  ? CommentReplyLayer(
                      parentComment: parentComment,
                      pagingController: _pagingController)
                  : Container();
            }),
            CommentInput(
              id: widget.id,
              postComment: widget.postComment,
              pagingController: _pagingController,
            ),
          ],
        ),
      ],
    );
  }
}
