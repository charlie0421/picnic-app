import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Pagination-enabled list view with infinite scroll and backend integration
class PaginatedListView<T> extends ConsumerStatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Widget? firstPageLoadingWidget;
  final int pageSize;
  final bool enableAnimation;
  final bool enableRefresh;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final String? noItemsFoundText;
  final String? newPageErrorText;
  final VoidCallback? onEmptyActionPressed;
  final String? emptyActionText;

  const PaginatedListView({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.firstPageLoadingWidget,
    this.pageSize = 20,
    this.enableAnimation = true,
    this.enableRefresh = true,
    this.scrollController,
    this.padding,
    this.noItemsFoundText,
    this.newPageErrorText,
    this.onEmptyActionPressed,
    this.emptyActionText,
  });

  @override
  ConsumerState<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends ConsumerState<PaginatedListView<T>> {
  late PagingController<int, T> _pagingController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 0);
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await widget.onLoadPage(pageKey, widget.pageSize);
      final isLastPage = newItems.length < widget.pageSize;
      
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = PagedListView<int, T>(
      pagingController: _pagingController,
      scrollController: widget.scrollController,
      padding: widget.padding,
      builderDelegate: PagedChildBuilderDelegate<T>(
        itemBuilder: (context, item, index) {
          Widget itemWidget = widget.itemBuilder(context, item, index);
          
          if (widget.enableAnimation) {
            itemWidget = AnimationConfiguration.staggeredList(
              position: index,
              child: SlideAnimation(
                duration: const Duration(milliseconds: 300),
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 300),
                  child: itemWidget,
                ),
              ),
            );
          }
          
          return itemWidget;
        },
        firstPageErrorIndicatorBuilder: (context) => _buildErrorWidget(isFirstPage: true),
        newPageErrorIndicatorBuilder: (context) => _buildErrorWidget(isFirstPage: false),
        firstPageProgressIndicatorBuilder: (context) => _buildLoadingWidget(isFirstPage: true),
        newPageProgressIndicatorBuilder: (context) => _buildLoadingWidget(isFirstPage: false),
        noItemsFoundIndicatorBuilder: (context) => _buildEmptyWidget(),
        noMoreItemsIndicatorBuilder: (context) => _buildNoMoreItemsWidget(),
      ),
    );

    if (widget.enableAnimation) {
      listView = AnimationLimiter(child: listView);
    }

    if (widget.enableRefresh) {
      listView = RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _pagingController.refresh();
        },
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildErrorWidget({required bool isFirstPage}) {
    if (isFirstPage && widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            isFirstPage 
              ? 'Failed to load data' 
              : widget.newPageErrorText ?? 'Failed to load more items',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (isFirstPage) {
                _pagingController.refresh();
              } else {
                _pagingController.retryLastFailedRequest();
              }
            },
            child: Text(isFirstPage ? 'Retry' : 'Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget({required bool isFirstPage}) {
    if (isFirstPage) {
      return widget.firstPageLoadingWidget ?? 
        widget.loadingWidget ?? 
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
    }

    return widget.loadingWidget ?? 
      Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
  }

  Widget _buildEmptyWidget() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            widget.noItemsFoundText ?? 'No items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or try again later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onEmptyActionPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onEmptyActionPressed,
              child: Text(widget.emptyActionText ?? 'Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoMoreItemsWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Text(
        'No more items to load',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[500],
        ),
      ),
    );
  }

  /// Refresh the list
  void refresh() {
    _pagingController.refresh();
  }

  /// Check if list is loading
  bool get isLoading => _pagingController.value.status == PagingStatus.loading;

  /// Check if list has error
  bool get hasError => _pagingController.value.status == PagingStatus.firstPageError;

  /// Get current items
  List<T> get items => _pagingController.itemList ?? [];

  /// Check if list is empty
  bool get isEmpty => items.isEmpty && !isLoading;
}

