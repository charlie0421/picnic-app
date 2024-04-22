import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/components/library/library_list.dart';
import 'package:prame_app/components/loading_view.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/providers/library_list_provider.dart';
import 'package:prame_app/ui/style.dart';

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
      child: widget.article.images != null
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
                        imageUrl: widget.article.images![index].image,
                        fit: BoxFit.cover,
                      ),
                      _buildBookmark(widget.article, index),
                    ],
                  ),
                );
              },
              itemCount: widget.article.images!.length,
              itemWidth: 300.w,
              itemHeight: 300.h,
              pagination: const SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey, activeColor: Constants.mainColor),
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
      child: article.images![index].bookmarkUsers!.isNotEmpty
          ? IconButton(
              icon: const Icon(
                Icons.bookmark,
                color: Constants.mainColor,
              ),
              onPressed: () {},
            )
          : IconButton(
              icon: const Icon(
                Icons.bookmark_border,
                color: Constants.mainColor,
              ),
              onPressed: () {
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    useRootNavigator: true,
                    useSafeArea: true,
                    builder: (BuildContext context) =>
                        AlbumList(imageId: article.images![index].id));
              }),
    );
  }
}
