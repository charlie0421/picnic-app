// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/promotion/promotion_campaign_v2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivePromotionCampaignV2Model {

@JsonKey(name: 'campaign_id') String get campaignId;@JsonKey(name: 'campaign_version_id') String get campaignVersionId; String get code;@JsonKey(name: 'display_name') Map<String, dynamic> get displayName;@JsonKey(name: 'multiplier_tenths')@_StrictIntConverter() int get multiplierTenths;@JsonKey(name: 'event_starts_at')@_StrictTimestampConverter() DateTime get eventStartsAt;@JsonKey(name: 'event_ends_at')@_StrictTimestampConverter() DateTime get eventEndsAt;@JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter() List<int> get repeatIsoDows;@JsonKey(name: 'home_creative') PromotionCreativeModel? get homeCreative;
/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePromotionCampaignV2ModelCopyWith<ActivePromotionCampaignV2Model> get copyWith => _$ActivePromotionCampaignV2ModelCopyWithImpl<ActivePromotionCampaignV2Model>(this as ActivePromotionCampaignV2Model, _$identity);

  /// Serializes this ActivePromotionCampaignV2Model to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePromotionCampaignV2Model&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.displayName, displayName)&&(identical(other.multiplierTenths, multiplierTenths) || other.multiplierTenths == multiplierTenths)&&(identical(other.eventStartsAt, eventStartsAt) || other.eventStartsAt == eventStartsAt)&&(identical(other.eventEndsAt, eventEndsAt) || other.eventEndsAt == eventEndsAt)&&const DeepCollectionEquality().equals(other.repeatIsoDows, repeatIsoDows)&&(identical(other.homeCreative, homeCreative) || other.homeCreative == homeCreative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,campaignVersionId,code,const DeepCollectionEquality().hash(displayName),multiplierTenths,eventStartsAt,eventEndsAt,const DeepCollectionEquality().hash(repeatIsoDows),homeCreative);

@override
String toString() {
  return 'ActivePromotionCampaignV2Model(campaignId: $campaignId, campaignVersionId: $campaignVersionId, code: $code, displayName: $displayName, multiplierTenths: $multiplierTenths, eventStartsAt: $eventStartsAt, eventEndsAt: $eventEndsAt, repeatIsoDows: $repeatIsoDows, homeCreative: $homeCreative)';
}


}

/// @nodoc
abstract mixin class $ActivePromotionCampaignV2ModelCopyWith<$Res>  {
  factory $ActivePromotionCampaignV2ModelCopyWith(ActivePromotionCampaignV2Model value, $Res Function(ActivePromotionCampaignV2Model) _then) = _$ActivePromotionCampaignV2ModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId,@JsonKey(name: 'campaign_version_id') String campaignVersionId, String code,@JsonKey(name: 'display_name') Map<String, dynamic> displayName,@JsonKey(name: 'multiplier_tenths')@_StrictIntConverter() int multiplierTenths,@JsonKey(name: 'event_starts_at')@_StrictTimestampConverter() DateTime eventStartsAt,@JsonKey(name: 'event_ends_at')@_StrictTimestampConverter() DateTime eventEndsAt,@JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter() List<int> repeatIsoDows,@JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative
});


