// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/community/fortune.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FortuneModel _$FortuneModelFromJson(Map<String, dynamic> json) {
  return _FortuneModel.fromJson(json);
}

/// @nodoc
mixin _$FortuneModel {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'year')
  int get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_id')
  int get artistId => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist')
  ArtistModel get artist => throw _privateConstructorUsedError;
  @JsonKey(name: 'overall_luck')
  String get overallLuck => throw _privateConstructorUsedError;
  @JsonKey(name: 'monthly_fortunes')
  List<MonthlyFortuneModel> get monthlyFortunes =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'aspects')
  AspectModel get aspects => throw _privateConstructorUsedError;
  @JsonKey(name: 'lucky')
  LuckyModel get lucky => throw _privateConstructorUsedError;
  @JsonKey(name: 'advice')
  List<String> get advice => throw _privateConstructorUsedError;

  /// Serializes this FortuneModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FortuneModelCopyWith<FortuneModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FortuneModelCopyWith<$Res> {
  factory $FortuneModelCopyWith(
          FortuneModel value, $Res Function(FortuneModel) then) =
      _$FortuneModelCopyWithImpl<$Res, FortuneModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'year') int year,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'artist') ArtistModel artist,
      @JsonKey(name: 'overall_luck') String overallLuck,
      @JsonKey(name: 'monthly_fortunes')
      List<MonthlyFortuneModel> monthlyFortunes,
      @JsonKey(name: 'aspects') AspectModel aspects,
      @JsonKey(name: 'lucky') LuckyModel lucky,
      @JsonKey(name: 'advice') List<String> advice});

  $ArtistModelCopyWith<$Res> get artist;
  $AspectModelCopyWith<$Res> get aspects;
  $LuckyModelCopyWith<$Res> get lucky;
}