/// Paginated grid view with similar functionality
class PaginatedGridView<T> extends ConsumerStatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final int pageSize;
  final bool enableAnimation;
  final bool enableRefresh;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  const PaginatedGridView({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.pageSize = 20,
    this.enableAnimation = true,
    this.enableRefresh = true,
    this.scrollController,
    this.padding,
  });

  @override
  ConsumerState<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends ConsumerState<PaginatedGridView<T>> {
  late PagingController<int, T> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController(firstPageKey: 0);
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await widget.onLoadPage(pageKey, widget.pageSize);
      final isLastPage = newItems.length < widget.pageSize;
      
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget gridView = PagedGridView<int, T>(
      pagingController: _pagingController,
      scrollController: widget.scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      builderDelegate: PagedChildBuilderDelegate<T>(
        itemBuilder: (context, item, index) {
          Widget itemWidget = widget.itemBuilder(context, item, index);
          
          if (widget.enableAnimation) {
            itemWidget = AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: widget.crossAxisCount,
              child: ScaleAnimation(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 400),
                  child: itemWidget,
                ),
              ),
            );
          }
          
          return itemWidget;
        },
        firstPageErrorIndicatorBuilder: (context) =>
          widget.errorWidget ?? const Center(child: Text('Error occurred')),
        newPageErrorIndicatorBuilder: (context) =>
          const Center(child: Text('Error loading more')),
        firstPageProgressIndicatorBuilder: (context) =>
          widget.loadingWidget ?? const Center(child: CircularProgressIndicator()),
        newPageProgressIndicatorBuilder: (context) =>
          const Center(child: CircularProgressIndicator()),
        noItemsFoundIndicatorBuilder: (context) =>
          widget.emptyWidget ?? const Center(child: Text('No items found')),
      ),
    );

    if (widget.enableAnimation) {
      gridView = AnimationLimiter(child: gridView);
    }

    if (widget.enableRefresh) {
      gridView = RefreshIndicator(
        onRefresh: () async {
          _pagingController.refresh();
        },
        child: gridView,
      );
    }

    return gridView;
  }

  /// Refresh the grid
  void refresh() {
    _pagingController.refresh();
  }

  /// Check if grid is loading
  bool get isLoading => _pagingController.value.status == PagingStatus.loading;
}

/// Supabase integration helper for pagination
class SupabasePaginationHelper {
  /// Create a paginated query for Supabase
  static Future<List<Map<String, dynamic>>> paginatedQuery({
    required Future<List<Map<String, dynamic>>> Function(int from, int to) queryBuilder,
    required int page,
    required int pageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    
    try {
      return await queryBuilder(from, to);
    } catch (error) {
      throw Exception('Failed to fetch data: $error');
    }
  }

  /// Create a paginated query with search functionality
  static Future<List<Map<String, dynamic>>> paginatedSearchQuery({
    required Future<List<Map<String, dynamic>>> Function(String searchTerm, int from, int to) queryBuilder,
    required String searchTerm,
    required int page,
    required int pageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    
    try {
      return await queryBuilder(searchTerm, from, to);
    } catch (error) {
      throw Exception('Failed to search data: $error');
    }
  }
}

/// Firebase integration helper for pagination
class FirebasePaginationHelper {
  /// Create a paginated query for Firebase with cursor-based pagination
  static Future<List<T>> paginatedQuery<T>({
    required Future<List<T>> Function(int limit, dynamic lastDocument) queryBuilder,
    required int page,
    required int pageSize,
    dynamic lastDocument,
  }) async {
    try {
      return await queryBuilder(pageSize, lastDocument);
    } catch (error) {
      throw Exception('Failed to fetch data: $error');
    }
  }
}

/// Advanced pagination controller with caching
class AdvancedPaginationController<T> {
  final int pageSize;
  final Duration cacheExpiry;
  final Map<int, List<T>> _cache = {};
  final Map<int, DateTime> _cacheTimestamps = {};

  AdvancedPaginationController({
    this.pageSize = 20,
    this.cacheExpiry = const Duration(minutes: 5),
  });

  /// Get cached data for a page if still valid
  List<T>? getCachedPage(int page) {
    final cachedData = _cache[page];
    final timestamp = _cacheTimestamps[page];
    
    if (cachedData != null && timestamp != null) {
      if (DateTime.now().difference(timestamp) < cacheExpiry) {
        return cachedData;
      } else {
        // Remove expired cache
        _cache.remove(page);
        _cacheTimestamps.remove(page);
      }
    }
    
    return null;
  }

  /// Cache data for a page
  void cachePage(int page, List<T> data) {
    _cache[page] = List.from(data);
    _cacheTimestamps[page] = DateTime.now();
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredPages = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= cacheExpiry)
        .map((entry) => entry.key)
        .toList();
    
    for (final page in expiredPages) {
      _cache.remove(page);
      _cacheTimestamps.remove(page);
    }
  }

  /// Get total cached items count
  int get cachedItemsCount {
    return _cache.values.fold(0, (sum, page) => sum + page.length);
  }
}