import 'dart:async';

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
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/snackbar_util.dart';
import 'package:picnic_app/util/ui.dart';

final commentsPageProvider = FutureProvider.autoDispose
    .family<List<CommentModel>, CommentsPageParams>((ref, params) async {
  final commentsNotifier = ref.read(
    commentsNotifierProvider(params.postId, params.pageKey, params.pageSize)
        .notifier,
  );

  return Future.value(
    commentsNotifier.build(params.postId, params.pageKey, params.pageSize),
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Comments loading timed out'),
  );
});

class CommentsPageParams {
  final String postId;
  final int pageKey;
  final int pageSize;

  const CommentsPageParams({
    required this.postId,
    required this.pageKey,
    required this.pageSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentsPageParams &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          pageKey == other.pageKey &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(postId, pageKey, pageSize);
}

class CommentList extends ConsumerStatefulWidget {
  const CommentList({
    required this.title,
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
  static const int _pageSize = 10;
  late final PagingController<int, CommentModel> _pagingController;
  bool _isDisposed = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 1)
      ..addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pagingController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isDisposed) return;

    try {
      final params = CommentsPageParams(
        postId: widget.id,
        pageKey: pageKey,
        pageSize: _pageSize,
      );

      final newItems = await ref.read(commentsPageProvider(params).future);

      if (_isDisposed) return;

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (error, stack) {
      logger.e('Error fetching comments: $error', stackTrace: stack);
      if (!_isDisposed) {
        _pagingController.error = error;
      }
    }
  }

  Future<void> _refreshComments() async {
    _pagingController.refresh();
  }

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  Future<void> _handleCommentAction(Future<void> Function() action) async {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {});

    try {
      await action();
      if (!_isDisposed) {
        await _refreshComments();
      }
    } catch (e, s) {
      logger.e('Error handling comment action: $e', stackTrace: s);
      if (!_isDisposed) {
        if (!context.mounted) return;
        SnackbarUtil().showSnackbar(S.of(context).error_action_failed);
      }
    } finally {
      _debounceTimer?.cancel();
    }
  }

  Future<void> _handleLikeComment(String commentId, bool currentLikeStatus) {
    final commentsNotifier = ref.read(
      commentsNotifierProvider(widget.id, 1, _pageSize).notifier,
    );

    return _handleCommentAction(() {
      return currentLikeStatus
          ? commentsNotifier.unlikeComment(commentId)
          : commentsNotifier.likeComment(commentId);
    });
  }

  Future<void> _handleReportComment(
    CommentModel comment,
    String reason,
    String text,
  ) {
    final commentsNotifier = ref.read(
      commentsNotifierProvider(widget.id, 1, _pageSize).notifier,
    );

    return _handleCommentAction(() {
      return commentsNotifier.reportComment(comment, reason, text);
    });
  }

  Future<void> _handleDeleteComment(String commentId) {
    final commentsNotifier = ref.read(
      commentsNotifierProvider(widget.id, 1, _pageSize).notifier,
    );

    return _handleCommentAction(() {
      return commentsNotifier.deleteComment(commentId);
    });
  }

  Widget _buildCommentItem(CommentModel item) {
    return Column(
      children: [
        CommentItem(
          postId: widget.id,
          commentModel: item,
          pagingController: _pagingController,
          openCommentsModal: widget.openCommentsModal,
          openReportModal: widget.openReportModal,
          onLike: () => _handleLikeComment(
            item.commentId,
            item.isLikedByMe ?? false,
          ),
          onReport: (reason, text) => _handleReportComment(item, reason, text),
          onDelete: () => _handleDeleteComment(item.commentId),
        ),
        if (item.children?.isNotEmpty ?? false)
          _buildChildComments(item.children!),
      ],
    );
  }

  Widget _buildChildComments(List<CommentModel> children) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final childItem = children[index];
        return Padding(
          padding: EdgeInsets.only(left: 40.cw),
          child: CommentItem(
            postId: widget.id,
            commentModel: childItem,
            pagingController: _pagingController,
            openCommentsModal: widget.openCommentsModal,
            onLike: () => _handleLikeComment(
              childItem.commentId,
              childItem.isLikedByMe ?? false,
            ),
            onReport: (reason, text) => _handleReportComment(
              childItem,
              reason,
              text,
            ),
            onDelete: () => _handleDeleteComment(childItem.commentId),
          ),
        );
      },
    );
  }

  Widget _buildPagedListView() {
    return PagedListView<int, CommentModel>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<CommentModel>(
        noItemsFoundIndicatorBuilder: (_) => NoItemContainer(
          message: S.of(context).label_article_comment_empty,
        ),
        firstPageProgressIndicatorBuilder: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        newPageProgressIndicatorBuilder: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
        firstPageErrorIndicatorBuilder: (context) => buildErrorView(
          context,
          error: _pagingController.error,
          retryFunction: _refreshComments,
          stackTrace: null,
        ),
        newPageErrorIndicatorBuilder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                S.of(context).error_loading_more_comments,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshComments,
                child: Text(S.of(context).label_retry),
              ),
            ],
          ),
        ),
        itemBuilder: (_, item, __) => _buildCommentItem(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentComment = ref.watch(parentItemProvider);
    final bool isReplyMode = parentComment?.commentId.isNotEmpty ?? false;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
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
                    onNotification: (notification) {
                      _dismissKeyboard();
                      return true;
                    },
                    child: RefreshIndicator(
                      onRefresh: _refreshComments,
                      child: _buildPagedListView(),
                    ),
                  ),
                ),
                if (isReplyMode)
                  CommentReplyLayer(
                    parentComment: parentComment!,
                    pagingController: _pagingController,
                  ),
                CommentInput(
                  id: widget.id,
                  pagingController: _pagingController,
                  onPostComment: (postId, parentId, locale, content) async {
                    final commentsNotifier = ref.read(
                      commentsNotifierProvider(widget.id, 1, _pageSize)
                          .notifier,
                    );
                    await _handleCommentAction(() {
                      return commentsNotifier.postComment(
                        postId,
                        parentId,
                        locale,
                        content,
                      );
                    });
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
