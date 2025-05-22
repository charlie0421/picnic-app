// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/pic/comment_like.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserCommentLikeModel _$UserCommentLikeModelFromJson(Map<String, dynamic> json) {
  return _UserCommentLikeModel.fromJson(json);
}

/// @nodoc
mixin _$UserCommentLikeModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

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
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'user_id') int userId,
      @JsonKey(name: 'created_at') DateTime createdAt});
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
    Object? userId = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
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
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'user_id') int userId,
      @JsonKey(name: 'created_at') DateTime createdAt});
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
    Object? userId = null,
    Object? createdAt = null,
  }) {
    return _then(_$UserCommentLikeModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserCommentLikeModelImpl extends _UserCommentLikeModel {
  const _$UserCommentLikeModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'created_at') required this.createdAt})
      : super._();

  factory _$UserCommentLikeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserCommentLikeModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'UserCommentLikeModel(id: $id, userId: $userId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserCommentLikeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, createdAt);

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
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'user_id') required final int userId,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$UserCommentLikeModelImpl;
  const _UserCommentLikeModel._() : super._();

  factory _UserCommentLikeModel.fromJson(Map<String, dynamic> json) =
      _$UserCommentLikeModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of UserCommentLikeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserCommentLikeModelImplCopyWith<_$UserCommentLikeModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
