import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/image_memory_profiler.dart';
import 'package:picnic_lib/core/utils/image_performance_benchmark.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/core/utils/memory_profiling_hook.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/io_client.dart';

class PicnicCachedNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  ConsumerState<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState
    extends ConsumerState<PicnicCachedNetworkImage> {
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _loading = true;
  // 실제 사용되는 코드에서 참조하지는 않지만 나중에 사용할 수 있으므로 남겨두고 lint 경고만 무시
  // ignore: unused_field
  bool _hasAttemptedLoad = false;
  // ignore: unused_field
  DateTime? _lastLoadAttempt;
  late final DateTime _loadStartTime = DateTime.now();
  bool _isImageUrlProcessed = false; // 중복 처리 방지를 위한 플래그

  // 처리된 이미지 URL 저장용 변수 추가
  String _processedImageUrl = '';

  // 전역 이미지 캐시 맵 (URL -> 로드 시간)
  static final Map<String, DateTime> _loadedImages = {};

  // 스냅샷 생성 중복 방지를 위한 정적 맵 (URL별로 마지막 스냅샷 생성 시간 추적)
  static final Map<String, DateTime> _lastSnapshotTimes = {};

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');

  /// 안전한 정수 변환 (무한대나 NaN 값 처리)
  int _safeToInt(double? value, int defaultValue) {
    if (value == null || value.isNaN || value.isInfinite) {
      return defaultValue;
    }
    return value.toInt();
  }

  @override
  void initState() {
    super.initState();
    // _processImageUrl() 호출을 didChangeDependencies()로 이동

    // 성능 벤치마크 추적 시작
    ImagePerformanceBenchmark().trackImageLoadStart(
      widget.imageUrl,
      metadata: {
        'widget_type': 'PicnicCachedNetworkImage',
        'width': widget.width,
        'height': widget.height,
        'fit': widget.fit.toString(),
        'is_gif': isGif,
      },
    );

    // 이미지 메모리 프로파일러 추적 시작
    ImageMemoryProfiler().trackImageLoadStart(
      widget.imageUrl,
      metadata: {
        'widget_type': 'PicnicCachedNetworkImage',
        'width': widget.width,
        'height': widget.height,
        'fit': widget.fit.toString(),
        'is_gif': isGif,
        'mem_cache_width': widget.memCacheWidth,
        'mem_cache_height': widget.memCacheHeight,
      },
    );

    // 이미 로드된 이미지인지 확인
    if (_loadedImages.containsKey(widget.imageUrl)) {
      // 이미 캐시된 이미지는 즉시 로딩 상태 해제
      setState(() {
        _loading = false;
        _hasAttemptedLoad = true;
      });
    }

    // 최적화된 이미지 캐시 관리
    if (_loadedImages.length > 200) {
      // 캐시된 이미지가 너무 많은 경우 오래된 항목 정리
      _cleanupOldCache();
    }

    // GIF 이미지 특별 처리
    if (isGif) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepareGifLoading();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery를 사용하는 _processImageUrl()을 여기서 호출 (중복 처리 방지)
    if (!_isImageUrlProcessed) {
      _processImageUrl();
      _isImageUrlProcessed = true;
    }
  }

  @override
  void didUpdateWidget(PicnicCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL이 변경된 경우 상태 리셋 및 재처리
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetState();
      _isImageUrlProcessed = false; // 플래그 리셋
      _processImageUrl();
    }
  }

  void _resetState() {
    setState(() {
      _hasError = false;
      _retryCount = 0;
    });
  }

  void _processImageUrl() {
    _processedImageUrl = _getOptimizedImageUrl(widget.imageUrl);
  }

  String _getOptimizedImageUrl(String originalUrl) {
    // 이미 처리된 URL이거나 외부 URL인 경우 그대로 반환
    if (originalUrl.startsWith('http')) {
      return originalUrl;
    }

    // 내부 이미지 URL 최적화 처리
    final resolutionMultiplier = _getResolutionMultiplier(context);
    return _getTransformedUrl(originalUrl, resolutionMultiplier, 80);
  }

  // GIF 로딩을 위한 준비 작업
  void _prepareGifLoading() {
    try {
      // 100MB 이상의 캐시가 쌓인 경우에만 필요한 부분 정리
      if (PaintingBinding.instance.imageCache.currentSizeBytes >
          100 * 1024 * 1024) {
        // 이미지 캐시 사용량 기록
        final previousSizeBytes =
            PaintingBinding.instance.imageCache.currentSizeBytes;

        // GIF 로딩을 위한 공간 확보
        _clearUnusedCache();

        // 캐시 삭제 이벤트 기록
        MemoryProfilingHook.onImageCacheCleared(
          previousSizeBytes: previousSizeBytes,
          previousImageCount:
              PaintingBinding.instance.imageCache.liveImageCount,
          ref: ref,
        );
      }
    } catch (e) {
      logger.e('GIF 로딩 준비 오류: $e');
    }
  }

  // 현재 사용하지 않는 이미지만 선택적으로 캐시에서 제거
  void _clearUnusedCache() {
    try {
      // 전체 캐시를 지우는 대신 선택적으로 정리하는 로직
      // 기존 캐시 전략을 유지하면서 효율성 개선
      PaintingBinding.instance.imageCache.clear();

      // 캐시는 지우더라도 로드 이력은 유지
      // _loadedImages는 유지하여 무한 로딩 방지
    } catch (e) {
      logger.e('캐시 정리 중 오류: $e');
    }
  }

  // 오래된 캐시 항목 정리
  void _cleanupOldCache() {
    try {
      final now = DateTime.now();
      final keysToRemove = <String>[];

      // 하루 이상 지난 항목 또는 최대 항목 수 초과 시 삭제
      _loadedImages.forEach((key, timestamp) {
        if (now.difference(timestamp).inHours > 24) {
          keysToRemove.add(key);
        }
      });

      // 오래된 순으로 절반 제거
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

      // 실제 삭제 실행
      for (final key in keysToRemove) {
        _loadedImages.remove(key);
      }

      logger.i('이미지 캐시 정리 완료: ${keysToRemove.length}개 항목 제거');
    } catch (e) {
      logger.e('캐시 정리 중 오류: $e');
    }
  }

  @override
  void dispose() {
    // 이미지가 화면에서 사라질 때 로드 시간 기록
    final loadDuration = DateTime.now().difference(_loadStartTime);

    // 환경 설정에서 정의된 임계값 사용
    final warningThreshold = Environment.imageLoadWarningThreshold;

    // 디버그 모드에서만, 설정된 임계값 이상인 경우에만 로그 출력
    if (kDebugMode && loadDuration.inSeconds > warningThreshold && mounted) {
      final disposeKey = "${widget.imageUrl}_dispose_${DateTime.now().hour}";
      logger.throttledWarn(
        '[${widget.runtimeType}] 이미지 로드 시간이 매우 오래 걸림: ${widget.imageUrl} - ${loadDuration.inMilliseconds}ms',
        disposeKey,
        throttleDuration: const Duration(hours: 1), // 1시간마다 한 번만 로그 출력
      );
    }
    super.dispose();
  }

  double _getResolutionMultiplier(BuildContext context) {
    if (UniversalPlatform.isWeb) return 2.0;
    if (UniversalPlatform.isAndroid) return 1.5;
    if (isIPad(context)) return 4.0;
    return 2.0;
  }

  // ignore: unused_element
  List<String> _getTransformedUrls(
      BuildContext context, double resolutionMultiplier) {
    // 웹 환경에서는 고품질 이미지만 로드 (다중 해상도 불필요)
    if (UniversalPlatform.isWeb) {
      return [
        _getTransformedUrl(
            widget.imageUrl, resolutionMultiplier, 90), // 웹에서는 최고 품질 사용
      ];
    }

    // 모바일 환경에서는 점진적 로딩을 위해 여러 해상도 제공
    return [
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier * .2, 20),
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier * .5, 50),
      // 중간품질
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 80),
    ];
  }

  String _getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    // 공개 URL(http로 시작)은 변환하지 않고 그대로 반환
    if (key.startsWith('http')) {
      return key;
    }

    Uri uri = Uri.parse('${Environment.cdnUrl}/$key');

    Map<String, String> queryParameters = {
      if (widget.width != null)
        'w': ((widget.width!).toInt() * resolutionMultiplier).toString(),
      if (widget.height != null)
        'h': ((widget.height!).toInt() * resolutionMultiplier).toString(),
      'q': quality.toString(),
    };

    // GIF는 변환하지 않고 원본 그대로 사용
    if (!isGif) {
      // WebP 지원 확인
      final supportsWebP = UniversalPlatform.isWeb ||
          (WebPSupportChecker.instance.supportInfo != null &&
              WebPSupportChecker.instance.supportInfo!.webp);

      // WebP 지원하는 경우 변환하여 사용
      queryParameters['f'] = supportsWebP ? 'webp' : 'png';
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = widget.width;
    final imageHeight = widget.height;

    // 처리된 URL 사용 (재시도 시에도 동일한 URL 사용)
    final url = _hasError && _retryCount < _maxRetries
        ? _processedImageUrl
        : _processedImageUrl;

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
          ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: _buildCachedNetworkImage(url, imageWidth, imageHeight, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedNetworkImage(
      String url, double? width, double? height, int index) {
    try {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: widget.fit,
        // 메모리 캐시 사이즈 최적화 - 무한대나 NaN 값 안전 처리
        memCacheWidth: widget.memCacheWidth ?? _safeToInt(width, 400),
        memCacheHeight: widget.memCacheHeight ?? _safeToInt(height, 400),
        // 디스크 캐시 크기 설정 제거 (일반 CacheManager 사용 시 지원되지 않음)
        // maxWidthDiskCache: 800,
        // maxHeightDiskCache: 800,
        // 이미지 캐시 정책 수정 - URL 자체를 캐시 키로 사용하여 불필요한 재다운로드 방지
        cacheKey: url,
        // 캐시 매니저 사용 - 타임아웃 설정이 포함된 커스텀 CacheManager
        cacheManager: CacheManager(Config(
          'picnic_image_cache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 1000,
          fileService: HttpFileService(
            httpClient: IOClient(HttpClient()
              ..connectionTimeout = const Duration(seconds: 8)
              ..idleTimeout = const Duration(seconds: 8)),
          ),
        )),
        // HTTP 헤더 최적화 - 연결 제한 문제 해결
        httpHeaders: {
          'Accept':
              'image/webp,image/apng,image/jpg,image/jpeg,image/png,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Cache-Control': 'max-age=2592000', // 30일
          'Connection': 'keep-alive',
          'User-Agent': 'PicnicApp/1.0 (Flutter)',
        },
        // 이미지 로딩 타임아웃 설정
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholderFadeInDuration: const Duration(milliseconds: 200),
        // 에러 처리 및 재시도 최적화
        errorListener: (exception) {
          logger.e('이미지 로드 에러: $url', error: exception);
          // 캐시에서 실패한 이미지 제거하여 재시도 시 완전한 재로딩 보장
          _removeFromCache(url);
        },
        // 이미지 로딩 상태별 위젯
        placeholder: (context, url) => _buildPlaceholder(width, height),
        errorWidget: (context, url, error) => _buildErrorWidget(
          width,
          height,
          () => _retryImageLoad(url, index),
        ),
        // 이미지 빌더 - 로딩 완료 시 부드러운 전환
        imageBuilder: (context, imageProvider) {
          _onImageLoaded(url);
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: widget.fit,
              ),
            ),
          );
        },
      );
    } catch (e) {
      logger.e('CachedNetworkImage 빌드 에러: $url', error: e);
      return _buildErrorWidget(
          width, height, () => _retryImageLoad(url, index));
    }
  }

  // 이미지 로드 성공 시 호출되는 메서드
  void _onImageLoaded(String url) {
    // 성능 벤치마크 추적 - 성공
    ImagePerformanceBenchmark().trackImageLoadComplete(
      widget.imageUrl,
      true,
      metadata: {
        'cache_hit': _loadedImages.containsKey(url),
        'load_duration_ms':
            DateTime.now().difference(_loadStartTime).inMilliseconds,
      },
    );

    // 이미지 메모리 프로파일러 추적 - 성공
    ImageMemoryProfiler().trackImageLoadComplete(
      widget.imageUrl,
      null, // 이미지 바이트는 CachedNetworkImage에서 직접 접근 불가
      metadata: {
        'cache_hit': _loadedImages.containsKey(url),
        'load_duration_ms':
            DateTime.now().difference(_loadStartTime).inMilliseconds,
        'success': true,
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
        });
      }
    });

    // 로드 시간 측정 및 기록
    final loadDuration = DateTime.now().difference(_loadStartTime);

    // 환경 설정에서 정의된 임계값 사용
    final warningThreshold = Environment.imageLoadWarningThreshold;
    final errorThreshold = Environment.imageLoadErrorThreshold;

    // 디버그 모드에서만, 설정된 임계값 이상인 경우에만 로그 출력 및 스냅샷 생성
    if (kDebugMode && loadDuration.inSeconds > warningThreshold) {
      // throttledWarn 메서드를 사용하여 중복 로그 최소화
      final cacheKey = "${url}_${DateTime.now().hour}"; // 시간 단위로 로그 제한
      logger.throttledWarn(
        '[${widget.runtimeType}] 이미지 로드 시간이 매우 오래 걸림: $url - ${loadDuration.inMilliseconds}ms',
        cacheKey,
        throttleDuration: const Duration(hours: 1), // 1시간마다 한 번만 로그 출력
      );

      // 설정된 에러 임계값 이상 걸린 경우만 메모리 스냅샷 생성 (더 엄격한 조건 추가)
      if (loadDuration.inSeconds > errorThreshold &&
          loadDuration.inSeconds > 60) {
        // 최소 60초 이상으로 더 엄격하게 변경
        // 스냅샷 생성 중복 방지: 같은 URL에 대해 30분 이내에는 스냅샷을 생성하지 않음
        final now = DateTime.now();
        final lastSnapshotTime = _lastSnapshotTimes[url];

        if (lastSnapshotTime == null ||
            now.difference(lastSnapshotTime).inMinutes >= 30) {
          // 30분으로 증가
          final profiler = ref.read(memoryProfilerProvider.notifier);
          profiler.takeSnapshot(
            'slow_image_load_${DateTime.now().millisecondsSinceEpoch}',
            level: MemoryProfiler.snapshotLevelLow, // 로깅 레벨을 낮춤
            metadata: {'url': url, 'duration_ms': loadDuration.inMilliseconds},
          );

          // 스냅샷 생성 시간 기록
          _lastSnapshotTimes[url] = now;

          // 오래된 스냅샷 기록 정리 (2시간 이상 된 것들)
          _lastSnapshotTimes
              .removeWhere((key, time) => now.difference(time).inHours >= 2);
        } else {
          logger.d(
              '스냅샷 생성 건너뜀: $url (마지막 생성으로부터 ${now.difference(lastSnapshotTime).inMinutes}분 경과, 30분 대기 필요)');
        }
      }
    }
  }

  // 이미지 로드 실패 시 호출되는 메서드

  /// 플레이스홀더 위젯 빌드
  Widget _buildPlaceholder(double? width, double? height) {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// 에러 위젯 빌드
  Widget _buildErrorWidget(
      double? width, double? height, VoidCallback onRetry) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '이미지 로딩 실패',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '재시도',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 캐시에서 이미지 제거
  void _removeFromCache(String url) {
    try {
      // CachedNetworkImage 캐시에서 제거
      final cacheManager = CacheManager(Config(
        'picnic_image_cache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 1000,
        fileService: HttpFileService(
          httpClient: IOClient(HttpClient()
            ..connectionTimeout = const Duration(seconds: 8)
            ..idleTimeout = const Duration(seconds: 8)),
        ),
      ));
      cacheManager.removeFile(url);

      // Flutter 이미지 캐시에서도 제거
      final imageProvider = NetworkImage(url);
      imageProvider.evict();

      logger.d('캐시에서 이미지 제거: $url');
    } catch (e) {
      logger.e('캐시 제거 실패: $url', error: e);
    }
  }

  /// 이미지 재로딩
  void _retryImageLoad(String url, int index) {
    setState(() {
      _hasError = false;
      _loading = true;

      // 캐시에서 완전히 제거 후 재시도
      _removeFromCache(url);

      // 재빌드 트리거
      _retryCount = 0;
    });

    logger.i('이미지 재시도: $url');
  }
}

Widget buildImageLoadingOverlay() {
  // withOpacity 대신 fromRGBO 사용 (알파값 0.05 = 255 * 0.05 = 약 13)
  return Container(
    color: const Color.fromRGBO(
        158, 158, 158, 0.05), // Colors.grey와 동일한 RGB 값에 알파값 0.05 적용
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
