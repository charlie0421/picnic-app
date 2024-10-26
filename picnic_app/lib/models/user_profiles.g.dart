// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profiles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfilesModelImpl _$$UserProfilesModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserProfilesModelImpl(
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      countryCode: json['country_code'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      userAgreement: json['user_agreement'] == null
          ? null
          : UserAgreement.fromJson(
              json['user_agreement'] as Map<String, dynamic>),
      isAdmin: json['is_admin'] as bool?,
      starCandy: (json['star_candy'] as num?)?.toInt(),
      starCandyBonus: (json['star_candy_bonus'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UserProfilesModelImplToJson(
        _$UserProfilesModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'country_code': instance.countryCode,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'user_agreement': instance.userAgreement,
      'is_admin': instance.isAdmin,
      'star_candy': instance.starCandy,
      'star_candy_bonus': instance.starCandyBonus,
    };

_$UserAgreementImpl _$$UserAgreementImplFromJson(Map<String, dynamic> json) =>
    _$UserAgreementImpl(
      terms: DateTime.parse(json['terms'] as String),
      privacy: DateTime.parse(json['privacy'] as String),
    );

Map<String, dynamic> _$$UserAgreementImplToJson(_$UserAgreementImpl instance) =>
    <String, dynamic>{
      'terms': instance.terms.toIso8601String(),
      'privacy': instance.privacy.toIso8601String(),
    };
