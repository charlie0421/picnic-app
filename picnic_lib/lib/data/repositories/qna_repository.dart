import 'dart:io';
import 'package:mime/mime.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class QnaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Q&A 스레드 목록 조회
  Future<List<QnaThread>> getQaThreadList({
    required String userId,
    int? lastId,
    int limit = 20,
  }) async {
    try {
      var query = _client.from('qna_threads').select().eq('user_id', userId);

      if (lastId != null) {
        final lastItemResponse = await _client
            .from('qna_threads')
            .select('created_at')
            .eq('id', lastId)
            .single();
        final lastCreatedAt = lastItemResponse['created_at'] as String;

        query = query.or(
          'created_at.lt.$lastCreatedAt,and(created_at.eq.$lastCreatedAt,id.lt.$lastId)',
        );
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response).map((item) => QnaThread.fromJson(item)).toList();
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
    List<File>? attachments,
  }) async {
    try {
      // 1. 스레드 생성
      final threadResponse = await _client
          .from('qna_threads')
          .insert({'user_id': userId, 'title': title})
          .select()
          .single();

      final newThread = QnaThread.fromJson(threadResponse);

      // 2. 첫 번째 메시지 생성 (첨부파일과 함께)
      await createQaMessage(
        threadId: newThread.id,
        userId: userId,
        content: initialMessage,
        attachments: attachments,
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
    List<File>? attachments,
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

      // 첨부파일이 있는 경우
      if (attachments != null && attachments.isNotEmpty) {
        final List<Map<String, dynamic>> attachmentRecords = [];

        for (final file in attachments) {
          final fileName = p.basename(file.path);
          final filePath = 'qna/$userId/${newMessage.id}/$fileName';

          await _client.storage.from('qna_attachments').upload(
                filePath,
                file,
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: lookupMimeType(file.path),
                ),
              );

          attachmentRecords.add({
            'message_id': newMessage.id,
            'file_name': fileName,
            'file_path': filePath,
            'file_type': lookupMimeType(file.path),
            'file_size': await file.length(),
          });
        }
        await _client.from('qna_attachments').insert(attachmentRecords);
      }

      // 완성된 메시지 다시 조회 (첨부파일 포함)
      final finalMessage = await _client
          .from('qna_messages')
          .select('*, qna_attachments(*)')
          .eq('id', newMessage.id)
          .single();

      return QnaMessage.fromJson(finalMessage);
    } catch (e) {
      throw Exception('Q&A 메시지 생성 실패: $e');
    }
  }

  /// 스토리지 파일의 공개 URL 가져오기
  String getPublicUrl(String path) {
    try {
      final response =
          _client.storage.from('qna_attachments').getPublicUrl(path);
      return response;
    } catch (e) {
      throw Exception('공개 URL 가져오기 실패: $e');
    }
  }
}

/// 특정 Q&A 스레드와 메시지 목록을 함께 반환하기 위한 헬퍼 클래스
class QaThreadWithMessages {
  final QnaThread thread;
  final List<QnaMessage> messages;

  QaThreadWithMessages({required this.thread, required this.messages});
}
