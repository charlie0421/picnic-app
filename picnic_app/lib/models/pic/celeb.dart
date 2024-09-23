import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/user_profiles.dart';

part 'celeb.freezed.dart';
part 'celeb.g.dart';

@freezed
class CelebListModel with _$CelebListModel {
  const CelebListModel._();

  const factory CelebListModel({
    required List<CelebModel> items,
    required MetaModel meta,
  }) = _CelebListModel;

  factory CelebListModel.fromJson(Map<String, dynamic> json) =>
      _$CelebListModelFromJson(json);
}

@freezed
class CelebModel with _$CelebModel {
  const CelebModel._();

  const factory CelebModel({
    required int id,
    required String name_ko,
    required String name_en,
    String? thumbnail,
    List<UserProfilesModel>? users,
  }) = _CelebModel;

  factory CelebModel.fromJson(Map<String, dynamic> json) =>
      _$CelebModelFromJson(json);
}