/// @nodoc
class _$FortuneModelCopyWithImpl<$Res, $Val extends FortuneModel>
    implements $FortuneModelCopyWith<$Res> {
  _$FortuneModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? year = null,
    Object? artistId = null,
    Object? artist = null,
    Object? overallLuck = null,
    Object? monthlyFortunes = null,
    Object? aspects = null,
    Object? lucky = null,
    Object? advice = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      overallLuck: null == overallLuck
          ? _value.overallLuck
          : overallLuck // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyFortunes: null == monthlyFortunes
          ? _value.monthlyFortunes
          : monthlyFortunes // ignore: cast_nullable_to_non_nullable
              as List<MonthlyFortuneModel>,
      aspects: null == aspects
          ? _value.aspects
          : aspects // ignore: cast_nullable_to_non_nullable
              as AspectModel,
      lucky: null == lucky
          ? _value.lucky
          : lucky // ignore: cast_nullable_to_non_nullable
              as LuckyModel,
      advice: null == advice
          ? _value.advice
          : advice // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res> get artist {
    return $ArtistModelCopyWith<$Res>(_value.artist, (value) {
      return _then(_value.copyWith(artist: value) as $Val);
    });
  }

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AspectModelCopyWith<$Res> get aspects {
    return $AspectModelCopyWith<$Res>(_value.aspects, (value) {
      return _then(_value.copyWith(aspects: value) as $Val);
    });
  }

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LuckyModelCopyWith<$Res> get lucky {
    return $LuckyModelCopyWith<$Res>(_value.lucky, (value) {
      return _then(_value.copyWith(lucky: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FortuneModelImplCopyWith<$Res>
    implements $FortuneModelCopyWith<$Res> {
  factory _$$FortuneModelImplCopyWith(
          _$FortuneModelImpl value, $Res Function(_$FortuneModelImpl) then) =
      __$$FortuneModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'year') int year,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'artist') ArtistModel artist,
      @JsonKey(name: 'overall_luck') String overallLuck,
      @JsonKey(name: 'monthly_fortunes')
      List<MonthlyFortuneModel> monthlyFortunes,
      @JsonKey(name: 'aspects') AspectModel aspects,
      @JsonKey(name: 'lucky') LuckyModel lucky,
      @JsonKey(name: 'advice') List<String> advice});

  @override
  $ArtistModelCopyWith<$Res> get artist;
  @override
  $AspectModelCopyWith<$Res> get aspects;
  @override
  $LuckyModelCopyWith<$Res> get lucky;
}

/// @nodoc
class __$$FortuneModelImplCopyWithImpl<$Res>
    extends _$FortuneModelCopyWithImpl<$Res, _$FortuneModelImpl>
    implements _$$FortuneModelImplCopyWith<$Res> {
  __$$FortuneModelImplCopyWithImpl(
      _$FortuneModelImpl _value, $Res Function(_$FortuneModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? year = null,
    Object? artistId = null,
    Object? artist = null,
    Object? overallLuck = null,
    Object? monthlyFortunes = null,
    Object? aspects = null,
    Object? lucky = null,
    Object? advice = null,
  }) {
    return _then(_$FortuneModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      overallLuck: null == overallLuck
          ? _value.overallLuck
          : overallLuck // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyFortunes: null == monthlyFortunes
          ? _value._monthlyFortunes
          : monthlyFortunes // ignore: cast_nullable_to_non_nullable
              as List<MonthlyFortuneModel>,
      aspects: null == aspects
          ? _value.aspects
          : aspects // ignore: cast_nullable_to_non_nullable
              as AspectModel,
      lucky: null == lucky
          ? _value.lucky
          : lucky // ignore: cast_nullable_to_non_nullable
              as LuckyModel,
      advice: null == advice
          ? _value._advice
          : advice // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FortuneModelImpl implements _FortuneModel {
  const _$FortuneModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'year') required this.year,
      @JsonKey(name: 'artist_id') required this.artistId,
      @JsonKey(name: 'artist') required this.artist,
      @JsonKey(name: 'overall_luck') required this.overallLuck,
      @JsonKey(name: 'monthly_fortunes')
      required final List<MonthlyFortuneModel> monthlyFortunes,
      @JsonKey(name: 'aspects') required this.aspects,
      @JsonKey(name: 'lucky') required this.lucky,
      @JsonKey(name: 'advice') required final List<String> advice})
      : _monthlyFortunes = monthlyFortunes,
        _advice = advice;

  factory _$FortuneModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FortuneModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'year')
  final int year;
  @override
  @JsonKey(name: 'artist_id')
  final int artistId;
  @override
  @JsonKey(name: 'artist')
  final ArtistModel artist;
  @override
  @JsonKey(name: 'overall_luck')
  final String overallLuck;
  final List<MonthlyFortuneModel> _monthlyFortunes;
  @override
  @JsonKey(name: 'monthly_fortunes')
  List<MonthlyFortuneModel> get monthlyFortunes {
    if (_monthlyFortunes is EqualUnmodifiableListView) return _monthlyFortunes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_monthlyFortunes);
  }

  @override
  @JsonKey(name: 'aspects')
  final AspectModel aspects;
  @override
  @JsonKey(name: 'lucky')
  final LuckyModel lucky;
  final List<String> _advice;
  @override
  @JsonKey(name: 'advice')
  List<String> get advice {
    if (_advice is EqualUnmodifiableListView) return _advice;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_advice);
  }

  @override
  String toString() {
    return 'FortuneModel(id: $id, year: $year, artistId: $artistId, artist: $artist, overallLuck: $overallLuck, monthlyFortunes: $monthlyFortunes, aspects: $aspects, lucky: $lucky, advice: $advice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FortuneModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.overallLuck, overallLuck) ||
                other.overallLuck == overallLuck) &&
            const DeepCollectionEquality()
                .equals(other._monthlyFortunes, _monthlyFortunes) &&
            (identical(other.aspects, aspects) || other.aspects == aspects) &&
            (identical(other.lucky, lucky) || other.lucky == lucky) &&
            const DeepCollectionEquality().equals(other._advice, _advice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      year,
      artistId,
      artist,
      overallLuck,
      const DeepCollectionEquality().hash(_monthlyFortunes),
      aspects,
      lucky,
      const DeepCollectionEquality().hash(_advice));

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FortuneModelImplCopyWith<_$FortuneModelImpl> get copyWith =>
      __$$FortuneModelImplCopyWithImpl<_$FortuneModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FortuneModelImplToJson(
      this,
    );
  }
}

