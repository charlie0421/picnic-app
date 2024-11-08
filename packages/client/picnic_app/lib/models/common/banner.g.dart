// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BannerModelImpl _$$BannerModelImplFromJson(Map<String, dynamic> json) =>
    _$BannerModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as Map<String, dynamic>,
      thumbnail: json['thumbnail'] as String,
      image: json['image'] as Map<String, dynamic>,
      duration: (json['duration'] as num?)?.toInt() ?? 3000,
    );

Map<String, dynamic> _$$BannerModelImplToJson(_$BannerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'image': instance.image,
      'duration': instance.duration,
    };
