// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/vote_item_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VoteItemRequest {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'vote_id') int get voteId;@JsonKey(name: 'status') String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of VoteItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteItemRequestCopyWith<VoteItemRequest> get copyWith => _$VoteItemRequestCopyWithImpl<VoteItemRequest>(this as VoteItemRequest, _$identity);

  /// Serializes this VoteItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteItemRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,status,createdAt,updatedAt);

@override
String toString() {
  return 'VoteItemRequest(id: $id, voteId: $voteId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $VoteItemRequestCopyWith<$Res>  {
  factory $VoteItemRequestCopyWith(VoteItemRequest value, $Res Function(VoteItemRequest) _then) = _$VoteItemRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$VoteItemRequestCopyWithImpl<$Res>
    implements $VoteItemRequestCopyWith<$Res> {
  _$VoteItemRequestCopyWithImpl(this._self, this._then);

  final VoteItemRequest _self;
  final $Res Function(VoteItemRequest) _then;

/// Create a copy of VoteItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? voteId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VoteItemRequest].
extension VoteItemRequestPatterns on VoteItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _VoteItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VoteItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteItemRequest() when $default != null:
return $default(_that.id,_that.voteId,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _VoteItemRequest():
return $default(_that.id,_that.voteId,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _VoteItemRequest() when $default != null:
return $default(_that.id,_that.voteId,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteItemRequest implements VoteItemRequest {
  const _VoteItemRequest({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote_id') required this.voteId, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _VoteItemRequest.fromJson(Map<String, dynamic> json) => _$VoteItemRequestFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'vote_id') final  int voteId;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of VoteItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteItemRequestCopyWith<_VoteItemRequest> get copyWith => __$VoteItemRequestCopyWithImpl<_VoteItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteItemRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,status,createdAt,updatedAt);

@override
String toString() {
  return 'VoteItemRequest(id: $id, voteId: $voteId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$VoteItemRequestCopyWith<$Res> implements $VoteItemRequestCopyWith<$Res> {
  factory _$VoteItemRequestCopyWith(_VoteItemRequest value, $Res Function(_VoteItemRequest) _then) = __$VoteItemRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$VoteItemRequestCopyWithImpl<$Res>
    implements _$VoteItemRequestCopyWith<$Res> {
  __$VoteItemRequestCopyWithImpl(this._self, this._then);

  final _VoteItemRequest _self;
  final $Res Function(_VoteItemRequest) _then;

/// Create a copy of VoteItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? voteId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_VoteItemRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
