// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profiles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfilesModel _$UserProfilesModelFromJson(Map<String, dynamic> json) {
  return _UserProfilesModel.fromJson(json);
}

/// @nodoc
mixin _$UserProfilesModel {
  @JsonKey(name: 'id')
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'nickname')
  String? get nickname => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_agreement')
  UserAgreement? get userAgreement => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_admin')
  bool get isAdmin => throw _privateConstructorUsedError;
  @JsonKey(name: 'star_candy')
  int get starCandy => throw _privateConstructorUsedError;
  @JsonKey(name: 'star_candy_bonus')
  int get starCandyBonus => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false)
  RealtimeChannel? get realtimeChannel => throw _privateConstructorUsedError;

  /// Serializes this UserProfilesModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfilesModelCopyWith<UserProfilesModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfilesModelCopyWith<$Res> {
  factory $UserProfilesModelCopyWith(
          UserProfilesModel value, $Res Function(UserProfilesModel) then) =
      _$UserProfilesModelCopyWithImpl<$Res, UserProfilesModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'nickname') String? nickname,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'user_agreement') UserAgreement? userAgreement,
      @JsonKey(name: 'is_admin') bool isAdmin,
      @JsonKey(name: 'star_candy') int starCandy,
      @JsonKey(name: 'star_candy_bonus') int starCandyBonus,
      @JsonKey(includeFromJson: false) RealtimeChannel? realtimeChannel});

  $UserAgreementCopyWith<$Res>? get userAgreement;
}

/// @nodoc
class _$UserProfilesModelCopyWithImpl<$Res, $Val extends UserProfilesModel>
    implements $UserProfilesModelCopyWith<$Res> {
  _$UserProfilesModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nickname = freezed,
    Object? avatarUrl = freezed,
    Object? countryCode = freezed,
    Object? deletedAt = freezed,
    Object? userAgreement = freezed,
    Object? isAdmin = null,
    Object? starCandy = null,
    Object? starCandyBonus = null,
    Object? realtimeChannel = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userAgreement: freezed == userAgreement
          ? _value.userAgreement
          : userAgreement // ignore: cast_nullable_to_non_nullable
              as UserAgreement?,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      starCandy: null == starCandy
          ? _value.starCandy
          : starCandy // ignore: cast_nullable_to_non_nullable
              as int,
      starCandyBonus: null == starCandyBonus
          ? _value.starCandyBonus
          : starCandyBonus // ignore: cast_nullable_to_non_nullable
              as int,
      realtimeChannel: freezed == realtimeChannel
          ? _value.realtimeChannel
          : realtimeChannel // ignore: cast_nullable_to_non_nullable
              as RealtimeChannel?,
    ) as $Val);
  }

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserAgreementCopyWith<$Res>? get userAgreement {
    if (_value.userAgreement == null) {
      return null;
    }

    return $UserAgreementCopyWith<$Res>(_value.userAgreement!, (value) {
      return _then(_value.copyWith(userAgreement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfilesModelImplCopyWith<$Res>
    implements $UserProfilesModelCopyWith<$Res> {
  factory _$$UserProfilesModelImplCopyWith(_$UserProfilesModelImpl value,
          $Res Function(_$UserProfilesModelImpl) then) =
      __$$UserProfilesModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'nickname') String? nickname,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'country_code') String? countryCode,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'user_agreement') UserAgreement? userAgreement,
      @JsonKey(name: 'is_admin') bool isAdmin,
      @JsonKey(name: 'star_candy') int starCandy,
      @JsonKey(name: 'star_candy_bonus') int starCandyBonus,
      @JsonKey(includeFromJson: false) RealtimeChannel? realtimeChannel});

  @override
  $UserAgreementCopyWith<$Res>? get userAgreement;
}

