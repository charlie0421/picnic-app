import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_detail_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/gallery_list_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/celeb_list_item.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/no_bookmark_celeb.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/enums.dart';

import '../../providers/celeb_list_provider.dart';
import '../../providers/app_setting_provider.dart';

/// pic 홈 상단 배너의 종횡비.
///
/// 배너 본체와 로딩/에러 플레이스홀더가 **모두** 이 값을 쓴다. 갈라지면 데이터가
/// 도착하는 순간 배너 아래 내용이 그 차이만큼 위아래로 튄다. 예전 플레이스홀더는
/// `화면폭 * 0.5` 짜리 상자였는데 배너는 16:9(= 폭 * 0.5625)라, 크기가 맞는
/// 플레이스홀더를 넣었어도 402pt 기기에서 25px 튀었을 자리다.
const double kPicHomeBannerAspectRatio = 16 / 9;

class PicHomePage extends ConsumerStatefulWidget {
  const PicHomePage({super.key});

  @override
  ConsumerState<PicHomePage> createState() => _PicHomePageState();
}

class _PicHomePageState extends ConsumerState<PicHomePage> {
  late final PagingController<int, VoteModel> _pagingController;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, VoteModel>(
      getNextPageKey: (state) => (state.keys?.last ?? 0) + 1,
      fetchPage: _fetch,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: true,
          );
    });
  }

  Future<List<VoteModel>> _fetch(int pageKey) async {
    final setting = ref.read(appSettingProvider);
    final area = setting.area;
    logger.i('area: $area');
    try {
      final newItems = await ref.read(
        asyncVoteListProvider(
          pageKey,
          _pageSize,
          'vote.id',
          'DESC',
          area,
          votePortal: VotePortal.pic,
          status: VoteStatus.activeAndUpcoming,
          category: VoteCategory.all,
        ).future,
      );

      return newItems;
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // PIC 홈 활성 상태(루트)일 때만 타이틀 비우기
    final navState = ref.watch(navigationInfoProvider);
    final bool isPicActive = navState.portalType == PortalType.pic;
    final bool isAtRoot =
        navState.voteNavigationStack == null ||
        navState.voteNavigationStack!.length <= 1;
    if (isPicActive && isAtRoot && navState.pageTitle.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(navigationInfoProvider.notifier).setPageTitle(pageTitle: '');
        }
      });
    }

    final asyncCelebListState = ref.watch(asyncCelebListProvider);

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

        final asyncBannerListState = ref.watch(
          asyncBannerListProvider(location: 'pic_home'),
        );
        return ListView(
          children: [
            CelebDropDown(),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  asyncBannerListState.when(
                    data: (data) {
                      return const CommonBanner(
                        'pic_home',
                        kPicHomeBannerAspectRatio,
                      );
                    },
                    // 배너 자리는 배너 모양으로 잡는다. 세로 리스트용
                    // VoteCardSkeleton 을 넣으면 안 된다 — 자연 높이가 기기별
                    // 460~524px 로 고정이라 어떤 배너 상자에도 들어가지 않는다.
                    loading: () => const CommonBannerSkeleton(
                      aspectRatio: kPicHomeBannerAspectRatio,
                    ),
                    // 실패해도 자리는 그대로 비워 둔다(기존 동작). 높이는
                    // 로딩/데이터와 같은 비율에서 나와야 세 상태가 서로 안 튄다.
                    error: (error, stackTrace) => const AspectRatio(
                      aspectRatio: kPicHomeBannerAspectRatio,
                      child: SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 16.w),
                    child: Text(
                      AppLocalizations.of(context).label_celeb_gallery,
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCelebGallery(),
                  const SizedBox(height: 20),
                  _buildVoteListTitle(),
                  _buildVoteSection(),
                ],
              ),
            ),
          ],
        );
      },
      // 로드된 화면과 같은 ListView 다. Column 이면 뷰포트 높이에 묶이는데
      // VoteCardSkeleton 은 자연 높이가 기기별 460~524px 로 고정이라 3장이면
      // 어떤 지원 기기에서도 화면을 넘긴다(402x874 기준 636px). 스크롤로 피하는
      // 게 아니라, 로딩 상태도 로드된 상태와 같은 스크롤 컨테이너를 쓰는 것이다.
      loading: () => ListView(
        children: const [
          VoteCardSkeleton(status: VoteCardStatus.ongoing),
          VoteCardSkeleton(status: VoteCardStatus.ongoing),
          VoteCardSkeleton(status: VoteCardStatus.ongoing),
        ],
      ),
      error: (error, stackTrace) {
        return buildErrorView(
          context,
          error: error,
          stackTrace: stackTrace,
          retryFunction: () {
            // ignore: unused_result
            ref.refresh(asyncMyCelebListProvider);
          },
        );
      },
    );
  }

  Widget _buildVoteListTitle() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 16.w),
      child: Row(
        children: [
          Text(
            "아티스트 투표",
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
          SvgPicture.asset(
            package: 'picnic_lib',
            'assets/icons/arrow_right_style=line.svg',
            width: 8.w,
            height: 15,
            colorFilter: const ColorFilter.mode(
              AppColors.grey900,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebGallery() {
    final asyncCelebGalleryListState = ref.watch(
      asyncCelebGalleryListProvider(9),
    );

    return asyncCelebGalleryListState.when(
      data: (data) => _buildGalleryList(data),
      error: (error, stackTrace) {
        return buildErrorView(
          context,
          error: error,
          stackTrace: stackTrace,
          retryFunction: () =>
              ref.read(asyncGalleryListProvider.notifier).build(),
        );
      },
      loading: () => const VoteCardSkeleton(status: VoteCardStatus.ongoing),
    );
  }

  Widget _buildGalleryList(List<GalleryModel> data) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 100,
      width: double.infinity,
      padding: EdgeInsets.only(left: 16.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          String title = data[index].getTitle();

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setPicCurrentPage(
                    GalleryDetailPage(
                      galleryId: data[index].id,
                      galleryName: data[index].titleEn,
                    ),
                  );
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
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 140.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8.r),
                        bottomRight: Radius.circular(8.r),
                      ),
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8.w),
                    child: Text(
                      title,
                      style: getTextStyle(
                        AppTypo.body14R,
                        Colors.white,
                      ).copyWith(overflow: TextOverflow.ellipsis),
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
          color: AppColors.grey00,
        ),
        itemCount: data.length,
      ),
    );
  }

  Widget _buildVoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedListView<int, VoteModel>.separated(
          state: _pagingController.value,
          fetchNextPage: _pagingController.fetchNextPage,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          builderDelegate: PagedChildBuilderDelegate<VoteModel>(
            firstPageProgressIndicatorBuilder: (context) => const Column(
              children: [
                VoteCardSkeleton(status: VoteCardStatus.ongoing),
                VoteCardSkeleton(status: VoteCardStatus.ongoing),
                VoteCardSkeleton(status: VoteCardStatus.ongoing),
              ],
            ),
            newPageProgressIndicatorBuilder: (context) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
            ),
            firstPageErrorIndicatorBuilder: (context) => buildErrorView(
              context,
              error: _pagingController.error,
              retryFunction: () => _pagingController.refresh(),
              stackTrace: null,
            ),
            newPageErrorIndicatorBuilder: (context) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
            ),
            noMoreItemsIndicatorBuilder: (context) => const SizedBox.shrink(),
            itemBuilder: (context, vote, index) {
              final now = DateTime.now().toUtc();
              final status = vote.startAt!.isAfter(now)
                  ? VoteStatus.upcoming
                  : VoteStatus.active;
              return VoteInfoCard(
                context: context,
                vote: vote,
                status: status,
                votePortal: VotePortal.pic,
              );
            },
            noItemsFoundIndicatorBuilder: (context) => NoItemContainer(),
          ),
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.grey300),
        ),
      ],
    );
  }
}

