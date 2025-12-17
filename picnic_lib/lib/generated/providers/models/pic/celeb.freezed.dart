// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/celeb.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CelebModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'name_ko') String get nameKo;@JsonKey(name: 'name_en') String get nameEn;@JsonKey(name: 'thumbnail') String? get thumbnail;@JsonKey(name: 'users') List<UserProfilesModel>? get users;
/// Create a copy of CelebModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CelebModelCopyWith<CelebModel> get copyWith => _$CelebModelCopyWithImpl<CelebModel>(this as CelebModel, _$identity);

  /// Serializes this CelebModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CelebModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other.users, users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,thumbnail,const DeepCollectionEquality().hash(users));

@override
String toString() {
  return 'CelebModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, thumbnail: $thumbnail, users: $users)';
}


}

/// @nodoc
abstract mixin class $CelebModelCopyWith<$Res>  {
  factory $CelebModelCopyWith(CelebModel value, $Res Function(CelebModel) _then) = _$CelebModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'thumbnail') String? thumbnail,@JsonKey(name: 'users') List<UserProfilesModel>? users
});




}
/// @nodoc
class _$CelebModelCopyWithImpl<$Res>
    implements $CelebModelCopyWith<$Res> {
  _$CelebModelCopyWithImpl(this._self, this._then);

  final CelebModel _self;
  final $Res Function(CelebModel) _then;

/// Create a copy of CelebModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? thumbnail = freezed,Object? users = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,users: freezed == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as List<UserProfilesModel>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CelebModel].
extension CelebModelPatterns on CelebModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CelebModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CelebModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CelebModel value)  $default,){
final _that = this;
switch (_that) {
case _CelebModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CelebModel value)?  $default,){
final _that = this;
switch (_that) {
case _CelebModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'users')  List<UserProfilesModel>? users)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CelebModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.thumbnail,_that.users);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'users')  List<UserProfilesModel>? users)  $default,) {final _that = this;
switch (_that) {
case _CelebModel():
return $default(_that.id,_that.nameKo,_that.nameEn,_that.thumbnail,_that.users);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'name_ko')  String nameKo, @JsonKey(name: 'name_en')  String nameEn, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'users')  List<UserProfilesModel>? users)?  $default,) {final _that = this;
switch (_that) {
case _CelebModel() when $default != null:
return $default(_that.id,_that.nameKo,_that.nameEn,_that.thumbnail,_that.users);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CelebModel extends CelebModel {
  const _CelebModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name_ko') required this.nameKo, @JsonKey(name: 'name_en') required this.nameEn, @JsonKey(name: 'thumbnail') this.thumbnail, @JsonKey(name: 'users') final  List<UserProfilesModel>? users}): _users = users,super._();
  factory _CelebModel.fromJson(Map<String, dynamic> json) => _$CelebModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'name_ko') final  String nameKo;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override@JsonKey(name: 'thumbnail') final  String? thumbnail;
 final  List<UserProfilesModel>? _users;
@override@JsonKey(name: 'users') List<UserProfilesModel>? get users {
  final value = _users;
  if (value == null) return null;
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CelebModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CelebModelCopyWith<_CelebModel> get copyWith => __$CelebModelCopyWithImpl<_CelebModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CelebModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CelebModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameKo, nameKo) || other.nameKo == nameKo)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other._users, _users));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nameKo,nameEn,thumbnail,const DeepCollectionEquality().hash(_users));

@override
String toString() {
  return 'CelebModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, thumbnail: $thumbnail, users: $users)';
}


}

/// @nodoc
abstract mixin class _$CelebModelCopyWith<$Res> implements $CelebModelCopyWith<$Res> {
  factory _$CelebModelCopyWith(_CelebModel value, $Res Function(_CelebModel) _then) = __$CelebModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'name_ko') String nameKo,@JsonKey(name: 'name_en') String nameEn,@JsonKey(name: 'thumbnail') String? thumbnail,@JsonKey(name: 'users') List<UserProfilesModel>? users
});




}
/// @nodoc
class __$CelebModelCopyWithImpl<$Res>
    implements _$CelebModelCopyWith<$Res> {
  __$CelebModelCopyWithImpl(this._self, this._then);

  final _CelebModel _self;
  final $Res Function(_CelebModel) _then;

/// Create a copy of CelebModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameKo = null,Object? nameEn = null,Object? thumbnail = freezed,Object? users = freezed,}) {
  return _then(_CelebModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameKo: null == nameKo ? _self.nameKo : nameKo // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,users: freezed == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<UserProfilesModel>?,
  ));
}


}

// dart format on
