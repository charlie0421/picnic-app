// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/community/compatibility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompatibilityHistoryModel _$CompatibilityHistoryModelFromJson(
    Map<String, dynamic> json) {
  return _CompatibilityHistoryModel.fromJson(json);
}

/// @nodoc
mixin _$CompatibilityHistoryModel {
  List<CompatibilityModel> get items => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Serializes this CompatibilityHistoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompatibilityHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompatibilityHistoryModelCopyWith<CompatibilityHistoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityHistoryModelCopyWith<$Res> {
  factory $CompatibilityHistoryModelCopyWith(CompatibilityHistoryModel value,
          $Res Function(CompatibilityHistoryModel) then) =
      _$CompatibilityHistoryModelCopyWithImpl<$Res, CompatibilityHistoryModel>;
  @useResult
  $Res call({List<CompatibilityModel> items, bool hasMore, bool isLoading});
}

/// @nodoc
class _$CompatibilityHistoryModelCopyWithImpl<$Res,
        $Val extends CompatibilityHistoryModel>
    implements $CompatibilityHistoryModelCopyWith<$Res> {
  _$CompatibilityHistoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompatibilityHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? hasMore = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CompatibilityModel>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompatibilityHistoryModelImplCopyWith<$Res>
    implements $CompatibilityHistoryModelCopyWith<$Res> {
  factory _$$CompatibilityHistoryModelImplCopyWith(
          _$CompatibilityHistoryModelImpl value,
          $Res Function(_$CompatibilityHistoryModelImpl) then) =
      __$$CompatibilityHistoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CompatibilityModel> items, bool hasMore, bool isLoading});
}

/// @nodoc
class __$$CompatibilityHistoryModelImplCopyWithImpl<$Res>
    extends _$CompatibilityHistoryModelCopyWithImpl<$Res,
        _$CompatibilityHistoryModelImpl>
    implements _$$CompatibilityHistoryModelImplCopyWith<$Res> {
  __$$CompatibilityHistoryModelImplCopyWithImpl(
      _$CompatibilityHistoryModelImpl _value,
      $Res Function(_$CompatibilityHistoryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompatibilityHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? hasMore = null,
    Object? isLoading = null,
  }) {
    return _then(_$CompatibilityHistoryModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CompatibilityModel>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompatibilityHistoryModelImpl implements _CompatibilityHistoryModel {
  const _$CompatibilityHistoryModelImpl(
      {required final List<CompatibilityModel> items,
      required this.hasMore,
      this.isLoading = false})
      : _items = items;

  factory _$CompatibilityHistoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompatibilityHistoryModelImplFromJson(json);

  final List<CompatibilityModel> _items;
  @override
  List<CompatibilityModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final bool hasMore;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'CompatibilityHistoryModel(items: $items, hasMore: $hasMore, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityHistoryModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), hasMore, isLoading);

  /// Create a copy of CompatibilityHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityHistoryModelImplCopyWith<_$CompatibilityHistoryModelImpl>
      get copyWith => __$$CompatibilityHistoryModelImplCopyWithImpl<
          _$CompatibilityHistoryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompatibilityHistoryModelImplToJson(
      this,
    );
  }
}

abstract class _CompatibilityHistoryModel implements CompatibilityHistoryModel {
  const factory _CompatibilityHistoryModel(
      {required final List<CompatibilityModel> items,
      required final bool hasMore,
      final bool isLoading}) = _$CompatibilityHistoryModelImpl;

  factory _CompatibilityHistoryModel.fromJson(Map<String, dynamic> json) =
      _$CompatibilityHistoryModelImpl.fromJson;

  @override
  List<CompatibilityModel> get items;
  @override
  bool get hasMore;
  @override
  bool get isLoading;

  /// Create a copy of CompatibilityHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompatibilityHistoryModelImplCopyWith<_$CompatibilityHistoryModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CompatibilityModel _$CompatibilityModelFromJson(Map<String, dynamic> json) {
  return _CompatibilityModel.fromJson(json);
}

/// @nodoc
mixin _$CompatibilityModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  ArtistModel get artist => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_birth_date')
  DateTime get birthDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_birth_time')
  String? get birthTime => throw _privateConstructorUsedError;
  CompatibilityStatus get status => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool? get isLoading => throw _privateConstructorUsedError;
  @JsonKey(name: 'compatibility_score')
  int? get compatibilityScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'compatibility_summary')
  String? get compatibilitySummary => throw _privateConstructorUsedError;
  Details? get details => throw _privateConstructorUsedError;
  List<String>? get tips => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
  Map<String, LocalizedCompatibility>? get localizedResults =>
      throw _privateConstructorUsedError;

  /// Serializes this CompatibilityModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompatibilityModelCopyWith<CompatibilityModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityModelCopyWith<$Res> {
  factory $CompatibilityModelCopyWith(
          CompatibilityModel value, $Res Function(CompatibilityModel) then) =
      _$CompatibilityModelCopyWithImpl<$Res, CompatibilityModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      ArtistModel artist,
      @JsonKey(name: 'user_birth_date') DateTime birthDate,
      @JsonKey(name: 'user_birth_time') String? birthTime,
      CompatibilityStatus status,
      String? gender,
      String? errorMessage,
      bool? isLoading,
      @JsonKey(name: 'compatibility_score') int? compatibilityScore,
      @JsonKey(name: 'compatibility_summary') String? compatibilitySummary,
      Details? details,
      List<String>? tips,
      DateTime? createdAt,
      DateTime? completedAt,
      @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
      Map<String, LocalizedCompatibility>? localizedResults});

  $ArtistModelCopyWith<$Res> get artist;
  $DetailsCopyWith<$Res>? get details;
}

