import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmark_state_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

/// 아티스트 선택 리스트 뷰 설정
class ArtistSelectConfig {
  const ArtistSelectConfig({
    this.showBookmarkToggle = false,
    this.hideSectionHeaderOnSearch = false,
    this.bookmarkSectionTitle = '북마크',
    this.generalSectionTitle = '전체 아티스트',
    this.emptyMessage = '등록된 아티스트가 없습니다.',
    this.searchEmptyMessageTemplate = '"{query}"에 대한 검색 결과가 없습니다.',
    this.errorMessage = '아티스트 목록을 불러오는데 실패했습니다.',
  });

  final bool showBookmarkToggle;
  final bool hideSectionHeaderOnSearch;
  final String bookmarkSectionTitle;
  final String generalSectionTitle;
  final String emptyMessage;
  final String searchEmptyMessageTemplate;
  final String errorMessage;
}

/// 공통 아티스트 선택 리스트 뷰 위젯
///
/// 북마크 상태 변경 시 위치 이동과 함께 이미지 로딩을 방지합니다.
/// PicnicCachedNetworkImage 내부의 글로벌 캐시가 이미지 로딩 상태를 추적합니다.
class ArtistSelectListView extends ConsumerStatefulWidget {
  const ArtistSelectListView({
    super.key,
    required this.searchQueryProvider,
    required this.config,
    this.onArtistTap,
    this.onBookmarkToggle,
  });

  final NotifierProvider<Notifier<String>, String> searchQueryProvider;
  final ArtistSelectConfig config;
  final void Function(ArtistModel artist)? onArtistTap;
  final Future<void> Function(ArtistModel artist)? onBookmarkToggle;

  @override
  ConsumerState<ArtistSelectListView> createState() =>
      ArtistSelectListViewState();
}

class ArtistSelectListViewState extends ConsumerState<ArtistSelectListView> {
  static const _pageSize = 20;

  final List<ArtistModel> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  late String _initialSearchQuery;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialSearchQuery = ref.read(widget.searchQueryProvider);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final items = await _fetchPage(0);
      if (!mounted) return;