$PromotionCreativeModelCopyWith<$Res>? get homeCreative;

}
/// @nodoc
class _$ActivePromotionCampaignV2ModelCopyWithImpl<$Res>
    implements $ActivePromotionCampaignV2ModelCopyWith<$Res> {
  _$ActivePromotionCampaignV2ModelCopyWithImpl(this._self, this._then);

  final ActivePromotionCampaignV2Model _self;
  final $Res Function(ActivePromotionCampaignV2Model) _then;

/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? campaignId = null,Object? campaignVersionId = null,Object? code = null,Object? displayName = null,Object? multiplierTenths = null,Object? eventStartsAt = null,Object? eventEndsAt = null,Object? repeatIsoDows = null,Object? homeCreative = freezed,}) {
  return _then(_self.copyWith(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,campaignVersionId: null == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,multiplierTenths: null == multiplierTenths ? _self.multiplierTenths : multiplierTenths // ignore: cast_nullable_to_non_nullable
as int,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventEndsAt: null == eventEndsAt ? _self.eventEndsAt : eventEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,repeatIsoDows: null == repeatIsoDows ? _self.repeatIsoDows : repeatIsoDows // ignore: cast_nullable_to_non_nullable
as List<int>,homeCreative: freezed == homeCreative ? _self.homeCreative : homeCreative // ignore: cast_nullable_to_non_nullable
as PromotionCreativeModel?,
  ));
}
/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PromotionCreativeModelCopyWith<$Res>? get homeCreative {
    if (_self.homeCreative == null) {
    return null;
  }

  return $PromotionCreativeModelCopyWith<$Res>(_self.homeCreative!, (value) {
    return _then(_self.copyWith(homeCreative: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivePromotionCampaignV2Model].
extension ActivePromotionCampaignV2ModelPatterns on ActivePromotionCampaignV2Model {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePromotionCampaignV2Model value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePromotionCampaignV2Model value)  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePromotionCampaignV2Model value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'multiplier_tenths')@_StrictIntConverter()  int multiplierTenths, @JsonKey(name: 'event_starts_at')@_StrictTimestampConverter()  DateTime eventStartsAt, @JsonKey(name: 'event_ends_at')@_StrictTimestampConverter()  DateTime eventEndsAt, @JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter()  List<int> repeatIsoDows, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model() when $default != null:
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.multiplierTenths,_that.eventStartsAt,_that.eventEndsAt,_that.repeatIsoDows,_that.homeCreative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'multiplier_tenths')@_StrictIntConverter()  int multiplierTenths, @JsonKey(name: 'event_starts_at')@_StrictTimestampConverter()  DateTime eventStartsAt, @JsonKey(name: 'event_ends_at')@_StrictTimestampConverter()  DateTime eventEndsAt, @JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter()  List<int> repeatIsoDows, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model():
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.multiplierTenths,_that.eventStartsAt,_that.eventEndsAt,_that.repeatIsoDows,_that.homeCreative);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'multiplier_tenths')@_StrictIntConverter()  int multiplierTenths, @JsonKey(name: 'event_starts_at')@_StrictTimestampConverter()  DateTime eventStartsAt, @JsonKey(name: 'event_ends_at')@_StrictTimestampConverter()  DateTime eventEndsAt, @JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter()  List<int> repeatIsoDows, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)?  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignV2Model() when $default != null:
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.multiplierTenths,_that.eventStartsAt,_that.eventEndsAt,_that.repeatIsoDows,_that.homeCreative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivePromotionCampaignV2Model extends ActivePromotionCampaignV2Model {
  const _ActivePromotionCampaignV2Model({@JsonKey(name: 'campaign_id') required this.campaignId, @JsonKey(name: 'campaign_version_id') required this.campaignVersionId, required this.code, @JsonKey(name: 'display_name') required final  Map<String, dynamic> displayName, @JsonKey(name: 'multiplier_tenths')@_StrictIntConverter() required this.multiplierTenths, @JsonKey(name: 'event_starts_at')@_StrictTimestampConverter() required this.eventStartsAt, @JsonKey(name: 'event_ends_at')@_StrictTimestampConverter() required this.eventEndsAt, @JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter() required final  List<int> repeatIsoDows, @JsonKey(name: 'home_creative') this.homeCreative}): _displayName = displayName,_repeatIsoDows = repeatIsoDows,super._();
  factory _ActivePromotionCampaignV2Model.fromJson(Map<String, dynamic> json) => _$ActivePromotionCampaignV2ModelFromJson(json);

@override@JsonKey(name: 'campaign_id') final  String campaignId;
@override@JsonKey(name: 'campaign_version_id') final  String campaignVersionId;
@override final  String code;
 final  Map<String, dynamic> _displayName;
@override@JsonKey(name: 'display_name') Map<String, dynamic> get displayName {
  if (_displayName is EqualUnmodifiableMapView) return _displayName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_displayName);
}

