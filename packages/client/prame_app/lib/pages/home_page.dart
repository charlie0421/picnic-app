import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/error.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/celeb.dart';
import 'package:prame_app/models/gallery.dart';
import 'package:prame_app/providers/celeb_banner_list_provider.dart';
import 'package:prame_app/providers/gallery_list_provider.dart';
import 'package:prame_app/providers/selected_celeb_provider.dart';
import 'package:prame_app/screens/draw_image_screen.dart';
import 'package:prame_app/screens/gallery_detail_screen.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

class HomePage extends ConsumerWidget {
  CelebModel celebModel;
  HomePage({super.key, required this.celebModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCelebState = ref.watch(selectedCelebProvider);
    celebModel = selectedCelebState ?? celebModel;
    final celebBannerListState =
        ref.watch(asyncCelebBannerListProvider(celebId: celebModel.id));
    final asyncGalleryListState =
        ref.watch(asyncGalleryListProvider(celebId: celebModel.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.Gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            height: 80,
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, DrawImageScreen.routeName);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(Intl.message('text_ads_random'),
                      style: getTextStyle(context, AppTypo.UI18M, AppColors.Gray900)),
                  Text('01:00:00',
                      style: getTextStyle(context, AppTypo.UI18M, AppColors.Gray900)),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          celebBannerListState.when(
            data: (data) {
              return SizedBox(
                height: 236,
                width: MediaQuery.of(context).size.width - 32,
                child: Swiper(
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: data.items[index].thumbnail,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  itemCount: data.items.length,
                  pagination: const SwiperPagination(),
                  autoplay: true,
                ),
              );
            },
            loading: () => buildLoadingOverlay(),
            error: (error, stackTrace) => ErrorView(
              context,
              retryFunction: () {
                ref.refresh(asyncCelebBannerListProvider(
                    celebId: selectedCelebState?.id ?? 1));
              },
              error: error,
              stackTrace: stackTrace,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              Intl.message('label_celeb_gallery'),
              style: getTextStyle(context, AppTypo.UI24B, AppColors.Gray900),
            ),
          ),
          const SizedBox(height: 20),
          asyncGalleryListState.when(
              data: _buildGalleryList,
              error: (error, stackTrace) {
                return ErrorView(
                  context,
                  error: error,
                  stackTrace: stackTrace,
                  retryFunction: () => ref
                      .read(asyncGalleryListProvider(celebId: 0).notifier)
                      .build(celebId: 0),
                );
              },
              loading: () => buildLoadingOverlay()),
        ],
      )),
    );
  }

  Widget _buildGalleryList(GalleryListModel data) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 215,
      width: double.infinity,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, GalleryDetailScreen.routeName,
                    arguments: GalleryDetailScreenArguments(
                        galleryId: data.items[index].id,
                        galleryName: data.items[index].titleKo));
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 215,
                    width: 215,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: data.items[index].cover,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      color: AppColors.Gray900.withOpacity(0.5),
                      child: Center(
                        child: Text(
                          data.items[index].titleKo,
                          style: getTextStyle(context, AppTypo.UI16B, AppColors.Gray00),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const VerticalDivider(
                width: 20,
                thickness: 0,
                color: AppColors.Gray00,
              ),
          itemCount: data.items.length),
    );
  }
}
