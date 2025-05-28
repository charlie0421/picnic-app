// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../data/models/wechat_token_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeChatTokenInfoImpl _$$WeChatTokenInfoImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$WeChatTokenInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$WeChatTokenInfoImpl(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          openId: $checkedConvert('open_id', (v) => v as String),
          unionId: $checkedConvert('union_id', (v) => v as String),
          scope: $checkedConvert('scope', (v) => v as String),
          expiresAt:
              $checkedConvert('expires_at', (v) => DateTime.parse(v as String)),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          nickname: $checkedConvert('nickname', (v) => v as String?),
          headImgUrl: $checkedConvert('head_img_url', (v) => v as String?),
          country: $checkedConvert('country', (v) => v as String?),
          province: $checkedConvert('province', (v) => v as String?),
          city: $checkedConvert('city', (v) => v as String?),
          language: $checkedConvert('language', (v) => v as String?),
          sex: $checkedConvert('sex', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'refreshToken': 'refresh_token',
        'openId': 'open_id',
        'unionId': 'union_id',
        'expiresAt': 'expires_at',
        'createdAt': 'created_at',
        'headImgUrl': 'head_img_url'
      },
    );

Map<String, dynamic> _$$WeChatTokenInfoImplToJson(
        _$WeChatTokenInfoImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'open_id': instance.openId,
      'union_id': instance.unionId,
      'scope': instance.scope,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'nickname': instance.nickname,
      'head_img_url': instance.headImgUrl,
      'country': instance.country,
      'province': instance.province,
      'city': instance.city,
      'language': instance.language,
      'sex': instance.sex,
    };
