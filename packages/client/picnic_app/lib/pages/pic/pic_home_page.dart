import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/celeb_list_item.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/no_bookmark_celeb.dart';
import 'package:picnic_app/components/vote/list/pic_vote_info_card.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/artist_vote.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/models/pic/gallery.dart';
import 'package:picnic_app/pages/pic/gallery_detail_page.dart';
import 'package:picnic_app/pages/pic/landing_page.dart';
import 'package:picnic_app/providers/banner_list_provider.dart';
import 'package:picnic_app/providers/gallery_list_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

import '../../providers/celeb_list_provider.dart';

class PicHomePage extends ConsumerStatefulWidget {
  const PicHomePage({super.key});

  @override
  ConsumerState<PicHomePage> createState() => _PicHomePageState();
}

class _PicHomePageState extends ConsumerState<PicHomePage> {
  final PagingController<int, ArtistVoteModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', "DESC").then((newItems) {
        final isLastPage =
            newItems.meta.currentPage == newItems.meta.totalPages;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems.items);
        } else {
          final nextPageKey = newItems.meta.currentPage + 1;
          _pagingController.appendPage(newItems.items, nextPageKey);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    final selectedCelebState = ref.watch(selectedCelebProvider);
    final selectedCelebNotifier = ref.read(selectedCelebProvider.notifier);

    return asyncCelebListState.when(
        data: (data) {
          if (data == null) {
            return const SizedBox.shrink();
          }
          // if (selectedCelebState == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            selectedCelebNotifier.setSelectedCeleb(data.first);
          });

          // ref.read(asyncMyCelebListProvider.notifier).fetchMyCelebList();
          // return const SizedBox.shrink();
          // }

          final asyncBannerListState =
              ref.watch(asyncBannerListProvider(location: 'pic_home'));
          final asyncGalleryListState =
              ref.watch(asyncCelebGalleryListProvider(1));
          return ListView(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                height: 44,
                padding: EdgeInsets.only(left: 16.cw, top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24).r,
                      child: PicnicCachedNetworkImage(
                        imageUrl: selectedCelebState?.thumbnail ?? '',
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedCelebState?.name_ko ?? '',
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _buildSelectCelebBottomSheet(),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_down_style=line.svg',
                        width: 20.cw,
                        height: 20,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  asyncBannerListState.when(
                    data: (data) {
                      final width = getPlatformScreenSize(context).width;
                      final height = width * .5;

                      logger.w('data: $data');

                      return SizedBox(
                        width: width,
                        height: height + 30,
                        child: Swiper(
                          itemBuilder: (BuildContext context, int index) {
                            String title =
                                getLocaleTextFromJson(data[index].title);
                            return Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: width,
                                  height: height,
                                  child: PicnicCachedNetworkImage(
                                      imageUrl: data[index].thumbnail,
                                      width: width.toInt(),
                                      height: height.toInt(),
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 30,
                                  child: Container(
                                    width: getPlatformScreenSize(context).width,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8.cw),
                                    color: Colors.black.withOpacity(0.5),
                                    child: Text(
                                      title,
                                      style: getTextStyle(
                                              AppTypo.body14R, Colors.white)
                                          .copyWith(
                                              overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                          itemCount: data.length,
                          containerHeight: height,
                          itemHeight: height,
                          autoplay: true,
                          pagination: const SwiperPagination(
                              builder: DotSwiperPaginationBuilder(
                                  size: 8,
                                  color: AppColors.grey200,
                                  activeColor: AppColors.grey500)),
                          layout: SwiperLayout.DEFAULT,
                        ),
                      );
                    },
                    loading: () => buildLoadingOverlay(),
                    error: (error, stackTrace) => ErrorView(
                      context,
                      retryFunction: () {
                        ref.refresh(
                            asyncBannerListProvider(location: 'pic_home'));
                      },
                      error: error,
                      stackTrace: stackTrace,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 16.cw),
                    child: Text(
                      S.of(context).label_celeb_gallery,
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
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
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 16.cw),
                    child: Row(
                      children: [
                        Text(
                          S.of(context).label_celeb_ask_to_you,
                          style:
                              getTextStyle(AppTypo.title18B, AppColors.grey900),
                        ),
                        SvgPicture.asset(
                          'assets/icons/arrow_right_style=line.svg',
                          width: 8.cw,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                              AppColors.grey900, BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PagedListView<int, ArtistVoteModel>(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    pagingController: _pagingController,
                    scrollDirection: Axis.vertical,
                    builderDelegate: PagedChildBuilderDelegate<ArtistVoteModel>(
                        firstPageErrorIndicatorBuilder: (context) {
                          return ErrorView(context,
                              error: _pagingController.error.toString(),
                              retryFunction: () => _pagingController.refresh(),
                              stackTrace: _pagingController.error.stackTrace);
                        },
                        firstPageProgressIndicatorBuilder: (context) {
                          return buildLoadingOverlay();
                        },
                        noItemsFoundIndicatorBuilder: (context) =>
                            const NoItemContainer(),
                        itemBuilder: (context, item, index) => PicVoteInfoCard(
                              context: context,
                              vote: item,
                              status: VoteStatus.active,
                            )),
                  ),
                ],
              )),
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
      height: 100,
      width: double.infinity,
      padding: EdgeInsets.only(left: 16.cw),
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            String title = data[index].getTitle();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: PicnicCachedNetworkImage(
                          width: 140,
                          height: 100,
                          imageUrl: data[index].cover ?? '',
                          fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 140.cw,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r)),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(vertical: 4, horizontal: 8.cw),
                      child: Text(
                        title,
                        style: getTextStyle(AppTypo.body14R, Colors.white)
                            .copyWith(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const VerticalDivider(
                width: 20,
                thickness: 0,
                color: AppColors.grey00,
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
                S.of(context).label_moveto_celeb_gallery,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
              Text(
                S.of(context).text_moveto_celeb_gallery,
                style: getTextStyle(AppTypo.body16R, AppColors.grey900),
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _buildFloating(context);
                  },
                  child: Text(S.of(context).label_find_celeb)),
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
                margin: EdgeInsets.symmetric(horizontal: 32.cw, vertical: 4),
                padding: EdgeInsets.symmetric(horizontal: 8.cw),
                decoration: BoxDecoration(
                  color: e.id == selectedCeleb.id
                      ? const Color(0xFF47E89B)
                      : AppColors.grey00,
                  border: Border.all(
                    color: AppColors.grey100,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    ref
                        .read(selectedCelebProvider.notifier)
                        .setSelectedCeleb(e);
                    ref.read(asyncBannerListProvider(location: 'pic_home'));
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

  _fetch(int page, int limit, String sort, String order) async {
    final response = await supabase
        .from('artist_vote')
        .select('*, artist_vote_item(*)')
        .eq('category', 'pic')
        // .lt('start_at', 'now()')
        // .gt('stop_at', 'now()')
        .order('id', ascending: false)
        .order('vote_total',
            ascending: false, referencedTable: 'artist_vote_item')
        .range((page - 1) * limit, page * limit - 1)
        .limit(limit)
        .count();

    final meta = {
      'totalItems': response.count,
      'currentPage': page,
      'itemCount': response.data.length,
      'itemsPerPage': limit,
      'totalPages': response.count ~/ limit + 1,
    };

    return ArtistVoteListModel.fromJson({'items': response.data, 'meta': meta});
  }
}
