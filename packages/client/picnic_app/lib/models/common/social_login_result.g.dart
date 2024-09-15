// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SocialLoginResultImpl _$$SocialLoginResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SocialLoginResultImpl(
      idToken: json['idToken'] as String?,
      accessToken: json['accessToken'] as String?,
      userData: json['userData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$SocialLoginResultImplToJson(
        _$SocialLoginResultImpl instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'accessToken': instance.accessToken,
      'userData': instance.userData,
    };
