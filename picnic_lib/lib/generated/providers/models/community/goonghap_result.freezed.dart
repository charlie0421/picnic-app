// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/goonghap_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoonghapResult {

 String get id; String get userId; String get idolName; DateTime get userBirthDate; DateTime get idolBirthDate; String get userGender; String? get birthTime;// Optional
 int get goonghapScore; String? get goonghapSummary; Map<String, dynamic>? get details; List<String>? get tips; DateTime get createdAt;
/// Create a copy of GoonghapResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoonghapResultCopyWith<GoonghapResult> get copyWith => _$GoonghapResultCopyWithImpl<GoonghapResult>(this as GoonghapResult, _$identity);

  /// Serializes this GoonghapResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoonghapResult&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.idolName, idolName) || other.idolName == idolName)&&(identical(other.userBirthDate, userBirthDate) || other.userBirthDate == userBirthDate)&&(identical(other.idolBirthDate, idolBirthDate) || other.idolBirthDate == idolBirthDate)&&(identical(other.userGender, userGender) || other.userGender == userGender)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime)&&(identical(other.goonghapScore, goonghapScore) || other.goonghapScore == goonghapScore)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&const DeepCollectionEquality().equals(other.details, details)&&const DeepCollectionEquality().equals(other.tips, tips)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,idolName,userBirthDate,idolBirthDate,userGender,birthTime,goonghapScore,goonghapSummary,const DeepCollectionEquality().hash(details),const DeepCollectionEquality().hash(tips),createdAt);

