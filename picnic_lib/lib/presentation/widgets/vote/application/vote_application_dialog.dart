import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote_request.dart';
import 'package:picnic_lib/data/models/vote/vote_request_user.dart';
import 'package:picnic_lib/data/repositories/vote_request_repository.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_request_provider.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/services/vote_application_service_provider.dart'
    hide voteRequestRepositoryProvider;
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

Future showVoteApplicationDialog({
  required BuildContext context,
  required VoteModel voteModel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return VoteApplicationDialog(
        vote: voteModel,
      );
    },
  );
}

class VoteApplicationDialog extends ConsumerStatefulWidget {
  final VoteModel vote;

  const VoteApplicationDialog({
    super.key,
    required this.vote,
  });

  @override
  ConsumerState<VoteApplicationDialog> createState() {
    return _VoteApplicationDialogState();
  }
}

class _VoteApplicationDialogState extends ConsumerState<VoteApplicationDialog> {
  bool _isSubmitting = false;
  bool _isSearching = false;
  String? _errorMessage;
  List<ArtistModel> _searchResults = [];
  String _currentSearchQuery = '';
  Map<String, int> _artistApplicationCounts = {};
  Map<String, String> _artistApplicationStatus = {};
  Map<String, bool> _artistAlreadyInVote = {};
  List<VoteRequestUser> _currentUserApplications = [];
  List<Map<String, dynamic>> _currentUserApplicationsWithDetails = [];
  Map<String, int> _userApplicationCounts = {}; // 사용자 신청별 총 신청 수

  @override
  void initState() {
    super.initState();
    _loadApplicationCounts();
  }

