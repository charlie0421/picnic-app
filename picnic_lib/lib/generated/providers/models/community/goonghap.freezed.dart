// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/goonghap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoonghapHistoryModel {

 List<GoonghapModel> get items; bool get hasMore; bool get isLoading;
/// Create a copy of GoonghapHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoonghapHistoryModelCopyWith<GoonghapHistoryModel> get copyWith => _$GoonghapHistoryModelCopyWithImpl<GoonghapHistoryModel>(this as GoonghapHistoryModel, _$identity);

  /// Serializes this GoonghapHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoonghapHistoryModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),hasMore,isLoading);

@override
String toString() {
  return 'GoonghapHistoryModel(items: $items, hasMore: $hasMore, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $GoonghapHistoryModelCopyWith<$Res>  {
  factory $GoonghapHistoryModelCopyWith(GoonghapHistoryModel value, $Res Function(GoonghapHistoryModel) _then) = _$GoonghapHistoryModelCopyWithImpl;
@useResult
$Res call({
 List<GoonghapModel> items, bool hasMore, bool isLoading
});




}
/// @nodoc
class _$GoonghapHistoryModelCopyWithImpl<$Res>
    implements $GoonghapHistoryModelCopyWith<$Res> {
  _$GoonghapHistoryModelCopyWithImpl(this._self, this._then);

  final GoonghapHistoryModel _self;
  final $Res Function(GoonghapHistoryModel) _then;

/// Create a copy of GoonghapHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GoonghapModel>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GoonghapHistoryModel].
extension GoonghapHistoryModelPatterns on GoonghapHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoonghapHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoonghapHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoonghapHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _GoonghapHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoonghapHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _GoonghapHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GoonghapModel> items,  bool hasMore,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoonghapHistoryModel() when $default != null:
return $default(_that.items,_that.hasMore,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GoonghapModel> items,  bool hasMore,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _GoonghapHistoryModel():
return $default(_that.items,_that.hasMore,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GoonghapModel> items,  bool hasMore,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _GoonghapHistoryModel() when $default != null:
return $default(_that.items,_that.hasMore,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoonghapHistoryModel implements GoonghapHistoryModel {
  const _GoonghapHistoryModel({required final  List<GoonghapModel> items, required this.hasMore, this.isLoading = false}): _items = items;
  factory _GoonghapHistoryModel.fromJson(Map<String, dynamic> json) => _$GoonghapHistoryModelFromJson(json);

 final  List<GoonghapModel> _items;
@override List<GoonghapModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  bool hasMore;
@override@JsonKey() final  bool isLoading;

/// Create a copy of GoonghapHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoonghapHistoryModelCopyWith<_GoonghapHistoryModel> get copyWith => __$GoonghapHistoryModelCopyWithImpl<_GoonghapHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoonghapHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoonghapHistoryModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,isLoading);

@override
String toString() {
  return 'GoonghapHistoryModel(items: $items, hasMore: $hasMore, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$GoonghapHistoryModelCopyWith<$Res> implements $GoonghapHistoryModelCopyWith<$Res> {
  factory _$GoonghapHistoryModelCopyWith(_GoonghapHistoryModel value, $Res Function(_GoonghapHistoryModel) _then) = __$GoonghapHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 List<GoonghapModel> items, bool hasMore, bool isLoading
});




}
/// @nodoc
class __$GoonghapHistoryModelCopyWithImpl<$Res>
    implements _$GoonghapHistoryModelCopyWith<$Res> {
  __$GoonghapHistoryModelCopyWithImpl(this._self, this._then);

  final _GoonghapHistoryModel _self;
  final $Res Function(_GoonghapHistoryModel) _then;

/// Create a copy of GoonghapHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? isLoading = null,}) {
  return _then(_GoonghapHistoryModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GoonghapModel>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GoonghapModel {

 String get id; String get userId; ArtistModel get artist;@JsonKey(name: 'user_birth_date') DateTime get birthDate;@JsonKey(name: 'user_birth_time') String? get birthTime; GoonghapStatus get status; String? get gender; String? get errorMessage; bool? get isLoading;@JsonKey(name: 'score') int? get score;@JsonKey(name: 'goonghap_summary') String? get goonghapSummary; Details? get details; List<String>? get tips; DateTime? get createdAt; DateTime? get completedAt;@JsonKey(name: 'i18n', fromJson: _parseI18nResults) Map<String, LocalizedGoonghap>? get localizedResults;@JsonKey(name: 'is_ads') bool? get isAds;@JsonKey(name: 'is_paid') bool? get isPaid;
/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoonghapModelCopyWith<GoonghapModel> get copyWith => _$GoonghapModelCopyWithImpl<GoonghapModel>(this as GoonghapModel, _$identity);

  /// Serializes this GoonghapModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoonghapModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.score, score) || other.score == score)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other.tips, tips)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other.localizedResults, localizedResults)&&(identical(other.isAds, isAds) || other.isAds == isAds)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,artist,birthDate,birthTime,status,gender,errorMessage,isLoading,score,goonghapSummary,details,const DeepCollectionEquality().hash(tips),createdAt,completedAt,const DeepCollectionEquality().hash(localizedResults),isAds,isPaid);

@override
String toString() {
  return 'GoonghapModel(id: $id, userId: $userId, artist: $artist, birthDate: $birthDate, birthTime: $birthTime, status: $status, gender: $gender, errorMessage: $errorMessage, isLoading: $isLoading, score: $score, goonghapSummary: $goonghapSummary, details: $details, tips: $tips, createdAt: $createdAt, completedAt: $completedAt, localizedResults: $localizedResults, isAds: $isAds, isPaid: $isPaid)';
}


}

/// @nodoc
abstract mixin class $GoonghapModelCopyWith<$Res>  {
  factory $GoonghapModelCopyWith(GoonghapModel value, $Res Function(GoonghapModel) _then) = _$GoonghapModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, ArtistModel artist,@JsonKey(name: 'user_birth_date') DateTime birthDate,@JsonKey(name: 'user_birth_time') String? birthTime, GoonghapStatus status, String? gender, String? errorMessage, bool? isLoading,@JsonKey(name: 'score') int? score,@JsonKey(name: 'goonghap_summary') String? goonghapSummary, Details? details, List<String>? tips, DateTime? createdAt, DateTime? completedAt,@JsonKey(name: 'i18n', fromJson: _parseI18nResults) Map<String, LocalizedGoonghap>? localizedResults,@JsonKey(name: 'is_ads') bool? isAds,@JsonKey(name: 'is_paid') bool? isPaid
});


$ArtistModelCopyWith<$Res> get artist;$DetailsCopyWith<$Res>? get details;

}
/// @nodoc
class _$GoonghapModelCopyWithImpl<$Res>
    implements $GoonghapModelCopyWith<$Res> {
  _$GoonghapModelCopyWithImpl(this._self, this._then);

  final GoonghapModel _self;
  final $Res Function(GoonghapModel) _then;

/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? artist = null,Object? birthDate = null,Object? birthTime = freezed,Object? status = null,Object? gender = freezed,Object? errorMessage = freezed,Object? isLoading = freezed,Object? score = freezed,Object? goonghapSummary = freezed,Object? details = freezed,Object? tips = freezed,Object? createdAt = freezed,Object? completedAt = freezed,Object? localizedResults = freezed,Object? isAds = freezed,Object? isPaid = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoonghapStatus,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: freezed == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,goonghapSummary: freezed == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Details?,tips: freezed == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,localizedResults: freezed == localizedResults ? _self.localizedResults : localizedResults // ignore: cast_nullable_to_non_nullable
as Map<String, LocalizedGoonghap>?,isAds: freezed == isAds ? _self.isAds : isAds // ignore: cast_nullable_to_non_nullable
as bool?,isPaid: freezed == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res> get artist {
  
  return $ArtistModelCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $DetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [GoonghapModel].
extension GoonghapModelPatterns on GoonghapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoonghapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoonghapModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoonghapModel value)  $default,){
final _that = this;
switch (_that) {
case _GoonghapModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoonghapModel value)?  $default,){
final _that = this;
switch (_that) {
case _GoonghapModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  ArtistModel artist, @JsonKey(name: 'user_birth_date')  DateTime birthDate, @JsonKey(name: 'user_birth_time')  String? birthTime,  GoonghapStatus status,  String? gender,  String? errorMessage,  bool? isLoading, @JsonKey(name: 'score')  int? score, @JsonKey(name: 'goonghap_summary')  String? goonghapSummary,  Details? details,  List<String>? tips,  DateTime? createdAt,  DateTime? completedAt, @JsonKey(name: 'i18n', fromJson: _parseI18nResults)  Map<String, LocalizedGoonghap>? localizedResults, @JsonKey(name: 'is_ads')  bool? isAds, @JsonKey(name: 'is_paid')  bool? isPaid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoonghapModel() when $default != null:
return $default(_that.id,_that.userId,_that.artist,_that.birthDate,_that.birthTime,_that.status,_that.gender,_that.errorMessage,_that.isLoading,_that.score,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt,_that.completedAt,_that.localizedResults,_that.isAds,_that.isPaid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  ArtistModel artist, @JsonKey(name: 'user_birth_date')  DateTime birthDate, @JsonKey(name: 'user_birth_time')  String? birthTime,  GoonghapStatus status,  String? gender,  String? errorMessage,  bool? isLoading, @JsonKey(name: 'score')  int? score, @JsonKey(name: 'goonghap_summary')  String? goonghapSummary,  Details? details,  List<String>? tips,  DateTime? createdAt,  DateTime? completedAt, @JsonKey(name: 'i18n', fromJson: _parseI18nResults)  Map<String, LocalizedGoonghap>? localizedResults, @JsonKey(name: 'is_ads')  bool? isAds, @JsonKey(name: 'is_paid')  bool? isPaid)  $default,) {final _that = this;
switch (_that) {
case _GoonghapModel():
return $default(_that.id,_that.userId,_that.artist,_that.birthDate,_that.birthTime,_that.status,_that.gender,_that.errorMessage,_that.isLoading,_that.score,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt,_that.completedAt,_that.localizedResults,_that.isAds,_that.isPaid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  ArtistModel artist, @JsonKey(name: 'user_birth_date')  DateTime birthDate, @JsonKey(name: 'user_birth_time')  String? birthTime,  GoonghapStatus status,  String? gender,  String? errorMessage,  bool? isLoading, @JsonKey(name: 'score')  int? score, @JsonKey(name: 'goonghap_summary')  String? goonghapSummary,  Details? details,  List<String>? tips,  DateTime? createdAt,  DateTime? completedAt, @JsonKey(name: 'i18n', fromJson: _parseI18nResults)  Map<String, LocalizedGoonghap>? localizedResults, @JsonKey(name: 'is_ads')  bool? isAds, @JsonKey(name: 'is_paid')  bool? isPaid)?  $default,) {final _that = this;
switch (_that) {
case _GoonghapModel() when $default != null:
return $default(_that.id,_that.userId,_that.artist,_that.birthDate,_that.birthTime,_that.status,_that.gender,_that.errorMessage,_that.isLoading,_that.score,_that.goonghapSummary,_that.details,_that.tips,_that.createdAt,_that.completedAt,_that.localizedResults,_that.isAds,_that.isPaid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoonghapModel extends GoonghapModel {
  const _GoonghapModel({this.id = '', required this.userId, required this.artist, @JsonKey(name: 'user_birth_date') required this.birthDate, @JsonKey(name: 'user_birth_time') this.birthTime, this.status = GoonghapStatus.pending, this.gender, this.errorMessage, this.isLoading, @JsonKey(name: 'score') this.score, @JsonKey(name: 'goonghap_summary') this.goonghapSummary, this.details, final  List<String>? tips, this.createdAt, this.completedAt, @JsonKey(name: 'i18n', fromJson: _parseI18nResults) final  Map<String, LocalizedGoonghap>? localizedResults, @JsonKey(name: 'is_ads') this.isAds, @JsonKey(name: 'is_paid') this.isPaid}): _tips = tips,_localizedResults = localizedResults,super._();
  factory _GoonghapModel.fromJson(Map<String, dynamic> json) => _$GoonghapModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String userId;
@override final  ArtistModel artist;
@override@JsonKey(name: 'user_birth_date') final  DateTime birthDate;
@override@JsonKey(name: 'user_birth_time') final  String? birthTime;
@override@JsonKey() final  GoonghapStatus status;
@override final  String? gender;
@override final  String? errorMessage;
@override final  bool? isLoading;
@override@JsonKey(name: 'score') final  int? score;
@override@JsonKey(name: 'goonghap_summary') final  String? goonghapSummary;
@override final  Details? details;
 final  List<String>? _tips;
@override List<String>? get tips {
  final value = _tips;
  if (value == null) return null;
  if (_tips is EqualUnmodifiableListView) return _tips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  DateTime? createdAt;
@override final  DateTime? completedAt;
 final  Map<String, LocalizedGoonghap>? _localizedResults;
@override@JsonKey(name: 'i18n', fromJson: _parseI18nResults) Map<String, LocalizedGoonghap>? get localizedResults {
  final value = _localizedResults;
  if (value == null) return null;
  if (_localizedResults is EqualUnmodifiableMapView) return _localizedResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'is_ads') final  bool? isAds;
@override@JsonKey(name: 'is_paid') final  bool? isPaid;

/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoonghapModelCopyWith<_GoonghapModel> get copyWith => __$GoonghapModelCopyWithImpl<_GoonghapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoonghapModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoonghapModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthTime, birthTime) || other.birthTime == birthTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.score, score) || other.score == score)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other._tips, _tips)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other._localizedResults, _localizedResults)&&(identical(other.isAds, isAds) || other.isAds == isAds)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,artist,birthDate,birthTime,status,gender,errorMessage,isLoading,score,goonghapSummary,details,const DeepCollectionEquality().hash(_tips),createdAt,completedAt,const DeepCollectionEquality().hash(_localizedResults),isAds,isPaid);

@override
String toString() {
  return 'GoonghapModel(id: $id, userId: $userId, artist: $artist, birthDate: $birthDate, birthTime: $birthTime, status: $status, gender: $gender, errorMessage: $errorMessage, isLoading: $isLoading, score: $score, goonghapSummary: $goonghapSummary, details: $details, tips: $tips, createdAt: $createdAt, completedAt: $completedAt, localizedResults: $localizedResults, isAds: $isAds, isPaid: $isPaid)';
}


}

/// @nodoc
abstract mixin class _$GoonghapModelCopyWith<$Res> implements $GoonghapModelCopyWith<$Res> {
  factory _$GoonghapModelCopyWith(_GoonghapModel value, $Res Function(_GoonghapModel) _then) = __$GoonghapModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, ArtistModel artist,@JsonKey(name: 'user_birth_date') DateTime birthDate,@JsonKey(name: 'user_birth_time') String? birthTime, GoonghapStatus status, String? gender, String? errorMessage, bool? isLoading,@JsonKey(name: 'score') int? score,@JsonKey(name: 'goonghap_summary') String? goonghapSummary, Details? details, List<String>? tips, DateTime? createdAt, DateTime? completedAt,@JsonKey(name: 'i18n', fromJson: _parseI18nResults) Map<String, LocalizedGoonghap>? localizedResults,@JsonKey(name: 'is_ads') bool? isAds,@JsonKey(name: 'is_paid') bool? isPaid
});


@override $ArtistModelCopyWith<$Res> get artist;@override $DetailsCopyWith<$Res>? get details;

}
/// @nodoc
class __$GoonghapModelCopyWithImpl<$Res>
    implements _$GoonghapModelCopyWith<$Res> {
  __$GoonghapModelCopyWithImpl(this._self, this._then);

  final _GoonghapModel _self;
  final $Res Function(_GoonghapModel) _then;

/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? artist = null,Object? birthDate = null,Object? birthTime = freezed,Object? status = null,Object? gender = freezed,Object? errorMessage = freezed,Object? isLoading = freezed,Object? score = freezed,Object? goonghapSummary = freezed,Object? details = freezed,Object? tips = freezed,Object? createdAt = freezed,Object? completedAt = freezed,Object? localizedResults = freezed,Object? isAds = freezed,Object? isPaid = freezed,}) {
  return _then(_GoonghapModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,birthTime: freezed == birthTime ? _self.birthTime : birthTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoonghapStatus,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: freezed == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,goonghapSummary: freezed == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Details?,tips: freezed == tips ? _self._tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,localizedResults: freezed == localizedResults ? _self._localizedResults : localizedResults // ignore: cast_nullable_to_non_nullable
as Map<String, LocalizedGoonghap>?,isAds: freezed == isAds ? _self.isAds : isAds // ignore: cast_nullable_to_non_nullable
as bool?,isPaid: freezed == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistModelCopyWith<$Res> get artist {
  
  return $ArtistModelCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of GoonghapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $DetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// @nodoc
mixin _$LocalizedGoonghap {

 String get language;@JsonKey(name: 'score') int get score;@JsonKey(name: 'score_title') String get scoreTitle;@JsonKey(name: 'goonghap_summary') String get goonghapSummary;@JsonKey(name: 'details') Details? get details; List<String> get tips;
/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalizedGoonghapCopyWith<LocalizedGoonghap> get copyWith => _$LocalizedGoonghapCopyWithImpl<LocalizedGoonghap>(this as LocalizedGoonghap, _$identity);

  /// Serializes this LocalizedGoonghap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalizedGoonghap&&(identical(other.language, language) || other.language == language)&&(identical(other.score, score) || other.score == score)&&(identical(other.scoreTitle, scoreTitle) || other.scoreTitle == scoreTitle)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other.tips, tips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,score,scoreTitle,goonghapSummary,details,const DeepCollectionEquality().hash(tips));

@override
String toString() {
  return 'LocalizedGoonghap(language: $language, score: $score, scoreTitle: $scoreTitle, goonghapSummary: $goonghapSummary, details: $details, tips: $tips)';
}


}

/// @nodoc
abstract mixin class $LocalizedGoonghapCopyWith<$Res>  {
  factory $LocalizedGoonghapCopyWith(LocalizedGoonghap value, $Res Function(LocalizedGoonghap) _then) = _$LocalizedGoonghapCopyWithImpl;
@useResult
$Res call({
 String language,@JsonKey(name: 'score') int score,@JsonKey(name: 'score_title') String scoreTitle,@JsonKey(name: 'goonghap_summary') String goonghapSummary,@JsonKey(name: 'details') Details? details, List<String> tips
});


$DetailsCopyWith<$Res>? get details;

}
/// @nodoc
class _$LocalizedGoonghapCopyWithImpl<$Res>
    implements $LocalizedGoonghapCopyWith<$Res> {
  _$LocalizedGoonghapCopyWithImpl(this._self, this._then);

  final LocalizedGoonghap _self;
  final $Res Function(LocalizedGoonghap) _then;

/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? score = null,Object? scoreTitle = null,Object? goonghapSummary = null,Object? details = freezed,Object? tips = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,scoreTitle: null == scoreTitle ? _self.scoreTitle : scoreTitle // ignore: cast_nullable_to_non_nullable
as String,goonghapSummary: null == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Details?,tips: null == tips ? _self.tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $DetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalizedGoonghap].
extension LocalizedGoonghapPatterns on LocalizedGoonghap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalizedGoonghap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalizedGoonghap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalizedGoonghap value)  $default,){
final _that = this;
switch (_that) {
case _LocalizedGoonghap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalizedGoonghap value)?  $default,){
final _that = this;
switch (_that) {
case _LocalizedGoonghap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language, @JsonKey(name: 'score')  int score, @JsonKey(name: 'score_title')  String scoreTitle, @JsonKey(name: 'goonghap_summary')  String goonghapSummary, @JsonKey(name: 'details')  Details? details,  List<String> tips)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalizedGoonghap() when $default != null:
return $default(_that.language,_that.score,_that.scoreTitle,_that.goonghapSummary,_that.details,_that.tips);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language, @JsonKey(name: 'score')  int score, @JsonKey(name: 'score_title')  String scoreTitle, @JsonKey(name: 'goonghap_summary')  String goonghapSummary, @JsonKey(name: 'details')  Details? details,  List<String> tips)  $default,) {final _that = this;
switch (_that) {
case _LocalizedGoonghap():
return $default(_that.language,_that.score,_that.scoreTitle,_that.goonghapSummary,_that.details,_that.tips);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language, @JsonKey(name: 'score')  int score, @JsonKey(name: 'score_title')  String scoreTitle, @JsonKey(name: 'goonghap_summary')  String goonghapSummary, @JsonKey(name: 'details')  Details? details,  List<String> tips)?  $default,) {final _that = this;
switch (_that) {
case _LocalizedGoonghap() when $default != null:
return $default(_that.language,_that.score,_that.scoreTitle,_that.goonghapSummary,_that.details,_that.tips);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalizedGoonghap implements LocalizedGoonghap {
  const _LocalizedGoonghap({required this.language, @JsonKey(name: 'score') this.score = 0, @JsonKey(name: 'score_title') this.scoreTitle = '', @JsonKey(name: 'goonghap_summary') this.goonghapSummary = '', @JsonKey(name: 'details') this.details, final  List<String> tips = const []}): _tips = tips;
  factory _LocalizedGoonghap.fromJson(Map<String, dynamic> json) => _$LocalizedGoonghapFromJson(json);

@override final  String language;
@override@JsonKey(name: 'score') final  int score;
@override@JsonKey(name: 'score_title') final  String scoreTitle;
@override@JsonKey(name: 'goonghap_summary') final  String goonghapSummary;
@override@JsonKey(name: 'details') final  Details? details;
 final  List<String> _tips;
@override@JsonKey() List<String> get tips {
  if (_tips is EqualUnmodifiableListView) return _tips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tips);
}


/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalizedGoonghapCopyWith<_LocalizedGoonghap> get copyWith => __$LocalizedGoonghapCopyWithImpl<_LocalizedGoonghap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalizedGoonghapToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalizedGoonghap&&(identical(other.language, language) || other.language == language)&&(identical(other.score, score) || other.score == score)&&(identical(other.scoreTitle, scoreTitle) || other.scoreTitle == scoreTitle)&&(identical(other.goonghapSummary, goonghapSummary) || other.goonghapSummary == goonghapSummary)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other._tips, _tips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,score,scoreTitle,goonghapSummary,details,const DeepCollectionEquality().hash(_tips));

@override
String toString() {
  return 'LocalizedGoonghap(language: $language, score: $score, scoreTitle: $scoreTitle, goonghapSummary: $goonghapSummary, details: $details, tips: $tips)';
}


}

