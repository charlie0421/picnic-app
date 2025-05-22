// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../data/models/user_push_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPushTokenImpl _$$UserPushTokenImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$UserPushTokenImpl',
      json,
      ($checkedConvert) {
        final val = _$UserPushTokenImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          userId: $checkedConvert('user_id', (v) => (v as num).toInt()),
          tokenIos: $checkedConvert('token_ios', (v) => v as String),
          tokenAndroid: $checkedConvert('token_android', (v) => v as String),
          tokenWeb: $checkedConvert('token_web', (v) => v as String),
          tokenMacos: $checkedConvert('token_macos', (v) => v as String),
          tokenWindows: $checkedConvert('token_windows', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'tokenIos': 'token_ios',
        'tokenAndroid': 'token_android',
        'tokenWeb': 'token_web',
        'tokenMacos': 'token_macos',
        'tokenWindows': 'token_windows'
      },
    );

Map<String, dynamic> _$$UserPushTokenImplToJson(_$UserPushTokenImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'token_ios': instance.tokenIos,
      'token_android': instance.tokenAndroid,
      'token_web': instance.tokenWeb,
      'token_macos': instance.tokenMacos,
      'token_windows': instance.tokenWindows,
    };
