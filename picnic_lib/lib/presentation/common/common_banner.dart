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
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
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
  List<CommonBannerSlide> _slides = const [];
  String? _activeSlideId;
  String _slideSequence = '';
  int _slideRevision = 0;
  String? _autoplaySlideId;
  Duration? _autoplayDuration;
  int _autoplayGeneration = 0;
  final _prefetchScope = PicnicImagePrefetchScope();
  String? _prefetchSignature;
  int _prefetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void dispose() {
    _cancelAutoplay();
    _prefetchGeneration++;
    _prefetchScope.dispose();
    _swiperController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommonBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduler != widget.scheduler) _cancelAutoplay();
    if (oldWidget.location != widget.location) _clearSlides();
  }

  void _cancelAutoplay() {
    _autoplayGeneration++;
    _autoplayTask?.cancel();
    _autoplayTask = null;
    _autoplaySlideId = null;
    _autoplayDuration = null;
  }

  void _clearSlides() {
    _cancelAutoplay();
    _slides = const [];
    _activeSlideId = null;
    _currentIndex = 0;
    _slideSequence = '';
    _slideRevision++;
    _schedulePrefetch(const []);
  }

  void _schedulePrefetch(List<PicnicImageRequest> requests) {
    final signature = requests
        .map((r) => '${r.url}:${r.decodeWidth}:${r.decodeHeight}')
        .join('|');
    if (_prefetchSignature == signature) return;
    _prefetchSignature = signature;
    final generation = ++_prefetchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _prefetchGeneration) {
        _prefetchScope.replace(context, requests);
      }
    });
  }

  PicnicImageRequest _request(String url, Size size) =>
      PicnicImageRequest.resolve(
        context: context,
        imageUrl: url,
        width: size.width,
        height: size.height,
      );

  void _startAutoplay() {
    if (_slides.length < 2) {
      _cancelAutoplay();
      return;
    }
    final current = _slides[_currentIndex];
    if (_autoplayTask != null &&
        _autoplaySlideId == current.id &&
        _autoplayDuration == current.duration) {
      return;
    }
    _cancelAutoplay();
    _autoplaySlideId = current.id;
    _autoplayDuration = current.duration;
    final generation = _autoplayGeneration;
    _autoplayTask = widget.scheduler.schedule(current.duration, () {
      if (!mounted || generation != _autoplayGeneration || _slides.length < 2) {
        return;
      }
      _autoplayTask = null;
      _autoplayGeneration++;
      final nextIndex = (_currentIndex + 1) % _slides.length;
      widget.onAutoplayMove?.call(nextIndex);
      unawaited(_swiperController?.move(nextIndex));
    });
  }

  void _changeSlide(int index, int revision) {
    if (!mounted ||
        revision != _slideRevision ||
        index < 0 ||
        index >= _slides.length) {
      return;
    }
    if (_slides[index].id == _activeSlideId) return;
    setState(() {
      _currentIndex = index;
      _activeSlideId = _slides[index].id;
      _swiperController?.index = index;
    });
    _startAutoplay();
  }

  List<CommonBannerSlide> _ordinarySlides(
    List<BannerModel> banners,
    Size size,
  ) => [for (final item in banners) _ordinarySlide(item, size)];

  CommonBannerSlide _ordinarySlide(BannerModel item, Size size) {
    final request = _request(getLocaleTextFromJson(item.image), size);
    return CommonBannerSlide(
      id: 'ordinary:${item.id}',
      duration: commonBannerSlideDuration(item.duration),
      imageRequest: request,
      child: _buildBannerItem(item, size, request),
    );
  }

  List<CommonBannerSlide> _homeSlides(
    List<BannerModel> ordinary,
    HomePromotionResolution resolved,
    Size size,
  ) {
    final emitted = <int>{};
    return [
      for (final slide in resolved.slides)
        if (emitted.add(slide.bannerId))
          _campaignSlide(
            id: 'campaign:${slide.bannerId}',
            duration: commonBannerSlideDuration(slide.durationMs),
            creative: slide.creative,
            size: size,
          ),
      ..._ordinarySlides(
        ordinary
            .where((banner) => !resolved.ownedBannerIds.contains(banner.id))
            .toList(),
        size,
      ),
    ];
  }

  CommonBannerSlide _campaignSlide({
    required String id,
    required Duration duration,
    required PromotionCreativeModel creative,
    required Size size,
  }) {
    final request = _request(
      creative.localizedImage(Localizations.localeOf(context).languageCode)!,
      size,
    );
    return CommonBannerSlide(
      id: id,
      duration: duration,
      imageRequest: request,
      child: CandyBoostBanner(creative: creative, imageRequest: request),
    );
  }

  Widget _renderSlides(List<CommonBannerSlide> slides) {
    if (slides.isEmpty) {
      _clearSlides();
      return const SizedBox.shrink();
    }
    final preservedIndex = slides.indexWhere(
      (slide) => slide.id == _activeSlideId,
    );
    _currentIndex = preservedIndex < 0 ? 0 : preservedIndex;
    _slides = slides;
    _activeSlideId = slides[_currentIndex].id;
    final nextRequest = slides.length > 1
        ? slides[(_currentIndex + 1) % slides.length].imageRequest
        : null;
    _schedulePrefetch([?nextRequest]);
    final sequence = slides.map((slide) => slide.id).join(',');
    if (_slideSequence != sequence) {
      _slideSequence = sequence;
      _slideRevision++;
    }
    final revision = _slideRevision;
    // Swiper reads this initial index when its slide sequence changes. Keep
    // ordinary rebuilds uncontrolled so swipes do not recreate its controller.
    _swiperController?.index = _currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && revision == _slideRevision) _startAutoplay();
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
                  key: ValueKey(revision),
                  controller: _swiperController,
                  itemCount: slides.length,
                  itemBuilder: (_, index) => KeyedSubtree(
                    key: ValueKey(slides[index].id),
                    child: slides[index].child,
                  ),
                  onIndexChanged: (index) => _changeSlide(index, revision),
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

  Widget _buildBannerItem(
    BannerModel item,
    Size size,
    PicnicImageRequest request,
  ) {
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
            key: ValueKey('banner_${item.id}'),
            imageUrl: imageUrl,
            imageRequest: request,
            fit: BoxFit.cover,
            // 베너 최적화 설정
            priority: ImagePriority.high, // 베너는 높은 우선순위
            enableMemoryOptimization: true,
            enableProgressiveLoading: !isGif, // GIF가 아닌 경우만 점진적 로딩
            lazyLoadingStrategy: LazyLoadingStrategy.none, // 베너는 즉시 로딩
            timeout: const Duration(seconds: 12), // 베너는 조금 더 긴 타임아웃
            maxRetries: 3, // 베너는 더 많은 재시도
            width: size.width,
            height: size.height,
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
    final campaign = widget.location == 'vote_home'
        ? ref.watch(
            homePromotionCampaignProvider(
              Localizations.localeOf(context).languageCode,
            ),
          )
        : null;
    return asyncBannerListState.when(
      skipLoadingOnRefresh: false,
      skipError: false,
      data: (data) {
        // Never reuse account-bound campaign data during a refresh or error.
        final resolved = campaign?.when<HomePromotionResolution?>(
          skipLoadingOnRefresh: false,
          skipError: false,
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final size = Size(width, width / widget.aspectRatio);
            // Ordinary HOME rows exclude campaign-owned banners at the provider
            // boundary and can display while campaign data loads.
            return _renderSlides(
              resolved == null
                  ? _ordinarySlides(data, size)
                  : _homeSlides(data, resolved, size),
            );
          },
        );
      },
      loading: () {
        _clearSlides();
        return _buildBannerShimmer();
      },
      error: (error, stackTrace) {
        _clearSlides();
        return buildErrorView(
          context,
          error: error.toString(),
          stackTrace: stackTrace,
        );
      },
    );
  }
}

class CommonBannerSlide {
  const CommonBannerSlide({
    required this.id,
    required this.duration,
    required this.child,
    this.imageRequest,
  });
  final PicnicImageRequest? imageRequest;
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
