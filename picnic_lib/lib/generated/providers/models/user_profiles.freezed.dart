// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/user_profiles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfilesModel {

@JsonKey(name: 'id') String? get id;@JsonKey(name: 'nickname') String? get nickname;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'country_code') String? get countryCode;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'user_agreement') UserAgreement? get userAgreement;@JsonKey(name: 'is_admin') bool? get isAdmin;@JsonKey(name: 'star_candy') int? get starCandy;@JsonKey(name: 'star_candy_bonus') int? get starCandyBonus;@JsonKey(name: 'jma_candy') int? get jmaCandy;@JsonKey(name: 'birth_date') DateTime? get birthDate;@JsonKey(name: 'gender') String? get gender;@JsonKey(name: 'birth_time') String? get birthTime;
/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfilesModelCopyWith<UserProfilesModel> get copyWith => _$UserProfilesModelCopyWithImpl<UserProfilesModel>(this as UserProfilesModel, _$identity);

  /// Serializes this UserProfilesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfilesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.userAgreement, userAgreement) || other.userAgreement == userAgreement)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy)&&(identical(other.starCandyBonus, starCandyBonus) || other.starCandyBonus == starCandyBonus)&&(identical(other.jmaCandy, jmaCandy) || other.jmaCandy == jmaCandy)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,avatarUrl,countryCode,deletedAt,userAgreement,isAdmin,starCandy,starCandyBonus,jmaCandy,birthDate,gender,birthTime);

@override
String toString() {
  return 'UserProfilesModel(id: $id, nickname: $nickname, avatarUrl: $avatarUrl, countryCode: $countryCode, deletedAt: $deletedAt, userAgreement: $userAgreement, isAdmin: $isAdmin, starCandy: $starCandy, starCandyBonus: $starCandyBonus, jmaCandy: $jmaCandy, birthDate: $birthDate, gender: $gender, birthTime: $birthTime)';
}


}

/// @nodoc
abstract mixin class $UserProfilesModelCopyWith<$Res>  {
  factory $UserProfilesModelCopyWith(UserProfilesModel value, $Res Function(UserProfilesModel) _then) = _$UserProfilesModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'nickname') String? nickname,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'country_code') String? countryCode,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'user_agreement') UserAgreement? userAgreement,@JsonKey(name: 'is_admin') bool? isAdmin,@JsonKey(name: 'star_candy') int? starCandy,@JsonKey(name: 'star_candy_bonus') int? starCandyBonus,@JsonKey(name: 'jma_candy') int? jmaCandy,@JsonKey(name: 'birth_date') DateTime? birthDate,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'birth_time') String? birthTime
});


