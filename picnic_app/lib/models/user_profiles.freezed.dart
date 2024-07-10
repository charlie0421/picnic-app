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
  String? get id => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get avatar_url => throw _privateConstructorUsedError;
  String? get country_code => throw _privateConstructorUsedError;
  DateTime? get deleted_at => throw _privateConstructorUsedError;
  UserAgreement? get user_agreement => throw _privateConstructorUsedError;
  int get star_candy => throw _privateConstructorUsedError;
  int get star_candy_bonus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {String? id,
      String? nickname,
      String? avatar_url,
      String? country_code,
      DateTime? deleted_at,
      UserAgreement? user_agreement,
      int star_candy,
      int star_candy_bonus});

  $UserAgreementCopyWith<$Res>? get user_agreement;
}

/// @nodoc
class _$UserProfilesModelCopyWithImpl<$Res, $Val extends UserProfilesModel>
    implements $UserProfilesModelCopyWith<$Res> {
  _$UserProfilesModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nickname = freezed,
    Object? avatar_url = freezed,
    Object? country_code = freezed,
    Object? deleted_at = freezed,
    Object? user_agreement = freezed,
    Object? star_candy = null,
    Object? star_candy_bonus = null,
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
      avatar_url: freezed == avatar_url
          ? _value.avatar_url
          : avatar_url // ignore: cast_nullable_to_non_nullable
              as String?,
      country_code: freezed == country_code
          ? _value.country_code
          : country_code // ignore: cast_nullable_to_non_nullable
              as String?,
      deleted_at: freezed == deleted_at
          ? _value.deleted_at
          : deleted_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      user_agreement: freezed == user_agreement
          ? _value.user_agreement
          : user_agreement // ignore: cast_nullable_to_non_nullable
              as UserAgreement?,
      star_candy: null == star_candy
          ? _value.star_candy
          : star_candy // ignore: cast_nullable_to_non_nullable
              as int,
      star_candy_bonus: null == star_candy_bonus
          ? _value.star_candy_bonus
          : star_candy_bonus // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserAgreementCopyWith<$Res>? get user_agreement {
    if (_value.user_agreement == null) {
      return null;
    }

    return $UserAgreementCopyWith<$Res>(_value.user_agreement!, (value) {
      return _then(_value.copyWith(user_agreement: value) as $Val);
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
      {String? id,
      String? nickname,
      String? avatar_url,
      String? country_code,
      DateTime? deleted_at,
      UserAgreement? user_agreement,
      int star_candy,
      int star_candy_bonus});

  @override
  $UserAgreementCopyWith<$Res>? get user_agreement;
}

/// @nodoc
class __$$UserProfilesModelImplCopyWithImpl<$Res>
    extends _$UserProfilesModelCopyWithImpl<$Res, _$UserProfilesModelImpl>
    implements _$$UserProfilesModelImplCopyWith<$Res> {
  __$$UserProfilesModelImplCopyWithImpl(_$UserProfilesModelImpl _value,
      $Res Function(_$UserProfilesModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? nickname = freezed,
    Object? avatar_url = freezed,
    Object? country_code = freezed,
    Object? deleted_at = freezed,
    Object? user_agreement = freezed,
    Object? star_candy = null,
    Object? star_candy_bonus = null,
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
      avatar_url: freezed == avatar_url
          ? _value.avatar_url
          : avatar_url // ignore: cast_nullable_to_non_nullable
              as String?,
      country_code: freezed == country_code
          ? _value.country_code
          : country_code // ignore: cast_nullable_to_non_nullable
              as String?,
      deleted_at: freezed == deleted_at
          ? _value.deleted_at
          : deleted_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      user_agreement: freezed == user_agreement
          ? _value.user_agreement
          : user_agreement // ignore: cast_nullable_to_non_nullable
              as UserAgreement?,
      star_candy: null == star_candy
          ? _value.star_candy
          : star_candy // ignore: cast_nullable_to_non_nullable
              as int,
      star_candy_bonus: null == star_candy_bonus
          ? _value.star_candy_bonus
          : star_candy_bonus // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfilesModelImpl extends _UserProfilesModel {
  const _$UserProfilesModelImpl(
      {this.id,
      this.nickname,
      this.avatar_url,
      this.country_code,
      this.deleted_at,
      this.user_agreement,
      required this.star_candy,
      required this.star_candy_bonus})
      : super._();

  factory _$UserProfilesModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfilesModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? nickname;
  @override
  final String? avatar_url;
  @override
  final String? country_code;
  @override
  final DateTime? deleted_at;
  @override
  final UserAgreement? user_agreement;
  @override
  final int star_candy;
  @override
  final int star_candy_bonus;

  @override
  String toString() {
    return 'UserProfilesModel(id: $id, nickname: $nickname, avatar_url: $avatar_url, country_code: $country_code, deleted_at: $deleted_at, user_agreement: $user_agreement, star_candy: $star_candy, star_candy_bonus: $star_candy_bonus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfilesModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.avatar_url, avatar_url) ||
                other.avatar_url == avatar_url) &&
            (identical(other.country_code, country_code) ||
                other.country_code == country_code) &&
            (identical(other.deleted_at, deleted_at) ||
                other.deleted_at == deleted_at) &&
            (identical(other.user_agreement, user_agreement) ||
                other.user_agreement == user_agreement) &&
            (identical(other.star_candy, star_candy) ||
                other.star_candy == star_candy) &&
            (identical(other.star_candy_bonus, star_candy_bonus) ||
                other.star_candy_bonus == star_candy_bonus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, nickname, avatar_url,
      country_code, deleted_at, user_agreement, star_candy, star_candy_bonus);

  @JsonKey(ignore: true)
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
      {final String? id,
      final String? nickname,
      final String? avatar_url,
      final String? country_code,
      final DateTime? deleted_at,
      final UserAgreement? user_agreement,
      required final int star_candy,
      required final int star_candy_bonus}) = _$UserProfilesModelImpl;
  const _UserProfilesModel._() : super._();

  factory _UserProfilesModel.fromJson(Map<String, dynamic> json) =
      _$UserProfilesModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get nickname;
  @override
  String? get avatar_url;
  @override
  String? get country_code;
  @override
  DateTime? get deleted_at;
  @override
  UserAgreement? get user_agreement;
  @override
  int get star_candy;
  @override
  int get star_candy_bonus;
  @override
  @JsonKey(ignore: true)
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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, terms, privacy);

  @JsonKey(ignore: true)
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
  @override
  @JsonKey(ignore: true)
  _$$UserAgreementImplCopyWith<_$UserAgreementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
