import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/common/banner.freezed.dart';
part '../../generated/models/common/banner.g.dart';

@freezed
class BannerModel with _$BannerModel {
  const BannerModel._();

  const factory BannerModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title') required Map<String, dynamic> title,
    @JsonKey(name: 'thumbnail') required String thumbnail,
    @JsonKey(name: 'image') required Map<String, dynamic> image,
    @JsonKey(name: 'duration', defaultValue: 3000) required int duration,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
}
