// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PolicyModel _$PolicyModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PolicyModel',
  json,
  ($checkedConvert) {
    final val = _PolicyModel(
      privacyEn: $checkedConvert(
        'privacy_en',
        (v) => PrivacyModel.fromJson(v as Map<String, dynamic>),
      ),
      termsEn: $checkedConvert(
        'terms_en',
        (v) => TermsModel.fromJson(v as Map<String, dynamic>),
      ),
      privacyKo: $checkedConvert(
        'privacy_ko',
        (v) => PrivacyModel.fromJson(v as Map<String, dynamic>),
      ),
      termsKo: $checkedConvert(
        'terms_ko',
        (v) => TermsModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'privacyEn': 'privacy_en',
    'termsEn': 'terms_en',
    'privacyKo': 'privacy_ko',
    'termsKo': 'terms_ko',
  },
);

Map<String, dynamic> _$PolicyModelToJson(_PolicyModel instance) =>
    <String, dynamic>{
      'privacy_en': instance.privacyEn.toJson(),
      'terms_en': instance.termsEn.toJson(),
      'privacy_ko': instance.privacyKo.toJson(),
      'terms_ko': instance.termsKo.toJson(),
    };

_PrivacyModel _$PrivacyModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PrivacyModel', json, ($checkedConvert) {
      final val = _PrivacyModel(
        content: $checkedConvert('content', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PrivacyModelToJson(_PrivacyModel instance) =>
    <String, dynamic>{'content': instance.content, 'version': instance.version};

_TermsModel _$TermsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TermsModel', json, ($checkedConvert) {
      final val = _TermsModel(
        content: $checkedConvert('content', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TermsModelToJson(_TermsModel instance) =>
    <String, dynamic>{'content': instance.content, 'version': instance.version};
