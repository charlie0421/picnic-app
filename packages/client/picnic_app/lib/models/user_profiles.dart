import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_profiles.freezed.dart';
part 'user_profiles.g.dart';

//
// @freezed
// class UserProfilesListModel with _$UserProfilesListModel {
//   const UserProfilesListModel._();
//
//   const factory UserProfilesListModel({
//     required List<UserProfilesModel> items,
//     required MetaModel meta,
//   }) = _UserProfilesListModel;
// }

@freezed
class UserProfilesModel with _$UserProfilesModel {
  const UserProfilesModel._();

  const factory UserProfilesModel({
    String? id,
    String? nickname,
    String? avatar_url,
    String? country_code,
    DateTime? deleted_at,
    UserAgreement? user_agreement,
    required bool is_admin,
    required int star_candy,
    required int star_candy_bonus,
    @JsonKey(includeFromJson: false) RealtimeChannel? realtime_channel,
  }) = _UserProfilesModel;

  factory UserProfilesModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfilesModelFromJson(json);
}

@freezed
class UserAgreement with _$UserAgreement {
  const UserAgreement._();

  const factory UserAgreement({
    required DateTime terms,
    required DateTime privacy,
  }) = _UserAgreement;

  factory UserAgreement.fromJson(Map<String, dynamic> json) =>
      _$UserAgreementFromJson(json);
}
