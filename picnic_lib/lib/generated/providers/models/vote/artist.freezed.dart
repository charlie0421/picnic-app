// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name') Map<String, dynamic> get name;@JsonKey(name: 'yy') int? get yy;@JsonKey(name: 'mm') int? get mm;@JsonKey(name: 'dd') int? get dd;@JsonKey(name: 'birth_date') DateTime? get birthDateRaw;@JsonKey(name: 'gender') String? get gender;@JsonKey(name: 'artist_group') ArtistGroupModel? get artistGroup;@JsonKey(name: 'image') String? get image;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'isBookmarked') bool? get isBookmarked;
/// Create a copy of ArtistModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<ArtistModel> get copyWith => _$ArtistModelCopyWithImpl<ArtistModel>(this as ArtistModel, _$identity);

  /// Serializes this ArtistModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.yy, yy) || other.yy == yy)&&(identical(other.mm, mm) || other.mm == mm)&&(identical(other.dd, dd) || other.dd == dd)&&(identical(other.birthDateRaw, birthDateRaw) || other.birthDateRaw == birthDateRaw)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup)&&(identical(other.image, image) || other.image == image)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),yy,mm,dd,birthDateRaw,gender,artistGroup,image,createdAt,updatedAt,deletedAt,isBookmarked);

@override
String toString() {
  return 'ArtistModel(id: $id, name: $name, yy: $yy, mm: $mm, dd: $dd, birthDateRaw: $birthDateRaw, gender: $gender, artistGroup: $artistGroup, image: $image, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, isBookmarked: $isBookmarked)';
}


}

/// @nodoc
abstract mixin class $ArtistModelCopyWith<$Res>  {
  factory $ArtistModelCopyWith(ArtistModel value, $Res Function(ArtistModel) _then) = _$ArtistModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, dynamic> name,@JsonKey(name: 'yy') int? yy,@JsonKey(name: 'mm') int? mm,@JsonKey(name: 'dd') int? dd,@JsonKey(name: 'birth_date') DateTime? birthDateRaw,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup,@JsonKey(name: 'image') String? image,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'isBookmarked') bool? isBookmarked
});


$ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class _$ArtistModelCopyWithImpl<$Res>
    implements $ArtistModelCopyWith<$Res> {
  _$ArtistModelCopyWithImpl(this._self, this._then);

  final ArtistModel _self;
  final $Res Function(ArtistModel) _then;

/// Create a copy of ArtistModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? yy = freezed,Object? mm = freezed,Object? dd = freezed,Object? birthDateRaw = freezed,Object? gender = freezed,Object? artistGroup = freezed,Object? image = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,Object? isBookmarked = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,yy: freezed == yy ? _self.yy : yy // ignore: cast_nullable_to_non_nullable
as int?,mm: freezed == mm ? _self.mm : mm // ignore: cast_nullable_to_non_nullable
as int?,dd: freezed == dd ? _self.dd : dd // ignore: cast_nullable_to_non_nullable
as int?,birthDateRaw: freezed == birthDateRaw ? _self.birthDateRaw : birthDateRaw // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of ArtistModel
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


/// Adds pattern-matching-related methods to [ArtistModel].
extension ArtistModelPatterns on ArtistModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'yy')  int? yy, @JsonKey(name: 'mm')  int? mm, @JsonKey(name: 'dd')  int? dd, @JsonKey(name: 'birth_date')  DateTime? birthDateRaw, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'isBookmarked')  bool? isBookmarked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistModel() when $default != null:
return $default(_that.id,_that.name,_that.yy,_that.mm,_that.dd,_that.birthDateRaw,_that.gender,_that.artistGroup,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.isBookmarked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'yy')  int? yy, @JsonKey(name: 'mm')  int? mm, @JsonKey(name: 'dd')  int? dd, @JsonKey(name: 'birth_date')  DateTime? birthDateRaw, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'isBookmarked')  bool? isBookmarked)  $default,) {final _that = this;
switch (_that) {
case _ArtistModel():
return $default(_that.id,_that.name,_that.yy,_that.mm,_that.dd,_that.birthDateRaw,_that.gender,_that.artistGroup,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.isBookmarked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name')  Map<String, dynamic> name, @JsonKey(name: 'yy')  int? yy, @JsonKey(name: 'mm')  int? mm, @JsonKey(name: 'dd')  int? dd, @JsonKey(name: 'birth_date')  DateTime? birthDateRaw, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'isBookmarked')  bool? isBookmarked)?  $default,) {final _that = this;
switch (_that) {
case _ArtistModel() when $default != null:
return $default(_that.id,_that.name,_that.yy,_that.mm,_that.dd,_that.birthDateRaw,_that.gender,_that.artistGroup,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.isBookmarked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistModel extends ArtistModel {
  const _ArtistModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required final  Map<String, dynamic> name, @JsonKey(name: 'yy') this.yy, @JsonKey(name: 'mm') this.mm, @JsonKey(name: 'dd') this.dd, @JsonKey(name: 'birth_date') this.birthDateRaw, @JsonKey(name: 'gender') this.gender, @JsonKey(name: 'artist_group') this.artistGroup, @JsonKey(name: 'image') this.image, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'isBookmarked') this.isBookmarked}): _name = name,super._();
  factory _ArtistModel.fromJson(Map<String, dynamic> json) => _$ArtistModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic> _name;
@override@JsonKey(name: 'name') Map<String, dynamic> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override@JsonKey(name: 'yy') final  int? yy;
@override@JsonKey(name: 'mm') final  int? mm;
@override@JsonKey(name: 'dd') final  int? dd;
@override@JsonKey(name: 'birth_date') final  DateTime? birthDateRaw;
@override@JsonKey(name: 'gender') final  String? gender;
@override@JsonKey(name: 'artist_group') final  ArtistGroupModel? artistGroup;
@override@JsonKey(name: 'image') final  String? image;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'isBookmarked') final  bool? isBookmarked;

/// Create a copy of ArtistModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistModelCopyWith<_ArtistModel> get copyWith => __$ArtistModelCopyWithImpl<_ArtistModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.yy, yy) || other.yy == yy)&&(identical(other.mm, mm) || other.mm == mm)&&(identical(other.dd, dd) || other.dd == dd)&&(identical(other.birthDateRaw, birthDateRaw) || other.birthDateRaw == birthDateRaw)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup)&&(identical(other.image, image) || other.image == image)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.isBookmarked, isBookmarked) || other.isBookmarked == isBookmarked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),yy,mm,dd,birthDateRaw,gender,artistGroup,image,createdAt,updatedAt,deletedAt,isBookmarked);

@override
String toString() {
  return 'ArtistModel(id: $id, name: $name, yy: $yy, mm: $mm, dd: $dd, birthDateRaw: $birthDateRaw, gender: $gender, artistGroup: $artistGroup, image: $image, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, isBookmarked: $isBookmarked)';
}


}

/// @nodoc
abstract mixin class _$ArtistModelCopyWith<$Res> implements $ArtistModelCopyWith<$Res> {
  factory _$ArtistModelCopyWith(_ArtistModel value, $Res Function(_ArtistModel) _then) = __$ArtistModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name') Map<String, dynamic> name,@JsonKey(name: 'yy') int? yy,@JsonKey(name: 'mm') int? mm,@JsonKey(name: 'dd') int? dd,@JsonKey(name: 'birth_date') DateTime? birthDateRaw,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup,@JsonKey(name: 'image') String? image,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'isBookmarked') bool? isBookmarked
});


@override $ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class __$ArtistModelCopyWithImpl<$Res>
    implements _$ArtistModelCopyWith<$Res> {
  __$ArtistModelCopyWithImpl(this._self, this._then);

  final _ArtistModel _self;
  final $Res Function(_ArtistModel) _then;

/// Create a copy of ArtistModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? yy = freezed,Object? mm = freezed,Object? dd = freezed,Object? birthDateRaw = freezed,Object? gender = freezed,Object? artistGroup = freezed,Object? image = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,Object? isBookmarked = freezed,}) {
  return _then(_ArtistModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,yy: freezed == yy ? _self.yy : yy // ignore: cast_nullable_to_non_nullable
as int?,mm: freezed == mm ? _self.mm : mm // ignore: cast_nullable_to_non_nullable
as int?,dd: freezed == dd ? _self.dd : dd // ignore: cast_nullable_to_non_nullable
as int?,birthDateRaw: freezed == birthDateRaw ? _self.birthDateRaw : birthDateRaw // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBookmarked: freezed == isBookmarked ? _self.isBookmarked : isBookmarked // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of ArtistModel
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

// dart format on