@override
String toString() {
  return 'GoonghapResult(id: $id, userId: $userId, idolName: $idolName, userBirthDate: $userBirthDate, idolBirthDate: $idolBirthDate, userGender: $userGender, birthTime: $birthTime, goonghapScore: $goonghapScore, goonghapSummary: $goonghapSummary, details: $details, tips: $tips, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GoonghapResultCopyWith<$Res>  {
  factory $GoonghapResultCopyWith(GoonghapResult value, $Res Function(GoonghapResult) _then) = _$GoonghapResultCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String idolName, DateTime userBirthDate, DateTime idolBirthDate, String userGender, String? birthTime, int goonghapScore, String? goonghapSummary, Map<String, dynamic>? details, List<String>? tips, DateTime createdAt
});




}
/// @nodoc
class _$GoonghapResultCopyWithImpl<$Res>
    implements $GoonghapResultCopyWith<$Res> {
  _$GoonghapResultCopyWithImpl(this._self, this._then);

  final GoonghapResult _self;
  final $Res Function(GoonghapResult) _then;

/// Create a copy of GoonghapResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? idolName = null,Object? userBirthDate = null,Object? idolBirthDate = null,Object? userGender = null,Object? birthTime = freezed,Object? goonghapScore = null,Object? goonghapSummary = freezed,Object? details = freezed,Object? tips = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,idolName: null == idolName ? _self.idolName : idolName // ignore: cast_nullable_to_non_nullable
as String,userBirthDate: null == userBirthDate ? _self.userBirthDate : userBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime,idolBirthDate: null == idolBirthDate ? _self.idolBirthDate : idolBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime,userGender: null == userGender ? _self.userGender : userGender // ignore: cast_nullable_to_non_nullable
as String,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,goonghapScore: null == goonghapScore ? _self.goonghapScore : goonghapScore // ignore: cast_nullable_to_non_nullable
as int,goonghapSummary: freezed == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,tips: freezed == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GoonghapResult].
extension GoonghapResultPatterns on GoonghapResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoonghapResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoonghapResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoonghapResult value)  $default,){
final _that = this;
switch (_that) {
case _GoonghapResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoonghapResult value)?  $default,){
final _that = this;
switch (_that) {
case _GoonghapResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String idolName,  DateTime userBirthDate,  DateTime idolBirthDate,  String userGender,  String? birthTime,  int goonghapScore,  String? goonghapSummary,  Map<String, dynamic>? details,  List<String>? tips,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoonghapResult() when $default != null:
return $default(_that.id,_that.userId,_that.idolName,_that.userBirthDate,_that.idolBirthDate,_that.userGender,_that.birthTime,_that.goonghapScore,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String idolName,  DateTime userBirthDate,  DateTime idolBirthDate,  String userGender,  String? birthTime,  int goonghapScore,  String? goonghapSummary,  Map<String, dynamic>? details,  List<String>? tips,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _GoonghapResult():
return $default(_that.id,_that.userId,_that.idolName,_that.userBirthDate,_that.idolBirthDate,_that.userGender,_that.birthTime,_that.goonghapScore,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String idolName,  DateTime userBirthDate,  DateTime idolBirthDate,  String userGender,  String? birthTime,  int goonghapScore,  String? goonghapSummary,  Map<String, dynamic>? details,  List<String>? tips,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GoonghapResult() when $default != null:
return $default(_that.id,_that.userId,_that.idolName,_that.userBirthDate,_that.idolBirthDate,_that.userGender,_that.birthTime,_that.goonghapScore,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoonghapResult implements GoonghapResult {
  const _GoonghapResult({required this.id, required this.userId, required this.idolName, required this.userBirthDate, required this.idolBirthDate, required this.userGender, this.birthTime, required this.goonghapScore, required this.goonghapSummary, required final  Map<String, dynamic>? details, required final  List<String>? tips, required this.createdAt}): _details = details,_tips = tips;
  factory _GoonghapResult.fromJson(Map<String, dynamic> json) => _$GoonghapResultFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String idolName;
@override final  DateTime userBirthDate;
@override final  DateTime idolBirthDate;
@override final  String userGender;
@override final  String? birthTime;
// Optional
@override final  int goonghapScore;
@override final  String? goonghapSummary;
 final  Map<String, dynamic>? _details;
@override Map<String, dynamic>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _tips;
@override List<String>? get tips {
  final value = _tips;
  if (value == null) return null;
  if (_tips is EqualUnmodifiableListView) return _tips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  DateTime createdAt;

/// Create a copy of GoonghapResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoonghapResultCopyWith<_GoonghapResult> get copyWith => __$GoonghapResultCopyWithImpl<_GoonghapResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoonghapResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoonghapResult&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.idolName, idolName) || other.idolName == idolName)&&(identical(other.userBirthDate, userBirthDate) || other.userBirthDate == userBirthDate)&&(identical(other.idolBirthDate, idolBirthDate) || other.idolBirthDate == idolBirthDate)&&(identical(other.userGender, userGender) || other.userGender == userGender)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime)&&(identical(other.goonghapScore, goonghapScore) || other.goonghapScore == goonghapScore)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&const DeepCollectionEquality().equals(other._details, _details)&&const DeepCollectionEquality().equals(other._tips, _tips)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,idolName,userBirthDate,idolBirthDate,userGender,birthTime,goonghapScore,goonghapSummary,const DeepCollectionEquality().hash(_details),const DeepCollectionEquality().hash(_tips),createdAt);

@override
String toString() {
  return 'GoonghapResult(id: $id, userId: $userId, idolName: $idolName, userBirthDate: $userBirthDate, idolBirthDate: $idolBirthDate, userGender: $userGender, birthTime: $birthTime, goonghapScore: $goonghapScore, goonghapSummary: $goonghapSummary, details: $details, tips: $tips, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GoonghapResultCopyWith<$Res> implements $GoonghapResultCopyWith<$Res> {
  factory _$GoonghapResultCopyWith(_GoonghapResult value, $Res Function(_GoonghapResult) _then) = __$GoonghapResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String idolName, DateTime userBirthDate, DateTime idolBirthDate, String userGender, String? birthTime, int goonghapScore, String? goonghapSummary, Map<String, dynamic>? details, List<String>? tips, DateTime createdAt
});




}
/// @nodoc
class __$GoonghapResultCopyWithImpl<$Res>
    implements _$GoonghapResultCopyWith<$Res> {
  __$GoonghapResultCopyWithImpl(this._self, this._then);

  final _GoonghapResult _self;
  final $Res Function(_GoonghapResult) _then;

/// Create a copy of GoonghapResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? idolName = null,Object? userBirthDate = null,Object? idolBirthDate = null,Object? userGender = null,Object? birthTime = freezed,Object? goonghapScore = null,Object? goonghapSummary = freezed,Object? details = freezed,Object? tips = freezed,Object? createdAt = null,}) {
  return _then(_GoonghapResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,idolName: null == idolName ? _self.idolName : idolName // ignore: cast_nullable_to_non_nullable
as String,userBirthDate: null == userBirthDate ? _self.userBirthDate : userBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime,idolBirthDate: null == idolBirthDate ? _self.idolBirthDate : idolBirthDate // ignore: cast_nullable_to_non_nullable
as DateTime,userGender: null == userGender ? _self.userGender : userGender // ignore: cast_nullable_to_non_nullable
as String,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,goonghapScore: null == goonghapScore ? _self.goonghapScore : goonghapScore // ignore: cast_nullable_to_non_nullable
as int,goonghapSummary: freezed == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,tips: freezed == tips ? _self._tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$StyleDetails {

 String? get idolStyle; String? get userStyle; String? get coupleStyle;
/// Create a copy of StyleDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StyleDetailsCopyWith<StyleDetails> get copyWith => _$StyleDetailsCopyWithImpl<StyleDetails>(this as StyleDetails, _$identity);

  /// Serializes this StyleDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StyleDetails&&(identical(other.idolStyle, idolStyle) || other.idolStyle == idolStyle)&&(identical(other.userStyle, userStyle) || other.userStyle == userStyle)&&(identical(other.coupleStyle, coupleStyle) || other.coupleStyle == coupleStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idolStyle,userStyle,coupleStyle);

@override
String toString() {
  return 'StyleDetails(idolStyle: $idolStyle, userStyle: $userStyle, coupleStyle: $coupleStyle)';
}


}

/// @nodoc
abstract mixin class $StyleDetailsCopyWith<$Res>  {
  factory $StyleDetailsCopyWith(StyleDetails value, $Res Function(StyleDetails) _then) = _$StyleDetailsCopyWithImpl;
@useResult
$Res call({
 String? idolStyle, String? userStyle, String? coupleStyle
});




}
/// @nodoc
class _$StyleDetailsCopyWithImpl<$Res>
    implements $StyleDetailsCopyWith<$Res> {
  _$StyleDetailsCopyWithImpl(this._self, this._then);

  final StyleDetails _self;
  final $Res Function(StyleDetails) _then;

/// Create a copy of StyleDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idolStyle = freezed,Object? userStyle = freezed,Object? coupleStyle = freezed,}) {
  return _then(_self.copyWith(
idolStyle: freezed == idolStyle ? _self.idolStyle : idolStyle // ignore: cast_nullable_to_non_nullable
as String?,userStyle: freezed == userStyle ? _self.userStyle : userStyle // ignore: cast_nullable_to_non_nullable
as String?,coupleStyle: freezed == coupleStyle ? _self.coupleStyle : coupleStyle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StyleDetails].
extension StyleDetailsPatterns on StyleDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StyleDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StyleDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StyleDetails value)  $default,){
final _that = this;
switch (_that) {
case _StyleDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StyleDetails value)?  $default,){
final _that = this;
switch (_that) {
case _StyleDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? idolStyle,  String? userStyle,  String? coupleStyle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StyleDetails() when $default != null:
return $default(_that.idolStyle,_that.userStyle,_that.coupleStyle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? idolStyle,  String? userStyle,  String? coupleStyle)  $default,) {final _that = this;
switch (_that) {
case _StyleDetails():
return $default(_that.idolStyle,_that.userStyle,_that.coupleStyle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? idolStyle,  String? userStyle,  String? coupleStyle)?  $default,) {final _that = this;
switch (_that) {
case _StyleDetails() when $default != null:
return $default(_that.idolStyle,_that.userStyle,_that.coupleStyle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StyleDetails implements StyleDetails {
  const _StyleDetails({required this.idolStyle, required this.userStyle, required this.coupleStyle});
  factory _StyleDetails.fromJson(Map<String, dynamic> json) => _$StyleDetailsFromJson(json);

@override final  String? idolStyle;
@override final  String? userStyle;
@override final  String? coupleStyle;

/// Create a copy of StyleDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StyleDetailsCopyWith<_StyleDetails> get copyWith => __$StyleDetailsCopyWithImpl<_StyleDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StyleDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StyleDetails&&(identical(other.idolStyle, idolStyle) || other.idolStyle == idolStyle)&&(identical(other.userStyle, userStyle) || other.userStyle == userStyle)&&(identical(other.coupleStyle, coupleStyle) || other.coupleStyle == coupleStyle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idolStyle,userStyle,coupleStyle);

@override
String toString() {
  return 'StyleDetails(idolStyle: $idolStyle, userStyle: $userStyle, coupleStyle: $coupleStyle)';
}


}

/// @nodoc
abstract mixin class _$StyleDetailsCopyWith<$Res> implements $StyleDetailsCopyWith<$Res> {
  factory _$StyleDetailsCopyWith(_StyleDetails value, $Res Function(_StyleDetails) _then) = __$StyleDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? idolStyle, String? userStyle, String? coupleStyle
});




}
/// @nodoc
class __$StyleDetailsCopyWithImpl<$Res>
    implements _$StyleDetailsCopyWith<$Res> {
  __$StyleDetailsCopyWithImpl(this._self, this._then);

  final _StyleDetails _self;
  final $Res Function(_StyleDetails) _then;

/// Create a copy of StyleDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idolStyle = freezed,Object? userStyle = freezed,Object? coupleStyle = freezed,}) {
  return _then(_StyleDetails(
idolStyle: freezed == idolStyle ? _self.idolStyle : idolStyle // ignore: cast_nullable_to_non_nullable
as String?,userStyle: freezed == userStyle ? _self.userStyle : userStyle // ignore: cast_nullable_to_non_nullable
as String?,coupleStyle: freezed == coupleStyle ? _self.coupleStyle : coupleStyle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ActivitiesDetails {

 List<String>? get recommended; String? get description;
/// Create a copy of ActivitiesDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivitiesDetailsCopyWith<ActivitiesDetails> get copyWith => _$ActivitiesDetailsCopyWithImpl<ActivitiesDetails>(this as ActivitiesDetails, _$identity);

  /// Serializes this ActivitiesDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivitiesDetails&&const DeepCollectionEquality().equals(other.recommended, recommended)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(recommended),description);

@override
String toString() {
  return 'ActivitiesDetails(recommended: $recommended, description: $description)';
}


}

/// @nodoc
abstract mixin class $ActivitiesDetailsCopyWith<$Res>  {
  factory $ActivitiesDetailsCopyWith(ActivitiesDetails value, $Res Function(ActivitiesDetails) _then) = _$ActivitiesDetailsCopyWithImpl;
@useResult
$Res call({
 List<String>? recommended, String? description
});




}
/// @nodoc
class _$ActivitiesDetailsCopyWithImpl<$Res>
    implements $ActivitiesDetailsCopyWith<$Res> {
  _$ActivitiesDetailsCopyWithImpl(this._self, this._then);

  final ActivitiesDetails _self;
  final $Res Function(ActivitiesDetails) _then;

/// Create a copy of ActivitiesDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recommended = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
recommended: freezed == recommended ? _self.recommended : recommended // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivitiesDetails].
extension ActivitiesDetailsPatterns on ActivitiesDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivitiesDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivitiesDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivitiesDetails value)  $default,){
final _that = this;
switch (_that) {
case _ActivitiesDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivitiesDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ActivitiesDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String>? recommended,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivitiesDetails() when $default != null:
return $default(_that.recommended,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String>? recommended,  String? description)  $default,) {final _that = this;
switch (_that) {
case _ActivitiesDetails():
return $default(_that.recommended,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String>? recommended,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _ActivitiesDetails() when $default != null:
return $default(_that.recommended,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivitiesDetails implements ActivitiesDetails {
  const _ActivitiesDetails({required final  List<String>? recommended, required this.description}): _recommended = recommended;
  factory _ActivitiesDetails.fromJson(Map<String, dynamic> json) => _$ActivitiesDetailsFromJson(json);

 final  List<String>? _recommended;
@override List<String>? get recommended {
  final value = _recommended;
  if (value == null) return null;
  if (_recommended is EqualUnmodifiableListView) return _recommended;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? description;

/// Create a copy of ActivitiesDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivitiesDetailsCopyWith<_ActivitiesDetails> get copyWith => __$ActivitiesDetailsCopyWithImpl<_ActivitiesDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivitiesDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivitiesDetails&&const DeepCollectionEquality().equals(other._recommended, _recommended)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recommended),description);

@override
String toString() {
  return 'ActivitiesDetails(recommended: $recommended, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ActivitiesDetailsCopyWith<$Res> implements $ActivitiesDetailsCopyWith<$Res> {
  factory _$ActivitiesDetailsCopyWith(_ActivitiesDetails value, $Res Function(_ActivitiesDetails) _then) = __$ActivitiesDetailsCopyWithImpl;
@override @useResult
$Res call({
 List<String>? recommended, String? description
});




}
/// @nodoc
class __$ActivitiesDetailsCopyWithImpl<$Res>
    implements _$ActivitiesDetailsCopyWith<$Res> {
  __$ActivitiesDetailsCopyWithImpl(this._self, this._then);

  final _ActivitiesDetails _self;
  final $Res Function(_ActivitiesDetails) _then;

/// Create a copy of ActivitiesDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recommended = freezed,Object? description = freezed,}) {
  return _then(_ActivitiesDetails(
recommended: freezed == recommended ? _self._recommended : recommended // ignore: cast_nullable_to_non_nullable
as List<String>?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
