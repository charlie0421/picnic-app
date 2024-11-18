// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/community/compatibility_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompatibilityResult _$CompatibilityResultFromJson(Map<String, dynamic> json) {
  return _CompatibilityResult.fromJson(json);
}

/// @nodoc
mixin _$CompatibilityResult {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get idolName => throw _privateConstructorUsedError;
  DateTime get userBirthDate => throw _privateConstructorUsedError;
  DateTime get idolBirthDate => throw _privateConstructorUsedError;
  String get userGender => throw _privateConstructorUsedError;
  String? get birthTime => throw _privateConstructorUsedError; // Optional
  int get compatibilityScore => throw _privateConstructorUsedError;
  String get compatibilitySummary => throw _privateConstructorUsedError;
  Map<String, dynamic> get details => throw _privateConstructorUsedError;
  List<String> get tips => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CompatibilityResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompatibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompatibilityResultCopyWith<CompatibilityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityResultCopyWith<$Res> {
  factory $CompatibilityResultCopyWith(
          CompatibilityResult value, $Res Function(CompatibilityResult) then) =
      _$CompatibilityResultCopyWithImpl<$Res, CompatibilityResult>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String idolName,
      DateTime userBirthDate,
      DateTime idolBirthDate,
      String userGender,
      String? birthTime,
      int compatibilityScore,
      String compatibilitySummary,
      Map<String, dynamic> details,
      List<String> tips,
      DateTime createdAt});
}

/// @nodoc
class _$CompatibilityResultCopyWithImpl<$Res, $Val extends CompatibilityResult>
    implements $CompatibilityResultCopyWith<$Res> {
  _$CompatibilityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompatibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? idolName = null,
    Object? userBirthDate = null,
    Object? idolBirthDate = null,
    Object? userGender = null,
    Object? birthTime = freezed,
    Object? compatibilityScore = null,
    Object? compatibilitySummary = null,
    Object? details = null,
    Object? tips = null,
    Object? createdAt = null,
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
      idolName: null == idolName
          ? _value.idolName
          : idolName // ignore: cast_nullable_to_non_nullable
              as String,
      userBirthDate: null == userBirthDate
          ? _value.userBirthDate
          : userBirthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      idolBirthDate: null == idolBirthDate
          ? _value.idolBirthDate
          : idolBirthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userGender: null == userGender
          ? _value.userGender
          : userGender // ignore: cast_nullable_to_non_nullable
              as String,
      birthTime: freezed == birthTime
          ? _value.birthTime
          : birthTime // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityScore: null == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as int,
      compatibilitySummary: null == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      tips: null == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompatibilityResultImplCopyWith<$Res>
    implements $CompatibilityResultCopyWith<$Res> {
  factory _$$CompatibilityResultImplCopyWith(_$CompatibilityResultImpl value,
          $Res Function(_$CompatibilityResultImpl) then) =
      __$$CompatibilityResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String idolName,
      DateTime userBirthDate,
      DateTime idolBirthDate,
      String userGender,
      String? birthTime,
      int compatibilityScore,
      String compatibilitySummary,
      Map<String, dynamic> details,
      List<String> tips,
      DateTime createdAt});
}

