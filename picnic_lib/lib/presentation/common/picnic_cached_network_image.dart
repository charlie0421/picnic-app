import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';

import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/image_shimmer_loading.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:visibility_detector/visibility_detector.dart';

export 'package:picnic_lib/presentation/common/image_shimmer_loading.dart' show buildImageLoadingOverlay;

/// 이미지 복잡도 레벨
enum ImageComplexity {
  low, // 작은 크기, 단순한 이미지
  medium, // 중간 크기 이미지
  high, // 큰 크기, 복잡한 이미지
}

/// Lazy Loading 전략
enum LazyLoadingStrategy {
  none, // Lazy Loading 비활성화
  viewport, // 뷰포트에 들어올 때 로드
  preload, // 뷰포트 근처에서 미리 로드
  progressive, // 점진적 로딩 (저품질 → 고품질)
}

/// 이미지 로딩 우선순위
enum ImagePriority {
  low, // 낮은 우선순위 (백그라운드 이미지 등)
  normal, // 일반 우선순위
  high, // 높은 우선순위 (사용자가 현재 보고 있는 이미지)
}

/// 성공적으로 로딩된 이미지 URL을 추적하는 글로벌 Set
/// 위젯이 재생성되더라도 이미 로딩된 이미지는 즉시 표시됨
final Set<String> _successfullyLoadedImageUrls = {};

class PicnicCachedNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Duration? timeout;
  final int? maxRetries;

  // Lazy Loading 관련 매개변수
  final LazyLoadingStrategy lazyLoadingStrategy;
  final double visibilityThreshold; // 가시성 임계값 (0.0 ~ 1.0)
  final Duration? lazyLoadDelay; // 지연 로딩 딜레이
  final Widget? placeholder; // 커스텀 플레이스홀더
  final bool enablePreloading; // 미리 로딩 활성화
  final double preloadDistance; // 미리 로딩 거리 (픽셀)

  // 성능 최적화 관련 매개변수
  final ImagePriority priority; // 이미지 로딩 우선순위
  final bool enableMemoryOptimization; // 메모리 최적화 활성화
  final bool enableProgressiveLoading; // 점진적 로딩 활성화

  /// 앱 레벨 동시 로딩 제한은 제거되었다(HTTP 클라이언트가 커넥션 풀링으로 제어).
  /// 하위 호환을 위해 파라미터는 남기지만 더 이상 아무 효과가 없다.
  @Deprecated('앱 레벨 동시 로딩 제한 제거됨 — 이 값은 무시된다')
  final int? maxConcurrentLoads;

  final Widget? errorWidget; // 커스텀 에러 위젯
  final bool showLoadingOverlay;

  // C3: 리스트 전용 요청 가중치 축소(다른 화면 영향 없음 — 기본값 null = 현재 동작 유지).
  // maxQualityOverride: 단일(저복잡도) URL 의 q 값을 이 값으로 제한.
  // maxResolutionMultiplierCap: _getResolutionMultiplier 결과를 이 값으로 clamp.
  final int? maxQualityOverride;
  final double? maxResolutionMultiplierCap;

  // C4: 빠른 플링 중에는 실제 이미지 대신 placeholder 를 보여주고, 스크롤이 멎으면 로드.
  // Scrollable.recommendDeferredLoadingForContext 게이트. 기본 false = 현재 동작.
  final bool deferDuringFastScroll;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.timeout,
    this.maxRetries,
    this.lazyLoadingStrategy = LazyLoadingStrategy.viewport,
    this.visibilityThreshold = 0.1,
    this.lazyLoadDelay,
    this.placeholder,
    this.errorWidget,
    this.showLoadingOverlay = true,
    this.enablePreloading = true,
    this.preloadDistance = 200.0,
    this.priority = ImagePriority.normal,
    this.enableMemoryOptimization = true,
    this.enableProgressiveLoading = true,
    @Deprecated('앱 레벨 동시 로딩 제한 제거됨 — 이 값은 무시된다')
    this.maxConcurrentLoads,
    this.maxQualityOverride,
    this.maxResolutionMultiplierCap,
    this.deferDuringFastScroll = false,
  });

  /// 테스트 환경에서 이미지 로딩 타이머 비활성화 (pending timer assertion 방지)
  @visibleForTesting
  static bool disableTimeoutForTest = false;

  @override
  ConsumerState<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState
    extends ConsumerState<PicnicCachedNetworkImage> {
  bool _loading = false;
  bool _hasError = false;
  bool _shouldLoadImage = false; // Lazy Loading 제어
  bool _isVisible = false; // 가시성 상태
  bool _isImageLoaded = false;
  DateTime? _loadStartTime;
  int _retryCount = 0;
  Timer? _lazyLoadTimer;
  Timer? _retryTimer; // 재시도 백오프 (취소 가능)
  List<String>? _cachedUrls; // 동일 위젯 생명주기 동안 고정된 URL 세트

  /// VisibilityDetector 의 Key 는 위젯 식별자일 뿐 아니라 visibility_detector
  /// 패키지의 **전역 static map**(`_updates`, `_lastVisibility`) 의 키로도 쓰인다.
  ///
  /// 예전에는 이 Key 를 `Key('lazy_image_$imageUrl')` — 즉 이미지 URL 로 만들었다.
  /// 그래서 같은 이미지가 화면에 두 번 이상 나오면(인기 아티스트가 여러 투표 카드의
  /// top3 에 걸리거나, 예정 투표 썸네일 그리드에 동시 노출) 키가 충돌해
  /// `_updates[key] = callback` 이 서로를 덮어썼고, 한쪽 인스턴스는 가시성 콜백을
  /// 영영 받지 못해 `_shouldLoadImage` 가 false 인 채로 남았다 — 로딩을 시작조차
  /// 못 하고 shimmer 만 보였다. 형제 위젯이 아니면 Flutter 가 중복 Key 에러도 내지
  /// 않아 조용히 오동작한다.
  ///
  /// 따라서 인스턴스마다 고유한 키를 쓴다.
  final Key _visibilityKey = UniqueKey();

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _defaultMaxRetries = 2;
  static const Duration _maxBackoffDelay = Duration(seconds: 30);

  // 성능 모니터링용 (CachedNetworkImage 캐시와는 별개)
  static final Map<String, DateTime> _lastSnapshotTimes = {};
  static final Map<String, List<DateTime>> _failureHistory = {};
  static DateTime? _lastGlobalSnapshot;
  static int _snapshotCount = 0;
  static DateTime? _lastMemoryPressureLog;
  static const Duration _memoryPressureLogInterval = Duration(minutes: 1);
  static final Map<String, DateTime> _lastTimeoutLogTimes = {};
  static const Duration _timeoutLogInterval = Duration(minutes: 3);
  int _reloadToken = 0;
  late final DisposableBuildContext<ConsumerState<PicnicCachedNetworkImage>>
  _scrollAwareContext;

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');

  Duration get effectiveTimeout => widget.timeout ?? _defaultTimeout;
  int get effectiveMaxRetries => widget.maxRetries ?? _defaultMaxRetries;

  Duration _calculateBackoffDelay(int retryCount) {
    final baseDelay = Duration(milliseconds: 500);
    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * math.pow(1.5, retryCount))
          .toInt(),
    );
    return delay > _maxBackoffDelay ? _maxBackoffDelay : delay;
  }

  int _roundPixels(double value, double multiplier) {
    final computed = (value * multiplier).round();
    return computed > 0 ? computed : 1;
  }

  /// [KNOWN ISSUE — 별도 후속 작업, 이 함수는 아직 고치지 않았다]
  ///
  /// 여기서 계산한 값은 `CachedNetworkImage.memCacheWidth/Height` 로 흘러
  /// 들어가 Flutter 엔진의 `ResizeImage.width/height` 가 된다. Flutter SDK
  /// 문서(`packages/flutter/lib/src/painting/image_provider.dart`,
  /// `ResizeImage.width` 1274-1281행, 클래스 문서 1230-1236·1251-1252행)에
  /// 따르면 이 값은 **디코드해서 캐시할 비트맵의 물리 픽셀(physical pixel)
  /// 수**다 — 논리(dp) 픽셀이 아니고, devicePixelRatio 를 자동으로 반영하지도
  /// 않는다. SDK 문서의 예제조차 `MediaQuery.widthOf(context) ~/ 2` 같은
  /// 논리값을 그대로 넣는 함정을 보여준다.
  ///
  /// 그런데 이 함수는 `explicit`(호출부가 넘긴 memCacheWidth/Height)이든
  /// `fallback`(위젯의 논리 width/height)이든 논리 px 기준값에 1.0 또는 0.5
  /// 배율만 곱한다 — DPR 을 전혀 반영하지 않는다. 반면 CDN 다운로드 URL 의
  /// w/h(`_getTransformedUrl`)는 `_getResolutionMultiplier`(DPR 기반, 최대
  /// 2.5~4.0배)로 정확히 물리 픽셀 목표를 계산한다. **두 경로의 단위가
  /// 불일치한다:** DPR 2.5~4 기기에서 물리 픽셀 기준 100~160px 이미지를
  /// 내려받고도 여기서는 40px(예: width=40dp) 로만 디코드해 캐시하므로,
  /// 렌더 시 화면이 요구하는 물리 픽셀로 다시 업스케일되어 흐릿해지고
  /// 내려받은 고해상도 데이터도 버려진다.
  ///
  /// 올바른 정렬 방향은 **CDN 요청은 물리 px 로 유지한 채 이 함수를 물리 px
  /// 로 끌어올리는 것**이다 — 반대로 CDN w/h 를 논리 px 로 낮추면 레티나
  /// 선명도 자체를 잃는다.
  ///
  /// 지금 고치지 않은 이유: 이 위젯을 쓰는 45곳 중 최소 10곳이 memCacheWidth/
  /// Height 를 명시적으로 넘기며(`explicit` 경로), 전부 DPR 을 반영하지 않은
  /// 원시 숫자다 — avatar_container.dart, common_banner.dart,
  /// vote_detail_page.dart(2곳), vote_detail_achieve_page.dart(2곳),
  /// vote_home_page.dart, board_list_page.dart, common_artist_widget.dart,
  /// artist_search_result_item.dart, goonghap_card.dart. `explicit` 값까지
  /// DPR 을 반영하려면(그래야 실사용 대부분에 효과가 있다) 앱 전역 디코드
  /// 메모리가 최대 DPR² 배(모바일 캡 2.5 → 6.25배, iPad 캡 4.0 → 16배)까지
  /// 늘 수 있어, 저사양 기기 OOM 위험을 실기기로 검증하기 전에는 단독으로
  /// 판단하지 않기로 했다(2026-08-07). 호출부 44곳을 흔드는 변경이라 이번
  /// PR(서버가 무시하는 CDN 파라미터 제거)과 롤백 단위를 분리한다.
  int _computeCacheDimension(
    int? explicit,
    double? fallback,
    double multiplier,
  ) {
    if (explicit != null) {
      return math.max(1, (explicit * multiplier).round());
    }
    if (fallback != null && fallback.isFinite) {
      return math.max(1, (fallback * multiplier).round());
    }

    return math.max(1, (400 * multiplier).round());
  }

  String _cacheKeyFor(String url, {int? index, bool isLowQuality = false}) {
    final buffer = StringBuffer(url)
      ..write('_')
      ..write(_reloadToken);
    if (index != null) {
      buffer
        ..write('_')
        ..write(index);
    }
    if (isLowQuality) {
      buffer.write('_lq');
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    _scrollAwareContext =
        DisposableBuildContext<ConsumerState<PicnicCachedNetworkImage>>(this);

    // Lazy Loading 전략에 따른 초기화
    _initializeLazyLoading();

    // 메모리 최적화가 활성화된 경우에만 실행
    if (widget.enableMemoryOptimization) {
      _PicnicCachedNetworkImageState._optimizeImageCache();
    }

    if (isGif) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareGifLoading();
      });
    }
    // URL 세트는 최초 계산 후 생명주기 동안 고정하여 캐시 키 변동을 방지
    // (동시 로딩 수 변화로 dpr/품질 조합이 흔들리며 캐시 미스가 나는 문제 완화)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cachedUrls ??= _getTransformedUrls(
          context,
          _capResolution(_getResolutionMultiplier(context)),
        );
      }
    });
  }

  /// Lazy Loading 초기화
  void _initializeLazyLoading() {
    // 이미 성공적으로 로딩된 이미지인지 확인
    final isAlreadyLoaded = _successfullyLoadedImageUrls.contains(widget.imageUrl);

    if (isAlreadyLoaded) {
      // 이미 로딩된 이미지는 즉시 표시
      _shouldLoadImage = true;
      _isImageLoaded = true;
      _loading = false;
      return;
    }

    _isImageLoaded = false;
    switch (widget.lazyLoadingStrategy) {
      case LazyLoadingStrategy.none:
        _shouldLoadImage = true;
        break;
      case LazyLoadingStrategy.viewport:
      case LazyLoadingStrategy.preload:
      case LazyLoadingStrategy.progressive:
        _shouldLoadImage = false;
        break;
    }
  }

  /// 가시성 변경 처리
  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible = info.visibleFraction >= widget.visibilityThreshold;

    if (isVisible != _isVisible) {
      _isVisible = isVisible;

      if (isVisible && !_shouldLoadImage) {
        _triggerLazyLoad();
      }

      // 가시화 시 이전에 에러가 있었고 재시도 가능하면 즉시 재시도 트리거
      if (isVisible && _hasError && _retryCount < effectiveMaxRetries) {
        setState(() {
          _hasError = false;
          _loading = true;
          _shouldLoadImage = true;
        });
      } else if (!isVisible &&
          _shouldLoadImage &&
          widget.priority == ImagePriority.low) {
        _cancelLoading();
      }
    }
  }

  /// 로딩 취소
  void _cancelLoading() {
    if (_lazyLoadTimer?.isActive == true) {
      _lazyLoadTimer?.cancel();
    }
  }

  /// Lazy Loading 트리거
  ///
  /// 예전에는 앱 레벨에서 동시 로딩을 8개로 제한하고 초과분을 전역 큐에 넣었으나,
  /// (1) 실제 다운로드 동시성은 flutter_cache_manager 가 이미 제어한다 —
  ///     WebHelper 가 concurrentFetches(기본 10)를 넘는 요청을 내부 큐에 넣는다
  ///     (flutter_cache_manager/lib/src/web/web_helper.dart). 따라서 앱 레벨의
  ///     추가 게이트는 중복이고,
  /// (2) 전역 카운터가 acquire/release 불일치(dispose 무조건 감소 + math.max
  ///     clamp)로 부정확해 큐 게이트가 사실상 발동하지 않았으며,
  /// (3) 카운터를 정확히 만들면 리스트 화면(항상 8개 이상 동시 로딩)에서 무관한
  ///     이미지가 큐에 갇히거나 저대역폭 오판(_isLowBandwidthConnection)이 켜지는
  ///     회귀를 낳았다.
  /// → 전역 동시성 제어를 제거하고, 우선순위 기반 지연만 유지한다.
  void _triggerLazyLoad() {
    if (_shouldLoadImage || !mounted) return;

    final delay = _calculateLoadDelay();

    if (delay > Duration.zero) {
      _lazyLoadTimer?.cancel();
      _lazyLoadTimer = Timer(delay, () {
        if (mounted && !_shouldLoadImage) {
          _startLoading();
        }
      });
    } else {
      _startLoading();
    }
  }

  /// 로딩 지연 시간 계산
  Duration _calculateLoadDelay() {
    final baseDelay = widget.lazyLoadDelay ?? Duration.zero;

    switch (widget.priority) {
      case ImagePriority.high:
        return Duration.zero;
      case ImagePriority.normal:
        return baseDelay;
      case ImagePriority.low:
        return baseDelay + Duration(milliseconds: 200);
    }
  }

  /// 로딩 시작
  void _startLoading() {
    if (!mounted) return;

    setState(() {
      _shouldLoadImage = true;
      _isImageLoaded = false;
    });
  }

  @override
  void dispose() {
    _lazyLoadTimer?.cancel();
    _retryTimer?.cancel();
    // visibility_detector 는 RenderObject dispose 시 전역 맵을 정리하지 않고,
    // `_lastVisibility` 는 "보이지 않게 될 때"만 엔트리를 지운다. 즉 보이는 상태로
    // dispose 되면(라우트 pop, 리스트 축소, pull-to-refresh) 엔트리가 영구히 남는다.
    // URL 기반 키일 때는 distinct URL 수만큼 유한했지만, 위의 인스턴스 고유 키는
    // dispose 마다 하나씩 무한히 늘어나므로 반드시 직접 정리해 줘야 한다.
    VisibilityDetectorController.instance.forget(_visibilityKey);
    _scrollAwareContext.dispose();
    super.dispose();
  }

  // 전역 캐시 최적화 상태 추적

  /// Flutter ImageCache 설정 최적화
  static void _optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    if (kIsWeb) {
      // 웹에서는 더 보수적인 설정
      imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150MB
      imageCache.maximumSize = 300; // 최대 300개 이미지
    } else {
      // 모바일에서는 메모리 사용 폭을 완화
      imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200MB
      imageCache.maximumSize = 500; // 최대 500개 이미지
    }

    // 캐시 정리 임계값을 더 높게 설정하여 빈번한 정리 방지
    imageCache.pendingImageCount;
  }

  /// 부분적 이미지 캐시 정리 (더 스마트한 정리)
  void _clearPartialImageCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final currentSizeBytes = imageCache.currentSizeBytes;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      final currentImageCount = imageCache.liveImageCount;
      final pendingDecodeCount = imageCache.pendingImageCount;

      if (pendingDecodeCount > 0) {
        logger.d('이미지 디코딩이 진행 중(pending: $pendingDecodeCount)이라 캐시 정리를 건너뜁니다.');
        return;
      }

      // 90% 초과 시에만 정리 (기존 85%에서 상향) - 더 관대한 임계값
      if (currentSizeBytes > maxSizeBytes * 0.90) {
        final previousSizeBytes = currentSizeBytes;
        final previousImageCount = currentImageCount;

        // 20%만 정리 (기존 30%에서 감소) - 더 보수적인 정리
        final targetSize = (maxSizeBytes * 0.7).round();

        // 더 부드러운 캐시 정리를 위한 배치 처리
        final originalMaxSize = imageCache.maximumSizeBytes;
        imageCache.maximumSizeBytes = targetSize;

        // 원래 제한으로 복구 (지연 시간 증가)
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            imageCache.maximumSizeBytes = originalMaxSize;
          }
        });

        final newSizeBytes = imageCache.currentSizeBytes;
        final newImageCount = imageCache.liveImageCount;

        final previousSizeMB = previousSizeBytes ~/ (1024 * 1024);
        final newSizeMB = newSizeBytes ~/ (1024 * 1024);

        logger.d(
          '이미지 캐시 부분 정리됨: ${previousSizeMB}MB/${(maxSizeBytes ~/ (1024 * 1024))}MB → ${newSizeMB}MB, '
          '이미지 수: $previousImageCount개 → $newImageCount개',
        );
      }
    } catch (e) {
      logger.e('이미지 캐시 정리 오류: $e');
    }
  }

  void _prepareGifLoading() {
    try {
      final currentSizeBytes =
          PaintingBinding.instance.imageCache.currentSizeBytes;

      // GIF 로딩 전 메모리 사용량이 150MB를 초과하는 경우에만 정리
      if (currentSizeBytes > 150 * 1024 * 1024) {
        _clearPartialImageCache();

        logger.d(
          'GIF 로딩을 위한 부분 캐시 정리: ${currentSizeBytes ~/ (1024 * 1024)}MB → ${PaintingBinding.instance.imageCache.currentSizeBytes ~/ (1024 * 1024)}MB',
        );
      }
    } catch (e) {
      logger.e('GIF 로딩 준비 오류: $e');
    }
  }

  @override
  void didUpdateWidget(PicnicCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL이 변경된 경우에만 상태 재설정
    if (oldWidget.imageUrl != widget.imageUrl && mounted) {
      _lazyLoadTimer?.cancel();
      _retryTimer?.cancel(); // 이전 URL 로 예약된 재시도가 새 로드를 깨지 않도록
      // 인스턴스 고유 키를 쓰면서부터 Element 가 재사용되므로, URL 이 바뀌어도
      // VisibilityDetector 는 가시성 "변화" 가 없다고 보고 콜백을 다시 주지 않는다.
      // 아래에서 상태를 재설정하고, 이미 보이는 중이면 직접 로드를 재트리거한다.
      setState(() {
        // 이전 URL 로 계산된 변환 URL 캐시를 반드시 버려야 한다.
        // (버리지 않으면 재활용된 리스트 셀이 이전 후보 이미지를 계속 보여준다.)
        _cachedUrls = null;
        // cacheKey 에 섞이는 재시도 토큰도 새 URL 기준으로 초기화한다.
        _reloadToken = 0;
        _retryCount = 0;
        _loading = true;
        _hasError = false;
        _shouldLoadImage =
            widget.lazyLoadingStrategy == LazyLoadingStrategy.none;
        _isImageLoaded = false;
        _loadStartTime = null;
      });

      // 이미 화면에 보이는 상태에서 URL 만 바뀐 경우: 가시성 콜백이 다시 오지
      // 않으므로 직접 재트리거한다. (전역 슬롯 기계장치를 제거했으므로 여기서
      // 재트리거해도 카운터/큐 부작용이 없다.)
      if (!_shouldLoadImage && _isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_shouldLoadImage && _isVisible) {
            _triggerLazyLoad();
          }
        });
      }
    }
    // URL이 같다면 기존 상태 유지 (로딩 상태 초기화하지 않음)
  }

  /// 플레이스홀더 빌드
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder!,
      );
    }

    if (!widget.showLoadingOverlay) {
      return const SizedBox.shrink();
    }

    // Shimmer 로딩으로 변경
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: const Color.fromRGBO(158, 158, 158, 0.05),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 메인 위젯 빌드
  Widget _buildMainWidget() {
    final imageWidth = widget.width;
    final imageHeight = widget.height;
    // 최초 계산된 URL 고정 사용 (빌드마다 변하지 않도록)
    _cachedUrls ??= _getTransformedUrls(
      context,
      _capResolution(_getResolutionMultiplier(context)),
    );
    final urls = _cachedUrls!;
    final primaryUrl = urls.last;

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand, // Stack이 부모 크기에 맞춤
          children: [
            // 배경 컨테이너 (크기 고정)
            if (widget.showLoadingOverlay)
              Container(
                width: imageWidth,
                height: imageHeight,
                color: const Color.fromRGBO(158, 158, 158, 0.05),
              ),

            // 로딩 오버레이 (크기 제한)
            if (widget.showLoadingOverlay && !_isImageLoaded && !_hasError)
              SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: buildImageLoadingOverlay(),
              ),

            // 진보적 이미지 로딩 구현
            if (urls.length > 1 && !_hasError)
              _buildProgressiveImageStack(urls, imageWidth, imageHeight),

            // 단일 이미지 또는 최종 이미지
            if (urls.length == 1 || _hasError)
              _buildCachedNetworkImage(primaryUrl, imageWidth, imageHeight, 0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // C4: 빠른 플링 중이면 디코드/네트워크를 미루고 placeholder 만 그린다.
    //
    // recommendDeferredLoadingForContext 는 inherited 의존성을 **만들지
    // 않으므로**, 스크롤이 멎어도 이 위젯은 저절로 재빌드되지 않는다 — 재시도
    // 예약이 없으면 플링 중에 빌드된 아이템이 영구 placeholder 로 남는다
    // (테스트로 재현: 정지 후 2초가 지나도 복귀하지 않았다). Flutter 의
    // ScrollAwareImageProvider 가 같은 이유로 같은 패턴을 쓴다.
    if (widget.deferDuringFastScroll &&
        Scrollable.recommendDeferredLoadingForContext(context)) {
      _scheduleDeferredRetry();
      return _buildSafePlaceholder();
    }

    // Lazy Loading이 비활성화된 경우 바로 이미지 렌더링
    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildSafeMainWidget();
    }

    // 이미지 로드가 필요하지 않은 경우 플레이스홀더 표시
    if (!_shouldLoadImage) {
      return VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _onVisibilityChanged,
        child: _buildSafePlaceholder(),
      );
    }

    // 이미지 로드
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildSafeMainWidget(),
    );
  }

  /// C4 지연 중 다음 프레임에 재평가를 예약한다.
  ///
  /// 플링이 계속이면 다시 placeholder(값싼 경로)로 떨어지고, 멎었으면 실제
  /// 이미지로 전환된다. 프레임당 한 번만 예약되며, 지연 상태가 아니면 아무
  /// 비용도 없다.
  bool _deferredRetryScheduled = false;

  void _scheduleDeferredRetry() {
    if (_deferredRetryScheduled) return;
    _deferredRetryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredRetryScheduled = false;
      if (mounted) setState(() {});
    });
  }

  /// 안전한 플레이스홀더 빌드 (크기 보장)
  Widget _buildSafePlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth =
            widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
        final safeHeight =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 100.0);

        return SizedBox(
          width: safeWidth,
          height: safeHeight,
          child: _buildPlaceholder(),
        );
      },
    );
  }

  /// 안전한 메인 위젯 빌드 (크기 보장)
  Widget _buildSafeMainWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth =
            widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
        final safeHeight =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 100.0);

        return SizedBox(
          width: safeWidth,
          height: safeHeight,
          child: _buildMainWidget(),
        );
      },
    );
  }

  /// C3: 리스트 전용 dpr 상한 적용. 기본(null)이면 변형 없음.
  double _capResolution(double multiplier) {
    final cap = widget.maxResolutionMultiplierCap;
    if (cap == null) return multiplier;
    return math.min(multiplier, cap);
  }

  double _getResolutionMultiplier(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    if (UniversalPlatform.isAndroid) {
      return math.min(devicePixelRatio * 1.1, 2.5);
    }

    if (isIPad(context)) {
      return math.min(devicePixelRatio * 1.3, 4.0);
    }

    return math.min(devicePixelRatio * 1.2, 2.5);
  }

  // NOTE: 과거에는 "동시 로딩 수 > 최대치의 80%" 를 저대역폭 신호로 보고 해상도를
  // 낮추고(dpr 강등) 작은 이미지까지 3단계 progressive 로 전환했다. 그러나
  //   (1) 동시 로딩 수는 대역폭 지표가 아니다 — 리스트 화면에서 8개 이상이 동시에
  //       로딩되는 건 정상이며 항상 임계를 넘는다,
  //   (2) 결과가 _cachedUrls 에 `??=` 로 고정되어 이미지가 영구히 블러로 남고,
  //   (3) 3단계 전환은 혼잡한 상황에서 오히려 요청 수를 3배로 늘린다.
  // 신뢰할 수 있는 대역폭 신호가 없으므로 이 heuristic 을 제거했다.

  List<String> _getTransformedUrls(
    BuildContext context,
    double resolutionMultiplier,
  ) {
    final imageSize = _estimateImageComplexity();

    switch (imageSize) {
      case ImageComplexity.low:
        // C3: 리스트가 maxQualityOverride 를 넘기면 그 값을, 아니면 기존 85.
        return [
          _getTransformedUrl(
            widget.imageUrl,
            resolutionMultiplier,
            widget.maxQualityOverride ?? 85,
          ),
        ];
      case ImageComplexity.medium:
        return [
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.6, 40),
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 80),
        ];
      case ImageComplexity.high:
        return [
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.3, 25),
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.6, 50),
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 80),
        ];
    }
  }

  /// 이미지 복잡도를 추정합니다
  ImageComplexity _estimateImageComplexity() {
    final width = widget.width ?? 400;
    final height = widget.height ?? 400;
    final pixelCount = width * height;

    if (isGif) return ImageComplexity.high;

    if (pixelCount < 50000) return ImageComplexity.low;
    if (pixelCount < 200000) return ImageComplexity.medium;
    return ImageComplexity.high;
  }

  /// [uri] 의 호스트가 CDN(Environment.cdnUrl 파생) 호스트와 일치하는지 판정한다.
  ///
  /// Environment.cdnUrl 은 앱마다 경로를 포함할 수 있다
  /// (picnic_app `https://cdn.picnic.fan/picnic` vs ttja_app
  /// `https://cdn.picnic.fan/ttja`). 경로가 아니라 **호스트만** 비교한다 — 같은
  /// 호스트 뒤는 물리적으로 동일한 CloudFront + 커스텀 리사이저이므로 w/h/q 처리
  /// 방식이 경로와 무관하게 같다. 경로까지 일치를 요구하면(prefix 비교) 같은 CDN
  /// 호스트가 다른 스코프 경로로 절대 URL 을 내려줄 때 변환 대상에서 빠지는
  /// 오탐이 생긴다.
  ///
  /// Environment 가 아직 초기화되지 않았으면(runApp 이전 레이스, 또는 이 값을
  /// 세팅하지 않은 테스트) CDN 여부를 판정할 수 없으므로 안전하게 false 를
  /// 반환한다 — 어느 쪽인지 모를 때는 원본 URL 을 건드리지 않는 쪽이 안전하다.
  bool _isCdnUrl(Uri uri) {
    if (!Environment.isInitialized) return false;
    final cdnHost = Uri.parse(Environment.cdnUrl).host.toLowerCase();
    return uri.host.toLowerCase() == cdnHost;
  }

  /// CDN(cdn.picnic.fan, CloudFront + 커스텀 리사이저) 변환 URL을 만든다.
  ///
  /// 서버가 실제로 쓰는 파라미터는 w/h/q 뿐이다(2026-08-07 프로덕션 실측).
  /// dpr/fm/f/fl/auto/fit 은 캐시 키(`_w{w}_h{h}_f{format}_q{q}`)에 반영되지
  /// 않거나 응답에 아무 영향을 주지 않는다 — 특히 f/fm 은 WebPSupportChecker의
  /// Phase 2 비동기 초기화(runApp 이후 완료)에 좌우되어, 초기 프레임엔 f=jpg로
  /// 이후 재빌드에선 f=webp로 서로 다른 URL(=서로 다른 캐시 키)을 만들었고,
  /// 서버는 둘 다 같은 바이트를 주므로 동일 이미지를 두 번 받아 두 번 저장하는
  /// 결함이 있었다. w/h/q만 보내 이 결함을 없앤다.
  ///
  /// 이 변환은 **CDN 호스트로 스코프된다.** 상대 경로(Environment.cdnUrl 로
  /// 조립됨)와 호스트가 CDN 인 절대 URL 에만 w/h/q 를 적용한다. 그 외 절대
  /// URL(스플래시 서버가 내려주는 외부 이미지, YouTube 썸네일, 서명 URL 등)은
  /// 원본을 그대로 반환한다 — 쿼리를 보존하고 아무 파라미터도 추가하지 않는다.
  /// 예전에는 절대 URL이면 호스트를 가리지 않고 원래 쿼리를 통째로 w/h/q 로
  /// 갈아끼웠는데, 이는 CDN 도입 이전부터 있던 선재 결함이었다 — 서명 URL
  /// (`?X-Amz-Signature=`, `?token=` 등)이 들어오면 서명이 깨지고, 실제 외부
  /// CDN(Imgix/Cloudinary 등)이면 fit 등 원래 파라미터가 사라져 렌더링이
  /// 달라진다.
  String _getTransformedUrl(
    String key,
    double resolutionMultiplier,
    int quality,
  ) {
    final normalizedKey = key.trim();
    final isAbsolute =
        normalizedKey.startsWith('http://') ||
        normalizedKey.startsWith('https://');

    if (isAbsolute) {
      final uri = Uri.parse(normalizedKey);
      if (!_isCdnUrl(uri)) {
        return normalizedKey;
      }
      return _withCdnQuery(uri, resolutionMultiplier, quality).toString();
    }

    final uri = Uri.parse(
      '${Environment.cdnUrl}/${normalizedKey.startsWith('/') ? normalizedKey.substring(1) : normalizedKey}',
    );
    return _withCdnQuery(uri, resolutionMultiplier, quality).toString();
  }

  Uri _withCdnQuery(Uri uri, double resolutionMultiplier, int quality) {
    final Map<String, String> queryParameters = {'q': quality.toString()};

    final widgetWidth = widget.width;
    if (widgetWidth != null && widgetWidth.isFinite) {
      queryParameters['w'] = _roundPixels(
        widgetWidth,
        resolutionMultiplier,
      ).toString();
    }
    final widgetHeight = widget.height;
    if (widgetHeight != null && widgetHeight.isFinite) {
      queryParameters['h'] = _roundPixels(
        widgetHeight,
        resolutionMultiplier,
      ).toString();
    }

    return uri.replace(queryParameters: queryParameters);
  }

  /// 진보적 이미지 로딩 스택 구성
  Widget _buildProgressiveImageStack(
    List<String> urls,
    double? width,
    double? height,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: urls.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          final isLowQuality = index < urls.length - 1;

          return _buildProgressiveImage(
            url,
            width,
            height,
            index,
            isLowQuality: isLowQuality,
          );
        }).toList(),
      ),
    );
  }

  /// 진보적 로딩을 위한 개별 이미지 빌더
  Widget _buildProgressiveImage(
    String url,
    double? width,
    double? height,
    int index, {
    required bool isLowQuality,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: widget.fit,
      cacheManager: null,
      cacheKey: _cacheKeyFor(url, index: index, isLowQuality: isLowQuality),
      memCacheWidth: _computeCacheDimension(
        widget.memCacheWidth,
        width,
        isLowQuality ? 0.5 : 1.0,
      ),
      memCacheHeight: _computeCacheDimension(
        widget.memCacheHeight,
        height,
        isLowQuality ? 0.5 : 1.0,
      ),
      maxWidthDiskCache: isLowQuality ? 1000 : 2000,
      maxHeightDiskCache: isLowQuality ? 1000 : 2000,
      fadeInDuration: isLowQuality
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 300),
      fadeOutDuration: isLowQuality
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 100),
      placeholder: (context, url) {
        if (!widget.showLoadingOverlay) {
          return const SizedBox.shrink();
        }
        return index == 0
            ? buildImageLoadingOverlay()
            : const SizedBox.shrink();
      },
      errorWidget: (context, url, error) {
        if (!isLowQuality) {
          return _handleImageError(url, error, width, height);
        }
        return const SizedBox.shrink();
      },
      imageBuilder: (context, imageProvider) {
        if (!isLowQuality) {
          _onImageLoadSuccess(url);
        }

        final scrollAwareImageProvider = ScrollAwareImageProvider(
          context: _scrollAwareContext,
          imageProvider: imageProvider,
        );

        return AnimatedOpacity(
          duration: Duration(milliseconds: isLowQuality ? 100 : 300),
          opacity: 1.0,
          child: Image(
            image: scrollAwareImageProvider,
            fit: widget.fit,
            width: width,
            height: height,
          ),
        );
      },
    );
  }

  Widget _buildCachedNetworkImage(
    String url,
    double? width,
    double? height,
    int index,
  ) {
    try {
      Timer? timeoutTimer;

      return StatefulBuilder(
        builder: (context, setState) {
          if (_loading && timeoutTimer == null && !PicnicCachedNetworkImage.disableTimeoutForTest) {
            timeoutTimer = Timer(effectiveTimeout, () {
              if (!mounted) return;
              final stillLoading = _loading && !_hasError && !_isImageLoaded;
              if (!stillLoading) return;

              final now = DateTime.now();
              final lastLoggedAt = _lastTimeoutLogTimes[url];
              if (lastLoggedAt == null ||
                  now.difference(lastLoggedAt) >= _timeoutLogInterval) {
                _lastTimeoutLogTimes[url] = now;
                logger.w('이미지 로딩 타임아웃: $url');
              }

              logger.w('이미지 로딩 타임아웃 후 에러 처리: $url');
              _handleImageError(
                url,
                'Timeout after ${effectiveTimeout.inSeconds} seconds',
                width,
                height,
              );
            });
          }

          return CachedNetworkImage(
            key: ValueKey('${widget.imageUrl}_$_reloadToken'),
            imageUrl: url,
            width: width,
            height: height,
            fit: widget.fit,
            cacheManager: null,
            cacheKey: _cacheKeyFor(url),
            memCacheWidth: _computeCacheDimension(
              widget.memCacheWidth,
              width,
              1.0,
            ),
            memCacheHeight: _computeCacheDimension(
              widget.memCacheHeight,
              height,
              1.0,
            ),
            maxWidthDiskCache: 2000,
            maxHeightDiskCache: 2000,
            progressIndicatorBuilder: (context, url, progress) {
              // 진행률 표시기가 호출되면 로딩 중임을 나타냄
              if (!_loading && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _loading = true;
                      _isImageLoaded = false;
                      _loadStartTime ??= DateTime.now();
                    });
                  }
                });
              }

              // 진행률에 관계없이 항상 스켈레톤 표시
              if (!widget.showLoadingOverlay) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                width: width,
                height: height,
                child: buildImageLoadingOverlay(),
              );
            },
            errorWidget: (context, url, error) {
              timeoutTimer?.cancel();
              return _handleImageError(url, error, width, height);
            },
            imageBuilder: (context, imageProvider) {
              timeoutTimer?.cancel();

              // 이미지가 성공적으로 로드되면 즉시 로딩 상태 해제
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _loading = false;
                    _hasError = false;
                  });
                }
              });

              final scrollAwareImageProvider = ScrollAwareImageProvider(
                context: _scrollAwareContext,
                imageProvider: imageProvider,
              );

              _onImageLoadSuccess(url);
              _retryCount = 0;

              return Image(
                image: scrollAwareImageProvider,
                fit: widget.fit,
                width: width,
                height: height,
              );
            },
          );
        },
      );
    } catch (e, stack) {
      logger.e('이미지 로드 중 예외 발생: $e (URL: $url)');
      Sentry.captureException(e, stackTrace: stack);

      return _buildErrorWidget(width, height);
    }
  }

  // 이미지 로딩 에러 처리 및 재시도 로직
  Widget _handleImageError(
    String url,
    dynamic error,
    double? width,
    double? height,
  ) {
    logger.w('이미지 로딩 실패 감지: $url, error: $error');
    _recordFailure(url);

    if (_shouldRetry(url, error)) {
      logger.i('이미지 로드 재시도 준비: $url');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = false;
            _isImageLoaded = false;
          });
        }
      });
      _scheduleRetry(url);
      return widget.showLoadingOverlay
          ? buildImageLoadingOverlay()
          : const SizedBox.shrink();
    }

    _onImageLoadError(url, error);
    return _buildErrorWidget(width, height);
  }

  // 실패 기록
  void _recordFailure(String url) {
    final now = DateTime.now();
    _failureHistory[url] = (_failureHistory[url] ?? [])..add(now);

    _failureHistory[url]!.removeWhere(
      (time) => now.difference(time).inHours > 1,
    );
  }

  // 재시도 여부 결정
  bool _shouldRetry(String url, dynamic error) {
    if (_retryCount >= effectiveMaxRetries) return false;

    final errorString = error.toString().toLowerCase();
    // 더 포괄적인 재시도 가능한 에러 목록
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      'socket',
      'handshake',
      'host',
      'resolve', // DNS 해결 실패
      'unreachable', // 네트워크 도달 불가
      'interrupted', // 연결 중단
      'refused', // 연결 거부
      'reset', // 연결 재설정
      'dispose', // 디코드 중 리소스 해제
    ];

    final isRetryableError = retryableErrors.any(
      (keyword) => errorString.contains(keyword),
    );

    final recentFailures = _failureHistory[url]?.length ?? 0;

    // 더 관대한 재시도 조건 (기존 10회에서 15회로 증가)
    return isRetryableError && recentFailures < 15;
  }

  // 재시도 스케줄링
  void _scheduleRetry(String url) {
    _retryCount++;
    final delay = _calculateBackoffDelay(_retryCount);

    logger.i(
      '이미지 로드 재시도 예정: $url (시도: $_retryCount/$effectiveMaxRetries, 지연: ${delay.inSeconds}초)',
    );

    // 취소 가능한 Timer 를 쓴다. 예전에는 Future.delayed(취소 불가)라, URL 이
    // 교체되거나(dispose/didUpdateWidget) 원래 요청이 뒤늦게 성공한 뒤에도
    // 예약된 재시도가 발화해 _reloadToken 을 올리고 이미 표시된 이미지를 지웠다.
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _reloadToken++;
          logger.i('이미지 로드 재시도 시작: $url (토큰: $_reloadToken)');
          _loading = true;
          _hasError = false;
          _isImageLoaded = false;
          _loadStartTime = null;
          _shouldLoadImage = true;
        });
      }
    });
  }

  // 에러 위젯 생성
  Widget _buildErrorWidget(double? width, double? height) {
    if (widget.errorWidget != null) {
      return SizedBox(width: width, height: height, child: widget.errorWidget);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Column 크기 최소화
            children: [
              Icon(
                _retryCount >= effectiveMaxRetries
                    ? Icons.image_not_supported
                    : Icons.refresh,
                color: Colors.grey[600],
                size: math.min(width ?? 40, height ?? 40) * 0.3,
              ),
              if (_retryCount >= effectiveMaxRetries) ...[
                const SizedBox(height: 4),
                Text(
                  '이미지 로드 실패',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 메모리 압박 상황 체크
  Future<bool> _checkMemoryPressure() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      final currentSizeBytes = imageCache.currentSizeBytes;

      final usagePercentage = (currentSizeBytes / maxSizeBytes) * 100;

      return usagePercentage >= 90.0;
    } catch (e) {
      logger.e('메모리 압박 상황 체크 중 오류: $e');
      return false;
    }
  }

  bool _shouldLogMemoryPressure(DateTime now) {
    final lastLoggedAt = _lastMemoryPressureLog;
    if (lastLoggedAt == null ||
        now.difference(lastLoggedAt) >= _memoryPressureLogInterval) {
      _lastMemoryPressureLog = now;
      return true;
    }
    return false;
  }

  void _onImageLoadSuccess(String url) async {
    final loadDuration = _loadStartTime != null
        ? DateTime.now().difference(_loadStartTime!)
        : Duration.zero;
    _loadStartTime = null;
    _lastTimeoutLogTimes.remove(url);

    // 예약된 재시도가 남아 있으면 취소한다. (타임아웃 등으로 재시도를 예약해 둔 뒤
    // 원래 요청이 뒤늦게 성공하는 경우, 그대로 두면 재시도가 _reloadToken 을 올려
    // 방금 표시된 이미지를 지우고 처음부터 다시 받는다.)
    _retryTimer?.cancel();
    _retryTimer = null;

    // 성공적으로 로딩된 이미지 URL을 글로벌 Set에 추가
    // 다음 번 위젯 재생성 시 즉시 표시됨
    _successfullyLoadedImageUrls.add(widget.imageUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
          _isImageLoaded = true;
        });
      }
    });

    final warningThreshold = Environment.imageLoadWarningThreshold;
    final errorThreshold = Environment.imageLoadErrorThreshold;

    if (kDebugMode && loadDuration.inSeconds > warningThreshold) {
      // 메모리 스냅샷 최적화 - 더 엄격한 조건으로 제한
      if (loadDuration.inSeconds > errorThreshold &&
          loadDuration.inSeconds > 180) {
        final now = DateTime.now();
        final globalLastSnapshot = _lastGlobalSnapshot;

        // 전역적으로 스냅샷 생성 빈도 제한 (최대 15분에 1회)
        if (globalLastSnapshot == null ||
            now.difference(globalLastSnapshot).inMinutes >= 15) {
          final urlLastSnapshot = _lastSnapshotTimes[url];

          // 특정 URL에 대한 스냅샷 생성 빈도 제한 (최대 2시간에 1회)
          if (urlLastSnapshot == null ||
              now.difference(urlLastSnapshot).inHours >= 2) {
            final isMemoryPressured = await _checkMemoryPressure();

            if (!isMemoryPressured || loadDuration.inSeconds > 300) {
              _lastSnapshotTimes[url] = now;
              _lastGlobalSnapshot = now;
              _snapshotCount++;

              logger.i(
                '느린 이미지 로딩 감지됨 ($_snapshotCount번째): $url - ${loadDuration.inSeconds}초',
              );
            } else {
              if (_shouldLogMemoryPressure(now)) {
                logger.d('메모리 압박으로 로깅 건너뜀: $url');
              }
            }
          }
        }

        // 오래된 스냅샷 기록 정리 (4시간 이상)
        _lastSnapshotTimes.removeWhere(
          (key, time) => now.difference(time).inHours >= 4,
        );
      }
    }
  }

  void _onImageLoadError(String url, dynamic error) {
    logger.e('이미지 로드 에러: $url, error: $error');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _isImageLoaded = false;
        });
      }
    });

    _loadStartTime = null;

    if (kDebugMode) {
      // logger.throttledWarn('이미지 로딩 오류: $error (URL: $url)', errorKey);
    }
  }
}
