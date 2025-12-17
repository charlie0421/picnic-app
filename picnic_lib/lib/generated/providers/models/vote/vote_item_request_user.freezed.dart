// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/vote_item_request_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VoteItemRequestUser {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'vote_id') int get voteId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'artist_id') int get artistId;@JsonKey(name: 'status') String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;// 조인된 아티스트 정보 (선택적)
@JsonKey(name: 'artist') ArtistModel? get artist;
/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteItemRequestUserCopyWith<VoteItemRequestUser> get copyWith => _$VoteItemRequestUserCopyWithImpl<VoteItemRequestUser>(this as VoteItemRequestUser, _$identity);

  /// Serializes this VoteItemRequestUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteItemRequestUser&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.artist, artist) || other.artist == artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,userId,artistId,status,createdAt,updatedAt,artist);

@override
String toString() {
  return 'VoteItemRequestUser(id: $id, voteId: $voteId, userId: $userId, artistId: $artistId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist)';
}


}

/// @nodoc
abstract mixin class $VoteItemRequestUserCopyWith<$Res>  {
  factory $VoteItemRequestUserCopyWith(VoteItemRequestUser value, $Res Function(VoteItemRequestUser) _then) = _$VoteItemRequestUserCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'artist') ArtistModel? artist
});


$ArtistModelCopyWith<$Res>? get artist;

}
/// @nodoc
class _$VoteItemRequestUserCopyWithImpl<$Res>
    implements $VoteItemRequestUserCopyWith<$Res> {
  _$VoteItemRequestUserCopyWithImpl(this._self, this._then);

  final VoteItemRequestUser _self;
  final $Res Function(VoteItemRequestUser) _then;

/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? voteId = null,Object? userId = null,Object? artistId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? artist = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,
  ));
}
/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $ArtistModelCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [VoteItemRequestUser].
extension VoteItemRequestUserPatterns on VoteItemRequestUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteItemRequestUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteItemRequestUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteItemRequestUser value)  $default,){
final _that = this;
switch (_that) {
case _VoteItemRequestUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteItemRequestUser value)?  $default,){
final _that = this;
switch (_that) {
case _VoteItemRequestUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'artist')  ArtistModel? artist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteItemRequestUser() when $default != null:
return $default(_that.id,_that.voteId,_that.userId,_that.artistId,_that.status,_that.createdAt,_that.updatedAt,_that.artist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'artist')  ArtistModel? artist)  $default,) {final _that = this;
switch (_that) {
case _VoteItemRequestUser():
return $default(_that.id,_that.voteId,_that.userId,_that.artistId,_that.status,_that.createdAt,_that.updatedAt,_that.artist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'artist')  ArtistModel? artist)?  $default,) {final _that = this;
switch (_that) {
case _VoteItemRequestUser() when $default != null:
return $default(_that.id,_that.voteId,_that.userId,_that.artistId,_that.status,_that.createdAt,_that.updatedAt,_that.artist);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteItemRequestUser implements VoteItemRequestUser {
  const _VoteItemRequestUser({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote_id') required this.voteId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'artist_id') required this.artistId, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'artist') this.artist});
  factory _VoteItemRequestUser.fromJson(Map<String, dynamic> json) => _$VoteItemRequestUserFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'vote_id') final  int voteId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'artist_id') final  int artistId;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
// 조인된 아티스트 정보 (선택적)
@override@JsonKey(name: 'artist') final  ArtistModel? artist;

/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteItemRequestUserCopyWith<_VoteItemRequestUser> get copyWith => __$VoteItemRequestUserCopyWithImpl<_VoteItemRequestUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteItemRequestUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteItemRequestUser&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.artist, artist) || other.artist == artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,userId,artistId,status,createdAt,updatedAt,artist);

@override
String toString() {
  return 'VoteItemRequestUser(id: $id, voteId: $voteId, userId: $userId, artistId: $artistId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist)';
}


}

/// @nodoc
abstract mixin class _$VoteItemRequestUserCopyWith<$Res> implements $VoteItemRequestUserCopyWith<$Res> {
  factory _$VoteItemRequestUserCopyWith(_VoteItemRequestUser value, $Res Function(_VoteItemRequestUser) _then) = __$VoteItemRequestUserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'artist') ArtistModel? artist
});


@override $ArtistModelCopyWith<$Res>? get artist;

}
/// @nodoc
class __$VoteItemRequestUserCopyWithImpl<$Res>
    implements _$VoteItemRequestUserCopyWith<$Res> {
  __$VoteItemRequestUserCopyWithImpl(this._self, this._then);

  final _VoteItemRequestUser _self;
  final $Res Function(_VoteItemRequestUser) _then;

/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? voteId = null,Object? userId = null,Object? artistId = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? artist = freezed,}) {
  return _then(_VoteItemRequestUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,
  ));
}

/// Create a copy of VoteItemRequestUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $ArtistModelCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}

// dart format on
