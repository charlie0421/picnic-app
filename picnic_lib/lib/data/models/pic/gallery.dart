import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';

part '../../../generated/models/pic/gallery.freezed.dart';
part '../../../generated/models/pic/gallery.g.dart';

@freezed
class GalleryModel with _$GalleryModel {
  const GalleryModel._();

  const factory GalleryModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title_ko') required String titleKo,
    @JsonKey(name: 'title_en') required String titleEn,
    @JsonKey(name: 'cover') String? cover,
    @JsonKey(name: 'celeb') required CelebModel? celeb,
  }) = _GalleryModel;

  String getTitle() {
    switch (Localizations.localeOf(navigatorKey.currentContext!).languageCode) {
      case 'ko':
        return titleKo;
      case 'en':
        return titleEn;
      default:
        return titleEn;
    }
  }

  String getCdnUrl(String url) {
    return 'https://cdn-dev.picnic.fan/gallery/$id/$url';
  }

  factory GalleryModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryModelFromJson(json);
}
