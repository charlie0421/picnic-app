import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'user_profiles.freezed.dart';

part 'user_profiles.g.dart';

@reflector
@freezed
class UserProfilesListModel with _$UserProfilesListModel {
  const UserProfilesListModel._();

  const factory UserProfilesListModel({
    required List<UserProfilesModel> items,
    required MetaModel meta,
  }) = _UserProfilesListModel;
}

@reflector
@freezed
class UserProfilesModel with _$UserProfilesModel {
  const UserProfilesModel._();

  const factory UserProfilesModel({
    String? id,
    String? nickname,
    String? avatar_url,
    String? country_code,
    required int star_candy,
    required int star_candy_bonus,
  }) = _UserProfilesModel;

  factory UserProfilesModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfilesModelFromJson(json);
}
