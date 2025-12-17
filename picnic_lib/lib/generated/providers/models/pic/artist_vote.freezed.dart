// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/artist_vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistVoteModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'title') Map<String, dynamic> get title;@JsonKey(name: 'category') String get category;@JsonKey(name: 'artist_vote_item') List<ArtistVoteItemModel>? get artistVoteItem;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'visible_at') DateTime? get visibleAt;@JsonKey(name: 'stop_at') DateTime get stopAt;@JsonKey(name: 'start_at') DateTime get startAt;
/// Create a copy of ArtistVoteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistVoteModelCopyWith<ArtistVoteModel> get copyWith => _$ArtistVoteModelCopyWithImpl<ArtistVoteModel>(this as ArtistVoteModel, _$identity);

  /// Serializes this ArtistVoteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistVoteModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.title, title)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.artistVoteItem, artistVoteItem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.visibleAt, visibleAt) || other.visibleAt == visibleAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt)&&(identical(other.startAt, startAt) || other.startAt == startAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(title),category,const DeepCollectionEquality().hash(artistVoteItem),createdAt,updatedAt,visibleAt,stopAt,startAt);

@override
String toString() {
  return 'ArtistVoteModel(id: $id, title: $title, category: $category, artistVoteItem: $artistVoteItem, createdAt: $createdAt, updatedAt: $updatedAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt)';
}


}

