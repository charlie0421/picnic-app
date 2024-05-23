import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/library/library_list.dart';
import 'package:picnic_app/models/prame/article.dart';

import '../../constants.dart';

class ArticleImages extends ConsumerStatefulWidget {
  ArticleModel article;

  ArticleImages({super.key, required this.article});

  @override
  ConsumerState<ArticleImages> createState() => _ArticleImagesState();
}

class _ArticleImagesState extends ConsumerState<ArticleImages> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: widget.article.article_image != null
          ? Swiper(
              itemBuilder: (BuildContext context, int index) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            widget.article.article_image![index].image ?? '',
                        fit: BoxFit.fitHeight,
                      ),
                      _buildBookmark(widget.article, index),
                    ],
                  ),
                );
              },
              itemCount: widget.article.article_image!.length,
              pagination: const SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey, activeColor: Constants.fanMainColor),
              ),
            )
          : SizedBox(
              width: 300.w,
              height: 300.h,
            ),
    );
  }

  Positioned _buildBookmark(ArticleModel article, int index) {
    return Positioned(
      top: 5,
      right: 5,
      child: article.article_image![index].article_image_user!.isNotEmpty
          ? IconButton(
              icon: const Icon(
                Icons.bookmark,
                color: Constants.fanMainColor,
              ),
              onPressed: () {},
            )
          : IconButton(
              icon: const Icon(
                Icons.bookmark_border,
                color: Constants.fanMainColor,
              ),
              onPressed: () {
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    useRootNavigator: true,
                    useSafeArea: true,
                    builder: (BuildContext context) =>
                        AlbumList(imageId: article.article_image![index].id));
              }),
    );
  }
}
