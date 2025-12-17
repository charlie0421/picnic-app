// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/qna/qna_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QnaMessage {

 int get id; int get threadId; String get userId; String? get content; DateTime get createdAt; bool get isAdminMessage;@JsonKey(name: 'qna_attachments') List<QnaAttachment> get attachments;
/// Create a copy of QnaMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QnaMessageCopyWith<QnaMessage> get copyWith => _$QnaMessageCopyWithImpl<QnaMessage>(this as QnaMessage, _$identity);

  /// Serializes this QnaMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QnaMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isAdminMessage, isAdminMessage) || other.isAdminMessage == isAdminMessage)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,threadId,userId,content,createdAt,isAdminMessage,const DeepCollectionEquality().hash(attachments));

@override
String toString() {
  return 'QnaMessage(id: $id, threadId: $threadId, userId: $userId, content: $content, createdAt: $createdAt, isAdminMessage: $isAdminMessage, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $QnaMessageCopyWith<$Res>  {
  factory $QnaMessageCopyWith(QnaMessage value, $Res Function(QnaMessage) _then) = _$QnaMessageCopyWithImpl;
@useResult
$Res call({
 int id, int threadId, String userId, String? content, DateTime createdAt, bool isAdminMessage,@JsonKey(name: 'qna_attachments') List<QnaAttachment> attachments
});




}
/// @nodoc
class _$QnaMessageCopyWithImpl<$Res>
    implements $QnaMessageCopyWith<$Res> {
  _$QnaMessageCopyWithImpl(this._self, this._then);

  final QnaMessage _self;
  final $Res Function(QnaMessage) _then;

/// Create a copy of QnaMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? threadId = null,Object? userId = null,Object? content = freezed,Object? createdAt = null,Object? isAdminMessage = null,Object? attachments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isAdminMessage: null == isAdminMessage ? _self.isAdminMessage : isAdminMessage // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<QnaAttachment>,
  ));
}

}


/// Adds pattern-matching-related methods to [QnaMessage].
extension QnaMessagePatterns on QnaMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QnaMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QnaMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QnaMessage value)  $default,){
final _that = this;
switch (_that) {
case _QnaMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QnaMessage value)?  $default,){
final _that = this;
switch (_that) {
case _QnaMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int threadId,  String userId,  String? content,  DateTime createdAt,  bool isAdminMessage, @JsonKey(name: 'qna_attachments')  List<QnaAttachment> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QnaMessage() when $default != null:
return $default(_that.id,_that.threadId,_that.userId,_that.content,_that.createdAt,_that.isAdminMessage,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int threadId,  String userId,  String? content,  DateTime createdAt,  bool isAdminMessage, @JsonKey(name: 'qna_attachments')  List<QnaAttachment> attachments)  $default,) {final _that = this;
switch (_that) {
case _QnaMessage():
return $default(_that.id,_that.threadId,_that.userId,_that.content,_that.createdAt,_that.isAdminMessage,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int threadId,  String userId,  String? content,  DateTime createdAt,  bool isAdminMessage, @JsonKey(name: 'qna_attachments')  List<QnaAttachment> attachments)?  $default,) {final _that = this;
switch (_that) {
case _QnaMessage() when $default != null:
return $default(_that.id,_that.threadId,_that.userId,_that.content,_that.createdAt,_that.isAdminMessage,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _QnaMessage implements QnaMessage {
  const _QnaMessage({required this.id, required this.threadId, required this.userId, this.content, required this.createdAt, required this.isAdminMessage, @JsonKey(name: 'qna_attachments') final  List<QnaAttachment> attachments = const []}): _attachments = attachments;
  factory _QnaMessage.fromJson(Map<String, dynamic> json) => _$QnaMessageFromJson(json);

@override final  int id;
@override final  int threadId;
@override final  String userId;
@override final  String? content;
@override final  DateTime createdAt;
@override final  bool isAdminMessage;
 final  List<QnaAttachment> _attachments;
@override@JsonKey(name: 'qna_attachments') List<QnaAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of QnaMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QnaMessageCopyWith<_QnaMessage> get copyWith => __$QnaMessageCopyWithImpl<_QnaMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QnaMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QnaMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isAdminMessage, isAdminMessage) || other.isAdminMessage == isAdminMessage)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,threadId,userId,content,createdAt,isAdminMessage,const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'QnaMessage(id: $id, threadId: $threadId, userId: $userId, content: $content, createdAt: $createdAt, isAdminMessage: $isAdminMessage, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$QnaMessageCopyWith<$Res> implements $QnaMessageCopyWith<$Res> {
  factory _$QnaMessageCopyWith(_QnaMessage value, $Res Function(_QnaMessage) _then) = __$QnaMessageCopyWithImpl;
@override @useResult
$Res call({
 int id, int threadId, String userId, String? content, DateTime createdAt, bool isAdminMessage,@JsonKey(name: 'qna_attachments') List<QnaAttachment> attachments
});




}
/// @nodoc
class __$QnaMessageCopyWithImpl<$Res>
    implements _$QnaMessageCopyWith<$Res> {
  __$QnaMessageCopyWithImpl(this._self, this._then);

  final _QnaMessage _self;
  final $Res Function(_QnaMessage) _then;

/// Create a copy of QnaMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? threadId = null,Object? userId = null,Object? content = freezed,Object? createdAt = null,Object? isAdminMessage = null,Object? attachments = null,}) {
  return _then(_QnaMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isAdminMessage: null == isAdminMessage ? _self.isAdminMessage : isAdminMessage // ignore: cast_nullable_to_non_nullable
as bool,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<QnaAttachment>,
  ));
}


}

// dart format on
