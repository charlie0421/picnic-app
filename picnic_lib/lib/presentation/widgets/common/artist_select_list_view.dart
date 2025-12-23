import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
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

  /// 북마크 토글 버튼 표시 여부 (나의 아티스트: true, 궁합: false)
  final bool showBookmarkToggle;

  /// 검색 시 섹션 헤더 숨김 여부 (나의 아티스트: false, 궁합: true)
  final bool hideSectionHeaderOnSearch;

  /// 북마크 섹션 제목 ("북마크" or "나의 아티스트")
  final String bookmarkSectionTitle;

  /// 일반 섹션 제목
  final String generalSectionTitle;

  /// 빈 목록 메시지
  final String emptyMessage;

  /// 검색 결과 없음 메시지 템플릿 ({query}가 검색어로 대체됨)
  final String searchEmptyMessageTemplate;

  /// 에러 메시지
  final String errorMessage;
}

/// 공통 아티스트 선택 리스트 뷰 위젯
///
/// 나의 아티스트와 궁합 아티스트 선택 화면에서 공통으로 사용됩니다.
/// [searchArtistsFast]를 사용하여 빠른 검색 성능을 제공합니다.
class ArtistSelectListView extends ConsumerStatefulWidget {
  const ArtistSelectListView({
    super.key,
    required this.searchQueryProvider,
    required this.config,
    this.onArtistTap,
    this.onBookmarkToggle,
  });

  /// 검색어 상태 프로바이더
  final NotifierProvider<Notifier<String>, String> searchQueryProvider;

  /// 위젯 설정
  final ArtistSelectConfig config;

  /// 아티스트 탭 콜백 (궁합에서 사용)
  final void Function(ArtistModel artist)? onArtistTap;

  /// 북마크 토글 콜백 (나의 아티스트에서 사용)
  final Future<void> Function(ArtistModel artist)? onBookmarkToggle;

  @override
  ConsumerState<ArtistSelectListView> createState() =>
      ArtistSelectListViewState();
}

class ArtistSelectListViewState extends ConsumerState<ArtistSelectListView> {
  late PagingController<int, ArtistModel> _pagingController;
  static const _pageSize = 20;
  late String _initialSearchQuery;

  @override
  void initState() {
    super.initState();

    // 초기 검색어 저장 (페이지 재진입 시 복원용)
    _initialSearchQuery = ref.read(widget.searchQueryProvider);

    _pagingController = PagingController<int, ArtistModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 0;
        final isLastPage =
            state.items!.length < (state.keys?.last ?? 0 + 1) * _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetchArtistPage,
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<List<ArtistModel>> _fetchArtistPage(int pageKey) async {
    try {
      if (!mounted) {
        return [];
      }

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
    } catch (e, stackTrace) {
      logger.e('Failed to fetch artist page',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 리스트를 새로고침합니다.
  void refresh() {
    _pagingController.refresh();
  }

  /// 특정 아티스트의 북마크 상태를 즉시 업데이트합니다.
  void updateBookmarkState(int artistId, bool isBookmarked) {
    final pages = _pagingController.value.pages;
    if (pages == null || pages.isEmpty) return;

    // 각 페이지의 아이템을 업데이트
    final updatedPages = pages.map((page) {
      return page.map((artist) {
        if (artist.id == artistId) {
          return artist.copyWith(isBookmarked: isBookmarked);
        }
        return artist;
      }).toList();
    }).toList();

    // PagingController의 value를 업데이트하고 UI 새로고침
    setState(() {
      _pagingController.value = _pagingController.value.copyWith(
        pages: updatedPages,
      );
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
                // Notifier의 set 메서드 호출
                (ref.read(widget.searchQueryProvider.notifier) as dynamic)
                    .set(query);
                _pagingController.refresh();
              }
            },
          ),
        ),
        Expanded(
          child: _buildArtistList(),
        ),
      ],
    );
  }

