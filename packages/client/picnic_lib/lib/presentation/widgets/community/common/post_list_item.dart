import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class PostListItem extends ConsumerStatefulWidget {
  final PostModel post;
  final Widget? popupMenu;

  const PostListItem({super.key, required this.post, required this.popupMenu});

  @override
  ConsumerState<PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends ConsumerState<PostListItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref
            .read(communityStateInfoProvider.notifier)
            .setCurrentBoard(widget.post.board!);

        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentPage(PostViewPage(widget.post.postId));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey300,
              width: 1.w,
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
                    if (widget.post.board != null)
                      Text(getLocaleTextFromJson(widget.post.board!.name),
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.primary500)),
                    SizedBox(width: 4.w),
                    widget.post.isAnonymous ?? false
                        ? const NoAvatar(
                            width: 18,
                            height: 18,
                            borderRadius: 4,
                          )
                        : ProfileImageContainer(
                            avatarUrl: widget.post.userProfiles?.avatarUrl,
                            borderRadius: 4,
                            width: 18,
                            height: 18,
                          ),
                    SizedBox(width: 4.w),
                    widget.post.isAnonymous ?? false
                        ? Text(t('anonymous'),
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900))
                        : Text(widget.post.userProfiles?.nickname ?? '',
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900)),
                    SizedBox(width: 4.w),
                    Text(formatTimeAgo(context, widget.post.createdAt!),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey400)),
                  ],
                ),
                Text(widget.post.title ?? '',
                    style: getTextStyle(AppTypo.body14M, AppColors.grey900)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: t('views'),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: ' ',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: widget.post.viewCount.toString(),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: ' ',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: t('replies'),
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: ' ',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.grey600),
                      ),
                      TextSpan(
                        text: widget.post.replyCount.toString(),
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
            widget.popupMenu ?? Container(),
          ],
        ),
      ),
    );
  }
}
