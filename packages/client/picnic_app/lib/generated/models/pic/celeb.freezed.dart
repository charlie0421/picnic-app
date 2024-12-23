// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/pic/celeb.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CelebModel _$CelebModelFromJson(Map<String, dynamic> json) {
  return _CelebModel.fromJson(json);
}

/// @nodoc
mixin _$CelebModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_ko')
  String get nameKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_en')
  String get nameEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail')
  String? get thumbnail => throw _privateConstructorUsedError;
  @JsonKey(name: 'users')
  List<UserProfilesModel>? get users => throw _privateConstructorUsedError;

  /// Serializes this CelebModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CelebModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CelebModelCopyWith<CelebModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CelebModelCopyWith<$Res> {
  factory $CelebModelCopyWith(
          CelebModel value, $Res Function(CelebModel) then) =
      _$CelebModelCopyWithImpl<$Res, CelebModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'users') List<UserProfilesModel>? users});
}

/// @nodoc
class _$CelebModelCopyWithImpl<$Res, $Val extends CelebModel>
    implements $CelebModelCopyWith<$Res> {
  _$CelebModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CelebModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? thumbnail = freezed,
    Object? users = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      users: freezed == users
          ? _value.users
          : users // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CelebModelImplCopyWith<$Res>
    implements $CelebModelCopyWith<$Res> {
  factory _$$CelebModelImplCopyWith(
          _$CelebModelImpl value, $Res Function(_$CelebModelImpl) then) =
      __$$CelebModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'users') List<UserProfilesModel>? users});
}

/// @nodoc
class __$$CelebModelImplCopyWithImpl<$Res>
    extends _$CelebModelCopyWithImpl<$Res, _$CelebModelImpl>
    implements _$$CelebModelImplCopyWith<$Res> {
  __$$CelebModelImplCopyWithImpl(
      _$CelebModelImpl _value, $Res Function(_$CelebModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CelebModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? thumbnail = freezed,
    Object? users = freezed,
  }) {
    return _then(_$CelebModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      users: freezed == users
          ? _value._users
          : users // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CelebModelImpl extends _CelebModel {
  const _$CelebModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name_ko') required this.nameKo,
      @JsonKey(name: 'name_en') required this.nameEn,
      @JsonKey(name: 'thumbnail') this.thumbnail,
      @JsonKey(name: 'users') final List<UserProfilesModel>? users})
      : _users = users,
        super._();

  factory _$CelebModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CelebModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'name_ko')
  final String nameKo;
  @override
  @JsonKey(name: 'name_en')
  final String nameEn;
  @override
  @JsonKey(name: 'thumbnail')
  final String? thumbnail;
  final List<UserProfilesModel>? _users;
  @override
  @JsonKey(name: 'users')
  List<UserProfilesModel>? get users {
    final value = _users;
    if (value == null) return null;
    if (_users is EqualUnmodifiableListView) return _users;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CelebModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, thumbnail: $thumbnail, users: $users)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CelebModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameKo, nameKo) || other.nameKo == nameKo) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            const DeepCollectionEquality().equals(other._users, _users));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nameKo, nameEn, thumbnail,
      const DeepCollectionEquality().hash(_users));

  /// Create a copy of CelebModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CelebModelImplCopyWith<_$CelebModelImpl> get copyWith =>
      __$$CelebModelImplCopyWithImpl<_$CelebModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CelebModelImplToJson(
      this,
    );
  }
}

abstract class _CelebModel extends CelebModel {
  const factory _CelebModel(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'name_ko') required final String nameKo,
          @JsonKey(name: 'name_en') required final String nameEn,
          @JsonKey(name: 'thumbnail') final String? thumbnail,
          @JsonKey(name: 'users') final List<UserProfilesModel>? users}) =
      _$CelebModelImpl;
  const _CelebModel._() : super._();

  factory _CelebModel.fromJson(Map<String, dynamic> json) =
      _$CelebModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'name_ko')
  String get nameKo;
  @override
  @JsonKey(name: 'name_en')
  String get nameEn;
  @override
  @JsonKey(name: 'thumbnail')
  String? get thumbnail;
  @override
  @JsonKey(name: 'users')
  List<UserProfilesModel>? get users;

  /// Create a copy of CelebModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CelebModelImplCopyWith<_$CelebModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
