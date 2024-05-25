// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celeb_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CelebBannerModel _$CelebBannerModelFromJson(Map<String, dynamic> json) =>
    CelebBannerModel(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      thumbnail: json['thumbnail'] as String?,
    );

Map<String, dynamic> _$CelebBannerModelToJson(CelebBannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'thumbnail': instance.thumbnail,
    };
