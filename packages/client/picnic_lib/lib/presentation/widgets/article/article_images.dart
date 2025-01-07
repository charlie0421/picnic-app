import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/library/library_list.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class ArticleImages extends ConsumerStatefulWidget {
  final ArticleModel article;

  const ArticleImages({super.key, required this.article});

  @override
  ConsumerState<ArticleImages> createState() => _ArticleImagesState();
}

class _ArticleImagesState extends ConsumerState<ArticleImages> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: widget.article.articleImage != null
          ? Swiper(
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showFullScreenImage(
                      context, widget.article.articleImage![index].image ?? ''),
                  child: Hero(
                    tag: 'imageHero${widget.article.articleImage![index].id}',
                    child: Stack(
                      children: [
                        Container(
                          alignment: Alignment.topCenter,
                          child: PicnicCachedNetworkImage(
                            imageUrl:
                                widget.article.articleImage![index].image ?? '',
                            fit: BoxFit.fitHeight,
                            height: 600,
                          ),
                        ),
                        Positioned(
                            top: 10.h,
                            right: 10.cw,
                            child: _buildBookmark(widget.article, index))
                      ],
                    ),
                  ),
                );
              },
              itemCount: widget.article.articleImage!.length,
              pagination: SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey, activeColor: picMainColor),
              ),
            )
          : SizedBox(width: 300.cw, height: 300),
    );
  }

  // itemBuilder: (BuildContext context, int index) {
  //                GestureDetector(
  //                 behavior: HitTestBehavior.opaque,
  //                 onTap: () => _showFullScreenImage(context,
  //                     widget.article.articleImage![index].image ?? ''),
  //                 child: Stack(
  //                   children: [
  //                     Hero(
  //                       tag:
  //                           'imageHero${widget.article.articleImage![index].id}',
  //                       child: PicnicCachedNetworkImage(
  //                         Key: widget.article.articleImage![index].image ?? '',
  //                         fit: BoxFit.cover,
  //                         height:600,
  //                       ),
  //                     ),
  //                     _buildBookmark(widget.article, index),
  //                   ],
  //                 ),
  //               );
  // },
  // itemCount: widget.article.articleImage!.length,
  // pagination: const SwiperPagination(
  //   builder: DotSwiperPaginationBuilder(
  //       color: Colors.grey, activeColor: picMainColor),
  // ),
  // )
  // : SizedBox(width: 300.cw, height:300),
  // );
  // }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // set to false
        pageBuilder: (_, __, ___) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildBookmark(ArticleModel article, int index) {
    return article.articleImage![index].articleImageUser!.isNotEmpty
        ? IconButton(
            icon: Icon(
              Icons.bookmark,
              color: picMainColor,
            ),
            onPressed: () {},
          )
        : IconButton(
            icon: Icon(
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
                      AlbumList(imageId: article.articleImage![index].id));
            });
  }
}

class FullScreenImageViewer extends ConsumerStatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  ConsumerState<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends ConsumerState<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;
  final double minScale = 1.0;
  final double maxScale = 4.0;

  Size? imageSize;

  @override
  void initState() {
    super.initState();

    _controller = TransformationController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 300), // Define the duration of the animation
    );

    _animationController.addListener(() {
      _controller.value = _animation.value; // Update the transformation value
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: ref.watch(globalMediaQueryProvider).padding,
        decoration: BoxDecoration(gradient: commonGradient),
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) => _handleDoubleTap(details),
                child: InteractiveViewer(
                  transformationController: _controller,
                  panEnabled: true,
                  // Disable panning
                  minScale: minScale,
                  maxScale: maxScale,
                  child: Container(
                    width: getPlatformScreenSize(context).width,
                    height: getPlatformScreenSize(context).height,
                    alignment: Alignment.center,
                    child: PicnicCachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      width: getPlatformScreenSize(context).width,
                      // imageBuilder: (context, imageProvider) {
                      //   return Image(
                      //     image: imageProvider,
                      //     fit: BoxFit.cover,
                      //     frameBuilder:
                      //         (context, child, frame, wasSynchronouslyLoaded) {
                      //       if (frame == null) {
                      //         return child; // Placeholder
                      //       } else {
                      //         WidgetsBinding.instance.addPostFrameCallback((_) {
                      //           final RenderBox box =
                      //               context.findRenderObject() as RenderBox;
                      //           setState(() {
                      //             imageSize = box.size; // 이미지 사이즈 업데이트
                      //           });
                      //         });
                      //         return child;
                      //       }
                      //     },
                      //   );
                      // },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
    final currentScale = _controller.value.getMaxScaleOnAxis();
    double targetScale;

    if (currentScale < 2.0) {
      targetScale = 2.0;
    } else if (currentScale < 3.0) {
      targetScale = 3.0;
    } else if (currentScale < 4.0) {
      targetScale = 4.0;
    } else {
      targetScale = 1.0;
    }

    final offset = _controller.toScene(position);
    final zoomed = Matrix4.identity()
      ..translate(
          -offset.dx * (targetScale - 1), -offset.dy * (targetScale - 1))
      ..scale(targetScale);

    _animation = Matrix4Tween(
      begin: _controller.value,
      end: zoomed,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0.0);
  }
}
