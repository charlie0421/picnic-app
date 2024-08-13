import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

@reflector
@freezed
class BannerModel with _$BannerModel {
  const BannerModel._();

  const factory BannerModel({
    required int id,
    required Map<String, dynamic> title,
    required String thumbnail,
    required Map<String, dynamic> image,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
}
