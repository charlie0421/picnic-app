import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/comment_input.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_reply_layer.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/ui/bottom_sheet_header.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class Comment extends ConsumerStatefulWidget {
  final PostModel postModel;
  final String? commentId;
  final Function? openCommentsModal;

  const Comment({
    super.key,
    required this.postModel,
    this.commentId,
    this.openCommentsModal,
  });

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);
  late final ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final commentsNotifier = ref.read(
        commentsNotifierProvider(widget.postModel.postId, pageKey, 10).notifier,
      );

      final comments = await commentsNotifier.build(
        widget.postModel.postId,
        pageKey,
        10,
      );

      final isLastPage = comments.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(comments);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(comments, nextPageKey);
      }

      // Scroll to specific comment if commentId is provided
      if (widget.commentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToComment(comments);
        });
      }
    } catch (e, s) {
      logger.e('Error fetching comments:', error: e, stackTrace: s);
      _pagingController.error = e;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToComment(List<CommentModel> comments) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].commentId == widget.commentId) {
        final itemIndex =
            _pagingController.itemList!.length - comments.length + i;
        _scrollController.animateTo(
          itemIndex * 100.0,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
        break;
      }

      // Check in children comments
      if (comments[i].children != null) {
        for (int j = 0; j < comments[i].children!.length; j++) {
          if (comments[i].children![j].commentId == widget.commentId) {
            final itemIndex =
                _pagingController.itemList!.length - comments.length + i;
            _scrollController.animateTo(
              itemIndex * 100.0,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
            );
            break;
          }
        }
      }
    }
  }

  Future<void> _handleLike(String commentId, bool isLiked) async {
    final commentsNotifier = ref.read(
      commentsNotifierProvider(widget.postModel.postId, 1, 10).notifier,
    );

    try {
      if (isLiked) {
        await commentsNotifier.unlikeComment(commentId);
      } else {
        await commentsNotifier.likeComment(commentId);
      }
      _pagingController.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('좋아요 처리 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(String commentId) async {
    try {
      final commentsNotifier = ref.read(
        commentsNotifierProvider(widget.postModel.postId, 1, 10).notifier,
      );
      await commentsNotifier.deleteComment(commentId);
      _pagingController.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글 삭제 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeyboardDismissOnTap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              title: widget.postModel.title,
            ),
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
                    return Column(
                      children: [
                        CommentItem(
                          commentModel: item,
                          postId: widget.postModel.postId,
                          pagingController: _pagingController,
                          shouldHighlight: item.commentId == widget.commentId,
                          openCommentsModal: widget.openCommentsModal,
                          onLike: () => _handleLike(
                              item.commentId, item.isLiked ?? false),
                          onDelete: () => _handleDelete(item.commentId),
                        ),
                        if (item.children != null && item.children!.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: item.children!.length,
                            itemBuilder: (context, index) {
                              final childItem = item.children![index];
                              return Container(
                                padding: EdgeInsets.only(left: 50.cw),
                                child: CommentItem(
                                  commentModel: childItem,
                                  postId: widget.postModel.postId,
                                  pagingController: _pagingController,
                                  shouldHighlight:
                                      childItem.commentId == widget.commentId,
                                  openCommentsModal: widget.openCommentsModal,
                                  onLike: () => _handleLike(
                                    childItem.commentId,
                                    childItem.isLiked ?? false,
                                  ),
                                  onDelete: () =>
                                      _handleDelete(childItem.commentId),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Column(
              children: [
                Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    final parentComment = ref.watch(parentItemProvider);
                    return parentComment != null &&
                            parentComment.commentId.isNotEmpty
                        ? CommentReplyLayer(
                            parentComment: parentComment,
                            pagingController: _pagingController,
                          )
                        : Container();
                  },
                ),
                CommentInput(
                  id: widget.postModel.postId,
                  pagingController: _pagingController,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
