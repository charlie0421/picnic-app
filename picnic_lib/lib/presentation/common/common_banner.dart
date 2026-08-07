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

/// 캠페인 RPC 대기 상한. 이 시간 안에 응답이 없으면 HOME 배너는 캠페인 없이
/// 일반 슬라이드로 degrade 렌더한다.
///
/// 상한은 반드시 이 위젯 안에서만 적용한다 — RPC provider/리포지토리 레벨에
/// 걸면 스토어 구매 플로우(purchase_star_candy_state)가 같은 provider 를 읽어
/// 보너스 안내·기록이 오염된다 (PR #143 회귀의 원인).
const Duration commonBannerCampaignWaitCap = Duration(seconds: 5);

Duration commonBannerSlideDuration(int milliseconds) =>
    Duration(milliseconds: milliseconds > 0 ? milliseconds : 3000);

int commonBannerSafeIndex(int currentIndex, int length) =>
    length == 0 || currentIndex >= length ? 0 : currentIndex;

class _CommonBannerState extends ConsumerState<CommonBanner> {
  int _currentIndex = 0;
  SwiperController? _swiperController;
  CommonBannerScheduledTask? _autoplayTask;
  CommonBannerScheduledTask? _campaignWaitTask;
  bool _campaignWaitExpired = false;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _autoplayTask?.cancel();
    _campaignWaitTask?.cancel();
    _swiperController?.dispose();
    super.dispose();
  }

  void _armCampaignWaitCap() {
    if (_campaignWaitTask != null) return;
    _campaignWaitTask = widget.scheduler.schedule(
      commonBannerCampaignWaitCap,
      () {
        if (mounted) setState(() => _campaignWaitExpired = true);
      },
    );
  }

  void _clearCampaignWaitCap({required bool resetExpired}) {
    _campaignWaitTask?.cancel();
    _campaignWaitTask = null;
    if (resetExpired) _campaignWaitExpired = false;
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
            // width/height 는 논리 픽셀 렌더 크기 — 없으면 CDN URL 에 w/h
            // 리사이즈 파라미터가 붙지 않아 원본 크기를 그대로 내려받는다.
            // DPR 보정은 위젯 내부(resolutionMultiplier)에서 곱해진다.
            //
            // 한계: 공유 위젯 _getTransformedUrl 이 w/h 에 multiplier 를
            // 곱하면서 dpr 도 함께 보내는 기존 결함 때문에 Imgix 가 배율을
            // 이중 적용해(실측 DPR3: w=2000&h=1125&dpr=2.5 → 최종 5000px
            // 요청, fit=max 로 원본 상한) 현재는 절감 효과가 거의 없다.
            // 그 결함이 고쳐지면 이 호출부가 의도대로 동작한다.
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width / widget.aspectRatio,
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
        // 상한의 의미는 "쿼리 세대당 5초"가 아니라 "이 표면이 shimmer 를
        // 연속으로 보여줄 수 있는 시간의 상한"이다. loading 중 provider 가
        // invalidate 돼도 상한은 이어서 흐르고(사용자 대기 시간은 리셋되지
        // 않으므로), 만료 뒤의 재조회는 shimmer 대신 일반 슬라이드를 즉시
        // 보여준다. 만료 상태는 캠페인 data 가 도착하면 해제된다.
        // (riverpod 은 loading→loading 재조회를 == 동등으로 dedupe 해 위젯에
        // 통지하지 않고 .future 도 미완료 future 를 재사용하므로, 세대별
        // 상한은 위젯 레벨에서 결정론적으로 구현할 수 없기도 하다.)
        return ref
            .watch(activePromotionCampaignProvider(PromotionSurface.home))
            .when(
              data: (campaigns) {
                _clearCampaignWaitCap(resetExpired: true);
                return _renderSlides(
                  _homeSlides(
                    data,
                    campaigns,
                    Localizations.localeOf(context).languageCode,
                  ),
                );
              },
              loading: () {
                // 상한 초과 시 캠페인 없이 degrade 렌더. provider 는 건드리지
                // 않으므로 스토어가 읽는 캠페인 상태는 오염되지 않고, 늦게라도
                // 응답이 오면 data 분기가 캠페인 슬라이드로 복구한다.
                if (_campaignWaitExpired) {
                  return _renderSlides(_ordinarySlides(data));
                }
                _armCampaignWaitCap();
                return _buildBannerShimmer();
              },
              // 캠페인 조회 실패 시 일반 베너로 degrade
              // 캠페인 데이터가 없어 owned 필터링은 못 하므로 대체 대상 베너가
              // 원본으로 노출될 수 있으나, 전체 미노출보다는 낫다
              error: (_, _) {
                _clearCampaignWaitCap(resetExpired: false);
                return _renderSlides(_ordinarySlides(data));
              },
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
