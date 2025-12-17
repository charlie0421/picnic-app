// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/fortune.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FortuneModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'year') int get year;@JsonKey(name: 'artist_id') int get artistId;@JsonKey(name: 'artist') ArtistModel get artist;@JsonKey(name: 'overall_luck') String get overallLuck;@JsonKey(name: 'monthly_fortunes') List<MonthlyFortuneModel> get monthlyFortunes;@JsonKey(name: 'aspects') AspectModel get aspects;@JsonKey(name: 'lucky') LuckyModel get lucky;@JsonKey(name: 'advice') List<String> get advice;
/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FortuneModelCopyWith<FortuneModel> get copyWith => _$FortuneModelCopyWithImpl<FortuneModel>(this as FortuneModel, _$identity);

  /// Serializes this FortuneModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FortuneModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.overallLuck, overallLuck) || other.overallLuck == overallLuck)&&const DeepCollectionEquality().equals(other.monthlyFortunes, monthlyFortunes)&&(identical(other.aspects, aspects) || other.aspects == aspects)&&(identical(other.lucky, lucky) || other.lucky == lucky)&&const DeepCollectionEquality().equals(other.advice, advice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,artistId,artist,overallLuck,const DeepCollectionEquality().hash(monthlyFortunes),aspects,lucky,const DeepCollectionEquality().hash(advice));

@override
String toString() {
  return 'FortuneModel(id: $id, year: $year, artistId: $artistId, artist: $artist, overallLuck: $overallLuck, monthlyFortunes: $monthlyFortunes, aspects: $aspects, lucky: $lucky, advice: $advice)';
}


}

/// @nodoc
abstract mixin class $FortuneModelCopyWith<$Res>  {
  factory $FortuneModelCopyWith(FortuneModel value, $Res Function(FortuneModel) _then) = _$FortuneModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'year') int year,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'artist') ArtistModel artist,@JsonKey(name: 'overall_luck') String overallLuck,@JsonKey(name: 'monthly_fortunes') List<MonthlyFortuneModel> monthlyFortunes,@JsonKey(name: 'aspects') AspectModel aspects,@JsonKey(name: 'lucky') LuckyModel lucky,@JsonKey(name: 'advice') List<String> advice
});


$ArtistModelCopyWith<$Res> get artist;$AspectModelCopyWith<$Res> get aspects;$LuckyModelCopyWith<$Res> get lucky;

}
/// @nodoc
class _$FortuneModelCopyWithImpl<$Res>
    implements $FortuneModelCopyWith<$Res> {
  _$FortuneModelCopyWithImpl(this._self, this._then);

  final FortuneModel _self;
  final $Res Function(FortuneModel) _then;

/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? year = null,Object? artistId = null,Object? artist = null,Object? overallLuck = null,Object? monthlyFortunes = null,Object? aspects = null,Object? lucky = null,Object? advice = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel,overallLuck: null == overallLuck ? _self.overallLuck : overallLuck // ignore: cast_nullable_to_non_nullable
as String,monthlyFortunes: null == monthlyFortunes ? _self.monthlyFortunes : monthlyFortunes // ignore: cast_nullable_to_non_nullable
as List<MonthlyFortuneModel>,aspects: null == aspects ? _self.aspects : aspects // ignore: cast_nullable_to_non_nullable
as AspectModel,lucky: null == lucky ? _self.lucky : lucky // ignore: cast_nullable_to_non_nullable
as LuckyModel,advice: null == advice ? _self.advice : advice // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res> get artist {
  
  return $ArtistModelCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AspectModelCopyWith<$Res> get aspects {
  
  return $AspectModelCopyWith<$Res>(_self.aspects, (value) {
    return _then(_self.copyWith(aspects: value));
  });
}/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LuckyModelCopyWith<$Res> get lucky {
  
  return $LuckyModelCopyWith<$Res>(_self.lucky, (value) {
    return _then(_self.copyWith(lucky: value));
  });
}
}


