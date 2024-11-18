// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/community/compatibility_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompatibilityResultImpl _$$CompatibilityResultImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$CompatibilityResultImpl',
      json,
      ($checkedConvert) {
        final val = _$CompatibilityResultImpl(
          id: $checkedConvert('id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String),
          idolName: $checkedConvert('idol_name', (v) => v as String),
          userBirthDate: $checkedConvert(
              'user_birth_date', (v) => DateTime.parse(v as String)),
          idolBirthDate: $checkedConvert(
              'idol_birth_date', (v) => DateTime.parse(v as String)),
          userGender: $checkedConvert('user_gender', (v) => v as String),
          birthTime: $checkedConvert('birth_time', (v) => v as String?),
          compatibilityScore:
              $checkedConvert('compatibility_score', (v) => (v as num).toInt()),
          compatibilitySummary:
              $checkedConvert('compatibility_summary', (v) => v as String),
          details: $checkedConvert('details', (v) => v as Map<String, dynamic>),
          tips: $checkedConvert('tips',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'idolName': 'idol_name',
        'userBirthDate': 'user_birth_date',
        'idolBirthDate': 'idol_birth_date',
        'userGender': 'user_gender',
        'birthTime': 'birth_time',
        'compatibilityScore': 'compatibility_score',
        'compatibilitySummary': 'compatibility_summary',
        'createdAt': 'created_at'
      },
    );

Map<String, dynamic> _$$CompatibilityResultImplToJson(
        _$CompatibilityResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'idol_name': instance.idolName,
      'user_birth_date': instance.userBirthDate.toIso8601String(),
      'idol_birth_date': instance.idolBirthDate.toIso8601String(),
      'user_gender': instance.userGender,
      'birth_time': instance.birthTime,
      'compatibility_score': instance.compatibilityScore,
      'compatibility_summary': instance.compatibilitySummary,
      'details': instance.details,
      'tips': instance.tips,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$StyleDetailsImpl _$$StyleDetailsImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$StyleDetailsImpl',
      json,
      ($checkedConvert) {
        final val = _$StyleDetailsImpl(
          idolStyle: $checkedConvert('idol_style', (v) => v as String),
          userStyle: $checkedConvert('user_style', (v) => v as String),
          coupleStyle: $checkedConvert('couple_style', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'idolStyle': 'idol_style',
        'userStyle': 'user_style',
        'coupleStyle': 'couple_style'
      },
    );

Map<String, dynamic> _$$StyleDetailsImplToJson(_$StyleDetailsImpl instance) =>
    <String, dynamic>{
      'idol_style': instance.idolStyle,
      'user_style': instance.userStyle,
      'couple_style': instance.coupleStyle,
    };

_$ActivitiesDetailsImpl _$$ActivitiesDetailsImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ActivitiesDetailsImpl',
      json,
      ($checkedConvert) {
        final val = _$ActivitiesDetailsImpl(
          recommended: $checkedConvert('recommended',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          description: $checkedConvert('description', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ActivitiesDetailsImplToJson(
        _$ActivitiesDetailsImpl instance) =>
    <String, dynamic>{
      'recommended': instance.recommended,
      'description': instance.description,
    };