$UserAgreementCopyWith<$Res>? get userAgreement;

}
/// @nodoc
class _$UserProfilesModelCopyWithImpl<$Res>
    implements $UserProfilesModelCopyWith<$Res> {
  _$UserProfilesModelCopyWithImpl(this._self, this._then);

  final UserProfilesModel _self;
  final $Res Function(UserProfilesModel) _then;

/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? nickname = freezed,Object? avatarUrl = freezed,Object? countryCode = freezed,Object? deletedAt = freezed,Object? userAgreement = freezed,Object? isAdmin = freezed,Object? starCandy = freezed,Object? starCandyBonus = freezed,Object? jmaCandy = freezed,Object? birthDate = freezed,Object? gender = freezed,Object? birthTime = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userAgreement: freezed == userAgreement ? _self.userAgreement : userAgreement // ignore: cast_nullable_to_non_nullable
as UserAgreement?,isAdmin: freezed == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool?,starCandy: freezed == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonus: freezed == starCandyBonus ? _self.starCandyBonus : starCandyBonus // ignore: cast_nullable_to_non_nullable
as int?,jmaCandy: freezed == jmaCandy ? _self.jmaCandy : jmaCandy // ignore: cast_nullable_to_non_nullable
as int?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserAgreementCopyWith<$Res>? get userAgreement {
    if (_self.userAgreement == null) {
    return null;
  }

  return $UserAgreementCopyWith<$Res>(_self.userAgreement!, (value) {
    return _then(_self.copyWith(userAgreement: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserProfilesModel].
extension UserProfilesModelPatterns on UserProfilesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfilesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfilesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfilesModel value)  $default,){
final _that = this;
switch (_that) {
case _UserProfilesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfilesModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfilesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'nickname')  String? nickname, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'country_code')  String? countryCode, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'user_agreement')  UserAgreement? userAgreement, @JsonKey(name: 'is_admin')  bool? isAdmin, @JsonKey(name: 'star_candy')  int? starCandy, @JsonKey(name: 'star_candy_bonus')  int? starCandyBonus, @JsonKey(name: 'jma_candy')  int? jmaCandy, @JsonKey(name: 'birth_date')  DateTime? birthDate, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birth_time')  String? birthTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfilesModel() when $default != null:
return $default(_that.id,_that.nickname,_that.avatarUrl,_that.countryCode,_that.deletedAt,_that.userAgreement,_that.isAdmin,_that.starCandy,_that.starCandyBonus,_that.jmaCandy,_that.birthDate,_that.gender,_that.birthTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'nickname')  String? nickname, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'country_code')  String? countryCode, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'user_agreement')  UserAgreement? userAgreement, @JsonKey(name: 'is_admin')  bool? isAdmin, @JsonKey(name: 'star_candy')  int? starCandy, @JsonKey(name: 'star_candy_bonus')  int? starCandyBonus, @JsonKey(name: 'jma_candy')  int? jmaCandy, @JsonKey(name: 'birth_date')  DateTime? birthDate, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birth_time')  String? birthTime)  $default,) {final _that = this;
switch (_that) {
case _UserProfilesModel():
return $default(_that.id,_that.nickname,_that.avatarUrl,_that.countryCode,_that.deletedAt,_that.userAgreement,_that.isAdmin,_that.starCandy,_that.starCandyBonus,_that.jmaCandy,_that.birthDate,_that.gender,_that.birthTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'nickname')  String? nickname, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'country_code')  String? countryCode, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'user_agreement')  UserAgreement? userAgreement, @JsonKey(name: 'is_admin')  bool? isAdmin, @JsonKey(name: 'star_candy')  int? starCandy, @JsonKey(name: 'star_candy_bonus')  int? starCandyBonus, @JsonKey(name: 'jma_candy')  int? jmaCandy, @JsonKey(name: 'birth_date')  DateTime? birthDate, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birth_time')  String? birthTime)?  $default,) {final _that = this;
switch (_that) {
case _UserProfilesModel() when $default != null:
return $default(_that.id,_that.nickname,_that.avatarUrl,_that.countryCode,_that.deletedAt,_that.userAgreement,_that.isAdmin,_that.starCandy,_that.starCandyBonus,_that.jmaCandy,_that.birthDate,_that.gender,_that.birthTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfilesModel extends UserProfilesModel {
  const _UserProfilesModel({@JsonKey(name: 'id') this.id, @JsonKey(name: 'nickname') this.nickname, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'country_code') this.countryCode, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'user_agreement') this.userAgreement, @JsonKey(name: 'is_admin') required this.isAdmin, @JsonKey(name: 'star_candy') required this.starCandy, @JsonKey(name: 'star_candy_bonus') required this.starCandyBonus, @JsonKey(name: 'jma_candy') required this.jmaCandy, @JsonKey(name: 'birth_date') this.birthDate, @JsonKey(name: 'gender') this.gender, @JsonKey(name: 'birth_time') this.birthTime}): super._();
  factory _UserProfilesModel.fromJson(Map<String, dynamic> json) => _$UserProfilesModelFromJson(json);

@override@JsonKey(name: 'id') final  String? id;
@override@JsonKey(name: 'nickname') final  String? nickname;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'country_code') final  String? countryCode;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'user_agreement') final  UserAgreement? userAgreement;
@override@JsonKey(name: 'is_admin') final  bool? isAdmin;
@override@JsonKey(name: 'star_candy') final  int? starCandy;
@override@JsonKey(name: 'star_candy_bonus') final  int? starCandyBonus;
@override@JsonKey(name: 'jma_candy') final  int? jmaCandy;
@override@JsonKey(name: 'birth_date') final  DateTime? birthDate;
@override@JsonKey(name: 'gender') final  String? gender;
@override@JsonKey(name: 'birth_time') final  String? birthTime;

/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfilesModelCopyWith<_UserProfilesModel> get copyWith => __$UserProfilesModelCopyWithImpl<_UserProfilesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfilesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfilesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.userAgreement, userAgreement) || other.userAgreement == userAgreement)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy)&&(identical(other.starCandyBonus, starCandyBonus) || other.starCandyBonus == starCandyBonus)&&(identical(other.jmaCandy, jmaCandy) || other.jmaCandy == jmaCandy)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nickname,avatarUrl,countryCode,deletedAt,userAgreement,isAdmin,starCandy,starCandyBonus,jmaCandy,birthDate,gender,birthTime);

@override
String toString() {
  return 'UserProfilesModel(id: $id, nickname: $nickname, avatarUrl: $avatarUrl, countryCode: $countryCode, deletedAt: $deletedAt, userAgreement: $userAgreement, isAdmin: $isAdmin, starCandy: $starCandy, starCandyBonus: $starCandyBonus, jmaCandy: $jmaCandy, birthDate: $birthDate, gender: $gender, birthTime: $birthTime)';
}


}

/// @nodoc
abstract mixin class _$UserProfilesModelCopyWith<$Res> implements $UserProfilesModelCopyWith<$Res> {
  factory _$UserProfilesModelCopyWith(_UserProfilesModel value, $Res Function(_UserProfilesModel) _then) = __$UserProfilesModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'nickname') String? nickname,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'country_code') String? countryCode,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'user_agreement') UserAgreement? userAgreement,@JsonKey(name: 'is_admin') bool? isAdmin,@JsonKey(name: 'star_candy') int? starCandy,@JsonKey(name: 'star_candy_bonus') int? starCandyBonus,@JsonKey(name: 'jma_candy') int? jmaCandy,@JsonKey(name: 'birth_date') DateTime? birthDate,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'birth_time') String? birthTime
});