/// @nodoc
class _$CompatibilityModelCopyWithImpl<$Res, $Val extends CompatibilityModel>
    implements $CompatibilityModelCopyWith<$Res> {
  _$CompatibilityModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? artist = null,
    Object? birthDate = null,
    Object? birthTime = freezed,
    Object? status = null,
    Object? gender = freezed,
    Object? errorMessage = freezed,
    Object? isLoading = freezed,
    Object? compatibilityScore = freezed,
    Object? compatibilitySummary = freezed,
    Object? details = freezed,
    Object? tips = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
    Object? localizedResults = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      birthTime: freezed == birthTime
          ? _value.birthTime
          : birthTime // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CompatibilityStatus,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: freezed == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as int?,
      compatibilitySummary: freezed == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Details?,
      tips: freezed == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localizedResults: freezed == localizedResults
          ? _value.localizedResults
          : localizedResults // ignore: cast_nullable_to_non_nullable
              as Map<String, LocalizedCompatibility>?,
    ) as $Val);
  }

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res> get artist {
    return $ArtistModelCopyWith<$Res>(_value.artist, (value) {
      return _then(_value.copyWith(artist: value) as $Val);
    });
  }

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DetailsCopyWith<$Res>? get details {
    if (_value.details == null) {
      return null;
    }

    return $DetailsCopyWith<$Res>(_value.details!, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompatibilityModelImplCopyWith<$Res>
    implements $CompatibilityModelCopyWith<$Res> {
  factory _$$CompatibilityModelImplCopyWith(_$CompatibilityModelImpl value,
          $Res Function(_$CompatibilityModelImpl) then) =
      __$$CompatibilityModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      ArtistModel artist,
      @JsonKey(name: 'user_birth_date') DateTime birthDate,
      @JsonKey(name: 'user_birth_time') String? birthTime,
      CompatibilityStatus status,
      String? gender,
      String? errorMessage,
      bool? isLoading,
      @JsonKey(name: 'compatibility_score') int? compatibilityScore,
      @JsonKey(name: 'compatibility_summary') String? compatibilitySummary,
      Details? details,
      List<String>? tips,
      DateTime? createdAt,
      DateTime? completedAt,
      @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
      Map<String, LocalizedCompatibility>? localizedResults});

  @override
  $ArtistModelCopyWith<$Res> get artist;
  @override
  $DetailsCopyWith<$Res>? get details;
}

