import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/comment/comment_input.dart';
import 'package:picnic_lib/presentation/common/comment/comment_item.dart';
import 'package:picnic_lib/presentation/common/comment/comment_reply_layer.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/bottom_sheet_header.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

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
    _pagingController = PagingController<int, CommentModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetchPage,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pagingController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<CommentModel>> _fetchPage(int pageKey) async {
    if (_isDisposed) return [];

    try {
      final params = CommentsPageParams(
        postId: widget.id,
        pageKey: pageKey,
        pageSize: _pageSize,
      );

      final newItems = await ref.read(commentsPageProvider(params).future);

      if (_isDisposed) return [];

      return newItems;
    } catch (error, stack) {
      logger.e('Error fetching comments: $error', stackTrace: stack);
      rethrow;
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
        if (navigatorKey.currentContext != null) {
          SnackbarUtil()
              .showSnackbar(AppLocalizations.of(navigatorKey.currentContext!).error_action_failed);
        }
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
          padding: EdgeInsets.only(left: 40.w),
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
    return PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) =>
            PagedListView<int, CommentModel>(
              state: _pagingController.value,
              fetchNextPage: _pagingController.fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<CommentModel>(
                noItemsFoundIndicatorBuilder: (_) => NoItemContainer(
                  message:
                      AppLocalizations.of(context).label_article_comment_empty,
                ),
                firstPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: MediumPulseLoadingIndicator(),
                  ),
                ),
                newPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: MediumPulseLoadingIndicator(),
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
                        AppLocalizations.of(context)
                            .error_loading_more_comments,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refreshComments,
                        child: Text(AppLocalizations.of(context).label_retry),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_, item, __) => _buildCommentItem(item),
              ),
            ));
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
