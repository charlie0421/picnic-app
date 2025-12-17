// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/qna/qna_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QnaAttachment {

 int get id; int get messageId; String get fileName; String get filePath; String? get fileType; int? get fileSize; DateTime get createdAt;
/// Create a copy of QnaAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QnaAttachmentCopyWith<QnaAttachment> get copyWith => _$QnaAttachmentCopyWithImpl<QnaAttachment>(this as QnaAttachment, _$identity);

  /// Serializes this QnaAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QnaAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,fileName,filePath,fileType,fileSize,createdAt);

@override
String toString() {
  return 'QnaAttachment(id: $id, messageId: $messageId, fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $QnaAttachmentCopyWith<$Res>  {
  factory $QnaAttachmentCopyWith(QnaAttachment value, $Res Function(QnaAttachment) _then) = _$QnaAttachmentCopyWithImpl;
@useResult
$Res call({
 int id, int messageId, String fileName, String filePath, String? fileType, int? fileSize, DateTime createdAt
});




}
/// @nodoc
class _$QnaAttachmentCopyWithImpl<$Res>
    implements $QnaAttachmentCopyWith<$Res> {
  _$QnaAttachmentCopyWithImpl(this._self, this._then);

  final QnaAttachment _self;
  final $Res Function(QnaAttachment) _then;

/// Create a copy of QnaAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? messageId = null,Object? fileName = null,Object? filePath = null,Object? fileType = freezed,Object? fileSize = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileType: freezed == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [QnaAttachment].
extension QnaAttachmentPatterns on QnaAttachment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QnaAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QnaAttachment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QnaAttachment value)  $default,){
final _that = this;
switch (_that) {
case _QnaAttachment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QnaAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _QnaAttachment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int messageId,  String fileName,  String filePath,  String? fileType,  int? fileSize,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QnaAttachment() when $default != null:
return $default(_that.id,_that.messageId,_that.fileName,_that.filePath,_that.fileType,_that.fileSize,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int messageId,  String fileName,  String filePath,  String? fileType,  int? fileSize,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _QnaAttachment():
return $default(_that.id,_that.messageId,_that.fileName,_that.filePath,_that.fileType,_that.fileSize,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int messageId,  String fileName,  String filePath,  String? fileType,  int? fileSize,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _QnaAttachment() when $default != null:
return $default(_that.id,_that.messageId,_that.fileName,_that.filePath,_that.fileType,_that.fileSize,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QnaAttachment implements QnaAttachment {
  const _QnaAttachment({required this.id, required this.messageId, required this.fileName, required this.filePath, this.fileType, this.fileSize, required this.createdAt});
  factory _QnaAttachment.fromJson(Map<String, dynamic> json) => _$QnaAttachmentFromJson(json);

@override final  int id;
@override final  int messageId;
@override final  String fileName;
@override final  String filePath;
@override final  String? fileType;
@override final  int? fileSize;
@override final  DateTime createdAt;

/// Create a copy of QnaAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QnaAttachmentCopyWith<_QnaAttachment> get copyWith => __$QnaAttachmentCopyWithImpl<_QnaAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QnaAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QnaAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,fileName,filePath,fileType,fileSize,createdAt);

@override
String toString() {
  return 'QnaAttachment(id: $id, messageId: $messageId, fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QnaAttachmentCopyWith<$Res> implements $QnaAttachmentCopyWith<$Res> {
  factory _$QnaAttachmentCopyWith(_QnaAttachment value, $Res Function(_QnaAttachment) _then) = __$QnaAttachmentCopyWithImpl;
@override @useResult
$Res call({
 int id, int messageId, String fileName, String filePath, String? fileType, int? fileSize, DateTime createdAt
});




}
/// @nodoc
class __$QnaAttachmentCopyWithImpl<$Res>
    implements _$QnaAttachmentCopyWith<$Res> {
  __$QnaAttachmentCopyWithImpl(this._self, this._then);

  final _QnaAttachment _self;
  final $Res Function(_QnaAttachment) _then;

/// Create a copy of QnaAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? messageId = null,Object? fileName = null,Object? filePath = null,Object? fileType = freezed,Object? fileSize = freezed,Object? createdAt = null,}) {
  return _then(_QnaAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileType: freezed == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
