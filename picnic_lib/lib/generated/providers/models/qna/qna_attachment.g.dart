// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/qna/qna_attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QnaAttachmentImpl _$$QnaAttachmentImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$QnaAttachmentImpl',
      json,
      ($checkedConvert) {
        final val = _$QnaAttachmentImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          messageId: $checkedConvert('message_id', (v) => (v as num).toInt()),
          fileName: $checkedConvert('file_name', (v) => v as String),
          filePath: $checkedConvert('file_path', (v) => v as String),
          fileType: $checkedConvert('file_type', (v) => v as String?),
          fileSize: $checkedConvert('file_size', (v) => (v as num?)?.toInt()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'messageId': 'message_id',
        'fileName': 'file_name',
        'filePath': 'file_path',
        'fileType': 'file_type',
        'fileSize': 'file_size',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$QnaAttachmentImplToJson(_$QnaAttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_id': instance.messageId,
      'file_name': instance.fileName,
      'file_path': instance.filePath,
      'file_type': instance.fileType,
      'file_size': instance.fileSize,
      'created_at': instance.createdAt.toIso8601String(),
    };
