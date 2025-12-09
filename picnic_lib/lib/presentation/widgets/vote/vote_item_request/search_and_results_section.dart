import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
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
  final ValueChanged<bool>? onSearchFocusChanged;
  final bool showSearchBoxOnly; // 검색창만 표시 (검색 포커스가 아닐 때)
  final VoidCallback? onCloseSearch; // 검색창 닫기 콜백
  final FocusNode? searchFocusNode; // 외부에서 관리하는 FocusNode
  final VoidCallback? onSearchBoxTapped; // 검색창 탭 콜백

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
    this.onSearchFocusChanged,
    this.showSearchBoxOnly = false,
    this.onCloseSearch,
    this.searchFocusNode,
    this.onSearchBoxTapped,
  });

  @override
  State<SearchAndResultsSection> createState() =>
      _SearchAndResultsSectionState();
}

class _SearchAndResultsSectionState extends State<SearchAndResultsSection> {
  final ScrollController _scrollController = ScrollController();
  FocusNode? _internalFocusNode;
  bool _isScrollLoading = false; // 스크롤 로딩 중복 방지

  FocusNode get _searchFocusNode =>
      widget.searchFocusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(SearchAndResultsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 FocusNode가 변경된 경우 리스너 재설정
    if (oldWidget.searchFocusNode != widget.searchFocusNode) {
      oldWidget.searchFocusNode?.removeListener(_onFocusChanged);
      _internalFocusNode?.removeListener(_onFocusChanged);
      _searchFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    // 내부에서 생성한 FocusNode만 dispose
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    widget.onSearchFocusChanged?.call(_searchFocusNode.hasFocus);
  }

  void _onScroll() {
    // 중복 호출 방지
    if (_isScrollLoading ||
        !widget.hasMoreResults ||
        widget.isLoadingMore ||
        widget.onLoadMore == null) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 80% 지점에 도달하면 추가 로드
    if (currentScroll >= maxScroll * 0.8) {
      _isScrollLoading = true;
      widget.onLoadMore!();

      // 0.5초 후 다시 스크롤 로딩 허용
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isScrollLoading = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 검색창만 표시 (초기 상태)
    if (widget.showSearchBoxOnly) {
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
        child: _buildSearchHeader(),
      );
    }

    // 검색 결과와 함께 표시 (Expanded)
    return Expanded(
      child: Container(
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

            // 검색 결과 영역
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    final isSearchMode = !widget.showSearchBoxOnly;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.r, 12.r, 12.r, 8.r),
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
                  AppLocalizations.of(context).vote_item_request_search_artist,
                  style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                ),
              ),
              // 검색 모드일 때 닫기 버튼 표시
              if (isSearchMode && widget.onCloseSearch != null)
                GestureDetector(
                  onTap: () {
                    _searchFocusNode.unfocus();
                    widget.onCloseSearch?.call();
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.grey600,
                      size: 14.r,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8.h),

          // 검색 입력 박스
          // showSearchBoxOnly 모드일 때는 GestureDetector로 감싸서 탭 시 레이아웃 먼저 변경
          if (widget.showSearchBoxOnly && widget.onSearchBoxTapped != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSearchBoxTapped,
              child: AbsorbPointer(
                child: EnhancedSearchBox(
                  hintText: AppLocalizations.of(context)
                      .vote_item_request_search_artist_hint,
                  onSearchChanged: widget.onSearchChanged,
                  showClearButton: true,
                  showSearchIcon: true,
                  autofocus: false,
                  focusNode: _searchFocusNode,
                  style: getTextStyle(AppTypo.body14R, AppColors.grey900),
                  hintStyle: getTextStyle(AppTypo.caption12R, AppColors.grey400),
                  height: 36.h,
                  debounceTime: const Duration(milliseconds: 200),
                ),
              ),
            )
          else
            EnhancedSearchBox(
              hintText: AppLocalizations.of(context)
                  .vote_item_request_search_artist_hint,
              onSearchChanged: widget.onSearchChanged,
              showClearButton: true,
              showSearchIcon: true,
              autofocus: false,
              focusNode: _searchFocusNode,
              style: getTextStyle(AppTypo.body14R, AppColors.grey900),
              hintStyle: getTextStyle(AppTypo.caption12R, AppColors.grey400),
              height: 36.h,
              debounceTime: const Duration(milliseconds: 200),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // 초기 상태: 검색어가 없으면 안내 메시지 표시
    final hasSearchQuery = widget.currentSearchQuery.trim().isNotEmpty;

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
          : !hasSearchQuery
              ? _buildInitialState() // 초기 상태 (검색어 없음)
              : widget.searchResults.isEmpty
                  ? _buildEmptyState() // 검색 결과 없음
                  : _buildResultsList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12.r, 8.r, 12.r, 12.r),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.grey200.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Row(
          children: [
            // 아티스트 이미지 스켈레톤
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(width: 12.w),
            // 아티스트 정보 스켈레톤
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: 10.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // 액션 버튼 스켈레톤
            Container(
              width: 45.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 초기 상태: 검색어 입력 전 안내 메시지
  Widget _buildInitialState() {
    return SizedBox(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primary500,
                size: 32.r,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context).vote_item_request_search_initial_guide,
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
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
              AppLocalizations.of(context).vote_item_request_no_search_results,
              style: getTextStyle(AppTypo.body14B, AppColors.grey600),
            ),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context).vote_item_request_search_try_other_keyword,
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
      padding: EdgeInsets.fromLTRB(16.r, 8.r, 16.r, 16.r),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.searchResults.length +
          (widget.hasMoreResults && widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 마지막 아이템이 로딩 인디케이터인지 확인
        if (index == widget.searchResults.length &&
            widget.hasMoreResults &&
            widget.isLoadingMore) {
          return _buildLoadMoreIndicator();
        }

        // 나머지는 아티스트 아이템
        final artistIndex = index;
        final artist = widget.searchResults[artistIndex];
        final applicationInfo = widget.searchResultsInfo[artist.id.toString()];
        final isInfoLoaded = applicationInfo != null;

        // 신청 정보가 로드되지 않았으면 기본값 사용
        final displayInfo = applicationInfo ??
            ArtistApplicationInfo(
              artistName: ArtistNameUtils.getDisplayName(artist.name),
              applicationCount: 0,
              applicationStatus:
                  AppLocalizations.of(context).vote_item_request_can_apply,
              isAlreadyInVote: false,
              isSubmitting: false,
            );

        return Container(
          key: ValueKey('search_result_${artist.id}'),
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(6.r),
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
            width: 32.w,
            height: 32.w,
            currentSearchQuery: widget.currentSearchQuery,
            listIndex: artistIndex,
            trailing: SearchResultActionButton(
              shouldShowApplicationButton: isInfoLoaded &&
                  !displayInfo.isAlreadyInVote &&
                  displayInfo.applicationStatus ==
                      AppLocalizations.of(context).vote_item_request_can_apply,
              isSubmitting: displayInfo.isSubmitting,
              isAlreadyInVote: displayInfo.isAlreadyInVote,
              status: displayInfo.applicationStatus,
              onPressed: () => widget.onSubmitApplication(artist),
              isLoading: !isInfoLoaded,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Column(
      children: List.generate(3, (_) => _buildSkeletonItem()),
    );
  }
}
