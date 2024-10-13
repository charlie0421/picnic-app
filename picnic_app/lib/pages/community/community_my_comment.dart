import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/comment/comment_popup_menu.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
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

class _CommunityMyCommentState extends ConsumerState<CommunityMyComment>
    with SingleTickerProviderStateMixin {
  late final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.none,
          showBottomNavigation: false,
          pageTitle: '내가 쓴 댓글');
    });

    _pagingController.addPageRequestListener((pageKey) async {
      final newItems = await commentsByUser(
          ref, supabase.auth.currentUser!.id, pageKey, 10,
          includeDeleted: false, includeReported: false);
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
  Widget build(BuildContext context) {
    return PagedListView<int, CommentModel>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<CommentModel>(
          itemBuilder: (context, item, index) {
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
                        Row(
                          children: [
                            Text(
                              item.post.board!.is_official
                                  ? getLocaleTextFromJson(item.post.board!.name)
                                  : item.post.board?.name['minor'],
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.primary500),
                            ),
                            SizedBox(width: 4.cw),
                            ProfileImageContainer(
                              avatarUrl: item.user.avatar_url,
                              borderRadius: 4,
                              width: 18,
                              height: 18,
                            ),
                            SizedBox(width: 4.cw),
                            Text(
                              item.user.nickname ?? '',
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.grey900),
                            ),
                            SizedBox(width: 4.cw),
                            Text(formatTimeAgo(context, item.createdAt),
                                style: getTextStyle(
                                    AppTypo.caption10SB, AppColors.grey400)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        CommentContents(item: item),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.cw),
                  CommentPopupMenu(
                    comment: item,
                    refreshFunction: _pagingController.refresh,
                  ),
                ],
              ),
            );
          },
          noItemsFoundIndicatorBuilder: (context) {
            return const NoItemContainer();
          },
        ));
  }
}

class CommentContents extends StatefulWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  _CommentContentsState createState() => _CommentContentsState();
}

class _CommentContentsState extends State<CommentContents> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: widget.item.content,
            style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          );

          final textPainter = TextPainter(
            text: textSpan,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout(
              maxWidth: constraints.maxWidth - 40); // 40은 "더보기" 텍스트의 예상 너비입니다.

          final exceedsMaxLines = textPainter.didExceedMaxLines;

          return GestureDetector(
            onTap: () {
              if (exceedsMaxLines) {
                setState(() {
                  _expanded = !_expanded;
                });
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.content,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ),
                if (exceedsMaxLines && !_expanded)
                  Text(
                    '더보기',
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