@override $UserAgreementCopyWith<$Res>? get userAgreement;

}
/// @nodoc
class __$UserProfilesModelCopyWithImpl<$Res>
    implements _$UserProfilesModelCopyWith<$Res> {
  __$UserProfilesModelCopyWithImpl(this._self, this._then);

  final _UserProfilesModel _self;
  final $Res Function(_UserProfilesModel) _then;

/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? nickname = freezed,Object? avatarUrl = freezed,Object? countryCode = freezed,Object? deletedAt = freezed,Object? userAgreement = freezed,Object? isAdmin = freezed,Object? starCandy = freezed,Object? starCandyBonus = freezed,Object? jmaCandy = freezed,Object? birthDate = freezed,Object? gender = freezed,Object? birthTime = freezed,}) {
  return _then(_UserProfilesModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,userAgreement: freezed == userAgreement ? _self.userAgreement : userAgreement // ignore: cast_nullable_to_non_nullable
as UserAgreement?,isAdmin: freezed == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool?,starCandy: freezed == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonus: freezed == starCandyBonus ? _self.starCandyBonus : starCandyBonus // ignore: cast_nullable_to_non_nullable
as int?,jmaCandy: freezed == jmaCandy ? _self.jmaCandy : jmaCandy // ignore: cast_nullable_to_non_nullable
as int?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UserProfilesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserAgreementCopyWith<$Res>? get userAgreement {
    if (_self.userAgreement == null) {
    return null;
  }

  return $UserAgreementCopyWith<$Res>(_self.userAgreement!, (value) {
    return _then(_self.copyWith(userAgreement: value));
  });
}
}


/// @nodoc
mixin _$UserAgreement {

 DateTime get terms; DateTime get privacy;
/// Create a copy of UserAgreement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserAgreementCopyWith<UserAgreement> get copyWith => _$UserAgreementCopyWithImpl<UserAgreement>(this as UserAgreement, _$identity);

  /// Serializes this UserAgreement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserAgreement&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terms,privacy);

@override
String toString() {
  return 'UserAgreement(terms: $terms, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class $UserAgreementCopyWith<$Res>  {
  factory $UserAgreementCopyWith(UserAgreement value, $Res Function(UserAgreement) _then) = _$UserAgreementCopyWithImpl;
@useResult
$Res call({
 DateTime terms, DateTime privacy
});




}
/// @nodoc
class _$UserAgreementCopyWithImpl<$Res>
    implements $UserAgreementCopyWith<$Res> {
  _$UserAgreementCopyWithImpl(this._self, this._then);

  final UserAgreement _self;
  final $Res Function(UserAgreement) _then;

/// Create a copy of UserAgreement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? terms = null,Object? privacy = null,}) {
  return _then(_self.copyWith(
terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as DateTime,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserAgreement].
extension UserAgreementPatterns on UserAgreement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserAgreement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserAgreement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserAgreement value)  $default,){
final _that = this;
switch (_that) {
case _UserAgreement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserAgreement value)?  $default,){
final _that = this;
switch (_that) {
case _UserAgreement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime terms,  DateTime privacy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserAgreement() when $default != null:
return $default(_that.terms,_that.privacy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime terms,  DateTime privacy)  $default,) {final _that = this;
switch (_that) {
case _UserAgreement():
return $default(_that.terms,_that.privacy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime terms,  DateTime privacy)?  $default,) {final _that = this;
switch (_that) {
case _UserAgreement() when $default != null:
return $default(_that.terms,_that.privacy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserAgreement extends UserAgreement {
  const _UserAgreement({required this.terms, required this.privacy}): super._();
  factory _UserAgreement.fromJson(Map<String, dynamic> json) => _$UserAgreementFromJson(json);

@override final  DateTime terms;
@override final  DateTime privacy;

/// Create a copy of UserAgreement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserAgreementCopyWith<_UserAgreement> get copyWith => __$UserAgreementCopyWithImpl<_UserAgreement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserAgreementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserAgreement&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.privacy, privacy) || other.privacy == privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,terms,privacy);

@override
String toString() {
  return 'UserAgreement(terms: $terms, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class _$UserAgreementCopyWith<$Res> implements $UserAgreementCopyWith<$Res> {
  factory _$UserAgreementCopyWith(_UserAgreement value, $Res Function(_UserAgreement) _then) = __$UserAgreementCopyWithImpl;
@override @useResult
$Res call({
 DateTime terms, DateTime privacy
});




}
/// @nodoc
class __$UserAgreementCopyWithImpl<$Res>
    implements _$UserAgreementCopyWith<$Res> {
  __$UserAgreementCopyWithImpl(this._self, this._then);

  final _UserAgreement _self;
  final $Res Function(_UserAgreement) _then;

/// Create a copy of UserAgreement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? terms = null,Object? privacy = null,}) {
  return _then(_UserAgreement(
terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as DateTime,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
