// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profiles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfilesModelImpl _$$UserProfilesModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserProfilesModelImpl(
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      avatar_url: json['avatar_url'] as String?,
      country_code: json['country_code'] as String?,
      star_candy: (json['star_candy'] as num).toInt(),
      star_candy_bonus: (json['star_candy_bonus'] as num).toInt(),
    );

Map<String, dynamic> _$$UserProfilesModelImplToJson(
        _$UserProfilesModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatar_url,
      'country_code': instance.country_code,
      'star_candy': instance.star_candy,
      'star_candy_bonus': instance.star_candy_bonus,
    };
