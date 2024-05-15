import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/user_push_token.dart';
import 'package:prame_app/reflector.dart';

part 'my_profile.g.dart';

@reflector
@JsonSerializable()
class MyProfileModel {
  final int id;
  final String? profileImage;
  final String? nickname;
  final String? email;
  final UserAgreement? userAgreement;
  final UserPushToken? pushToken;

  MyProfileModel({
    required this.id,
    this.profileImage,
    this.nickname,
    this.email,
    this.userAgreement,
    this.pushToken,
  });

  factory MyProfileModel.fromJson(Map<String, dynamic> json) =>
      _$MyProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$MyProfileModelToJson(this);
}

@reflector
@JsonSerializable()
class UserAgreement {
  final int id;
  final DateTime? terms;
  final DateTime? privacy;

  UserAgreement({
    required this.id,
    this.terms,
    this.privacy,
  });

  factory UserAgreement.fromJson(Map<String, dynamic> json) =>
      _$UserAgreementFromJson(json);

  Map<String, dynamic> toJson() => _$UserAgreementToJson(this);
}
