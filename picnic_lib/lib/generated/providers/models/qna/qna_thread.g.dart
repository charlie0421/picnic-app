// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/qna/qna_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QnaThread _$QnaThreadFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_QnaThread',
  json,
  ($checkedConvert) {
    final val = _QnaThread(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      userId: $checkedConvert('user_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
      status: $checkedConvert('status', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$QnaThreadToJson(_QnaThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'status': instance.status,
    };
