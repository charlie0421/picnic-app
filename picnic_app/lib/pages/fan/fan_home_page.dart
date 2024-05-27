import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/no_bookmark_celeb.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/fan/celeb.dart';
import 'package:picnic_app/models/fan/gallery.dart';
import 'package:picnic_app/pages/fan/gallery_detail_page.dart';
import 'package:picnic_app/pages/fan/landing_page.dart';
import 'package:picnic_app/providers/celeb_banner_list_provider.dart';
import 'package:picnic_app/providers/gallery_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/screens/fan/draw_image_screen.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

import '../../components/celeb_list_item.dart';
import '../../providers/celeb_list_provider.dart';

class FanHomePage extends ConsumerStatefulWidget {
  const FanHomePage({super.key});

  @override
  ConsumerState<FanHomePage> createState() => _FanHomePageState();
}

class _FanHomePageState extends ConsumerState<FanHomePage> {
  @override
  Widget build(BuildContext context) {
    final asyncMyCelebListState = ref.watch(asyncMyCelebListProvider);
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final selectedCelebState = ref.watch(selectedCelebProvider);
    final selectedCelebNotifier = ref.read(selectedCelebProvider.notifier);

    return asyncMyCelebListState.when(
        data: (data) {
          if (selectedCelebState == null) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              selectedCelebNotifier
                  .setSelectedCeleb(asyncCelebListState.value?.first);

              ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
            });
            return const SizedBox.shrink();
          }

          final celebBannerListState = ref.watch(
              asyncCelebBannerListProvider(celebId: selectedCelebState.id));
          final asyncGalleryListState =
              ref.watch(asyncCelebGalleryListProvider(selectedCelebState.id));
          return Column(
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                            imageUrl: selectedCelebState.thumbnail ?? '',
                            width: 38,
                            height: 38),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedCelebState.name_ko,
                        style: getTextStyle(
                            context, AppTypo.BODY16B, AppColors.Gray900),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _buildSelectCelebBottomSheet(),
                        child: SvgPicture.asset(
                          'assets/icons/dropdown.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  )),
              Padding(
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
                          Navigator.pushNamed(
                              context, DrawImageScreen.routeName);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(Intl.message('text_ads_random'),
                                style: getTextStyle(context, AppTypo.TITLE18M,
                                    AppColors.Gray900)),
                            Text('01:00:00',
                                style: getTextStyle(context, AppTypo.TITLE18M,
                                    AppColors.Gray900)),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    imageUrl: data[index].thumbnail ?? '',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                            itemCount: data.length,
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
                              celebId: selectedCelebState.id));
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
                        style: getTextStyle(
                            context, AppTypo.TITLE18B, AppColors.Gray900),
                      ),
                    ),
                    const SizedBox(height: 20),
                    asyncGalleryListState.when(
                        data: (data) => _buildGalleryList(data),
                        error: (error, stackTrace) {
                          return ErrorView(
                            context,
                            error: error,
                            stackTrace: stackTrace,
                            retryFunction: () => ref
                                .read(asyncGalleryListProvider.notifier)
                                .build(),
                          );
                        },
                        loading: () => buildLoadingOverlay()),
                  ],
                )),
              ),
            ],
          );
        },
        loading: () => buildLoadingOverlay(),
        error: (error, stackTrace) {
          return ErrorView(
            context,
            error: error,
            stackTrace: stackTrace,
            retryFunction: () {
              ref.refresh(asyncMyCelebListProvider);
            },
          );
        });
  }

  Widget _buildGalleryList(List<GalleryModel> data) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 215,
      width: double.infinity,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentPage(GalleryDetailPage(
                      galleryId: data[index].id,
                      galleryName: data[index].title_en,
                    ));
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 215,
                    width: 215,
                    child: CachedNetworkImage(
                      imageUrl: data[index].cover ?? '',
                      fit: BoxFit.cover,
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
                          data[index].title_en,
                          style: getTextStyle(
                              context, AppTypo.BODY16B, AppColors.Gray00),
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
          itemCount: data.length),
    );
  }

  void _buildSelectCelebBottomSheet() {
    final asyncMyCelebListState = ref.watch(asyncMyCelebListProvider);
    final selectedCelebState = ref.watch(selectedCelebProvider);

    logger.w('asyncMyCelebListState: $asyncMyCelebListState');

    showModalBottomSheet(
        context: context,
        useSafeArea: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (BuildContext context) {
          return SingleChildScrollView(
              child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                Intl.message('label_moveto_celeb_gallery'),
                style:
                    getTextStyle(context, AppTypo.TITLE18B, AppColors.Gray900),
              ),
              Text(
                Intl.message('text_moveto_celeb_gallery'),
                style:
                    getTextStyle(context, AppTypo.BODY16R, AppColors.Gray900),
              ),
              const SizedBox(height: 16),
              if (selectedCelebState != null)
                ...asyncMyCelebListState.when(
                    data: (data) {
                      logger.w('data: $data');
                      if (data == null) {
                        return [const SizedBox()];
                      }
                      logger.w('data.items.length: ${data.length}');
                      return data.isNotEmpty
                          ? _buildSearchList(context, data, selectedCelebState)
                          : [const NoBookmarkCeleb()];
                    },
                    loading: () => [buildLoadingOverlay()],
                    error: (error, stackTrace) => [
                          ErrorView(
                            context,
                            retryFunction: () {
                              ref.refresh(asyncMyCelebListProvider);
                            },
                            error: error,
                            stackTrace: stackTrace,
                          )
                        ]),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                  onTap: () {
                    _buildFloating(context);
                  },
                  child: Text(Intl.message('label_find_celeb'))),
              const SizedBox(
                height: 40,
              ),
            ],
          ));
        });
  }

  List<Widget> _buildSearchList(
      BuildContext context, List<CelebModel> data, CelebModel selectedCeleb) {
    logger.w('selectedCeleb: $selectedCeleb');
    logger.w('selectedCeleb: ${selectedCeleb.name_ko}');
    logger.w('CelebListModel: ${data.length}');

    data.removeWhere((item) => item.id == selectedCeleb.id);
    data.insert(0, selectedCeleb);
    return selectedCeleb != null
        ? data
            .map((e) => Container(
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: e.id == selectedCeleb.id
                      ? const Color(0xFF47E89B)
                      : AppColors.Gray00,
                  border: Border.all(
                    color: AppColors.Gray100,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    ref
                        .read(selectedCelebProvider.notifier)
                        .setSelectedCeleb(e);
                    ref.read(asyncCelebBannerListProvider(celebId: e.id));
                    Navigator.pop(context);
                  },
                  child: CelebListItem(
                      item: e,
                      type: 'my',
                      showBookmark: e.id != selectedCeleb.id,
                      enableBookmark: false),
                )))
            .toList()
        : [const NoBookmarkCeleb()];
  }

  void _buildFloating(context) {
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return const LandingPage();
        });
  }
}
