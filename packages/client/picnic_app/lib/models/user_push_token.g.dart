// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_push_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPushTokenImpl _$$UserPushTokenImplFromJson(Map<String, dynamic> json) =>
    _$UserPushTokenImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      tokenIos: json['token_ios'] as String,
      tokenAndroid: json['token_android'] as String,
      tokenWeb: json['token_web'] as String,
      tokenMacos: json['token_macos'] as String,
      tokenWindows: json['token_windows'] as String,
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
