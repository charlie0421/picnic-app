// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/community/goonghap_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoonghapResult _$GoonghapResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_GoonghapResult',
  json,
  ($checkedConvert) {
    final val = _GoonghapResult(
      id: $checkedConvert('id', (v) => v as String),
      userId: $checkedConvert('user_id', (v) => v as String),
      idolName: $checkedConvert('idol_name', (v) => v as String),
      userBirthDate: $checkedConvert(
        'user_birth_date',
        (v) => DateTime.parse(v as String),
      ),
      idolBirthDate: $checkedConvert(
        'idol_birth_date',
        (v) => DateTime.parse(v as String),
      ),
      userGender: $checkedConvert('user_gender', (v) => v as String),
      birthTime: $checkedConvert('birth_time', (v) => v as String?),
      goonghapScore: $checkedConvert(
        'goonghap_score',
        (v) => (v as num).toInt(),
      ),
      goonghapSummary: $checkedConvert('goonghap_summary', (v) => v as String?),
      details: $checkedConvert('details', (v) => v as Map<String, dynamic>?),
      tips: $checkedConvert(
        'tips',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
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
    'goonghapScore': 'goonghap_score',
    'goonghapSummary': 'goonghap_summary',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$GoonghapResultToJson(_GoonghapResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'idol_name': instance.idolName,
      'user_birth_date': instance.userBirthDate.toIso8601String(),
      'idol_birth_date': instance.idolBirthDate.toIso8601String(),
      'user_gender': instance.userGender,
      'birth_time': instance.birthTime,
      'goonghap_score': instance.goonghapScore,
      'goonghap_summary': instance.goonghapSummary,
      'details': instance.details,
      'tips': instance.tips,
      'created_at': instance.createdAt.toIso8601String(),
    };

_StyleDetails _$StyleDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_StyleDetails',
      json,
      ($checkedConvert) {
        final val = _StyleDetails(
          idolStyle: $checkedConvert('idol_style', (v) => v as String?),
          userStyle: $checkedConvert('user_style', (v) => v as String?),
          coupleStyle: $checkedConvert('couple_style', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'idolStyle': 'idol_style',
        'userStyle': 'user_style',
        'coupleStyle': 'couple_style',
      },
    );

Map<String, dynamic> _$StyleDetailsToJson(_StyleDetails instance) =>
    <String, dynamic>{
      'idol_style': instance.idolStyle,
      'user_style': instance.userStyle,
      'couple_style': instance.coupleStyle,
    };

_ActivitiesDetails _$ActivitiesDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ActivitiesDetails', json, ($checkedConvert) {
      final val = _ActivitiesDetails(
        recommended: $checkedConvert(
          'recommended',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        description: $checkedConvert('description', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ActivitiesDetailsToJson(_ActivitiesDetails instance) =>
    <String, dynamic>{
      'recommended': instance.recommended,
      'description': instance.description,
    };
