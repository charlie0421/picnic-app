import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_input_page.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityArtistSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final compatibilityArtistSearchQueryProvider =
    NotifierProvider<CompatibilityArtistSearchQueryNotifier, String>(
  CompatibilityArtistSearchQueryNotifier.new,
);

class CompatibilityArtistSelectPage extends ConsumerStatefulWidget {
  const CompatibilityArtistSelectPage({super.key});

  @override
  ConsumerState<CompatibilityArtistSelectPage> createState() =>
      _CompatibilityArtistSelectPageState();
}

class _CompatibilityArtistSelectPageState
    extends ConsumerState<CompatibilityArtistSelectPage>
    with RouteAwareStateMixin<CompatibilityArtistSelectPage> {
  late PagingController<int, ArtistModel> _pagingController;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();

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

    _updateNavigation();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  Future<List<ArtistModel>> _fetchArtistPage(int pageKey) async {
    try {
      if (!mounted) {
        return [];
      }

      final searchQuery =
          ref.read(compatibilityArtistSearchQueryProvider);
      logger.d('Fetching page $pageKey with query: "$searchQuery"');

      // SearchService를 직접 호출하여 provider dispose 문제 회피
      final language = Localizations.localeOf(context).languageCode;
      final newItems = await SearchService.searchArtists(
        query: searchQuery,
        page: pageKey,
        limit: _pageSize,
        language: language,
        supportKoreanInitials: true,
      );

      logger.d('Received ${newItems.length} items for page $pageKey');
      return newItems;
    } catch (e, stackTrace) {
      logger.e('Failed to fetch artist page',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16),
          child: EnhancedSearchBox(
            hintText: AppLocalizations.of(context).text_hint_search,
            onSearchChanged: (query) {
              if (mounted) {
                ref.read(compatibilityArtistSearchQueryProvider.notifier).set(query);
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
    final searchQuery =
        ref.watch(compatibilityArtistSearchQueryProvider);

    return PagingListener<int, ArtistModel>(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) {
        return PagedListView<int, ArtistModel>(
          state: state,
          fetchNextPage: fetchNextPage,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    ? '등록된 아티스트가 없습니다.'
                    : '"$searchQuery"에 대한 검색 결과가 없습니다.',
              );
            },
            firstPageErrorIndicatorBuilder: (context) {
              return buildErrorView(
                context,
                error: _pagingController.value.error?.toString() ??
                    '아티스트 목록을 불러오는데 실패했습니다.',
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
    // 북마크된 아티스트인지 확인하여 영역 구분
    final isBookmarked = item.isBookmarked == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색어가 없을 때만 섹션 헤더 표시
        if (searchQuery.isEmpty) ...[
          // 북마크 섹션 시작 헤더 추가
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
                    '나의 아티스트',
                    style: getTextStyle(AppTypo.caption12M, AppColors.primary500),
                  ),
                ],
              ),
            ),
          // 일반 아티스트 섹션 시작 헤더 추가
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
                    '전체 아티스트',
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                  ),
                ],
              ),
            ),
        ],
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
            ),
            title: _buildHighlightedName(item, searchQuery),
            subtitle: item.artistGroup?.name != null
                ? _buildHighlightedGroupName(item, searchQuery)
                : null,
            onTap: () {
              logger.i('Artist selected: ${getLocaleTextFromJson(item.name)}');
              ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
                    CompatibilityInputPage(artist: item),
                  );
            },
          ),
        ),
        if (searchQuery.isEmpty)
          Divider(height: 1, color: AppColors.grey200),
      ],
    );
  }

  /// 첫 번째 북마크 아이템인지 확인
  bool _isFirstBookmarkItem(int index) {
    final items = _pagingController.value.items;
    if (items == null || index >= items.length) return false;

    final currentItem = items[index];
    // 현재 아이템이 북마크이고, 첫 번째 아이템이거나 이전 아이템이 북마크가 아닌 경우
    return currentItem.isBookmarked == true &&
        (index == 0 || items[index - 1].isBookmarked != true);
  }

  /// 첫 번째 일반(비북마크) 아이템인지 확인
  bool _isFirstNonBookmarkItem(int index) {
    final items = _pagingController.value.items;
    if (items == null || index >= items.length) return false;

    final currentItem = items[index];
    // 현재 아이템이 북마크가 아니고, 첫 번째 아이템이거나 이전 아이템이 북마크인 경우
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

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).compatibility_new_compatibility,
          );
    });
  }
}

