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
          birthDate: $checkedConvert(
              'user_birth_date', (v) => DateTime.parse(v as String)),
          birthTime: $checkedConvert('user_birth_time', (v) => v as String?),
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
          details: $checkedConvert(
              'details',
              (v) => v == null
                  ? null
                  : Details.fromJson(v as Map<String, dynamic>)),
          tips: $checkedConvert('tips',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          completedAt: $checkedConvert('completed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          localizedResults:
              $checkedConvert('i18n', (v) => _parseI18nResults(v)),
        );
        return val;
      },
      fieldKeyMap: const {
        'userId': 'user_id',
        'birthDate': 'user_birth_date',
        'birthTime': 'user_birth_time',
        'errorMessage': 'error_message',
        'isLoading': 'is_loading',
        'compatibilityScore': 'compatibility_score',
        'compatibilitySummary': 'compatibility_summary',
        'createdAt': 'created_at',
        'completedAt': 'completed_at',
        'localizedResults': 'i18n'
      },
    );

Map<String, dynamic> _$$CompatibilityModelImplToJson(
        _$CompatibilityModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'artist': instance.artist.toJson(),
      'user_birth_date': instance.birthDate.toIso8601String(),
      'user_birth_time': instance.birthTime,
      'status': _$CompatibilityStatusEnumMap[instance.status]!,
      'gender': instance.gender,
      'error_message': instance.errorMessage,
      'is_loading': instance.isLoading,
      'compatibility_score': instance.compatibilityScore,
      'compatibility_summary': instance.compatibilitySummary,
      'details': instance.details?.toJson(),
      'tips': instance.tips,
      'created_at': instance.createdAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'i18n': instance.localizedResults?.map((k, e) => MapEntry(k, e.toJson())),
    };

const _$CompatibilityStatusEnumMap = {
  CompatibilityStatus.pending: 'pending',
  CompatibilityStatus.completed: 'completed',
  CompatibilityStatus.error: 'error',
};

_$LocalizedCompatibilityImpl _$$LocalizedCompatibilityImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$LocalizedCompatibilityImpl',
      json,
      ($checkedConvert) {
        final val = _$LocalizedCompatibilityImpl(
          language: $checkedConvert('language', (v) => v as String),
          compatibilityScore:
              $checkedConvert('compatibility_score', (v) => (v as num).toInt()),
          compatibilitySummary: $checkedConvert(
              'compatibility_summary', (v) => v as String? ?? ''),
          details: $checkedConvert(
              'details', (v) => Details.fromJson(v as Map<String, dynamic>)),
          tips: $checkedConvert(
              'tips',
              (v) =>
                  (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                  const []),
        );
        return val;
      },
      fieldKeyMap: const {
        'compatibilityScore': 'compatibility_score',
        'compatibilitySummary': 'compatibility_summary'
      },
    );

Map<String, dynamic> _$$LocalizedCompatibilityImplToJson(
        _$LocalizedCompatibilityImpl instance) =>
    <String, dynamic>{
      'language': instance.language,
      'compatibility_score': instance.compatibilityScore,
      'compatibility_summary': instance.compatibilitySummary,
      'details': instance.details.toJson(),
      'tips': instance.tips,
    };

_$DetailsImpl _$$DetailsImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$DetailsImpl',
      json,
      ($checkedConvert) {
        final val = _$DetailsImpl(
          style: $checkedConvert(
              'style', (v) => StyleDetails.fromJson(v as Map<String, dynamic>)),
          activities: $checkedConvert('activities',
              (v) => ActivitiesDetails.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$DetailsImplToJson(_$DetailsImpl instance) =>
    <String, dynamic>{
      'style': instance.style.toJson(),
      'activities': instance.activities.toJson(),
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