/// Adds pattern-matching-related methods to [FortuneModel].
extension FortuneModelPatterns on FortuneModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FortuneModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FortuneModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FortuneModel value)  $default,){
final _that = this;
switch (_that) {
case _FortuneModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FortuneModel value)?  $default,){
final _that = this;
switch (_that) {
case _FortuneModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'year')  int year, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'artist')  ArtistModel artist, @JsonKey(name: 'overall_luck')  String overallLuck, @JsonKey(name: 'monthly_fortunes')  List<MonthlyFortuneModel> monthlyFortunes, @JsonKey(name: 'aspects')  AspectModel aspects, @JsonKey(name: 'lucky')  LuckyModel lucky, @JsonKey(name: 'advice')  List<String> advice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FortuneModel() when $default != null:
return $default(_that.id,_that.year,_that.artistId,_that.artist,_that.overallLuck,_that.monthlyFortunes,_that.aspects,_that.lucky,_that.advice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'year')  int year, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'artist')  ArtistModel artist, @JsonKey(name: 'overall_luck')  String overallLuck, @JsonKey(name: 'monthly_fortunes')  List<MonthlyFortuneModel> monthlyFortunes, @JsonKey(name: 'aspects')  AspectModel aspects, @JsonKey(name: 'lucky')  LuckyModel lucky, @JsonKey(name: 'advice')  List<String> advice)  $default,) {final _that = this;
switch (_that) {
case _FortuneModel():
return $default(_that.id,_that.year,_that.artistId,_that.artist,_that.overallLuck,_that.monthlyFortunes,_that.aspects,_that.lucky,_that.advice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'year')  int year, @JsonKey(name: 'artist_id')  int artistId, @JsonKey(name: 'artist')  ArtistModel artist, @JsonKey(name: 'overall_luck')  String overallLuck, @JsonKey(name: 'monthly_fortunes')  List<MonthlyFortuneModel> monthlyFortunes, @JsonKey(name: 'aspects')  AspectModel aspects, @JsonKey(name: 'lucky')  LuckyModel lucky, @JsonKey(name: 'advice')  List<String> advice)?  $default,) {final _that = this;
switch (_that) {
case _FortuneModel() when $default != null:
return $default(_that.id,_that.year,_that.artistId,_that.artist,_that.overallLuck,_that.monthlyFortunes,_that.aspects,_that.lucky,_that.advice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FortuneModel implements FortuneModel {
  const _FortuneModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'year') required this.year, @JsonKey(name: 'artist_id') required this.artistId, @JsonKey(name: 'artist') required this.artist, @JsonKey(name: 'overall_luck') required this.overallLuck, @JsonKey(name: 'monthly_fortunes') required final  List<MonthlyFortuneModel> monthlyFortunes, @JsonKey(name: 'aspects') required this.aspects, @JsonKey(name: 'lucky') required this.lucky, @JsonKey(name: 'advice') required final  List<String> advice}): _monthlyFortunes = monthlyFortunes,_advice = advice;
  factory _FortuneModel.fromJson(Map<String, dynamic> json) => _$FortuneModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'year') final  int year;
@override@JsonKey(name: 'artist_id') final  int artistId;
@override@JsonKey(name: 'artist') final  ArtistModel artist;
@override@JsonKey(name: 'overall_luck') final  String overallLuck;
 final  List<MonthlyFortuneModel> _monthlyFortunes;
@override@JsonKey(name: 'monthly_fortunes') List<MonthlyFortuneModel> get monthlyFortunes {
  if (_monthlyFortunes is EqualUnmodifiableListView) return _monthlyFortunes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyFortunes);
}

@override@JsonKey(name: 'aspects') final  AspectModel aspects;
@override@JsonKey(name: 'lucky') final  LuckyModel lucky;
 final  List<String> _advice;
@override@JsonKey(name: 'advice') List<String> get advice {
  if (_advice is EqualUnmodifiableListView) return _advice;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_advice);
}


