// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/vote/vote_request_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoteRequestUser _$VoteRequestUserFromJson(Map<String, dynamic> json) {
  return _VoteRequestUser.fromJson(json);
}

/// @nodoc
mixin _$VoteRequestUser {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_request_id')
  String get voteRequestId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'status')
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VoteRequestUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteRequestUserCopyWith<VoteRequestUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteRequestUserCopyWith<$Res> {
  factory $VoteRequestUserCopyWith(
          VoteRequestUser value, $Res Function(VoteRequestUser) then) =
      _$VoteRequestUserCopyWithImpl<$Res, VoteRequestUser>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_request_id') String voteRequestId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$VoteRequestUserCopyWithImpl<$Res, $Val extends VoteRequestUser>
    implements $VoteRequestUserCopyWith<$Res> {
  _$VoteRequestUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteRequestId = null,
    Object? userId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteRequestId: null == voteRequestId
          ? _value.voteRequestId
          : voteRequestId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VoteRequestUserImplCopyWith<$Res>
    implements $VoteRequestUserCopyWith<$Res> {
  factory _$$VoteRequestUserImplCopyWith(_$VoteRequestUserImpl value,
          $Res Function(_$VoteRequestUserImpl) then) =
      __$$VoteRequestUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_request_id') String voteRequestId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$VoteRequestUserImplCopyWithImpl<$Res>
    extends _$VoteRequestUserCopyWithImpl<$Res, _$VoteRequestUserImpl>
    implements _$$VoteRequestUserImplCopyWith<$Res> {
  __$$VoteRequestUserImplCopyWithImpl(
      _$VoteRequestUserImpl _value, $Res Function(_$VoteRequestUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteRequestId = null,
    Object? userId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$VoteRequestUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteRequestId: null == voteRequestId
          ? _value.voteRequestId
          : voteRequestId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteRequestUserImpl extends _VoteRequestUser {
  const _$VoteRequestUserImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_request_id') required this.voteRequestId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'status') required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt})
      : super._();

  factory _$VoteRequestUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteRequestUserImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'vote_request_id')
  final String voteRequestId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'status')
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VoteRequestUser(id: $id, voteRequestId: $voteRequestId, userId: $userId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteRequestUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteRequestId, voteRequestId) ||
                other.voteRequestId == voteRequestId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, voteRequestId, userId, status, createdAt, updatedAt);

  /// Create a copy of VoteRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteRequestUserImplCopyWith<_$VoteRequestUserImpl> get copyWith =>
      __$$VoteRequestUserImplCopyWithImpl<_$VoteRequestUserImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteRequestUserImplToJson(
      this,
    );
  }
}

abstract class _VoteRequestUser extends VoteRequestUser {
  const factory _VoteRequestUser(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'vote_request_id') required final String voteRequestId,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'status') required final String status,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$VoteRequestUserImpl;
  const _VoteRequestUser._() : super._();

  factory _VoteRequestUser.fromJson(Map<String, dynamic> json) =
      _$VoteRequestUserImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'vote_request_id')
  String get voteRequestId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'status')
  String get status;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of VoteRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteRequestUserImplCopyWith<_$VoteRequestUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
