import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/post_view_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';

class PostListItem extends ConsumerWidget {
  final PostModel post;

  const PostListItem({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.i('post: $post');
    return GestureDetector(
      onTap: () {
        ref.read(navigationInfoProvider.notifier).setCurrentPage(PostViewPage(
              post,
            ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey300,
              width: 1.h,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(getLocaleTextFromJson(post.boards.name),
                    style:
                        getTextStyle(AppTypo.caption12B, AppColors.primary500)),
                SizedBox(width: 4.w),
                ProfileImageContainer(
                  avatarUrl: post.user_profiles?.avatar_url,
                  borderRadius: 4,
                  width: 18,
                  height: 18,
                ),
                SizedBox(width: 4.w),
                Text(post.user_profiles?.nickname ?? '',
                    style: getTextStyle(AppTypo.caption12B, AppColors.grey900)),
                SizedBox(width: 4.w),
                Text(formatTimeAgo(context, post.created_at),
                    style:
                        getTextStyle(AppTypo.caption10SB, AppColors.grey400)),
              ],
            ),
            Text(post.title,
                style: getTextStyle(AppTypo.body14M, AppColors.grey900)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '조회',
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                  TextSpan(
                    text: post.view_count.toString(),
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                  TextSpan(
                    text: ' ',
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                  TextSpan(
                    text: '조회',
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                  TextSpan(
                    text: post.view_count.toString(),
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                  ),
                ],
              ),
            ),
            // if (post.imageUrls.isNotEmpty)
            //   Image.network(post.imageUrls.first, width: double.infinity),
          ],
        ),
      ),
    );
  }
}