/// @nodoc
class __$$CompatibilityResultImplCopyWithImpl<$Res>
    extends _$CompatibilityResultCopyWithImpl<$Res, _$CompatibilityResultImpl>
    implements _$$CompatibilityResultImplCopyWith<$Res> {
  __$$CompatibilityResultImplCopyWithImpl(_$CompatibilityResultImpl _value,
      $Res Function(_$CompatibilityResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompatibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? idolName = null,
    Object? userBirthDate = null,
    Object? idolBirthDate = null,
    Object? userGender = null,
    Object? birthTime = freezed,
    Object? compatibilityScore = null,
    Object? compatibilitySummary = null,
    Object? details = null,
    Object? tips = null,
    Object? createdAt = null,
  }) {
    return _then(_$CompatibilityResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      idolName: null == idolName
          ? _value.idolName
          : idolName // ignore: cast_nullable_to_non_nullable
              as String,
      userBirthDate: null == userBirthDate
          ? _value.userBirthDate
          : userBirthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      idolBirthDate: null == idolBirthDate
          ? _value.idolBirthDate
          : idolBirthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userGender: null == userGender
          ? _value.userGender
          : userGender // ignore: cast_nullable_to_non_nullable
              as String,
      birthTime: freezed == birthTime
          ? _value.birthTime
          : birthTime // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityScore: null == compatibilityScore
          ? _value.compatibilityScore
          : compatibilityScore // ignore: cast_nullable_to_non_nullable
              as int,
      compatibilitySummary: null == compatibilitySummary
          ? _value.compatibilitySummary
          : compatibilitySummary // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      tips: null == tips
          ? _value._tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompatibilityResultImpl implements _CompatibilityResult {
  const _$CompatibilityResultImpl(
      {required this.id,
      required this.userId,
      required this.idolName,
      required this.userBirthDate,
      required this.idolBirthDate,
      required this.userGender,
      this.birthTime,
      required this.compatibilityScore,
      required this.compatibilitySummary,
      required final Map<String, dynamic> details,
      required final List<String> tips,
      required this.createdAt})
      : _details = details,
        _tips = tips;

  factory _$CompatibilityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompatibilityResultImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String idolName;
  @override
  final DateTime userBirthDate;
  @override
  final DateTime idolBirthDate;
  @override
  final String userGender;
  @override
  final String? birthTime;
// Optional
  @override
  final int compatibilityScore;
  @override
  final String compatibilitySummary;
  final Map<String, dynamic> _details;
  @override
  Map<String, dynamic> get details {
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_details);
  }

  final List<String> _tips;
  @override
  List<String> get tips {
    if (_tips is EqualUnmodifiableListView) return _tips;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tips);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'CompatibilityResult(id: $id, userId: $userId, idolName: $idolName, userBirthDate: $userBirthDate, idolBirthDate: $idolBirthDate, userGender: $userGender, birthTime: $birthTime, compatibilityScore: $compatibilityScore, compatibilitySummary: $compatibilitySummary, details: $details, tips: $tips, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.idolName, idolName) ||
                other.idolName == idolName) &&
            (identical(other.userBirthDate, userBirthDate) ||
                other.userBirthDate == userBirthDate) &&
            (identical(other.idolBirthDate, idolBirthDate) ||
                other.idolBirthDate == idolBirthDate) &&
            (identical(other.userGender, userGender) ||
                other.userGender == userGender) &&
            (identical(other.birthTime, birthTime) ||
                other.birthTime == birthTime) &&
            (identical(other.compatibilityScore, compatibilityScore) ||
                other.compatibilityScore == compatibilityScore) &&
            (identical(other.compatibilitySummary, compatibilitySummary) ||
                other.compatibilitySummary == compatibilitySummary) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            const DeepCollectionEquality().equals(other._tips, _tips) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      idolName,
      userBirthDate,
      idolBirthDate,
      userGender,
      birthTime,
      compatibilityScore,
      compatibilitySummary,
      const DeepCollectionEquality().hash(_details),
      const DeepCollectionEquality().hash(_tips),
      createdAt);

  /// Create a copy of CompatibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityResultImplCopyWith<_$CompatibilityResultImpl> get copyWith =>
      __$$CompatibilityResultImplCopyWithImpl<_$CompatibilityResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompatibilityResultImplToJson(
      this,
    );
  }
}

abstract class _CompatibilityResult implements CompatibilityResult {
  const factory _CompatibilityResult(
      {required final String id,
      required final String userId,
      required final String idolName,
      required final DateTime userBirthDate,
      required final DateTime idolBirthDate,
      required final String userGender,
      final String? birthTime,
      required final int compatibilityScore,
      required final String compatibilitySummary,
      required final Map<String, dynamic> details,
      required final List<String> tips,
      required final DateTime createdAt}) = _$CompatibilityResultImpl;

  factory _CompatibilityResult.fromJson(Map<String, dynamic> json) =
      _$CompatibilityResultImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get idolName;
  @override
  DateTime get userBirthDate;
  @override
  DateTime get idolBirthDate;
  @override
  String get userGender;
  @override
  String? get birthTime; // Optional
  @override
  int get compatibilityScore;
  @override
  String get compatibilitySummary;
  @override
  Map<String, dynamic> get details;
  @override
  List<String> get tips;
  @override
  DateTime get createdAt;

  /// Create a copy of CompatibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompatibilityResultImplCopyWith<_$CompatibilityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StyleDetails _$StyleDetailsFromJson(Map<String, dynamic> json) {
  return _StyleDetails.fromJson(json);
}

/// @nodoc
mixin _$StyleDetails {
  String get idolStyle => throw _privateConstructorUsedError;
  String get userStyle => throw _privateConstructorUsedError;
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
  $Res call({String idolStyle, String userStyle, String coupleStyle});
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
  $Res call({String idolStyle, String userStyle, String coupleStyle});
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
      {required this.idolStyle,
      required this.userStyle,
      required this.coupleStyle});

  factory _$StyleDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StyleDetailsImplFromJson(json);

  @override
  final String idolStyle;
  @override
  final String userStyle;
  @override
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
      {required final String idolStyle,
      required final String userStyle,
      required final String coupleStyle}) = _$StyleDetailsImpl;

  factory _StyleDetails.fromJson(Map<String, dynamic> json) =
      _$StyleDetailsImpl.fromJson;

  @override
  String get idolStyle;
  @override
  String get userStyle;
  @override
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
