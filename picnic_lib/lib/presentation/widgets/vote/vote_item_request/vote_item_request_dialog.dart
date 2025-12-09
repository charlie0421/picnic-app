import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/current_applications_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_and_results_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart';
import 'package:picnic_lib/ui/style.dart';

Future showVoteItemRequestDialog({
  required BuildContext context,
  required VoteModel voteModel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return VoteItemRequestDialog(
        vote: voteModel,
      );
    },
  );
}

class VoteItemRequestDialog extends ConsumerStatefulWidget {
  final VoteModel vote;

  const VoteItemRequestDialog({
    super.key,
    required this.vote,
  });

  @override
  ConsumerState<VoteItemRequestDialog> createState() =>
      _VoteItemRequestDialogState();
}

class _VoteItemRequestDialogState extends ConsumerState<VoteItemRequestDialog> {
  late VoteItemRequestService _service;
  final FocusNode _searchFocusNode = FocusNode();

  // 현재 사용자 신청 관련 (하단 구간용)

  // 모든 사용자 신청 관련 (상단 구간용)
  List<Map<String, dynamic>> _artistApplicationSummaries = [];
  int _totalApplications = 0;
  bool _isLoadingApplications = true; // 상단 섹션 로딩 상태

  // 검색 관련
  List<ArtistModel> _searchResults = [];
  final Map<String, ArtistApplicationInfo> _searchResultsInfo = {};
  String _currentSearchQuery = '';
  bool _isSearching = false;
  bool _hasMoreResults = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _lastSearchToken;
  String? _errorMessage;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _service =
        VoteItemRequestService(ref: ref, voteId: widget.vote.id.toString());
    _loadAllApplicationData();
    // 초기에는 아티스트 목록 로드하지 않음
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 검색창 탭 시 호출: 레이아웃 먼저 변경 후 포커스 요청
  void _onSearchBoxTapped() {
    if (_isSearchFocused) return;

    // 1. 먼저 레이아웃 변경 (검색 모드로 전환)
    setState(() {
      _isSearchFocused = true;
    });

    // 2. 레이아웃 변경 완료 후 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height - 64.h,
        decoration: BoxDecoration(
          color: AppColors.grey00,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            // 검색창 - 항상 상단에 표시
            SearchAndResultsSection(
              currentSearchQuery: _currentSearchQuery,
              onSearchChanged: _onSearchChanged,
              searchResults: _searchResults,
              searchResultsInfo: _searchResultsInfo,
              onSubmitApplication: _submitApplication,
              isSearching: _isSearching,
              hasMoreResults: _hasMoreResults,
              onLoadMore: _loadMoreResults,
              isLoadingMore: _isLoadingMore,
              showSearchBoxOnly: !_isSearchFocused,
              searchFocusNode: _searchFocusNode,
              onSearchBoxTapped: _onSearchBoxTapped,
              onCloseSearch: () {
                _searchFocusNode.unfocus();
                setState(() {
                  _isSearchFocused = false;
                  _searchResults.clear();
                  _searchResultsInfo.clear();
                  _currentSearchQuery = '';
                });
              },
            ),
            // 신청 현황 섹션 - 검색 포커스가 아닐 때 표시
            if (!_isSearchFocused)
              Expanded(
                child: CurrentApplicationsSection(
                  artistApplicationSummaries: _artistApplicationSummaries,
                  totalApplications: _totalApplications,
                  isLoading: _isLoadingApplications,
                ),
              ),
            if (_errorMessage != null) _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  // 모든 사용자 신청 데이터 로딩 (상단 섹션용)
  Future<void> _loadAllApplicationData() async {
    try {
      setState(() {
        _isLoadingApplications = true;
      });

      final result = await _service.loadAllApplicationsByArtist();

      if (mounted) {
        setState(() {
          _artistApplicationSummaries = result['artistApplicationSummaries'];
          _totalApplications = result['totalApplications'];
          _isLoadingApplications = false;
        });
      }
    } catch (e) {
      logger.e('모든 신청 데이터 로딩 실패', error: e);
      if (mounted) {
        setState(() {
          _isLoadingApplications = false;
        });
      }
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    setState(() => _isLoadingMore = true);

    try {
      await _loadArtistsPage(_currentSearchQuery, page: _currentPage + 1);
    } catch (e) {
      logger.e('Failed to load more results', error: e);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadArtistsPage(String query,
      {required int page, bool isInitial = false, String? searchToken}) async {
    logger.d(
        '📋 _loadArtistsPage 시작 - 검색어: "$query", 페이지: $page, 초기로드: $isInitial');

    final results = await _service.searchArtistsWithPagination(
      query,
      page: page,
      pageSize: _pageSize,
    );

    logger.d('📋 검색 서비스 결과: ${results['artists']?.length ?? 0}개 아티스트');

    // 검색 토큰이 유효하지 않으면 결과 무시 (이미 새로운 검색이 시작됨)
    if (searchToken != null && _lastSearchToken != searchToken) {
      logger.d('📋 검색 토큰 불일치로 결과 무시');
      return;
    }

    if (mounted) {
      final artists = results['artists'] as List<ArtistModel>;

      // 1단계: 검색 결과 먼저 표시 (신청 정보 없이)
      setState(() {
        if (isInitial) {
          _searchResults = artists;
          _searchResultsInfo.clear();
          logger.d('📋 초기 로드 - 검색 결과 즉시 표시: ${artists.length}개');
        } else {
          _searchResults.addAll(artists);
          logger.d('📋 추가 로드 - 검색 결과 추가: ${artists.length}개 (총 ${_searchResults.length}개)');
        }
        _currentPage = page;
        _hasMoreResults = results['hasMore'] ?? false;
        _isSearching = false;
      });

      // 2단계: 신청 정보를 백그라운드에서 로드
      _loadApplicationDataInBackground(artists, searchToken);
    }
  }

  /// 신청 정보를 백그라운드에서 로드하고 UI 업데이트
  Future<void> _loadApplicationDataInBackground(
      List<ArtistModel> artists, String? searchToken) async {
    try {
      final userInfo = ref.read(userInfoProvider).value;
      logger.d('📋 백그라운드 신청 정보 로드 시작: ${artists.length}개');

      final applicationData = await _service.loadApplicationDataForResults(
        artists,
        userInfo?.id,
      );

      // 토큰 검증 (다른 검색이 시작되었으면 무시)
      if (searchToken != null && _lastSearchToken != searchToken) {
        logger.d('📋 신청 정보 로드 완료했으나 토큰 불일치로 무시');
        return;
      }

      if (mounted) {
        setState(() {
          _searchResultsInfo.addAll(applicationData);
        });
        logger.d('📋 신청 정보 UI 업데이트 완료: ${applicationData.length}개');
      }
    } catch (e) {
      logger.e('📋 백그라운드 신청 정보 로드 실패', error: e);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.r, 12.r, 12.r, 12.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.05),
            AppColors.primary500.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary500.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.how_to_vote_rounded,
              color: AppColors.primary500,
              size: 18.r,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).vote_item_request_title,
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.grey600,
                size: 20.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String query) async {
    logger.d('🔍 검색 시작: "$query" (이전: "$_currentSearchQuery")');

    // 검색 토큰 생성 (중복 요청 방지)
    final searchToken = DateTime.now().millisecondsSinceEpoch.toString();
    _lastSearchToken = searchToken;

    setState(() {
      _currentSearchQuery = query;
      _isSearching = true;
      _currentPage = 0;
    });

    // EnhancedSearchBox에서 이미 디바운싱 처리하므로 즉시 검색 실행
    if (mounted) {
      logger.d('🔍 검색 실행: "$query"');
      await _loadArtistsPage(query,
          page: 0, isInitial: true, searchToken: searchToken);
    }
  }

  Future<void> _submitApplication(ArtistModel artist) async {
    try {
      final userInfo = ref.read(userInfoProvider).value;

      logger.d('submitApplication: $userInfo');

      // 로그인되지 않은 경우 로그인 유도 다이얼로그 표시
      if (userInfo?.id == null) {
        showRequireLoginDialog();
        return;
      }

      // 신청 중 상태로 UI 업데이트
      setState(() {
        final artistId = artist.id.toString();
        if (_searchResultsInfo.containsKey(artistId)) {
          _searchResultsInfo[artistId] = _searchResultsInfo[artistId]!.copyWith(
            isSubmitting: true,
          );
        }
        _errorMessage = null; // 기존 에러 메시지 제거
      });

      await _service.submitApplication(artist, userInfo!.id!);

      if (mounted) {
        // 신청 성공 시 검색 포커스 해제하여 상단 섹션 표시
        FocusScope.of(context).unfocus();

        // 신청 성공 즉시 해당 아티스트 상태 업데이트
        setState(() {
          _isSearchFocused = false;
          final artistId = artist.id.toString();
          if (_searchResultsInfo.containsKey(artistId)) {
            _searchResultsInfo[artistId] =
                _searchResultsInfo[artistId]!.copyWith(
              isSubmitting: false,
              applicationStatus: AppLocalizations.of(context)
                  .vote_item_request_status_pending, // 대기중으로 변경
              applicationCount:
                  _searchResultsInfo[artistId]!.applicationCount + 1, // 신청수 증가
            );
          }
        });

        // 전체 데이터 완전 갱신 (상단/하단 모두)
        await _refreshAllData();

        // 성공 메시지를 다이얼로그 내부에 표시
        setState(() {
          _errorMessage = '✅ 신청이 완료되었습니다!';
        });

        // 3초 후 성공 메시지 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final artistId = artist.id.toString();
          if (_searchResultsInfo.containsKey(artistId)) {
            _searchResultsInfo[artistId] =
                _searchResultsInfo[artistId]!.copyWith(
              isSubmitting: false,
            );
          }
          _errorMessage = e.toString().contains('already_applied')
              ? '이미 신청한 아티스트입니다'
              : '신청 중 오류가 발생했습니다: ${e.toString()}';
        });

        // 3초 후 에러 메시지 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
      logger.e('신청 실패', error: e);
    }
  }

  /// 전체 데이터 갱신 (상단/하단 모두)
  Future<void> _refreshAllData() async {
    try {
      logger.d(
          '🔄 _refreshAllData 시작 - 현재 검색어: "$_currentSearchQuery", 검색 결과: ${_searchResults.length}개');

      // 1. 상단 섹션 데이터 갱신
      await _loadAllApplicationData();

      // 2. 하단 섹션 데이터 갱신 - 현재 검색 상태 유지
      if (_searchResults.isNotEmpty) {
        // 기존 검색 결과가 있으면 신청 정보만 갱신
        logger.d('🔄 기존 검색 결과 유지하고 신청 정보만 갱신: ${_searchResults.length}개');

        final userInfo = ref.read(userInfoProvider).value;
        final applicationData = await _service.loadApplicationDataForResults(
          _searchResults,
          userInfo?.id,
        );

        logger.d('🔄 신청 정보 갱신 완료: ${applicationData.length}개');

        if (mounted) {
          setState(() {
            // 기존 검색 결과는 유지하고 신청 정보만 업데이트
            _searchResultsInfo.clear();
            _searchResultsInfo.addAll(applicationData);
          });
          logger.d(
              '🔄 UI 상태 업데이트 완료 - 검색 결과: ${_searchResults.length}개, 정보: ${_searchResultsInfo.length}개');
        }
      } else if (_currentSearchQuery.isNotEmpty) {
        // 검색어가 있지만 결과가 없으면 검색 다시 실행
        logger.d('🔄 검색어가 있지만 결과가 없음 - 검색 다시 실행: "$_currentSearchQuery"');
        await _onSearchChanged(_currentSearchQuery);
      }

      logger.d('🔄 _refreshAllData 완료');
    } catch (e) {
      logger.e('전체 데이터 갱신 실패: $e');
    }
  }

  Widget _buildErrorMessage() {
    final isSuccess = _errorMessage!.startsWith('✅');

    return Container(
      margin: EdgeInsets.all(20.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: getTextStyle(
                AppTypo.body14R,
                isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
