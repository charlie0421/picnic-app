// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyProfileModel _$MyProfileModelFromJson(Map<String, dynamic> json) =>
    MyProfileModel(
      id: json['id'] as int,
      profileImage: json['profileImage'] as String?,
      nickname: json['nickname'] as String?,
      email: json['email'] as String?,
      userAgreement: json['userAgreement'] == null
          ? null
          : UserAgreement.fromJson(
              json['userAgreement'] as Map<String, dynamic>),
      pushToken: json['pushToken'] == null
          ? null
          : UserPushToken.fromJson(json['pushToken'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MyProfileModelToJson(MyProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profileImage': instance.profileImage,
      'nickname': instance.nickname,
      'email': instance.email,
      'userAgreement': instance.userAgreement,
      'pushToken': instance.pushToken,
    };

UserAgreement _$UserAgreementFromJson(Map<String, dynamic> json) =>
    UserAgreement(
      id: json['id'] as int,
      terms: json['terms'] == null
          ? null
          : DateTime.parse(json['terms'] as String),
      privacy: json['privacy'] == null
          ? null
          : DateTime.parse(json['privacy'] as String),
    );

Map<String, dynamic> _$UserAgreementToJson(UserAgreement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'terms': instance.terms?.toIso8601String(),
      'privacy': instance.privacy?.toIso8601String(),
    };
