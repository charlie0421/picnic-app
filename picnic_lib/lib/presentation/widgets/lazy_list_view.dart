import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 지연 로딩을 지원하는 ListView
///
/// 가시성에 따라 아이템을 동적으로 로드하여 메모리 사용량과
/// 초기 로딩 시간을 최적화합니다.
class LazyListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int preloadBuffer;
  final Duration loadDelay;
  final bool enableLazyLoading;

  const LazyListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.preloadBuffer = 5,
    this.loadDelay = const Duration(milliseconds: 100),
    this.enableLazyLoading = true,
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  final Set<int> _loadedIndices = {};
  final Map<int, Timer> _loadingTimers = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);

    // 지연 로딩이 비활성화된 경우 모든 아이템을 즉시 로드
    if (!widget.enableLazyLoading) {
      for (int i = 0; i < widget.items.length; i++) {
        _loadedIndices.add(i);
      }
    } else {
      // 초기 화면에 보이는 아이템들을 미리 로드
      _preloadInitialItems();
    }
  }

  @override
  void dispose() {
    for (final timer in _loadingTimers.values) {
      timer.cancel();
    }
    _loadingTimers.clear();

    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enableLazyLoading) return;

    final scrollPosition = _scrollController.position;
    final viewportHeight = scrollPosition.viewportDimension;
    final scrollOffset = scrollPosition.pixels;

    // 현재 보이는 영역과 버퍼 영역의 아이템들을 로드
    final startIndex =
        ((scrollOffset / _estimatedItemHeight) - widget.preloadBuffer)
            .floor()
            .clamp(0, widget.items.length - 1);
    final endIndex = (((scrollOffset + viewportHeight) / _estimatedItemHeight) +
            widget.preloadBuffer)
        .ceil()
        .clamp(0, widget.items.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      _scheduleItemLoad(i);
    }
  }

  double get _estimatedItemHeight => 80.0; // 기본 아이템 높이 추정값

  void _preloadInitialItems() {
    // 초기 화면에 보이는 아이템 수 계산 (대략적)
    final screenHeight = MediaQuery.of(context).size.height;
    final initialItemCount =
        ((screenHeight / _estimatedItemHeight) + widget.preloadBuffer)
            .ceil()
            .clamp(0, widget.items.length);

    for (int i = 0; i < initialItemCount; i++) {
      _scheduleItemLoad(i);
    }
  }

  void _scheduleItemLoad(int index) {
    if (_loadedIndices.contains(index) || _loadingTimers.containsKey(index)) {
      return;
    }

    _loadingTimers[index] = Timer(widget.loadDelay, () {
      if (mounted) {
        setState(() {
          _loadedIndices.add(index);
        });
      }
      _loadingTimers.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('항목이 없습니다'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        if (!widget.enableLazyLoading || _loadedIndices.contains(index)) {
          try {
            return widget.itemBuilder(context, widget.items[index], index);
          } catch (e) {
            logger.e('아이템 빌드 오류 (인덱스: $index)', error: e);
            return widget.errorBuilder?.call(context, e) ??
                ListTile(
                  title: Text('오류: ${e.toString()}'),
                  leading: const Icon(Icons.error, color: Colors.red),
                );
          }
        } else {
          // 로딩 중인 아이템의 플레이스홀더
          return widget.loadingBuilder?.call(context) ??
              Container(
                height: _estimatedItemHeight,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        }
      },
    );
  }
}

/// 지연 로딩을 지원하는 GridView
///
/// 가시성에 따라 아이템을 동적으로 로드하여 메모리 사용량과
/// 초기 로딩 시간을 최적화합니다.
class LazyGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final int preloadBuffer;
  final Duration loadDelay;
  final bool enableLazyLoading;

  const LazyGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.preloadBuffer = 10,
    this.loadDelay = const Duration(milliseconds: 100),
    this.enableLazyLoading = true,
  });

  @override
  State<LazyGridView<T>> createState() => _LazyGridViewState<T>();
}

