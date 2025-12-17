// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/board.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardModel {

@JsonKey(name: 'board_id') String get boardId;@JsonKey(name: 'artist_id') int get artistId;@JsonKey(name: 'name') Map<String, dynamic> get name;@DescriptionConverter() dynamic get description;@JsonKey(name: 'is_official') bool? get isOfficial;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt; ArtistModel? get artist;@JsonKey(name: 'request_message') String? get requestMessage;@JsonKey(name: 'status') String? get status;@JsonKey(name: 'creator_id') String? get creatorId;@JsonKey(name: 'features') List<String>? get features;
/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardModelCopyWith<BoardModel> get copyWith => _$BoardModelCopyWithImpl<BoardModel>(this as BoardModel, _$identity);

  /// Serializes this BoardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardModel&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&const DeepCollectionEquality().equals(other.name, name)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.isOfficial, isOfficial) || other.isOfficial == isOfficial)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.requestMessage, requestMessage) || other.requestMessage == requestMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&const DeepCollectionEquality().equals(other.features, features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,boardId,artistId,const DeepCollectionEquality().hash(name),const DeepCollectionEquality().hash(description),isOfficial,createdAt,updatedAt,artist,requestMessage,status,creatorId,const DeepCollectionEquality().hash(features));

@override
String toString() {
  return 'BoardModel(boardId: $boardId, artistId: $artistId, name: $name, description: $description, isOfficial: $isOfficial, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist, requestMessage: $requestMessage, status: $status, creatorId: $creatorId, features: $features)';
}


}

/// @nodoc
abstract mixin class $BoardModelCopyWith<$Res>  {
  factory $BoardModelCopyWith(BoardModel value, $Res Function(BoardModel) _then) = _$BoardModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'board_id') String boardId,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'name') Map<String, dynamic> name,@DescriptionConverter() dynamic description,@JsonKey(name: 'is_official') bool? isOfficial,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, ArtistModel? artist,@JsonKey(name: 'request_message') String? requestMessage,@JsonKey(name: 'status') String? status,@JsonKey(name: 'creator_id') String? creatorId,@JsonKey(name: 'features') List<String>? features
});


