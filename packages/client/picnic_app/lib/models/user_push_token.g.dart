// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_push_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPushToken _$UserPushTokenFromJson(Map<String, dynamic> json) =>
    UserPushToken(
      id: (json['id'] as num).toInt(),
      user_id: (json['user_id'] as num).toInt(),
      token_ios: json['token_ios'] as String,
      token_android: json['token_android'] as String,
      token_web: json['token_web'] as String,
      token_macos: json['token_macos'] as String,
      token_windows: json['token_windows'] as String,
    );

Map<String, dynamic> _$UserPushTokenToJson(UserPushToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'token_ios': instance.token_ios,
      'token_android': instance.token_android,
      'token_web': instance.token_web,
      'token_macos': instance.token_macos,
      'token_windows': instance.token_windows,
    };
