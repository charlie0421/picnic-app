// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_like.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserCommentLikeListModel _$UserCommentLikeListModelFromJson(
    Map<String, dynamic> json) {
  return _UserCommentLikeListModel.fromJson(json);
}

/// @nodoc
mixin _$UserCommentLikeListModel {
  List<UserCommentLikeModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  /// Serializes this UserCommentLikeListModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCommentLikeListModelCopyWith<UserCommentLikeListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCommentLikeListModelCopyWith<$Res> {
  factory $UserCommentLikeListModelCopyWith(UserCommentLikeListModel value,
          $Res Function(UserCommentLikeListModel) then) =
      _$UserCommentLikeListModelCopyWithImpl<$Res, UserCommentLikeListModel>;
  @useResult
  $Res call({List<UserCommentLikeModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$UserCommentLikeListModelCopyWithImpl<$Res,
        $Val extends UserCommentLikeListModel>
    implements $UserCommentLikeListModelCopyWith<$Res> {
  _$UserCommentLikeListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
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
              as List<UserCommentLikeModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ) as $Val);
  }

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MetaModelCopyWith<$Res> get meta {
    return $MetaModelCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserCommentLikeListModelImplCopyWith<$Res>
    implements $UserCommentLikeListModelCopyWith<$Res> {
  factory _$$UserCommentLikeListModelImplCopyWith(
          _$UserCommentLikeListModelImpl value,
          $Res Function(_$UserCommentLikeListModelImpl) then) =
      __$$UserCommentLikeListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<UserCommentLikeModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$UserCommentLikeListModelImplCopyWithImpl<$Res>
    extends _$UserCommentLikeListModelCopyWithImpl<$Res,
        _$UserCommentLikeListModelImpl>
    implements _$$UserCommentLikeListModelImplCopyWith<$Res> {
  __$$UserCommentLikeListModelImplCopyWithImpl(
      _$UserCommentLikeListModelImpl _value,
      $Res Function(_$UserCommentLikeListModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$UserCommentLikeListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<UserCommentLikeModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCommentLikeListModelImpl extends _UserCommentLikeListModel {
  const _$UserCommentLikeListModelImpl(
      {required final List<UserCommentLikeModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$UserCommentLikeListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCommentLikeListModelImplFromJson(json);

  final List<UserCommentLikeModel> _items;
  @override
  List<UserCommentLikeModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'UserCommentLikeListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCommentLikeListModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), meta);

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCommentLikeListModelImplCopyWith<_$UserCommentLikeListModelImpl>
      get copyWith => __$$UserCommentLikeListModelImplCopyWithImpl<
          _$UserCommentLikeListModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCommentLikeListModelImplToJson(
      this,
    );
  }
}

abstract class _UserCommentLikeListModel extends UserCommentLikeListModel {
  const factory _UserCommentLikeListModel(
      {required final List<UserCommentLikeModel> items,
      required final MetaModel meta}) = _$UserCommentLikeListModelImpl;
  const _UserCommentLikeListModel._() : super._();

  factory _UserCommentLikeListModel.fromJson(Map<String, dynamic> json) =
      _$UserCommentLikeListModelImpl.fromJson;

  @override
  List<UserCommentLikeModel> get items;
  @override
  MetaModel get meta;

  /// Create a copy of UserCommentLikeListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCommentLikeListModelImplCopyWith<_$UserCommentLikeListModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UserCommentLikeModel _$UserCommentLikeModelFromJson(Map<String, dynamic> json) {
  return _UserCommentLikeModel.fromJson(json);
}

/// @nodoc
mixin _$UserCommentLikeModel {
  int get id => throw _privateConstructorUsedError;
  int get user_id => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;

  /// Serializes this UserCommentLikeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCommentLikeModelCopyWith<UserCommentLikeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCommentLikeModelCopyWith<$Res> {
  factory $UserCommentLikeModelCopyWith(UserCommentLikeModel value,
          $Res Function(UserCommentLikeModel) then) =
      _$UserCommentLikeModelCopyWithImpl<$Res, UserCommentLikeModel>;
  @useResult
  $Res call({int id, int user_id, DateTime created_at});
}

/// @nodoc
class _$UserCommentLikeModelCopyWithImpl<$Res,
        $Val extends UserCommentLikeModel>
    implements $UserCommentLikeModelCopyWith<$Res> {
  _$UserCommentLikeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? created_at = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserCommentLikeModelImplCopyWith<$Res>
    implements $UserCommentLikeModelCopyWith<$Res> {
  factory _$$UserCommentLikeModelImplCopyWith(_$UserCommentLikeModelImpl value,
          $Res Function(_$UserCommentLikeModelImpl) then) =
      __$$UserCommentLikeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, int user_id, DateTime created_at});
}

/// @nodoc
class __$$UserCommentLikeModelImplCopyWithImpl<$Res>
    extends _$UserCommentLikeModelCopyWithImpl<$Res, _$UserCommentLikeModelImpl>
    implements _$$UserCommentLikeModelImplCopyWith<$Res> {
  __$$UserCommentLikeModelImplCopyWithImpl(_$UserCommentLikeModelImpl _value,
      $Res Function(_$UserCommentLikeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? created_at = null,
  }) {
    return _then(_$UserCommentLikeModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCommentLikeModelImpl extends _UserCommentLikeModel {
  const _$UserCommentLikeModelImpl(
      {required this.id, required this.user_id, required this.created_at})
      : super._();

  factory _$UserCommentLikeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCommentLikeModelImplFromJson(json);

  @override
  final int id;
  @override
  final int user_id;
  @override
  final DateTime created_at;

  @override
  String toString() {
    return 'UserCommentLikeModel(id: $id, user_id: $user_id, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCommentLikeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, user_id, created_at);

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserCommentLikeModelImplCopyWith<_$UserCommentLikeModelImpl>
      get copyWith =>
          __$$UserCommentLikeModelImplCopyWithImpl<_$UserCommentLikeModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserCommentLikeModelImplToJson(
      this,
    );
  }
}

abstract class _UserCommentLikeModel extends UserCommentLikeModel {
  const factory _UserCommentLikeModel(
      {required final int id,
      required final int user_id,
      required final DateTime created_at}) = _$UserCommentLikeModelImpl;
  const _UserCommentLikeModel._() : super._();

  factory _UserCommentLikeModel.fromJson(Map<String, dynamic> json) =
      _$UserCommentLikeModelImpl.fromJson;

  @override
  int get id;
  @override
  int get user_id;
  @override
  DateTime get created_at;

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCommentLikeModelImplCopyWith<_$UserCommentLikeModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
