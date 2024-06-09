import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'banner.g.dart';

@reflector
@JsonSerializable()
class BannerModel {
  final int id;
  final String title_ko;
  final String title_en;
  final String title_ja;
  final String title_zh;
  String? thumbnail;

  BannerModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    required this.title_ja,
    required this.title_zh,
    this.thumbnail,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}
