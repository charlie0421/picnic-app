// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/common/social_login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SocialLoginResultImpl _$$SocialLoginResultImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$SocialLoginResultImpl',
      json,
      ($checkedConvert) {
        final val = _$SocialLoginResultImpl(
          idToken: $checkedConvert('id_token', (v) => v as String?),
          accessToken: $checkedConvert('access_token', (v) => v as String?),
          userData:
              $checkedConvert('user_data', (v) => v as Map<String, dynamic>?),
        );
        return val;
      },
      fieldKeyMap: const {
        'idToken': 'id_token',
        'accessToken': 'access_token',
        'userData': 'user_data'
      },
    );

Map<String, dynamic> _$$SocialLoginResultImplToJson(
        _$SocialLoginResultImpl instance) =>
    <String, dynamic>{
      'id_token': instance.idToken,
      'access_token': instance.accessToken,
      'user_data': instance.userData,
    };
