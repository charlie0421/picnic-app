import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vote_item_request_service_helper.dart';
import 'vote_item_request_models.dart';

/// 투표 항목 신청 서비스 클래스
class VoteItemRequestService {
  final WidgetRef ref;
  final String voteId;
  final SupabaseClient? _supabase;

  /// 투표 area 에 따른 아티스트 검색 범위 (musical 투표 → 뮤지컬 배우 검색).
  final ArtistSearchScope artistScope;

  VoteItemRequestService({
    required this.ref,
    required this.voteId,
    String? voteArea,
    SupabaseClient? supabase,
  })  : _supabase = supabase,
        artistScope = artistSearchScopeForVoteArea(voteArea);

  /// 신청 수 및 사용자 신청 내역 로드
  Future<Map<String, dynamic>> loadApplicationCounts(String? userId) async {
    try {
      final voteRequestRepository = ref.read(voteItemRequestRepositoryProvider);

      // 전체 투표 신청 수 조회
      final totalCount = await voteRequestRepository
          .getVoteItemRequestCount(int.parse(voteId));

      List<VoteItemRequestUser> userApplications = [];
      List<Map<String, dynamic>> userApplicationsWithDetails = [];
      Map<String, int> applicationCounts = {};

      logger.d('loadApplicationCounts: $userId');

      // 현재 사용자의 신청 내역 조회
      if (userId != null) {
        userApplicationsWithDetails = await voteRequestRepository
            .getCurrentUserApplicationsWithDetails(userId);

        // 각 사용자 신청에 대한 총 신청 수 조회
        for (final applicationData in userApplicationsWithDetails) {
          try {
            // VoteItemRequestUser 객체 생성
            final application = VoteItemRequestUser.fromJson(applicationData);
            userApplications.add(application);

            // vote_requests에서 제목 추출
            final voteRequest = applicationData['vote_requests'];
            if (voteRequest != null) {
              final title = voteRequest['title'] as String?;
              if (title != null) {
                final count = await voteRequestRepository
                    .getApplicationCountByTitle(title);
                applicationCounts[application.id.toString()] = count;
              }
            }
          } catch (e) {
            logger.w('Application data processing failed: $e');
          }
        }
      }

      logger.d(
          'Vote application count loading completed: total $totalCount, user applications ${userApplications.length}');

      return {
        'userApplications': userApplications,
        'userApplicationsWithDetails': userApplicationsWithDetails,
        'userApplicationCounts': applicationCounts,
      };
    } catch (e) {
      logger.e('Application count loading failed', error: e);
      return {
        'userApplications': <VoteItemRequestUser>[],
        'userApplicationsWithDetails': <Map<String, dynamic>>[],
        'userApplicationCounts': <String, int>{},
      };
    }
  }

  /// 아티스트 검색
  Future<List<ArtistModel>> searchArtists(String query) async {
    try {
      // 검색 결과를 20개로 제한하여 성능 향상
      final results = await SearchService.searchArtists(
        query: query,
        page: 0,
        limit: 20,
        supportKoreanInitials: true,
      );

      return results;
    } catch (e) {
      logger.e('Artist search failed', error: e);
      return [];
    }
  }

  /// 페이지네이션을 지원하는 아티스트 검색 (빠른 검색 사용)
  Future<Map<String, dynamic>> searchArtistsWithPagination(
    String query, {
    required int page,
    required int pageSize,
  }) async {
    try {
      // 투표 후보 신청용 빠른 검색 메서드 사용 (투표 area 에 맞는 검색 범위 적용)
      final artists = await SearchService.searchArtistsFast(
        query: query,
        page: page,
        limit: pageSize,
        scope: artistScope,
      );

      // 더 많은 결과가 있는지는 단순히 결과 개수로 판단
      final hasMore = artists.length == pageSize;

      return {
        'artists': artists,
        'hasMore': hasMore,
        'currentPage': page,
      };
    } catch (e) {
      logger.e('Artist search with pagination failed', error: e);
      return {
        'artists': <ArtistModel>[],
        'hasMore': false,
        'currentPage': page,
      };
    }
  }

