import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Optimized grid view with efficient rendering and pagination
class OptimizedGridView<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool keepAlive;
  final bool enableAnimation;
  final Duration animationDelay;
  final Duration animationDuration;
  final double cacheExtent;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.scrollController,
    this.padding,
    this.keepAlive = true,
    this.enableAnimation = true,
    this.animationDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.cacheExtent = 250.0,
  });

  @override
  ConsumerState<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends ConsumerState<OptimizedGridView<T>>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => widget.keepAlive;

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
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: widget.items.length + (widget.hasMore && widget.isLoading ? widget.crossAxisCount : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return _buildItem(context, widget.items[index], index);
        } else {
          return _buildLoadingCell();
        }
      },
    );

    if (widget.enableAnimation) {
      gridView = AnimationLimiter(child: gridView);
    }

    if (widget.onRefresh != null) {
      gridView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildItem(BuildContext context, T item, int index) {
    Widget itemWidget = widget.itemBuilder(context, item, index);

    if (widget.keepAlive) {
      itemWidget = _KeepAliveWrapper(child: itemWidget);
    }

    if (widget.enableAnimation) {
      itemWidget = AnimationConfiguration.staggeredGrid(
        position: index,
        columnCount: widget.crossAxisCount,
        delay: widget.animationDelay,
        child: ScaleAnimation(
          duration: widget.animationDuration,
          curve: Curves.elasticOut,
          child: FadeInAnimation(
            duration: widget.animationDuration,
            child: itemWidget,
          ),
        ),
      );
    }

    return itemWidget;
  }

  Widget _buildLoadingCell() {
    return Container(
      margin: EdgeInsets.all(widget.crossAxisSpacing / 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
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
}

/// Keep alive wrapper for grid items
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

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

/// Staggered grid view for dynamic item sizes
class OptimizedStaggeredGridView<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double Function(T item, int index)? itemHeightBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool enableAnimation;

  const OptimizedStaggeredGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemHeightBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.scrollController,
    this.padding,
    this.enableAnimation = true,
  });

  @override
  ConsumerState<OptimizedStaggeredGridView<T>> createState() => _OptimizedStaggeredGridViewState<T>();
}

class _OptimizedStaggeredGridViewState<T> extends ConsumerState<OptimizedStaggeredGridView<T>> {
  late ScrollController _scrollController;
  final List<double> _columnHeights = [];

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Initialize column heights
    _columnHeights.clear();
    for (int i = 0; i < widget.crossAxisCount; i++) {
      _columnHeights.add(0);
    }
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
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (widget.padding != null)
          SliverPadding(
            padding: widget.padding!,
            sliver: _buildStaggeredGrid(),
          )
        else
          _buildStaggeredGrid(),
        
        if (widget.isLoading && widget.hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildStaggeredGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: 0.7, // Base aspect ratio, will be overridden
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= widget.items.length) return null;
          
          final item = widget.items[index];
          Widget itemWidget = widget.itemBuilder(context, item, index);

          // Calculate dynamic height if provided
          if (widget.itemHeightBuilder != null) {
            final height = widget.itemHeightBuilder!(item, index);
            itemWidget = SizedBox(
              height: height,
              child: itemWidget,
            );
          }

          if (widget.enableAnimation) {
            itemWidget = AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: widget.crossAxisCount,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: itemWidget),
              ),
            );
          }

          return itemWidget;
        },
        childCount: widget.items.length,
      ),
    );
  }
}

/// Masonry-style grid view with dynamic item sizes
class MasonryGridView<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const MasonryGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.scrollController,
    this.padding,
  });

  @override
  ConsumerState<MasonryGridView<T>> createState() => _MasonryGridViewState<T>();
}

class _MasonryGridViewState<T> extends ConsumerState<MasonryGridView<T>> {
  late ScrollController _scrollController;

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
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      controller: _scrollController,
      padding: widget.padding,
      child: _buildMasonryLayout(),
    );

    if (widget.onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildMasonryLayout() {
    final columns = List.generate(widget.crossAxisCount, (_) => <Widget>[]);
    final columnHeights = List.generate(widget.crossAxisCount, (_) => 0.0);

    // Distribute items across columns
    for (int i = 0; i < widget.items.length; i++) {
      // Find column with minimum height
      int targetColumn = 0;
      double minHeight = columnHeights[0];
      
      for (int j = 1; j < widget.crossAxisCount; j++) {
        if (columnHeights[j] < minHeight) {
          minHeight = columnHeights[j];
          targetColumn = j;
        }
      }

      final item = widget.items[i];
      final itemWidget = widget.itemBuilder(context, item, i);
      
      columns[targetColumn].add(
        Padding(
          padding: EdgeInsets.only(bottom: widget.mainAxisSpacing),
          child: itemWidget,
        ),
      );

      // Estimate height (this could be improved with actual measurements)
      columnHeights[targetColumn] += 200 + widget.mainAxisSpacing;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.asMap().entries.map((entry) {
        final index = entry.key;
        final columnWidgets = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : widget.crossAxisSpacing / 2,
              right: index == widget.crossAxisCount - 1 ? 0 : widget.crossAxisSpacing / 2,
            ),
            child: Column(
              children: [
                ...columnWidgets,
                if (widget.isLoading && widget.hasMore && index == 0)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Grid view performance optimizer
class GridViewOptimizer {
  /// Calculate optimal cross axis count based on screen width
  static int calculateOptimalCrossAxisCount({
    required BuildContext context,
    required double minItemWidth,
    double maxItemWidth = double.infinity,
    double spacing = 8.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (spacing * 2);
    
    int crossAxisCount = 1;
    double itemWidth = minItemWidth;
    
    while (itemWidth <= maxItemWidth) {
      final totalItemWidth = (crossAxisCount * itemWidth) + ((crossAxisCount - 1) * spacing);
      
      if (totalItemWidth > availableWidth) {
        break;
      }
      
      crossAxisCount++;
      itemWidth = (availableWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
    }
    
    return (crossAxisCount - 1).clamp(1, 10);
  }

  /// Calculate child aspect ratio for consistent grid appearance
  static double calculateChildAspectRatio({
    required BuildContext context,
    required int crossAxisCount,
    required double targetHeight,
    double spacing = 8.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (spacing * 2);
    final itemWidth = (availableWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
    
    return itemWidth / targetHeight;
  }
}