/// @nodoc
class __$$UserProfilesModelImplCopyWithImpl<$Res>
    extends _$UserProfilesModelCopyWithImpl<$Res, _$UserProfilesModelImpl>
    implements _$$UserProfilesModelImplCopyWith<$Res> {
  __$$UserProfilesModelImplCopyWithImpl(_$UserProfilesModelImpl _value,
      $Res Function(_$UserProfilesModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nickname = freezed,
    Object? avatarUrl = freezed,
    Object? countryCode = freezed,
    Object? deletedAt = freezed,
    Object? userAgreement = freezed,
    Object? isAdmin = null,
    Object? starCandy = null,
    Object? starCandyBonus = null,
    Object? realtimeChannel = freezed,
  }) {
    return _then(_$UserProfilesModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userAgreement: freezed == userAgreement
          ? _value.userAgreement
          : userAgreement // ignore: cast_nullable_to_non_nullable
              as UserAgreement?,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      starCandy: null == starCandy
          ? _value.starCandy
          : starCandy // ignore: cast_nullable_to_non_nullable
              as int,
      starCandyBonus: null == starCandyBonus
          ? _value.starCandyBonus
          : starCandyBonus // ignore: cast_nullable_to_non_nullable
              as int,
      realtimeChannel: freezed == realtimeChannel
          ? _value.realtimeChannel
          : realtimeChannel // ignore: cast_nullable_to_non_nullable
              as RealtimeChannel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfilesModelImpl extends _UserProfilesModel {
  const _$UserProfilesModelImpl(
      {@JsonKey(name: 'id') this.id,
      @JsonKey(name: 'nickname') this.nickname,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'country_code') this.countryCode,
      @JsonKey(name: 'deleted_at') this.deletedAt,
      @JsonKey(name: 'user_agreement') this.userAgreement,
      @JsonKey(name: 'is_admin') required this.isAdmin,
      @JsonKey(name: 'star_candy') required this.starCandy,
      @JsonKey(name: 'star_candy_bonus') required this.starCandyBonus,
      @JsonKey(includeFromJson: false) this.realtimeChannel})
      : super._();

  factory _$UserProfilesModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfilesModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String? id;
  @override
  @JsonKey(name: 'nickname')
  final String? nickname;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'user_agreement')
  final UserAgreement? userAgreement;
  @override
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @override
  @JsonKey(name: 'star_candy')
  final int starCandy;
  @override
  @JsonKey(name: 'star_candy_bonus')
  final int starCandyBonus;
  @override
  @JsonKey(includeFromJson: false)
  final RealtimeChannel? realtimeChannel;

  @override
  String toString() {
    return 'UserProfilesModel(id: $id, nickname: $nickname, avatarUrl: $avatarUrl, countryCode: $countryCode, deletedAt: $deletedAt, userAgreement: $userAgreement, isAdmin: $isAdmin, starCandy: $starCandy, starCandyBonus: $starCandyBonus, realtimeChannel: $realtimeChannel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfilesModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.userAgreement, userAgreement) ||
                other.userAgreement == userAgreement) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.starCandy, starCandy) ||
                other.starCandy == starCandy) &&
            (identical(other.starCandyBonus, starCandyBonus) ||
                other.starCandyBonus == starCandyBonus) &&
            (identical(other.realtimeChannel, realtimeChannel) ||
                other.realtimeChannel == realtimeChannel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      nickname,
      avatarUrl,
      countryCode,
      deletedAt,
      userAgreement,
      isAdmin,
      starCandy,
      starCandyBonus,
      realtimeChannel);

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfilesModelImplCopyWith<_$UserProfilesModelImpl> get copyWith =>
      __$$UserProfilesModelImplCopyWithImpl<_$UserProfilesModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfilesModelImplToJson(
      this,
    );
  }
}

abstract class _UserProfilesModel extends UserProfilesModel {
  const factory _UserProfilesModel(
      {@JsonKey(name: 'id') final String? id,
      @JsonKey(name: 'nickname') final String? nickname,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      @JsonKey(name: 'country_code') final String? countryCode,
      @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
      @JsonKey(name: 'user_agreement') final UserAgreement? userAgreement,
      @JsonKey(name: 'is_admin') required final bool isAdmin,
      @JsonKey(name: 'star_candy') required final int starCandy,
      @JsonKey(name: 'star_candy_bonus') required final int starCandyBonus,
      @JsonKey(includeFromJson: false)
      final RealtimeChannel? realtimeChannel}) = _$UserProfilesModelImpl;
  const _UserProfilesModel._() : super._();

