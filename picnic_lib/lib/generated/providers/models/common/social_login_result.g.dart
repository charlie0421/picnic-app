// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/common/social_login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialLoginResult _$SocialLoginResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_SocialLoginResult',
      json,
      ($checkedConvert) {
        final val = _SocialLoginResult(
          idToken: $checkedConvert('id_token', (v) => v as String?),
          accessToken: $checkedConvert('access_token', (v) => v as String?),
          userData: $checkedConvert(
            'user_data',
            (v) => v as Map<String, dynamic>?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'idToken': 'id_token',
        'accessToken': 'access_token',
        'userData': 'user_data',
      },
    );

Map<String, dynamic> _$SocialLoginResultToJson(_SocialLoginResult instance) =>
    <String, dynamic>{
      'id_token': instance.idToken,
      'access_token': instance.accessToken,
      'user_data': instance.userData,
    };
