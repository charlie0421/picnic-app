import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:picnic_lib/l10n.dart';

class QnaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[QNA-I18N] $message');
    }
  }

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

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final status = (map['status'] as String?)?.trim();
        if (status == null || status.isEmpty) {
          map['status'] = 'RECEIVED';
        }
        return QnaThread.fromJson(map);
      }).toList();
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

      String? categoryLabel;
      final categoryCode = threadResponse['category_code'] as String?;
      if (categoryCode != null && categoryCode.isNotEmpty) {
        categoryLabel = await _getCategoryLabelByCode(categoryCode);
      }

      return QaThreadWithMessages(
        thread: thread,
        messages: messages,
        categoryLabel: categoryLabel,
      );
    } catch (e) {
      throw Exception('Q&A 스레드 조회 실패: $e');
    }
  }

  // 기존 _resolveLocalized는 더 이상 사용하지 않고, 공통 유틸(getLocaleTextFromJson)을 사용합니다.

  Future<String?> _getCategoryLabelByCode(String code) async {
    try {
      final row = await _client
          .from('qna_categories')
          .select('label')
          .eq('code', code)
          .maybeSingle();
      if (row == null) return null;
      final dynamic labelField = row['label'];
      if (labelField is Map<String, dynamic>) {
        final resolved = getLocaleTextFromJson(labelField);
        return resolved.isEmpty ? null : resolved;
      }
      return null;
    } catch (e) {
      _logDebug('error fetching label for code=$code: $e');
      return null;
    }
  }

  /// Q&A 스레드 생성
  Future<QnaThread> createQaThread({
    required String userId,
    required String title,
    required String initialMessage,
    String? categoryCode,
    List<File>? attachments,
  }) async {
    try {
      // 1. 스레드 생성
      final insertData = <String, dynamic>{'user_id': userId, 'title': title};
      if (categoryCode != null) {
        insertData['category_code'] = categoryCode;
      }

      final threadResponse = await _client
          .from('qna_threads')
          .insert(insertData)
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

  /// Q&A 카테고리 목록 조회
  Future<List<QnaCategory>> getCategories() async {
    try {
      final response = await _client
          .from('qna_categories')
          .select(
            'code,label,question_template,answer_template,order_number,active',
          )
          .eq('active', true)
          .order('order_number', ascending: true);

      final list = (response as List<dynamic>).map((raw) {
        final Map<String, dynamic> row = raw as Map<String, dynamic>;
        final Map<String, dynamic>? labelJson =
            row['label'] as Map<String, dynamic>?;
        final Map<String, dynamic>? qJson =
            row['question_template'] as Map<String, dynamic>?;
        final Map<String, dynamic>? aJson =
            row['answer_template'] as Map<String, dynamic>?;

        final label = labelJson != null ? getLocaleTextFromJson(labelJson) : '';
        final qTmpl = qJson != null ? getLocaleTextFromJson(qJson) : null;
        final aTmpl = aJson != null ? getLocaleTextFromJson(aJson) : null;

        if (kDebugMode &&
            ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase() ==
                'en') {
          _logDebug(
            'code=${row['code']} label="$label" qTmplPreview="${(qTmpl ?? '').toString().substring(0, (qTmpl ?? '').length.clamp(0, 30))}"',
          );
        }

        return QnaCategory(
          code: row['code'] as String,
          label: label,
          questionTemplate: qTmpl,
          answerTemplate: aTmpl,
        );
      }).toList();

      return list;
    } catch (e) {
      throw Exception('Q&A 카테고리 조회 실패: $e');
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
          final safeName = _generateUuidName(p.extension(file.path));
          final filePath = 'qna/$userId/${newMessage.id}/$safeName';

          await _client.storage
              .from('qna_attachments')
              .upload(
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
            'file_name': safeName,
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

  String _generateUuidName(String extension) {
    final uuid = const Uuid().v4().replaceAll('-', '');
    final normalizedExt = extension.isNotEmpty && extension.startsWith('.')
        ? extension
        : (extension.isNotEmpty ? '.$extension' : '');
    return '$uuid$normalizedExt';
  }

  /// 스토리지 파일의 공개 URL 가져오기
  String getPublicUrl(String path) {
    try {
      final response = _client.storage
          .from('qna_attachments')
          .getPublicUrl(path);
      return response;
    } catch (e) {
      throw Exception('공개 URL 가져오기 실패: $e');
    }
  }

  /// 특정 스레드에서 가장 처음(오래된) 첨부파일 1개 조회
  Future<QnaAttachment?> getFirstAttachmentForThread(int threadId) async {
    try {
      final List<dynamic> rows = await _client
          .from('qna_attachments')
          .select('*, qna_messages!inner(thread_id)')
          .eq('qna_messages.thread_id', threadId)
          .order('created_at', ascending: true)
          .limit(1);

      if (rows.isEmpty) return null;
      final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
      return QnaAttachment.fromJson(row);
    } catch (e) {
      throw Exception('첫 첨부파일 조회 실패: $e');
    }
  }
}

/// 특정 Q&A 스레드와 메시지 목록을 함께 반환하기 위한 헬퍼 클래스
class QaThreadWithMessages {
  final QnaThread thread;
  final List<QnaMessage> messages;
  final String? categoryLabel;

  QaThreadWithMessages({
    required this.thread,
    required this.messages,
    this.categoryLabel,
  });
}
