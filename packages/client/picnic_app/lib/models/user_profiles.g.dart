// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profiles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfilesListModel _$UserProfilesListModelFromJson(
        Map<String, dynamic> json) =>
    UserProfilesListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => UserProfilesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserProfilesListModelToJson(
        UserProfilesListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

UserProfilesModel _$UserProfilesModelFromJson(Map<String, dynamic> json) =>
    UserProfilesModel(
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      country_code: json['country_code'] as String?,
      star_candy: (json['star_candy'] as num?)?.toInt(),
      avatar_url: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$UserProfilesModelToJson(UserProfilesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatar_url,
      'country_code': instance.country_code,
      'star_candy': instance.star_candy,
    };