class CelebDropDown extends ConsumerStatefulWidget {
  const CelebDropDown({super.key});

  @override
  ConsumerState<CelebDropDown> createState() => _CelebDropDownState();
}

class _CelebDropDownState extends ConsumerState<CelebDropDown> {
  @override
  Widget build(BuildContext context) {
    final selectedCelebState = ref.watch(selectedCelebProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _buildSelectCelebBottomSheet(),
      child: Container(
        alignment: Alignment.centerLeft,
        height: 44,
        padding: EdgeInsets.only(left: 16.w, top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PicnicCachedNetworkImage(
                imageUrl: selectedCelebState?.thumbnail ?? '',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedCelebState?.nameKo ?? '',
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/arrow_down_style=line.svg',
              width: 20.w,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _buildSelectCelebBottomSheet() {
    final asyncCelebListState = ref.watch(asyncMyCelebListProvider);
    final selectedCelebState = ref.watch(selectedCelebProvider);

    logger.w('asyncMyCelebListState: $asyncCelebListState');

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
                AppLocalizations.of(context).label_moveto_celeb_gallery,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
              Text(
                AppLocalizations.of(context).text_moveto_celeb_gallery,
                style: getTextStyle(AppTypo.body16R, AppColors.grey900),
              ),
              const SizedBox(height: 16),
              if (selectedCelebState != null)
                ...asyncCelebListState.when(
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
                  loading: () => [ui.buildLoadingOverlay()],
                  error: (error, stackTrace) => [
                    buildErrorView(
                      context,
                      retryFunction: () {
                        // ignore: unused_result
                        ref.refresh(asyncMyCelebListProvider);
                      },
                      error: error,
                      stackTrace: stackTrace,
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSearchList(
    BuildContext context,
    List<CelebModel> data,
    CelebModel selectedCeleb,
  ) {
    data.removeWhere((item) => item.id == selectedCeleb.id);
    return data
        .map(
          (e) => Container(
            height: 70,
            margin: EdgeInsets.symmetric(horizontal: 32.w, vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: e.id == selectedCeleb.id
                  ? const Color(0xFF47E89B)
                  : AppColors.grey00,
              border: Border.all(color: AppColors.grey100, width: 1),
            ),
            child: InkWell(
              onTap: () {
                ref.read(selectedCelebProvider.notifier).setSelectedCeleb(e);
                ref.read(asyncBannerListProvider(location: 'pic_home'));
                Navigator.pop(context);
              },
              child: CelebListItem(
                item: e,
                type: 'my',
                showBookmark: e.id != selectedCeleb.id,
                enableBookmark: false,
              ),
            ),
          ),
        )
        .toList();
  }
}
