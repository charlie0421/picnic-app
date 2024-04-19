import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/best_comment.dart';
import 'package:prame_app/components/article/comment/comment.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/providers/article_list_provider.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

class ArticleList extends ConsumerWidget {
  final int galleryId;
  const ArticleList(this.galleryId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(asyncArticleListProvider(galleryId)).when(
          data: (pagingController) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PagedListView<int, ArticleModel>(
                pagingController: pagingController,
                scrollDirection: Axis.vertical,
                builderDelegate: PagedChildBuilderDelegate<ArticleModel>(
                  firstPageErrorIndicatorBuilder: (context) {
                    return ErrorView(context,
                        error: pagingController.error.toString(),
                        retryFunction: () => pagingController.refresh(),
                        stackTrace: pagingController.error.stackTrace);
                  },
                  firstPageProgressIndicatorBuilder: (context) {
                    return buildLoadingOverlay();
                  },
                  noItemsFoundIndicatorBuilder: (context) {
                    return ErrorView(context,
                        error: 'No Items Found', stackTrace: null);
                  },
                  itemBuilder: (context, item, index) {
                    final article = item;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 30.h,
                            child: Row(
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    article.titleKo,
                                    style: getTextStyle(
                                      AppTypo.UI24B,
                                      AppColors.Gray900,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10.w,
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(article.createdAt),
                                    style: getTextStyle(
                                      AppTypo.UI14B,
                                      AppColors.Gray900,
                                    ).copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10.h,
                          ),
                          GestureDetector(
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(1),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 7,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              height: 400.h,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: article.images != null
                                        ? Swiper(
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(5),
                                                  topRight: Radius.circular(5),
                                                ),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl: article
                                                          .images![index].image,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Positioned(
                                                      top: 5,
                                                      right: 5,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.bookmarks,
                                                          color: Constants
                                                              .mainColor,
                                                        ),
                                                        onPressed: () {},
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            itemCount: article.images!.length,
                                            itemWidth: 300.w,
                                            itemHeight: 300.h,
                                            pagination: const SwiperPagination(
                                              builder:
                                                  DotSwiperPaginationBuilder(
                                                      color: Colors.grey,
                                                      activeColor:
                                                          Constants.mainColor),
                                            ),
                                          )
                                        : SizedBox(
                                            width: 300.w,
                                            height: 300.h,
                                          ),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        article.content,
                                        style: getTextStyle(
                                          AppTypo.UI14M,
                                          AppColors.Gray900,
                                        ),
                                      )),
                                  GestureDetector(
                                      onTap: () => buildCommentBottomSheet(
                                          context, article,
                                          commentId: item.mostLikedComment?.id),
                                      child: BestComment(article: article)),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () => buildCommentBottomSheet(
                                          context, article),
                                      child: Text(
                                          '${Intl.message('label_read_more_comment')} ${ref.watch(commentCountProvider(article.id)).value != 0 ? ref.watch(commentCountProvider(article.id)).value : article.commentCount}',
                                          style: getTextStyle(
                                            AppTypo.UI14B,
                                            AppColors.Gray900,
                                          )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )),
          loading: () => buildLoadingOverlay(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  void buildCommentBottomSheet(BuildContext context, ArticleModel articleModel,
      {int? commentId}) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          return SafeArea(
              child: Comment(articleModel: articleModel, commentId: commentId));
        });
  }
}
