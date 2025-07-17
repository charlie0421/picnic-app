// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../data/models/user_profiles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfilesModelImpl _$$UserProfilesModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$UserProfilesModelImpl',
      json,
      ($checkedConvert) {
        final val = _$UserProfilesModelImpl(
          id: $checkedConvert('id', (v) => v as String?),
          nickname: $checkedConvert('nickname', (v) => v as String?),
          avatarUrl: $checkedConvert('avatar_url', (v) => v as String?),
          countryCode: $checkedConvert('country_code', (v) => v as String?),
          deletedAt: $checkedConvert('deleted_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          userAgreement: $checkedConvert(
              'user_agreement',
              (v) => v == null
                  ? null
                  : UserAgreement.fromJson(v as Map<String, dynamic>)),
          isAdmin: $checkedConvert('is_admin', (v) => v as bool?),
          starCandy: $checkedConvert('star_candy', (v) => (v as num?)?.toInt()),
          starCandyBonus:
              $checkedConvert('star_candy_bonus', (v) => (v as num?)?.toInt()),
          jmaCandy: $checkedConvert('jma_candy', (v) => (v as num?)?.toInt()),
          birthDate: $checkedConvert('birth_date',
              (v) => v == null ? null : DateTime.parse(v as String)),
          gender: $checkedConvert('gender', (v) => v as String?),
          birthTime: $checkedConvert('birth_time', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'avatarUrl': 'avatar_url',
        'countryCode': 'country_code',
        'deletedAt': 'deleted_at',
        'userAgreement': 'user_agreement',
        'isAdmin': 'is_admin',
        'starCandy': 'star_candy',
        'starCandyBonus': 'star_candy_bonus',
        'jmaCandy': 'jma_candy',
        'birthDate': 'birth_date',
        'birthTime': 'birth_time'
      },
    );

Map<String, dynamic> _$$UserProfilesModelImplToJson(
        _$UserProfilesModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'avatar_url': instance.avatarUrl,
      'country_code': instance.countryCode,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'user_agreement': instance.userAgreement?.toJson(),
      'is_admin': instance.isAdmin,
      'star_candy': instance.starCandy,
      'star_candy_bonus': instance.starCandyBonus,
      'jma_candy': instance.jmaCandy,
      'birth_date': instance.birthDate?.toIso8601String(),
      'gender': instance.gender,
      'birth_time': instance.birthTime,
    };

_$UserAgreementImpl _$$UserAgreementImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$UserAgreementImpl',
      json,
      ($checkedConvert) {
        final val = _$UserAgreementImpl(
          terms: $checkedConvert('terms', (v) => DateTime.parse(v as String)),
          privacy:
              $checkedConvert('privacy', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$UserAgreementImplToJson(_$UserAgreementImpl instance) =>
    <String, dynamic>{
      'terms': instance.terms.toIso8601String(),
      'privacy': instance.privacy.toIso8601String(),
    };
