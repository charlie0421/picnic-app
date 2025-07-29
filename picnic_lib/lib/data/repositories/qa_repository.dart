import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Q&A 스레드 목록 조회
  Future<List<QnaThread>> getQaThreadList({required String userId}) async {
    try {
      final response = await _client
          .from('qna_threads')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => QnaThread.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Q&A 스레드 목록 조회 실패: $e');
    }
  }

  /// 특정 Q&A 스레드 및 메시지 조회
  Future<QaThreadWithMessages> getQaThreadById(int threadId) async {
    try {
      final threadResponse = await _client
          .from('qna_threads')
          .select()
          .eq('id', threadId)
          .single();

      final messagesResponse = await _client
          .from('qna_messages')
          .select('*, qna_attachments(*)')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);

      final thread = QnaThread.fromJson(threadResponse);
      final messages = (messagesResponse as List<dynamic>)
          .map((item) => QnaMessage.fromJson(item as Map<String, dynamic>))
          .toList();

      return QaThreadWithMessages(thread: thread, messages: messages);
    } catch (e) {
      throw Exception('Q&A 스레드 조회 실패: $e');
    }
  }

  /// Q&A 스레드 생성
  Future<QnaThread> createQaThread({
    required String userId,
    required String title,
    required String initialMessage,
  }) async {
    try {
      // 1. 스레드 생성
      final threadResponse = await _client
          .from('qna_threads')
          .insert({'user_id': userId, 'title': title})
          .select()
          .single();

      final newThread = QnaThread.fromJson(threadResponse);

      // 2. 첫 번째 메시지 생성
      await createQaMessage(
        threadId: newThread.id,
        userId: userId,
        content: initialMessage,
      );

      return newThread;
    } catch (e) {
      throw Exception('Q&A 스레드 생성 실패: $e');
    }
  }

  /// Q&A 메시지 생성
  Future<QnaMessage> createQaMessage({
    required int threadId,
    required String userId,
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final messageResponse = await _client
          .from('qna_messages')
          .insert({
            'thread_id': threadId,
            'user_id': userId,
            'content': content,
          })
          .select()
          .single();

      final newMessage = QnaMessage.fromJson(messageResponse);
      logger.d('New message created with ID: ${newMessage.id}');

      // 첨부파일이 있는 경우
      if (attachments != null && attachments.isNotEmpty) {
        logger.d('Attachments found, preparing to insert...');
        final attachmentRecords = attachments
            .map((att) => {
                  'message_id': newMessage.id,
                  'file_name': att['file_name'],
                  'file_path': att['file_path'],
                  'file_type': att['file_type'],
                  'file_size': att['file_size'],
                })
            .toList();

        logger.d('Inserting attachment records: $attachmentRecords');
        await _client.from('qna_attachments').insert(attachmentRecords);
        logger.d('Attachment records inserted successfully.');
      }

      // 완성된 메시지 다시 조회 (첨부파일 포함)
      logger.d('Refetching message with attachments...');
      final finalMessage = await _client
          .from('qna_messages')
          .select('*, qna_attachments(*)')
          .eq('id', newMessage.id)
          .single();

      logger.d('Final message data: $finalMessage');
      return QnaMessage.fromJson(finalMessage);
    } catch (e) {
      logger.d('Error creating Q&A message: $e');
      throw Exception('Q&A 메시지 생성 실패: $e');
    }
  }

  /// 스토리지 파일의 서명된 URL 가져오기
  Future<String> getSignedUrl(String path) async {
    try {
      final response = await _client.storage
          .from('qna_attachments')
          .createSignedUrl(path, 60 * 60); // 1 hour expiration
      return response;
    } catch (e) {
      throw Exception('서명된 URL 가져오기 실패: $e');
    }
  }
}

/// 특정 Q&A 스레드와 메시지 목록을 함께 반환하기 위한 헬퍼 클래스
class QaThreadWithMessages {
  final QnaThread thread;
  final List<QnaMessage> messages;

  QaThreadWithMessages({required this.thread, required this.messages});
}