/// @nodoc
class __$$CompatibilityModelImplCopyWithImpl<$Res>
    extends _$CompatibilityModelCopyWithImpl<$Res, _$CompatibilityModelImpl>
    implements _$$CompatibilityModelImplCopyWith<$Res> {
  __$$CompatibilityModelImplCopyWithImpl(_$CompatibilityModelImpl _value,
      $Res Function(_$CompatibilityModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? artist = null,
    Object? birthDate = null,
    Object? birthTime = freezed,
    Object? status = null,
    Object? gender = freezed,
    Object? errorMessage = freezed,
    Object? isLoading = freezed,
    Object? compatibilityScore = freezed,
    Object? compatibilitySummary = freezed,
    Object? details = freezed,
    Object? tips = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
    Object? localizedResults = freezed,
  }) {
    return _then(_$CompatibilityModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      birthTime: freezed == birthTime
          ? _value.birthTime
          : birthTime // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CompatibilityStatus,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: freezed == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool?,
      compatibilityScore: freezed == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as int?,
      compatibilitySummary: freezed == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Details?,
      tips: freezed == tips
          ? _value._tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localizedResults: freezed == localizedResults
          ? _value._localizedResults
          : localizedResults // ignore: cast_nullable_to_non_nullable
              as Map<String, LocalizedCompatibility>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompatibilityModelImpl extends _CompatibilityModel {
  const _$CompatibilityModelImpl(
      {this.id = '',
      required this.userId,
      required this.artist,
      @JsonKey(name: 'user_birth_date') required this.birthDate,
      @JsonKey(name: 'user_birth_time') this.birthTime,
      this.status = CompatibilityStatus.pending,
      this.gender,
      this.errorMessage,
      this.isLoading,
      @JsonKey(name: 'compatibility_score') this.compatibilityScore,
      @JsonKey(name: 'compatibility_summary') this.compatibilitySummary,
      this.details,
      final List<String>? tips,
      this.createdAt,
      this.completedAt,
      @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
      final Map<String, LocalizedCompatibility>? localizedResults})
      : _tips = tips,
        _localizedResults = localizedResults,
        super._();

  factory _$CompatibilityModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompatibilityModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  final String userId;
  @override
  final ArtistModel artist;
  @override
  @JsonKey(name: 'user_birth_date')
  final DateTime birthDate;
  @override
  @JsonKey(name: 'user_birth_time')
  final String? birthTime;
  @override
  @JsonKey()
  final CompatibilityStatus status;
  @override
  final String? gender;
  @override
  final String? errorMessage;
  @override
  final bool? isLoading;
  @override
  @JsonKey(name: 'compatibility_score')
  final int? compatibilityScore;
  @override
  @JsonKey(name: 'compatibility_summary')
  final String? compatibilitySummary;
  @override
  final Details? details;
  final List<String>? _tips;
  @override
  List<String>? get tips {
    final value = _tips;
    if (value == null) return null;
    if (_tips is EqualUnmodifiableListView) return _tips;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? completedAt;
  final Map<String, LocalizedCompatibility>? _localizedResults;
  @override
  @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
  Map<String, LocalizedCompatibility>? get localizedResults {
    final value = _localizedResults;
    if (value == null) return null;
    if (_localizedResults is EqualUnmodifiableMapView) return _localizedResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'CompatibilityModel(id: $id, userId: $userId, artist: $artist, birthDate: $birthDate, birthTime: $birthTime, status: $status, gender: $gender, errorMessage: $errorMessage, isLoading: $isLoading, compatibilityScore: $compatibilityScore, compatibilitySummary: $compatibilitySummary, details: $details, tips: $tips, createdAt: $createdAt, completedAt: $completedAt, localizedResults: $localizedResults)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.birthTime, birthTime) ||
                other.birthTime == birthTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.compatibilityScore, compatibilityScore) ||
                other.compatibilityScore == compatibilityScore) &&
            (identical(other.compatibilitySummary, compatibilitySummary) ||
                other.compatibilitySummary == compatibilitySummary) &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality().equals(other._tips, _tips) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality()
                .equals(other._localizedResults, _localizedResults));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      artist,
      birthDate,
      birthTime,
      status,
      gender,
      errorMessage,
      isLoading,
      compatibilityScore,
      compatibilitySummary,
      details,
      const DeepCollectionEquality().hash(_tips),
      createdAt,
      completedAt,
      const DeepCollectionEquality().hash(_localizedResults));

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityModelImplCopyWith<_$CompatibilityModelImpl> get copyWith =>
      __$$CompatibilityModelImplCopyWithImpl<_$CompatibilityModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompatibilityModelImplToJson(
      this,
    );
  }
}