/// @nodoc
abstract mixin class _$LocalizedGoonghapCopyWith<$Res> implements $LocalizedGoonghapCopyWith<$Res> {
  factory _$LocalizedGoonghapCopyWith(_LocalizedGoonghap value, $Res Function(_LocalizedGoonghap) _then) = __$LocalizedGoonghapCopyWithImpl;
@override @useResult
$Res call({
 String language,@JsonKey(name: 'score') int score,@JsonKey(name: 'score_title') String scoreTitle,@JsonKey(name: 'goonghap_summary') String goonghapSummary,@JsonKey(name: 'details') Details? details, List<String> tips
});


@override $DetailsCopyWith<$Res>? get details;

}
/// @nodoc
class __$LocalizedGoonghapCopyWithImpl<$Res>
    implements _$LocalizedGoonghapCopyWith<$Res> {
  __$LocalizedGoonghapCopyWithImpl(this._self, this._then);

  final _LocalizedGoonghap _self;
  final $Res Function(_LocalizedGoonghap) _then;

/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? score = null,Object? scoreTitle = null,Object? goonghapSummary = null,Object? details = freezed,Object? tips = null,}) {
  return _then(_LocalizedGoonghap(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,scoreTitle: null == scoreTitle ? _self.scoreTitle : scoreTitle // ignore: cast_nullable_to_non_nullable
as String,goonghapSummary: null == goonghapSummary ? _self.goonghapSummary : goonghapSummary // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Details?,tips: null == tips ? _self._tips : tips // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of LocalizedGoonghap
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $DetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// @nodoc
mixin _$Details {

 StyleDetails get style; ActivitiesDetails get activities;
/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailsCopyWith<Details> get copyWith => _$DetailsCopyWithImpl<Details>(this as Details, _$identity);

  /// Serializes this Details to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Details&&(identical(other.style, style) || other.style == style)&&(identical(other.activities, activities) || other.activities == activities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,style,activities);

@override
String toString() {
  return 'Details(style: $style, activities: $activities)';
}


}

/// @nodoc
abstract mixin class $DetailsCopyWith<$Res>  {
  factory $DetailsCopyWith(Details value, $Res Function(Details) _then) = _$DetailsCopyWithImpl;
@useResult
$Res call({
 StyleDetails style, ActivitiesDetails activities
});


$StyleDetailsCopyWith<$Res> get style;$ActivitiesDetailsCopyWith<$Res> get activities;

}
/// @nodoc
class _$DetailsCopyWithImpl<$Res>
    implements $DetailsCopyWith<$Res> {
  _$DetailsCopyWithImpl(this._self, this._then);

  final Details _self;
  final $Res Function(Details) _then;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? style = null,Object? activities = null,}) {
  return _then(_self.copyWith(
style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as StyleDetails,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as ActivitiesDetails,
  ));
}
/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StyleDetailsCopyWith<$Res> get style {
  
  return $StyleDetailsCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivitiesDetailsCopyWith<$Res> get activities {
  
  return $ActivitiesDetailsCopyWith<$Res>(_self.activities, (value) {
    return _then(_self.copyWith(activities: value));
  });
}
}


/// Adds pattern-matching-related methods to [Details].
extension DetailsPatterns on Details {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Details value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Details() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Details value)  $default,){
final _that = this;
switch (_that) {
case _Details():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Details value)?  $default,){
final _that = this;
switch (_that) {
case _Details() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StyleDetails style,  ActivitiesDetails activities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Details() when $default != null:
return $default(_that.style,_that.activities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StyleDetails style,  ActivitiesDetails activities)  $default,) {final _that = this;
switch (_that) {
case _Details():
return $default(_that.style,_that.activities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StyleDetails style,  ActivitiesDetails activities)?  $default,) {final _that = this;
switch (_that) {
case _Details() when $default != null:
return $default(_that.style,_that.activities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Details implements Details {
  const _Details({required this.style, required this.activities});
  factory _Details.fromJson(Map<String, dynamic> json) => _$DetailsFromJson(json);

@override final  StyleDetails style;
@override final  ActivitiesDetails activities;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetailsCopyWith<_Details> get copyWith => __$DetailsCopyWithImpl<_Details>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Details&&(identical(other.style, style) || other.style == style)&&(identical(other.activities, activities) || other.activities == activities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,style,activities);

@override
String toString() {
  return 'Details(style: $style, activities: $activities)';
}


}

/// @nodoc
abstract mixin class _$DetailsCopyWith<$Res> implements $DetailsCopyWith<$Res> {
  factory _$DetailsCopyWith(_Details value, $Res Function(_Details) _then) = __$DetailsCopyWithImpl;
@override @useResult
$Res call({
 StyleDetails style, ActivitiesDetails activities
});


@override $StyleDetailsCopyWith<$Res> get style;@override $ActivitiesDetailsCopyWith<$Res> get activities;

}
/// @nodoc
class __$DetailsCopyWithImpl<$Res>
    implements _$DetailsCopyWith<$Res> {
  __$DetailsCopyWithImpl(this._self, this._then);

  final _Details _self;
  final $Res Function(_Details) _then;

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? style = null,Object? activities = null,}) {
  return _then(_Details(
style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as StyleDetails,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as ActivitiesDetails,
  ));
}

/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StyleDetailsCopyWith<$Res> get style {
  
  return $StyleDetailsCopyWith<$Res>(_self.style, (value) {
    return _then(_self.copyWith(style: value));
  });
}/// Create a copy of Details
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivitiesDetailsCopyWith<$Res> get activities {
  
  return $ActivitiesDetailsCopyWith<$Res>(_self.activities, (value) {
    return _then(_self.copyWith(activities: value));
  });
}
}


/// @nodoc
mixin _$StyleDetails {

@JsonKey(name: 'idol_style') String get idolStyle;@JsonKey(name: 'user_style') String get userStyle;@JsonKey(name: 'couple_style') String get coupleStyle;
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
@JsonKey(name: 'idol_style') String idolStyle,@JsonKey(name: 'user_style') String userStyle,@JsonKey(name: 'couple_style') String coupleStyle
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
@pragma('vm:prefer-inline') @override $Res call({Object? idolStyle = null,Object? userStyle = null,Object? coupleStyle = null,}) {
  return _then(_self.copyWith(
idolStyle: null == idolStyle ? _self.idolStyle : idolStyle // ignore: cast_nullable_to_non_nullable
as String,userStyle: null == userStyle ? _self.userStyle : userStyle // ignore: cast_nullable_to_non_nullable
as String,coupleStyle: null == coupleStyle ? _self.coupleStyle : coupleStyle // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'idol_style')  String idolStyle, @JsonKey(name: 'user_style')  String userStyle, @JsonKey(name: 'couple_style')  String coupleStyle)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'idol_style')  String idolStyle, @JsonKey(name: 'user_style')  String userStyle, @JsonKey(name: 'couple_style')  String coupleStyle)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'idol_style')  String idolStyle, @JsonKey(name: 'user_style')  String userStyle, @JsonKey(name: 'couple_style')  String coupleStyle)?  $default,) {final _that = this;
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
  const _StyleDetails({@JsonKey(name: 'idol_style') required this.idolStyle, @JsonKey(name: 'user_style') required this.userStyle, @JsonKey(name: 'couple_style') required this.coupleStyle});
  factory _StyleDetails.fromJson(Map<String, dynamic> json) => _$StyleDetailsFromJson(json);

@override@JsonKey(name: 'idol_style') final  String idolStyle;
@override@JsonKey(name: 'user_style') final  String userStyle;
@override@JsonKey(name: 'couple_style') final  String coupleStyle;

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
@JsonKey(name: 'idol_style') String idolStyle,@JsonKey(name: 'user_style') String userStyle,@JsonKey(name: 'couple_style') String coupleStyle
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
@override @pragma('vm:prefer-inline') $Res call({Object? idolStyle = null,Object? userStyle = null,Object? coupleStyle = null,}) {
  return _then(_StyleDetails(
idolStyle: null == idolStyle ? _self.idolStyle : idolStyle // ignore: cast_nullable_to_non_nullable
as String,userStyle: null == userStyle ? _self.userStyle : userStyle // ignore: cast_nullable_to_non_nullable
as String,coupleStyle: null == coupleStyle ? _self.coupleStyle : coupleStyle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ActivitiesDetails {

 List<String> get recommended; String get description;
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
 List<String> recommended, String description
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
@pragma('vm:prefer-inline') @override $Res call({Object? recommended = null,Object? description = null,}) {
  return _then(_self.copyWith(
recommended: null == recommended ? _self.recommended : recommended // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> recommended,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> recommended,  String description)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> recommended,  String description)?  $default,) {final _that = this;
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
  const _ActivitiesDetails({required final  List<String> recommended, required this.description}): _recommended = recommended;
  factory _ActivitiesDetails.fromJson(Map<String, dynamic> json) => _$ActivitiesDetailsFromJson(json);

 final  List<String> _recommended;
@override List<String> get recommended {
  if (_recommended is EqualUnmodifiableListView) return _recommended;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommended);
}

@override final  String description;

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
 List<String> recommended, String description
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
@override @pragma('vm:prefer-inline') $Res call({Object? recommended = null,Object? description = null,}) {
  return _then(_ActivitiesDetails(
recommended: null == recommended ? _self._recommended : recommended // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
