import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/services/animation_service.dart';
import 'animated_list_item.dart';

/// 스크롤 방향
enum ScrollDirection { forward, reverse, idle }

/// 리스트 아이템 상태
enum ListItemState { visible, cached, disposed }

/// 캐싱된 리스트 아이템 정보
class CachedListItem {
  final int index;
  final Widget widget;
  final DateTime cacheTime;
  final ListItemState state;
  final double? height;

  const CachedListItem({
    required this.index,
    required this.widget,
    required this.cacheTime,
    this.state = ListItemState.cached,
    this.height,
  });

  CachedListItem copyWith({
    int? index,
    Widget? widget,
    DateTime? cacheTime,
    ListItemState? state,
    double? height,
  }) {
    return CachedListItem(
      index: index ?? this.index,
      widget: widget ?? this.widget,
      cacheTime: cacheTime ?? this.cacheTime,
      state: state ?? this.state,
      height: height ?? this.height,
    );
  }
}

/// 리스트 성능 메트릭
class ListPerformanceMetrics {
  int visibleItemCount = 0;
  int cachedItemCount = 0;
  int totalItemsBuilt = 0;
  double averageBuildTime = 0.0;
  double scrollVelocity = 0.0;
  Duration lastFrameTime = Duration.zero;

  Map<String, dynamic> toJson() => {
    'visibleItemCount': visibleItemCount,
    'cachedItemCount': cachedItemCount,
    'totalItemsBuilt': totalItemsBuilt,
    'averageBuildTime': averageBuildTime,
    'scrollVelocity': scrollVelocity,
    'lastFrameTime': lastFrameTime.inMilliseconds,
  };
}

/// 최적화된 리스트 뷰 위젯
class OptimizedListView extends StatefulWidget {
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.enableCaching = true,
    this.maxCacheSize = 50,
    this.cacheTimeout = const Duration(minutes: 5),
    this.enablePagination = false,
    this.paginationThreshold = 5,
    this.onLoadMore,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.animationType = AnimationType.fadeIn,
    this.enableAnimation = true,
    this.enableKeepAlive = true,
    this.physics,
    this.controller,
    this.padding,
    this.reverse = false,
    this.enablePerformanceMetrics = false,
    this.onPerformanceUpdate,
    this.preloadDistance = 250.0,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool enableCaching;
  final int maxCacheSize;
  final Duration cacheTimeout;
  final bool enablePagination;
  final int paginationThreshold;
  final VoidCallback? onLoadMore;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final AnimationType animationType;
  final bool enableAnimation;
  final bool enableKeepAlive;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool reverse;
  final bool enablePerformanceMetrics;
  final ValueChanged<ListPerformanceMetrics>? onPerformanceUpdate;
  final double preloadDistance;

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController;
  final Map<int, CachedListItem> _itemCache = {};
  final Set<int> _visibleIndices = {};
  final Map<int, double> _itemHeights = {};
  
  bool _isLoading = false;
  Object? _error;
  ScrollDirection _currentDirection = ScrollDirection.idle;
  double _lastScrollOffset = 0.0;
  Timer? _cacheCleanupTimer;
  Timer? _performanceTimer;
  
  final ListPerformanceMetrics _metrics = ListPerformanceMetrics();
  final Stopwatch _buildStopwatch = Stopwatch();

