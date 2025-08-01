// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/qna/qna_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QnaMessageImpl _$$QnaMessageImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$QnaMessageImpl',
      json,
      ($checkedConvert) {
        final val = _$QnaMessageImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          threadId: $checkedConvert('thread_id', (v) => (v as num).toInt()),
          userId: $checkedConvert('user_id', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String?),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          isAdminMessage: $checkedConvert('is_admin_message', (v) => v as bool),
          attachments: $checkedConvert(
              'qna_attachments',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) =>
                          QnaAttachment.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  const []),
        );
        return val;
      },
      fieldKeyMap: const {
        'threadId': 'thread_id',
        'userId': 'user_id',
        'createdAt': 'created_at',
        'isAdminMessage': 'is_admin_message',
        'attachments': 'qna_attachments'
      },
    );

Map<String, dynamic> _$$QnaMessageImplToJson(_$QnaMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'thread_id': instance.threadId,
      'user_id': instance.userId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_admin_message': instance.isAdminMessage,
      'qna_attachments': instance.attachments.map((e) => e.toJson()).toList(),
    };
