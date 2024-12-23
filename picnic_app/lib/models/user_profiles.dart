import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/user_profiles.freezed.dart';
part '../generated/models/user_profiles.g.dart';

@freezed
class UserProfilesModel with _$UserProfilesModel {
  const UserProfilesModel._();

  const factory UserProfilesModel({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'nickname') String? nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'user_agreement') UserAgreement? userAgreement,
    @JsonKey(name: 'is_admin') required bool? isAdmin,
    @JsonKey(name: 'star_candy') required int? starCandy,
    @JsonKey(name: 'star_candy_bonus') required int? starCandyBonus,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'birth_time') String? birthTime,
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
