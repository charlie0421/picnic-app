import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/user_profiles.dart';

part '../../generated/models/pic/celeb.freezed.dart';

part '../../generated/models/pic/celeb.g.dart';

@freezed
class CelebModel with _$CelebModel {
  const CelebModel._();

  const factory CelebModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name_ko') required String nameKo,
    @JsonKey(name: 'name_en') required String nameEn,
    @JsonKey(name: 'thumbnail') String? thumbnail,
    @JsonKey(name: 'users') List<UserProfilesModel>? users,
  }) = _CelebModel;

  factory CelebModel.fromJson(Map<String, dynamic> json) =>
      _$CelebModelFromJson(json);
}
