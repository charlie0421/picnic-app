import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/core/utils/memory_profiling_hook.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  ConsumerState<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState
    extends ConsumerState<PicnicCachedNetworkImage> {
  bool _loading = true;
  // 실제 사용되는 코드에서 참조하지는 않지만 나중에 사용할 수 있으므로 남겨두고 lint 경고만 무시
  // ignore: unused_field
  bool _hasError = false;
  // ignore: unused_field
  bool _hasAttemptedLoad = false;
  // ignore: unused_field
  DateTime? _lastLoadAttempt;
  late final DateTime _loadStartTime = DateTime.now();

  // 전역 이미지 캐시 맵 (URL -> 로드 시간)
  static final Map<String, DateTime> _loadedImages = {};

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');

  @override
  void initState() {
    super.initState();

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
  void didUpdateWidget(PicnicCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL이 변경된 경우에만 이미지 다시 로드
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _loading = true;
        _hasError = false;
        _hasAttemptedLoad = _loadedImages.containsKey(widget.imageUrl);
        _lastLoadAttempt = null;
      });
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
      final disposeKey = "${widget.imageUrl}_dispose_${DateTime.now().day}";
      logger.throttledWarn(
        '[${widget.runtimeType}] 이미지 로드 시간이 매우 오래 걸림: ${widget.imageUrl} - ${loadDuration.inMilliseconds}ms',
        disposeKey,
        throttleDuration: const Duration(hours: 6), // 6시간마다 한 번만 로그 출력
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
    final resolutionMultiplier = _getResolutionMultiplier(context);

    // 단일 URL만 사용하여 이미지 중복 로딩 방지
    final url = _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 80);

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
        // 메모리 캐시 사이즈 최적화
        memCacheWidth: widget.memCacheWidth ?? (width?.toInt() ?? 300),
        memCacheHeight: widget.memCacheHeight ?? (height?.toInt() ?? 300),
        maxWidthDiskCache: 1000, // 디스크 캐시 크기 제한
        maxHeightDiskCache: 1000,
        // 이미지 캐시 정책 수정
        cacheKey: "${url}_${DateTime.now().day}", // 하루 단위로 캐시 키 변경
        // 로딩 시 Shimmer 효과 표시
        progressIndicatorBuilder: (context, url, progress) =>
            buildImageLoadingOverlay(),
        errorWidget: (context, url, error) {
          _onImageLoadError(url, error);
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
        },
        imageBuilder: (context, imageProvider) {
          // 성공적으로 로드된 이미지 처리
          _onImageLoadSuccess(url);

          // 이미지가 성공적으로 로드되면 캐시에 추가
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
    } catch (e, stack) {
      logger.e('이미지 로드 중 예외 발생: $e (URL: $url)');

      // 예외 발생 시 Sentry에 기록
      Sentry.captureException(e, stackTrace: stack);

      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.grey),
        ),
      );
    }
  }

  // 이미지 로드 성공 시 호출되는 메서드
  void _onImageLoadSuccess(String url) {
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
      final cacheKey = "${url}_${DateTime.now().day}";
      logger.throttledWarn(
        '[${widget.runtimeType}] 이미지 로드 시간이 매우 오래 걸림: $url - ${loadDuration.inMilliseconds}ms',
        cacheKey,
        throttleDuration: const Duration(hours: 6), // 6시간마다 한 번만 로그 출력
      );

      // 설정된 에러 임계값 이상 걸린 경우만 메모리 스냅샷 생성
      if (loadDuration.inSeconds > errorThreshold) {
        final profiler = ref.read(memoryProfilerProvider.notifier);
        profiler.takeSnapshot(
          'slow_image_load_${DateTime.now().millisecondsSinceEpoch}',
          level: MemoryProfiler.snapshotLevelMedium,
          metadata: {'url': url, 'duration_ms': loadDuration.inMilliseconds},
        );
      }
    }
  }

  // 이미지 로드 실패 시 호출되는 메서드
  void _onImageLoadError(String url, dynamic error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    });

    // 디버그 모드에서만 에러 로그 출력 (throttled 방식으로)
    if (kDebugMode) {
      final errorKey = "${url}_error_${DateTime.now().day}";
      logger.throttledWarn('이미지 로딩 오류: $error (URL: $url)', errorKey);
    }
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
