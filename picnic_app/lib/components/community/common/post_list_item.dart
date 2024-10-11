import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/post_view_page.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class PostListItem extends ConsumerStatefulWidget {
  final PostModel post;

  const PostListItem({super.key, required this.post});

  @override
  ConsumerState<PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends ConsumerState<PostListItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref.read(navigationInfoProvider.notifier).setCurrentPage(PostViewPage(
              widget.post,
            ));
        ref.read(communityStateInfoProvider.notifier).setCurrentBoardId(
            widget.post.board_id,
            widget.post.boards.is_official
                ? getLocaleTextFromJson(widget.post.boards.name)
                : widget.post.boards.name['minor']);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey300,
              width: 1.cw,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(getLocaleTextFromJson(widget.post.boards.name),
                        style: getTextStyle(
                            AppTypo.caption12B, AppColors.primary500)),
                    SizedBox(width: 4.cw),
                    widget.post.is_anonymous
                        ? NoAvatar(
                            width: 18,
                            height: 18,
                            borderRadius: 4,
                          )
                        : ProfileImageContainer(
                            avatarUrl: widget.post.user_profiles?.avatar_url,
                            borderRadius: 4,
                            width: 18,
                            height: 18,
                          ),
                    SizedBox(width: 4.cw),
                    widget.post.is_anonymous
                        ? Text('잌명',
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900))
                        : Text(widget.post.user_profiles?.nickname ?? '',
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900)),
                    SizedBox(width: 4.cw),
                    Text(formatTimeAgo(context, widget.post.created_at),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey400)),
                  ],
                ),
                Text(widget.post.title,
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '조회',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: widget.post.view_count.toString(),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: ' ',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: '댓글',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: widget.post.view_count.toString(),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                    ],
                  ),
                ),
                // if (widget.post.imageUrls.isNotEmpty)
                //   Image.network(widget.post.imageUrls.first, width: double.infinity),
              ],
            ),
            PostPopupMenu(
                post: widget.post,
                context: context,
                openReportModal: _openPostReportModal,
                refreshFunction: ref.refresh),
          ],
        ),
      ),
    );
  }

  void _openPostReportModal(String title, PostModel post) {
    try {
      showDialog(
        context: context,
        builder: (context) => ReportDialog(
            title: '게시글 신고하기', type: ReportType.post, target: post),
      );
    } catch (e, s) {
      logger.e('Error: $e, StackTrace: $s');
    }
  }
}