/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FortuneModelCopyWith<_FortuneModel> get copyWith => __$FortuneModelCopyWithImpl<_FortuneModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FortuneModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FortuneModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.overallLuck, overallLuck) || other.overallLuck == overallLuck)&&const DeepCollectionEquality().equals(other._monthlyFortunes, _monthlyFortunes)&&(identical(other.aspects, aspects) || other.aspects == aspects)&&(identical(other.lucky, lucky) || other.lucky == lucky)&&const DeepCollectionEquality().equals(other._advice, _advice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,artistId,artist,overallLuck,const DeepCollectionEquality().hash(_monthlyFortunes),aspects,lucky,const DeepCollectionEquality().hash(_advice));

@override
String toString() {
  return 'FortuneModel(id: $id, year: $year, artistId: $artistId, artist: $artist, overallLuck: $overallLuck, monthlyFortunes: $monthlyFortunes, aspects: $aspects, lucky: $lucky, advice: $advice)';
}


}

/// @nodoc
abstract mixin class _$FortuneModelCopyWith<$Res> implements $FortuneModelCopyWith<$Res> {
  factory _$FortuneModelCopyWith(_FortuneModel value, $Res Function(_FortuneModel) _then) = __$FortuneModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'year') int year,@JsonKey(name: 'artist_id') int artistId,@JsonKey(name: 'artist') ArtistModel artist,@JsonKey(name: 'overall_luck') String overallLuck,@JsonKey(name: 'monthly_fortunes') List<MonthlyFortuneModel> monthlyFortunes,@JsonKey(name: 'aspects') AspectModel aspects,@JsonKey(name: 'lucky') LuckyModel lucky,@JsonKey(name: 'advice') List<String> advice
});


@override $ArtistModelCopyWith<$Res> get artist;@override $AspectModelCopyWith<$Res> get aspects;@override $LuckyModelCopyWith<$Res> get lucky;

}
/// @nodoc
class __$FortuneModelCopyWithImpl<$Res>
    implements _$FortuneModelCopyWith<$Res> {
  __$FortuneModelCopyWithImpl(this._self, this._then);

  final _FortuneModel _self;
  final $Res Function(_FortuneModel) _then;

/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? year = null,Object? artistId = null,Object? artist = null,Object? overallLuck = null,Object? monthlyFortunes = null,Object? aspects = null,Object? lucky = null,Object? advice = null,}) {
  return _then(_FortuneModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel,overallLuck: null == overallLuck ? _self.overallLuck : overallLuck // ignore: cast_nullable_to_non_nullable
as String,monthlyFortunes: null == monthlyFortunes ? _self._monthlyFortunes : monthlyFortunes // ignore: cast_nullable_to_non_nullable
as List<MonthlyFortuneModel>,aspects: null == aspects ? _self.aspects : aspects // ignore: cast_nullable_to_non_nullable
as AspectModel,lucky: null == lucky ? _self.lucky : lucky // ignore: cast_nullable_to_non_nullable
as LuckyModel,advice: null == advice ? _self._advice : advice // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res> get artist {
  
  return $ArtistModelCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AspectModelCopyWith<$Res> get aspects {
  
  return $AspectModelCopyWith<$Res>(_self.aspects, (value) {
    return _then(_self.copyWith(aspects: value));
  });
}/// Create a copy of FortuneModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LuckyModelCopyWith<$Res> get lucky {
  
  return $LuckyModelCopyWith<$Res>(_self.lucky, (value) {
    return _then(_self.copyWith(lucky: value));
  });
}
}


