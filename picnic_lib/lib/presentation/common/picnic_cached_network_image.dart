import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/core/utils/memory_profiling_hook.dart';
import 'package:picnic_lib/core/utils/optimized_cache_manager.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  final int? maxConcurrentLoads; // 최대 동시 로딩 수
  final bool useOptimizedCacheManager; // 최적화된 캐시 매니저 사용 여부

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
    this.enablePreloading = true,
    this.preloadDistance = 200.0,
    this.priority = ImagePriority.normal,
    this.enableMemoryOptimization = true,
    this.enableProgressiveLoading = true,
    this.maxConcurrentLoads,
    this.useOptimizedCacheManager = false, // 기본값은 false로 설정
  });

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
  late final DateTime _loadStartTime = DateTime.now();
  int _retryCount = 0;
  Timer? _lazyLoadTimer;

  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const int _defaultMaxRetries = 2;
  static const Duration _maxBackoffDelay = Duration(seconds: 30);

  // 동시 로딩 제어 (CachedNetworkImage와 별개로 앱 레벨에서 제어)
  static int _currentLoadingCount = 0;
  static const int _maxConcurrentLoads = 6;
  static final List<Completer<void>> _loadingQueue = [];

  // 성능 모니터링용 (CachedNetworkImage 캐시와는 별개)
  static final Map<String, DateTime> _lastSnapshotTimes = {};
  static final Map<String, List<DateTime>> _failureHistory = {};
  static DateTime? _lastGlobalSnapshot;
  static int _snapshotCount = 0;

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');
  bool get isLowBandwidth => _isLowBandwidthConnection();

  Duration get effectiveTimeout => widget.timeout ?? _defaultTimeout;
  int get effectiveMaxRetries => widget.maxRetries ?? _defaultMaxRetries;
  int get maxConcurrentLoads =>
      widget.maxConcurrentLoads ?? _maxConcurrentLoads;

  Duration _calculateBackoffDelay(int retryCount) {
    final baseDelay = Duration(milliseconds: 500);
    final delay = Duration(
      milliseconds:
          (baseDelay.inMilliseconds * math.pow(1.5, retryCount)).toInt(),
    );
    return delay > _maxBackoffDelay ? _maxBackoffDelay : delay;
  }

  @override
  void initState() {
    super.initState();

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
  }

  /// Lazy Loading 초기화
  void _initializeLazyLoading() {
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
  void _triggerLazyLoad() {
    if (_shouldLoadImage || !mounted) return;

    if (_currentLoadingCount >= maxConcurrentLoads) {
      _queueLoading();
      return;
    }

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

  /// 로딩 대기열에 추가
  void _queueLoading() {
    final completer = Completer<void>();
    _loadingQueue.add(completer);

    completer.future.then((_) {
      if (mounted && !_shouldLoadImage) {
        _startLoading();
      }
    });
  }

  /// 로딩 시작
  void _startLoading() {
    if (!mounted) return;

    _currentLoadingCount++;
    setState(() {
      _shouldLoadImage = true;
    });
  }

  /// 로딩 완료 처리
  void _onLoadingComplete() {
    _currentLoadingCount = math.max(0, _currentLoadingCount - 1);

    if (_loadingQueue.isNotEmpty) {
      final nextCompleter = _loadingQueue.removeAt(0);
      nextCompleter.complete();
    }
  }

  @override
  void dispose() {
    _lazyLoadTimer?.cancel();
    _onLoadingComplete();
    super.dispose();
  }

  // 전역 캐시 최적화 상태 추적
  static DateTime? _lastCacheOptimization;
  static const Duration _cacheOptimizationInterval = Duration(minutes: 10);

  /// Flutter ImageCache 설정 최적화
  static void _optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    if (kIsWeb) {
      // 웹에서는 더 보수적인 설정
      imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150MB
      imageCache.maximumSize = 300; // 최대 300개 이미지
    } else {
      // 모바일에서는 더 여유있는 설정
      imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200MB (기존 80MB에서 증가)
      imageCache.maximumSize = 500; // 최대 500개 이미지 (기존 300개에서 증가)
    }
  }

  /// 부분적 이미지 캐시 정리 (더 스마트한 정리)
  void _clearPartialImageCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final currentSizeBytes = imageCache.currentSizeBytes;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      final currentImageCount = imageCache.liveImageCount;

      // 85% 초과 시에만 정리 (기존 80%에서 상향)
      if (currentSizeBytes > maxSizeBytes * 0.85) {
        final previousSizeBytes = currentSizeBytes;
        final previousImageCount = currentImageCount;

        // 30%만 정리 (기존 100% 정리에서 개선)
        final targetSize = (maxSizeBytes * 0.6).round();
        imageCache.clear();

        // 새로운 임시 제한 설정으로 점진적 정리
        final originalMaxSize = imageCache.maximumSizeBytes;
        imageCache.maximumSizeBytes = targetSize;

        // 원래 제한으로 복구
        Future.delayed(Duration(milliseconds: 100), () {
          imageCache.maximumSizeBytes = originalMaxSize;
        });

        final newSizeBytes = imageCache.currentSizeBytes;
        final newImageCount = imageCache.liveImageCount;

        final previousSizeMB = previousSizeBytes ~/ (1024 * 1024);
        final newSizeMB = newSizeBytes ~/ (1024 * 1024);

        logger.d(
            '이미지 캐시 부분 정리됨: ${previousSizeMB}MB/${(maxSizeBytes ~/ (1024 * 1024))}MB → ${newSizeMB}MB, '
            '이미지 수: ${previousImageCount}개 → ${newImageCount}개');

        // 메모리 프로파일링 훅 호출
        MemoryProfilingHook.onImageCacheCleared(
          previousSizeBytes: previousSizeBytes,
          previousImageCount: previousImageCount,
          ref: ref,
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
        final previousSizeBytes = currentSizeBytes;
        final previousImageCount =
            PaintingBinding.instance.imageCache.liveImageCount;

        _clearPartialImageCache();

        logger.d(
            'GIF 로딩을 위한 부분 캐시 정리: ${currentSizeBytes ~/ (1024 * 1024)}MB → ${PaintingBinding.instance.imageCache.currentSizeBytes ~/ (1024 * 1024)}MB');

        MemoryProfilingHook.onImageCacheCleared(
          previousSizeBytes: previousSizeBytes,
          previousImageCount: previousImageCount,
          ref: ref,
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
      setState(() {
        _loading = true;
        _hasError = false;
        _shouldLoadImage =
            widget.lazyLoadingStrategy == LazyLoadingStrategy.none;
      });
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
          child: _ShimmerLoading(
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
    final resolutionMultiplier = _getResolutionMultiplier(context);

    // 진보적 로딩을 위한 URL 목록 생성
    final urls = _getTransformedUrls(context, resolutionMultiplier);
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
            Container(
              width: imageWidth,
              height: imageHeight,
              color: const Color.fromRGBO(158, 158, 158, 0.05),
            ),

            // 로딩 오버레이 (크기 제한)
            if (_loading)
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
    // Lazy Loading이 비활성화된 경우 바로 이미지 렌더링
    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildSafeMainWidget();
    }

    // 이미지 로드가 필요하지 않은 경우 플레이스홀더 표시
    if (!_shouldLoadImage) {
      return VisibilityDetector(
        key: Key('lazy_image_${widget.imageUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: _buildSafePlaceholder(),
      );
    }

    // 이미지 로드
    return VisibilityDetector(
      key: Key('lazy_image_${widget.imageUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildSafeMainWidget(),
    );
  }

  /// 안전한 플레이스홀더 빌드 (크기 보장)
  Widget _buildSafePlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
        final safeHeight = widget.height ??
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
        final safeWidth = widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
        final safeHeight = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 100.0);

        return SizedBox(
          width: safeWidth,
          height: safeHeight,
          child: _buildMainWidget(),
        );
      },
    );
  }

  double _getResolutionMultiplier(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    final isLowBandwidth = _isLowBandwidthConnection();

    if (UniversalPlatform.isAndroid) {
      return isLowBandwidth ? 1.0 : math.min(devicePixelRatio * 1.1, 2.5);
    }

    if (isIPad(context)) {
      return isLowBandwidth ? 2.0 : math.min(devicePixelRatio * 1.3, 4.0);
    }

    return isLowBandwidth ? 1.2 : math.min(devicePixelRatio * 1.2, 2.5);
  }

  /// 저대역폭 연결 상태 확인
  bool _isLowBandwidthConnection() {
    // 동시 로딩 수가 많으면 저대역폭으로 간주
    return _currentLoadingCount > maxConcurrentLoads * 0.8;
  }

  List<String> _getTransformedUrls(
      BuildContext context, double resolutionMultiplier) {
    final isLowBandwidth = _isLowBandwidthConnection();
    final imageSize = _estimateImageComplexity();

    if (isLowBandwidth) {
      return [
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.4, 25),
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.8, 55),
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 75),
      ];
    }

    switch (imageSize) {
      case ImageComplexity.low:
        return [
          _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 85),
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

  String _getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    Uri uri = Uri.parse('${Environment.cdnUrl}/$key');

    Map<String, String> queryParameters = {
      if (widget.width != null)
        'w': ((widget.width!).toInt() * resolutionMultiplier).toString(),
      if (widget.height != null)
        'h': ((widget.height!).toInt() * resolutionMultiplier).toString(),
      'q': quality.toString(),
    };

    if (!isGif) {
      final supportsWebP = WebPSupportChecker.instance.supportInfo != null &&
          WebPSupportChecker.instance.supportInfo!.webp;

      if (supportsWebP) {
        queryParameters['f'] = 'webp';
      } else {
        queryParameters['f'] = 'jpg';
      }

      queryParameters.addAll({
        'fm': queryParameters['f']!,
        'auto': 'compress,format',
        'fit': 'max',
        'dpr': resolutionMultiplier.toString(),
      });

      if (queryParameters['f'] == 'jpg') {
        queryParameters['fl'] = 'progressive';
      }
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  /// 진보적 이미지 로딩 스택 구성
  Widget _buildProgressiveImageStack(
      List<String> urls, double? width, double? height) {
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
      cacheManager: widget.useOptimizedCacheManager
          ? OptimizedCacheManager.instance
          : null,
      memCacheWidth: isLowQuality
          ? ((widget.memCacheWidth ?? (width?.toInt() ?? 400)) * 0.5).toInt()
          : (widget.memCacheWidth ?? (width?.toInt() ?? 400)),
      memCacheHeight: isLowQuality
          ? ((widget.memCacheHeight ?? (height?.toInt() ?? 400)) * 0.5).toInt()
          : (widget.memCacheHeight ?? (height?.toInt() ?? 400)),
      maxWidthDiskCache: isLowQuality ? 1000 : 2000,
      maxHeightDiskCache: isLowQuality ? 1000 : 2000,
      cacheKey: url,
      fadeInDuration: isLowQuality
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 300),
      fadeOutDuration: isLowQuality
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 100),
      placeholder: (context, url) {
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

        return AnimatedOpacity(
          duration: Duration(milliseconds: isLowQuality ? 100 : 300),
          opacity: 1.0,
          child: Image(
            image: imageProvider,
            fit: widget.fit,
            width: width,
            height: height,
          ),
        );
      },
    );
  }

  Widget _buildCachedNetworkImage(
      String url, double? width, double? height, int index) {
    try {
      Timer? timeoutTimer;

      return StatefulBuilder(
        builder: (context, setState) {
          if (_loading && timeoutTimer == null) {
            timeoutTimer = Timer(effectiveTimeout, () {
              if (mounted && _loading) {
                logger.w('이미지 로딩 타임아웃: $url');
                _handleImageError(
                    url,
                    'Timeout after ${effectiveTimeout.inSeconds} seconds',
                    width,
                    height);
              }
            });
          }

          return CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: widget.fit,
            cacheManager: widget.useOptimizedCacheManager
                ? OptimizedCacheManager.instance
                : null,
            memCacheWidth: widget.memCacheWidth ?? (width?.toInt() ?? 400),
            memCacheHeight: widget.memCacheHeight ?? (height?.toInt() ?? 400),
            maxWidthDiskCache: 2000,
            maxHeightDiskCache: 2000,
            cacheKey: url,
            progressIndicatorBuilder: (context, url, progress) {
              // 진행률 표시기가 호출되면 로딩 중임을 나타냄
              if (!_loading && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _loading = true;
                    });
                  }
                });
              }

              if (progress.totalSize != null) {
                final progressPercent =
                    progress.downloaded / progress.totalSize!;
                return SizedBox(
                  width: width,
                  height: height,
                  child: Container(
                    color: const Color.fromRGBO(158, 158, 158, 0.05),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Column 크기 최소화
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: progressPercent,
                              strokeWidth: 2.0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[400]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progressPercent * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
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

              _onImageLoadSuccess(url);
              _retryCount = 0;

              return Image(
                image: imageProvider,
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
      String url, dynamic error, double? width, double? height) {
    _recordFailure(url);

    if (_shouldRetry(url, error)) {
      _scheduleRetry(url);
      return buildImageLoadingOverlay();
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
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      'socket',
      'handshake',
      'host',
    ];

    final isRetryableError = retryableErrors.any(
      (keyword) => errorString.contains(keyword),
    );

    final recentFailures = _failureHistory[url]?.length ?? 0;

    return isRetryableError && recentFailures < 10;
  }

  // 재시도 스케줄링
  void _scheduleRetry(String url) {
    _retryCount++;
    final delay = _calculateBackoffDelay(_retryCount);

    logger.i(
        '이미지 로드 재시도 예정: $url (시도: $_retryCount/$effectiveMaxRetries, 지연: ${delay.inSeconds}초)');

    Future.delayed(delay, () {
      if (mounted) {
        setState(() {
          _loading = true;
          _hasError = false;
        });
      }
    });
  }

  // 에러 위젯 생성
  Widget _buildErrorWidget(double? width, double? height) {
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
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

      return usagePercentage > 80.0;
    } catch (e) {
      logger.e('메모리 압박 상황 체크 중 오류: $e');
      return false;
    }
  }

  void _onImageLoadSuccess(String url) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
        });
      }
    });

    _onLoadingComplete();

    final loadDuration = DateTime.now().difference(_loadStartTime);

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
              final profiler = ref.read(memoryProfilerProvider.notifier);
              profiler.takeSnapshot(
                'slow_image_load_${DateTime.now().millisecondsSinceEpoch}',
                level: MemoryProfiler.snapshotLevelLow,
                metadata: {
                  'url': url,
                  'duration_ms': loadDuration.inMilliseconds,
                  'retry_count': _retryCount,
                  'memory_pressured': isMemoryPressured,
                },
              );

              _lastSnapshotTimes[url] = now;
              _lastGlobalSnapshot = now;
              _snapshotCount++;

              logger.i(
                  '메모리 스냅샷 생성됨 ($_snapshotCount번째): $url - ${loadDuration.inSeconds}초');
            } else {
              logger.d('메모리 압박으로 스냅샷 생성 건너뜀: $url');
            }
          }
        }

        // 오래된 스냅샷 기록 정리 (4시간 이상)
        _lastSnapshotTimes
            .removeWhere((key, time) => now.difference(time).inHours >= 4);
      }
    }
  }

  void _onImageLoadError(String url, dynamic error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    });

    _onLoadingComplete();

    if (kDebugMode) {
      final errorKey = "${url}_error_${DateTime.now().hour}";
      logger.throttledWarn('이미지 로딩 오류: $error (URL: $url)', errorKey);
    }
  }
}

Widget buildImageLoadingOverlay() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: const Color.fromRGBO(158, 158, 158, 0.05),
    child: _ShimmerLoading(
      isLoading: true,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    ),
  );
}

class _ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const _ShimmerLoading({
    required this.isLoading,
    required this.child,
  });

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Color(0xFFEBEBF4),
                  Color(0xFFF4F4F4),
                  Color(0xFFEBEBF4),
                ],
                stops: const [0.1, 0.3, 0.4],
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                tileMode: TileMode.clamp,
                transform: _SlidingGradientTransform(
                  slidePercent: _animation.value,
                ),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
