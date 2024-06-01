import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'banner.g.dart';

// @reflector
// @JsonSerializable()
// class CelebBannerListModel {
//   final List<CelebBannerModel> items;
//   final MetaModel meta;
//
//   CelebBannerListModel({
//     required this.items,
//     required this.meta,
//   });
//
//   factory CelebBannerListModel.fromJson(Map<String, dynamic> json) =>
//       _$CelebBannerListModelFromJson(json);
//
//   Map<String, dynamic> toJson() => _$CelebBannerListModelToJson(this);
// }

@reflector
@JsonSerializable()
class BannerModel {
  final int id;
  final String title_ko;
  final String title_en;
  String? thumbnail;

  BannerModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    this.thumbnail,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}
