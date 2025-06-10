import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote_request_user.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_request_provider.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/services/vote_item_request_service_provider.dart'
    hide voteRequestRepositoryProvider;
import 'package:picnic_lib/ui/style.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  ConsumerState<VoteItemRequestDialog> createState() {
    return _VoteItemRequestDialogState();
  }
}

class _VoteItemRequestDialogState extends ConsumerState<VoteItemRequestDialog> {
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
  Set<String> _submittingArtists = {}; // 현재 신청 중인 아티스트들
  Map<String, ArtistModel?> _artistCache = {}; // 아티스트 정보 캐시

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
          .getVoteItemRequestCount(widget.vote.id.toString());

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
            logger.w('Application data processing failed: $e');
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
          'Vote application count loading completed: total $totalCount, user applications ${_currentUserApplications.length}');
    } catch (e) {
      logger.e('Application count loading failed', error: e);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        // 검색 결과 초기화 시 관련 데이터도 정리
        _artistApplicationCounts.clear();
        _artistApplicationStatus.clear();
        _artistAlreadyInVote.clear();
        // 아티스트 캐시는 유지 (재사용 가능)
      });
      return;
    }

    setState(() {
      _isSearching = true;
      // 새 검색 시작 시 이전 결과 정리
      _searchResults.clear();
      _artistApplicationCounts.clear();
      _artistApplicationStatus.clear();
      _artistAlreadyInVote.clear();
      // 아티스트 캐시는 유지 (재사용 가능)
    });

    try {
      // 검색 결과를 20개로 제한하여 성능 향상
      final results = await SearchService.searchArtists(
        query: query,
        page: 0,
        limit: 20, // 50 -> 20으로 감소
        supportKoreanInitials: true,
      );

      if (mounted && _currentSearchQuery == query) {
        // 검색어가 여전히 같은지 확인
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // 검색 결과에 대한 신청 수/상태 로딩
        _loadApplicationDataForResults(results);
      }
    } catch (e) {
      logger.e('Artist search failed', error: e);
      if (mounted && _currentSearchQuery == query) {
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
        final artistName = _getDisplayName(artist.name);
        final koreanName = artist.name['ko'] as String? ?? '';
        final englishName = artist.name['en'] as String? ?? '';

        try {
          // 실제 신청 수 가져오기 (아티스트별) - 한글 이름으로 먼저 시도
          int applicationCount = 0;
          if (koreanName.isNotEmpty) {
            applicationCount =
                await voteRequestRepository.getArtistApplicationCount(
                    widget.vote.id.toString(), koreanName);
          }
          // 한글로 찾지 못했고 영어가 있으면 영어로 시도
          if (applicationCount == 0 && englishName.isNotEmpty) {
            applicationCount =
                await voteRequestRepository.getArtistApplicationCount(
                    widget.vote.id.toString(), englishName);
          }

          // 아티스트가 이미 이 투표의 vote_item에 등록되었는지 확인
          bool isAlreadyInVote = false;
          if (koreanName.isNotEmpty) {
            isAlreadyInVote = await _checkIfArtistInVoteItems(koreanName);
          }
          if (!isAlreadyInVote && englishName.isNotEmpty) {
            isAlreadyInVote = await _checkIfArtistInVoteItems(englishName);
          }

          // 현재 사용자의 해당 아티스트에 대한 신청 상태 가져오기
          String applicationStatus = t('vote_item_request_can_apply');
          if (userInfo?.id != null) {
            VoteRequestUser? userApplication;
            // 한글 이름으로 먼저 확인
            if (koreanName.isNotEmpty) {
              userApplication =
                  await voteRequestRepository.getUserApplicationStatus(
                      widget.vote.id.toString(), userInfo!.id!, koreanName);
            }
            // 한글로 찾지 못했고 영어가 있으면 영어로 확인
            if (userApplication == null && englishName.isNotEmpty) {
              userApplication =
                  await voteRequestRepository.getUserApplicationStatus(
                      widget.vote.id.toString(), userInfo!.id!, englishName);
            }

            if (userApplication != null) {
              switch (userApplication.status.toLowerCase()) {
                case 'pending':
                  applicationStatus = t('vote_item_request_status_pending');
                  break;
                case 'approved':
                  applicationStatus = t('vote_item_request_status_approved');
                  break;
                case 'rejected':
                  applicationStatus = t('vote_item_request_status_rejected');
                  break;
                case 'in-progress':
                  applicationStatus = t('vote_item_request_status_in_progress');
                  break;
                case 'cancelled':
                  applicationStatus = t('vote_item_request_status_cancelled');
                  break;
                default:
                  applicationStatus = t('vote_item_request_can_apply');
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
          logger.w('Artist $artistName application data loading failed: $e');
          // 오류 발생 시 기본값 설정
          if (mounted) {
            setState(() {
              _artistApplicationCounts[artistName] = 0;
              _artistApplicationStatus[artistName] =
                  t('vote_item_request_can_apply');
              _artistAlreadyInVote[artistName] = false;
            });
          }
        }
      }
    } catch (e) {
      logger.e('Application data loading failed', error: e);
      // 전체 오류 발생 시 기본값으로 설정
      for (final artist in artists) {
        final artistName = _getDisplayName(artist.name);
        if (mounted) {
          setState(() {
            _artistApplicationCounts[artistName] = 0;
            _artistApplicationStatus[artistName] =
                t('vote_item_request_can_apply');
            _artistAlreadyInVote[artistName] = false;
          });
        }
      }
    }
  }

  // 아티스트 이름으로 아티스트 정보 검색 (캐시 포함)
  Future<ArtistModel?> _getArtistByName(String artistName) async {
    // 캐시에서 먼저 확인
    if (_artistCache.containsKey(artistName)) {
      return _artistCache[artistName];
    }

    try {
      final results = await SearchService.searchArtists(
        query: artistName,
        page: 0,
        limit: 5,
        supportKoreanInitials: true,
      );

      ArtistModel? foundArtist;

      // 정확히 일치하는 아티스트 찾기 (한글/영어 모두 확인)
      for (final artist in results) {
        final searchArtistName = _getDisplayName(artist.name);
        final koreanName = artist.name['ko'] as String? ?? '';
        final englishName = artist.name['en'] as String? ?? '';

        // 전체 이름 또는 개별 언어 이름으로 매칭 확인
        if (searchArtistName == artistName ||
            koreanName == artistName ||
            englishName == artistName) {
          foundArtist = artist;
          break;
        }
      }

      // 정확히 일치하는 것이 없으면 첫 번째 결과 사용
      if (foundArtist == null && results.isNotEmpty) {
        foundArtist = results.first;
      }

      // 캐시에 저장
      _artistCache[artistName] = foundArtist;
      return foundArtist;
    } catch (e) {
      logger.w('Artist search by name failed: $e');
      // 오류 시에도 캐시에 null 저장하여 반복 검색 방지
      _artistCache[artistName] = null;
      return null;
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
            final nameMap = artistData['name'] as Map<String, dynamic>? ?? {};
            final koreanNameFromDb = nameMap['ko'] as String? ?? '';
            final englishNameFromDb = nameMap['en'] as String? ?? '';

            // 한글, 영어 이름 중 하나라도 일치하면 등록된 것으로 간주
            if (koreanNameFromDb == artistName ||
                englishNameFromDb == artistName ||
                _getDisplayName(nameMap) == artistName) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      logger.w('Artist registration status check failed: $e');
      return false; // 오류 시 등록되지 않은 것으로 간주
    }
  }

  Future<void> _submitApplication(ArtistModel artist) async {
    final artistName = _getDisplayName(artist.name);
    final koreanName = artist.name['ko'] as String? ?? '';
    final englishName = artist.name['en'] as String? ?? '';

    setState(() {
      _submittingArtists.add(artistName);
      _errorMessage = null;
    });

    try {
      final userInfoAsync = ref.read(userInfoProvider);
      final userInfo = userInfoAsync.value;
      if (userInfo?.id == null) {
        throw Exception(t('vote_item_request_user_info_not_found'));
      }

      final voteRequestService = ref.read(voteItemRequestServiceProvider);

      // 아티스트별 신청 상태 확인 (전체 투표 중복 체크 제거)
      final voteRequestRepository = ref.read(voteRequestRepositoryProvider);
      VoteRequestUser? userApplication;
      // 한글 이름으로 먼저 확인
      if (koreanName.isNotEmpty) {
        userApplication = await voteRequestRepository.getUserApplicationStatus(
            widget.vote.id.toString(), userInfo!.id!, koreanName);
      }
      // 한글로 찾지 못했고 영어가 있으면 영어로 확인
      if (userApplication == null && englishName.isNotEmpty) {
        userApplication = await voteRequestRepository.getUserApplicationStatus(
            widget.vote.id.toString(), userInfo!.id!, englishName);
      }

      if (userApplication != null) {
        final status = userApplication.status.toLowerCase();
        if (status == 'pending' ||
            status == 'approved' ||
            status == 'in-progress') {
          if (mounted) {
            setState(() {
              _errorMessage = t('vote_item_request_already_applied_artist');
            });
          }
          return;
        }
      }

      final groupName = artist.artistGroup != null
          ? _getDisplayName(artist.artistGroup!.name)
          : null;

      // 신청할 때는 한글 이름을 우선 사용 (없으면 영어)
      final submitArtistName = koreanName.isNotEmpty ? koreanName : englishName;

      await voteRequestService.submitArtistApplication(
        voteId: widget.vote.id.toString(),
        userId: userInfo!.id!,
        title: submitArtistName,
        artistName: submitArtistName,
        groupName: groupName,
      );

      // 신청 성공 후 상태 업데이트
      if (mounted) {
        await _loadApplicationCounts(); // 현재 사용자 신청 목록 갱신
        await _loadApplicationDataForResults(_searchResults); // 검색 결과 상태 갱신

        Navigator.of(context).pop();
        showSimpleDialog(
          title: t('success'),
          content: t('application_success'),
        );
      }
    } catch (e) {
      logger.e('Vote application failed', error: e);
      if (mounted) {
        setState(() {
          // VoteRequestException에서 사용자 친화적 메시지 추출
          String errorMsg = e.toString();
          if (errorMsg.contains('VoteRequestException:')) {
            errorMsg =
                errorMsg.replaceFirst('VoteRequestException:', '').trim();
          }
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingArtists.remove(artistName);
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
                      t('vote_item_request_title'),
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
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
              t('vote_item_request_current_item_request'),
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            ),
          ),
          Container(
            height: 140.h, // 이미지가 포함되어 높이 증가
            child: _currentUserApplications.isEmpty
                ? Center(
                    child: Text(
                      t('vote_item_request_no_item_request_yet'),
                      style:
                          getTextStyle(AppTypo.caption12R, AppColors.grey500),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.r),
                    itemCount: _currentUserApplications.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    physics: NeverScrollableScrollPhysics(), // 내부 스크롤 비활성화
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
          return t('vote_item_request_status_pending');
        case 'approved':
          return t('vote_item_request_status_approved');
        case 'rejected':
          return t('vote_item_request_status_rejected');
        case 'in-progress':
          return t('vote_item_request_status_in_progress');
        case 'cancelled':
          return t('vote_item_request_status_cancelled');
        default:
          return t('vote_item_request_status_unknown');
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

    // 상세 데이터에서 아티스트명과 그룹명 추출
    Map<String, String?> getArtistInfo() {
      try {
        // _currentUserApplicationsWithDetails에서 해당 application과 매칭되는 데이터 찾기
        final detailData = _currentUserApplicationsWithDetails.firstWhere(
          (detail) => detail['id'] == application.id,
          orElse: () => <String, dynamic>{},
        );

        if (detailData.isNotEmpty && detailData['vote_requests'] != null) {
          final voteRequest = detailData['vote_requests'];
          final artistName = voteRequest['title'] as String? ??
              t('vote_item_request_artist_name_missing');
          final groupName =
              voteRequest['description'] as String?; // description에서 그룹명 추출

          return {
            'artistName': artistName,
            'groupName': groupName,
          };
        }
        return {
          'artistName': t('vote_item_request_artist_name_missing'),
          'groupName': null,
        };
      } catch (e) {
        logger.w('Artist info extraction failed: $e');
        return {
          'artistName': t('vote_item_request_artist_name_missing'),
          'groupName': null,
        };
      }
    }

    final artistInfo = getArtistInfo();
    final artistName = artistInfo['artistName']!;
    final groupName = artistInfo['groupName'];
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
          // 아티스트 이미지 (동적으로 검색해서 가져오기)
          FutureBuilder<ArtistModel?>(
            future: _getArtistByName(artistName),
            builder: (context, snapshot) {
              final artist = snapshot.data;
              return Container(
                width: 40.w,
                height: 40.h,
                child: ClipOval(
                  child: artist?.image != null
                      ? PicnicCachedNetworkImage(
                          imageUrl: artist!.image!,
                          fit: BoxFit.cover,
                          width: 40.w,
                          height: 40.h,
                        )
                      : Container(
                          color: AppColors.grey200,
                          child: Icon(
                            Icons.person,
                            color: AppColors.grey500,
                            size: 20.r,
                          ),
                        ),
                ),
              );
            },
          ),
          SizedBox(width: 12.w),

          // 아티스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아티스트 이름 표시 (한글/영어 조합)
                FutureBuilder<ArtistModel?>(
                  future: _getArtistByName(artistName),
                  builder: (context, snapshot) {
                    final artist = snapshot.data;
                    final displayName = artist != null
                        ? _getDisplayName(artist.name)
                        : artistName;
                    return Text(
                      displayName,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                // 그룹명 표시 (한글/영어 조합)
                FutureBuilder<ArtistModel?>(
                  future: _getArtistByName(artistName),
                  builder: (context, snapshot) {
                    final artist = snapshot.data;
                    if (artist?.artistGroup != null) {
                      final displayGroupName =
                          _getDisplayName(artist!.artistGroup!.name);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 2.h),
                          Text(
                            displayGroupName,
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    } else if (groupName != null && groupName.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 2.h),
                          Text(
                            groupName,
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
                SizedBox(height: 4.h),
                // 신청수를 태그 형태로 표시
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: AppColors.primary500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _formatNumber(applicationCount),
                    style:
                        getTextStyle(AppTypo.caption10SB, AppColors.primary500),
                  ),
                ),
              ],
            ),
          ),

          // 상태 표시
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
            t('vote_item_request_search_artist'),
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
          ),
          SizedBox(height: 8.h),
          EnhancedSearchBox(
            hintText: t('vote_item_request_search_artist_hint'),
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
          t('vote_item_request_search_artist_prompt'),
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          t('vote_item_request_no_search_results'),
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      itemCount: _searchResults.length,
      addAutomaticKeepAlives: false, // 화면 밖의 위젯을 메모리에서 해제
      addRepaintBoundaries: false, // 불필요한 RepaintBoundary 제거
      cacheExtent: 200.0, // 캐시 범위 제한
      itemBuilder: (context, index) {
        final artist = _searchResults[index];
        return _buildSearchResultItem(artist, index);
      },
    );
  }

  Widget _buildSearchResultItem(ArtistModel artist, int index) {
    final artistName = _getDisplayName(artist.name);
    final groupName = artist.artistGroup != null
        ? _getDisplayName(artist.artistGroup!.name)
        : '';
    final applicationCount = _artistApplicationCounts[artistName] ?? 0;
    final status = _artistApplicationStatus[artistName] ??
        t('vote_item_request_can_apply');
    final isAlreadyInVote = _artistAlreadyInVote[artistName] ?? false;
    final isSubmittingThisArtist = _submittingArtists.contains(artistName);

    // 신청 버튼을 표시할지 결정하는 조건
    final shouldShowApplicationButton =
        _shouldShowApplicationButton(status, isAlreadyInVote);

    // 표시할 상태 텍스트 결정
    String displayStatus = status;
    if (isAlreadyInVote) {
      displayStatus = t('vote_item_request_already_registered');
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: (shouldShowApplicationButton && !isSubmittingThisArtist)
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
                      ? _LazyImageWidget(
                          imageUrl: artist.image!,
                          width: 50.w,
                          height: 50.h,
                          listIndex: index,
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
                  // 신청수를 태그 형태로 표시
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(
                        color: AppColors.primary500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _formatNumber(applicationCount),
                      style: getTextStyle(
                          AppTypo.caption10SB, AppColors.primary500),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // 신청 버튼 또는 상태 표시
                  if (_shouldShowApplicationButton(
                      displayStatus, isAlreadyInVote))
                    ElevatedButton(
                      onPressed: (isSubmittingThisArtist)
                          ? null
                          : () => _submitApplication(artist),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 30),
                      ),
                      child: isSubmittingThisArtist
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              t('vote_item_request_submit'),
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
                      child: Text(
                        t('vote_item_request_already_registered'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else if (status != t('vote_item_request_can_apply'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == t('vote_item_request_status_pending')
                            ? Colors.orange.withValues(alpha: 0.1)
                            : status == t('vote_item_request_status_approved')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == t('vote_item_request_status_pending')
                              ? Colors.orange.withValues(alpha: 0.3)
                              : status == t('vote_item_request_status_approved')
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: status == t('vote_item_request_status_pending')
                              ? Colors.orange
                              : status == t('vote_item_request_status_approved')
                                  ? Colors.green
                                  : Colors.grey[600],
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

  // 숫자에 3자리 콤마 포맷 적용
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // 한글/영어 모두 표시하되 사용자 언어에 따라 순서 조정
  String _getDisplayName(Map<String, dynamic> nameJson) {
    if (nameJson.isEmpty) return '';

    final currentLanguage = getLocaleLanguage();
    final koreanName = nameJson['ko'] as String? ?? '';
    final englishName = nameJson['en'] as String? ?? '';

    // 둘 다 없으면 빈 문자열
    if (koreanName.isEmpty && englishName.isEmpty) return '';

    // 하나만 있으면 그것만 반환
    if (koreanName.isEmpty) return englishName;
    if (englishName.isEmpty) return koreanName;

    // 둘 다 있으면 사용자 언어에 따라 순서 결정
    if (currentLanguage == 'ko') {
      // 한국어 사용자: 한글 먼저
      return '$koreanName ($englishName)';
    } else {
      // 한국어 이외 사용자: 영어 먼저
      return '$englishName ($koreanName)';
    }
  }

  // 신청 버튼을 표시할지 결정하는 조건
  bool _shouldShowApplicationButton(String status, bool isAlreadyInVote) {
    // 이미 투표에 등록된 경우
    if (isAlreadyInVote) return false;

    // 거절된 경우는 재신청 가능
    if (status == t('vote_item_request_status_rejected') ||
        status == t('vote_item_request_status_cancelled')) return true;

    // 내가 이미 신청한 경우 (대기중, 승인됨, 진행중)
    if (status == t('vote_item_request_status_pending') ||
        status == t('vote_item_request_status_approved') ||
        status == t('vote_item_request_status_in_progress')) return false;

    // 신청 가능한 경우만 true
    return status == t('vote_item_request_can_apply');
  }
}

// 지연 로딩을 위한 이미지 위젯
class _LazyImageWidget extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final int listIndex;

  const _LazyImageWidget({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.listIndex,
  });

  @override
  State<_LazyImageWidget> createState() => _LazyImageWidgetState();
}

class _LazyImageWidgetState extends State<_LazyImageWidget> {
  bool _shouldLoadImage = false;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    // 리스트 상위 몇 개 항목은 즉시 로딩
    if (widget.listIndex < 3) {
      _shouldLoadImage = true;
    } else {
      // 나머지는 점진적으로 지연 후 로딩 (최대 500ms)
      final delay = (widget.listIndex * 50).clamp(100, 500);
      _loadTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            _shouldLoadImage = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: _shouldLoadImage
          ? PicnicCachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              width: widget.width,
              height: widget.height,
            )
          : Container(
              color: AppColors.grey200,
              child: Icon(
                Icons.person,
                color: AppColors.grey500,
                size: 24.r,
              ),
            ),
    );
  }
}
