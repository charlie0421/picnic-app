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
  Future<VoteRequest> updateVoteRequestStatus(String requestId, String status) async {
    try {
      final response = await _supabase
          .from('vote_requests')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
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
          .select('id')
          .eq('vote_id', voteId)
          .eq('user_id', userId)
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
      // 트랜잭션을 사용하여 투표 요청과 사용자 정보를 함께 생성
      final response = await _supabase.rpc('create_vote_request_with_user', params: {
        'request_data': request.toJson(),
        'user_id': userId,
        'user_status': status,
      });

      return VoteRequest.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 요청 및 사용자 정보 생성 실패: $e');
    }
  }

  /// 투표 요청 사용자 정보를 생성합니다
  Future<VoteRequestUser> createVoteRequestUser(VoteRequestUser requestUser) async {
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
    String requestUserId, 
    String status
  ) async {
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
  Future<List<VoteRequestUser>> getVoteRequestUsers(String voteRequestId) async {
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
} 