// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/qna/qna_thread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QnaThread _$QnaThreadFromJson(Map<String, dynamic> json) {
  return _QnaThread.fromJson(json);
}

/// @nodoc
mixin _$QnaThread {
  int get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this QnaThread to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QnaThread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QnaThreadCopyWith<QnaThread> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QnaThreadCopyWith<$Res> {
  factory $QnaThreadCopyWith(QnaThread value, $Res Function(QnaThread) then) =
      _$QnaThreadCopyWithImpl<$Res, QnaThread>;
  @useResult
  $Res call(
      {int id,
      String userId,
      String title,
      DateTime createdAt,
      DateTime updatedAt,
      String status});
}

/// @nodoc
class _$QnaThreadCopyWithImpl<$Res, $Val extends QnaThread>
    implements $QnaThreadCopyWith<$Res> {
  _$QnaThreadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QnaThread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QnaThreadImplCopyWith<$Res>
    implements $QnaThreadCopyWith<$Res> {
  factory _$$QnaThreadImplCopyWith(
          _$QnaThreadImpl value, $Res Function(_$QnaThreadImpl) then) =
      __$$QnaThreadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String userId,
      String title,
      DateTime createdAt,
      DateTime updatedAt,
      String status});
}

/// @nodoc
class __$$QnaThreadImplCopyWithImpl<$Res>
    extends _$QnaThreadCopyWithImpl<$Res, _$QnaThreadImpl>
    implements _$$QnaThreadImplCopyWith<$Res> {
  __$$QnaThreadImplCopyWithImpl(
      _$QnaThreadImpl _value, $Res Function(_$QnaThreadImpl) _then)
      : super(_value, _then);

  /// Create a copy of QnaThread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? status = null,
  }) {
    return _then(_$QnaThreadImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QnaThreadImpl implements _QnaThread {
  const _$QnaThreadImpl(
      {required this.id,
      required this.userId,
      required this.title,
      required this.createdAt,
      required this.updatedAt,
      required this.status});

  factory _$QnaThreadImpl.fromJson(Map<String, dynamic> json) =>
      _$$QnaThreadImplFromJson(json);

  @override
  final int id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String status;

  @override
  String toString() {
    return 'QnaThread(id: $id, userId: $userId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QnaThreadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, title, createdAt, updatedAt, status);

  /// Create a copy of QnaThread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QnaThreadImplCopyWith<_$QnaThreadImpl> get copyWith =>
      __$$QnaThreadImplCopyWithImpl<_$QnaThreadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QnaThreadImplToJson(
      this,
    );
  }
}

abstract class _QnaThread implements QnaThread {
  const factory _QnaThread(
      {required final int id,
      required final String userId,
      required final String title,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      required final String status}) = _$QnaThreadImpl;

  factory _QnaThread.fromJson(Map<String, dynamic> json) =
      _$QnaThreadImpl.fromJson;

  @override
  int get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String get status;

  /// Create a copy of QnaThread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QnaThreadImplCopyWith<_$QnaThreadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
