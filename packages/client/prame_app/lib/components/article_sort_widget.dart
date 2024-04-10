import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/providers/article_list_provider.dart';
import 'package:prame_app/ui/style.dart';

class ArticleSortWidget extends ConsumerStatefulWidget {
  final int galleryId;
  const ArticleSortWidget({
    super.key,
    required this.galleryId,
  });

  @override
  ConsumerState<ArticleSortWidget> createState() => _ArticleSortWidgetState();
}

class _ArticleSortWidgetState extends ConsumerState<ArticleSortWidget> {
  @override
  Widget build(BuildContext context) {
    final sortOptionState = ref.watch(sortOptionProvider);
    final sortOptionNotifier = ref.read(sortOptionProvider.notifier);

    final asyncArticleListNotifier = ref.read(asyncArticleListProvider(
            1, 10, 'article.createdAt', 'DESC',
            galleryId: widget.galleryId)
        .notifier);
    logger.i('sortOptionState: $sortOptionState');
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SafeArea(
                child: Container(
                  height: 224.h,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('정렬 방식 선택',
                              style: getTextStyle(
                                  AppTypo.UI16B, AppColors.Gray900)),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: SvgPicture.asset(
                                'assets/icons/icon/close_s.svg',
                                width: 18.w,
                                height: 18.h,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.Gray800,
                                  BlendMode.srcIn,
                                )),
                          ),
                        ],
                      ),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 3,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: AppColors.Gray100,
                        ),
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return InkWell(
                                onTap: () {
                                  asyncArticleListNotifier.fetch(
                                      1, 10, 'article.created_at', 'DESC',
                                      galleryId: widget.galleryId);
                                  sortOptionNotifier
                                      .setSortOption('article.created_at');
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  height: 56.h,
                                  child: Row(
                                    children: [
                                      sortOptionState == 'article.created_at'
                                          ? SvgPicture.asset(
                                              'assets/icons/icon/check_green.svg',
                                              width: 18.w,
                                              height: 18.h,
                                            )
                                          : SizedBox(width: 18.w),
                                      SizedBox(width: 8.w),
                                      Text('최신 등록순',
                                          style: sortOptionState ==
                                                  'article.created_at'
                                              ? getTextStyle(AppTypo.UI16B,
                                                  AppColors.GP400)
                                              : getTextStyle(AppTypo.UI16M,
                                                  AppColors.Gray900)),
                                    ],
                                  ),
                                ),
                              );
                            case 1:
                              return InkWell(
                                onTap: () {
                                  asyncArticleListNotifier.fetch(
                                      1, 10, 'article.viewCount', 'ASC',
                                      galleryId: widget.galleryId);
                                  sortOptionNotifier
                                      .setSortOption('article.viewCount');

                                  Navigator.pop(context);
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  height: 56.h,
                                  child: Row(
                                    children: [
                                      sortOptionState == 'article.viewCount'
                                          ? SvgPicture.asset(
                                              'assets/icons/icon/check_green.svg',
                                              width: 18.w,
                                              height: 18.h,
                                            )
                                          : SizedBox(width: 18.w),
                                      SizedBox(width: 8.w),
                                      Text('조회수',
                                          style: sortOptionState ==
                                                  'article.viewCount'
                                              ? getTextStyle(AppTypo.UI16B,
                                                  AppColors.GP400)
                                              : getTextStyle(AppTypo.UI16M,
                                                  AppColors.Gray900)),
                                    ],
                                  ),
                                ),
                              );
                            case 2:
                              return InkWell(
                                onTap: () {
                                  asyncArticleListNotifier.fetch(
                                      1, 10, 'article.point', 'DESC',
                                      galleryId: widget.galleryId);
                                  sortOptionNotifier
                                      .setSortOption('article.point');

                                  Navigator.pop(context);
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  height: 56.h,
                                  child: Row(
                                    children: [
                                      sortOptionState == 'article.comment'
                                          ? SvgPicture.asset(
                                              'assets/icons/icon/check_green.svg',
                                              width: 18.w,
                                              height: 18.h,
                                            )
                                          : SizedBox(width: 18.w),
                                      SizedBox(width: 8.w),
                                      Text('댓글 순',
                                          style:
                                              sortOptionState == 'article.point'
                                                  ? getTextStyle(AppTypo.UI16B,
                                                      AppColors.GP400)
                                                  : getTextStyle(AppTypo.UI16M,
                                                      AppColors.Gray900)),
                                    ],
                                  ),
                                ),
                              );
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      child: Container(
        width: 102.w,
        height: 30.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8).r,
          border: Border.all(color: AppColors.Gray100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4).w,
        margin: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  sortOptionState == 'article.created_at'
                      ? '최신 등록순'
                      : sortOptionState == 'article.viewCount'
                          ? '조회순'
                          : '댓글순',
                  style: getTextStyle(AppTypo.UI14M, AppColors.Gray600),
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/line_arrow/state=down.svg',
              width: 18.w,
              height: 18.h,
            )
          ],
        ),
      ),
    );
  }
}
