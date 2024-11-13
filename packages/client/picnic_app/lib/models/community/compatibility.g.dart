// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compatibility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompatibilityHistoryModelImpl _$$CompatibilityHistoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CompatibilityHistoryModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => CompatibilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool,
      isLoading: json['isLoading'] as bool? ?? false,
    );

Map<String, dynamic> _$$CompatibilityHistoryModelImplToJson(
        _$CompatibilityHistoryModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'hasMore': instance.hasMore,
      'isLoading': instance.isLoading,
    };

_$CompatibilityModelImpl _$$CompatibilityModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CompatibilityModelImpl(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String,
      artist: ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
      birthDate: DateTime.parse(json['birthDate'] as String),
      birthTime: json['birthTime'] as String?,
      status:
          $enumDecodeNullable(_$CompatibilityStatusEnumMap, json['status']) ??
              CompatibilityStatus.pending,
      gender: json['gender'] as String?,
      errorMessage: json['errorMessage'] as String?,
      isLoading: json['isLoading'] as bool?,
      compatibilityScore: (json['compatibilityScore'] as num?)?.toInt(),
      compatibilitySummary: json['compatibilitySummary'] as String?,
      style: json['style'] == null
          ? null
          : StyleDetails.fromJson(json['style'] as Map<String, dynamic>),
      activities: json['activities'] == null
          ? null
          : ActivitiesDetails.fromJson(
              json['activities'] as Map<String, dynamic>),
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$$CompatibilityModelImplToJson(
        _$CompatibilityModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'artist': instance.artist,
      'birthDate': instance.birthDate.toIso8601String(),
      'birthTime': instance.birthTime,
      'status': _$CompatibilityStatusEnumMap[instance.status]!,
      'gender': instance.gender,
      'errorMessage': instance.errorMessage,
      'isLoading': instance.isLoading,
      'compatibilityScore': instance.compatibilityScore,
      'compatibilitySummary': instance.compatibilitySummary,
      'style': instance.style,
      'activities': instance.activities,
      'tips': instance.tips,
      'createdAt': instance.createdAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$CompatibilityStatusEnumMap = {
  CompatibilityStatus.pending: 'pending',
  CompatibilityStatus.completed: 'completed',
  CompatibilityStatus.error: 'error',
};

_$StyleDetailsImpl _$$StyleDetailsImplFromJson(Map<String, dynamic> json) =>
    _$StyleDetailsImpl(
      idol_style: json['idol_style'] as String,
      user_style: json['user_style'] as String,
      couple_style: json['couple_style'] as String,
    );

Map<String, dynamic> _$$StyleDetailsImplToJson(_$StyleDetailsImpl instance) =>
    <String, dynamic>{
      'idol_style': instance.idol_style,
      'user_style': instance.user_style,
      'couple_style': instance.couple_style,
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