/// @nodoc
mixin _$MonthlyFortuneModel {

@JsonKey(name: 'month') int get month;@JsonKey(name: 'honor') String get honor;@JsonKey(name: 'career') String get career;@JsonKey(name: 'health') String get health;@JsonKey(name: 'summary') String get summary;
/// Create a copy of MonthlyFortuneModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyFortuneModelCopyWith<MonthlyFortuneModel> get copyWith => _$MonthlyFortuneModelCopyWithImpl<MonthlyFortuneModel>(this as MonthlyFortuneModel, _$identity);

  /// Serializes this MonthlyFortuneModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyFortuneModel&&(identical(other.month, month) || other.month == month)&&(identical(other.honor, honor) || other.honor == honor)&&(identical(other.career, career) || other.career == career)&&(identical(other.health, health) || other.health == health)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,honor,career,health,summary);

@override
String toString() {
  return 'MonthlyFortuneModel(month: $month, honor: $honor, career: $career, health: $health, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $MonthlyFortuneModelCopyWith<$Res>  {
  factory $MonthlyFortuneModelCopyWith(MonthlyFortuneModel value, $Res Function(MonthlyFortuneModel) _then) = _$MonthlyFortuneModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'month') int month,@JsonKey(name: 'honor') String honor,@JsonKey(name: 'career') String career,@JsonKey(name: 'health') String health,@JsonKey(name: 'summary') String summary
});




}
/// @nodoc
class _$MonthlyFortuneModelCopyWithImpl<$Res>
    implements $MonthlyFortuneModelCopyWith<$Res> {
  _$MonthlyFortuneModelCopyWithImpl(this._self, this._then);

  final MonthlyFortuneModel _self;
  final $Res Function(MonthlyFortuneModel) _then;

/// Create a copy of MonthlyFortuneModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? honor = null,Object? career = null,Object? health = null,Object? summary = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,honor: null == honor ? _self.honor : honor // ignore: cast_nullable_to_non_nullable
as String,career: null == career ? _self.career : career // ignore: cast_nullable_to_non_nullable
as String,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyFortuneModel].
extension MonthlyFortuneModelPatterns on MonthlyFortuneModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyFortuneModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyFortuneModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyFortuneModel value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyFortuneModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyFortuneModel value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyFortuneModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'month')  int month, @JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'summary')  String summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyFortuneModel() when $default != null:
return $default(_that.month,_that.honor,_that.career,_that.health,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'month')  int month, @JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'summary')  String summary)  $default,) {final _that = this;
switch (_that) {
case _MonthlyFortuneModel():
return $default(_that.month,_that.honor,_that.career,_that.health,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'month')  int month, @JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'summary')  String summary)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyFortuneModel() when $default != null:
return $default(_that.month,_that.honor,_that.career,_that.health,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyFortuneModel implements MonthlyFortuneModel {
  const _MonthlyFortuneModel({@JsonKey(name: 'month') required this.month, @JsonKey(name: 'honor') required this.honor, @JsonKey(name: 'career') required this.career, @JsonKey(name: 'health') required this.health, @JsonKey(name: 'summary') required this.summary});
  factory _MonthlyFortuneModel.fromJson(Map<String, dynamic> json) => _$MonthlyFortuneModelFromJson(json);

@override@JsonKey(name: 'month') final  int month;
@override@JsonKey(name: 'honor') final  String honor;
@override@JsonKey(name: 'career') final  String career;
@override@JsonKey(name: 'health') final  String health;
@override@JsonKey(name: 'summary') final  String summary;

/// Create a copy of MonthlyFortuneModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyFortuneModelCopyWith<_MonthlyFortuneModel> get copyWith => __$MonthlyFortuneModelCopyWithImpl<_MonthlyFortuneModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyFortuneModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyFortuneModel&&(identical(other.month, month) || other.month == month)&&(identical(other.honor, honor) || other.honor == honor)&&(identical(other.career, career) || other.career == career)&&(identical(other.health, health) || other.health == health)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,honor,career,health,summary);

@override
String toString() {
  return 'MonthlyFortuneModel(month: $month, honor: $honor, career: $career, health: $health, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$MonthlyFortuneModelCopyWith<$Res> implements $MonthlyFortuneModelCopyWith<$Res> {
  factory _$MonthlyFortuneModelCopyWith(_MonthlyFortuneModel value, $Res Function(_MonthlyFortuneModel) _then) = __$MonthlyFortuneModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'month') int month,@JsonKey(name: 'honor') String honor,@JsonKey(name: 'career') String career,@JsonKey(name: 'health') String health,@JsonKey(name: 'summary') String summary
});




}
/// @nodoc
class __$MonthlyFortuneModelCopyWithImpl<$Res>
    implements _$MonthlyFortuneModelCopyWith<$Res> {
  __$MonthlyFortuneModelCopyWithImpl(this._self, this._then);

  final _MonthlyFortuneModel _self;
  final $Res Function(_MonthlyFortuneModel) _then;

/// Create a copy of MonthlyFortuneModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? honor = null,Object? career = null,Object? health = null,Object? summary = null,}) {
  return _then(_MonthlyFortuneModel(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,honor: null == honor ? _self.honor : honor // ignore: cast_nullable_to_non_nullable
as String,career: null == career ? _self.career : career // ignore: cast_nullable_to_non_nullable
as String,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AspectModel {

@JsonKey(name: 'honor') String get honor;@JsonKey(name: 'career') String get career;@JsonKey(name: 'health') String get health;@JsonKey(name: 'finances') String get finances;@JsonKey(name: 'relationships') String get relationships;
/// Create a copy of AspectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AspectModelCopyWith<AspectModel> get copyWith => _$AspectModelCopyWithImpl<AspectModel>(this as AspectModel, _$identity);

  /// Serializes this AspectModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AspectModel&&(identical(other.honor, honor) || other.honor == honor)&&(identical(other.career, career) || other.career == career)&&(identical(other.health, health) || other.health == health)&&(identical(other.finances, finances) || other.finances == finances)&&(identical(other.relationships, relationships) || other.relationships == relationships));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,honor,career,health,finances,relationships);

@override
String toString() {
  return 'AspectModel(honor: $honor, career: $career, health: $health, finances: $finances, relationships: $relationships)';
}


}

/// @nodoc
abstract mixin class $AspectModelCopyWith<$Res>  {
  factory $AspectModelCopyWith(AspectModel value, $Res Function(AspectModel) _then) = _$AspectModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'honor') String honor,@JsonKey(name: 'career') String career,@JsonKey(name: 'health') String health,@JsonKey(name: 'finances') String finances,@JsonKey(name: 'relationships') String relationships
});




}
/// @nodoc
class _$AspectModelCopyWithImpl<$Res>
    implements $AspectModelCopyWith<$Res> {
  _$AspectModelCopyWithImpl(this._self, this._then);

  final AspectModel _self;
  final $Res Function(AspectModel) _then;

/// Create a copy of AspectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? honor = null,Object? career = null,Object? health = null,Object? finances = null,Object? relationships = null,}) {
  return _then(_self.copyWith(
honor: null == honor ? _self.honor : honor // ignore: cast_nullable_to_non_nullable
as String,career: null == career ? _self.career : career // ignore: cast_nullable_to_non_nullable
as String,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as String,finances: null == finances ? _self.finances : finances // ignore: cast_nullable_to_non_nullable
as String,relationships: null == relationships ? _self.relationships : relationships // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AspectModel].
extension AspectModelPatterns on AspectModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AspectModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AspectModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AspectModel value)  $default,){
final _that = this;
switch (_that) {
case _AspectModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AspectModel value)?  $default,){
final _that = this;
switch (_that) {
case _AspectModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'finances')  String finances, @JsonKey(name: 'relationships')  String relationships)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AspectModel() when $default != null:
return $default(_that.honor,_that.career,_that.health,_that.finances,_that.relationships);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'finances')  String finances, @JsonKey(name: 'relationships')  String relationships)  $default,) {final _that = this;
switch (_that) {
case _AspectModel():
return $default(_that.honor,_that.career,_that.health,_that.finances,_that.relationships);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'honor')  String honor, @JsonKey(name: 'career')  String career, @JsonKey(name: 'health')  String health, @JsonKey(name: 'finances')  String finances, @JsonKey(name: 'relationships')  String relationships)?  $default,) {final _that = this;
switch (_that) {
case _AspectModel() when $default != null:
return $default(_that.honor,_that.career,_that.health,_that.finances,_that.relationships);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AspectModel implements AspectModel {
  const _AspectModel({@JsonKey(name: 'honor') required this.honor, @JsonKey(name: 'career') required this.career, @JsonKey(name: 'health') required this.health, @JsonKey(name: 'finances') required this.finances, @JsonKey(name: 'relationships') required this.relationships});
  factory _AspectModel.fromJson(Map<String, dynamic> json) => _$AspectModelFromJson(json);

@override@JsonKey(name: 'honor') final  String honor;
@override@JsonKey(name: 'career') final  String career;
@override@JsonKey(name: 'health') final  String health;
@override@JsonKey(name: 'finances') final  String finances;
@override@JsonKey(name: 'relationships') final  String relationships;

/// Create a copy of AspectModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AspectModelCopyWith<_AspectModel> get copyWith => __$AspectModelCopyWithImpl<_AspectModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AspectModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AspectModel&&(identical(other.honor, honor) || other.honor == honor)&&(identical(other.career, career) || other.career == career)&&(identical(other.health, health) || other.health == health)&&(identical(other.finances, finances) || other.finances == finances)&&(identical(other.relationships, relationships) || other.relationships == relationships));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,honor,career,health,finances,relationships);

@override
String toString() {
  return 'AspectModel(honor: $honor, career: $career, health: $health, finances: $finances, relationships: $relationships)';
}


}

/// @nodoc
abstract mixin class _$AspectModelCopyWith<$Res> implements $AspectModelCopyWith<$Res> {
  factory _$AspectModelCopyWith(_AspectModel value, $Res Function(_AspectModel) _then) = __$AspectModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'honor') String honor,@JsonKey(name: 'career') String career,@JsonKey(name: 'health') String health,@JsonKey(name: 'finances') String finances,@JsonKey(name: 'relationships') String relationships
});




}
/// @nodoc
class __$AspectModelCopyWithImpl<$Res>
    implements _$AspectModelCopyWith<$Res> {
  __$AspectModelCopyWithImpl(this._self, this._then);

  final _AspectModel _self;
  final $Res Function(_AspectModel) _then;

/// Create a copy of AspectModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? honor = null,Object? career = null,Object? health = null,Object? finances = null,Object? relationships = null,}) {
  return _then(_AspectModel(
honor: null == honor ? _self.honor : honor // ignore: cast_nullable_to_non_nullable
as String,career: null == career ? _self.career : career // ignore: cast_nullable_to_non_nullable
as String,health: null == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as String,finances: null == finances ? _self.finances : finances // ignore: cast_nullable_to_non_nullable
as String,relationships: null == relationships ? _self.relationships : relationships // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LuckyModel {

@JsonKey(name: 'days') List<String> get days;@JsonKey(name: 'colors') List<String> get colors;@JsonKey(name: 'numbers') List<int> get numbers;@JsonKey(name: 'directions') List<String> get directions;
/// Create a copy of LuckyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LuckyModelCopyWith<LuckyModel> get copyWith => _$LuckyModelCopyWithImpl<LuckyModel>(this as LuckyModel, _$identity);

  /// Serializes this LuckyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LuckyModel&&const DeepCollectionEquality().equals(other.days, days)&&const DeepCollectionEquality().equals(other.colors, colors)&&const DeepCollectionEquality().equals(other.numbers, numbers)&&const DeepCollectionEquality().equals(other.directions, directions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(days),const DeepCollectionEquality().hash(colors),const DeepCollectionEquality().hash(numbers),const DeepCollectionEquality().hash(directions));

@override
String toString() {
  return 'LuckyModel(days: $days, colors: $colors, numbers: $numbers, directions: $directions)';
}


}

/// @nodoc
abstract mixin class $LuckyModelCopyWith<$Res>  {
  factory $LuckyModelCopyWith(LuckyModel value, $Res Function(LuckyModel) _then) = _$LuckyModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'days') List<String> days,@JsonKey(name: 'colors') List<String> colors,@JsonKey(name: 'numbers') List<int> numbers,@JsonKey(name: 'directions') List<String> directions
});




}
/// @nodoc
class _$LuckyModelCopyWithImpl<$Res>
    implements $LuckyModelCopyWith<$Res> {
  _$LuckyModelCopyWithImpl(this._self, this._then);

  final LuckyModel _self;
  final $Res Function(LuckyModel) _then;

/// Create a copy of LuckyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? colors = null,Object? numbers = null,Object? directions = null,}) {
  return _then(_self.copyWith(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<String>,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,numbers: null == numbers ? _self.numbers : numbers // ignore: cast_nullable_to_non_nullable
as List<int>,directions: null == directions ? _self.directions : directions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LuckyModel].
extension LuckyModelPatterns on LuckyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LuckyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LuckyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LuckyModel value)  $default,){
final _that = this;
switch (_that) {
case _LuckyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LuckyModel value)?  $default,){
final _that = this;
switch (_that) {
case _LuckyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'days')  List<String> days, @JsonKey(name: 'colors')  List<String> colors, @JsonKey(name: 'numbers')  List<int> numbers, @JsonKey(name: 'directions')  List<String> directions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LuckyModel() when $default != null:
return $default(_that.days,_that.colors,_that.numbers,_that.directions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'days')  List<String> days, @JsonKey(name: 'colors')  List<String> colors, @JsonKey(name: 'numbers')  List<int> numbers, @JsonKey(name: 'directions')  List<String> directions)  $default,) {final _that = this;
switch (_that) {
case _LuckyModel():
return $default(_that.days,_that.colors,_that.numbers,_that.directions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'days')  List<String> days, @JsonKey(name: 'colors')  List<String> colors, @JsonKey(name: 'numbers')  List<int> numbers, @JsonKey(name: 'directions')  List<String> directions)?  $default,) {final _that = this;
switch (_that) {
case _LuckyModel() when $default != null:
return $default(_that.days,_that.colors,_that.numbers,_that.directions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LuckyModel implements LuckyModel {
  const _LuckyModel({@JsonKey(name: 'days') required final  List<String> days, @JsonKey(name: 'colors') required final  List<String> colors, @JsonKey(name: 'numbers') required final  List<int> numbers, @JsonKey(name: 'directions') required final  List<String> directions}): _days = days,_colors = colors,_numbers = numbers,_directions = directions;
  factory _LuckyModel.fromJson(Map<String, dynamic> json) => _$LuckyModelFromJson(json);

 final  List<String> _days;
@override@JsonKey(name: 'days') List<String> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

 final  List<String> _colors;
@override@JsonKey(name: 'colors') List<String> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}

 final  List<int> _numbers;
@override@JsonKey(name: 'numbers') List<int> get numbers {
  if (_numbers is EqualUnmodifiableListView) return _numbers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_numbers);
}

 final  List<String> _directions;
@override@JsonKey(name: 'directions') List<String> get directions {
  if (_directions is EqualUnmodifiableListView) return _directions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_directions);
}


/// Create a copy of LuckyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LuckyModelCopyWith<_LuckyModel> get copyWith => __$LuckyModelCopyWithImpl<_LuckyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LuckyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LuckyModel&&const DeepCollectionEquality().equals(other._days, _days)&&const DeepCollectionEquality().equals(other._colors, _colors)&&const DeepCollectionEquality().equals(other._numbers, _numbers)&&const DeepCollectionEquality().equals(other._directions, _directions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),const DeepCollectionEquality().hash(_colors),const DeepCollectionEquality().hash(_numbers),const DeepCollectionEquality().hash(_directions));

@override
String toString() {
  return 'LuckyModel(days: $days, colors: $colors, numbers: $numbers, directions: $directions)';
}


}

/// @nodoc
abstract mixin class _$LuckyModelCopyWith<$Res> implements $LuckyModelCopyWith<$Res> {
  factory _$LuckyModelCopyWith(_LuckyModel value, $Res Function(_LuckyModel) _then) = __$LuckyModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'days') List<String> days,@JsonKey(name: 'colors') List<String> colors,@JsonKey(name: 'numbers') List<int> numbers,@JsonKey(name: 'directions') List<String> directions
});




}
/// @nodoc
class __$LuckyModelCopyWithImpl<$Res>
    implements _$LuckyModelCopyWith<$Res> {
  __$LuckyModelCopyWithImpl(this._self, this._then);

  final _LuckyModel _self;
  final $Res Function(_LuckyModel) _then;

/// Create a copy of LuckyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? colors = null,Object? numbers = null,Object? directions = null,}) {
  return _then(_LuckyModel(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<String>,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,numbers: null == numbers ? _self._numbers : numbers // ignore: cast_nullable_to_non_nullable
as List<int>,directions: null == directions ? _self._directions : directions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