  @override
  bool get wantKeepAlive => widget.enableKeepAlive;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _startCacheCleanup();
    _startPerformanceTracking();
  }

  void _initializeController() {
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _startCacheCleanup() {
    if (!widget.enableCaching) return;
    
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupCache(),
    );
  }

  void _startPerformanceTracking() {
    if (!widget.enablePerformanceMetrics) return;
    
    _performanceTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updatePerformanceMetrics(),
    );
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    
    // 스크롤 방향 업데이트
    if (delta > 0) {
      _currentDirection = ScrollDirection.forward;
    } else if (delta < 0) {
      _currentDirection = ScrollDirection.reverse;
    } else {
      _currentDirection = ScrollDirection.idle;
    }
    
    _lastScrollOffset = currentOffset;
    _metrics.scrollVelocity = delta.abs();

    // 페이지네이션 확인
    if (widget.enablePagination && !_isLoading) {
      _checkPagination();
    }

    // 가시 영역 아이템 추적
    _updateVisibleIndices();
  }

  void _checkPagination() {
    if (_scrollController.position.extentAfter < widget.preloadDistance) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || widget.onLoadMore == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100)); // 디바운스
      widget.onLoadMore?.call();
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateVisibleIndices() {
    if (!_scrollController.hasClients) return;
    
    final renderObject = context.findRenderObject() as RenderBox?;
    if (renderObject == null) return;
    
    final viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) return;
    
    final visibleRange = viewport.getOffsetToReveal(renderObject, 0.0);
    // 가시 영역 계산 로직 구현
    // 실제 구현에서는 더 정교한 가시성 계산이 필요
  }

  Widget _buildCachedItem(int index) {
    if (!widget.enableCaching) {
      return _buildItem(index);
    }

    final now = DateTime.now();
    final cached = _itemCache[index];
    
    // 캐시된 아이템이 있고 유효한 경우
    if (cached != null && 
        now.difference(cached.cacheTime) < widget.cacheTimeout) {
      return cached.widget;
    }

    // 새 아이템 빌드 및 캐시
    final newItem = _buildItem(index);
    _cacheItem(index, newItem);
    
    return newItem;
  }

  Widget _buildItem(int index) {
    _buildStopwatch.reset();
    _buildStopwatch.start();
    
    Widget item = widget.itemBuilder(context, index);
    
    // 애니메이션 적용
    if (widget.enableAnimation) {
      item = AnimatedListItem(
        index: index,
        animationType: widget.animationType,
        child: item,
      );
    }

    // Keep Alive 적용
    if (widget.enableKeepAlive) {
      item = _KeepAliveWrapper(child: item);
    }

    _buildStopwatch.stop();
    _metrics.totalItemsBuilt++;
    
    return RepaintBoundary(child: item);
  }

  void _cacheItem(int index, Widget item) {
    if (!widget.enableCaching) return;
    
    // 캐시 크기 제한
    if (_itemCache.length >= widget.maxCacheSize) {
      _evictOldestCacheItem();
    }
    
    _itemCache[index] = CachedListItem(
      index: index,
      widget: item,
      cacheTime: DateTime.now(),
    );
    
    _metrics.cachedItemCount = _itemCache.length;
  }

  void _evictOldestCacheItem() {
    if (_itemCache.isEmpty) return;
    
    DateTime oldest = DateTime.now();
    int? oldestIndex;
    
    for (final entry in _itemCache.entries) {
      if (entry.value.cacheTime.isBefore(oldest)) {
        oldest = entry.value.cacheTime;
        oldestIndex = entry.key;
      }
    }
    
    if (oldestIndex != null) {
      _itemCache.remove(oldestIndex);
    }
  }

  void _cleanupCache() {
    final now = DateTime.now();
    final expiredIndices = <int>[];
    
    for (final entry in _itemCache.entries) {
      if (now.difference(entry.value.cacheTime) > widget.cacheTimeout) {
        expiredIndices.add(entry.key);
      }
    }
    
    for (final index in expiredIndices) {
      _itemCache.remove(index);
    }
    
    _metrics.cachedItemCount = _itemCache.length;
  }

  void _updatePerformanceMetrics() {
    _metrics.visibleItemCount = _visibleIndices.length;
    _metrics.cachedItemCount = _itemCache.length;
    
    if (_metrics.totalItemsBuilt > 0) {
      _metrics.averageBuildTime = _buildStopwatch.elapsedMilliseconds / 
                                  _metrics.totalItemsBuilt;
    }
    
    widget.onPerformanceUpdate?.call(_metrics);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.itemCount == 0) {
      return widget.emptyBuilder?.call(context) ?? 
             const Center(child: Text('목록이 비어있습니다'));
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
             Center(child: Text('오류가 발생했습니다: $_error'));
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      reverse: widget.reverse,
      itemCount: widget.itemCount + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 로딩 인디케이터
        if (index == widget.itemCount) {
          return widget.loadingBuilder?.call(context) ??
                 const Center(
                   child: Padding(
                     padding: EdgeInsets.all(16.0),
                     child: CircularProgressIndicator(),
                   ),
                 );
        }
        
        return _buildCachedItem(index);
      },
    );
  }

  @override
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _performanceTimer?.cancel();
    
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    
    _itemCache.clear();
    super.dispose();
  }
}

