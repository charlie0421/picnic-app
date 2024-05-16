import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'celeb_banner.g.dart';

@reflector
@JsonSerializable()
class CelebBannerListModel {
  final List<CelebBannerModel> items;
  final MetaModel meta;

  CelebBannerListModel({
    required this.items,
    required this.meta,
  });

  factory CelebBannerListModel.fromJson(Map<String, dynamic> json) =>
      _$CelebBannerListModelFromJson(json);

  Map<String, dynamic> toJson() => _$CelebBannerListModelToJson(this);
}

@reflector
@JsonSerializable()
class CelebBannerModel {
  final int id;
  final String titleKo;
  final String titleEn;
  final String thumbnail;

  CelebBannerModel({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.thumbnail,
  });

  factory CelebBannerModel.fromJson(Map<String, dynamic> json) =>
      _$CelebBannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CelebBannerModelToJson(this);
}
