import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class PostList extends ConsumerWidget {
  const PostList(this.artistId, {super.key});

  final int? artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postListAsyncValue = ref.watch(postListProvider);
    logger.i('postListAsyncValue: $postListAsyncValue');

    return Column(
      children: [
        postListAsyncValue.when(
          data: (data) => data == null || data.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 80),
                      Text('게시글을 작성해 주세요!',
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.grey500)),
                      const SizedBox(height: 54),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: AppColors.primary500,
                            backgroundColor: AppColors.grey00,
                            textStyle: getTextStyle(AppTypo.body14B),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(
                                color: AppColors.primary500,
                                width: 1,
                              ),
                            ),
                          ),
                          onPressed: () {},
                          child: Text('게시글 작성하기',
                              style: getTextStyle(
                                  AppTypo.body14B, AppColors.primary500)))
                    ],
                  ))
              : SizedBox(
                  height: 288,
                  child: Column(children: [
                    ...List.generate(
                        3, (index) => PostListItem(post: data[index])),
                    ElevatedButton(
                        onPressed: () {}, child: const Text('My Artist 게시판 보기'))
                  ]),
                ),
          error: (err, stack) =>
              ErrorView(context, error: err, stackTrace: stack),
          loading: () => buildLoadingOverlay(),
        ),
      ],
    );
  }
}

class PostListItem extends ConsumerWidget {
  final PostModel post;

  const PostListItem({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.i('post: $post');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16),
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
              Text(post.user_id.substring(0, 8),
                  style: getTextStyle(AppTypo.caption12B, AppColors.grey900)),
              SizedBox(width: 12.w),
              Text(formatTimeAgo(context, post.created_at),
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey400)),
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
    );
  }
}

final postListProvider = FutureProvider((ref) async {
  try {
    final response = await supabase
        .schema('community')
        .from('posts')
        .select('*, boards!inner(*)')
        .eq('boards.artist_id', 1);
    logger.d('response: $response');
    return response.map((data) => PostModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
});
