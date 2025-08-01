// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/qna/qna_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QnaAttachment _$QnaAttachmentFromJson(Map<String, dynamic> json) {
  return _QnaAttachment.fromJson(json);
}

/// @nodoc
mixin _$QnaAttachment {
  int get id => throw _privateConstructorUsedError;
  int get messageId => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  String? get fileType => throw _privateConstructorUsedError;
  int? get fileSize => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this QnaAttachment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QnaAttachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QnaAttachmentCopyWith<QnaAttachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QnaAttachmentCopyWith<$Res> {
  factory $QnaAttachmentCopyWith(
          QnaAttachment value, $Res Function(QnaAttachment) then) =
      _$QnaAttachmentCopyWithImpl<$Res, QnaAttachment>;
  @useResult
  $Res call(
      {int id,
      int messageId,
      String fileName,
      String filePath,
      String? fileType,
      int? fileSize,
      DateTime createdAt});
}

/// @nodoc
class _$QnaAttachmentCopyWithImpl<$Res, $Val extends QnaAttachment>
    implements $QnaAttachmentCopyWith<$Res> {
  _$QnaAttachmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QnaAttachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = freezed,
    Object? fileSize = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as int,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QnaAttachmentImplCopyWith<$Res>
    implements $QnaAttachmentCopyWith<$Res> {
  factory _$$QnaAttachmentImplCopyWith(
          _$QnaAttachmentImpl value, $Res Function(_$QnaAttachmentImpl) then) =
      __$$QnaAttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int messageId,
      String fileName,
      String filePath,
      String? fileType,
      int? fileSize,
      DateTime createdAt});
}

/// @nodoc
class __$$QnaAttachmentImplCopyWithImpl<$Res>
    extends _$QnaAttachmentCopyWithImpl<$Res, _$QnaAttachmentImpl>
    implements _$$QnaAttachmentImplCopyWith<$Res> {
  __$$QnaAttachmentImplCopyWithImpl(
      _$QnaAttachmentImpl _value, $Res Function(_$QnaAttachmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of QnaAttachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = freezed,
    Object? fileSize = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$QnaAttachmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as int,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: freezed == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QnaAttachmentImpl implements _QnaAttachment {
  const _$QnaAttachmentImpl(
      {required this.id,
      required this.messageId,
      required this.fileName,
      required this.filePath,
      this.fileType,
      this.fileSize,
      required this.createdAt});

  factory _$QnaAttachmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$QnaAttachmentImplFromJson(json);

  @override
  final int id;
  @override
  final int messageId;
  @override
  final String fileName;
  @override
  final String filePath;
  @override
  final String? fileType;
  @override
  final int? fileSize;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'QnaAttachment(id: $id, messageId: $messageId, fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QnaAttachmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, messageId, fileName,
      filePath, fileType, fileSize, createdAt);

  /// Create a copy of QnaAttachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QnaAttachmentImplCopyWith<_$QnaAttachmentImpl> get copyWith =>
      __$$QnaAttachmentImplCopyWithImpl<_$QnaAttachmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QnaAttachmentImplToJson(
      this,
    );
  }
}

abstract class _QnaAttachment implements QnaAttachment {
  const factory _QnaAttachment(
      {required final int id,
      required final int messageId,
      required final String fileName,
      required final String filePath,
      final String? fileType,
      final int? fileSize,
      required final DateTime createdAt}) = _$QnaAttachmentImpl;

  factory _QnaAttachment.fromJson(Map<String, dynamic> json) =
      _$QnaAttachmentImpl.fromJson;

  @override
  int get id;
  @override
  int get messageId;
  @override
  String get fileName;
  @override
  String get filePath;
  @override
  String? get fileType;
  @override
  int? get fileSize;
  @override
  DateTime get createdAt;

  /// Create a copy of QnaAttachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QnaAttachmentImplCopyWith<_$QnaAttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
