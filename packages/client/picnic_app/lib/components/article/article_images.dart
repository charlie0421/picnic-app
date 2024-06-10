import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/library/library_list.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/util.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              widget.article.article_image![index].image ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              buildPlaceholderImage(),
                        ),
                        _buildBookmark(widget.article, index),
                      ],
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

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  FullScreenImageViewer({required this.imageUrl});

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _controller = TransformationController();
  final double minScale = 1.0;
  final double maxScale = 4.0;

  Size? imageSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: MediaQuery.of(context).padding,
        decoration: const BoxDecoration(gradient: commonGradient),
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onDoubleTapDown: (details) => _handleDoubleTap(details),
                child: InteractiveViewer(
                  transformationController: _controller,
                  panEnabled: true,
                  // Disable panning
                  minScale: minScale,
                  maxScale: maxScale,
                  child: Hero(
                    tag: 'imageHero${widget.imageUrl}',
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      imageBuilder: (context, imageProvider) {
                        return Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (frame == null) {
                              return child; // Placeholder
                            } else {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final RenderBox box =
                                    context.findRenderObject() as RenderBox;
                                setState(() {
                                  imageSize = box.size; // 이미지 사이즈 업데이트
                                });
                                print('Image size: $imageSize'); // 디버그 출력
                              });
                              return child;
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 40,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap(TapDownDetails details) {
    final position = details.localPosition;
    final screenSize = MediaQuery.of(context).size;
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final currentMatrix = _controller.value.clone();

    double newScale;
    if (currentScale < 2.0) {
      newScale = 2.0;
    } else if (currentScale < 3.0) {
      newScale = 3.0;
    } else if (currentScale < 4.0) {
      newScale = 4.0;
    } else {
      newScale = 1.0; // Reset to original scale if already at max scale
    }

    vector.Vector4 focalPoint =
        vector.Vector4(position.dx, position.dy, 0.0, 1.0);
    vector.Vector4 transformedFocalPoint =
        currentMatrix.transformed(focalPoint);

    final matrix = Matrix4.identity()
      ..translate(transformedFocalPoint.x - position.dx * newScale,
          transformedFocalPoint.y - position.dy * newScale)
      ..scale(newScale);

    setState(() {
      _controller.value = matrix;
    });
  }
}
