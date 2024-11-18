// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/community/compatibility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompatibilityHistoryModelImpl _$$CompatibilityHistoryModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$CompatibilityHistoryModelImpl',
      json,
      ($checkedConvert) {
        final val = _$CompatibilityHistoryModelImpl(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      CompatibilityModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          hasMore: $checkedConvert('has_more', (v) => v as bool),
          isLoading: $checkedConvert('is_loading', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {'hasMore': 'has_more', 'isLoading': 'is_loading'},
    );

Map<String, dynamic> _$$CompatibilityHistoryModelImplToJson(
        _$CompatibilityHistoryModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'has_more': instance.hasMore,
      'is_loading': instance.isLoading,
    };

_$CompatibilityModelImpl _$$CompatibilityModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$CompatibilityModelImpl',
      json,
      ($checkedConvert) {
        final val = _$CompatibilityModelImpl(
          id: $checkedConvert('id', (v) => v as String? ?? ''),
          userId: $checkedConvert('user_id', (v) => v as String),
          artist: $checkedConvert(
              'artist', (v) => ArtistModel.fromJson(v as Map<String, dynamic>)),
          birthDate:
              $checkedConvert('birth_date', (v) => DateTime.parse(v as String)),
          birthTime: $checkedConvert('birth_time', (v) => v as String?),
          status: $checkedConvert(
              'status',
              (v) =>
                  $enumDecodeNullable(_$CompatibilityStatusEnumMap, v) ??
                  CompatibilityStatus.pending),
          gender: $checkedConvert('gender', (v) => v as String?),
          errorMessage: $checkedConvert('error_message', (v) => v as String?),
          isLoading: $checkedConvert('is_loading', (v) => v as bool?),
          compatibilityScore: $checkedConvert(
              'compatibility_score', (v) => (v as num?)?.toInt()),
          compatibilitySummary:
              $checkedConvert('compatibility_summary', (v) => v as String?),
          style: $checkedConvert(
              'style',
              (v) => v == null
                  ? null
                  : StyleDetails.fromJson(v as Map<String, dynamic>)),
          activities: $checkedConvert(
              'activities',
              (v) => v == null
                  ? null
                  : ActivitiesDetails.fromJson(v as Map<String, dynamic>)),
          tips: $checkedConvert('tips',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          completedAt: $checkedConvert('completed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'birthDate': 'birth_date',
        'birthTime': 'birth_time',
        'errorMessage': 'error_message',
        'isLoading': 'is_loading',
        'compatibilityScore': 'compatibility_score',
        'compatibilitySummary': 'compatibility_summary',
        'createdAt': 'created_at',
        'completedAt': 'completed_at'
      },
    );

Map<String, dynamic> _$$CompatibilityModelImplToJson(
        _$CompatibilityModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'artist': instance.artist.toJson(),
      'birth_date': instance.birthDate.toIso8601String(),
      'birth_time': instance.birthTime,
      'status': _$CompatibilityStatusEnumMap[instance.status]!,
      'gender': instance.gender,
      'error_message': instance.errorMessage,
      'is_loading': instance.isLoading,
      'compatibility_score': instance.compatibilityScore,
      'compatibility_summary': instance.compatibilitySummary,
      'style': instance.style?.toJson(),
      'activities': instance.activities?.toJson(),
      'tips': instance.tips,
      'created_at': instance.createdAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };

const _$CompatibilityStatusEnumMap = {
  CompatibilityStatus.pending: 'pending',
  CompatibilityStatus.completed: 'completed',
  CompatibilityStatus.error: 'error',
};

_$StyleDetailsImpl _$$StyleDetailsImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$StyleDetailsImpl',
      json,
      ($checkedConvert) {
        final val = _$StyleDetailsImpl(
          idol_style: $checkedConvert('idol_style', (v) => v as String),
          user_style: $checkedConvert('user_style', (v) => v as String),
          couple_style: $checkedConvert('couple_style', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$$StyleDetailsImplToJson(_$StyleDetailsImpl instance) =>
    <String, dynamic>{
      'idol_style': instance.idol_style,
      'user_style': instance.user_style,
      'couple_style': instance.couple_style,
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
