import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_detail_page.dart';
import 'package:picnic_lib/presentation/providers/gallery_list_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/ui/style.dart';

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
      error: (error, stackTrace) => buildErrorView(
        context,
        error: error,
        stackTrace: stackTrace,
        retryFunction: () =>
            ref.read(asyncGalleryListProvider.notifier).build(),
      ),
    );
  }

  Widget _buildData(List<GalleryModel> galleryList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).label_celeb_gallery,
              style: getTextStyle(
                AppTypo.title18B,
                AppColors.grey900,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView.separated(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: galleryList.length,
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 16,
                );
              },
              itemBuilder: (context, index) {
                final gallery = galleryList[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref
                        .read(navigationInfoProvider.notifier)
                        .setPicCurrentPage(GalleryDetailPage(
                          galleryId: gallery.id,
                          galleryName: gallery.titleEn,
                        ));
                  },
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      SizedBox(
                          width: double.infinity,
                          height: 215,
                          child: PicnicCachedNetworkImage(
                            imageUrl: gallery.cover ?? '',
                            width: 361,
                            height: 215,
                            fit: BoxFit.cover,
                          )),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: SizedBox(
                          height: 30,
                          child: Text(
                            gallery.titleEn,
                            style: getTextStyle(
                              AppTypo.title18B,
                              AppColors.grey00,
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