/// Keep Alive 래퍼 위젯
class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});
  
  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 최적화된 그리드 뷰
class OptimizedGridView extends StatefulWidget {
  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.enableCaching = true,
    this.maxCacheSize = 30,
    this.animationType = AnimationType.scaleIn,
    this.enableAnimation = true,
    this.physics,
    this.controller,
    this.padding,
    this.enablePerformanceMetrics = false,
    this.onPerformanceUpdate,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool enableCaching;
  final int maxCacheSize;
  final AnimationType animationType;
  final bool enableAnimation;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool enablePerformanceMetrics;
  final ValueChanged<ListPerformanceMetrics>? onPerformanceUpdate;

  @override
  State<OptimizedGridView> createState() => _OptimizedGridViewState();
}

class _OptimizedGridViewState extends State<OptimizedGridView> {
  final Map<int, Widget> _itemCache = {};
  final ListPerformanceMetrics _metrics = ListPerformanceMetrics();

  Widget _buildCachedItem(int index) {
    if (!widget.enableCaching) {
      return _buildItem(index);
    }

    if (_itemCache.containsKey(index)) {
      return _itemCache[index]!;
    }

    final item = _buildItem(index);
    
    if (_itemCache.length >= widget.maxCacheSize) {
      _itemCache.remove(_itemCache.keys.first);
    }
    
    _itemCache[index] = item;
    _metrics.cachedItemCount = _itemCache.length;
    
    return item;
  }

  Widget _buildItem(int index) {
    Widget item = widget.itemBuilder(context, index);
    
    if (widget.enableAnimation) {
      item = AnimatedGridItem(
        index: index,
        columnCount: _getColumnCount(),
        animationType: widget.animationType,
        child: item,
      );
    }

    return RepaintBoundary(child: item);
  }

  int _getColumnCount() {
    if (widget.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
      return (widget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount;
    }
    return 2; // 기본값
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const Center(child: Text('항목이 없습니다'));
    }

    return GridView.builder(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _buildCachedItem(index),
    );
  }

  @override
  void dispose() {
    _itemCache.clear();
    super.dispose();
  }
}

/// 무한 스크롤 리스트 뷰
class InfiniteScrollListView extends StatefulWidget {
  const InfiniteScrollListView({
    super.key,
    required this.itemBuilder,
    required this.onLoadMore,
    this.initialItemCount = 20,
    this.loadingBuilder,
    this.errorBuilder,
    this.hasMore = true,
    this.animationType = AnimationType.slideInFromBottom,
    this.enableAnimation = true,
    this.threshold = 200.0,
  });

  final Widget Function(BuildContext context, int index) itemBuilder;
  final Future<List<dynamic>> Function(int offset, int limit) onLoadMore;
  final int initialItemCount;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final bool hasMore;
  final AnimationType animationType;
  final bool enableAnimation;
  final double threshold;

  @override
  State<InfiniteScrollListView> createState() => _InfiniteScrollListViewState();
}

class _InfiniteScrollListViewState extends State<InfiniteScrollListView> {
  final ScrollController _controller = ScrollController();
  final List<dynamic> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _loadInitialItems();
  }

  void _onScroll() {
    if (_controller.position.extentAfter < widget.threshold && 
        !_isLoading && 
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitialItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final newItems = await widget.onLoadMore(0, widget.initialItemCount);
      
      setState(() {
        _items.clear();
        _items.addAll(newItems);
        _hasMore = newItems.length == widget.initialItemCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final newItems = await widget.onLoadMore(_items.length, 20);
      
      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder?.call(context, _error!) ??
             Center(child: Text('오류가 발생했습니다: $_error'));
    }

    return RefreshIndicator(
      onRefresh: _loadInitialItems,
      child: ListView.builder(
        controller: _controller,
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return widget.loadingBuilder?.call(context) ??
                   const Center(
                     child: Padding(
                       padding: EdgeInsets.all(16.0),
                       child: CircularProgressIndicator(),
                     ),
                   );
          }

          Widget item = widget.itemBuilder(context, index);
          
          if (widget.enableAnimation) {
            item = AnimatedListItem(
              index: index,
              animationType: widget.animationType,
              child: item,
            );
          }

          return item;
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}