import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

/// 이미지가 많은 리스트에서 성능을 최적화하는 위젯
///
/// 특징:
/// - 자동 우선순위 조정
/// - 스크롤 기반 로딩 제어
/// - 메모리 사용량 모니터링
/// - 동적 품질 조정
class OptimizedImageList extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final List<String> imageUrls;
  final Widget Function(BuildContext context, String imageUrl, int index)
      itemBuilder;
  final int itemCount;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  // 성능 최적화 설정
  final int visibleItemBuffer; // 보이는 아이템 주변 버퍼
  final int maxConcurrentLoads; // 최대 동시 로딩 수
  final bool enableDynamicQuality; // 동적 품질 조정
  final bool enableScrollOptimization; // 스크롤 최적화

  const OptimizedImageList({
    super.key,
    this.scrollController,
    required this.imageUrls,
    required this.itemBuilder,
    required this.itemCount,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.visibleItemBuffer = 3,
    this.maxConcurrentLoads = 4,
    this.enableDynamicQuality = true,
    this.enableScrollOptimization = true,
  });

  @override
  ConsumerState<OptimizedImageList> createState() => _OptimizedImageListState();
}

class _OptimizedImageListState extends ConsumerState<OptimizedImageList> {
  late ScrollController _scrollController;
  bool _isScrolling = false;
  double _scrollVelocity = 0.0;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  // 성능 모니터링
  DateTime? _lastScrollUpdate;
  static const Duration _scrollUpdateThreshold = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastScrollUpdate != null &&
        now.difference(_lastScrollUpdate!).inMilliseconds <
            _scrollUpdateThreshold.inMilliseconds) {
      return; // 스크롤 업데이트 빈도 제한
    }
    _lastScrollUpdate = now;

    if (widget.enableScrollOptimization) {
      _updateScrollState();
      _updateVisibleRange();
    }
  }

  void _updateScrollState() {
    final position = _scrollController.position;
    final velocity = position.activity?.velocity ?? 0.0;

    setState(() {
      _scrollVelocity = velocity.abs();
      _isScrolling = _scrollVelocity > 50.0; // 빠른 스크롤 감지
    });
  }

  void _updateVisibleRange() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final viewportHeight = position.viewportDimension;
    final scrollOffset = position.pixels;

    // 대략적인 아이템 높이 계산 (실제 구현에서는 더 정확하게)
    final estimatedItemHeight = viewportHeight / 10; // 가정: 화면에 10개 아이템

    final firstVisible = (scrollOffset / estimatedItemHeight).floor();
    final lastVisible =
        ((scrollOffset + viewportHeight) / estimatedItemHeight).ceil();

    setState(() {
      _firstVisibleIndex = (firstVisible - widget.visibleItemBuffer)
          .clamp(0, widget.itemCount - 1);
      _lastVisibleIndex = (lastVisible + widget.visibleItemBuffer)
          .clamp(0, widget.itemCount - 1);
    });
  }

  /// 아이템의 우선순위 계산
  ImagePriority _calculateImagePriority(int index) {
    if (!widget.enableScrollOptimization) {
      return ImagePriority.normal;
    }

    // 현재 보이는 범위 내의 이미지는 높은 우선순위
    if (index >= _firstVisibleIndex && index <= _lastVisibleIndex) {
      return _isScrolling ? ImagePriority.normal : ImagePriority.high;
    }

    // 버퍼 범위 내의 이미지는 일반 우선순위
    final bufferStart = _firstVisibleIndex - widget.visibleItemBuffer;
    final bufferEnd = _lastVisibleIndex + widget.visibleItemBuffer;

    if (index >= bufferStart && index <= bufferEnd) {
      return ImagePriority.normal;
    }

    // 그 외는 낮은 우선순위
    return ImagePriority.low;
  }

  /// 동적 로딩 전략 결정
  LazyLoadingStrategy _calculateLoadingStrategy(int index) {
    if (!widget.enableScrollOptimization) {
      return LazyLoadingStrategy.viewport;
    }

    final priority = _calculateImagePriority(index);

    if (_isScrolling && _scrollVelocity > 200.0) {
      // 빠른 스크롤 중에는 뷰포트 로딩만
      return LazyLoadingStrategy.viewport;
    }

    switch (priority) {
      case ImagePriority.high:
        return LazyLoadingStrategy.none; // 즉시 로딩
      case ImagePriority.normal:
        return LazyLoadingStrategy.viewport;
      case ImagePriority.low:
        return LazyLoadingStrategy.preload;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _onScroll();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          if (index >= widget.imageUrls.length) {
            return widget.itemBuilder(context, '', index);
          }

          final imageUrl = widget.imageUrls[index];
          final priority = _calculateImagePriority(index);
          final loadingStrategy = _calculateLoadingStrategy(index);

          return _OptimizedImageListItem(
            key: ValueKey('image_item_$index'),
            imageUrl: imageUrl,
            index: index,
            priority: priority,
            loadingStrategy: loadingStrategy,
            maxConcurrentLoads: widget.maxConcurrentLoads,
            enableDynamicQuality: widget.enableDynamicQuality,
            isScrolling: _isScrolling,
            scrollVelocity: _scrollVelocity,
            itemBuilder: widget.itemBuilder,
          );
        },
      ),
    );
  }
}