abstract class _CompatibilityModel extends CompatibilityModel {
  const factory _CompatibilityModel(
          {final String id,
          required final String userId,
          required final ArtistModel artist,
          @JsonKey(name: 'user_birth_date') required final DateTime birthDate,
          @JsonKey(name: 'user_birth_time') final String? birthTime,
          final CompatibilityStatus status,
          final String? gender,
          final String? errorMessage,
          final bool? isLoading,
          @JsonKey(name: 'compatibility_score') final int? compatibilityScore,
          @JsonKey(name: 'compatibility_summary')
          final String? compatibilitySummary,
          final Details? details,
          final List<String>? tips,
          final DateTime? createdAt,
          final DateTime? completedAt,
          @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
          final Map<String, LocalizedCompatibility>? localizedResults}) =
      _$CompatibilityModelImpl;
  const _CompatibilityModel._() : super._();

  factory _CompatibilityModel.fromJson(Map<String, dynamic> json) =
      _$CompatibilityModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  ArtistModel get artist;
  @override
  @JsonKey(name: 'user_birth_date')
  DateTime get birthDate;
  @override
  @JsonKey(name: 'user_birth_time')
  String? get birthTime;
  @override
  CompatibilityStatus get status;
  @override
  String? get gender;
  @override
  String? get errorMessage;
  @override
  bool? get isLoading;
  @override
  @JsonKey(name: 'compatibility_score')
  int? get compatibilityScore;
  @override
  @JsonKey(name: 'compatibility_summary')
  String? get compatibilitySummary;
  @override
  Details? get details;
  @override
  List<String>? get tips;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
  Map<String, LocalizedCompatibility>? get localizedResults;

  /// Create a copy of CompatibilityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompatibilityModelImplCopyWith<_$CompatibilityModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LocalizedCompatibility _$LocalizedCompatibilityFromJson(
    Map<String, dynamic> json) {
  return _LocalizedCompatibility.fromJson(json);
}

/// @nodoc
mixin _$LocalizedCompatibility {
  String get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'compatibility_summary')
  String get compatibilitySummary => throw _privateConstructorUsedError;
  @JsonKey(name: 'details')
  Details? get details => throw _privateConstructorUsedError;
  List<String> get tips => throw _privateConstructorUsedError;

  /// Serializes this LocalizedCompatibility to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalizedCompatibilityCopyWith<LocalizedCompatibility> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalizedCompatibilityCopyWith<$Res> {
  factory $LocalizedCompatibilityCopyWith(LocalizedCompatibility value,
          $Res Function(LocalizedCompatibility) then) =
      _$LocalizedCompatibilityCopyWithImpl<$Res, LocalizedCompatibility>;
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'compatibility_summary') String compatibilitySummary,
      @JsonKey(name: 'details') Details? details,
      List<String> tips});

  $DetailsCopyWith<$Res>? get details;
}