abstract class _FortuneModel implements FortuneModel {
  const factory _FortuneModel(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'year') required final int year,
          @JsonKey(name: 'artist_id') required final int artistId,
          @JsonKey(name: 'artist') required final ArtistModel artist,
          @JsonKey(name: 'overall_luck') required final String overallLuck,
          @JsonKey(name: 'monthly_fortunes')
          required final List<MonthlyFortuneModel> monthlyFortunes,
          @JsonKey(name: 'aspects') required final AspectModel aspects,
          @JsonKey(name: 'lucky') required final LuckyModel lucky,
          @JsonKey(name: 'advice') required final List<String> advice}) =
      _$FortuneModelImpl;

  factory _FortuneModel.fromJson(Map<String, dynamic> json) =
      _$FortuneModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'year')
  int get year;
  @override
  @JsonKey(name: 'artist_id')
  int get artistId;
  @override
  @JsonKey(name: 'artist')
  ArtistModel get artist;
  @override
  @JsonKey(name: 'overall_luck')
  String get overallLuck;
  @override
  @JsonKey(name: 'monthly_fortunes')
  List<MonthlyFortuneModel> get monthlyFortunes;
  @override
  @JsonKey(name: 'aspects')
  AspectModel get aspects;
  @override
  @JsonKey(name: 'lucky')
  LuckyModel get lucky;
  @override
  @JsonKey(name: 'advice')
  List<String> get advice;

  /// Create a copy of FortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FortuneModelImplCopyWith<_$FortuneModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonthlyFortuneModel _$MonthlyFortuneModelFromJson(Map<String, dynamic> json) {
  return _MonthlyFortuneModel.fromJson(json);
}

/// @nodoc
mixin _$MonthlyFortuneModel {
  @JsonKey(name: 'month')
  int get month => throw _privateConstructorUsedError;
  @JsonKey(name: 'love')
  String get love => throw _privateConstructorUsedError;
  @JsonKey(name: 'career')
  String get career => throw _privateConstructorUsedError;
  @JsonKey(name: 'health')
  String get health => throw _privateConstructorUsedError;
  @JsonKey(name: 'summary')
  String get summary => throw _privateConstructorUsedError;

  /// Serializes this MonthlyFortuneModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlyFortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlyFortuneModelCopyWith<MonthlyFortuneModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlyFortuneModelCopyWith<$Res> {
  factory $MonthlyFortuneModelCopyWith(
          MonthlyFortuneModel value, $Res Function(MonthlyFortuneModel) then) =
      _$MonthlyFortuneModelCopyWithImpl<$Res, MonthlyFortuneModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'month') int month,
      @JsonKey(name: 'love') String love,
      @JsonKey(name: 'career') String career,
      @JsonKey(name: 'health') String health,
      @JsonKey(name: 'summary') String summary});
}