  Widget _buildArtistList() {
    final searchQuery = ref.watch(widget.searchQueryProvider);

    return PagingListener<int, ArtistModel>(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) {
        return PagedListView<int, ArtistModel>(
          state: state,
          fetchNextPage: fetchNextPage,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          builderDelegate: PagedChildBuilderDelegate<ArtistModel>(
            itemBuilder: (context, item, index) {
              return _buildArtistItem(item, index, searchQuery);
            },
            firstPageProgressIndicatorBuilder: (context) {
              return const Center(child: MediumPulseLoadingIndicator());
            },
            newPageProgressIndicatorBuilder: (context) {
              return const Center(child: MediumPulseLoadingIndicator());
            },
            noItemsFoundIndicatorBuilder: (context) {
              return NoItemContainer(
                message: searchQuery.isEmpty
                    ? widget.config.emptyMessage
                    : widget.config.searchEmptyMessageTemplate
                        .replaceAll('{query}', searchQuery),
              );
            },
            firstPageErrorIndicatorBuilder: (context) {
              return buildErrorView(
                context,
                error: _pagingController.value.error?.toString() ??
                    widget.config.errorMessage,
                stackTrace: StackTrace.current,
                retryFunction: () {
                  _pagingController.refresh();
                },
              );
            },
            newPageErrorIndicatorBuilder: (context) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _pagingController.refresh();
                    },
                    child: const Text('다시 시도'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistItem(ArtistModel item, int index, String searchQuery) {
    final isBookmarked = item.isBookmarked == true;
    final shouldShowSectionHeaders = widget.config.hideSectionHeaderOnSearch
        ? searchQuery.isEmpty
        : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        if (shouldShowSectionHeaders) ...[
          // 북마크 섹션 헤더
          if (_isFirstBookmarkItem(index))
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
                    style:
                        getTextStyle(AppTypo.caption12M, AppColors.primary500),
                  ),
                ],
              ),
            ),
          // 일반 아티스트 섹션 헤더
          if (_isFirstNonBookmarkItem(index))
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
        ],
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
            leading: PicnicCachedNetworkImage(
              width: 48,
              height: 48,
              imageUrl: 'artist/${item.id}/image.png',
              borderRadius: BorderRadius.circular(24),
              lazyLoadingStrategy: LazyLoadingStrategy.viewport,
              priority: ImagePriority.normal,
            ),
            title: _buildHighlightedName(item, searchQuery),
            subtitle: item.artistGroup?.name != null
                ? _buildHighlightedGroupName(item, searchQuery)
                : null,
            trailing: widget.config.showBookmarkToggle
                ? _buildBookmarkButton(item, isBookmarked)
                : null,
            onTap: widget.onArtistTap != null
                ? () => widget.onArtistTap!(item)
                : null,
          ),
        ),
        // 구분선 (검색어가 없을 때만 표시하거나, hideSectionHeaderOnSearch가 false면 항상 표시)
        if (!widget.config.hideSectionHeaderOnSearch || searchQuery.isEmpty)
          Divider(height: 1, color: AppColors.grey200),
      ],
    );
  }

  Widget _buildBookmarkButton(ArtistModel item, bool isBookmarked) {
    return GestureDetector(
      onTap: () {
        logger.i(
            '🔖 북마크 버튼 탭됨 - Artist: ${getLocaleTextFromJson(item.name)}, isBookmarked: ${item.isBookmarked}');
        widget.onBookmarkToggle?.call(item);
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
          item.isBookmarked == true ? Icons.star : Icons.star_border,
          color:
              item.isBookmarked == true ? AppColors.primary500 : AppColors.grey500,
          size: 24,
        ),
      ),
    );
  }

  /// 첫 번째 북마크 아이템인지 확인
  bool _isFirstBookmarkItem(int index) {
    final items = _pagingController.value.items;
    if (items == null || index >= items.length) return false;

    final currentItem = items[index];
    return currentItem.isBookmarked == true &&
        (index == 0 || items[index - 1].isBookmarked != true);
  }

  /// 첫 번째 일반(비북마크) 아이템인지 확인
  bool _isFirstNonBookmarkItem(int index) {
    final items = _pagingController.value.items;
    if (items == null || index >= items.length) return false;

    final currentItem = items[index];
    return currentItem.isBookmarked != true &&
        (index == 0 || items[index - 1].isBookmarked == true);
  }

  Widget _buildHighlightedName(ArtistModel item, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Text(
        getLocaleTextFromJson(item.name, context),
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      );
    }

    final matchingText =
        KoreanSearchUtils.getMatchingText(item.name, searchQuery);

    return KoreanSearchUtils.buildConditionalHighlightText(
      matchingText,
      searchQuery,
      getTextStyle(AppTypo.body14M, AppColors.grey900),
      highlightColor: AppColors.primary500.withValues(alpha: 0.3),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildHighlightedGroupName(ArtistModel item, String searchQuery) {
    final groupName = item.artistGroup?.name;
    if (groupName == null) return const SizedBox.shrink();

    final groupNameText = getLocaleTextFromJson(groupName, context);
    if (searchQuery.isEmpty) {
      return Text(
        groupNameText,
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
      );
    }

    return KoreanSearchUtils.buildConditionalHighlightText(
      groupNameText,
      searchQuery,
      getTextStyle(AppTypo.caption12R, AppColors.grey600),
      highlightColor: AppColors.primary500.withValues(alpha: 0.3),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