/// @nodoc
class _$LocalizedCompatibilityCopyWithImpl<$Res,
        $Val extends LocalizedCompatibility>
    implements $LocalizedCompatibilityCopyWith<$Res> {
  _$LocalizedCompatibilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? compatibilitySummary = null,
    Object? details = freezed,
    Object? tips = null,
  }) {
    return _then(_value.copyWith(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      compatibilitySummary: null == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Details?,
      tips: null == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DetailsCopyWith<$Res>? get details {
    if (_value.details == null) {
      return null;
    }

    return $DetailsCopyWith<$Res>(_value.details!, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LocalizedCompatibilityImplCopyWith<$Res>
    implements $LocalizedCompatibilityCopyWith<$Res> {
  factory _$$LocalizedCompatibilityImplCopyWith(
          _$LocalizedCompatibilityImpl value,
          $Res Function(_$LocalizedCompatibilityImpl) then) =
      __$$LocalizedCompatibilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'compatibility_summary') String compatibilitySummary,
      @JsonKey(name: 'details') Details? details,
      List<String> tips});

  @override
  $DetailsCopyWith<$Res>? get details;
}

/// @nodoc
class __$$LocalizedCompatibilityImplCopyWithImpl<$Res>
    extends _$LocalizedCompatibilityCopyWithImpl<$Res,
        _$LocalizedCompatibilityImpl>
    implements _$$LocalizedCompatibilityImplCopyWith<$Res> {
  __$$LocalizedCompatibilityImplCopyWithImpl(
      _$LocalizedCompatibilityImpl _value,
      $Res Function(_$LocalizedCompatibilityImpl) _then)
      : super(_value, _then);

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? compatibilitySummary = null,
    Object? details = freezed,
    Object? tips = null,
  }) {
    return _then(_$LocalizedCompatibilityImpl(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      compatibilitySummary: null == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Details?,
      tips: null == tips
          ? _value._tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocalizedCompatibilityImpl implements _LocalizedCompatibility {
  const _$LocalizedCompatibilityImpl(
      {required this.language,
      @JsonKey(name: 'compatibility_summary')
      required this.compatibilitySummary,
      @JsonKey(name: 'details') this.details,
      final List<String> tips = const []})
      : _tips = tips;

  factory _$LocalizedCompatibilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocalizedCompatibilityImplFromJson(json);

  @override
  final String language;
  @override
  @JsonKey(name: 'compatibility_summary')
  final String compatibilitySummary;
  @override
  @JsonKey(name: 'details')
  final Details? details;
  final List<String> _tips;
  @override
  @JsonKey()
  List<String> get tips {
    if (_tips is EqualUnmodifiableListView) return _tips;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tips);
  }

  @override
  String toString() {
    return 'LocalizedCompatibility(language: $language, compatibilitySummary: $compatibilitySummary, details: $details, tips: $tips)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalizedCompatibilityImpl &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.compatibilitySummary, compatibilitySummary) ||
                other.compatibilitySummary == compatibilitySummary) &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality().equals(other._tips, _tips));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, language, compatibilitySummary,
      details, const DeepCollectionEquality().hash(_tips));

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalizedCompatibilityImplCopyWith<_$LocalizedCompatibilityImpl>
      get copyWith => __$$LocalizedCompatibilityImplCopyWithImpl<
          _$LocalizedCompatibilityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocalizedCompatibilityImplToJson(
      this,
    );
  }
}

abstract class _LocalizedCompatibility implements LocalizedCompatibility {
  const factory _LocalizedCompatibility(
      {required final String language,
      @JsonKey(name: 'compatibility_summary')
      required final String compatibilitySummary,
      @JsonKey(name: 'details') final Details? details,
      final List<String> tips}) = _$LocalizedCompatibilityImpl;

  factory _LocalizedCompatibility.fromJson(Map<String, dynamic> json) =
      _$LocalizedCompatibilityImpl.fromJson;

  @override
  String get language;
  @override
  @JsonKey(name: 'compatibility_summary')
  String get compatibilitySummary;
  @override
  @JsonKey(name: 'details')
  Details? get details;
  @override
  List<String> get tips;