/// @nodoc
class _$MonthlyFortuneModelCopyWithImpl<$Res, $Val extends MonthlyFortuneModel>
    implements $MonthlyFortuneModelCopyWith<$Res> {
  _$MonthlyFortuneModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlyFortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? love = null,
    Object? career = null,
    Object? health = null,
    Object? summary = null,
  }) {
    return _then(_value.copyWith(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      love: null == love
          ? _value.love
          : love // ignore: cast_nullable_to_non_nullable
              as String,
      career: null == career
          ? _value.career
          : career // ignore: cast_nullable_to_non_nullable
              as String,
      health: null == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MonthlyFortuneModelImplCopyWith<$Res>
    implements $MonthlyFortuneModelCopyWith<$Res> {
  factory _$$MonthlyFortuneModelImplCopyWith(_$MonthlyFortuneModelImpl value,
          $Res Function(_$MonthlyFortuneModelImpl) then) =
      __$$MonthlyFortuneModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'month') int month,
      @JsonKey(name: 'love') String love,
      @JsonKey(name: 'career') String career,
      @JsonKey(name: 'health') String health,
      @JsonKey(name: 'summary') String summary});
}

/// @nodoc
class __$$MonthlyFortuneModelImplCopyWithImpl<$Res>
    extends _$MonthlyFortuneModelCopyWithImpl<$Res, _$MonthlyFortuneModelImpl>
    implements _$$MonthlyFortuneModelImplCopyWith<$Res> {
  __$$MonthlyFortuneModelImplCopyWithImpl(_$MonthlyFortuneModelImpl _value,
      $Res Function(_$MonthlyFortuneModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MonthlyFortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? love = null,
    Object? career = null,
    Object? health = null,
    Object? summary = null,
  }) {
    return _then(_$MonthlyFortuneModelImpl(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      love: null == love
          ? _value.love
          : love // ignore: cast_nullable_to_non_nullable
              as String,
      career: null == career
          ? _value.career
          : career // ignore: cast_nullable_to_non_nullable
              as String,
      health: null == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as String,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlyFortuneModelImpl implements _MonthlyFortuneModel {
  const _$MonthlyFortuneModelImpl(
      {@JsonKey(name: 'month') required this.month,
      @JsonKey(name: 'love') required this.love,
      @JsonKey(name: 'career') required this.career,
      @JsonKey(name: 'health') required this.health,
      @JsonKey(name: 'summary') required this.summary});

  factory _$MonthlyFortuneModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlyFortuneModelImplFromJson(json);

  @override
  @JsonKey(name: 'month')
  final int month;
  @override
  @JsonKey(name: 'love')
  final String love;
  @override
  @JsonKey(name: 'career')
  final String career;
  @override
  @JsonKey(name: 'health')
  final String health;
  @override
  @JsonKey(name: 'summary')
  final String summary;

  @override
  String toString() {
    return 'MonthlyFortuneModel(month: $month, love: $love, career: $career, health: $health, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyFortuneModelImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.love, love) || other.love == love) &&
            (identical(other.career, career) || other.career == career) &&
            (identical(other.health, health) || other.health == health) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, month, love, career, health, summary);

  /// Create a copy of MonthlyFortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyFortuneModelImplCopyWith<_$MonthlyFortuneModelImpl> get copyWith =>
      __$$MonthlyFortuneModelImplCopyWithImpl<_$MonthlyFortuneModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlyFortuneModelImplToJson(
      this,
    );
  }
}

abstract class _MonthlyFortuneModel implements MonthlyFortuneModel {
  const factory _MonthlyFortuneModel(
          {@JsonKey(name: 'month') required final int month,
          @JsonKey(name: 'love') required final String love,
          @JsonKey(name: 'career') required final String career,
          @JsonKey(name: 'health') required final String health,
          @JsonKey(name: 'summary') required final String summary}) =
      _$MonthlyFortuneModelImpl;

  factory _MonthlyFortuneModel.fromJson(Map<String, dynamic> json) =
      _$MonthlyFortuneModelImpl.fromJson;

  @override
  @JsonKey(name: 'month')
  int get month;
  @override
  @JsonKey(name: 'love')
  String get love;
  @override
  @JsonKey(name: 'career')
  String get career;
  @override
  @JsonKey(name: 'health')
  String get health;
  @override
  @JsonKey(name: 'summary')
  String get summary;

  /// Create a copy of MonthlyFortuneModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyFortuneModelImplCopyWith<_$MonthlyFortuneModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AspectModel _$AspectModelFromJson(Map<String, dynamic> json) {
  return _AspectModel.fromJson(json);
}

/// @nodoc
mixin _$AspectModel {
  @JsonKey(name: 'love')
  String get love => throw _privateConstructorUsedError;
  @JsonKey(name: 'career')
  String get career => throw _privateConstructorUsedError;
  @JsonKey(name: 'health')
  String get health => throw _privateConstructorUsedError;
  @JsonKey(name: 'finances')
  String get finances => throw _privateConstructorUsedError;
  @JsonKey(name: 'relationships')
  String get relationships => throw _privateConstructorUsedError;

  /// Serializes this AspectModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AspectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AspectModelCopyWith<AspectModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AspectModelCopyWith<$Res> {
  factory $AspectModelCopyWith(
          AspectModel value, $Res Function(AspectModel) then) =
      _$AspectModelCopyWithImpl<$Res, AspectModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'love') String love,
      @JsonKey(name: 'career') String career,
      @JsonKey(name: 'health') String health,
      @JsonKey(name: 'finances') String finances,
      @JsonKey(name: 'relationships') String relationships});
}

