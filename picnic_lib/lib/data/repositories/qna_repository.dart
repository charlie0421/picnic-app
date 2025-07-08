import 'package:picnic_lib/data/models/qna/qna.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QnARepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// QnA 목록 조회
  Future<QnAListResponse> getQnAList({
    int page = 1,
    int limit = 20,
    String? status,
    bool? isPrivate,
  }) async {
    try {
      var query = _client
          .from('qnas')
          .select('*')
          .order('created_at', ascending: false);

      // 필터 조건이 있는 경우 새로운 쿼리 체인 구성
      if (status != null && isPrivate != null) {
        query = _client
            .from('qnas')
            .select('*')
            .eq('status', status)
            .eq('is_private', isPrivate)
            .order('created_at', ascending: false);
      } else if (status != null) {
        query = _client
            .from('qnas')
            .select('*')
            .eq('status', status)
            .order('created_at', ascending: false);
      } else if (isPrivate != null) {
        query = _client
            .from('qnas')
            .select('*')
            .eq('is_private', isPrivate)
            .order('created_at', ascending: false);
      }

      final offset = (page - 1) * limit;
      final response = await query.range(offset, offset + limit - 1);

      // 간단한 count 조회
      final totalResponse =
          await _client.from('qnas').select('qna_id'); // id -> qna_id로 변경

      final items = (response as List<dynamic>)
          .map((item) => QnA.fromJson(item as Map<String, dynamic>))
          .toList();

      return QnAListResponse(
        items: items,
        totalCount: totalResponse.length,
        page: page,
        pageSize: limit,
      );
    } catch (e) {
      throw Exception('QnA 목록 조회 실패: $e');
    }
  }

  /// 특정 QnA 조회
  Future<QnA?> getQnAById(int qnaId) async {
    // id -> qnaId로 변경
    try {
      final response = await _client
          .from('qnas')
          .select('*')
          .eq('qna_id', qnaId) // id -> qna_id로 변경
          .maybeSingle();

      if (response == null) return null;

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('QnA 조회 실패: $e');
    }
  }

  /// 사용자의 QnA 목록 조회
  Future<QnAListResponse> getMyQnAList({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _client
          .from('qnas')
          .select('*')
          .eq('created_by', userId) // user_id -> created_by로 변경
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final totalResponse = await _client
          .from('qnas')
          .select('qna_id') // id -> qna_id로 변경
          .eq('created_by', userId); // user_id -> created_by로 변경

      final items = (response as List<dynamic>)
          .map((item) => QnA.fromJson(item as Map<String, dynamic>))
          .toList();

      return QnAListResponse(
        items: items,
        totalCount: totalResponse.length,
        page: page,
        pageSize: limit,
      );
    } catch (e) {
      throw Exception('내 QnA 목록 조회 실패: $e');
    }
  }

  /// QnA 생성
  Future<QnA> createQnA(QnACreateRequest request) async {
    try {
      final response =
          await _client.from('qnas').insert(request.toJson()).select().single();

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('QnA 생성 실패: $e');
    }
  }

  /// QnA 수정 (제목, 내용만)
  Future<QnA> updateQnA({
    required int qnaId, // id -> qnaId로 변경
    required String userId,
    String? title,
    String? question, // content -> question으로 변경
    bool? isPrivate, // isPublic -> isPrivate로 변경
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (question != null) {
        updateData['question'] = question; // content -> question
      }
      if (isPrivate != null) {
        updateData['is_private'] = isPrivate; // is_public -> is_private
      }

      final response = await _client
          .from('qnas')
          .update(updateData)
          .eq('qna_id', qnaId) // id -> qna_id로 변경
          .eq('created_by', userId) // user_id -> created_by로 변경
          .select()
          .single();

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('QnA 수정 실패: $e');
    }
  }

  /// QnA 삭제 (소프트 삭제)
  Future<void> deleteQnA({
    required int qnaId, // id -> qnaId로 변경
    required String userId,
  }) async {
    try {
      await _client
          .from('qnas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('qna_id', qnaId) // id -> qna_id로 변경
          .eq('created_by', userId); // user_id -> created_by로 변경
    } catch (e) {
      throw Exception('QnA 삭제 실패: $e');
    }
  }

  /// 답변 추가 (관리자용)
  Future<QnA> addAnswer({
    required int qnaId, // id -> qnaId로 변경
    required String answer,
    required String answeredBy,
  }) async {
    try {
      final response = await _client
          .from('qnas')
          .update({
            'answer': answer,
            'answered_by': answeredBy,
            'answered_at': DateTime.now().toIso8601String(),
            'status': 'ANSWERED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('qna_id', qnaId) // id -> qna_id로 변경
          .select()
          .single();

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('답변 추가 실패: $e');
    }
  }
}