  /// 검색 결과에 대한 신청 데이터 로드
  Future<Map<String, ArtistApplicationInfo>> loadApplicationDataForResults(
      List<ArtistModel> artists, String? userId) async {
    final Map<String, ArtistApplicationInfo> applicationData = {};

    try {
      final batches = VoteItemRequestServiceHelper.splitIntoBatches(
        artists,
        VoteItemRequestServiceHelper.enrichmentBatchSize,
      );
      for (final batch in batches) {
        final batchData = await _loadApplicationDataBatch(batch, userId);
        applicationData.addAll(batchData);
      }
      return applicationData;
    } catch (e) {
      logger.e('Application data loading failed', error: e);
      // 전체 오류 발생 시 기본값으로 설정
      for (final artist in artists) {
        final artistName = ArtistNameUtils.getDisplayName(artist.name);
        applicationData[artist.id.toString()] = ArtistApplicationInfo(
          artistName: artistName,
          applicationCount: 0,
          applicationStatus: AppLocalizations.of(navigatorKey.currentContext!)
              .vote_item_request_can_apply,
          isAlreadyInVote: false,
        );
      }
      return applicationData;
    }
  }

  /// 배치 단위로 신청 데이터 로드
  Future<Map<String, ArtistApplicationInfo>> _loadApplicationDataBatch(
      List<ArtistModel> artists, String? userId) async {
    final Map<String, ArtistApplicationInfo> applicationData = {};
    final voteRequestRepository = ref.read(voteItemRequestRepositoryProvider);

    final artistNames = VoteItemRequestServiceHelper.collectArtistNameSet(
      artists.map((artist) => artist.name).toList(),
    );

    // 배치로 신청수 가져오기
    Map<String, int> applicationCounts = {};
    Map<int, int> applicationCountsByArtistId = {};
    Map<String, bool> alreadyInVote = {};
    Map<String, String> userApplicationStatuses = {};

    if (artistNames.isNotEmpty) {
      try {
        final supabase = _supabase ?? Supabase.instance.client;

        // 타임아웃 설정으로 무한 대기 방지
        final futures = <Future>[];

        // 1. 집계 뷰에서 모든 아티스트의 신청수를 한번에 가져오기
        futures.add(voteRequestRepository
            .getVoteItemRequestCountSummary(int.parse(voteId))
            .then((summary) {
          applicationCounts = summary.countsByArtistName;
          applicationCountsByArtistId = summary.countsByArtistId;
        }));

        // 2. 투표 아이템에 이미 등록된 아티스트 확인
        futures.add(supabase
            .from('vote_item')
            .select('artist!inner(name)')
            .eq('vote_id', voteId)
            .timeout(Duration(seconds: 10))
            .then((response) {
          for (final item in response) {
            if (item['artist'] != null) {
              final artistData = item['artist'] as Map<String, dynamic>;
              final nameData = artistData['name'] as Map<String, dynamic>;

              final koreanName = nameData['ko'] as String? ?? '';
              final englishName = nameData['en'] as String? ?? '';

              if (koreanName.isNotEmpty && artistNames.contains(koreanName)) {
                alreadyInVote[koreanName] = true;
              }
              if (englishName.isNotEmpty && artistNames.contains(englishName)) {
                alreadyInVote[englishName] = true;
              }
            }
          }
        }));

        // 3. 현재 사용자의 신청 상태 확인 (userId가 있는 경우)
        if (userId != null) {
          futures.add(supabase
              .from('vote_item_request_users')
              .select('''
                vote_id,
                user_id,
                artist_id,
                artist!inner(name),
                status
              ''')
              .eq('vote_id', voteId)
              .eq('user_id', userId)
              .timeout(Duration(seconds: 10))
              .then((response) {
                for (final row in response) {
                  if (row['vote_id'].toString() != voteId ||
                      row['user_id'] != userId) {
                    continue;
                  }
                  if (row['artist'] != null) {
                    final artistData = row['artist'] as Map<String, dynamic>;
                    final nameData = artistData['name'] as Map<String, dynamic>;
                    final koreanName = nameData['ko'] as String? ?? '';
                    final englishName = nameData['en'] as String? ?? '';
                    final status = row['status'] as String;
                    final artistId = row['artist_id'] as int;

                    final statusText = _getUserApplicationStatusText(status);

                    if (koreanName.isNotEmpty &&
                        artistNames.contains(koreanName)) {
                      userApplicationStatuses[koreanName] = statusText;
                    }
                    if (englishName.isNotEmpty &&
                        artistNames.contains(englishName)) {
                      userApplicationStatuses[englishName] = statusText;
                    }
                    // 아티스트 ID로도 저장해서 정확한 매칭 지원
                    userApplicationStatuses[artistId.toString()] = statusText;
                  }
                }
              }));
        }

        // 모든 쿼리를 병렬로 실행하되 전체 타임아웃 설정
        await Future.wait(futures).timeout(Duration(seconds: 30));
      } catch (e) {
        logger.e('배치 데이터 로딩 중 오류 발생: $e');
        // 타임아웃이나 기타 오류 시에도 기본값으로 계속 진행
      }
    }

    // 결과 조립
    for (final artist in artists) {
      final displayName = ArtistNameUtils.getDisplayName(artist.name);
      final koreanName = artist.name['ko'] as String? ?? '';
      final englishName = artist.name['en'] as String? ?? '';

      // 아티스트 ID를 우선 사용하고 이름은 이전 데이터용 fallback으로 사용
      int totalApplicationCount = applicationCountsByArtistId[artist.id] ?? 0;
      if (!applicationCountsByArtistId.containsKey(artist.id)) {
        if (koreanName.isNotEmpty) {
          totalApplicationCount = applicationCounts[koreanName] ?? 0;
        }
        if (totalApplicationCount == 0 && englishName.isNotEmpty) {
          totalApplicationCount = applicationCounts[englishName] ?? 0;
        }
      }

      // 투표에 이미 등록 여부 확인
      bool isAlreadyInVote = false;
      if (koreanName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[koreanName] ?? false;
      }
      if (!isAlreadyInVote && englishName.isNotEmpty) {
        isAlreadyInVote = alreadyInVote[englishName] ?? false;
      }

      // 사용자 신청 상태 확인 (ID 우선, 이름으로 fallback)
      String applicationStatus =
          AppLocalizations.of(navigatorKey.currentContext!)
              .vote_item_request_can_apply;
      if (userId != null) {
        // 1. 아티스트 ID로 먼저 확인 (가장 정확함)
        if (userApplicationStatuses.containsKey(artist.id.toString())) {
          applicationStatus = userApplicationStatuses[artist.id.toString()]!;
        }
        // 2. 한글 이름으로 확인
        else if (koreanName.isNotEmpty &&
            userApplicationStatuses.containsKey(koreanName)) {
          applicationStatus = userApplicationStatuses[koreanName]!;
        }
        // 3. 영어 이름으로 확인
        else if (englishName.isNotEmpty &&
            userApplicationStatuses.containsKey(englishName)) {
          applicationStatus = userApplicationStatuses[englishName]!;
        }
      }

      // 아티스트 ID를 키로 사용하여 정확한 매칭 보장
      applicationData[artist.id.toString()] = ArtistApplicationInfo(
        artistName: displayName,
        applicationCount: totalApplicationCount,
        applicationStatus: applicationStatus,
        isAlreadyInVote: isAlreadyInVote,
      );
    }

    return applicationData;
  }

