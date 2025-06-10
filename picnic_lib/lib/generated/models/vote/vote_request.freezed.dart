// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/vote/vote_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoteRequest _$VoteRequestFromJson(Map<String, dynamic> json) {
  return _VoteRequest.fromJson(json);
}

/// @nodoc
mixin _$VoteRequest {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_id')
  String get voteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VoteRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteRequestCopyWith<VoteRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteRequestCopyWith<$Res> {
  factory $VoteRequestCopyWith(
          VoteRequest value, $Res Function(VoteRequest) then) =
      _$VoteRequestCopyWithImpl<$Res, VoteRequest>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_id') String voteId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$VoteRequestCopyWithImpl<$Res, $Val extends VoteRequest>
    implements $VoteRequestCopyWith<$Res> {
  _$VoteRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$VoteRequestImplCopyWith<$Res>
    implements $VoteRequestCopyWith<$Res> {
  factory _$$VoteRequestImplCopyWith(
          _$VoteRequestImpl value, $Res Function(_$VoteRequestImpl) then) =
      __$$VoteRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_id') String voteId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$VoteRequestImplCopyWithImpl<$Res>
    extends _$VoteRequestCopyWithImpl<$Res, _$VoteRequestImpl>
    implements _$$VoteRequestImplCopyWith<$Res> {
  __$$VoteRequestImplCopyWithImpl(
      _$VoteRequestImpl _value, $Res Function(_$VoteRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$VoteRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
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
class _$VoteRequestImpl extends _VoteRequest {
  const _$VoteRequestImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_id') required this.voteId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt})
      : super._();

  factory _$VoteRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteRequestImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'vote_id')
  final String voteId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VoteRequest(id: $id, voteId: $voteId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteId, voteId) || other.voteId == voteId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, voteId, createdAt, updatedAt);

  /// Create a copy of VoteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteRequestImplCopyWith<_$VoteRequestImpl> get copyWith =>
      __$$VoteRequestImplCopyWithImpl<_$VoteRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteRequestImplToJson(
      this,
    );
  }
}

abstract class _VoteRequest extends VoteRequest {
  const factory _VoteRequest(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'vote_id') required final String voteId,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$VoteRequestImpl;
  const _VoteRequest._() : super._();

  factory _VoteRequest.fromJson(Map<String, dynamic> json) =
      _$VoteRequestImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'vote_id')
  String get voteId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of VoteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteRequestImplCopyWith<_$VoteRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