/// @nodoc
abstract mixin class $ArtistVoteModelCopyWith<$Res>  {
  factory $ArtistVoteModelCopyWith(ArtistVoteModel value, $Res Function(ArtistVoteModel) _then) = _$ArtistVoteModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'category') String category,@JsonKey(name: 'artist_vote_item') List<ArtistVoteItemModel>? artistVoteItem,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'visible_at') DateTime? visibleAt,@JsonKey(name: 'stop_at') DateTime stopAt,@JsonKey(name: 'start_at') DateTime startAt
});




}
/// @nodoc
class _$ArtistVoteModelCopyWithImpl<$Res>
    implements $ArtistVoteModelCopyWith<$Res> {
  _$ArtistVoteModelCopyWithImpl(this._self, this._then);

  final ArtistVoteModel _self;
  final $Res Function(ArtistVoteModel) _then;

/// Create a copy of ArtistVoteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? artistVoteItem = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? visibleAt = freezed,Object? stopAt = null,Object? startAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,artistVoteItem: freezed == artistVoteItem ? _self.artistVoteItem : artistVoteItem // ignore: cast_nullable_to_non_nullable
as List<ArtistVoteItemModel>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleAt: freezed == visibleAt ? _self.visibleAt : visibleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: null == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistVoteModel].
extension ArtistVoteModelPatterns on ArtistVoteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistVoteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistVoteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistVoteModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistVoteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistVoteModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistVoteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'category')  String category, @JsonKey(name: 'artist_vote_item')  List<ArtistVoteItemModel>? artistVoteItem, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime stopAt, @JsonKey(name: 'start_at')  DateTime startAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistVoteModel() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.artistVoteItem,_that.createdAt,_that.updatedAt,_that.visibleAt,_that.stopAt,_that.startAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'category')  String category, @JsonKey(name: 'artist_vote_item')  List<ArtistVoteItemModel>? artistVoteItem, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime stopAt, @JsonKey(name: 'start_at')  DateTime startAt)  $default,) {final _that = this;
switch (_that) {
case _ArtistVoteModel():
return $default(_that.id,_that.title,_that.category,_that.artistVoteItem,_that.createdAt,_that.updatedAt,_that.visibleAt,_that.stopAt,_that.startAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'category')  String category, @JsonKey(name: 'artist_vote_item')  List<ArtistVoteItemModel>? artistVoteItem, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime stopAt, @JsonKey(name: 'start_at')  DateTime startAt)?  $default,) {final _that = this;
switch (_that) {
case _ArtistVoteModel() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.artistVoteItem,_that.createdAt,_that.updatedAt,_that.visibleAt,_that.stopAt,_that.startAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistVoteModel extends ArtistVoteModel {
  const _ArtistVoteModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') required final  Map<String, dynamic> title, @JsonKey(name: 'category') required this.category, @JsonKey(name: 'artist_vote_item') required final  List<ArtistVoteItemModel>? artistVoteItem, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'visible_at') required this.visibleAt, @JsonKey(name: 'stop_at') required this.stopAt, @JsonKey(name: 'start_at') required this.startAt}): _title = title,_artistVoteItem = artistVoteItem,super._();
  factory _ArtistVoteModel.fromJson(Map<String, dynamic> json) => _$ArtistVoteModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic> _title;
@override@JsonKey(name: 'title') Map<String, dynamic> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

@override@JsonKey(name: 'category') final  String category;
 final  List<ArtistVoteItemModel>? _artistVoteItem;
@override@JsonKey(name: 'artist_vote_item') List<ArtistVoteItemModel>? get artistVoteItem {
  final value = _artistVoteItem;
  if (value == null) return null;
  if (_artistVoteItem is EqualUnmodifiableListView) return _artistVoteItem;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'visible_at') final  DateTime? visibleAt;
@override@JsonKey(name: 'stop_at') final  DateTime stopAt;
@override@JsonKey(name: 'start_at') final  DateTime startAt;

/// Create a copy of ArtistVoteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistVoteModelCopyWith<_ArtistVoteModel> get copyWith => __$ArtistVoteModelCopyWithImpl<_ArtistVoteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistVoteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistVoteModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._title, _title)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._artistVoteItem, _artistVoteItem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.visibleAt, visibleAt) || other.visibleAt == visibleAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt)&&(identical(other.startAt, startAt) || other.startAt == startAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_title),category,const DeepCollectionEquality().hash(_artistVoteItem),createdAt,updatedAt,visibleAt,stopAt,startAt);

@override
String toString() {
  return 'ArtistVoteModel(id: $id, title: $title, category: $category, artistVoteItem: $artistVoteItem, createdAt: $createdAt, updatedAt: $updatedAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt)';
}


}

/// @nodoc
abstract mixin class _$ArtistVoteModelCopyWith<$Res> implements $ArtistVoteModelCopyWith<$Res> {
  factory _$ArtistVoteModelCopyWith(_ArtistVoteModel value, $Res Function(_ArtistVoteModel) _then) = __$ArtistVoteModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'category') String category,@JsonKey(name: 'artist_vote_item') List<ArtistVoteItemModel>? artistVoteItem,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'visible_at') DateTime? visibleAt,@JsonKey(name: 'stop_at') DateTime stopAt,@JsonKey(name: 'start_at') DateTime startAt
});




}
/// @nodoc
class __$ArtistVoteModelCopyWithImpl<$Res>
    implements _$ArtistVoteModelCopyWith<$Res> {
  __$ArtistVoteModelCopyWithImpl(this._self, this._then);

  final _ArtistVoteModel _self;
  final $Res Function(_ArtistVoteModel) _then;

/// Create a copy of ArtistVoteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? artistVoteItem = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? visibleAt = freezed,Object? stopAt = null,Object? startAt = null,}) {
  return _then(_ArtistVoteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,artistVoteItem: freezed == artistVoteItem ? _self._artistVoteItem : artistVoteItem // ignore: cast_nullable_to_non_nullable
as List<ArtistVoteItemModel>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleAt: freezed == visibleAt ? _self.visibleAt : visibleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: null == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ArtistVoteItemModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'vote_total') int get voteTotal;@JsonKey(name: 'artist_vote_id') int get artistVoteId;@JsonKey(name: 'title') Map<String, dynamic> get title;@JsonKey(name: 'description') Map<String, dynamic> get description;
/// Create a copy of ArtistVoteItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistVoteItemModelCopyWith<ArtistVoteItemModel> get copyWith => _$ArtistVoteItemModelCopyWithImpl<ArtistVoteItemModel>(this as ArtistVoteItemModel, _$identity);

  /// Serializes this ArtistVoteItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistVoteItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.voteTotal, voteTotal) || other.voteTotal == voteTotal)&&(identical(other.artistVoteId, artistVoteId) || other.artistVoteId == artistVoteId)&&const DeepCollectionEquality().equals(other.title, title)&&const DeepCollectionEquality().equals(other.description, description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteTotal,artistVoteId,const DeepCollectionEquality().hash(title),const DeepCollectionEquality().hash(description));

@override
String toString() {
  return 'ArtistVoteItemModel(id: $id, voteTotal: $voteTotal, artistVoteId: $artistVoteId, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class $ArtistVoteItemModelCopyWith<$Res>  {
  factory $ArtistVoteItemModelCopyWith(ArtistVoteItemModel value, $Res Function(ArtistVoteItemModel) _then) = _$ArtistVoteItemModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_total') int voteTotal,@JsonKey(name: 'artist_vote_id') int artistVoteId,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'description') Map<String, dynamic> description
});




}
/// @nodoc
class _$ArtistVoteItemModelCopyWithImpl<$Res>
    implements $ArtistVoteItemModelCopyWith<$Res> {
  _$ArtistVoteItemModelCopyWithImpl(this._self, this._then);

  final ArtistVoteItemModel _self;
  final $Res Function(ArtistVoteItemModel) _then;

/// Create a copy of ArtistVoteItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? voteTotal = null,Object? artistVoteId = null,Object? title = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteTotal: null == voteTotal ? _self.voteTotal : voteTotal // ignore: cast_nullable_to_non_nullable
as int,artistVoteId: null == artistVoteId ? _self.artistVoteId : artistVoteId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistVoteItemModel].
extension ArtistVoteItemModelPatterns on ArtistVoteItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistVoteItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistVoteItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistVoteItemModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistVoteItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistVoteItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistVoteItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int voteTotal, @JsonKey(name: 'artist_vote_id')  int artistVoteId, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'description')  Map<String, dynamic> description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistVoteItemModel() when $default != null:
return $default(_that.id,_that.voteTotal,_that.artistVoteId,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int voteTotal, @JsonKey(name: 'artist_vote_id')  int artistVoteId, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'description')  Map<String, dynamic> description)  $default,) {final _that = this;
switch (_that) {
case _ArtistVoteItemModel():
return $default(_that.id,_that.voteTotal,_that.artistVoteId,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int voteTotal, @JsonKey(name: 'artist_vote_id')  int artistVoteId, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'description')  Map<String, dynamic> description)?  $default,) {final _that = this;
switch (_that) {
case _ArtistVoteItemModel() when $default != null:
return $default(_that.id,_that.voteTotal,_that.artistVoteId,_that.title,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistVoteItemModel extends ArtistVoteItemModel {
  const _ArtistVoteItemModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote_total') required this.voteTotal, @JsonKey(name: 'artist_vote_id') required this.artistVoteId, @JsonKey(name: 'title') required final  Map<String, dynamic> title, @JsonKey(name: 'description') required final  Map<String, dynamic> description}): _title = title,_description = description,super._();
  factory _ArtistVoteItemModel.fromJson(Map<String, dynamic> json) => _$ArtistVoteItemModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'vote_total') final  int voteTotal;
@override@JsonKey(name: 'artist_vote_id') final  int artistVoteId;
 final  Map<String, dynamic> _title;
@override@JsonKey(name: 'title') Map<String, dynamic> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

 final  Map<String, dynamic> _description;
@override@JsonKey(name: 'description') Map<String, dynamic> get description {
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_description);
}


/// Create a copy of ArtistVoteItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistVoteItemModelCopyWith<_ArtistVoteItemModel> get copyWith => __$ArtistVoteItemModelCopyWithImpl<_ArtistVoteItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistVoteItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistVoteItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.voteTotal, voteTotal) || other.voteTotal == voteTotal)&&(identical(other.artistVoteId, artistVoteId) || other.artistVoteId == artistVoteId)&&const DeepCollectionEquality().equals(other._title, _title)&&const DeepCollectionEquality().equals(other._description, _description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteTotal,artistVoteId,const DeepCollectionEquality().hash(_title),const DeepCollectionEquality().hash(_description));

@override
String toString() {
  return 'ArtistVoteItemModel(id: $id, voteTotal: $voteTotal, artistVoteId: $artistVoteId, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ArtistVoteItemModelCopyWith<$Res> implements $ArtistVoteItemModelCopyWith<$Res> {
  factory _$ArtistVoteItemModelCopyWith(_ArtistVoteItemModel value, $Res Function(_ArtistVoteItemModel) _then) = __$ArtistVoteItemModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_total') int voteTotal,@JsonKey(name: 'artist_vote_id') int artistVoteId,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'description') Map<String, dynamic> description
});




}
/// @nodoc
class __$ArtistVoteItemModelCopyWithImpl<$Res>
    implements _$ArtistVoteItemModelCopyWith<$Res> {
  __$ArtistVoteItemModelCopyWithImpl(this._self, this._then);

  final _ArtistVoteItemModel _self;
  final $Res Function(_ArtistVoteItemModel) _then;

/// Create a copy of ArtistVoteItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? voteTotal = null,Object? artistVoteId = null,Object? title = null,Object? description = null,}) {
  return _then(_ArtistVoteItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteTotal: null == voteTotal ? _self.voteTotal : voteTotal // ignore: cast_nullable_to_non_nullable
as int,artistVoteId: null == artistVoteId ? _self.artistVoteId : artistVoteId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,description: null == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$MyStarMemberModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name_ko') String get nameKo;@JsonKey(name: 'name_en') String get nameEn;@JsonKey(name: 'gender') String get gender;@JsonKey(name: 'image') String? get image;@JsonKey(name: 'mystar_group') MyStarGroupModel? get mystarGroup;
/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyStarMemberModelCopyWith<MyStarMemberModel> get copyWith => _$MyStarMemberModelCopyWithImpl<MyStarMemberModel>(this as MyStarMemberModel, _$identity);

  /// Serializes this MyStarMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyStarMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.image, image) || other.image == image)&&(identical(other.mystarGroup, mystarGroup) || other.mystarGroup == mystarGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,gender,image,mystarGroup);

@override
String toString() {
  return 'MyStarMemberModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, gender: $gender, image: $image, mystarGroup: $mystarGroup)';
}


}

/// @nodoc
abstract mixin class $MyStarMemberModelCopyWith<$Res>  {
  factory $MyStarMemberModelCopyWith(MyStarMemberModel value, $Res Function(MyStarMemberModel) _then) = _$MyStarMemberModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'gender') String gender,@JsonKey(name: 'image') String? image,@JsonKey(name: 'mystar_group') MyStarGroupModel? mystarGroup
});