@override@JsonKey(name: 'multiplier_tenths')@_StrictIntConverter() final  int multiplierTenths;
@override@JsonKey(name: 'event_starts_at')@_StrictTimestampConverter() final  DateTime eventStartsAt;
@override@JsonKey(name: 'event_ends_at')@_StrictTimestampConverter() final  DateTime eventEndsAt;
 final  List<int> _repeatIsoDows;
@override@JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter() List<int> get repeatIsoDows {
  if (_repeatIsoDows is EqualUnmodifiableListView) return _repeatIsoDows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_repeatIsoDows);
}

@override@JsonKey(name: 'home_creative') final  PromotionCreativeModel? homeCreative;

/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePromotionCampaignV2ModelCopyWith<_ActivePromotionCampaignV2Model> get copyWith => __$ActivePromotionCampaignV2ModelCopyWithImpl<_ActivePromotionCampaignV2Model>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivePromotionCampaignV2ModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePromotionCampaignV2Model&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other._displayName, _displayName)&&(identical(other.multiplierTenths, multiplierTenths) || other.multiplierTenths == multiplierTenths)&&(identical(other.eventStartsAt, eventStartsAt) || other.eventStartsAt == eventStartsAt)&&(identical(other.eventEndsAt, eventEndsAt) || other.eventEndsAt == eventEndsAt)&&const DeepCollectionEquality().equals(other._repeatIsoDows, _repeatIsoDows)&&(identical(other.homeCreative, homeCreative) || other.homeCreative == homeCreative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,campaignVersionId,code,const DeepCollectionEquality().hash(_displayName),multiplierTenths,eventStartsAt,eventEndsAt,const DeepCollectionEquality().hash(_repeatIsoDows),homeCreative);

@override
String toString() {
  return 'ActivePromotionCampaignV2Model(campaignId: $campaignId, campaignVersionId: $campaignVersionId, code: $code, displayName: $displayName, multiplierTenths: $multiplierTenths, eventStartsAt: $eventStartsAt, eventEndsAt: $eventEndsAt, repeatIsoDows: $repeatIsoDows, homeCreative: $homeCreative)';
}


}

/// @nodoc
abstract mixin class _$ActivePromotionCampaignV2ModelCopyWith<$Res> implements $ActivePromotionCampaignV2ModelCopyWith<$Res> {
  factory _$ActivePromotionCampaignV2ModelCopyWith(_ActivePromotionCampaignV2Model value, $Res Function(_ActivePromotionCampaignV2Model) _then) = __$ActivePromotionCampaignV2ModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId,@JsonKey(name: 'campaign_version_id') String campaignVersionId, String code,@JsonKey(name: 'display_name') Map<String, dynamic> displayName,@JsonKey(name: 'multiplier_tenths')@_StrictIntConverter() int multiplierTenths,@JsonKey(name: 'event_starts_at')@_StrictTimestampConverter() DateTime eventStartsAt,@JsonKey(name: 'event_ends_at')@_StrictTimestampConverter() DateTime eventEndsAt,@JsonKey(name: 'repeat_iso_dows')@_StrictIntListConverter() List<int> repeatIsoDows,@JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative
});


@override $PromotionCreativeModelCopyWith<$Res>? get homeCreative;

}
/// @nodoc
class __$ActivePromotionCampaignV2ModelCopyWithImpl<$Res>
    implements _$ActivePromotionCampaignV2ModelCopyWith<$Res> {
  __$ActivePromotionCampaignV2ModelCopyWithImpl(this._self, this._then);

  final _ActivePromotionCampaignV2Model _self;
  final $Res Function(_ActivePromotionCampaignV2Model) _then;

/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? campaignId = null,Object? campaignVersionId = null,Object? code = null,Object? displayName = null,Object? multiplierTenths = null,Object? eventStartsAt = null,Object? eventEndsAt = null,Object? repeatIsoDows = null,Object? homeCreative = freezed,}) {
  return _then(_ActivePromotionCampaignV2Model(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,campaignVersionId: null == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self._displayName : displayName // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,multiplierTenths: null == multiplierTenths ? _self.multiplierTenths : multiplierTenths // ignore: cast_nullable_to_non_nullable
as int,eventStartsAt: null == eventStartsAt ? _self.eventStartsAt : eventStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,eventEndsAt: null == eventEndsAt ? _self.eventEndsAt : eventEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,repeatIsoDows: null == repeatIsoDows ? _self._repeatIsoDows : repeatIsoDows // ignore: cast_nullable_to_non_nullable
as List<int>,homeCreative: freezed == homeCreative ? _self.homeCreative : homeCreative // ignore: cast_nullable_to_non_nullable
as PromotionCreativeModel?,
  ));
}

