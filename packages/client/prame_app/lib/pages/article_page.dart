import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/providers/article_list_provider.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

import '../components/article_sort_widget.dart';

class ArticlePage extends ConsumerStatefulWidget {
  final int galleryId;
  const ArticlePage({super.key, required this.galleryId});

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  );

  @override
  Widget build(BuildContext context) {
    final asyncArticleListState = ref.watch(asyncArticleListProvider(
        1, 10, 'createdAt', 'DESC',
        galleryId: widget.galleryId));

    return asyncArticleListState.when(
      data: (data) {
        return _buildData(data);
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stackTrace) => ErrorView(context,
          error: error,
          stackTrace: stackTrace,
          retryFunction: () => ref.read(asyncArticleListProvider(
                  1, 10, 'createdAt', 'DESC',
                  galleryId: widget.galleryId)
              .notifier)),
    );
  }

  _buildData(ArticleListModel articleList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ArticleSortWidget(
              galleryId: widget.galleryId,
            ),
          ),
          SizedBox(
            height: 20.h,
          ),
          Expanded(
            child: ListView.separated(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: articleList.items.length,
              separatorBuilder: (context, index) {
                return SizedBox(
                  height: 16.h,
                );
              },
              itemBuilder: (context, index) {
                final article = articleList.items[index];
                return Column(
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
                              article.createdAt.toIso8601String(),
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
                              child: Swiper(
                                itemBuilder: (BuildContext context, int index) {
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: article.images[index].image,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                                itemCount: article.images.length,
                                itemWidth: 300.w,
                                itemHeight: 300.h,
                                pagination: const SwiperPagination(
                                  builder: DotSwiperPaginationBuilder(
                                    color: Colors.grey,
                                    activeColor: Colors.red,
                                  ),
                                ),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
