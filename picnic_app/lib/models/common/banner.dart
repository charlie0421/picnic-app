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
    required String title_ko,
    required String title_en,
    required String title_ja,
    required String title_zh,
    String? thumbnail,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
}