  Future<void> _loadApplicationCounts() async {
    try {
      final voteRequestRepository = ref.read(voteRequestRepositoryProvider);
      final userInfoAsync = ref.read(userInfoProvider);
      final userInfo = userInfoAsync.value;

      // 전체 투표 신청 수 조회
      final totalCount = await voteRequestRepository
          .getVoteApplicationCount(widget.vote.id.toString());

      // 현재 사용자의 신청 내역 조회
      if (userInfo?.id != null) {
        final userApplicationsWithDetails =
            await voteRequestRepository.getCurrentUserApplicationsWithDetails(
                widget.vote.id.toString(), userInfo!.id!);

        // 각 사용자 신청에 대한 총 신청 수 조회
        final Map<String, int> applicationCounts = {};
        final List<VoteRequestUser> userApplications = [];

        for (final applicationData in userApplicationsWithDetails) {
          try {
            // VoteRequestUser 객체 생성
            final application = VoteRequestUser.fromJson(applicationData);
            userApplications.add(application);

            // vote_requests에서 제목 추출
            final voteRequest = applicationData['vote_requests'];
            if (voteRequest != null) {
              final title = voteRequest['title'] as String?;
              if (title != null) {
                final count =
                    await voteRequestRepository.getApplicationCountByTitle(
                        widget.vote.id.toString(), title);
                applicationCounts[application.id] = count;
              }
            }
          } catch (e) {
            logger.w('신청 데이터 처리 실패: $e');
          }
        }

        if (mounted) {
          setState(() {
            _currentUserApplications = userApplications;
            _currentUserApplicationsWithDetails = userApplicationsWithDetails;
            _userApplicationCounts = applicationCounts;
          });
        }
      }

      logger.d(
          '투표 신청 수 로딩 완료: 총 $totalCount개, 사용자 신청 ${_currentUserApplications.length}개');
    } catch (e) {
      logger.e('신청 수 로딩 실패', error: e);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SearchService.searchArtists(
        query: query,
        page: 0,
        limit: 50,
        supportKoreanInitials: true,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // 검색 결과에 대한 신청 수/상태 로딩
        _loadApplicationDataForResults(results);
      }
    } catch (e) {
      logger.e('아티스트 검색 실패', error: e);
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadApplicationDataForResults(List<ArtistModel> artists) async {
    try {
      final voteRequestRepository = ref.read(voteRequestRepositoryProvider);
      final userInfoAsync = ref.read(userInfoProvider);
      final userInfo = userInfoAsync.value;

      for (final artist in artists) {
        final artistName = getLocaleTextFromJson(artist.name);

        try {
          // 실제 신청 수 가져오기 (아티스트별)
          final applicationCount = await voteRequestRepository
              .getArtistApplicationCount(widget.vote.id.toString(), artistName);

          // 아티스트가 이미 이 투표의 vote_item에 등록되었는지 확인
          final isAlreadyInVote = await _checkIfArtistInVoteItems(artistName);

          // 현재 사용자의 해당 아티스트에 대한 신청 상태 가져오기
          String applicationStatus = '신청 가능';
          if (userInfo?.id != null) {
            final userApplication =
                await voteRequestRepository.getUserApplicationStatus(
                    widget.vote.id.toString(), userInfo!.id!, artistName);

            if (userApplication != null) {
              switch (userApplication.status.toLowerCase()) {
                case 'pending':
                  applicationStatus = '대기중';
                  break;
                case 'approved':
                  applicationStatus = '승인됨';
                  break;
                case 'rejected':
                  applicationStatus = '거절됨';
                  break;
                case 'in-progress':
                  applicationStatus = '진행중';
                  break;
                case 'cancelled':
                  applicationStatus = '취소됨';
                  break;
                default:
                  applicationStatus = '신청 가능';
              }
            }
          }

          if (mounted) {
            setState(() {
              _artistApplicationCounts[artistName] = applicationCount;
              _artistApplicationStatus[artistName] = applicationStatus;
              _artistAlreadyInVote[artistName] = isAlreadyInVote;
            });
          }
        } catch (e) {
          logger.w('아티스트 $artistName의 신청 데이터 로딩 실패: $e');
          // 오류 발생 시 기본값 설정
          if (mounted) {
            setState(() {
              _artistApplicationCounts[artistName] = 0;
              _artistApplicationStatus[artistName] = '신청 가능';
              _artistAlreadyInVote[artistName] = false;
            });
          }
        }
      }
    } catch (e) {
      logger.e('신청 데이터 로딩 실패', error: e);
      // 전체 오류 발생 시 기본값으로 설정
      for (final artist in artists) {
        final artistName = getLocaleTextFromJson(artist.name);
        if (mounted) {
          setState(() {
            _artistApplicationCounts[artistName] = 0;
            _artistApplicationStatus[artistName] = '신청 가능';
            _artistAlreadyInVote[artistName] = false;
          });
        }
      }
    }
  }

  // 아티스트가 이미 이 투표의 vote_item에 등록되었는지 확인
  Future<bool> _checkIfArtistInVoteItems(String artistName) async {
    try {
      // vote_item 테이블을 artist 테이블과 조인하여 아티스트 이름으로 확인
      final supabase = Supabase.instance.client;
      final response = await supabase.from('vote_item').select('''
            id,
            artist!inner(name)
          ''').eq('vote_id', widget.vote.id.toString());

      if (response != null && response is List) {
        // 모든 vote_item을 확인하여 아티스트 이름이 일치하는지 검사
        for (final item in response) {
          if (item['artist'] != null) {
            final artistData = item['artist'];
            final artistNameFromDb = getLocaleTextFromJson(artistData['name']);
            if (artistNameFromDb == artistName) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      logger.w('아티스트 등록 상태 확인 실패: $e');
      return false; // 오류 시 등록되지 않은 것으로 간주
    }
  }

  Future<void> _submitApplication(ArtistModel artist) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userInfoAsync = ref.read(userInfoProvider);
      final userInfo = userInfoAsync.value;
      if (userInfo?.id == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final voteApplicationService = ref.read(voteApplicationServiceProvider);

      final artistName = getLocaleTextFromJson(artist.name);
      final groupName = artist.artistGroup != null
          ? getLocaleTextFromJson(artist.artistGroup!.name)
          : null;

      await voteApplicationService.submitApplication(
        voteId: widget.vote.id.toString(),
        userId: userInfo!.id!,
        title: artistName,
        description: '투표 아이템 추가 신청', // 10자 이상 조건 충족하는 간단한 설명
        artistName: artistName,
        groupName: groupName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        showSimpleDialog(
          title: t('success'),
          content: t('application_success'),
        );
      }
    } catch (e) {
      logger.e('투표 신청 실패', error: e);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height - 80.h, // 화면 높이에서 여백만 제외
        decoration: BoxDecoration(
          color: AppColors.grey00,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('vote_application_title'),
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      print('닫기 버튼 클릭됨'); // 디버그용
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(
                        Icons.close,
                        color: AppColors.grey600,
                        size: 24.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 내용
            Expanded(
              child: Column(
                children: [
                  // 현재 신청 리스트 섹션
                  _buildCurrentApplicationsSection(),

                  // 검색 섹션
                  _buildSearchSection(),

                  // 검색 결과
                  Expanded(
                    child: _buildSearchResults(),
                  ),
                ],
              ),
            ),

            // 오류 메시지
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.all(16.r),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: getTextStyle(AppTypo.caption12R, Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentApplicationsSection() {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Text(
              '현재 신청 목록',
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            ),
          ),
          Container(
            height: 120.h,
            child: _currentUserApplications.isEmpty
                ? Center(
                    child: Text(
                      '아직 신청된 항목이 없습니다',
                      style:
                          getTextStyle(AppTypo.caption12R, AppColors.grey500),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.r),
                    itemCount: _currentUserApplications.length,
                    itemBuilder: (context, index) {
                      final application = _currentUserApplications[index];
                      return _buildUserApplicationItem(application);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserApplicationItem(VoteRequestUser application) {
    // 상태를 한글로 변환
    String getStatusText(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return '대기중';
        case 'approved':
          return '승인됨';
        case 'rejected':
          return '거절됨';
        case 'in-progress':
          return '진행중';
        case 'cancelled':
          return '취소됨';
        default:
          return '알 수 없음';
      }
    }

    // 상태에 따른 색상 설정
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'in-progress':
          return AppColors.primary500;
        case 'cancelled':
          return AppColors.grey400;
        default:
          return AppColors.grey400;
      }
    }

    // 상세 데이터에서 아티스트명 추출
    String getArtistName() {
      try {
        // _currentUserApplicationsWithDetails에서 해당 application과 매칭되는 데이터 찾기
        final detailData = _currentUserApplicationsWithDetails.firstWhere(
          (detail) => detail['id'] == application.id,
          orElse: () => <String, dynamic>{},
        );

        if (detailData.isNotEmpty && detailData['vote_requests'] != null) {
          final voteRequest = detailData['vote_requests'];
          return voteRequest['title'] as String? ?? '아티스트명 없음';
        }
        return '아티스트명 없음';
      } catch (e) {
        logger.w('아티스트명 추출 실패: $e');
        return '아티스트명 없음';
      }
    }

    final artistName = getArtistName();
    final applicationCount = _userApplicationCounts[application.id] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아티스트 이름 표시
                Text(
                  artistName,
                  style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '총 신청 ${applicationCount}개',
                  style: getTextStyle(AppTypo.caption12M, AppColors.primary500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      getStatusColor(application.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: getStatusColor(application.status)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  getStatusText(application.status),
                  style: getTextStyle(
                      AppTypo.caption10SB, getStatusColor(application.status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아티스트 검색',
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
          ),
          SizedBox(height: 8.h),
          EnhancedSearchBox(
            hintText: t('search_artist_hint'),
            onSearchChanged: _onSearchChanged,
            showClearButton: true,
            showSearchIcon: true,
            autofocus: false,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentSearchQuery.isEmpty) {
      return Center(
        child: Text(
          '아티스트명을 검색하여 신청해 보세요',
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다',
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final artist = _searchResults[index];
        return _buildSearchResultItem(artist);
      },
    );
  }

  Widget _buildSearchResultItem(ArtistModel artist) {
    final artistName = getLocaleTextFromJson(artist.name);
    final groupName = artist.artistGroup != null
        ? getLocaleTextFromJson(artist.artistGroup!.name)
        : '';
    final applicationCount = _artistApplicationCounts[artistName] ?? 0;
    final status = _artistApplicationStatus[artistName] ?? '신청 가능';
    final isAlreadyInVote = _artistAlreadyInVote[artistName] ?? false;

    // 신청 버튼을 표시할지 결정하는 조건
    final shouldShowApplicationButton =
        _shouldShowApplicationButton(status, isAlreadyInVote);

    // 표시할 상태 텍스트 결정
    String displayStatus = status;
    if (isAlreadyInVote) {
      displayStatus = '이미 등록됨';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: (shouldShowApplicationButton && !_isSubmitting)
            ? () => _submitApplication(artist)
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // 아티스트 이미지
              Container(
                width: 50.w,
                height: 50.h,
                child: ClipOval(
                  child: artist.image != null
                      ? PicnicCachedNetworkImage(
                          imageUrl: artist.image!,
                          fit: BoxFit.cover,
                          width: 50.w,
                          height: 50.h,
                        )
                      : Container(
                          color: AppColors.grey200,
                          child: Icon(
                            Icons.person,
                            color: AppColors.grey500,
                            size: 24.r,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12.w),

              // 아티스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KoreanSearchUtils.buildConditionalHighlightText(
                      artistName,
                      _currentSearchQuery,
                      getTextStyle(AppTypo.body16B, AppColors.grey900),
                      highlightColor:
                          AppColors.primary500.withValues(alpha: 0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (groupName.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      KoreanSearchUtils.buildConditionalHighlightText(
                        groupName,
                        _currentSearchQuery,
                        getTextStyle(AppTypo.caption12R, AppColors.grey600),
                        highlightColor:
                            AppColors.primary500.withValues(alpha: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 신청 정보 및 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '신청 ${applicationCount}개',
                    style:
                        getTextStyle(AppTypo.caption12M, AppColors.primary500),
                  ),
                  SizedBox(height: 4.h),
                  // 신청 버튼 또는 상태 표시
                  if (_shouldShowApplicationButton(
                      displayStatus, isAlreadyInVote))
                    ElevatedButton(
                      onPressed: () => _submitApplication(artist),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 30),
                      ),
                      child: const Text(
                        '신청',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else if (isAlreadyInVote)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '이미 등록됨',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(), // 아무것도 표시하지 않음
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 신청 버튼을 표시할지 결정하는 조건
  bool _shouldShowApplicationButton(String status, bool isAlreadyInVote) {
    // 이미 투표에 등록된 경우
    if (isAlreadyInVote) return false;

    // 거절된 경우
    if (status.toLowerCase() == '거절됨') return false;

    // 내가 이미 신청한 경우 (대기중, 승인됨, 진행중)
    if (status == '대기중' || status == '승인됨' || status == '진행중') return false;

    // 신청 가능한 경우만 true
    return status == '신청 가능';
  }
}
