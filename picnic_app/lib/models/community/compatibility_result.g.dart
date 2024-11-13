// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compatibility_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompatibilityResultImpl _$$CompatibilityResultImplFromJson(
        Map<String, dynamic> json) =>
    _$CompatibilityResultImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      idolName: json['idolName'] as String,
      userBirthDate: DateTime.parse(json['userBirthDate'] as String),
      idolBirthDate: DateTime.parse(json['idolBirthDate'] as String),
      userGender: json['userGender'] as String,
      birthTime: json['birthTime'] as String?,
      compatibilityScore: (json['compatibilityScore'] as num).toInt(),
      compatibilitySummary: json['compatibilitySummary'] as String,
      details: json['details'] as Map<String, dynamic>,
      tips: (json['tips'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CompatibilityResultImplToJson(
        _$CompatibilityResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'idolName': instance.idolName,
      'userBirthDate': instance.userBirthDate.toIso8601String(),
      'idolBirthDate': instance.idolBirthDate.toIso8601String(),
      'userGender': instance.userGender,
      'birthTime': instance.birthTime,
      'compatibilityScore': instance.compatibilityScore,
      'compatibilitySummary': instance.compatibilitySummary,
      'details': instance.details,
      'tips': instance.tips,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$StyleDetailsImpl _$$StyleDetailsImplFromJson(Map<String, dynamic> json) =>
    _$StyleDetailsImpl(
      idolStyle: json['idolStyle'] as String,
      userStyle: json['userStyle'] as String,
      coupleStyle: json['coupleStyle'] as String,
    );

Map<String, dynamic> _$$StyleDetailsImplToJson(_$StyleDetailsImpl instance) =>
    <String, dynamic>{
      'idolStyle': instance.idolStyle,
      'userStyle': instance.userStyle,
      'coupleStyle': instance.coupleStyle,
    };

_$ActivitiesDetailsImpl _$$ActivitiesDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$ActivitiesDetailsImpl(
      recommended: (json['recommended'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$ActivitiesDetailsImplToJson(
        _$ActivitiesDetailsImpl instance) =>
    <String, dynamic>{
      'recommended': instance.recommended,
      'description': instance.description,
    };
