import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/my_page/vote_artist_list_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class VoteArtistPage extends ConsumerStatefulWidget {
  const VoteArtistPage({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteArtistPage> {
  late PagingController<int, ArtistModel> _pagingController;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();

    logger.i('🎯 VoteArtistPage initState called');

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('🎯 VoteArtistPage setting title');
      try {
        ref.read(navigationInfoProvider.notifier).setMyPageTitle(
            pageTitle: AppLocalizations.of(context).label_mypage_my_artist);
        logger.i('🎯 VoteArtistPage title set successfully');
      } catch (e) {
        logger.e('🎯 VoteArtistPage title setting failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<List<ArtistModel>> _fetchArtistPage(int pageKey) async {
    logger.i(
        '🎯 [VoteArtistPage] _fetchArtistPage called with pageKey: $pageKey');

    try {
      if (!mounted) {
        return [];
      }

      final searchQuery = ref.read(searchQueryProvider);
      logger.d('Fetching page $pageKey with query: "$searchQuery"');

      final newItems =
          await ref.read(asyncVoteArtistListProvider.notifier).fetchArtists(
                page: pageKey,
                query: searchQuery,
                language: Localizations.localeOf(context).languageCode,
              );

      logger.d('Received ${newItems.length} items for page $pageKey');
      return newItems;
    } catch (e, stackTrace) {
      logger.e('Failed to fetch artist page', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('🎯 VoteArtistPage build called');

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16),
          child: EnhancedSearchBox(
            hintText: AppLocalizations.of(context).text_hint_search,
            onSearchChanged: (query) {
              logger.i(
                  '🔍 [VoteArtistPage] Search changed called with query: "$query"');
              if (mounted) {
                try {
                  logger.i(
                      '🔍 [VoteArtistPage] Setting search query and refreshing');
                  ref.read(searchQueryProvider.notifier).state = query;
                  _pagingController.refresh();
                  logger.i(
                      '🔍 [VoteArtistPage] Search query set and refresh triggered');
                } catch (e) {
                  logger.e('Search error', error: e);
                }
              } else {
                logger.w(
                    '🔍 [VoteArtistPage] Widget not mounted, skipping search');
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
    final searchQuery = ref.watch(searchQueryProvider);

    return PagingListener<int, ArtistModel>(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) {
        return PagedListView<int, ArtistModel>(
          state: state,
          fetchNextPage: fetchNextPage,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          builderDelegate: PagedChildBuilderDelegate<ArtistModel>(
            itemBuilder: (context, item, index) {
              // SearchService에서 이미 필터링된 결과를 사용하므로 추가 필터링 불필요
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

    // 🔥🔥🔥 강력한 디버깅 로그 추가
    logger.d('🔥🔥🔥 _buildArtistItem 호출됨 - Index: $index');
    logger.d('🔥🔥🔥 Artist: ${getLocaleTextFromJson(item.name)}');
    logger.d('🔥🔥🔥 isBookmarked: $isBookmarked (raw: ${item.isBookmarked})');
    logger.d(
        '🔥🔥🔥 _isFirstBookmarkItem($index): ${_isFirstBookmarkItem(index)}');
    logger.d(
        '🔥🔥🔥 _isFirstNonBookmarkItem($index): ${_isFirstNonBookmarkItem(index)}');

    // 상세한 디버깅 로그 추가
    logger.i(
        '🎯 _buildArtistItem - Index: $index, Artist: ${getLocaleTextFromJson(item.name)}, isBookmarked: $isBookmarked, raw isBookmarked: ${item.isBookmarked}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  '북마크',
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
            trailing: GestureDetector(
              onTap: () {
                // 디버깅 로그 추가
                logger.i(
                    '🔖 북마크 버튼 탭됨 - Artist: ${getLocaleTextFromJson(item.name)}, isBookmarked: ${item.isBookmarked}');
                _toggleBookmark(item);
              },
              child: Container(
                padding: EdgeInsets.all(10.w), // 패딩을 더 크게
                decoration: BoxDecoration(
                  color: isBookmarked
                      ? AppColors.primary500.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isBookmarked
                      ? Border.all(
                          color: AppColors.primary500.withValues(alpha: 0.3),
                          width: 1)
                      : Border.all(
                          color: Colors.grey.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(
                  item.isBookmarked == true ? Icons.star : Icons.star_border,
                  color: item.isBookmarked == true
                      ? AppColors.primary500
                      : AppColors.grey500, // 색상을 조정
                  size: 24, // 크기 조정
                ),
              ),
            ),
            onTap: () {
              logger.i(
                  'Artist tapped: ${getLocaleTextFromJson(item.name)} - 북마크 상태: $isBookmarked');
            },
          ),
        ),
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

  /// 검색어가 포함된 아티스트 이름을 하이라이트하여 반환
  Widget _buildHighlightedName(ArtistModel item, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Text(
        getLocaleTextFromJson(item.name, context),
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      );
    }

    // 검색어에 매칭되는 언어의 텍스트 찾기
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

  /// 검색어가 포함된 그룹 이름을 하이라이트하여 반환
  Widget _buildHighlightedGroupName(ArtistModel item, String searchQuery) {
    if (item.artistGroup?.name == null) {
      return const SizedBox.shrink();
    }

    if (searchQuery.isEmpty) {
      return Text(
        getLocaleTextFromJson(item.artistGroup!.name, context),
        style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
      );
    }

    // 검색어에 매칭되는 언어의 텍스트 찾기
    final matchingText =
        KoreanSearchUtils.getMatchingText(item.artistGroup!.name, searchQuery);

    return KoreanSearchUtils.buildConditionalHighlightText(
      matchingText,
      searchQuery,
      getTextStyle(AppTypo.caption12R, AppColors.grey500),
      highlightColor: AppColors.primary500.withValues(alpha: 0.3),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Future<void> _toggleBookmark(ArtistModel artist) async {
    try {
      final provider = ref.read(asyncVoteArtistListProvider.notifier);

      if (artist.isBookmarked == true) {
        // 북마크 해제
        final bookmarkedProvider =
            ref.read(asyncBookmarkedArtistsProvider.notifier);
        final success = await provider.unBookmarkArtist(
          artistId: artist.id,
          bookmarkedArtistsRef: bookmarkedProvider,
        );

        if (success) {
          logger.i('북마크 해제됨: ${getLocaleTextFromJson(artist.name)}');
          _pagingController.refresh(); // 리스트 새로고침
        }
      } else {
        // 북마크 추가
        final success = await provider.bookmarkArtist(artistId: artist.id);

        if (success) {
          logger.i('북마크 추가됨: ${getLocaleTextFromJson(artist.name)}');
          _pagingController.refresh(); // 리스트 새로고침
        } else {
          logger.w('북마크 추가 실패 (최대 5개 제한)');
        SnackbarUtil().show(
          AppLocalizations.of(navigatorKey.currentContext!).toast_max_five_celeb,
        );
        }
      }
    } catch (e) {
      logger.e('북마크 토글 실패', error: e);
    }
  }
}
