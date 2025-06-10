import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/data/models/vote/vote_request.dart';
import 'package:picnic_lib/data/models/vote/vote_request_user.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

/// 투표 요청 관련 데이터베이스 작업을 담당하는 리포지토리
class VoteRequestRepository {
  final SupabaseClient _supabase;

  VoteRequestRepository(this._supabase);

  /// 새로운 투표 요청을 생성합니다
  Future<VoteRequest> createVoteRequest(VoteRequest request) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .insert(request.toJson())
          .select()
          .single();

      return VoteRequest.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 요청 생성 실패: $e');
    }
  }

  /// 특정 투표에 대한 모든 요청을 조회합니다
  Future<List<VoteRequest>> getVoteRequestsByVoteId(String voteId) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .select()
          .eq('vote_id', voteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VoteRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw VoteRequestException('투표 요청 목록 조회 실패: $e');
    }
  }

  /// 특정 사용자의 모든 투표 요청을 조회합니다
  Future<List<VoteRequest>> getUserVoteRequests(String userId) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .select('''
            *,
            vote_request_users!inner(user_id)
          ''')
          .eq('vote_request_users.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VoteRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw VoteRequestException('사용자 투표 요청 목록 조회 실패: $e');
    }
  }

  /// 투표 요청 상태를 업데이트합니다
  Future<VoteRequest> updateVoteRequestStatus(
      String requestId, String status) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', requestId)
          .select()
          .single();

      return VoteRequest.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 요청 상태 업데이트 실패: $e');
    }
  }

  /// 사용자가 특정 투표에 이미 요청했는지 확인합니다
  Future<bool> hasUserRequestedVote(String voteId, String userId) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('''
            id,
            vote_requests!inner(vote_id)
          ''')
          .eq('user_id', userId)
          .eq('vote_requests.vote_id', voteId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw VoteRequestException('중복 요청 확인 실패: $e');
    }
  }

  /// 투표 요청과 함께 사용자 정보를 생성합니다 (중복 방지 포함)
  Future<VoteRequest> createVoteRequestWithUser({
    required VoteRequest request,
    required String userId,
    String status = 'pending',
  }) async {
    // 중복 요청 확인
    final hasRequested = await hasUserRequestedVote(request.voteId, userId);
    if (hasRequested) {
      throw const DuplicateVoteRequestException('이미 해당 투표에 요청하셨습니다.');
    }

    try {
      // 1. 먼저 투표 요청 생성
      final voteRequestResponse = await _supabase
          .from('vote_requests')
          .insert({
            'vote_id': request.voteId,
            'title': request.title,
            'description': request.description,
          })
          .select()
          .single();

      final voteRequest = VoteRequest.fromJson(voteRequestResponse);

      // 2. 사용자 정보 생성
      await _supabase.from('vote_request_users').insert({
        'vote_request_id': voteRequest.id,
        'user_id': userId,
        'status': status,
      });

      return voteRequest;
    } catch (e) {
      throw VoteRequestException('투표 요청 및 사용자 정보 생성 실패: $e');
    }
  }

  /// 아티스트별 투표 요청과 함께 사용자 정보를 생성합니다 (전체 투표 중복 체크 제외)
  ///
  /// 같은 투표에서 다른 아티스트에 대한 신청을 허용하되,
  /// 아티스트별 중복 체크는 호출하는 곳에서 처리해야 합니다.
  Future<VoteRequest> createArtistVoteRequestWithUser({
    required VoteRequest request,
    required String userId,
    String status = 'pending',
  }) async {
    try {
      // 1. 먼저 투표 요청 생성 (전체 투표 중복 체크 제외)
      final voteRequestResponse = await _supabase
          .from('vote_requests')
          .insert({
            'vote_id': request.voteId,
            'title': request.title,
            'description': request.description,
          })
          .select()
          .single();

      final voteRequest = VoteRequest.fromJson(voteRequestResponse);

      // 2. 사용자 정보 생성
      await _supabase.from('vote_request_users').insert({
        'vote_request_id': voteRequest.id,
        'user_id': userId,
        'status': status,
      });

      return voteRequest;
    } catch (e) {
      throw VoteRequestException('아티스트별 투표 요청 및 사용자 정보 생성 실패: $e');
    }
  }

  /// 투표 요청 사용자 정보를 생성합니다
  Future<VoteRequestUser> createVoteRequestUser(
      VoteRequestUser requestUser) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .insert(requestUser.toJson())
          .select()
          .single();

      return VoteRequestUser.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 요청 사용자 정보 생성 실패: $e');
    }
  }

  /// 투표 요청 사용자 상태를 업데이트합니다
  Future<VoteRequestUser> updateVoteRequestUserStatus(
      String requestUserId, String status) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', requestUserId)
          .select()
          .single();

      return VoteRequestUser.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 요청 사용자 상태 업데이트 실패: $e');
    }
  }

  /// 특정 투표 요청의 모든 사용자를 조회합니다
  Future<List<VoteRequestUser>> getVoteRequestUsers(
      String voteRequestId) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select()
          .eq('vote_request_id', voteRequestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => VoteRequestUser.fromJson(json))
          .toList();
    } catch (e) {
      throw VoteRequestException('투표 요청 사용자 목록 조회 실패: $e');
    }
  }

  /// 특정 시간 이후 사용자의 신청 수를 조회합니다
  Future<int> getUserApplicationCountSince(
      String userId, DateTime since) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String());

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('사용자 신청 수 조회 실패: $e');
    }
  }

  /// 특정 투표의 총 신청 수를 조회합니다
  Future<int> getVoteItemRequestCount(String voteId) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .select('id')
          .eq('vote_id', voteId);

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('투표 신청 수 조회 실패: $e');
    }
  }

  /// 사용자의 전체 신청 수를 조회합니다
  Future<int> getUserTotalApplicationCount(String userId) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('사용자 전체 신청 수 조회 실패: $e');
    }
  }

  /// 특정 투표에서 특정 아티스트에 대한 신청 수를 조회합니다
  Future<int> getArtistApplicationCount(
      String voteId, String artistName) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .select('id')
          .eq('vote_id', voteId)
          .eq('title', artistName); // title 필드에 아티스트 이름이 저장됨

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('아티스트 신청 수 조회 실패: $e');
    }
  }

  /// 사용자의 특정 아티스트에 대한 신청 상태를 조회합니다
  Future<VoteRequestUser?> getUserApplicationStatus(
      String voteId, String userId, String artistName) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('''
            *,
            vote_requests!inner(vote_id, title)
          ''')
          .eq('user_id', userId)
          .eq('vote_requests.vote_id', voteId)
          .eq('vote_requests.title', artistName)
          .maybeSingle();

      if (response != null) {
        return VoteRequestUser.fromJson(response);
      }
      return null;
    } catch (e) {
      throw VoteRequestException('사용자 신청 상태 조회 실패: $e');
    }
  }

  /// 현재 사용자의 특정 투표에 대한 모든 신청 내역을 조회합니다
  Future<List<Map<String, dynamic>>> getCurrentUserApplicationsWithDetails(
      String voteId, String userId) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('''
            *,
            vote_requests!inner(vote_id, title, description)
          ''')
          .eq('user_id', userId)
          .eq('vote_requests.vote_id', voteId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw VoteRequestException('사용자 신청 내역 조회 실패: $e');
    }
  }

  /// 현재 사용자의 특정 투표에 대한 모든 신청 내역을 조회합니다 (기존 호환성)
  Future<List<VoteRequestUser>> getCurrentUserApplications(
      String voteId, String userId) async {
    try {
      final response = await _supabase
          .from('vote_request_users')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // vote_id로 필터링
      final filtered = <Map<String, dynamic>>[];
      for (final item in response as List) {
        final voteRequestResponse = await _supabase
            .from('vote_requests')
            .select('vote_id')
            .eq('id', item['vote_request_id'])
            .eq('vote_id', voteId)
            .maybeSingle();

        if (voteRequestResponse != null) {
          filtered.add(item);
        }
      }

      return filtered.map((json) => VoteRequestUser.fromJson(json)).toList();
    } catch (e) {
      throw VoteRequestException('사용자 신청 내역 조회 실패: $e');
    }
  }

  /// 특정 아티스트(제목)에 대한 총 신청 수를 조회합니다
  Future<int> getApplicationCountByTitle(String voteId, String title) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .select('id')
          .eq('vote_id', voteId)
          .eq('title', title);

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('제목별 신청 수 조회 실패: $e');
    }
  }
}