/// Create a copy of ActivePromotionCampaignV2Model
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PromotionCreativeModelCopyWith<$Res>? get homeCreative {
    if (_self.homeCreative == null) {
    return null;
  }

  return $PromotionCreativeModelCopyWith<$Res>(_self.homeCreative!, (value) {
    return _then(_self.copyWith(homeCreative: value));
  });
}
}


/// @nodoc
mixin _$ActivePromotionCampaignsV2Model {

 List<ActivePromotionCampaignV2Model> get items;@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt get totalCount;@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'snapshot_at')@_StrictTimestampConverter() DateTime get snapshotAt;@JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter() List<int> get campaignOwnedHomeBannerIds;
/// Create a copy of ActivePromotionCampaignsV2Model
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePromotionCampaignsV2ModelCopyWith<ActivePromotionCampaignsV2Model> get copyWith => _$ActivePromotionCampaignsV2ModelCopyWithImpl<ActivePromotionCampaignsV2Model>(this as ActivePromotionCampaignsV2Model, _$identity);

  /// Serializes this ActivePromotionCampaignsV2Model to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePromotionCampaignsV2Model&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt)&&const DeepCollectionEquality().equals(other.campaignOwnedHomeBannerIds, campaignOwnedHomeBannerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,nextCursor,snapshotAt,const DeepCollectionEquality().hash(campaignOwnedHomeBannerIds));

@override
String toString() {
  return 'ActivePromotionCampaignsV2Model(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt, campaignOwnedHomeBannerIds: $campaignOwnedHomeBannerIds)';
}


}

/// @nodoc
abstract mixin class $ActivePromotionCampaignsV2ModelCopyWith<$Res>  {
  factory $ActivePromotionCampaignsV2ModelCopyWith(ActivePromotionCampaignsV2Model value, $Res Function(ActivePromotionCampaignsV2Model) _then) = _$ActivePromotionCampaignsV2ModelCopyWithImpl;
@useResult
$Res call({
 List<ActivePromotionCampaignV2Model> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at')@_StrictTimestampConverter() DateTime snapshotAt,@JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter() List<int> campaignOwnedHomeBannerIds
});




}
/// @nodoc
class _$ActivePromotionCampaignsV2ModelCopyWithImpl<$Res>
    implements $ActivePromotionCampaignsV2ModelCopyWith<$Res> {
  _$ActivePromotionCampaignsV2ModelCopyWithImpl(this._self, this._then);

  final ActivePromotionCampaignsV2Model _self;
  final $Res Function(ActivePromotionCampaignsV2Model) _then;

/// Create a copy of ActivePromotionCampaignsV2Model
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,Object? campaignOwnedHomeBannerIds = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ActivePromotionCampaignV2Model>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,campaignOwnedHomeBannerIds: null == campaignOwnedHomeBannerIds ? _self.campaignOwnedHomeBannerIds : campaignOwnedHomeBannerIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivePromotionCampaignsV2Model].
extension ActivePromotionCampaignsV2ModelPatterns on ActivePromotionCampaignsV2Model {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePromotionCampaignsV2Model value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePromotionCampaignsV2Model value)  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePromotionCampaignsV2Model value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ActivePromotionCampaignV2Model> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')@_StrictTimestampConverter()  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter()  List<int> campaignOwnedHomeBannerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt,_that.campaignOwnedHomeBannerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ActivePromotionCampaignV2Model> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')@_StrictTimestampConverter()  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter()  List<int> campaignOwnedHomeBannerIds)  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model():
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt,_that.campaignOwnedHomeBannerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ActivePromotionCampaignV2Model> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')@_StrictTimestampConverter()  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter()  List<int> campaignOwnedHomeBannerIds)?  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsV2Model() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt,_that.campaignOwnedHomeBannerIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivePromotionCampaignsV2Model extends ActivePromotionCampaignsV2Model {
  const _ActivePromotionCampaignsV2Model({required final  List<ActivePromotionCampaignV2Model> items, @JsonKey(name: 'total_count')@WalletAmountConverter() required this.totalCount, @JsonKey(name: 'next_cursor') this.nextCursor, @JsonKey(name: 'snapshot_at')@_StrictTimestampConverter() required this.snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter() required final  List<int> campaignOwnedHomeBannerIds}): _items = items,_campaignOwnedHomeBannerIds = campaignOwnedHomeBannerIds,super._();
  factory _ActivePromotionCampaignsV2Model.fromJson(Map<String, dynamic> json) => _$ActivePromotionCampaignsV2ModelFromJson(json);

 final  List<ActivePromotionCampaignV2Model> _items;
