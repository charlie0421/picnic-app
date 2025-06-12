import 'dart:async';
import 'dart:math' as math;

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
  });

  @override
  ConsumerState<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState
    extends ConsumerState<PicnicCachedNetworkImage> {
  bool _loading = true;
  bool _hasError = false;
  bool _shouldLoadImage = false; // Lazy Loading 제어
  bool _isVisible = false; // 가시성 상태
  late final DateTime _loadStartTime = DateTime.now();
  int _retryCount = 0;
  Timer? _lazyLoadTimer;

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _defaultMaxRetries = 3;
  static const Duration _maxBackoffDelay = Duration(seconds: 60);

  static final Map<String, DateTime> _loadedImages = {};
  static final Map<String, DateTime> _lastSnapshotTimes = {};
  static final Map<String, List<DateTime>> _failureHistory = {};

  // 전역 스냅샷 생성 기록 및 카운터
  static DateTime? _lastGlobalSnapshot;
  static int _snapshotCount = 0;

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');

  Duration get effectiveTimeout => widget.timeout ?? _defaultTimeout;
  int get effectiveMaxRetries => widget.maxRetries ?? _defaultMaxRetries;

  Duration _calculateBackoffDelay(int retryCount) {
    final baseDelay = Duration(milliseconds: 1000);
    final delay = Duration(
      milliseconds:
          (baseDelay.inMilliseconds * math.pow(2, retryCount)).toInt(),
    );
    return delay > _maxBackoffDelay ? _maxBackoffDelay : delay;
  }

  @override
  void initState() {
    super.initState();

    // Lazy Loading 전략에 따른 초기화
    _initializeLazyLoading();

    if (_loadedImages.containsKey(widget.imageUrl)) {
      setState(() {
        _loading = false;
      });
    }

    if (_loadedImages.length > 200) {
      _cleanupOldCache();
    }

    // 메모리 캐시 최적화
    _optimizeImageCache();

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
    // mounted 체크로 dispose된 위젯에서 setState 호출 방지
    if (!mounted) return;

    final isVisible = info.visibleFraction >= widget.visibilityThreshold;

    if (isVisible != _isVisible) {
      setState(() {
        _isVisible = isVisible;
      });

      if (isVisible && !_shouldLoadImage) {
        _triggerLazyLoad();
      }
    }
  }

  /// Lazy Loading 트리거
  void _triggerLazyLoad() {
    if (_shouldLoadImage || !mounted) return;

    final delay = widget.lazyLoadDelay ?? Duration.zero;

    if (delay > Duration.zero) {
      _lazyLoadTimer?.cancel();
      _lazyLoadTimer = Timer(delay, () {
        if (mounted && !_shouldLoadImage) {
          setState(() {
            _shouldLoadImage = true;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _shouldLoadImage = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _lazyLoadTimer?.cancel();

    final loadDuration = DateTime.now().difference(_loadStartTime);
    final warningThreshold = Environment.imageLoadWarningThreshold;

    if (kDebugMode && loadDuration.inSeconds > warningThreshold && mounted) {
      final disposeKey = "${widget.imageUrl}_dispose_${DateTime.now().hour}";
    }
    super.dispose();
  }

  // 전역 캐시 최적화 상태 추적
  static DateTime? _lastCacheOptimization;
  static const Duration _cacheOptimizationInterval = Duration(minutes: 5);

  /// 이미지 캐시 최적화 (개선된 버전)
  void _optimizeImageCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final now = DateTime.now();

      // 캐시 최적화 빈도 제한 (5분에 1회)
      if (_lastCacheOptimization != null &&
          now.difference(_lastCacheOptimization!).inMinutes < 5) {
        return;
      }

      // 플랫폼별 메모리 제한 설정 (모바일/데스크톱만)
      int maxSizeBytes;
      int maxSize;

      if (UniversalPlatform.isMobile) {
        // 모바일: 보수적인 메모리 사용
        maxSize = 100; // 최대 100개 이미지
        maxSizeBytes = 50 * 1024 * 1024; // 50MB
      } else {
        // 데스크톱: 더 많은 메모리 사용 가능
        maxSize = 200;
        maxSizeBytes = 200 * 1024 * 1024; // 200MB
      }

      // 캐시 제한 설정 (한 번만 설정)
      if (imageCache.maximumSizeBytes != maxSizeBytes) {
        imageCache.maximumSize = maxSize;
        imageCache.maximumSizeBytes = maxSizeBytes;
      }

      final currentSizeBytes = imageCache.currentSizeBytes;
      final currentSizeMB = currentSizeBytes ~/ (1024 * 1024);
      final maxSizeMB = maxSizeBytes ~/ (1024 * 1024);
      final thresholdBytes = (maxSizeBytes * 0.8).toInt();
      final thresholdMB = thresholdBytes ~/ (1024 * 1024);

      // 현재 캐시 크기가 제한을 초과하면 정리
      if (currentSizeBytes > thresholdBytes && currentSizeBytes > 0) {
        final beforeClearCount = imageCache.liveImageCount;
        imageCache.clear();
        _lastCacheOptimization = now;

        logger.i(
            '이미지 캐시 정리됨: ${currentSizeMB}MB/${maxSizeMB}MB (임계값: ${thresholdMB}MB), '
            '이미지 수: ${beforeClearCount}개 → 0개');
      }
    } catch (e) {
      logger.e('이미지 캐시 최적화 중 오류: $e');
    }
  }

  void _prepareGifLoading() {
    try {
      final currentSizeBytes =
          PaintingBinding.instance.imageCache.currentSizeBytes;
      final sizeMB = currentSizeBytes ~/ (1024 * 1024);

      // GIF 로딩 전 메모리 사용량이 100MB를 초과하는 경우에만 정리
      if (currentSizeBytes > 100 * 1024 * 1024) {
        final previousSizeBytes = currentSizeBytes;
        final previousImageCount =
            PaintingBinding.instance.imageCache.liveImageCount;

        _clearUnusedCache();

        logger.d(
            'GIF 로딩을 위한 캐시 정리: ${sizeMB}MB → 0MB, 이미지 수: ${previousImageCount}개 → 0개');

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

  void _clearUnusedCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
    } catch (e) {
      logger.e('캐시 정리 중 오류: $e');
    }
  }

  void _cleanupOldCache() {
    try {
      final now = DateTime.now();
      final keysToRemove = <String>[];

      _loadedImages.forEach((key, timestamp) {
        if (now.difference(timestamp).inHours > 24) {
          keysToRemove.add(key);
        }
      });

      if (keysToRemove.isEmpty && _loadedImages.length > 100) {
        final sortedEntries = _loadedImages.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        final removeCount = (_loadedImages.length / 2).round();
        for (var i = 0; i < removeCount; i++) {
          if (i < sortedEntries.length) {
            keysToRemove.add(sortedEntries[i].key);
          }
        }
      }

      for (final key in keysToRemove) {
        _loadedImages.remove(key);
      }

      // 로그 레벨을 debug로 변경하여 빈도 감소
      if (keysToRemove.isNotEmpty) {
        logger.d('이미지 캐시 정리 완료: ${keysToRemove.length}개 항목 제거');
      }
    } catch (e) {
      logger.e('캐시 정리 중 오류: $e');
    }
  }

  @override
  void didUpdateWidget(PicnicCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl && mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
        _shouldLoadImage =
            widget.lazyLoadingStrategy == LazyLoadingStrategy.none;
      });
    }
  }

  /// 플레이스홀더 위젯 빌드
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    // 기존 shimmer 로딩 오버레이 사용
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: buildImageLoadingOverlay(),
    );
  }

  /// 메인 위젯 빌드
  Widget _buildMainWidget() {
    final imageWidth = widget.width;
    final imageHeight = widget.height;
    final resolutionMultiplier = _getResolutionMultiplier(context);

    // 진보적 로딩을 위한 URL 목록 생성
    final urls = _getTransformedUrls(context, resolutionMultiplier);
    final primaryUrl = urls.last; // 최고 품질 URL

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_loading)
            ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: buildImageLoadingOverlay(),
            ),

          // 진보적 이미지 로딩 구현
          if (urls.length > 1 && !_hasError)
            _buildProgressiveImageStack(urls, imageWidth, imageHeight),

          // 단일 이미지 또는 최종 이미지
          if (urls.length == 1 || _hasError)
            ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: _buildCachedNetworkImage(
                  primaryUrl, imageWidth, imageHeight, 0),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lazy Loading이 비활성화된 경우 바로 이미지 렌더링
    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildMainWidget();
    }

    // 이미지 로드가 필요하지 않은 경우 플레이스홀더 표시
    if (!_shouldLoadImage) {
      return VisibilityDetector(
        key: Key('lazy_image_${widget.imageUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: _buildPlaceholder(),
      );
    }

    // 이미지 로드
    return VisibilityDetector(
      key: Key('lazy_image_${widget.imageUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildMainWidget(),
    );
  }

  double _getResolutionMultiplier(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    // 네트워크 상태에 따른 적응형 해상도 조정
    final isLowBandwidth = _isLowBandwidthConnection();

    if (UniversalPlatform.isAndroid) {
      return isLowBandwidth ? 1.0 : math.min(devicePixelRatio * 1.1, 2.5);
    }

    if (isIPad(context)) {
      return isLowBandwidth ? 2.0 : math.min(devicePixelRatio * 1.3, 4.0);
    }

    // iOS 및 기타 플랫폼
    return isLowBandwidth ? 1.2 : math.min(devicePixelRatio * 1.2, 2.5);
  }

  /// 저대역폭 연결 상태 확인
  bool _isLowBandwidthConnection() {
    // 실제 구현에서는 connectivity_plus나 network_info_plus를 사용
    // 현재는 기본값으로 false 반환 (향후 구현 예정)
    return false;
  }

  List<String> _getTransformedUrls(
      BuildContext context, double resolutionMultiplier) {
    final isLowBandwidth = _isLowBandwidthConnection();
    final imageSize = _estimateImageComplexity();

    // 모바일/데스크톱에서 적응형 로딩
    if (isLowBandwidth) {
      return [
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.4, 25),
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.8, 55),
        _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 75),
      ];
    }

    // 일반적인 경우 (이미지 복잡도에 따른 로딩)
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

    // GIF는 항상 높은 복잡도로 처리
    if (isGif) return ImageComplexity.high;

    // 픽셀 수에 따른 복잡도 분류
    if (pixelCount < 50000) return ImageComplexity.low; // ~224x224 미만
    if (pixelCount < 200000) return ImageComplexity.medium; // ~447x447 미만
    return ImageComplexity.high; // 그 이상
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

      // 최적화된 이미지 형식 선택 (모바일/데스크톱)
      if (supportsWebP) {
        queryParameters['f'] = 'webp';
      } else {
        queryParameters['f'] = 'jpg'; // PNG 대신 JPG로 기본값 설정 (더 작은 파일 크기)
      }

      // 추가 최적화 매개변수
      queryParameters.addAll({
        'fm': queryParameters['f']!, // 명시적 형식 지정
        'auto': 'compress,format', // 자동 압축 및 형식 최적화
        'fit': 'max', // 크기 제한 내에서 최대한 맞춤
        'dpr': resolutionMultiplier.toString(), // Device Pixel Ratio
      });

      // 프로그레시브 로딩 활성화 (JPEG용)
      if (queryParameters['f'] == 'jpg') {
        queryParameters['fl'] = 'progressive';
      }
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  /// 진보적 이미지 로딩 스택 구성
  Widget _buildProgressiveImageStack(
      List<String> urls, double? width, double? height) {
    return Stack(
      children: urls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;
        final isLowQuality = index < urls.length - 1;

        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: _buildProgressiveImage(
            url,
            width,
            height,
            index,
            isLowQuality: isLowQuality,
          ),
        );
      }).toList(),
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
      cacheManager: OptimizedCacheManager.instance,
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
          ? const Duration(milliseconds: 100) // 빠른 페이드인
          : const Duration(milliseconds: 300), // 일반 페이드인
      fadeOutDuration: isLowQuality
          ? const Duration(milliseconds: 200) // 빠른 페이드아웃
          : const Duration(milliseconds: 100), // 빠른 페이드아웃
      placeholder: (context, url) {
        // 첫 번째 이미지만 로딩 인디케이터 표시
        return index == 0
            ? buildImageLoadingOverlay()
            : const SizedBox.shrink();
      },
      errorWidget: (context, url, error) {
        // 마지막 이미지에서 에러 시에만 에러 위젯 표시
        if (!isLowQuality) {
          return _handleImageError(url, error, width, height);
        }
        return const SizedBox.shrink();
      },
      imageBuilder: (context, imageProvider) {
        if (!isLowQuality) {
          // 최고 품질 이미지 로드 완료
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
      // 타임아웃 타이머 시작
      Timer? timeoutTimer;

      return StatefulBuilder(
        builder: (context, setState) {
          if (_loading && timeoutTimer == null) {
            // 타임아웃 타이머 설정
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
            memCacheWidth: widget.memCacheWidth ?? (width?.toInt() ?? 400),
            memCacheHeight: widget.memCacheHeight ?? (height?.toInt() ?? 400),
            maxWidthDiskCache: 2000,
            maxHeightDiskCache: 2000,
            cacheKey: url,
            // 최적화된 캐시 관리자 사용
            cacheManager: OptimizedCacheManager.instance,
            progressIndicatorBuilder: (context, url, progress) {
              // 진행률 정보가 있으면 더 정확한 로딩 표시
              if (progress.totalSize != null) {
                final progressPercent =
                    progress.downloaded / progress.totalSize!;
                return Container(
                  color: const Color.fromRGBO(158, 158, 158, 0.05),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progressPercent,
                          strokeWidth: 2.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[400]!,
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
                );
              }
              return buildImageLoadingOverlay();
            },
            errorWidget: (context, url, error) {
              timeoutTimer?.cancel();
              return _handleImageError(url, error, width, height);
            },
            imageBuilder: (context, imageProvider) {
              timeoutTimer?.cancel();
              _onImageLoadSuccess(url);
              _retryCount = 0; // 성공 시 재시도 카운터 리셋

              if (!_loadedImages.containsKey(url)) {
                _loadedImages[url] = DateTime.now();
              }

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

    // 재시도 가능한 상황인지 확인
    if (_shouldRetry(url, error)) {
      _scheduleRetry(url);
      return buildImageLoadingOverlay(); // 재시도 중에는 로딩 표시
    }

    _onImageLoadError(url, error);
    return _buildErrorWidget(width, height);
  }

  // 실패 기록
  void _recordFailure(String url) {
    final now = DateTime.now();
    _failureHistory[url] = (_failureHistory[url] ?? [])..add(now);

    // 1시간 이상 된 실패 기록 정리
    _failureHistory[url]!.removeWhere(
      (time) => now.difference(time).inHours > 1,
    );
  }

  // 재시도 여부 결정
  bool _shouldRetry(String url, dynamic error) {
    if (_retryCount >= effectiveMaxRetries) return false;

    // 특정 에러 타입에 대해서만 재시도
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

    // 최근 1시간 내 같은 URL 실패 횟수 확인
    final recentFailures = _failureHistory[url]?.length ?? 0;

    return isRetryableError && recentFailures < 10; // 최대 10회까지만
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
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  /// 메모리 압박 상황 체크
  Future<bool> _checkMemoryPressure() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      final currentSizeBytes = imageCache.currentSizeBytes;

      // 메모리 사용량이 80% 이상이면 압박 상황으로 판단
      final usagePercentage = (currentSizeBytes / maxSizeBytes) * 100;

      return usagePercentage > 80.0;
    } catch (e) {
      logger.e('메모리 압박 상황 체크 중 오류: $e');
      return false; // 오류 시 안전하게 압박 없음으로 처리
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

    final loadDuration = DateTime.now().difference(_loadStartTime);

    final warningThreshold = Environment.imageLoadWarningThreshold;
    final errorThreshold = Environment.imageLoadErrorThreshold;

    if (kDebugMode && loadDuration.inSeconds > warningThreshold) {
      final cacheKey = "${url}_${DateTime.now().hour}";

      // 메모리 스냅샷 최적화 - 더 엄격한 조건으로 제한
      if (loadDuration.inSeconds > errorThreshold &&
          loadDuration.inSeconds > 120) {
        // 120초(2분) 이상일 때만
        final now = DateTime.now();
        final globalLastSnapshot = _lastGlobalSnapshot;

        // 전역적으로 스냅샷 생성 빈도 제한 (최대 10분에 1회)
        if (globalLastSnapshot == null ||
            now.difference(globalLastSnapshot).inMinutes >= 10) {
          final urlLastSnapshot = _lastSnapshotTimes[url];

          // 특정 URL에 대한 스냅샷 생성 빈도 제한 (최대 1시간에 1회)
          if (urlLastSnapshot == null ||
              now.difference(urlLastSnapshot).inHours >= 1) {
            // 메모리 압박 상황 체크
            final isMemoryPressured = await _checkMemoryPressure();

            if (!isMemoryPressured || loadDuration.inSeconds > 300) {
              // 5분 이상이면 메모리 압박 무시
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
          } else {
            logger.d(
                '스냅샷 생성 건너뜀: $url (URL별 제한 - 마지막 생성으로부터 ${now.difference(urlLastSnapshot).inMinutes}분 경과)');
          }
        } else {
          logger.d(
              '스냅샷 생성 건너뜀: 전역 제한 (마지막 생성으로부터 ${now.difference(globalLastSnapshot).inMinutes}분 경과)');
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

    if (kDebugMode) {
      final errorKey = "${url}_error_${DateTime.now().hour}";
      logger.throttledWarn('이미지 로딩 오류: $error (URL: $url)', errorKey);
    }
  }
}

Widget buildImageLoadingOverlay() {
  return Container(
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

    return AnimatedBuilder(
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