/// @nodoc
class _$AspectModelCopyWithImpl<$Res, $Val extends AspectModel>
    implements $AspectModelCopyWith<$Res> {
  _$AspectModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AspectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? love = null,
    Object? career = null,
    Object? health = null,
    Object? finances = null,
    Object? relationships = null,
  }) {
    return _then(_value.copyWith(
      love: null == love
          ? _value.love
          : love // ignore: cast_nullable_to_non_nullable
              as String,
      career: null == career
          ? _value.career
          : career // ignore: cast_nullable_to_non_nullable
              as String,
      health: null == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as String,
      finances: null == finances
          ? _value.finances
          : finances // ignore: cast_nullable_to_non_nullable
              as String,
      relationships: null == relationships
          ? _value.relationships
          : relationships // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AspectModelImplCopyWith<$Res>
    implements $AspectModelCopyWith<$Res> {
  factory _$$AspectModelImplCopyWith(
          _$AspectModelImpl value, $Res Function(_$AspectModelImpl) then) =
      __$$AspectModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'love') String love,
      @JsonKey(name: 'career') String career,
      @JsonKey(name: 'health') String health,
      @JsonKey(name: 'finances') String finances,
      @JsonKey(name: 'relationships') String relationships});
}

/// @nodoc
class __$$AspectModelImplCopyWithImpl<$Res>
    extends _$AspectModelCopyWithImpl<$Res, _$AspectModelImpl>
    implements _$$AspectModelImplCopyWith<$Res> {
  __$$AspectModelImplCopyWithImpl(
      _$AspectModelImpl _value, $Res Function(_$AspectModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AspectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? love = null,
    Object? career = null,
    Object? health = null,
    Object? finances = null,
    Object? relationships = null,
  }) {
    return _then(_$AspectModelImpl(
      love: null == love
          ? _value.love
          : love // ignore: cast_nullable_to_non_nullable
              as String,
      career: null == career
          ? _value.career
          : career // ignore: cast_nullable_to_non_nullable
              as String,
      health: null == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as String,
      finances: null == finances
          ? _value.finances
          : finances // ignore: cast_nullable_to_non_nullable
              as String,
      relationships: null == relationships
          ? _value.relationships
          : relationships // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AspectModelImpl implements _AspectModel {
  const _$AspectModelImpl(
      {@JsonKey(name: 'love') required this.love,
      @JsonKey(name: 'career') required this.career,
      @JsonKey(name: 'health') required this.health,
      @JsonKey(name: 'finances') required this.finances,
      @JsonKey(name: 'relationships') required this.relationships});

  factory _$AspectModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AspectModelImplFromJson(json);

  @override
  @JsonKey(name: 'love')
  final String love;
  @override
  @JsonKey(name: 'career')
  final String career;
  @override
  @JsonKey(name: 'health')
  final String health;
  @override
  @JsonKey(name: 'finances')
  final String finances;
  @override
  @JsonKey(name: 'relationships')
  final String relationships;

  @override
  String toString() {
    return 'AspectModel(love: $love, career: $career, health: $health, finances: $finances, relationships: $relationships)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AspectModelImpl &&
            (identical(other.love, love) || other.love == love) &&
            (identical(other.career, career) || other.career == career) &&
            (identical(other.health, health) || other.health == health) &&
            (identical(other.finances, finances) ||
                other.finances == finances) &&
            (identical(other.relationships, relationships) ||
                other.relationships == relationships));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, love, career, health, finances, relationships);

  /// Create a copy of AspectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AspectModelImplCopyWith<_$AspectModelImpl> get copyWith =>
      __$$AspectModelImplCopyWithImpl<_$AspectModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AspectModelImplToJson(
      this,
    );
  }
}

abstract class _AspectModel implements AspectModel {
  const factory _AspectModel(
      {@JsonKey(name: 'love') required final String love,
      @JsonKey(name: 'career') required final String career,
      @JsonKey(name: 'health') required final String health,
      @JsonKey(name: 'finances') required final String finances,
      @JsonKey(name: 'relationships')
      required final String relationships}) = _$AspectModelImpl;

  factory _AspectModel.fromJson(Map<String, dynamic> json) =
      _$AspectModelImpl.fromJson;

  @override
  @JsonKey(name: 'love')
  String get love;
  @override
  @JsonKey(name: 'career')
  String get career;
  @override
  @JsonKey(name: 'health')
  String get health;
  @override
  @JsonKey(name: 'finances')
  String get finances;
  @override
  @JsonKey(name: 'relationships')
  String get relationships;

  /// Create a copy of AspectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AspectModelImplCopyWith<_$AspectModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LuckyModel _$LuckyModelFromJson(Map<String, dynamic> json) {
  return _LuckyModel.fromJson(json);
}

/// @nodoc
mixin _$LuckyModel {
  @JsonKey(name: 'days')
  List<String> get days => throw _privateConstructorUsedError;
  @JsonKey(name: 'colors')
  List<String> get colors => throw _privateConstructorUsedError;
  @JsonKey(name: 'numbers')
  List<int> get numbers => throw _privateConstructorUsedError;
  @JsonKey(name: 'directions')
  List<String> get directions => throw _privateConstructorUsedError;

  /// Serializes this LuckyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LuckyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LuckyModelCopyWith<LuckyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LuckyModelCopyWith<$Res> {
  factory $LuckyModelCopyWith(
          LuckyModel value, $Res Function(LuckyModel) then) =
      _$LuckyModelCopyWithImpl<$Res, LuckyModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'days') List<String> days,
      @JsonKey(name: 'colors') List<String> colors,
      @JsonKey(name: 'numbers') List<int> numbers,
      @JsonKey(name: 'directions') List<String> directions});
}

