// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celeb.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CelebListModelImpl _$$CelebListModelImplFromJson(Map<String, dynamic> json) =>
    _$CelebListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => CelebModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CelebListModelImplToJson(
        _$CelebListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$CelebModelImpl _$$CelebModelImplFromJson(Map<String, dynamic> json) =>
    _$CelebModelImpl(
      id: (json['id'] as num).toInt(),
      name_ko: json['name_ko'] as String,
      name_en: json['name_en'] as String,
      thumbnail: json['thumbnail'] as String?,
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => UserProfilesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$CelebModelImplToJson(_$CelebModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'thumbnail': instance.thumbnail,
      'users': instance.users,
    };