      setState(() {
        _items.addAll(items);
        _currentPage = 1;
        _hasMore = items.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.e('Failed to load initial data', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _fetchPage(_currentPage);
      if (!mounted) return;

      setState(() {
        _items.addAll(items);
        _currentPage++;
        _hasMore = items.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.e('Failed to load more data', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<ArtistModel>> _fetchPage(int pageKey) async {
    final searchQuery = ref.read(widget.searchQueryProvider);
    logger.d('Fetching page $pageKey with query: "$searchQuery"');

    final language = Localizations.localeOf(context).languageCode;
    final newItems = await SearchService.searchArtistsFast(
      query: searchQuery,
      page: pageKey,
      limit: _pageSize,
      language: language,
      includeBookmarks: true,
    );

    logger.d('Received ${newItems.length} items for page $pageKey');
    return newItems;
  }

  /// 리스트를 새로고침합니다.
  void refresh() {
    _loadInitialData();
  }

  /// 북마크 상태 업데이트 및 위치 이동
  void updateBookmarkState(int artistId, bool isBookmarked) {
    logger.d('🔖 updateBookmarkState - artistId: $artistId, isBookmarked: $isBookmarked');

    // 1. 글로벌 상태 업데이트
    ref.read(bookmarkStateProvider.notifier).updateBookmarkState(artistId, isBookmarked);

    // 2. 로컬 리스트에서 위치 이동
    final itemIndex = _items.indexWhere((item) => item.id == artistId);
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    final updatedItem = item.copyWith(isBookmarked: isBookmarked);

    setState(() {
      // 현재 위치에서 제거
      _items.removeAt(itemIndex);

      if (isBookmarked) {
        // 북마크 추가: 북마크 섹션 마지막에 삽입
        final lastBookmarkIndex = _items.lastIndexWhere((i) => i.isBookmarked == true);
        final insertIndex = lastBookmarkIndex + 1;
        _items.insert(insertIndex, updatedItem);
        logger.d('🔖 북마크 추가 - 새 위치: $insertIndex');
      } else {
        // 북마크 해제: 일반 섹션 첫 번째에 삽입
        final firstNonBookmarkIndex = _items.indexWhere((i) => i.isBookmarked != true);
        final insertIndex = firstNonBookmarkIndex == -1 ? _items.length : firstNonBookmarkIndex;
        _items.insert(insertIndex, updatedItem);
        logger.d('🔖 북마크 해제 - 새 위치: $insertIndex');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16),
          child: EnhancedSearchBox(
            hintText: AppLocalizations.of(context).text_hint_search,
            initialValue: _initialSearchQuery,
            onSearchChanged: (query) {
              if (mounted) {
                (ref.read(widget.searchQueryProvider.notifier) as dynamic)
                    .set(query);
                // 캐시 무효화 후 새로고침
                SearchService.invalidateCache('artist_fast');
                _loadInitialData();
              }
            },
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final searchQuery = ref.watch(widget.searchQueryProvider);

    if (_error != null && _items.isEmpty) {
      return buildErrorView(
        context,
        error: _error!,
        stackTrace: StackTrace.current,
        retryFunction: _loadInitialData,
      );
    }

    if (_isLoading && _items.isEmpty) {
      return const Center(child: MediumPulseLoadingIndicator());
    }

    if (_items.isEmpty) {
      return NoItemContainer(
        message: searchQuery.isEmpty
            ? widget.config.emptyMessage
            : widget.config.searchEmptyMessageTemplate
                .replaceAll('{query}', searchQuery),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      // 아이템 재사용을 위한 설정
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(child: MediumPulseLoadingIndicator());
        }

        final item = _items[index];
        return _ArtistItemWidget(
          key: ValueKey('artist_item_${item.id}'),
          item: item,
          index: index,
          allItems: _items,
          searchQuery: searchQuery,
          config: widget.config,
          onArtistTap: widget.onArtistTap,
          onBookmarkToggle: widget.onBookmarkToggle,
        );
      },
    );
  }
}

/// 개별 아티스트 아이템 위젯
class _ArtistItemWidget extends ConsumerStatefulWidget {
  const _ArtistItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.allItems,
    required this.searchQuery,
    required this.config,
    this.onArtistTap,
    this.onBookmarkToggle,
  });

  final ArtistModel item;
  final int index;
  final List<ArtistModel> allItems;
  final String searchQuery;
  final ArtistSelectConfig config;
  final void Function(ArtistModel artist)? onArtistTap;
  final Future<void> Function(ArtistModel artist)? onBookmarkToggle;

  @override
  ConsumerState<_ArtistItemWidget> createState() => _ArtistItemWidgetState();
}

class _ArtistItemWidgetState extends ConsumerState<_ArtistItemWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 이 아티스트의 북마크 상태만 선택적으로 watch (UI 표시용)
    final overrideState = ref.watch(
      bookmarkStateProvider.select((states) => states[widget.item.id]),
    );
    // 로컬 데이터의 isBookmarked를 사용 (위치 이동 후 업데이트됨)
    final isBookmarked = overrideState ?? widget.item.isBookmarked == true;

    // 섹션 헤더는 로컬 데이터 기준으로 표시
    final shouldShowHeaders = widget.config.hideSectionHeaderOnSearch
        ? widget.searchQuery.isEmpty
        : true;
    final isFirstBookmark = shouldShowHeaders && _isFirstBookmarkItem();
    final isFirstNonBookmark = shouldShowHeaders && _isFirstNonBookmarkItem();

    final imageUrl = 'artist/${widget.item.id}/image.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 북마크 섹션 헤더
        if (isFirstBookmark)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            margin: EdgeInsets.only(top: 8.h),
            color: AppColors.primary500.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.primary500, size: 18),
                SizedBox(width: 6.w),
                Text(
                  widget.config.bookmarkSectionTitle,
                  style: getTextStyle(AppTypo.caption12M, AppColors.primary500),
                ),
              ],
            ),
          ),
        // 일반 아티스트 섹션 헤더
        if (isFirstNonBookmark)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            margin: EdgeInsets.only(top: 8.h),
            color: AppColors.grey100,
            child: Row(
              children: [
                Icon(Icons.people, color: AppColors.grey600, size: 18),
                SizedBox(width: 6.w),
                Text(
                  widget.config.generalSectionTitle,
                  style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                ),
              ],
            ),
          ),
        // 아티스트 아이템
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isBookmarked
                ? AppColors.primary500.withValues(alpha: 0.05)
                : Colors.white,
            border: isBookmarked
                ? Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.2),
                    width: 0.5)
                : null,
          ),
          child: ListTile(
            leading: RepaintBoundary(
              child: PicnicCachedNetworkImage(
                key: ValueKey('artist_image_${widget.item.id}'),
                width: 48,
                height: 48,
                imageUrl: imageUrl,
                borderRadius: BorderRadius.circular(24),
                // PicnicCachedNetworkImage 내부에서 이미 로딩된 이미지를 추적함
                lazyLoadingStrategy: LazyLoadingStrategy.viewport,
                priority: ImagePriority.high,
              ),
            ),
            title: _buildHighlightedName(context),
            subtitle: widget.item.artistGroup?.name != null
                ? _buildHighlightedGroupName(context)
                : null,
            trailing: widget.config.showBookmarkToggle
                ? _buildBookmarkButton(context, isBookmarked)
                : null,
            onTap: widget.onArtistTap != null ? () => widget.onArtistTap!(widget.item) : null,
          ),
        ),
        // 구분선
        if (!widget.config.hideSectionHeaderOnSearch || widget.searchQuery.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Divider(height: 1, color: AppColors.grey200),
          ),
      ],
    );
  }

  /// 첫 번째 북마크 아이템인지 확인
  bool _isFirstBookmarkItem() {
    if (widget.item.isBookmarked != true) return false;
    if (widget.index == 0) return true;
    return widget.allItems[widget.index - 1].isBookmarked != true;
  }

  /// 첫 번째 일반 아이템인지 확인
  bool _isFirstNonBookmarkItem() {
    if (widget.item.isBookmarked == true) return false;
    if (widget.index == 0) return true;
    return widget.allItems[widget.index - 1].isBookmarked == true;
  }

  Widget _buildBookmarkButton(BuildContext context, bool isBookmarked) {
    return GestureDetector(
      onTap: () {
        logger.i(
            '🔖 북마크 버튼 탭됨 - Artist: ${getLocaleTextFromJson(widget.item.name)}, isBookmarked: $isBookmarked');
        final updatedItem = widget.item.copyWith(isBookmarked: isBookmarked);
        widget.onBookmarkToggle?.call(updatedItem);
      },
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isBookmarked
              ? AppColors.primary500.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isBookmarked
              ? Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.3), width: 1)
              : Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(
          isBookmarked ? Icons.star : Icons.star_border,
          color: isBookmarked ? AppColors.primary500 : AppColors.grey500,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildHighlightedName(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return Text(
        getLocaleTextFromJson(widget.item.name, context),
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      );
    }

    final matchingText =
        KoreanSearchUtils.getMatchingText(widget.item.name, widget.searchQuery);

    return KoreanSearchUtils.buildConditionalHighlightText(
      matchingText,
      widget.searchQuery,
      getTextStyle(AppTypo.body14M, AppColors.grey900),
      highlightColor: AppColors.primary500.withValues(alpha: 0.3),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildHighlightedGroupName(BuildContext context) {
    final groupName = widget.item.artistGroup?.name;
    if (groupName == null) return const SizedBox.shrink();

    final groupNameText = getLocaleTextFromJson(groupName, context);
    if (widget.searchQuery.isEmpty) {
      return Text(
        groupNameText,
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
      );
    }

    return KoreanSearchUtils.buildConditionalHighlightText(
      groupNameText,
      widget.searchQuery,
      getTextStyle(AppTypo.caption12R, AppColors.grey600),
      highlightColor: AppColors.primary500.withValues(alpha: 0.3),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