$ArtistModelCopyWith<$Res>? get artist;

}
/// @nodoc
class _$BoardModelCopyWithImpl<$Res>
    implements $BoardModelCopyWith<$Res> {
  _$BoardModelCopyWithImpl(this._self, this._then);

  final BoardModel _self;
  final $Res Function(BoardModel) _then;

/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? boardId = null,Object? artistId = null,Object? name = null,Object? description = freezed,Object? isOfficial = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? artist = freezed,Object? requestMessage = freezed,Object? status = freezed,Object? creatorId = freezed,Object? features = freezed,}) {
  return _then(_self.copyWith(
boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as dynamic,isOfficial: freezed == isOfficial ? _self.isOfficial : isOfficial // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,requestMessage: freezed == requestMessage ? _self.requestMessage : requestMessage // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,creatorId: freezed == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of BoardModel
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


/// Adds pattern-matching-related methods to [BoardModel].
extension BoardModelPatterns on BoardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardModel value)  $default,){
final _that = this;
switch (_that) {
case _BoardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardModel value)?  $default,){
final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'board_id')  String boardId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'name')  Map<String, dynamic> name, @DescriptionConverter()  dynamic description, @JsonKey(name: 'is_official')  bool? isOfficial, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  ArtistModel? artist, @JsonKey(name: 'request_message')  String? requestMessage, @JsonKey(name: 'status')  String? status, @JsonKey(name: 'creator_id')  String? creatorId, @JsonKey(name: 'features')  List<String>? features)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
return $default(_that.boardId,_that.artistId,_that.name,_that.description,_that.isOfficial,_that.createdAt,_that.updatedAt,_that.artist,_that.requestMessage,_that.status,_that.creatorId,_that.features);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'board_id')  String boardId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'name')  Map<String, dynamic> name, @DescriptionConverter()  dynamic description, @JsonKey(name: 'is_official')  bool? isOfficial, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  ArtistModel? artist, @JsonKey(name: 'request_message')  String? requestMessage, @JsonKey(name: 'status')  String? status, @JsonKey(name: 'creator_id')  String? creatorId, @JsonKey(name: 'features')  List<String>? features)  $default,) {final _that = this;
switch (_that) {
case _BoardModel():
return $default(_that.boardId,_that.artistId,_that.name,_that.description,_that.isOfficial,_that.createdAt,_that.updatedAt,_that.artist,_that.requestMessage,_that.status,_that.creatorId,_that.features);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'board_id')  String boardId, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'name')  Map<String, dynamic> name, @DescriptionConverter()  dynamic description, @JsonKey(name: 'is_official')  bool? isOfficial, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt,  ArtistModel? artist, @JsonKey(name: 'request_message')  String? requestMessage, @JsonKey(name: 'status')  String? status, @JsonKey(name: 'creator_id')  String? creatorId, @JsonKey(name: 'features')  List<String>? features)?  $default,) {final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
return $default(_that.boardId,_that.artistId,_that.name,_that.description,_that.isOfficial,_that.createdAt,_that.updatedAt,_that.artist,_that.requestMessage,_that.status,_that.creatorId,_that.features);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardModel extends BoardModel {
  const _BoardModel({@JsonKey(name: 'board_id') required this.boardId, @JsonKey(name: 'artist_id') required this.artistId, @JsonKey(name: 'name') required final  Map<String, dynamic> name, @DescriptionConverter() required this.description, @JsonKey(name: 'is_official') required this.isOfficial, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, required this.artist, @JsonKey(name: 'request_message') required this.requestMessage, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'creator_id') required this.creatorId, @JsonKey(name: 'features') required final  List<String>? features}): _name = name,_features = features,super._();
  factory _BoardModel.fromJson(Map<String, dynamic> json) => _$BoardModelFromJson(json);

@override@JsonKey(name: 'board_id') final  String boardId;
@override@JsonKey(name: 'artist_id') final  int artistId;
 final  Map<String, dynamic> _name;
@override@JsonKey(name: 'name') Map<String, dynamic> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override@DescriptionConverter() final  dynamic description;
@override@JsonKey(name: 'is_official') final  bool? isOfficial;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override final  ArtistModel? artist;
@override@JsonKey(name: 'request_message') final  String? requestMessage;
@override@JsonKey(name: 'status') final  String? status;
@override@JsonKey(name: 'creator_id') final  String? creatorId;
 final  List<String>? _features;
@override@JsonKey(name: 'features') List<String>? get features {
  final value = _features;
  if (value == null) return null;
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardModelCopyWith<_BoardModel> get copyWith => __$BoardModelCopyWithImpl<_BoardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardModel&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&const DeepCollectionEquality().equals(other._name, _name)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.isOfficial, isOfficial) || other.isOfficial == isOfficial)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.requestMessage, requestMessage) || other.requestMessage == requestMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&const DeepCollectionEquality().equals(other._features, _features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,boardId,artistId,const DeepCollectionEquality().hash(_name),const DeepCollectionEquality().hash(description),isOfficial,createdAt,updatedAt,artist,requestMessage,status,creatorId,const DeepCollectionEquality().hash(_features));

@override
String toString() {
  return 'BoardModel(boardId: $boardId, artistId: $artistId, name: $name, description: $description, isOfficial: $isOfficial, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist, requestMessage: $requestMessage, status: $status, creatorId: $creatorId, features: $features)';
}


}

/// @nodoc
abstract mixin class _$BoardModelCopyWith<$Res> implements $BoardModelCopyWith<$Res> {
  factory _$BoardModelCopyWith(_BoardModel value, $Res Function(_BoardModel) _then) = __$BoardModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'board_id') String boardId,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'name') Map<String, dynamic> name,@DescriptionConverter() dynamic description,@JsonKey(name: 'is_official') bool? isOfficial,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt, ArtistModel? artist,@JsonKey(name: 'request_message') String? requestMessage,@JsonKey(name: 'status') String? status,@JsonKey(name: 'creator_id') String? creatorId,@JsonKey(name: 'features') List<String>? features
});


@override $ArtistModelCopyWith<$Res>? get artist;

}
/// @nodoc
class __$BoardModelCopyWithImpl<$Res>
    implements _$BoardModelCopyWith<$Res> {
  __$BoardModelCopyWithImpl(this._self, this._then);

  final _BoardModel _self;
  final $Res Function(_BoardModel) _then;

/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? boardId = null,Object? artistId = null,Object? name = null,Object? description = freezed,Object? isOfficial = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? artist = freezed,Object? requestMessage = freezed,Object? status = freezed,Object? creatorId = freezed,Object? features = freezed,}) {
  return _then(_BoardModel(
boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as dynamic,isOfficial: freezed == isOfficial ? _self.isOfficial : isOfficial // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,requestMessage: freezed == requestMessage ? _self.requestMessage : requestMessage // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,creatorId: freezed == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of BoardModel
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