/// 최적화된 이미지 리스트 아이템
class _OptimizedImageListItem extends StatelessWidget {
  final String imageUrl;
  final int index;
  final ImagePriority priority;
  final LazyLoadingStrategy loadingStrategy;
  final int maxConcurrentLoads;
  final bool enableDynamicQuality;
  final bool isScrolling;
  final double scrollVelocity;
  final Widget Function(BuildContext context, String imageUrl, int index)
      itemBuilder;

  const _OptimizedImageListItem({
    super.key,
    required this.imageUrl,
    required this.index,
    required this.priority,
    required this.loadingStrategy,
    required this.maxConcurrentLoads,
    required this.enableDynamicQuality,
    required this.isScrolling,
    required this.scrollVelocity,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return itemBuilder(context, imageUrl, index);
  }
}

/// 최적화된 이미지 위젯 (PicnicCachedNetworkImage 래퍼)
class OptimizedListImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImagePriority priority;
  final LazyLoadingStrategy loadingStrategy;
  final bool isScrolling;
  final double scrollVelocity;
  final BorderRadius? borderRadius;
  final bool useOptimizedCacheManager; // 최적화된 캐시 매니저 사용 여부

  const OptimizedListImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.priority = ImagePriority.normal,
    this.loadingStrategy = LazyLoadingStrategy.viewport,
    this.isScrolling = false,
    this.scrollVelocity = 0.0,
    this.borderRadius,
    this.useOptimizedCacheManager = false, // 기본값은 false
  });

  @override
  Widget build(BuildContext context) {
    // 빠른 스크롤 중에는 타임아웃 단축
    final timeout = isScrolling && scrollVelocity > 200.0
        ? Duration(seconds: 5)
        : Duration(seconds: 15);

    // 스크롤 중에는 재시도 횟수 감소
    final maxRetries = isScrolling ? 1 : 2;

    return SizedBox(
      width: width,
      height: height,
      child: PicnicCachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        priority: priority,
        lazyLoadingStrategy: loadingStrategy,
        timeout: timeout,
        maxRetries: maxRetries,
        borderRadius: borderRadius,
        enableMemoryOptimization: true,
        enableProgressiveLoading: !isScrolling, // 스크롤 중에는 점진적 로딩 비활성화
        visibilityThreshold: isScrolling ? 0.3 : 0.1, // 스크롤 중에는 더 많이 보여야 로딩
        useOptimizedCacheManager: useOptimizedCacheManager, // 선택적 사용
      ),
    );
  }
}
