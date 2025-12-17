// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/community/goonghap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoonghapHistoryModel _$GoonghapHistoryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_GoonghapHistoryModel',
  json,
  ($checkedConvert) {
    final val = _GoonghapHistoryModel(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map((e) => GoonghapModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      hasMore: $checkedConvert('has_more', (v) => v as bool),
      isLoading: $checkedConvert('is_loading', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {'hasMore': 'has_more', 'isLoading': 'is_loading'},
);

Map<String, dynamic> _$GoonghapHistoryModelToJson(
  _GoonghapHistoryModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'has_more': instance.hasMore,
  'is_loading': instance.isLoading,
};

_GoonghapModel _$GoonghapModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_GoonghapModel',
  json,
  ($checkedConvert) {
    final val = _GoonghapModel(
      id: $checkedConvert('id', (v) => v as String? ?? ''),
      userId: $checkedConvert('user_id', (v) => v as String),
      artist: $checkedConvert(
        'artist',
        (v) => ArtistModel.fromJson(v as Map<String, dynamic>),
      ),
      birthDate: $checkedConvert(
        'user_birth_date',
        (v) => DateTime.parse(v as String),
      ),
      birthTime: $checkedConvert('user_birth_time', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$GoonghapStatusEnumMap, v) ??
            GoonghapStatus.pending,
      ),
      gender: $checkedConvert('gender', (v) => v as String?),
      errorMessage: $checkedConvert('error_message', (v) => v as String?),
      isLoading: $checkedConvert('is_loading', (v) => v as bool?),
      score: $checkedConvert('score', (v) => (v as num?)?.toInt()),
      goonghapSummary: $checkedConvert('goonghap_summary', (v) => v as String?),
      details: $checkedConvert(
        'details',
        (v) => v == null ? null : Details.fromJson(v as Map<String, dynamic>),
      ),
      tips: $checkedConvert(
        'tips',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      completedAt: $checkedConvert(
        'completed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      localizedResults: $checkedConvert('i18n', (v) => _parseI18nResults(v)),
      isAds: $checkedConvert('is_ads', (v) => v as bool?),
      isPaid: $checkedConvert('is_paid', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'birthDate': 'user_birth_date',
    'birthTime': 'user_birth_time',
    'errorMessage': 'error_message',
    'isLoading': 'is_loading',
    'goonghapSummary': 'goonghap_summary',
    'createdAt': 'created_at',
    'completedAt': 'completed_at',
    'localizedResults': 'i18n',
    'isAds': 'is_ads',
    'isPaid': 'is_paid',
  },
);

Map<String, dynamic> _$GoonghapModelToJson(_GoonghapModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'artist': instance.artist.toJson(),
      'user_birth_date': instance.birthDate.toIso8601String(),
      'user_birth_time': instance.birthTime,
      'status': _$GoonghapStatusEnumMap[instance.status]!,
      'gender': instance.gender,
      'error_message': instance.errorMessage,
      'is_loading': instance.isLoading,
      'score': instance.score,
      'goonghap_summary': instance.goonghapSummary,
      'details': instance.details?.toJson(),
      'tips': instance.tips,
      'created_at': instance.createdAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'i18n': instance.localizedResults?.map((k, e) => MapEntry(k, e.toJson())),
      'is_ads': instance.isAds,
      'is_paid': instance.isPaid,
    };

const _$GoonghapStatusEnumMap = {
  GoonghapStatus.pending: 'pending',
  GoonghapStatus.completed: 'completed',
  GoonghapStatus.error: 'error',
  GoonghapStatus.input: 'input',
};

_LocalizedGoonghap _$LocalizedGoonghapFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_LocalizedGoonghap',
      json,
      ($checkedConvert) {
        final val = _LocalizedGoonghap(
          language: $checkedConvert('language', (v) => v as String),
          score: $checkedConvert('score', (v) => (v as num?)?.toInt() ?? 0),
          scoreTitle: $checkedConvert('score_title', (v) => v as String? ?? ''),
          goonghapSummary: $checkedConvert(
            'goonghap_summary',
            (v) => v as String? ?? '',
          ),
          details: $checkedConvert(
            'details',
            (v) =>
                v == null ? null : Details.fromJson(v as Map<String, dynamic>),
          ),
          tips: $checkedConvert(
            'tips',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'scoreTitle': 'score_title',
        'goonghapSummary': 'goonghap_summary',
      },
    );

Map<String, dynamic> _$LocalizedGoonghapToJson(_LocalizedGoonghap instance) =>
    <String, dynamic>{
      'language': instance.language,
      'score': instance.score,
      'score_title': instance.scoreTitle,
      'goonghap_summary': instance.goonghapSummary,
      'details': instance.details?.toJson(),
      'tips': instance.tips,
    };

_Details _$DetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Details', json, ($checkedConvert) {
      final val = _Details(
        style: $checkedConvert(
          'style',
          (v) => StyleDetails.fromJson(v as Map<String, dynamic>),
        ),
        activities: $checkedConvert(
          'activities',
          (v) => ActivitiesDetails.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DetailsToJson(_Details instance) => <String, dynamic>{
  'style': instance.style.toJson(),
  'activities': instance.activities.toJson(),
};

_StyleDetails _$StyleDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_StyleDetails',
      json,
      ($checkedConvert) {
        final val = _StyleDetails(
          idolStyle: $checkedConvert('idol_style', (v) => v as String),
          userStyle: $checkedConvert('user_style', (v) => v as String),
          coupleStyle: $checkedConvert('couple_style', (v) => v as String),
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
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        description: $checkedConvert('description', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ActivitiesDetailsToJson(_ActivitiesDetails instance) =>
    <String, dynamic>{
      'recommended': instance.recommended,
      'description': instance.description,
    };
