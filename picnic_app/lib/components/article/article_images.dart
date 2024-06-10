import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/library/library_list.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/util.dart';

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
                return GestureDetector(
                  onTap: () => _showFullScreenImage(context,
                      widget.article.article_image![index].image ?? ''),
                  child: Hero(
                    tag: 'imageHero${widget.article.article_image![index].id}',
                    child: CachedNetworkImage(
                      imageUrl:
                          widget.article.article_image![index].image ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => buildPlaceholderImage(),
                    ),
                  ),
                );
              },
              itemCount: widget.article.article_image!.length,
              pagination: SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey, activeColor: picMainColor),
              ),
            )
          : SizedBox(width: 300.w, height: 300.h),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // set to false
        pageBuilder: (_, __, ___) => FullScreenImageViewer(imageUrl: imageUrl),
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
                color: picMainColor,
              ),
              onPressed: () {},
            )
          : IconButton(
              icon: const Icon(
                Icons.bookmark_border,
                color: picMainColor,
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

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: 'imageHero$imageUrl',
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => buildPlaceholderImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