/// @nodoc
class _$LuckyModelCopyWithImpl<$Res, $Val extends LuckyModel>
    implements $LuckyModelCopyWith<$Res> {
  _$LuckyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LuckyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? days = null,
    Object? colors = null,
    Object? numbers = null,
    Object? directions = null,
  }) {
    return _then(_value.copyWith(
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colors: null == colors
          ? _value.colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      numbers: null == numbers
          ? _value.numbers
          : numbers // ignore: cast_nullable_to_non_nullable
              as List<int>,
      directions: null == directions
          ? _value.directions
          : directions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LuckyModelImplCopyWith<$Res>
    implements $LuckyModelCopyWith<$Res> {
  factory _$$LuckyModelImplCopyWith(
          _$LuckyModelImpl value, $Res Function(_$LuckyModelImpl) then) =
      __$$LuckyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'days') List<String> days,
      @JsonKey(name: 'colors') List<String> colors,
      @JsonKey(name: 'numbers') List<int> numbers,
      @JsonKey(name: 'directions') List<String> directions});
}

/// @nodoc
class __$$LuckyModelImplCopyWithImpl<$Res>
    extends _$LuckyModelCopyWithImpl<$Res, _$LuckyModelImpl>
    implements _$$LuckyModelImplCopyWith<$Res> {
  __$$LuckyModelImplCopyWithImpl(
      _$LuckyModelImpl _value, $Res Function(_$LuckyModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of LuckyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? days = null,
    Object? colors = null,
    Object? numbers = null,
    Object? directions = null,
  }) {
    return _then(_$LuckyModelImpl(
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colors: null == colors
          ? _value._colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      numbers: null == numbers
          ? _value._numbers
          : numbers // ignore: cast_nullable_to_non_nullable
              as List<int>,
      directions: null == directions
          ? _value._directions
          : directions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LuckyModelImpl implements _LuckyModel {
  const _$LuckyModelImpl(
      {@JsonKey(name: 'days') required final List<String> days,
      @JsonKey(name: 'colors') required final List<String> colors,
      @JsonKey(name: 'numbers') required final List<int> numbers,
      @JsonKey(name: 'directions') required final List<String> directions})
      : _days = days,
        _colors = colors,
        _numbers = numbers,
        _directions = directions;

  factory _$LuckyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LuckyModelImplFromJson(json);

  final List<String> _days;
  @override
  @JsonKey(name: 'days')
  List<String> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  final List<String> _colors;
  @override
  @JsonKey(name: 'colors')
  List<String> get colors {
    if (_colors is EqualUnmodifiableListView) return _colors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colors);
  }

  final List<int> _numbers;
  @override
  @JsonKey(name: 'numbers')
  List<int> get numbers {
    if (_numbers is EqualUnmodifiableListView) return _numbers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_numbers);
  }

  final List<String> _directions;
  @override
  @JsonKey(name: 'directions')
  List<String> get directions {
    if (_directions is EqualUnmodifiableListView) return _directions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_directions);
  }

  @override
  String toString() {
    return 'LuckyModel(days: $days, colors: $colors, numbers: $numbers, directions: $directions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LuckyModelImpl &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            const DeepCollectionEquality().equals(other._colors, _colors) &&
            const DeepCollectionEquality().equals(other._numbers, _numbers) &&
            const DeepCollectionEquality()
                .equals(other._directions, _directions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_days),
      const DeepCollectionEquality().hash(_colors),
      const DeepCollectionEquality().hash(_numbers),
      const DeepCollectionEquality().hash(_directions));

  /// Create a copy of LuckyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LuckyModelImplCopyWith<_$LuckyModelImpl> get copyWith =>
      __$$LuckyModelImplCopyWithImpl<_$LuckyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LuckyModelImplToJson(
      this,
    );
  }
}

abstract class _LuckyModel implements LuckyModel {
  const factory _LuckyModel(
      {@JsonKey(name: 'days') required final List<String> days,
      @JsonKey(name: 'colors') required final List<String> colors,
      @JsonKey(name: 'numbers') required final List<int> numbers,
      @JsonKey(name: 'directions')
      required final List<String> directions}) = _$LuckyModelImpl;

  factory _LuckyModel.fromJson(Map<String, dynamic> json) =
      _$LuckyModelImpl.fromJson;

  @override
  @JsonKey(name: 'days')
  List<String> get days;
  @override
  @JsonKey(name: 'colors')
  List<String> get colors;
  @override
  @JsonKey(name: 'numbers')
  List<int> get numbers;
  @override
  @JsonKey(name: 'directions')
  List<String> get directions;

  /// Create a copy of LuckyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LuckyModelImplCopyWith<_$LuckyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
