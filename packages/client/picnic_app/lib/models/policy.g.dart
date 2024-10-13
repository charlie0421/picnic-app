// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PolicyModelImpl _$$PolicyModelImplFromJson(Map<String, dynamic> json) =>
    _$PolicyModelImpl(
      privacyEn:
          PrivacyModel.fromJson(json['privacy_en'] as Map<String, dynamic>),
      termsEn: TermsModel.fromJson(json['terms_en'] as Map<String, dynamic>),
      privacyKo:
          PrivacyModel.fromJson(json['privacy_ko'] as Map<String, dynamic>),
      termsKo: TermsModel.fromJson(json['terms_ko'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PolicyModelImplToJson(_$PolicyModelImpl instance) =>
    <String, dynamic>{
      'privacy_en': instance.privacyEn,
      'terms_en': instance.termsEn,
      'privacy_ko': instance.privacyKo,
      'terms_ko': instance.termsKo,
    };

_$PrivacyModelImpl _$$PrivacyModelImplFromJson(Map<String, dynamic> json) =>
    _$PrivacyModelImpl(
      content: json['content'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$$PrivacyModelImplToJson(_$PrivacyModelImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'version': instance.version,
    };

_$TermsModelImpl _$$TermsModelImplFromJson(Map<String, dynamic> json) =>
    _$TermsModelImpl(
      content: json['content'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$$TermsModelImplToJson(_$TermsModelImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'version': instance.version,
    };
