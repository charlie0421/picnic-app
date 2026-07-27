import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class CommonBanner extends ConsumerStatefulWidget {
  const CommonBanner(
    this.location,
    this.aspectRatio, {
    super.key,
    this.scheduler = const TimerCommonBannerScheduler(),
    this.onAutoplayMove,
  });

  final String location;
  final double aspectRatio;
  final CommonBannerScheduler scheduler;
  final ValueChanged<int>? onAutoplayMove;

  @override
  ConsumerState<CommonBanner> createState() => _CommonBannerState();
}

Duration commonBannerSlideDuration(int milliseconds) =>
    Duration(milliseconds: milliseconds > 0 ? milliseconds : 3000);

int commonBannerSafeIndex(int currentIndex, int length) =>
    length == 0 || currentIndex >= length ? 0 : currentIndex;

class _CommonBannerState extends ConsumerState<CommonBanner> {
  int _currentIndex = 0;
  SwiperController? _swiperController;
  CommonBannerScheduledTask? _autoplayTask;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _autoplayTask?.cancel();
    _swiperController?.dispose();
    super.dispose();
  }

  void _startAutoplay(List<CommonBannerSlide> slides) {
    _autoplayTask?.cancel();
    if (slides.length > 1) {
      _autoplayTask = widget.scheduler.schedule(
        slides[_currentIndex].duration,
        () {
          if (mounted) {
            final nextIndex = (_currentIndex + 1) % slides.length;
            widget.onAutoplayMove?.call(nextIndex);
            _swiperController?.move(nextIndex);
          }
        },
      );
    }
  }

  List<CommonBannerSlide> _ordinarySlides(List<BannerModel> banners) => [
    for (final item in banners)
      CommonBannerSlide(
        id: 'ordinary:${item.id}',
        duration: commonBannerSlideDuration(item.duration),
        child: _buildBannerItem(item),
      ),
  ];

  List<CommonBannerSlide> _homeSlides(
    List<BannerModel> ordinary,
    ActivePromotionCampaignsModel campaigns,
    String locale,
  ) {
    final owned = campaigns.campaignOwnedHomeBannerIds.toSet();
    final emitted = <int>{};
    return [
      for (final campaign in campaigns.visibleHomeItems(locale))
        if (emitted.add(campaign.homeCreative!.bannerId))
          CommonBannerSlide(
            id: 'campaign:${campaign.homeCreative!.bannerId}',
            duration: commonBannerSlideDuration(
              campaign.homeCreative!.duration,
            ),
            child: CandyBoostBanner(campaign: campaign),
          ),
      ..._ordinarySlides(
        ordinary.where((banner) => !owned.contains(banner.id)).toList(),
      ),
    ];
  }

  Widget _renderSlides(List<CommonBannerSlide> slides) {
    if (slides.isEmpty) return const SizedBox.shrink();
    _currentIndex = commonBannerSafeIndex(_currentIndex, slides.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoplay(slides);
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: slides.length == 1
              ? KeyedSubtree(
                  key: ValueKey(slides.single.id),
                  child: slides.single.child,
                )
              : Swiper(
                  controller: _swiperController,
                  itemCount: slides.length,
                  itemBuilder: (_, index) => KeyedSubtree(
                    key: ValueKey(slides[index].id),
                    child: slides[index].child,
                  ),
                  onIndexChanged: (index) {
                    setState(() => _currentIndex = index);
                    _startAutoplay(slides);
                  },
                  autoplay: false,
                  duration: 300,
                ),
        ),
        if (slides.length > 1)
          SizedBox(
            height: 20,
            child: CustomPagination(
              itemCount: slides.length,
              activeIndex: _currentIndex,
            ),
          ),
      ],
    );
  }

  Widget _buildBannerShimmer() {
    final width = ref.watch(globalMediaQueryProvider).size.width;
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(width: width, color: Colors.white),
      ),
    );
  }

  Widget _buildBannerItem(BannerModel item) {
    String title = getLocaleTextFromJson(item.title);
    String imageUrl = getLocaleTextFromJson(item.image);
    final isGif = imageUrl.toLowerCase().endsWith('.gif');

    return GestureDetector(
      onTap: () async {
        if (item.link != null) {
          try {
            final uri = Uri.parse(item.link!);
            final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
            final host = uri.host.toLowerCase();
            final isPicnicDomain =
                host == 'applink.picnic.fan' || host == 'www.picnic.fan';

            // Picnic 도메인의 앱 내부 경로는 외부 브라우저를 열지 말고 인앱 딥링크로 처리
            if (isHttp && isPicnicDomain) {
              await AppInitializer.handleDeepLink(ref, item.link!);
            } else if (isHttp) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              await AppInitializer.handleDeepLink(ref, item.link!);
            }
          } catch (_) {
            await AppInitializer.handleDeepLink(ref, item.link!);
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 베너는 항상 고우선순위로 처리
          PicnicCachedNetworkImage(
            key: ValueKey('banner_${item.id}_$_currentIndex'),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            // 베너 최적화 설정
            priority: ImagePriority.high, // 베너는 높은 우선순위
            enableMemoryOptimization: true,
            enableProgressiveLoading: !isGif, // GIF가 아닌 경우만 점진적 로딩
            lazyLoadingStrategy: LazyLoadingStrategy.none, // 베너는 즉시 로딩
            timeout: const Duration(seconds: 12), // 베너는 조금 더 긴 타임아웃
            maxRetries: 3, // 베너는 더 많은 재시도
            // 베너 크기에 맞는 메모리 캐시 설정
            memCacheWidth: MediaQuery.of(context).size.width.toInt(),
            memCacheHeight:
                (MediaQuery.of(context).size.width / widget.aspectRatio)
                    .toInt(),
          ),
          if (title.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8.w),
                color: Colors.black.withValues(alpha: 0.5),
                child: Text(
                  title,
                  style: getTextStyle(
                    AppTypo.body14R,
                    Colors.white,
                  ).copyWith(overflow: TextOverflow.ellipsis),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncBannerListState = ref.watch(
      asyncBannerListProvider(location: widget.location),
    );
    return asyncBannerListState.when(
      data: (List<BannerModel> data) {
        if (widget.location != 'vote_home') {
          return _renderSlides(_ordinarySlides(data));
        }
        return ref
            .watch(activePromotionCampaignProvider(PromotionSurface.home))
            .when(
              data: (campaigns) => _renderSlides(
                _homeSlides(
                  data,
                  campaigns,
                  Localizations.localeOf(context).languageCode,
                ),
              ),
              loading: _buildBannerShimmer,
              // 캠페인 조회 실패 시 일반 베너로 degrade
              // 캠페인 데이터가 없어 owned 필터링은 못 하므로 대체 대상 베너가
              // 원본으로 노출될 수 있으나, 전체 미노출보다는 낫다
              error: (_, _) => _renderSlides(_ordinarySlides(data)),
            );
      },
      loading: _buildBannerShimmer,
      error: (error, stackTrace) => buildErrorView(
        context,
        error: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  }
}

class CommonBannerSlide {
  const CommonBannerSlide({
    required this.id,
    required this.duration,
    required this.child,
  });
  final String id;
  final Duration duration;
  final Widget child;
}

abstract interface class CommonBannerScheduledTask {
  void cancel();
}

abstract interface class CommonBannerScheduler {
  CommonBannerScheduledTask schedule(Duration delay, VoidCallback callback);
}

class TimerCommonBannerScheduler implements CommonBannerScheduler {
  const TimerCommonBannerScheduler();

  @override
  CommonBannerScheduledTask schedule(Duration delay, VoidCallback callback) =>
      _TimerCommonBannerScheduledTask(Timer(delay, callback));
}

class _TimerCommonBannerScheduledTask implements CommonBannerScheduledTask {
  _TimerCommonBannerScheduledTask(this.timer);
  final Timer timer;

  @override
  void cancel() => timer.cancel();
}
