import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
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

  // 현재 사용자 신청 관련 (하단 구간용)
  List<VoteItemRequestUser> _currentUserApplications = [];
  List<Map<String, dynamic>> _currentUserApplicationsWithDetails = [];
  Map<String, int> _userApplicationCounts = {};

  // 모든 사용자 신청 관련 (상단 구간용)
  List<Map<String, dynamic>> _artistApplicationSummaries = [];
  int _totalApplications = 0;
  bool _isLoadingApplications = true; // 상단 섹션 로딩 상태

  // 검색 관련
  List<ArtistModel> _searchResults = [];
  Map<String, ArtistApplicationInfo> _searchResultsInfo = {};
  String _currentSearchQuery = '';
  bool _isSearching = false;
  bool _hasMoreResults = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _lastSearchToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service =
        VoteItemRequestService(ref: ref, voteId: widget.vote.id.toString());
    _loadAllApplicationData();
    _loadInitialArtists();
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
            // 남은 공간을 두 섹션으로 분할 (시각적 균형 고려)
            Expanded(
              child: Column(
                children: [
                  // 모든 사용자 신청 현황 섹션 - 상단
                  Expanded(
                    flex: 3,
                    child: CurrentApplicationsSection(
                      artistApplicationSummaries: _artistApplicationSummaries,
                      totalApplications: _totalApplications,
                      isLoading: _isLoadingApplications,
                    ),
                  ),
                  // 검색 및 결과 섹션 - 하단
                  Expanded(
                    flex: 7,
                    child: SearchAndResultsSection(
                      currentSearchQuery: _currentSearchQuery,
                      onSearchChanged: _onSearchChanged,
                      searchResults: _searchResults,
                      searchResultsInfo: _searchResultsInfo,
                      onSubmitApplication: _submitApplication,
                      isSearching: _isSearching,
                      hasMoreResults: _hasMoreResults,
                      onLoadMore: _loadMoreResults,
                      isLoadingMore: _isLoadingMore,
                    ),
                  ),
                ],
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

  Future<void> _loadInitialArtists() async {
    setState(() {
      _isSearching = true;
      _currentPage = 0;
      _searchResults.clear();
      _searchResultsInfo.clear();
    });

    try {
      // 첫 페이지 로드 (빈 문자열로 검색하여 전체 아티스트 목록을 가져옴)
      await _loadArtistsPage('', page: 0, isInitial: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      logger.e('Failed to load initial artists', error: e);
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
    final results = await _service.searchArtistsWithPagination(
      query,
      page: page,
      pageSize: _pageSize,
    );

    // 검색 토큰이 유효하지 않으면 결과 무시 (이미 새로운 검색이 시작됨)
    if (searchToken != null && _lastSearchToken != searchToken) {
      return;
    }

    if (mounted) {
      final userInfo = ref.read(userInfoProvider).value;
      final applicationData = await _service.loadApplicationDataForResults(
        results['artists'],
        userInfo?.id,
      );

      // 다시 한번 토큰 검증 (긴 작업 후)
      if (searchToken != null && _lastSearchToken != searchToken) {
        return;
      }

      // 신청수 기준으로 정렬 (많은 순서대로)
      final artists = results['artists'] as List<ArtistModel>;
      artists.sort((a, b) {
        final aCount = applicationData[a.id.toString()]?.applicationCount ?? 0;
        final bCount = applicationData[b.id.toString()]?.applicationCount ?? 0;
        return bCount.compareTo(aCount); // 내림차순
      });

      setState(() {
        if (isInitial) {
          _searchResults = artists;
          _searchResultsInfo.clear();
        } else {
          _searchResults.addAll(artists);
        }
        _searchResultsInfo.addAll(applicationData);
        _currentPage = page;
        _hasMoreResults = results['hasMore'] ?? false;
        _isSearching = false;
      });
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
              t('vote_item_request_title'),
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
    _currentSearchQuery = query;

    // 검색 토큰 생성 (동시 요청 방지)
    final searchToken = DateTime.now().millisecondsSinceEpoch.toString();
    _lastSearchToken = searchToken;

    // 검색어가 비어있으면 초기 아티스트 목록 다시 로드
    if (query.isEmpty) {
      await _loadInitialArtists();
      return;
    }

    setState(() {
      _isSearching = true;
      _currentPage = 0;
      _searchResults.clear();
      _searchResultsInfo.clear();
    });

    try {
      // 검색어가 있을 때는 첫 페이지부터 검색
      await _loadArtistsPage(query,
          page: 0, isInitial: true, searchToken: searchToken);
    } catch (e) {
      // 검색 토큰이 여전히 유효한 경우만 에러 상태 설정
      if (mounted && _lastSearchToken == searchToken) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _submitApplication(ArtistModel artist) async {
    try {
      final userInfo = ref.read(userInfoProvider).value;

      logger.d('submitApplication: $userInfo');

      if (userInfo?.id == null) throw Exception('사용자 정보가 없습니다');

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
        // 신청 성공 즉시 해당 아티스트 상태 업데이트
        setState(() {
          final artistId = artist.id.toString();
          if (_searchResultsInfo.containsKey(artistId)) {
            _searchResultsInfo[artistId] =
                _searchResultsInfo[artistId]!.copyWith(
              isSubmitting: false,
              applicationStatus:
                  t('vote_item_request_status_pending'), // 대기중으로 변경
              applicationCount:
                  _searchResultsInfo[artistId]!.applicationCount + 1, // 신청수 증가
            );
          }
        });

        // 상단 섹션만 백그라운드에서 갱신 (하단은 이미 즉시 업데이트됨)
        _loadAllApplicationData();

        // 성공 메시지를 다이얼로그 내부에 표시
        setState(() {
          _errorMessage = '✅ 신청이 완료되었습니다!';
        });

        // 3초 후 성공 메시지 제거
        Future.delayed(Duration(seconds: 3), () {
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
          _errorMessage = e.toString();

          // 신청 실패 시 submitting 상태 해제
          final artistId = artist.id.toString();
          if (_searchResultsInfo.containsKey(artistId)) {
            _searchResultsInfo[artistId] =
                _searchResultsInfo[artistId]!.copyWith(
              isSubmitting: false,
            );
          }
        });
      }
    }
  }

  /// 모든 데이터를 새로고침하는 메서드
  Future<void> _refreshAllData() async {
    try {
      // 상단 섹션 데이터 갱신
      await _loadAllApplicationData();

      // 하단 검색 결과 데이터 갱신 - 기존 검색 결과를 유지하면서 신청 정보만 업데이트
      if (_currentSearchQuery.isNotEmpty && _searchResults.isNotEmpty) {
        logger.d('Refreshing application data for existing search results');

        // 기존 검색 결과에 대한 신청 정보만 다시 로드
        final userInfo = ref.read(userInfoProvider).value;
        final applicationData = await _service.loadApplicationDataForResults(
          _searchResults,
          userInfo?.id,
        );

        if (mounted) {
          setState(() {
            // 기존 검색 결과는 유지하고 신청 정보만 업데이트
            _searchResultsInfo.clear();
            _searchResultsInfo.addAll(applicationData);
          });
        }
      } else if (_currentSearchQuery.isEmpty) {
        // 초기 아티스트 목록 갱신 (검색어가 없는 경우만)
        logger.d('Refreshing initial artists list');
        await _loadInitialArtists();
      }

      logger.d('Data refresh completed successfully');
    } catch (e) {
      logger.e('Failed to refresh data', error: e);
      // 갱신 실패 시에도 기본적인 신청 정보는 업데이트
      if (_searchResults.isNotEmpty) {
        final userInfo = ref.read(userInfoProvider).value;
        try {
          final applicationData = await _service.loadApplicationDataForResults(
            _searchResults,
            userInfo?.id,
          );

          if (mounted) {
            setState(() {
              _searchResultsInfo.clear();
              _searchResultsInfo.addAll(applicationData);
            });
          }
        } catch (fallbackError) {
          logger.e('Fallback data refresh also failed', error: fallbackError);
        }
      }
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
