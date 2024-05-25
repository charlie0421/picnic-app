import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/fan/gallery.dart';
import 'package:picnic_app/pages/fan/gallery_detail_page.dart';
import 'package:picnic_app/providers/gallery_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  );

  @override
  Widget build(BuildContext context) {
    final asyncGalleryListState = ref.watch(asyncGalleryListProvider);

    return asyncGalleryListState.when(
      data: (galleryList) {
        return _buildData(galleryList);
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stackTrace) => ErrorView(
        context,
        error: error,
        stackTrace: stackTrace,
        retryFunction: () =>
            ref.read(asyncGalleryListProvider.notifier).build(),
      ),
    );
  }

  _buildData(List<GalleryModel> galleryList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              Intl.message('label_celeb_gallery'),
              style: getTextStyle(
                context,
                AppTypo.UI24B,
                AppColors.Gray900,
              ),
            ),
          ),
          SizedBox(
            height: 20.h,
          ),
          Expanded(
            child: ListView.separated(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: galleryList.length,
              separatorBuilder: (context, index) {
                return SizedBox(
                  height: 16.h,
                );
              },
              itemBuilder: (context, index) {
                final gallery = galleryList[index];
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(navigationInfoProvider.notifier)
                        .setCurrentPage(GalleryDetailPage(
                          galleryId: gallery.id,
                          galleryName: gallery.title_en,
                        ));
                  },
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      SizedBox(
                          width: double.infinity,
                          height: 215.h,
                          child: CachedNetworkImage(
                            imageUrl: gallery.cover ?? '',
                            width: 361.w,
                            height: 215.h,
                            fit: BoxFit.cover,
                          )),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: SizedBox(
                          height: 30.h,
                          child: Text(
                            gallery.title_en,
                            style: getTextStyle(
                              context,
                              AppTypo.UI20B,
                              AppColors.Gray00,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
