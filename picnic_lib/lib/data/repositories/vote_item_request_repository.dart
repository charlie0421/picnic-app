import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

/// 투표 아이템 요청 관련 데이터 액세스 레이어
class VoteItemRequestRepository {
  final SupabaseClient _supabase;

  VoteItemRequestRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 투표 아이템 요청 수 조회
  Future<int> getVoteItemRequestCount(int voteId) async {
    try {
      final response = await _supabase
          .from('vote_item_request_users')
          .select('id')
          .eq('vote_id', voteId);

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('투표 아이템 요청 수 조회 실패: $e');
    }
  }

  /// 현재 사용자의 신청 내역을 상세 정보와 함께 조회
  Future<List<Map<String, dynamic>>> getCurrentUserApplicationsWithDetails(
      String userId) async {
    try {
      // 뷰를 사용하여 아티스트 정보가 포함된 데이터 조회
      final response = await _supabase
          .from('vote_item_requests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw VoteRequestException('사용자 신청 내역 조회 실패: $e');
    }
  }

  /// 제목별 신청 수 조회
  Future<int> getApplicationCountByTitle(String title) async {
    try {
      final response = await _supabase
          .from('artist')
          .select('id')
          .ilike('name->ko', '%$title%');

      return (response as List).length;
    } catch (e) {
      throw VoteRequestException('제목별 신청 수 조회 실패: $e');
    }
  }

  /// 사용자 신청 상태 조회
  Future<Map<String, dynamic>?> getUserApplicationStatus(
      String userId, int voteId, int artistId) async {
    try {
      // 뷰를 사용하여 아티스트 정보가 포함된 데이터 조회
      final response = await _supabase
          .from('vote_item_requests')
          .select('*')
          .eq('user_id', userId)
          .eq('vote_id', voteId)
          .eq('artist_id', artistId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw VoteRequestException('사용자 신청 상태 조회 실패: $e');
    }
  }

  /// VoteItemRequestUser 생성
  Future<VoteItemRequestUser> createVoteItemRequestUser({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    try {
      final result = await createVoteItemRequestWithUser(
        voteId: voteId,
        artistId: artistId,
        userId: userId,
      );

      return VoteItemRequestUser.fromJson(result);
    } catch (e) {
      throw VoteRequestException('VoteItemRequestUser 생성 실패: $e');
    }
  }

  /// 사용자의 투표 아이템 신청 목록 조회
  Future<List<Map<String, dynamic>>> getUserVoteItemRequests(
      String userId) async {
    try {
      return await getCurrentUserApplicationsWithDetails(userId);
    } catch (e) {
      throw VoteRequestException('사용자 투표 아이템 신청 목록 조회 실패: $e');
    }
  }

  /// 투표 아이템 요청과 사용자 정보를 함께 생성
  Future<Map<String, dynamic>> createVoteItemRequestWithUser({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_vote_item_request_with_user',
        params: {
          'vote_id_param': voteId,
          'artist_id_param': artistId,
          'user_id_param': userId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      if (e.toString().contains('이미 해당 아티스트에 대해 신청하셨습니다')) {
        throw const DuplicateVoteRequestException('이미 해당 아티스트에 대해 신청하셨습니다.');
      } else if (e.toString().contains('존재하지 않는 아티스트입니다')) {
        throw VoteRequestException('존재하지 않는 아티스트입니다.');
      }
      throw VoteRequestException('투표 아이템 요청 생성 실패: $e');
    }
  }

  /// 특정 투표에서 특정 아티스트의 신청 수 조회
  Future<int> getArtistRequestCount(int voteId, int artistId) async {
    try {
      final response = await _supabase.rpc(
        'get_artist_request_count',
        params: {
          'vote_id_param': voteId,
          'artist_id_param': artistId,
        },
      );

      return response as int;
    } catch (e) {
      throw VoteRequestException('아티스트 신청 수 조회 실패: $e');
    }
  }

  /// 사용자가 특정 투표에서 특정 아티스트에 대해 신청했는지 확인
  Future<bool> hasUserRequestedArtist(
      int voteId, int artistId, String userId) async {
    try {
      final response = await _supabase
          .from('vote_item_request_users')
          .select('id')
          .eq('vote_id', voteId)
          .eq('artist_id', artistId)
          .eq('user_id', userId)
          .maybeSingle();

      logger.d('hasUserRequestedArtist: $response');

      // response가 null이 아니면 신청한 것, null이면 신청하지 않은 것
      return response != null;
    } catch (e) {
      throw VoteRequestException('사용자 신청 여부 확인 실패: $e');
    }
  }

  /// 특정 투표의 모든 요청 조회 (아티스트 정보 포함)
  Future<List<VoteItemRequestUser>> getVoteItemRequestsByVoteId(
      int voteId) async {
    try {
      // 뷰를 사용하여 아티스트 정보가 포함된 데이터 조회
      final response = await _supabase
          .from('vote_item_requests')
          .select('*')
          .eq('vote_id', voteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => VoteItemRequestUser.fromJson(data))
          .toList();
    } catch (e) {
      throw VoteRequestException('투표 아이템 요청 목록 조회 실패: $e');
    }
  }

  /// 사용자의 특정 투표에 대한 신청 내역 조회
  Future<List<VoteItemRequestUser>> getUserRequestsByVoteId(
      String userId, int voteId) async {
    try {
      // 뷰를 사용하여 아티스트 정보가 포함된 데이터 조회
      final response = await _supabase
          .from('vote_item_requests')
          .select('*')
          .eq('user_id', userId)
          .eq('vote_id', voteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => VoteItemRequestUser.fromJson(data))
          .toList();
    } catch (e) {
      throw VoteRequestException('사용자 신청 내역 조회 실패: $e');
    }
  }

  /// 사용자의 모든 신청 내역 조회
  Future<List<VoteItemRequestUser>> getAllUserRequests(String userId) async {
    try {
      final response =
          await _supabase.from('vote_item_request_users').select('''
            *,
            artist(id, name, image, group_id)
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return (response as List)
          .map((data) => VoteItemRequestUser.fromJson(data))
          .toList();
    } catch (e) {
      throw VoteRequestException('사용자 전체 신청 내역 조회 실패: $e');
    }
  }

  /// 투표 아이템 요청 상태 업데이트
  Future<VoteItemRequestUser> updateVoteItemRequestStatus(
      String requestId, String status) async {
    try {
      final response = await _supabase
          .from('vote_item_request_users')
          .update({'status': status})
          .eq('id', requestId)
          .select()
          .single();

      return VoteItemRequestUser.fromJson(response);
    } catch (e) {
      throw VoteRequestException('투표 아이템 요청 상태 업데이트 실패: $e');
    }
  }

  /// 특정 아티스트의 신청 통계 조회
  Future<Map<String, dynamic>> getArtistRequestStatistics(int artistId) async {
    try {
      final response = await _supabase
          .from('artist_request_statistics')
          .select('*')
          .eq('artist_id', artistId)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      throw VoteRequestException('아티스트 신청 통계 조회 실패: $e');
    }
  }

  /// 투표별 신청 상태 요약 조회
  Future<List<Map<String, dynamic>>> getVoteRequestStatusSummary(
      int voteId) async {
    try {
      final response = await _supabase
          .from('vote_item_request_status_summary')
          .select('*')
          .eq('vote_id', voteId)
          .order('request_count', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw VoteRequestException('투표 신청 상태 요약 조회 실패: $e');
    }
  }

  /// 사용자 신청 히스토리 조회
  Future<List<Map<String, dynamic>>> getUserRequestHistory(
      String userId) async {
    try {
      final response = await _supabase
          .from('user_vote_item_request_history')
          .select('*')
          .eq('user_id', userId)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw VoteRequestException('사용자 신청 히스토리 조회 실패: $e');
    }
  }

  /// 투표 아이템 요청 삭제 (뷰이므로 실제로는 vote_item_request_users에서 삭제)
  Future<void> deleteVoteItemRequest(String requestId) async {
    try {
      // vote_item_requests는 이제 뷰이므로 실제 데이터는 vote_item_request_users에서 삭제
      await _supabase
          .from('vote_item_request_users')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw VoteRequestException('투표 아이템 요청 삭제 실패: $e');
    }
  }

  /// 사용자 신청 삭제
  Future<void> deleteUserRequest(String userRequestId) async {
    try {
      await _supabase
          .from('vote_item_request_users')
          .delete()
          .eq('id', userRequestId);
    } catch (e) {
      throw VoteRequestException('사용자 신청 삭제 실패: $e');
    }
  }
}