$MyStarGroupModelCopyWith<$Res>? get mystarGroup;

}
/// @nodoc
class _$MyStarMemberModelCopyWithImpl<$Res>
    implements $MyStarMemberModelCopyWith<$Res> {
  _$MyStarMemberModelCopyWithImpl(this._self, this._then);

  final MyStarMemberModel _self;
  final $Res Function(MyStarMemberModel) _then;

/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? gender = null,Object? image = freezed,Object? mystarGroup = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,mystarGroup: freezed == mystarGroup ? _self.mystarGroup : mystarGroup // ignore: cast_nullable_to_non_nullable
as MyStarGroupModel?,
  ));
}
/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyStarGroupModelCopyWith<$Res>? get mystarGroup {
    if (_self.mystarGroup == null) {
    return null;
  }

  return $MyStarGroupModelCopyWith<$Res>(_self.mystarGroup!, (value) {
    return _then(_self.copyWith(mystarGroup: value));
  });
}
}


/// Adds pattern-matching-related methods to [MyStarMemberModel].
extension MyStarMemberModelPatterns on MyStarMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyStarMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyStarMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyStarMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _MyStarMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyStarMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyStarMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'mystar_group')  MyStarGroupModel? mystarGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyStarMemberModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.gender,_that.image,_that.mystarGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'mystar_group')  MyStarGroupModel? mystarGroup)  $default,) {final _that = this;
switch (_that) {
case _MyStarMemberModel():
return $default(_that.id,_that.nameKo,_that.nameEn,_that.gender,_that.image,_that.mystarGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'mystar_group')  MyStarGroupModel? mystarGroup)?  $default,) {final _that = this;
switch (_that) {
case _MyStarMemberModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.gender,_that.image,_that.mystarGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyStarMemberModel extends MyStarMemberModel {
  const _MyStarMemberModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name_ko') required this.nameKo, @JsonKey(name: 'name_en') required this.nameEn, @JsonKey(name: 'gender') required this.gender, @JsonKey(name: 'image') required this.image, @JsonKey(name: 'mystar_group') this.mystarGroup}): super._();
  factory _MyStarMemberModel.fromJson(Map<String, dynamic> json) => _$MyStarMemberModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'name_ko') final  String nameKo;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override@JsonKey(name: 'gender') final  String gender;
@override@JsonKey(name: 'image') final  String? image;
@override@JsonKey(name: 'mystar_group') final  MyStarGroupModel? mystarGroup;

/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyStarMemberModelCopyWith<_MyStarMemberModel> get copyWith => __$MyStarMemberModelCopyWithImpl<_MyStarMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyStarMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyStarMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.image, image) || other.image == image)&&(identical(other.mystarGroup, mystarGroup) || other.mystarGroup == mystarGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,gender,image,mystarGroup);

