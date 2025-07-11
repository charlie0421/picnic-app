import 'package:picnic_lib/data/models/qna/qna.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QnARepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// QnA 목록 조회
  Future<QnAListResponse> getQnAList({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      var query = _client
          .from('qnas')
          .select('*')
          .order('created_at', ascending: false);

      // 상태 필터 조건이 있는 경우
      if (status != null) {
        query = _client
            .from('qnas')
            .select('*')
            .eq('status', status)
            .order('created_at', ascending: false);
      }

      final offset = (page - 1) * limit;
      final response = await query.range(offset, offset + limit - 1);

      // 간단한 count 조회
      final totalResponse = await _client.from('qnas').select('qna_id');

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
    try {
      final response = await _client
          .from('qnas')
          .select('*')
          .eq('qna_id', qnaId)
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
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final totalResponse =
          await _client.from('qnas').select('qna_id').eq('created_by', userId);

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
    required int qnaId,
    required String userId,
    String? title,
    String? question,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (question != null) {
        updateData['question'] = question;
      }

      final response = await _client
          .from('qnas')
          .update(updateData)
          .eq('qna_id', qnaId)
          .eq('created_by', userId)
          .select()
          .single();

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('QnA 수정 실패: $e');
    }
  }

  /// QnA 삭제 (소프트 삭제)
  Future<void> deleteQnA({
    required int qnaId,
    required String userId,
  }) async {
    try {
      await _client
          .from('qnas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('qna_id', qnaId)
          .eq('created_by', userId);
    } catch (e) {
      throw Exception('QnA 삭제 실패: $e');
    }
  }

  /// 답변 추가 (관리자용)
  Future<QnA> addAnswer({
    required int qnaId,
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
          .eq('qna_id', qnaId)
          .select()
          .single();

      return QnA.fromJson(response);
    } catch (e) {
      throw Exception('답변 추가 실패: $e');
    }
  }
}
