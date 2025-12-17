// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/community/fortune.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FortuneModel _$FortuneModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_FortuneModel',
      json,
      ($checkedConvert) {
        final val = _FortuneModel(
          id: $checkedConvert('id', (v) => v as String),
          year: $checkedConvert('year', (v) => (v as num).toInt()),
          artistId: $checkedConvert('artist_id', (v) => (v as num).toInt()),
          artist: $checkedConvert(
            'artist',
            (v) => ArtistModel.fromJson(v as Map<String, dynamic>),
          ),
          overallLuck: $checkedConvert('overall_luck', (v) => v as String),
          monthlyFortunes: $checkedConvert(
            'monthly_fortunes',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      MonthlyFortuneModel.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          aspects: $checkedConvert(
            'aspects',
            (v) => AspectModel.fromJson(v as Map<String, dynamic>),
          ),
          lucky: $checkedConvert(
            'lucky',
            (v) => LuckyModel.fromJson(v as Map<String, dynamic>),
          ),
          advice: $checkedConvert(
            'advice',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'artistId': 'artist_id',
        'overallLuck': 'overall_luck',
        'monthlyFortunes': 'monthly_fortunes',
      },
    );

Map<String, dynamic> _$FortuneModelToJson(
  _FortuneModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'artist_id': instance.artistId,
  'artist': instance.artist.toJson(),
  'overall_luck': instance.overallLuck,
  'monthly_fortunes': instance.monthlyFortunes.map((e) => e.toJson()).toList(),
  'aspects': instance.aspects.toJson(),
  'lucky': instance.lucky.toJson(),
  'advice': instance.advice,
};

_MonthlyFortuneModel _$MonthlyFortuneModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MonthlyFortuneModel', json, ($checkedConvert) {
      final val = _MonthlyFortuneModel(
        month: $checkedConvert('month', (v) => (v as num).toInt()),
        honor: $checkedConvert('honor', (v) => v as String),
        career: $checkedConvert('career', (v) => v as String),
        health: $checkedConvert('health', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MonthlyFortuneModelToJson(
  _MonthlyFortuneModel instance,
) => <String, dynamic>{
  'month': instance.month,
  'honor': instance.honor,
  'career': instance.career,
  'health': instance.health,
  'summary': instance.summary,
};

_AspectModel _$AspectModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AspectModel', json, ($checkedConvert) {
      final val = _AspectModel(
        honor: $checkedConvert('honor', (v) => v as String),
        career: $checkedConvert('career', (v) => v as String),
        health: $checkedConvert('health', (v) => v as String),
        finances: $checkedConvert('finances', (v) => v as String),
        relationships: $checkedConvert('relationships', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AspectModelToJson(_AspectModel instance) =>
    <String, dynamic>{
      'honor': instance.honor,
      'career': instance.career,
      'health': instance.health,
      'finances': instance.finances,
      'relationships': instance.relationships,
    };

_LuckyModel _$LuckyModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LuckyModel', json, ($checkedConvert) {
      final val = _LuckyModel(
        days: $checkedConvert(
          'days',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        colors: $checkedConvert(
          'colors',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        numbers: $checkedConvert(
          'numbers',
          (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
        directions: $checkedConvert(
          'directions',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LuckyModelToJson(_LuckyModel instance) =>
    <String, dynamic>{
      'days': instance.days,
      'colors': instance.colors,
      'numbers': instance.numbers,
      'directions': instance.directions,
    };