@override
String toString() {
  return 'MyStarMemberModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, gender: $gender, image: $image, mystarGroup: $mystarGroup)';
}


}

/// @nodoc
abstract mixin class _$MyStarMemberModelCopyWith<$Res> implements $MyStarMemberModelCopyWith<$Res> {
  factory _$MyStarMemberModelCopyWith(_MyStarMemberModel value, $Res Function(_MyStarMemberModel) _then) = __$MyStarMemberModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'gender') String gender,@JsonKey(name: 'image') String? image,@JsonKey(name: 'mystar_group') MyStarGroupModel? mystarGroup
});


@override $MyStarGroupModelCopyWith<$Res>? get mystarGroup;

}
/// @nodoc
class __$MyStarMemberModelCopyWithImpl<$Res>
    implements _$MyStarMemberModelCopyWith<$Res> {
  __$MyStarMemberModelCopyWithImpl(this._self, this._then);

  final _MyStarMemberModel _self;
  final $Res Function(_MyStarMemberModel) _then;

/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? gender = null,Object? image = freezed,Object? mystarGroup = freezed,}) {
  return _then(_MyStarMemberModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,mystarGroup: freezed == mystarGroup ? _self.mystarGroup : mystarGroup // ignore: cast_nullable_to_non_nullable
as MyStarGroupModel?,
  ));
}