  factory _UserProfilesModel.fromJson(Map<String, dynamic> json) =
      _$UserProfilesModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String? get id;
  @override
  @JsonKey(name: 'nickname')
  String? get nickname;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'country_code')
  String? get countryCode;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(name: 'user_agreement')
  UserAgreement? get userAgreement;
  @override
  @JsonKey(name: 'is_admin')
  bool get isAdmin;
  @override
  @JsonKey(name: 'star_candy')
  int get starCandy;
  @override
  @JsonKey(name: 'star_candy_bonus')
  int get starCandyBonus;
  @override
  @JsonKey(includeFromJson: false)
  RealtimeChannel? get realtimeChannel;

  /// Create a copy of UserProfilesModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfilesModelImplCopyWith<_$UserProfilesModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserAgreement _$UserAgreementFromJson(Map<String, dynamic> json) {
  return _UserAgreement.fromJson(json);
}

/// @nodoc
mixin _$UserAgreement {
  DateTime get terms => throw _privateConstructorUsedError;
  DateTime get privacy => throw _privateConstructorUsedError;

  /// Serializes this UserAgreement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserAgreement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAgreementCopyWith<UserAgreement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAgreementCopyWith<$Res> {
  factory $UserAgreementCopyWith(
          UserAgreement value, $Res Function(UserAgreement) then) =
      _$UserAgreementCopyWithImpl<$Res, UserAgreement>;
  @useResult
  $Res call({DateTime terms, DateTime privacy});
}

/// @nodoc
class _$UserAgreementCopyWithImpl<$Res, $Val extends UserAgreement>
    implements $UserAgreementCopyWith<$Res> {
  _$UserAgreementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAgreement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? terms = null,
    Object? privacy = null,
  }) {
    return _then(_value.copyWith(
      terms: null == terms
          ? _value.terms
          : terms // ignore: cast_nullable_to_non_nullable
              as DateTime,
      privacy: null == privacy
          ? _value.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserAgreementImplCopyWith<$Res>
    implements $UserAgreementCopyWith<$Res> {
  factory _$$UserAgreementImplCopyWith(
          _$UserAgreementImpl value, $Res Function(_$UserAgreementImpl) then) =
      __$$UserAgreementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime terms, DateTime privacy});
}

/// @nodoc
class __$$UserAgreementImplCopyWithImpl<$Res>
    extends _$UserAgreementCopyWithImpl<$Res, _$UserAgreementImpl>
    implements _$$UserAgreementImplCopyWith<$Res> {
  __$$UserAgreementImplCopyWithImpl(
      _$UserAgreementImpl _value, $Res Function(_$UserAgreementImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserAgreement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? terms = null,
    Object? privacy = null,
  }) {
    return _then(_$UserAgreementImpl(
      terms: null == terms
          ? _value.terms
          : terms // ignore: cast_nullable_to_non_nullable
              as DateTime,
      privacy: null == privacy
          ? _value.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAgreementImpl extends _UserAgreement {
  const _$UserAgreementImpl({required this.terms, required this.privacy})
      : super._();

  factory _$UserAgreementImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAgreementImplFromJson(json);

  @override
  final DateTime terms;
  @override
  final DateTime privacy;

  @override
  String toString() {
    return 'UserAgreement(terms: $terms, privacy: $privacy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAgreementImpl &&
            (identical(other.terms, terms) || other.terms == terms) &&
            (identical(other.privacy, privacy) || other.privacy == privacy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, terms, privacy);

  /// Create a copy of UserAgreement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAgreementImplCopyWith<_$UserAgreementImpl> get copyWith =>
      __$$UserAgreementImplCopyWithImpl<_$UserAgreementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAgreementImplToJson(
      this,
    );
  }
}

abstract class _UserAgreement extends UserAgreement {
  const factory _UserAgreement(
      {required final DateTime terms,
      required final DateTime privacy}) = _$UserAgreementImpl;
  const _UserAgreement._() : super._();

  factory _UserAgreement.fromJson(Map<String, dynamic> json) =
      _$UserAgreementImpl.fromJson;

  @override
  DateTime get terms;
  @override
  DateTime get privacy;

  /// Create a copy of UserAgreement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAgreementImplCopyWith<_$UserAgreementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
