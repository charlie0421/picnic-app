import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/comment/comment_popup_menu.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class CommunityMyComment extends ConsumerStatefulWidget {
  const CommunityMyComment({super.key});

  @override
  ConsumerState<CommunityMyComment> createState() => _CommunityMyCommentState();
}

class _CommunityMyCommentState extends ConsumerState<CommunityMyComment> {
  late final PagingController<int, CommentModel> _pagingController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.none,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).post_my_written_reply,
          );
    });

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

  static const _pageSize = 20;

  Future<List<CommentModel>> _fetchPage(int pageKey) async {
    final userCommentsNotifier = ref.read(
      userCommentsNotifierProvider(
        supabase.auth.currentUser!.id,
        pageKey,
        10,
      ).notifier,
    );

    return await userCommentsNotifier.build(
      supabase.auth.currentUser!.id,
      pageKey,
      10,
      includeDeleted: false,
      includeReported: false,
    );
  }

  Future<void> _handleRefresh() async {
    _pagingController.refresh();
  }

  Future<void> _handleDelete(String commentId) async {
    try {
      final commentsNotifier = ref.read(
        commentsNotifierProvider(commentId, 1, 10).notifier,
      );
      await commentsNotifier.deleteComment(commentId);
      _handleRefresh();
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);

      if (!mounted) return;

      SnackbarUtil().showSnackbar(
        AppLocalizations.of(context).post_comment_delete_fail,
        backgroundColor: Colors.red,
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) =>
          PagedListView<int, CommentModel>(
        state: _pagingController.value,
        fetchNextPage: _pagingController.fetchNextPage,
        builderDelegate: PagedChildBuilderDelegate<CommentModel>(
          itemBuilder: (context, item, index) => CommentListItem(
            item: item,
            onDelete: () => _handleDelete(item.commentId),
            onRefresh: _handleRefresh,
          ),
          noItemsFoundIndicatorBuilder: (context) => const NoItemContainer(),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context).post_comment_loading_fail),
                ElevatedButton(
                  onPressed: _handleRefresh,
                  child: Text(AppLocalizations.of(context).common_retry_label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommentListItem extends StatelessWidget {
  final CommentModel item;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const CommentListItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      width: getPlatformScreenSize(context).width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(context),
                const SizedBox(height: 5),
                CommentContents(item: item),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          CommentPopupMenu(
            postId: item.post!.postId,
            comment: item,
            onDelete: onDelete,
            refreshFunction: onRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          getLocaleTextFromJson(item.post!.board!.name),
          style: getTextStyle(AppTypo.caption12B, AppColors.primary500),
        ),
        SizedBox(width: 4.w),
        ProfileImageContainer(
          avatarUrl: item.user?.avatarUrl,
          borderRadius: 4,
          width: 18,
          height: 18,
        ),
        SizedBox(width: 4.w),
        Text(
          item.user?.nickname ?? '',
          style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
        ),
        SizedBox(width: 4.w),
        Text(
          formatTimeAgo(context, item.createdAt),
          style: getTextStyle(AppTypo.caption10SB, AppColors.grey400),
        ),
      ],
    );
  }
}

class CommentContents extends StatefulWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  CommentContentsState createState() => CommentContentsState();
}

class CommentContentsState extends State<CommentContents> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: widget.item.content?[widget.item.locale] ?? {},
            style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          );

          final textPainter = TextPainter(
            text: textSpan,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout(maxWidth: constraints.maxWidth - 40);

          final exceedsMaxLines = textPainter.didExceedMaxLines;

          return GestureDetector(
            onTap: exceedsMaxLines ? _toggleExpanded : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.content?[widget.item.locale] ?? {},
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ),
                if (exceedsMaxLines && !_expanded)
                  Text(
                    AppLocalizations.of(context).post_comment_content_more,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