/// Create a copy of MyStarMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyStarGroupModelCopyWith<$Res>? get mystarGroup {
    if (_self.mystarGroup == null) {
    return null;
  }

  return $MyStarGroupModelCopyWith<$Res>(_self.mystarGroup!, (value) {
    return _then(_self.copyWith(mystarGroup: value));
  });
}
}


/// @nodoc
mixin _$MyStarGroupModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name_ko') String get nameKo;@JsonKey(name: 'name_en') String get nameEn; String? get image;
/// Create a copy of MyStarGroupModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyStarGroupModelCopyWith<MyStarGroupModel> get copyWith => _$MyStarGroupModelCopyWithImpl<MyStarGroupModel>(this as MyStarGroupModel, _$identity);

  /// Serializes this MyStarGroupModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyStarGroupModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,image);

@override
String toString() {
  return 'MyStarGroupModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, image: $image)';
}


}

/// @nodoc
abstract mixin class $MyStarGroupModelCopyWith<$Res>  {
  factory $MyStarGroupModelCopyWith(MyStarGroupModel value, $Res Function(MyStarGroupModel) _then) = _$MyStarGroupModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn, String? image
});




}
/// @nodoc
class _$MyStarGroupModelCopyWithImpl<$Res>
    implements $MyStarGroupModelCopyWith<$Res> {
  _$MyStarGroupModelCopyWithImpl(this._self, this._then);

  final MyStarGroupModel _self;
  final $Res Function(MyStarGroupModel) _then;

/// Create a copy of MyStarGroupModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MyStarGroupModel].
extension MyStarGroupModelPatterns on MyStarGroupModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyStarGroupModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyStarGroupModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyStarGroupModel value)  $default,){
final _that = this;
switch (_that) {
case _MyStarGroupModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyStarGroupModel value)?  $default,){
final _that = this;
switch (_that) {
case _MyStarGroupModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn,  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyStarGroupModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn,  String? image)  $default,) {final _that = this;
switch (_that) {
case _MyStarGroupModel():
return $default(_that.id,_that.nameKo,_that.nameEn,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn,  String? image)?  $default,) {final _that = this;
switch (_that) {
case _MyStarGroupModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyStarGroupModel extends MyStarGroupModel {
  const _MyStarGroupModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name_ko') required this.nameKo, @JsonKey(name: 'name_en') required this.nameEn, this.image}): super._();
  factory _MyStarGroupModel.fromJson(Map<String, dynamic> json) => _$MyStarGroupModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'name_ko') final  String nameKo;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override final  String? image;

/// Create a copy of MyStarGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyStarGroupModelCopyWith<_MyStarGroupModel> get copyWith => __$MyStarGroupModelCopyWithImpl<_MyStarGroupModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyStarGroupModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyStarGroupModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,image);

@override
String toString() {
  return 'MyStarGroupModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, image: $image)';
}


}

/// @nodoc
abstract mixin class _$MyStarGroupModelCopyWith<$Res> implements $MyStarGroupModelCopyWith<$Res> {
  factory _$MyStarGroupModelCopyWith(_MyStarGroupModel value, $Res Function(_MyStarGroupModel) _then) = __$MyStarGroupModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn, String? image
});




}
/// @nodoc
class __$MyStarGroupModelCopyWithImpl<$Res>
    implements _$MyStarGroupModelCopyWith<$Res> {
  __$MyStarGroupModelCopyWithImpl(this._self, this._then);

  final _MyStarGroupModel _self;
  final $Res Function(_MyStarGroupModel) _then;

/// Create a copy of MyStarGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? image = freezed,}) {
  return _then(_MyStarGroupModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ArtistMemberModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name') Map<String, String> get name;@JsonKey(name: 'gender') String get gender;@JsonKey(name: 'image') String? get image;@JsonKey(name: 'artist_group') ArtistGroupModel? get artistGroup;
/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistMemberModelCopyWith<ArtistMemberModel> get copyWith => _$ArtistMemberModelCopyWithImpl<ArtistMemberModel>(this as ArtistMemberModel, _$identity);

  /// Serializes this ArtistMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistMemberModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.image, image) || other.image == image)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),gender,image,artistGroup);

@override
String toString() {
  return 'ArtistMemberModel(id: $id, name: $name, gender: $gender, image: $image, artistGroup: $artistGroup)';
}


}

/// @nodoc
abstract mixin class $ArtistMemberModelCopyWith<$Res>  {
  factory $ArtistMemberModelCopyWith(ArtistMemberModel value, $Res Function(ArtistMemberModel) _then) = _$ArtistMemberModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, String> name,@JsonKey(name: 'gender') String gender,@JsonKey(name: 'image') String? image,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup
});


$ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class _$ArtistMemberModelCopyWithImpl<$Res>
    implements $ArtistMemberModelCopyWith<$Res> {
  _$ArtistMemberModelCopyWithImpl(this._self, this._then);

  final ArtistMemberModel _self;
  final $Res Function(ArtistMemberModel) _then;

/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? image = freezed,Object? artistGroup = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,
  ));
}
/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistGroupModelCopyWith<$Res>? get artistGroup {
    if (_self.artistGroup == null) {
    return null;
  }

  return $ArtistGroupModelCopyWith<$Res>(_self.artistGroup!, (value) {
    return _then(_self.copyWith(artistGroup: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistMemberModel].
extension ArtistMemberModelPatterns on ArtistMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, String> name, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistMemberModel() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.image,_that.artistGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, String> name, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)  $default,) {final _that = this;
switch (_that) {
case _ArtistMemberModel():
return $default(_that.id,_that.name,_that.gender,_that.image,_that.artistGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, String> name, @JsonKey(name: 'gender')  String gender, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)?  $default,) {final _that = this;
switch (_that) {
case _ArtistMemberModel() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.image,_that.artistGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistMemberModel extends ArtistMemberModel {
  const _ArtistMemberModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required final  Map<String, String> name, @JsonKey(name: 'gender') required this.gender, @JsonKey(name: 'image') required this.image, @JsonKey(name: 'artist_group') this.artistGroup}): _name = name,super._();
  factory _ArtistMemberModel.fromJson(Map<String, dynamic> json) => _$ArtistMemberModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, String> _name;
@override@JsonKey(name: 'name') Map<String, String> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override@JsonKey(name: 'gender') final  String gender;
@override@JsonKey(name: 'image') final  String? image;
@override@JsonKey(name: 'artist_group') final  ArtistGroupModel? artistGroup;

/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistMemberModelCopyWith<_ArtistMemberModel> get copyWith => __$ArtistMemberModelCopyWithImpl<_ArtistMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistMemberModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.image, image) || other.image == image)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),gender,image,artistGroup);