@override List<ActivePromotionCampaignV2Model> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count')@WalletAmountConverter() final  BigInt totalCount;
@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'snapshot_at')@_StrictTimestampConverter() final  DateTime snapshotAt;
 final  List<int> _campaignOwnedHomeBannerIds;
@override@JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter() List<int> get campaignOwnedHomeBannerIds {
  if (_campaignOwnedHomeBannerIds is EqualUnmodifiableListView) return _campaignOwnedHomeBannerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_campaignOwnedHomeBannerIds);
}


/// Create a copy of ActivePromotionCampaignsV2Model
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePromotionCampaignsV2ModelCopyWith<_ActivePromotionCampaignsV2Model> get copyWith => __$ActivePromotionCampaignsV2ModelCopyWithImpl<_ActivePromotionCampaignsV2Model>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivePromotionCampaignsV2ModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePromotionCampaignsV2Model&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt)&&const DeepCollectionEquality().equals(other._campaignOwnedHomeBannerIds, _campaignOwnedHomeBannerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,nextCursor,snapshotAt,const DeepCollectionEquality().hash(_campaignOwnedHomeBannerIds));

@override
String toString() {
  return 'ActivePromotionCampaignsV2Model(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt, campaignOwnedHomeBannerIds: $campaignOwnedHomeBannerIds)';
}


}

/// @nodoc
abstract mixin class _$ActivePromotionCampaignsV2ModelCopyWith<$Res> implements $ActivePromotionCampaignsV2ModelCopyWith<$Res> {
  factory _$ActivePromotionCampaignsV2ModelCopyWith(_ActivePromotionCampaignsV2Model value, $Res Function(_ActivePromotionCampaignsV2Model) _then) = __$ActivePromotionCampaignsV2ModelCopyWithImpl;
@override @useResult
$Res call({
 List<ActivePromotionCampaignV2Model> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at')@_StrictTimestampConverter() DateTime snapshotAt,@JsonKey(name: 'campaign_owned_home_banner_ids')@_StrictIntListConverter() List<int> campaignOwnedHomeBannerIds
});




}
/// @nodoc
class __$ActivePromotionCampaignsV2ModelCopyWithImpl<$Res>
    implements _$ActivePromotionCampaignsV2ModelCopyWith<$Res> {
  __$ActivePromotionCampaignsV2ModelCopyWithImpl(this._self, this._then);

  final _ActivePromotionCampaignsV2Model _self;
  final $Res Function(_ActivePromotionCampaignsV2Model) _then;

/// Create a copy of ActivePromotionCampaignsV2Model
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,Object? campaignOwnedHomeBannerIds = null,}) {
  return _then(_ActivePromotionCampaignsV2Model(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ActivePromotionCampaignV2Model>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,campaignOwnedHomeBannerIds: null == campaignOwnedHomeBannerIds ? _self._campaignOwnedHomeBannerIds : campaignOwnedHomeBannerIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
