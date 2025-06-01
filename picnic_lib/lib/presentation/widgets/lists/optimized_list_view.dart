import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../core/services/scroll_physics_service.dart';

/// Optimized list view with keep alive pattern and efficient rendering
class OptimizedListView<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
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
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollPhysicsService.ScrollPhysicsType? physicsType;
  final bool enableAdaptivePhysics;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.scrollController,
    this.padding,
    this.keepAlive = true,
    this.enableAnimation = true,
    this.animationDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 300),
    this.cacheExtent = 250.0, // Default cache extent for better performance
    this.shrinkWrap = false,
    this.physics,
    this.physicsType,
    this.enableAdaptivePhysics = true,
  });

  @override
  ConsumerState<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends ConsumerState<OptimizedListView<T>>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  late ScrollPhysicsService _physicsService;
  ScrollPhysics? _adaptivePhysics;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _physicsService = ScrollPhysicsService();
    
    // Add scroll listener for load more functionality
    _scrollController.addListener(_onScroll);
    
    // Initialize adaptive physics if enabled
    if (widget.enableAdaptivePhysics) {
      _scrollController.addListener(_updateAdaptivePhysics);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
      if (widget.enableAdaptivePhysics) {
        _scrollController.removeListener(_updateAdaptivePhysics);
      }
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Trigger load more when near the end
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  void _updateAdaptivePhysics() {
    if (!widget.enableAdaptivePhysics || !_scrollController.hasClients) return;
    
    final metrics = _scrollController.position;
    final newPhysics = ScrollPhysicsManager().getAdaptivePhysics(metrics);
    
    if (_adaptivePhysics.runtimeType != newPhysics.runtimeType) {
      setState(() {
        _adaptivePhysics = newPhysics;
      });
    }
  }

  ScrollPhysics _getScrollPhysics() {
    // Priority order: explicit physics > physics type > adaptive physics > list physics
    if (widget.physics != null) {
      return widget.physics!;
    }
    
    if (widget.physicsType != null) {
      return _physicsService.getPhysics(widget.physicsType!);
    }
    
    if (widget.enableAdaptivePhysics && _adaptivePhysics != null) {
      return _adaptivePhysics!;
    }
    
    return _physicsService.getListPhysics();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent,
      shrinkWrap: widget.shrinkWrap,
      physics: _getScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return _buildItem(context, widget.items[index], index);
        } else {
          // Loading indicator at the bottom
          return _buildLoadingIndicator();
        }
      },
    );

    // Wrap with animations if enabled
    if (widget.enableAnimation) {
      listView = AnimationLimiter(child: listView);
    }

    // Wrap with refresh indicator if onRefresh is provided
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildItem(BuildContext context, T item, int index) {
    Widget itemWidget = widget.itemBuilder(context, item, index);

    // Add keep alive wrapper if needed
    if (widget.keepAlive) {
      itemWidget = _KeepAliveWrapper(child: itemWidget);
    }

    // Add animation if enabled
    if (widget.enableAnimation) {
      itemWidget = AnimationConfiguration.staggeredList(
        position: index,
        delay: widget.animationDelay,
        child: SlideAnimation(
          duration: widget.animationDuration,
          verticalOffset: 50.0,
          child: FadeInAnimation(
            duration: widget.animationDuration,
            child: itemWidget,
          ),
        ),
      );
    }

    return itemWidget;
  }

  Widget _buildLoadingIndicator() {
    if (!widget.isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

/// Keep alive wrapper to maintain widget state
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

/// Performance metrics for list optimization
class ListPerformanceMetrics {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start measuring performance
  static void startMeasurement(String key) {
    _timers[key] = Stopwatch()..start();
  }

  /// Stop measuring and record result
  static void stopMeasurement(String key) {
    final timer = _timers[key];
    if (timer != null) {
      timer.stop();
      _measurements[key] ??= [];
      _measurements[key]!.add(timer.elapsed);
      _timers.remove(key);
    }
  }

  /// Get average measurement
  static Duration? getAverageMeasurement(String key) {
    final measurements = _measurements[key];
    if (measurements == null || measurements.isEmpty) return null;

    final total = measurements.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    return Duration(microseconds: total ~/ measurements.length);
  }

  /// Clear all measurements
  static void clearMeasurements() {
    _measurements.clear();
    _timers.clear();
  }

  /// Get performance report
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _measurements.entries) {
      final key = entry.key;
      final measurements = entry.value;
      
      if (measurements.isNotEmpty) {
        final total = measurements.fold<int>(
          0,
          (sum, duration) => sum + duration.inMicroseconds,
        );
        
        report[key] = {
          'count': measurements.length,
          'average_ms': (total / measurements.length / 1000).toStringAsFixed(2),
          'min_ms': (measurements.map((d) => d.inMicroseconds).reduce((a, b) => a < b ? a : b) / 1000).toStringAsFixed(2),
          'max_ms': (measurements.map((d) => d.inMicroseconds).reduce((a, b) => a > b ? a : b) / 1000).toStringAsFixed(2),
        };
      }
    }
    
    return report;
  }
}