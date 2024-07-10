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

/// @nodoc
mixin _$UserProfilesListModel {
  List<UserProfilesModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $UserProfilesListModelCopyWith<UserProfilesListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfilesListModelCopyWith<$Res> {
  factory $UserProfilesListModelCopyWith(UserProfilesListModel value,
          $Res Function(UserProfilesListModel) then) =
      _$UserProfilesListModelCopyWithImpl<$Res, UserProfilesListModel>;
  @useResult
  $Res call({List<UserProfilesModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$UserProfilesListModelCopyWithImpl<$Res,
        $Val extends UserProfilesListModel>
    implements $UserProfilesListModelCopyWith<$Res> {
  _$UserProfilesListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MetaModelCopyWith<$Res> get meta {
    return $MetaModelCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfilesListModelImplCopyWith<$Res>
    implements $UserProfilesListModelCopyWith<$Res> {
  factory _$$UserProfilesListModelImplCopyWith(
          _$UserProfilesListModelImpl value,
          $Res Function(_$UserProfilesListModelImpl) then) =
      __$$UserProfilesListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<UserProfilesModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$UserProfilesListModelImplCopyWithImpl<$Res>
    extends _$UserProfilesListModelCopyWithImpl<$Res,
        _$UserProfilesListModelImpl>
    implements _$$UserProfilesListModelImplCopyWith<$Res> {
  __$$UserProfilesListModelImplCopyWithImpl(_$UserProfilesListModelImpl _value,
      $Res Function(_$UserProfilesListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$UserProfilesListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc

class _$UserProfilesListModelImpl extends _UserProfilesListModel {
  const _$UserProfilesListModelImpl(
      {required final List<UserProfilesModel> items, required this.meta})
      : _items = items,
        super._();

  final List<UserProfilesModel> _items;
  @override
  List<UserProfilesModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'UserProfilesListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfilesListModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), meta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfilesListModelImplCopyWith<_$UserProfilesListModelImpl>
      get copyWith => __$$UserProfilesListModelImplCopyWithImpl<
          _$UserProfilesListModelImpl>(this, _$identity);
}

abstract class _UserProfilesListModel extends UserProfilesListModel {
  const factory _UserProfilesListModel(
      {required final List<UserProfilesModel> items,
      required final MetaModel meta}) = _$UserProfilesListModelImpl;
  const _UserProfilesListModel._() : super._();

  @override
  List<UserProfilesModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$UserProfilesListModelImplCopyWith<_$UserProfilesListModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

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
      int star_candy,
      int star_candy_bonus});
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
      int star_candy,
      int star_candy_bonus});
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
  final int star_candy;
  @override
  final int star_candy_bonus;

  @override
  String toString() {
    return 'UserProfilesModel(id: $id, nickname: $nickname, avatar_url: $avatar_url, country_code: $country_code, deleted_at: $deleted_at, star_candy: $star_candy, star_candy_bonus: $star_candy_bonus)';
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
            (identical(other.star_candy, star_candy) ||
                other.star_candy == star_candy) &&
            (identical(other.star_candy_bonus, star_candy_bonus) ||
                other.star_candy_bonus == star_candy_bonus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, nickname, avatar_url,
      country_code, deleted_at, star_candy, star_candy_bonus);

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
  int get star_candy;
  @override
  int get star_candy_bonus;
  @override
  @JsonKey(ignore: true)
  _$$UserProfilesModelImplCopyWith<_$UserProfilesModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