@override
String toString() {
  return 'ArtistMemberModel(id: $id, name: $name, gender: $gender, image: $image, artistGroup: $artistGroup)';
}


}

/// @nodoc
abstract mixin class _$ArtistMemberModelCopyWith<$Res> implements $ArtistMemberModelCopyWith<$Res> {
  factory _$ArtistMemberModelCopyWith(_ArtistMemberModel value, $Res Function(_ArtistMemberModel) _then) = __$ArtistMemberModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, String> name,@JsonKey(name: 'gender') String gender,@JsonKey(name: 'image') String? image,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup
});


@override $ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class __$ArtistMemberModelCopyWithImpl<$Res>
    implements _$ArtistMemberModelCopyWith<$Res> {
  __$ArtistMemberModelCopyWithImpl(this._self, this._then);

  final _ArtistMemberModel _self;
  final $Res Function(_ArtistMemberModel) _then;

/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? image = freezed,Object? artistGroup = freezed,}) {
  return _then(_ArtistMemberModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,
  ));
}

/// Create a copy of ArtistMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistGroupModelCopyWith<$Res>? get artistGroup {
    if (_self.artistGroup == null) {
    return null;
  }

  return $ArtistGroupModelCopyWith<$Res>(_self.artistGroup!, (value) {
    return _then(_self.copyWith(artistGroup: value));
  });
}
}


/// @nodoc
mixin _$ArtistGroupModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name') Map<String, dynamic> get name;@JsonKey(name: 'image') String? get image;
/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistGroupModelCopyWith<ArtistGroupModel> get copyWith => _$ArtistGroupModelCopyWithImpl<ArtistGroupModel>(this as ArtistGroupModel, _$identity);

  /// Serializes this ArtistGroupModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistGroupModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),image);

@override
String toString() {
  return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class $ArtistGroupModelCopyWith<$Res>  {
  factory $ArtistGroupModelCopyWith(ArtistGroupModel value, $Res Function(ArtistGroupModel) _then) = _$ArtistGroupModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, dynamic> name,@JsonKey(name: 'image') String? image
});




}
/// @nodoc
class _$ArtistGroupModelCopyWithImpl<$Res>
    implements $ArtistGroupModelCopyWith<$Res> {
  _$ArtistGroupModelCopyWithImpl(this._self, this._then);

  final ArtistGroupModel _self;
  final $Res Function(ArtistGroupModel) _then;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistGroupModel].
extension ArtistGroupModelPatterns on ArtistGroupModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistGroupModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistGroupModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistGroupModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistGroupModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'image')  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
return $default(_that.id,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'image')  String? image)  $default,) {final _that = this;
switch (_that) {
case _ArtistGroupModel():
return $default(_that.id,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'image')  String? image)?  $default,) {final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
return $default(_that.id,_that.name,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistGroupModel extends ArtistGroupModel {
  const _ArtistGroupModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required final  Map<String, dynamic> name, @JsonKey(name: 'image') this.image}): _name = name,super._();
  factory _ArtistGroupModel.fromJson(Map<String, dynamic> json) => _$ArtistGroupModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic> _name;
@override@JsonKey(name: 'name') Map<String, dynamic> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override@JsonKey(name: 'image') final  String? image;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistGroupModelCopyWith<_ArtistGroupModel> get copyWith => __$ArtistGroupModelCopyWithImpl<_ArtistGroupModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistGroupModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistGroupModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),image);

@override
String toString() {
  return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class _$ArtistGroupModelCopyWith<$Res> implements $ArtistGroupModelCopyWith<$Res> {
  factory _$ArtistGroupModelCopyWith(_ArtistGroupModel value, $Res Function(_ArtistGroupModel) _then) = __$ArtistGroupModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, dynamic> name,@JsonKey(name: 'image') String? image
});




}
/// @nodoc
class __$ArtistGroupModelCopyWithImpl<$Res>
    implements _$ArtistGroupModelCopyWith<$Res> {
  __$ArtistGroupModelCopyWithImpl(this._self, this._then);

  final _ArtistGroupModel _self;
  final $Res Function(_ArtistGroupModel) _then;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? image = freezed,}) {
  return _then(_ArtistGroupModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
