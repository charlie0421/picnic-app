// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celeb_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CelebBannerListModel _$CelebBannerListModelFromJson(
        Map<String, dynamic> json) =>
    CelebBannerListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => CelebBannerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CelebBannerListModelToJson(
        CelebBannerListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

CelebBannerModel _$CelebBannerModelFromJson(Map<String, dynamic> json) =>
    CelebBannerModel(
      id: json['id'] as int,
      titleKo: json['titleKo'] as String,
      titleEn: json['titleEn'] as String,
      thumbnail: json['thumbnail'] as String,
    );

Map<String, dynamic> _$CelebBannerModelToJson(CelebBannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleKo': instance.titleKo,
      'titleEn': instance.titleEn,
      'thumbnail': instance.thumbnail,
    };
