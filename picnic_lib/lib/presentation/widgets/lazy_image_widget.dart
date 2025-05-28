import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/image_memory_profiler.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

/// 레이지 로딩을 지원하는 이미지 위젯
/// 뷰포트에 들어올 때만 이미지를 로드하여 메모리 사용량을 최적화합니다.
class LazyImageWidget extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double threshold; // 뷰포트에 얼마나 들어와야 로드할지 (0.0 ~ 1.0)
  final bool enableLazyLoading; // 레이지 로딩 활성화 여부

  const LazyImageWidget({
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
    this.threshold = 0.1, // 10% 들어오면 로드 시작
    this.enableLazyLoading = true,
  });

  @override
  ConsumerState<LazyImageWidget> createState() => _LazyImageWidgetState();
}

class _LazyImageWidgetState extends ConsumerState<LazyImageWidget> {
  bool _isVisible = false;
  bool _hasStartedLoading = false;
  bool _shouldForceLoad = false;

  @override
  void initState() {
    super.initState();

    // 레이지 로딩이 비활성화된 경우 즉시 로드
    if (!widget.enableLazyLoading) {
      _isVisible = true;
      _hasStartedLoading = true;
      _shouldForceLoad = true;
    }
  }

  @override
  void didUpdateWidget(LazyImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // URL이 변경된 경우 상태 리셋
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetLoadingState();
    }

    // 레이지 로딩 설정이 변경된 경우
    if (oldWidget.enableLazyLoading != widget.enableLazyLoading) {
      if (!widget.enableLazyLoading && !_hasStartedLoading) {
        setState(() {
          _isVisible = true;
          _hasStartedLoading = true;
          _shouldForceLoad = true;
        });
      }
    }
  }

  void _resetLoadingState() {
    setState(() {
      _isVisible = !widget.enableLazyLoading;
      _hasStartedLoading = !widget.enableLazyLoading;
      _shouldForceLoad = !widget.enableLazyLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 레이지 로딩이 비활성화된 경우 또는 강제 로드인 경우 바로 이미지 표시
    if (!widget.enableLazyLoading || _shouldForceLoad) {
      return _buildImage();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _LazyLoadingDetector(
          threshold: widget.threshold,
          onVisibilityChanged: _onVisibilityChanged,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: _isVisible ? _buildImage() : _buildPlaceholder(),
          ),
        );
      },
    );
  }

  void _onVisibilityChanged(bool isVisible) {
    if (isVisible && !_hasStartedLoading) {
      setState(() {
        _isVisible = true;
        _hasStartedLoading = true;
      });

      logger.d('레이지 로딩 시작: ${widget.imageUrl}');

      // 이미지 메모리 프로파일러에 레이지 로딩 이벤트 추적
      ImageMemoryProfiler().trackImageLoadStart(
        widget.imageUrl,
        metadata: {
          'widget_type': 'LazyImageWidget',
          'lazy_loading': true,
          'threshold': widget.threshold,
          'width': widget.width,
          'height': widget.height,
          'fit': widget.fit.toString(),
        },
      );
    }
  }

  Widget _buildImage() {
    return PicnicCachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      borderRadius: widget.borderRadius,
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: widget.borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                color: Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                widget.enableLazyLoading ? '스크롤하여 로드' : '이미지 준비 중',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
  }
}

/// 뷰포트 교차 감지를 위한 위젯
class _LazyLoadingDetector extends StatefulWidget {
  final Widget child;
  final double threshold;
  final ValueChanged<bool> onVisibilityChanged;

  const _LazyLoadingDetector({
    required this.child,
    required this.threshold,
    required this.onVisibilityChanged,
  });

  @override
  State<_LazyLoadingDetector> createState() => _LazyLoadingDetectorState();
}

class _LazyLoadingDetectorState extends State<_LazyLoadingDetector> {
  bool _isVisible = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 초기화 후 가시성 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
      _isInitialized = true;
    });
  }

  @override
  void didUpdateWidget(_LazyLoadingDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때마다 가시성 재확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 스크롤 이벤트 발생 시 가시성 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkVisibility();
        });
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 레이아웃이 변경될 때마다 가시성 확인
          if (_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkVisibility();
            });
          }

          return widget.child;
        },
      ),
    );
  }

  void _checkVisibility() {
    if (!mounted) return;

    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) {
        // 렌더박스가 없거나 크기가 없는 경우 잠시 후 재시도
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _checkVisibility();
            });
          }
        });
        return;
      }

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // 화면 크기 가져오기
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return;

      final screenSize = mediaQuery.size;
      final viewPadding = mediaQuery.viewPadding;

      // 위젯의 경계 계산
      final widgetRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );

      // 실제 보이는 화면 영역 계산 (상태바, 네비게이션바 제외)
      final visibleScreenRect = Rect.fromLTWH(
        0,
        viewPadding.top,
        screenSize.width,
        screenSize.height - viewPadding.top - viewPadding.bottom,
      );

      // 교차 영역 계산
      final intersection = widgetRect.intersect(visibleScreenRect);
      final intersectionArea = intersection.width * intersection.height;
      final widgetArea = size.width * size.height;

      // 교차 비율 계산
      final intersectionRatio =
          widgetArea > 0 ? intersectionArea / widgetArea : 0.0;

      final isCurrentlyVisible = intersectionRatio >= widget.threshold;

      // 가시성 상태가 변경된 경우에만 콜백 호출
      if (isCurrentlyVisible != _isVisible) {
        _isVisible = isCurrentlyVisible;
        widget.onVisibilityChanged(_isVisible);

        // 디버그 정보 출력 (throttling 적용)
        if (_isVisible) {
          logger.throttledWarn(
            '이미지 가시성 감지: 교차비율 ${(intersectionRatio * 100).toStringAsFixed(1)}%',
            'image_visibility_detected',
            throttleDuration: const Duration(seconds: 30),
          );
        }
      }
    } catch (e) {
      logger.throttledWarn(
        '가시성 확인 중 오류: $e',
        'visibility_check_error',
        throttleDuration: const Duration(minutes: 5),
      );
    }
  }
}

/// 리스트뷰에서 사용할 수 있는 레이지 로딩 이미지 위젯
class LazyListImageWidget extends ConsumerWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final int index; // 리스트에서의 인덱스
  final int visibleRange; // 현재 보이는 아이템 범위

  const LazyListImageWidget({
    super.key,
    required this.imageUrl,
    required this.index,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
    this.visibleRange = 5, // 앞뒤 5개 아이템까지 미리 로드
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      borderRadius: borderRadius,
      placeholder: placeholder,
      threshold: 0.05, // 리스트에서는 더 빨리 로드
      enableLazyLoading: true,
    );
  }
}

/// 그리드뷰에서 사용할 수 있는 레이지 로딩 이미지 위젯
class LazyGridImageWidget extends ConsumerWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const LazyGridImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LazyImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      borderRadius: borderRadius,
      placeholder: placeholder,
      threshold: 0.2, // 그리드에서는 20% 보일 때 로드
      enableLazyLoading: true,
    );
  }
}