  /// 아티스트 이름으로 아티스트 정보 검색
  Future<ArtistModel?> getArtistByName(
      String artistName, Map<String, ArtistModel?> cache) async {
    // 캐시에서 먼저 확인
    if (cache.containsKey(artistName)) {
      return cache[artistName];
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
        final searchArtistName = ArtistNameUtils.getDisplayName(artist.name);
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
      cache[artistName] = foundArtist;
      return foundArtist;
    } catch (e) {
      logger.w('Artist search by name failed: $e');
      // 오류 시에도 캐시에 null 저장하여 반복 검색 방지
      cache[artistName] = null;
      return null;
    }
  }

  /// 아티스트가 이미 이 투표의 vote_item에 등록되었는지 확인
  Future<bool> checkIfArtistInVoteItems(String artistName) async {
    try {
      // vote_item 테이블을 artist 테이블과 조인하여 아티스트 이름으로 확인
      final supabase = Supabase.instance.client;
      final response = await supabase.from('vote_item').select('''
            id,
            artist!inner(name)
          ''').eq('vote_id', voteId);

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
              ArtistNameUtils.getDisplayName(nameMap) == artistName) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      logger.w('Artist registration status check failed: $e');
      return false; // 오류 시 등록되지 않은 것으로 간주
    }
  }

  /// 아티스트 신청 제출
  Future<void> submitApplication(ArtistModel artist, String userId) async {
    try {
      // 아티스트별 신청 상태 확인 (전체 투표 중복 체크 제거)
      final voteRequestRepository = ref.read(voteItemRequestRepositoryProvider);

      // 사용자가 이미 해당 아티스트에 대해 신청했는지 확인
      final hasRequested = await voteRequestRepository.hasUserRequestedArtist(
          int.parse(voteId), artist.id, userId);

      if (hasRequested) {
        throw Exception(AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_already_applied_artist);
      }

      // VoteItemRequestRepository를 사용하여 직접 신청 생성
      await voteRequestRepository.createVoteItemRequestWithUser(
        voteId: int.parse(voteId),
        artistId: artist.id,
        userId: userId,
      );
    } catch (e) {
      logger.e('Vote application failed', error: e);
      rethrow;
    }
  }

  /// 사용자 신청 상태를 한글 텍스트로 변환
  String _getUserApplicationStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_status_pending; // "대기중"으로 표시
      case 'approved':
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_status_approved;
      case 'rejected':
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_status_rejected;
      case 'in-progress':
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_status_in_progress;
      case 'cancelled':
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_status_cancelled;
      default:
        return AppLocalizations.of(navigatorKey.currentContext!)
            .vote_item_request_can_apply;
    }
  }

  /// 모든 사용자의 신청을 아티스트별로 그룹화해서 조회
  Future<Map<String, dynamic>> loadAllApplicationsByArtist() async {
    try {
      final voteRequestRepository = ref.read(voteItemRequestRepositoryProvider);

      final summary = await voteRequestRepository
          .getVoteItemRequestCountSummary(int.parse(voteId));
      final supabase = _supabase ?? Supabase.instance.client;
      final artistRows = summary.countsByArtistId.isEmpty
          ? <dynamic>[]
          : await supabase
              .from('artist')
              .select('id,name,image,artist_group(id,name)')
              .inFilter('id', summary.countsByArtistId.keys.toList());
      final artistInfoById = <int, Map<String, dynamic>>{};
      for (final row in artistRows) {
        if (row is Map<String, dynamic> && row['id'] is int) {
          artistInfoById[row['id'] as int] = row;
        }
      }

      // 아티스트별 신청 요약 생성
      final List<Map<String, dynamic>> artistApplicationSummaries = [];

      for (final entry in summary.countsByArtistId.entries) {
        final artistId = entry.key;
        final artistName = summary.artistNamesById[artistId] ?? '';
        final statusCounts =
            summary.statusCountsByArtistId[artistId] ?? <String, int>{};
        final totalCount = entry.value;
        final pendingCount = statusCounts['pending'] ?? 0;
        final approvedCount = statusCounts['approved'] ?? 0;
        final rejectedCount = statusCounts['rejected'] ?? 0;

        artistApplicationSummaries.add({
          'artistId': artistId,
          // 아티스트 테이블 조회가 실패했을 때의 폴백. 뷰의 `artist_name` 은
          // `a.name->>'ko'` 이므로 'ko' 키가 맞다 — 'und' 같은 임의 키를 쓰면
          // `ArtistNameUtils.getDisplayName` (ko/en 만 읽음) 이 렌더하지 못해
          // 이름이 있는데도 "알 수 없는 아티스트"로 표시된다.
          'artist': artistInfoById[artistId] ?? {
            'id': artistId,
            'name': {'ko': artistName},
          },
          'totalApplications': totalCount,
          'pendingCount': pendingCount,
          'approvedCount': approvedCount,
          'rejectedCount': rejectedCount,
          'statusCounts': statusCounts,
        });
      }

      // 신청 수가 많은 순서로 정렬
      artistApplicationSummaries.sort((a, b) => (b['totalApplications'] as int)
          .compareTo(a['totalApplications'] as int));

      return {
        'artistApplicationSummaries': artistApplicationSummaries,
        'totalApplications': summary.totalCount,
      };
    } catch (e) {
      logger.e('모든 사용자 신청 로딩 실패: $e');
      return {
        'artistApplicationSummaries': <Map<String, dynamic>>[],
        'totalApplications': 0,
      };
    }
  }
}
