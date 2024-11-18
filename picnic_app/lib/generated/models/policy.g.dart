// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../models/policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PolicyModelImpl _$$PolicyModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$PolicyModelImpl',
      json,
      ($checkedConvert) {
        final val = _$PolicyModelImpl(
          privacyEn: $checkedConvert('privacy_en',
              (v) => PrivacyModel.fromJson(v as Map<String, dynamic>)),
          termsEn: $checkedConvert('terms_en',
              (v) => TermsModel.fromJson(v as Map<String, dynamic>)),
          privacyKo: $checkedConvert('privacy_ko',
              (v) => PrivacyModel.fromJson(v as Map<String, dynamic>)),
          termsKo: $checkedConvert('terms_ko',
              (v) => TermsModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'privacyEn': 'privacy_en',
        'termsEn': 'terms_en',
        'privacyKo': 'privacy_ko',
        'termsKo': 'terms_ko'
      },
    );

Map<String, dynamic> _$$PolicyModelImplToJson(_$PolicyModelImpl instance) =>
    <String, dynamic>{
      'privacy_en': instance.privacyEn.toJson(),
      'terms_en': instance.termsEn.toJson(),
      'privacy_ko': instance.privacyKo.toJson(),
      'terms_ko': instance.termsKo.toJson(),
    };

_$PrivacyModelImpl _$$PrivacyModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$PrivacyModelImpl',
      json,
      ($checkedConvert) {
        final val = _$PrivacyModelImpl(
          content: $checkedConvert('content', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$PrivacyModelImplToJson(_$PrivacyModelImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'version': instance.version,
    };

_$TermsModelImpl _$$TermsModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$TermsModelImpl',
      json,
      ($checkedConvert) {
        final val = _$TermsModelImpl(
          content: $checkedConvert('content', (v) => v as String),
          version: $checkedConvert('version', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$TermsModelImplToJson(_$TermsModelImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'version': instance.version,
    };
