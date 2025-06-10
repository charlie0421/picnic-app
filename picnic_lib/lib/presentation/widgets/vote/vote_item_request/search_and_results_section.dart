import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/ui/style.dart';
import 'vote_item_request_models.dart';
import 'common_artist_widget.dart';
import 'search_result_action_button.dart';

/// 검색 및 결과 통합 섹션 위젯
class SearchAndResultsSection extends StatefulWidget {
  final String currentSearchQuery;
  final Function(String) onSearchChanged;
  final List<ArtistModel> searchResults;
  final Map<String, ArtistApplicationInfo> searchResultsInfo;
  final Function(ArtistModel) onSubmitApplication;
  final bool isSearching;
  final bool hasMoreResults;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const SearchAndResultsSection({
    super.key,
    required this.currentSearchQuery,
    required this.onSearchChanged,
    required this.searchResults,
    required this.searchResultsInfo,
    required this.onSubmitApplication,
    required this.isSearching,
    this.hasMoreResults = false,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  State<SearchAndResultsSection> createState() => _SearchAndResultsSectionState();
}

class _SearchAndResultsSectionState extends State<SearchAndResultsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMoreResults || widget.isLoadingMore || widget.onLoadMore == null) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // 80% 지점에 도달하면 추가 로드
    if (currentScroll >= maxScroll * 0.8) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.grey200.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 헤더 및 입력 영역
          _buildSearchHeader(),
          
          // 검색 결과 영역 (항상 표시)
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 정보
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary500,
                  size: 14.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  t('vote_item_request_search_artist'),
                  style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10.h),
          
          // 검색 입력 박스
          SizedBox(
            height: 36.h,
            child: EnhancedSearchBox(
              hintText: t('vote_item_request_search_artist_hint'),
              onSearchChanged: widget.onSearchChanged,
              showClearButton: true,
              showSearchIcon: true,
              autofocus: false,
              style: getTextStyle(AppTypo.body14R, AppColors.grey900),
              hintStyle: getTextStyle(AppTypo.body14R, AppColors.grey400),
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.grey200.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: widget.isSearching
          ? _buildLoadingState()
          : widget.searchResults.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary500,
              strokeWidth: 2,
            ),
            SizedBox(height: 12.h),
            Text(
              '아티스트를 검색하고 있습니다...',
              style: getTextStyle(AppTypo.body14R, AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.grey200.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.grey500,
                size: 32.r,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '검색 결과가 없습니다',
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
            ),
            SizedBox(height: 4.h),
            Text(
              '다른 키워드로 검색해보세요',
              style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 16.r),
      physics: BouncingScrollPhysics(),
      itemCount: widget.searchResults.length + (widget.hasMoreResults && widget.isLoadingMore ? 1 : 0), // 아이템들 + 로딩 인디케이터
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        
        // 마지막 아이템이 로딩 인디케이터인지 확인
        if (index == widget.searchResults.length && widget.hasMoreResults && widget.isLoadingMore) {
          return _buildLoadMoreIndicator();
        }
        
        // 나머지는 아티스트 아이템
        final artistIndex = index;
        final artist = widget.searchResults[artistIndex];
        final applicationInfo = widget.searchResultsInfo[artist.id.toString()] ?? 
            ArtistApplicationInfo(
              artistName: ArtistNameUtils.getDisplayName(artist.name),
              applicationCount: 0,
              applicationStatus: t('vote_item_request_can_apply'),
              isAlreadyInVote: false,
              isSubmitting: false,
            );
    
        return Container(
          margin: EdgeInsets.only(bottom: 2.h), // 간격 더 축소 (4.h -> 2.h)
          padding: EdgeInsets.all(6.r), // 패딩 더 축소 (8.r -> 6.r)
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.grey200.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: CommonArtistWidget(
            artist: artist,
            artistName: ArtistNameUtils.getDisplayName(artist.name),
            groupName: artist.artistGroup?.name != null 
                ? ArtistNameUtils.getDisplayName(artist.artistGroup!.name)
                : null,
            applicationCount: applicationInfo.applicationCount,
            width: 32.w, // 크기 더 축소 (36.w -> 32.w)
            height: 32.w, // 크기 더 축소 (36.w -> 32.w)
            currentSearchQuery: widget.currentSearchQuery,
            listIndex: artistIndex,
            trailing: SearchResultActionButton(
              shouldShowApplicationButton: !applicationInfo.isAlreadyInVote &&
                  applicationInfo.applicationStatus == t('vote_item_request_can_apply'),
              isSubmitting: applicationInfo.isSubmitting,
              isAlreadyInVote: applicationInfo.isAlreadyInVote,
              status: applicationInfo.applicationStatus,
              onPressed: () => widget.onSubmitApplication(artist),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                color: AppColors.primary500,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '더 많은 아티스트를 불러오는 중...',
              style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
} 