class _LazyGridViewState<T> extends State<LazyGridView<T>> {
  final Set<int> _loadedIndices = {};
  final Map<int, Timer> _loadingTimers = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);

    // 지연 로딩이 비활성화된 경우 모든 아이템을 즉시 로드
    if (!widget.enableLazyLoading) {
      for (int i = 0; i < widget.items.length; i++) {
        _loadedIndices.add(i);
      }
    } else {
      // 초기 화면에 보이는 아이템들을 미리 로드
      _preloadInitialItems();
    }
  }

  @override
  void dispose() {
    for (final timer in _loadingTimers.values) {
      timer.cancel();
    }
    _loadingTimers.clear();

    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enableLazyLoading) return;

    final scrollPosition = _scrollController.position;
    final viewportHeight = scrollPosition.viewportDimension;
    final scrollOffset = scrollPosition.pixels;

    // 그리드의 행 높이 계산
    final itemHeight = _estimatedItemHeight;
    final rowHeight = itemHeight + widget.mainAxisSpacing;

    // 현재 보이는 영역의 행 범위 계산
    final startRow = ((scrollOffset / rowHeight) -
            (widget.preloadBuffer / widget.crossAxisCount))
        .floor()
        .clamp(0, _totalRows - 1);
    final endRow = (((scrollOffset + viewportHeight) / rowHeight) +
            (widget.preloadBuffer / widget.crossAxisCount))
        .ceil()
        .clamp(0, _totalRows - 1);

    // 해당 행들의 모든 아이템 로드
    for (int row = startRow; row <= endRow; row++) {
      for (int col = 0; col < widget.crossAxisCount; col++) {
        final index = row * widget.crossAxisCount + col;
        if (index < widget.items.length) {
          _scheduleItemLoad(index);
        }
      }
    }
  }

  double get _estimatedItemHeight {
    // 화면 너비를 기준으로 아이템 높이 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth -
        (widget.padding?.horizontal ?? 0) -
        (widget.crossAxisSpacing * (widget.crossAxisCount - 1));
    final itemWidth = availableWidth / widget.crossAxisCount;
    return itemWidth / widget.childAspectRatio;
  }

  int get _totalRows => (widget.items.length / widget.crossAxisCount).ceil();

  void _preloadInitialItems() {
    // 초기 화면에 보이는 아이템 수 계산
    final screenHeight = MediaQuery.of(context).size.height;
    final itemHeight = _estimatedItemHeight;
    final rowHeight = itemHeight + widget.mainAxisSpacing;
    final visibleRows = (screenHeight / rowHeight).ceil();
    final initialItemCount =
        ((visibleRows + (widget.preloadBuffer / widget.crossAxisCount)) *
                widget.crossAxisCount)
            .ceil()
            .clamp(0, widget.items.length);

    for (int i = 0; i < initialItemCount; i++) {
      _scheduleItemLoad(i);
    }
  }

  void _scheduleItemLoad(int index) {
    if (_loadedIndices.contains(index) || _loadingTimers.containsKey(index)) {
      return;
    }

    _loadingTimers[index] = Timer(widget.loadDelay, () {
      if (mounted) {
        setState(() {
          _loadedIndices.add(index);
        });
      }
      _loadingTimers.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('항목이 없습니다'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        if (!widget.enableLazyLoading || _loadedIndices.contains(index)) {
          try {
            return widget.itemBuilder(context, widget.items[index], index);
          } catch (e) {
            logger.e('그리드 아이템 빌드 오류 (인덱스: $index)', error: e);
            return widget.errorBuilder?.call(context, e) ??
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
          }
        } else {
          // 로딩 중인 아이템의 플레이스홀더
          return widget.loadingBuilder?.call(context) ??
              Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        }
      },
    );
  }
}

/// 페이지네이션을 지원하는 지연 로딩 리스트
class LazyPaginatedListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataLoader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int pageSize;
  final double loadMoreThreshold;

  const LazyPaginatedListView({
    super.key,
    required this.dataLoader,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.pageSize = 20,
    this.loadMoreThreshold = 200.0,
  });

  @override
  State<LazyPaginatedListView<T>> createState() =>
      _LazyPaginatedListViewState<T>();
}

class _LazyPaginatedListViewState<T> extends State<LazyPaginatedListView<T>> {
  final List<T> _items = [];
  late ScrollController _scrollController;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || !_hasMoreData) return;

    final scrollPosition = _scrollController.position;
    final remainingDistance =
        scrollPosition.maxScrollExtent - scrollPosition.pixels;

    if (remainingDistance <= widget.loadMoreThreshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.dataLoader(_currentPage, widget.pageSize);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _hasMoreData = newItems.length == widget.pageSize;
          _isLoading = false;
        });
      }

      logger.d('페이지 로드 완료: 페이지=$_currentPage, 아이템=${newItems.length}개');
    } catch (e) {
      logger.e('페이지 로드 실패: 페이지=$_currentPage', error: e);

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMoreData = true;
      _error = null;
    });

    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _error != null) {
      return widget.errorBuilder?.call(context, _error) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('오류: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('항목이 없습니다'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: _items.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          } else {
            // 로딩 인디케이터
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _error != null
                      ? Column(
                          children: [
                            Text('오류: $_error'),
                            ElevatedButton(
                              onPressed: _loadNextPage,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
            );
          }
        },
      ),
    );
  }
}
