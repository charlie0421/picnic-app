// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../data/models/user_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserNotificationImpl _$$UserNotificationImplFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  r'_$UserNotificationImpl',
  json,
  ($checkedConvert) {
    final val = _$UserNotificationImpl(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      userId: $checkedConvert('user_id', (v) => v as String?),
      title: $checkedConvert('title', (v) => v as String),
      body: $checkedConvert('body', (v) => v as String),
      data: $checkedConvert('data', (v) => v as Map<String, dynamic>?),
      actionUrl: $checkedConvert('action_url', (v) => v as String?),
      type: $checkedConvert('type', (v) => v as String? ?? 'default'),
      isRead: $checkedConvert('is_read', (v) => v as bool? ?? false),
      createdAt: $checkedConvert('created_at', (v) => v as String?),
      readAt: $checkedConvert('read_at', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'actionUrl': 'action_url',
    'isRead': 'is_read',
    'createdAt': 'created_at',
    'readAt': 'read_at',
  },
);

Map<String, dynamic> _$$UserNotificationImplToJson(
  _$UserNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'body': instance.body,
  'data': instance.data,
  'action_url': instance.actionUrl,
  'type': instance.type,
  'is_read': instance.isRead,
  'created_at': instance.createdAt,
  'read_at': instance.readAt,
};