  /// Create a copy of LocalizedCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalizedCompatibilityImplCopyWith<_$LocalizedCompatibilityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

Details _$DetailsFromJson(Map<String, dynamic> json) {
  return _Details.fromJson(json);
}

/// @nodoc
mixin _$Details {
  StyleDetails get style => throw _privateConstructorUsedError;
  ActivitiesDetails get activities => throw _privateConstructorUsedError;

  /// Serializes this Details to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetailsCopyWith<Details> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetailsCopyWith<$Res> {
  factory $DetailsCopyWith(Details value, $Res Function(Details) then) =
      _$DetailsCopyWithImpl<$Res, Details>;
  @useResult
  $Res call({StyleDetails style, ActivitiesDetails activities});

  $StyleDetailsCopyWith<$Res> get style;
  $ActivitiesDetailsCopyWith<$Res> get activities;
}

/// @nodoc
class _$DetailsCopyWithImpl<$Res, $Val extends Details>
    implements $DetailsCopyWith<$Res> {
  _$DetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? style = null,
    Object? activities = null,
  }) {
    return _then(_value.copyWith(
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as StyleDetails,
      activities: null == activities
          ? _value.activities
          : activities // ignore: cast_nullable_to_non_nullable
              as ActivitiesDetails,
    ) as $Val);
  }

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StyleDetailsCopyWith<$Res> get style {
    return $StyleDetailsCopyWith<$Res>(_value.style, (value) {
      return _then(_value.copyWith(style: value) as $Val);
    });
  }

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ActivitiesDetailsCopyWith<$Res> get activities {
    return $ActivitiesDetailsCopyWith<$Res>(_value.activities, (value) {
      return _then(_value.copyWith(activities: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DetailsImplCopyWith<$Res> implements $DetailsCopyWith<$Res> {
  factory _$$DetailsImplCopyWith(
          _$DetailsImpl value, $Res Function(_$DetailsImpl) then) =
      __$$DetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({StyleDetails style, ActivitiesDetails activities});

  @override
  $StyleDetailsCopyWith<$Res> get style;
  @override
  $ActivitiesDetailsCopyWith<$Res> get activities;
}

/// @nodoc
class __$$DetailsImplCopyWithImpl<$Res>
    extends _$DetailsCopyWithImpl<$Res, _$DetailsImpl>
    implements _$$DetailsImplCopyWith<$Res> {
  __$$DetailsImplCopyWithImpl(
      _$DetailsImpl _value, $Res Function(_$DetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? style = null,
    Object? activities = null,
  }) {
    return _then(_$DetailsImpl(
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as StyleDetails,
      activities: null == activities
          ? _value.activities
          : activities // ignore: cast_nullable_to_non_nullable
              as ActivitiesDetails,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetailsImpl implements _Details {
  const _$DetailsImpl({required this.style, required this.activities});

  factory _$DetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetailsImplFromJson(json);

  @override
  final StyleDetails style;
  @override
  final ActivitiesDetails activities;

  @override
  String toString() {
    return 'Details(style: $style, activities: $activities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetailsImpl &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.activities, activities) ||
                other.activities == activities));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, style, activities);

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetailsImplCopyWith<_$DetailsImpl> get copyWith =>
      __$$DetailsImplCopyWithImpl<_$DetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetailsImplToJson(
      this,
    );
  }
}

abstract class _Details implements Details {
  const factory _Details(
      {required final StyleDetails style,
      required final ActivitiesDetails activities}) = _$DetailsImpl;

  factory _Details.fromJson(Map<String, dynamic> json) = _$DetailsImpl.fromJson;

  @override
  StyleDetails get style;
  @override
  ActivitiesDetails get activities;

  /// Create a copy of Details
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetailsImplCopyWith<_$DetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StyleDetails _$StyleDetailsFromJson(Map<String, dynamic> json) {
  return _StyleDetails.fromJson(json);
}

/// @nodoc
mixin _$StyleDetails {
  @JsonKey(name: 'idol_style')
  String get idolStyle => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_style')
  String get userStyle => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_style')
  String get coupleStyle => throw _privateConstructorUsedError;

  /// Serializes this StyleDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StyleDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StyleDetailsCopyWith<StyleDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StyleDetailsCopyWith<$Res> {
  factory $StyleDetailsCopyWith(
          StyleDetails value, $Res Function(StyleDetails) then) =
      _$StyleDetailsCopyWithImpl<$Res, StyleDetails>;
  @useResult
  $Res call(
      {@JsonKey(name: 'idol_style') String idolStyle,
      @JsonKey(name: 'user_style') String userStyle,
      @JsonKey(name: 'couple_style') String coupleStyle});
}

/// @nodoc
class _$StyleDetailsCopyWithImpl<$Res, $Val extends StyleDetails>
    implements $StyleDetailsCopyWith<$Res> {
  _$StyleDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StyleDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idolStyle = null,
    Object? userStyle = null,
    Object? coupleStyle = null,
  }) {
    return _then(_value.copyWith(
      idolStyle: null == idolStyle
          ? _value.idolStyle
          : idolStyle // ignore: cast_nullable_to_non_nullable
              as String,
      userStyle: null == userStyle
          ? _value.userStyle
          : userStyle // ignore: cast_nullable_to_non_nullable
              as String,
      coupleStyle: null == coupleStyle
          ? _value.coupleStyle
          : coupleStyle // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StyleDetailsImplCopyWith<$Res>
    implements $StyleDetailsCopyWith<$Res> {
  factory _$$StyleDetailsImplCopyWith(
          _$StyleDetailsImpl value, $Res Function(_$StyleDetailsImpl) then) =
      __$$StyleDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'idol_style') String idolStyle,
      @JsonKey(name: 'user_style') String userStyle,
      @JsonKey(name: 'couple_style') String coupleStyle});
}

/// @nodoc
class __$$StyleDetailsImplCopyWithImpl<$Res>
    extends _$StyleDetailsCopyWithImpl<$Res, _$StyleDetailsImpl>
    implements _$$StyleDetailsImplCopyWith<$Res> {
  __$$StyleDetailsImplCopyWithImpl(
      _$StyleDetailsImpl _value, $Res Function(_$StyleDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of StyleDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idolStyle = null,
    Object? userStyle = null,
    Object? coupleStyle = null,
  }) {
    return _then(_$StyleDetailsImpl(
      idolStyle: null == idolStyle
          ? _value.idolStyle
          : idolStyle // ignore: cast_nullable_to_non_nullable
              as String,
      userStyle: null == userStyle
          ? _value.userStyle
          : userStyle // ignore: cast_nullable_to_non_nullable
              as String,
      coupleStyle: null == coupleStyle
          ? _value.coupleStyle
          : coupleStyle // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StyleDetailsImpl implements _StyleDetails {
  const _$StyleDetailsImpl(
      {@JsonKey(name: 'idol_style') required this.idolStyle,
      @JsonKey(name: 'user_style') required this.userStyle,
      @JsonKey(name: 'couple_style') required this.coupleStyle});

  factory _$StyleDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StyleDetailsImplFromJson(json);

  @override
  @JsonKey(name: 'idol_style')
  final String idolStyle;
  @override
  @JsonKey(name: 'user_style')
  final String userStyle;
  @override
  @JsonKey(name: 'couple_style')
  final String coupleStyle;

  @override
  String toString() {
    return 'StyleDetails(idolStyle: $idolStyle, userStyle: $userStyle, coupleStyle: $coupleStyle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StyleDetailsImpl &&
            (identical(other.idolStyle, idolStyle) ||
                other.idolStyle == idolStyle) &&
            (identical(other.userStyle, userStyle) ||
                other.userStyle == userStyle) &&
            (identical(other.coupleStyle, coupleStyle) ||
                other.coupleStyle == coupleStyle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, idolStyle, userStyle, coupleStyle);

  /// Create a copy of StyleDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StyleDetailsImplCopyWith<_$StyleDetailsImpl> get copyWith =>
      __$$StyleDetailsImplCopyWithImpl<_$StyleDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StyleDetailsImplToJson(
      this,
    );
  }
}

abstract class _StyleDetails implements StyleDetails {
  const factory _StyleDetails(
          {@JsonKey(name: 'idol_style') required final String idolStyle,
          @JsonKey(name: 'user_style') required final String userStyle,
          @JsonKey(name: 'couple_style') required final String coupleStyle}) =
      _$StyleDetailsImpl;

  factory _StyleDetails.fromJson(Map<String, dynamic> json) =
      _$StyleDetailsImpl.fromJson;

  @override
  @JsonKey(name: 'idol_style')
  String get idolStyle;
  @override
  @JsonKey(name: 'user_style')
  String get userStyle;
  @override
  @JsonKey(name: 'couple_style')
  String get coupleStyle;

  /// Create a copy of StyleDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StyleDetailsImplCopyWith<_$StyleDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActivitiesDetails _$ActivitiesDetailsFromJson(Map<String, dynamic> json) {
  return _ActivitiesDetails.fromJson(json);
}

/// @nodoc
mixin _$ActivitiesDetails {
  List<String> get recommended => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Serializes this ActivitiesDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActivitiesDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivitiesDetailsCopyWith<ActivitiesDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivitiesDetailsCopyWith<$Res> {
  factory $ActivitiesDetailsCopyWith(
          ActivitiesDetails value, $Res Function(ActivitiesDetails) then) =
      _$ActivitiesDetailsCopyWithImpl<$Res, ActivitiesDetails>;
  @useResult
  $Res call({List<String> recommended, String description});
}

/// @nodoc
class _$ActivitiesDetailsCopyWithImpl<$Res, $Val extends ActivitiesDetails>
    implements $ActivitiesDetailsCopyWith<$Res> {
  _$ActivitiesDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivitiesDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recommended = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      recommended: null == recommended
          ? _value.recommended
          : recommended // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivitiesDetailsImplCopyWith<$Res>
    implements $ActivitiesDetailsCopyWith<$Res> {
  factory _$$ActivitiesDetailsImplCopyWith(_$ActivitiesDetailsImpl value,
          $Res Function(_$ActivitiesDetailsImpl) then) =
      __$$ActivitiesDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> recommended, String description});
}

/// @nodoc
class __$$ActivitiesDetailsImplCopyWithImpl<$Res>
    extends _$ActivitiesDetailsCopyWithImpl<$Res, _$ActivitiesDetailsImpl>
    implements _$$ActivitiesDetailsImplCopyWith<$Res> {
  __$$ActivitiesDetailsImplCopyWithImpl(_$ActivitiesDetailsImpl _value,
      $Res Function(_$ActivitiesDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActivitiesDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recommended = null,
    Object? description = null,
  }) {
    return _then(_$ActivitiesDetailsImpl(
      recommended: null == recommended
          ? _value._recommended
          : recommended // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActivitiesDetailsImpl implements _ActivitiesDetails {
  const _$ActivitiesDetailsImpl(
      {required final List<String> recommended, required this.description})
      : _recommended = recommended;

  factory _$ActivitiesDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActivitiesDetailsImplFromJson(json);

  final List<String> _recommended;
  @override
  List<String> get recommended {
    if (_recommended is EqualUnmodifiableListView) return _recommended;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommended);
  }

  @override
  final String description;

  @override
  String toString() {
    return 'ActivitiesDetails(recommended: $recommended, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivitiesDetailsImpl &&
            const DeepCollectionEquality()
                .equals(other._recommended, _recommended) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_recommended), description);

  /// Create a copy of ActivitiesDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivitiesDetailsImplCopyWith<_$ActivitiesDetailsImpl> get copyWith =>
      __$$ActivitiesDetailsImplCopyWithImpl<_$ActivitiesDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActivitiesDetailsImplToJson(
      this,
    );
  }
}

abstract class _ActivitiesDetails implements ActivitiesDetails {
  const factory _ActivitiesDetails(
      {required final List<String> recommended,
      required final String description}) = _$ActivitiesDetailsImpl;

  factory _ActivitiesDetails.fromJson(Map<String, dynamic> json) =
      _$ActivitiesDetailsImpl.fromJson;

  @override
  List<String> get recommended;
  @override
  String get description;

  /// Create a copy of ActivitiesDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivitiesDetailsImplCopyWith<_$ActivitiesDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
