// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/qna/qna_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QnaMessage _$QnaMessageFromJson(Map<String, dynamic> json) {
  return _QnaMessage.fromJson(json);
}

/// @nodoc
mixin _$QnaMessage {
  int get id => throw _privateConstructorUsedError;
  int get threadId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get isAdminMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'qna_attachments')
  List<QnaAttachment> get attachments => throw _privateConstructorUsedError;

  /// Serializes this QnaMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QnaMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QnaMessageCopyWith<QnaMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QnaMessageCopyWith<$Res> {
  factory $QnaMessageCopyWith(
          QnaMessage value, $Res Function(QnaMessage) then) =
      _$QnaMessageCopyWithImpl<$Res, QnaMessage>;
  @useResult
  $Res call(
      {int id,
      int threadId,
      String userId,
      String? content,
      DateTime createdAt,
      bool isAdminMessage,
      @JsonKey(name: 'qna_attachments') List<QnaAttachment> attachments});
}

/// @nodoc
class _$QnaMessageCopyWithImpl<$Res, $Val extends QnaMessage>
    implements $QnaMessageCopyWith<$Res> {
  _$QnaMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QnaMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? threadId = null,
    Object? userId = null,
    Object? content = freezed,
    Object? createdAt = null,
    Object? isAdminMessage = null,
    Object? attachments = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAdminMessage: null == isAdminMessage
          ? _value.isAdminMessage
          : isAdminMessage // ignore: cast_nullable_to_non_nullable
              as bool,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<QnaAttachment>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QnaMessageImplCopyWith<$Res>
    implements $QnaMessageCopyWith<$Res> {
  factory _$$QnaMessageImplCopyWith(
          _$QnaMessageImpl value, $Res Function(_$QnaMessageImpl) then) =
      __$$QnaMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int threadId,
      String userId,
      String? content,
      DateTime createdAt,
      bool isAdminMessage,
      @JsonKey(name: 'qna_attachments') List<QnaAttachment> attachments});
}

/// @nodoc
class __$$QnaMessageImplCopyWithImpl<$Res>
    extends _$QnaMessageCopyWithImpl<$Res, _$QnaMessageImpl>
    implements _$$QnaMessageImplCopyWith<$Res> {
  __$$QnaMessageImplCopyWithImpl(
      _$QnaMessageImpl _value, $Res Function(_$QnaMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of QnaMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? threadId = null,
    Object? userId = null,
    Object? content = freezed,
    Object? createdAt = null,
    Object? isAdminMessage = null,
    Object? attachments = null,
  }) {
    return _then(_$QnaMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAdminMessage: null == isAdminMessage
          ? _value.isAdminMessage
          : isAdminMessage // ignore: cast_nullable_to_non_nullable
              as bool,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<QnaAttachment>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$QnaMessageImpl implements _QnaMessage {
  const _$QnaMessageImpl(
      {required this.id,
      required this.threadId,
      required this.userId,
      this.content,
      required this.createdAt,
      required this.isAdminMessage,
      @JsonKey(name: 'qna_attachments')
      final List<QnaAttachment> attachments = const []})
      : _attachments = attachments;

  factory _$QnaMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$QnaMessageImplFromJson(json);

  @override
  final int id;
  @override
  final int threadId;
  @override
  final String userId;
  @override
  final String? content;
  @override
  final DateTime createdAt;
  @override
  final bool isAdminMessage;
  final List<QnaAttachment> _attachments;
  @override
  @JsonKey(name: 'qna_attachments')
  List<QnaAttachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  String toString() {
    return 'QnaMessage(id: $id, threadId: $threadId, userId: $userId, content: $content, createdAt: $createdAt, isAdminMessage: $isAdminMessage, attachments: $attachments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QnaMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.threadId, threadId) ||
                other.threadId == threadId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isAdminMessage, isAdminMessage) ||
                other.isAdminMessage == isAdminMessage) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      threadId,
      userId,
      content,
      createdAt,
      isAdminMessage,
      const DeepCollectionEquality().hash(_attachments));

  /// Create a copy of QnaMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QnaMessageImplCopyWith<_$QnaMessageImpl> get copyWith =>
      __$$QnaMessageImplCopyWithImpl<_$QnaMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QnaMessageImplToJson(
      this,
    );
  }
}

abstract class _QnaMessage implements QnaMessage {
  const factory _QnaMessage(
      {required final int id,
      required final int threadId,
      required final String userId,
      final String? content,
      required final DateTime createdAt,
      required final bool isAdminMessage,
      @JsonKey(name: 'qna_attachments')
      final List<QnaAttachment> attachments}) = _$QnaMessageImpl;

  factory _QnaMessage.fromJson(Map<String, dynamic> json) =
      _$QnaMessageImpl.fromJson;

  @override
  int get id;
  @override
  int get threadId;
  @override
  String get userId;
  @override
  String? get content;
  @override
  DateTime get createdAt;
  @override
  bool get isAdminMessage;
  @override
  @JsonKey(name: 'qna_attachments')
  List<QnaAttachment> get attachments;

  /// Create a copy of QnaMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QnaMessageImplCopyWith<_$QnaMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
