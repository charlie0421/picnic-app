import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/comment/comment_popup_menu.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class CommunityMyComment extends ConsumerStatefulWidget {
  const CommunityMyComment({super.key});

  @override
  ConsumerState<CommunityMyComment> createState() => _CommunityMyCommentState();
}

class _CommunityMyCommentState extends ConsumerState<CommunityMyComment> {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _initializePagingController();
  }

  void _initializeNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.none,
            showBottomNavigation: false,
            pageTitle: S.of(context).post_my_written_reply,
          );
    });
  }

  void _initializePagingController() {
    _pagingController.addPageRequestListener((pageKey) => _fetchPage(pageKey));
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCommentsNotifier = ref.read(
        userCommentsNotifierProvider(
          supabase.auth.currentUser!.id,
          pageKey,
          10,
        ).notifier,
      );

      final newItems = await userCommentsNotifier.build(
        supabase.auth.currentUser!.id,
        pageKey,
        10,
        includeDeleted: false,
        includeReported: false,
      );

      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).post_comment_delete_fail),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: PagedListView<int, CommentModel>(
        pagingController: _pagingController,
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
                Text(S.of(context).post_comment_loading_fail),
                ElevatedButton(
                  onPressed: _handleRefresh,
                  child: Text(S.of(context).common_retry_label),
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
        horizontal: 16.cw,
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
          SizedBox(width: 10.cw),
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
        SizedBox(width: 4.cw),
        ProfileImageContainer(
          avatarUrl: item.user.avatarUrl,
          borderRadius: 4,
          width: 18,
          height: 18,
        ),
        SizedBox(width: 4.cw),
        Text(
          item.user.nickname ?? '',
          style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
        ),
        SizedBox(width: 4.cw),
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
            text: getLocaleTextFromJson(widget.item.content ?? {}),
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
                    getLocaleTextFromJson(widget.item.content ?? {}),
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ),
                if (exceedsMaxLines && !_expanded)
                  Text(
                    S.of(context).post_comment_content_more,
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
