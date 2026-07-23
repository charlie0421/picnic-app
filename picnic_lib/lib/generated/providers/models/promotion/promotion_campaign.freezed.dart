// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/promotion/promotion_campaign.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromotionCreativeModel {

@JsonKey(name: 'banner_id') int get bannerId; Map<String, dynamic> get title; Map<String, dynamic> get image; String? get thumbnail; String? get link; int get duration;
/// Create a copy of PromotionCreativeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromotionCreativeModelCopyWith<PromotionCreativeModel> get copyWith => _$PromotionCreativeModelCopyWithImpl<PromotionCreativeModel>(this as PromotionCreativeModel, _$identity);

  /// Serializes this PromotionCreativeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromotionCreativeModel&&(identical(other.bannerId, bannerId) || other.bannerId == bannerId)&&const DeepCollectionEquality().equals(other.title, title)&&const DeepCollectionEquality().equals(other.image, image)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.link, link) || other.link == link)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannerId,const DeepCollectionEquality().hash(title),const DeepCollectionEquality().hash(image),thumbnail,link,duration);

@override
String toString() {
  return 'PromotionCreativeModel(bannerId: $bannerId, title: $title, image: $image, thumbnail: $thumbnail, link: $link, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $PromotionCreativeModelCopyWith<$Res>  {
  factory $PromotionCreativeModelCopyWith(PromotionCreativeModel value, $Res Function(PromotionCreativeModel) _then) = _$PromotionCreativeModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'banner_id') int bannerId, Map<String, dynamic> title, Map<String, dynamic> image, String? thumbnail, String? link, int duration
});




}
/// @nodoc
class _$PromotionCreativeModelCopyWithImpl<$Res>
    implements $PromotionCreativeModelCopyWith<$Res> {
  _$PromotionCreativeModelCopyWithImpl(this._self, this._then);

  final PromotionCreativeModel _self;
  final $Res Function(PromotionCreativeModel) _then;

/// Create a copy of PromotionCreativeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bannerId = null,Object? title = null,Object? image = null,Object? thumbnail = freezed,Object? link = freezed,Object? duration = null,}) {
  return _then(_self.copyWith(
bannerId: null == bannerId ? _self.bannerId : bannerId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PromotionCreativeModel].
extension PromotionCreativeModelPatterns on PromotionCreativeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromotionCreativeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromotionCreativeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromotionCreativeModel value)  $default,){
final _that = this;
switch (_that) {
case _PromotionCreativeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromotionCreativeModel value)?  $default,){
final _that = this;
switch (_that) {
case _PromotionCreativeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'banner_id')  int bannerId,  Map<String, dynamic> title,  Map<String, dynamic> image,  String? thumbnail,  String? link,  int duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromotionCreativeModel() when $default != null:
return $default(_that.bannerId,_that.title,_that.image,_that.thumbnail,_that.link,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'banner_id')  int bannerId,  Map<String, dynamic> title,  Map<String, dynamic> image,  String? thumbnail,  String? link,  int duration)  $default,) {final _that = this;
switch (_that) {
case _PromotionCreativeModel():
return $default(_that.bannerId,_that.title,_that.image,_that.thumbnail,_that.link,_that.duration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'banner_id')  int bannerId,  Map<String, dynamic> title,  Map<String, dynamic> image,  String? thumbnail,  String? link,  int duration)?  $default,) {final _that = this;
switch (_that) {
case _PromotionCreativeModel() when $default != null:
return $default(_that.bannerId,_that.title,_that.image,_that.thumbnail,_that.link,_that.duration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromotionCreativeModel extends PromotionCreativeModel {
  const _PromotionCreativeModel({@JsonKey(name: 'banner_id') required this.bannerId, required final  Map<String, dynamic> title, required final  Map<String, dynamic> image, this.thumbnail, this.link, this.duration = 3000}): _title = title,_image = image,super._();
  factory _PromotionCreativeModel.fromJson(Map<String, dynamic> json) => _$PromotionCreativeModelFromJson(json);

@override@JsonKey(name: 'banner_id') final  int bannerId;
 final  Map<String, dynamic> _title;
@override Map<String, dynamic> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

 final  Map<String, dynamic> _image;
@override Map<String, dynamic> get image {
  if (_image is EqualUnmodifiableMapView) return _image;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_image);
}

@override final  String? thumbnail;
@override final  String? link;
@override@JsonKey() final  int duration;

/// Create a copy of PromotionCreativeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromotionCreativeModelCopyWith<_PromotionCreativeModel> get copyWith => __$PromotionCreativeModelCopyWithImpl<_PromotionCreativeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromotionCreativeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromotionCreativeModel&&(identical(other.bannerId, bannerId) || other.bannerId == bannerId)&&const DeepCollectionEquality().equals(other._title, _title)&&const DeepCollectionEquality().equals(other._image, _image)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.link, link) || other.link == link)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannerId,const DeepCollectionEquality().hash(_title),const DeepCollectionEquality().hash(_image),thumbnail,link,duration);

@override
String toString() {
  return 'PromotionCreativeModel(bannerId: $bannerId, title: $title, image: $image, thumbnail: $thumbnail, link: $link, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$PromotionCreativeModelCopyWith<$Res> implements $PromotionCreativeModelCopyWith<$Res> {
  factory _$PromotionCreativeModelCopyWith(_PromotionCreativeModel value, $Res Function(_PromotionCreativeModel) _then) = __$PromotionCreativeModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'banner_id') int bannerId, Map<String, dynamic> title, Map<String, dynamic> image, String? thumbnail, String? link, int duration
});




}
/// @nodoc
class __$PromotionCreativeModelCopyWithImpl<$Res>
    implements _$PromotionCreativeModelCopyWith<$Res> {
  __$PromotionCreativeModelCopyWithImpl(this._self, this._then);

  final _PromotionCreativeModel _self;
  final $Res Function(_PromotionCreativeModel) _then;

/// Create a copy of PromotionCreativeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bannerId = null,Object? title = null,Object? image = null,Object? thumbnail = freezed,Object? link = freezed,Object? duration = null,}) {
  return _then(_PromotionCreativeModel(
bannerId: null == bannerId ? _self.bannerId : bannerId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: null == image ? _self._image : image // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ActivePromotionCampaignModel {

@JsonKey(name: 'campaign_id') String get campaignId;@JsonKey(name: 'campaign_version_id') String get campaignVersionId; String get code;@JsonKey(name: 'display_name') Map<String, dynamic> get displayName;@JsonKey(name: 'extra_bonus_bps') int get extraBonusBps;@JsonKey(name: 'window_starts_at') DateTime get windowStartsAt;@JsonKey(name: 'window_ends_at') DateTime get windowEndsAt;@JsonKey(name: 'show_in_store') bool get showInStore;@JsonKey(name: 'show_home_banner') bool get showHomeBanner;@JsonKey(name: 'home_creative') PromotionCreativeModel? get homeCreative;
/// Create a copy of ActivePromotionCampaignModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePromotionCampaignModelCopyWith<ActivePromotionCampaignModel> get copyWith => _$ActivePromotionCampaignModelCopyWithImpl<ActivePromotionCampaignModel>(this as ActivePromotionCampaignModel, _$identity);

  /// Serializes this ActivePromotionCampaignModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePromotionCampaignModel&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.displayName, displayName)&&(identical(other.extraBonusBps, extraBonusBps) || other.extraBonusBps == extraBonusBps)&&(identical(other.windowStartsAt, windowStartsAt) || other.windowStartsAt == windowStartsAt)&&(identical(other.windowEndsAt, windowEndsAt) || other.windowEndsAt == windowEndsAt)&&(identical(other.showInStore, showInStore) || other.showInStore == showInStore)&&(identical(other.showHomeBanner, showHomeBanner) || other.showHomeBanner == showHomeBanner)&&(identical(other.homeCreative, homeCreative) || other.homeCreative == homeCreative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,campaignVersionId,code,const DeepCollectionEquality().hash(displayName),extraBonusBps,windowStartsAt,windowEndsAt,showInStore,showHomeBanner,homeCreative);

@override
String toString() {
  return 'ActivePromotionCampaignModel(campaignId: $campaignId, campaignVersionId: $campaignVersionId, code: $code, displayName: $displayName, extraBonusBps: $extraBonusBps, windowStartsAt: $windowStartsAt, windowEndsAt: $windowEndsAt, showInStore: $showInStore, showHomeBanner: $showHomeBanner, homeCreative: $homeCreative)';
}


}

/// @nodoc
abstract mixin class $ActivePromotionCampaignModelCopyWith<$Res>  {
  factory $ActivePromotionCampaignModelCopyWith(ActivePromotionCampaignModel value, $Res Function(ActivePromotionCampaignModel) _then) = _$ActivePromotionCampaignModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId,@JsonKey(name: 'campaign_version_id') String campaignVersionId, String code,@JsonKey(name: 'display_name') Map<String, dynamic> displayName,@JsonKey(name: 'extra_bonus_bps') int extraBonusBps,@JsonKey(name: 'window_starts_at') DateTime windowStartsAt,@JsonKey(name: 'window_ends_at') DateTime windowEndsAt,@JsonKey(name: 'show_in_store') bool showInStore,@JsonKey(name: 'show_home_banner') bool showHomeBanner,@JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative
});


$PromotionCreativeModelCopyWith<$Res>? get homeCreative;

}
/// @nodoc
class _$ActivePromotionCampaignModelCopyWithImpl<$Res>
    implements $ActivePromotionCampaignModelCopyWith<$Res> {
  _$ActivePromotionCampaignModelCopyWithImpl(this._self, this._then);

  final ActivePromotionCampaignModel _self;
  final $Res Function(ActivePromotionCampaignModel) _then;

/// Create a copy of ActivePromotionCampaignModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? campaignId = null,Object? campaignVersionId = null,Object? code = null,Object? displayName = null,Object? extraBonusBps = null,Object? windowStartsAt = null,Object? windowEndsAt = null,Object? showInStore = null,Object? showHomeBanner = null,Object? homeCreative = freezed,}) {
  return _then(_self.copyWith(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,campaignVersionId: null == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extraBonusBps: null == extraBonusBps ? _self.extraBonusBps : extraBonusBps // ignore: cast_nullable_to_non_nullable
as int,windowStartsAt: null == windowStartsAt ? _self.windowStartsAt : windowStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowEndsAt: null == windowEndsAt ? _self.windowEndsAt : windowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,showInStore: null == showInStore ? _self.showInStore : showInStore // ignore: cast_nullable_to_non_nullable
as bool,showHomeBanner: null == showHomeBanner ? _self.showHomeBanner : showHomeBanner // ignore: cast_nullable_to_non_nullable
as bool,homeCreative: freezed == homeCreative ? _self.homeCreative : homeCreative // ignore: cast_nullable_to_non_nullable
as PromotionCreativeModel?,
  ));
}
/// Create a copy of ActivePromotionCampaignModel
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


/// Adds pattern-matching-related methods to [ActivePromotionCampaignModel].
extension ActivePromotionCampaignModelPatterns on ActivePromotionCampaignModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePromotionCampaignModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePromotionCampaignModel value)  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePromotionCampaignModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'extra_bonus_bps')  int extraBonusBps, @JsonKey(name: 'window_starts_at')  DateTime windowStartsAt, @JsonKey(name: 'window_ends_at')  DateTime windowEndsAt, @JsonKey(name: 'show_in_store')  bool showInStore, @JsonKey(name: 'show_home_banner')  bool showHomeBanner, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel() when $default != null:
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.extraBonusBps,_that.windowStartsAt,_that.windowEndsAt,_that.showInStore,_that.showHomeBanner,_that.homeCreative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'extra_bonus_bps')  int extraBonusBps, @JsonKey(name: 'window_starts_at')  DateTime windowStartsAt, @JsonKey(name: 'window_ends_at')  DateTime windowEndsAt, @JsonKey(name: 'show_in_store')  bool showInStore, @JsonKey(name: 'show_home_banner')  bool showHomeBanner, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel():
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.extraBonusBps,_that.windowStartsAt,_that.windowEndsAt,_that.showInStore,_that.showHomeBanner,_that.homeCreative);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'campaign_id')  String campaignId, @JsonKey(name: 'campaign_version_id')  String campaignVersionId,  String code, @JsonKey(name: 'display_name')  Map<String, dynamic> displayName, @JsonKey(name: 'extra_bonus_bps')  int extraBonusBps, @JsonKey(name: 'window_starts_at')  DateTime windowStartsAt, @JsonKey(name: 'window_ends_at')  DateTime windowEndsAt, @JsonKey(name: 'show_in_store')  bool showInStore, @JsonKey(name: 'show_home_banner')  bool showHomeBanner, @JsonKey(name: 'home_creative')  PromotionCreativeModel? homeCreative)?  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignModel() when $default != null:
return $default(_that.campaignId,_that.campaignVersionId,_that.code,_that.displayName,_that.extraBonusBps,_that.windowStartsAt,_that.windowEndsAt,_that.showInStore,_that.showHomeBanner,_that.homeCreative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivePromotionCampaignModel extends ActivePromotionCampaignModel {
  const _ActivePromotionCampaignModel({@JsonKey(name: 'campaign_id') required this.campaignId, @JsonKey(name: 'campaign_version_id') required this.campaignVersionId, required this.code, @JsonKey(name: 'display_name') required final  Map<String, dynamic> displayName, @JsonKey(name: 'extra_bonus_bps') required this.extraBonusBps, @JsonKey(name: 'window_starts_at') required this.windowStartsAt, @JsonKey(name: 'window_ends_at') required this.windowEndsAt, @JsonKey(name: 'show_in_store') required this.showInStore, @JsonKey(name: 'show_home_banner') required this.showHomeBanner, @JsonKey(name: 'home_creative') this.homeCreative}): _displayName = displayName,super._();
  factory _ActivePromotionCampaignModel.fromJson(Map<String, dynamic> json) => _$ActivePromotionCampaignModelFromJson(json);

@override@JsonKey(name: 'campaign_id') final  String campaignId;
@override@JsonKey(name: 'campaign_version_id') final  String campaignVersionId;
@override final  String code;
 final  Map<String, dynamic> _displayName;
@override@JsonKey(name: 'display_name') Map<String, dynamic> get displayName {
  if (_displayName is EqualUnmodifiableMapView) return _displayName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_displayName);
}

@override@JsonKey(name: 'extra_bonus_bps') final  int extraBonusBps;
@override@JsonKey(name: 'window_starts_at') final  DateTime windowStartsAt;
@override@JsonKey(name: 'window_ends_at') final  DateTime windowEndsAt;
@override@JsonKey(name: 'show_in_store') final  bool showInStore;
@override@JsonKey(name: 'show_home_banner') final  bool showHomeBanner;
@override@JsonKey(name: 'home_creative') final  PromotionCreativeModel? homeCreative;

/// Create a copy of ActivePromotionCampaignModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePromotionCampaignModelCopyWith<_ActivePromotionCampaignModel> get copyWith => __$ActivePromotionCampaignModelCopyWithImpl<_ActivePromotionCampaignModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivePromotionCampaignModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePromotionCampaignModel&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other._displayName, _displayName)&&(identical(other.extraBonusBps, extraBonusBps) || other.extraBonusBps == extraBonusBps)&&(identical(other.windowStartsAt, windowStartsAt) || other.windowStartsAt == windowStartsAt)&&(identical(other.windowEndsAt, windowEndsAt) || other.windowEndsAt == windowEndsAt)&&(identical(other.showInStore, showInStore) || other.showInStore == showInStore)&&(identical(other.showHomeBanner, showHomeBanner) || other.showHomeBanner == showHomeBanner)&&(identical(other.homeCreative, homeCreative) || other.homeCreative == homeCreative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,campaignId,campaignVersionId,code,const DeepCollectionEquality().hash(_displayName),extraBonusBps,windowStartsAt,windowEndsAt,showInStore,showHomeBanner,homeCreative);

@override
String toString() {
  return 'ActivePromotionCampaignModel(campaignId: $campaignId, campaignVersionId: $campaignVersionId, code: $code, displayName: $displayName, extraBonusBps: $extraBonusBps, windowStartsAt: $windowStartsAt, windowEndsAt: $windowEndsAt, showInStore: $showInStore, showHomeBanner: $showHomeBanner, homeCreative: $homeCreative)';
}


}

/// @nodoc
abstract mixin class _$ActivePromotionCampaignModelCopyWith<$Res> implements $ActivePromotionCampaignModelCopyWith<$Res> {
  factory _$ActivePromotionCampaignModelCopyWith(_ActivePromotionCampaignModel value, $Res Function(_ActivePromotionCampaignModel) _then) = __$ActivePromotionCampaignModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'campaign_id') String campaignId,@JsonKey(name: 'campaign_version_id') String campaignVersionId, String code,@JsonKey(name: 'display_name') Map<String, dynamic> displayName,@JsonKey(name: 'extra_bonus_bps') int extraBonusBps,@JsonKey(name: 'window_starts_at') DateTime windowStartsAt,@JsonKey(name: 'window_ends_at') DateTime windowEndsAt,@JsonKey(name: 'show_in_store') bool showInStore,@JsonKey(name: 'show_home_banner') bool showHomeBanner,@JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative
});


@override $PromotionCreativeModelCopyWith<$Res>? get homeCreative;

}
/// @nodoc
class __$ActivePromotionCampaignModelCopyWithImpl<$Res>
    implements _$ActivePromotionCampaignModelCopyWith<$Res> {
  __$ActivePromotionCampaignModelCopyWithImpl(this._self, this._then);

  final _ActivePromotionCampaignModel _self;
  final $Res Function(_ActivePromotionCampaignModel) _then;

/// Create a copy of ActivePromotionCampaignModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? campaignId = null,Object? campaignVersionId = null,Object? code = null,Object? displayName = null,Object? extraBonusBps = null,Object? windowStartsAt = null,Object? windowEndsAt = null,Object? showInStore = null,Object? showHomeBanner = null,Object? homeCreative = freezed,}) {
  return _then(_ActivePromotionCampaignModel(
campaignId: null == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String,campaignVersionId: null == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self._displayName : displayName // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extraBonusBps: null == extraBonusBps ? _self.extraBonusBps : extraBonusBps // ignore: cast_nullable_to_non_nullable
as int,windowStartsAt: null == windowStartsAt ? _self.windowStartsAt : windowStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,windowEndsAt: null == windowEndsAt ? _self.windowEndsAt : windowEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,showInStore: null == showInStore ? _self.showInStore : showInStore // ignore: cast_nullable_to_non_nullable
as bool,showHomeBanner: null == showHomeBanner ? _self.showHomeBanner : showHomeBanner // ignore: cast_nullable_to_non_nullable
as bool,homeCreative: freezed == homeCreative ? _self.homeCreative : homeCreative // ignore: cast_nullable_to_non_nullable
as PromotionCreativeModel?,
  ));
}

/// Create a copy of ActivePromotionCampaignModel
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
mixin _$ActivePromotionCampaignsModel {

 List<ActivePromotionCampaignModel> get items;@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt get totalCount;@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'snapshot_at') DateTime get snapshotAt;@JsonKey(name: 'campaign_owned_home_banner_ids') List<int> get campaignOwnedHomeBannerIds;
/// Create a copy of ActivePromotionCampaignsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePromotionCampaignsModelCopyWith<ActivePromotionCampaignsModel> get copyWith => _$ActivePromotionCampaignsModelCopyWithImpl<ActivePromotionCampaignsModel>(this as ActivePromotionCampaignsModel, _$identity);

  /// Serializes this ActivePromotionCampaignsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePromotionCampaignsModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt)&&const DeepCollectionEquality().equals(other.campaignOwnedHomeBannerIds, campaignOwnedHomeBannerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,nextCursor,snapshotAt,const DeepCollectionEquality().hash(campaignOwnedHomeBannerIds));

@override
String toString() {
  return 'ActivePromotionCampaignsModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt, campaignOwnedHomeBannerIds: $campaignOwnedHomeBannerIds)';
}


}

/// @nodoc
abstract mixin class $ActivePromotionCampaignsModelCopyWith<$Res>  {
  factory $ActivePromotionCampaignsModelCopyWith(ActivePromotionCampaignsModel value, $Res Function(ActivePromotionCampaignsModel) _then) = _$ActivePromotionCampaignsModelCopyWithImpl;
@useResult
$Res call({
 List<ActivePromotionCampaignModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt,@JsonKey(name: 'campaign_owned_home_banner_ids') List<int> campaignOwnedHomeBannerIds
});




}
/// @nodoc
class _$ActivePromotionCampaignsModelCopyWithImpl<$Res>
    implements $ActivePromotionCampaignsModelCopyWith<$Res> {
  _$ActivePromotionCampaignsModelCopyWithImpl(this._self, this._then);

  final ActivePromotionCampaignsModel _self;
  final $Res Function(ActivePromotionCampaignsModel) _then;

/// Create a copy of ActivePromotionCampaignsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,Object? campaignOwnedHomeBannerIds = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ActivePromotionCampaignModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,campaignOwnedHomeBannerIds: null == campaignOwnedHomeBannerIds ? _self.campaignOwnedHomeBannerIds : campaignOwnedHomeBannerIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivePromotionCampaignsModel].
extension ActivePromotionCampaignsModelPatterns on ActivePromotionCampaignsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePromotionCampaignsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePromotionCampaignsModel value)  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePromotionCampaignsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ActivePromotionCampaignModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')  List<int> campaignOwnedHomeBannerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ActivePromotionCampaignModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')  List<int> campaignOwnedHomeBannerIds)  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ActivePromotionCampaignModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids')  List<int> campaignOwnedHomeBannerIds)?  $default,) {final _that = this;
switch (_that) {
case _ActivePromotionCampaignsModel() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt,_that.campaignOwnedHomeBannerIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivePromotionCampaignsModel extends ActivePromotionCampaignsModel {
  const _ActivePromotionCampaignsModel({required final  List<ActivePromotionCampaignModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter() required this.totalCount, @JsonKey(name: 'next_cursor') this.nextCursor, @JsonKey(name: 'snapshot_at') required this.snapshotAt, @JsonKey(name: 'campaign_owned_home_banner_ids') required final  List<int> campaignOwnedHomeBannerIds}): _items = items,_campaignOwnedHomeBannerIds = campaignOwnedHomeBannerIds,super._();
  factory _ActivePromotionCampaignsModel.fromJson(Map<String, dynamic> json) => _$ActivePromotionCampaignsModelFromJson(json);

 final  List<ActivePromotionCampaignModel> _items;
@override List<ActivePromotionCampaignModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count')@WalletAmountConverter() final  BigInt totalCount;
@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'snapshot_at') final  DateTime snapshotAt;
 final  List<int> _campaignOwnedHomeBannerIds;
@override@JsonKey(name: 'campaign_owned_home_banner_ids') List<int> get campaignOwnedHomeBannerIds {
  if (_campaignOwnedHomeBannerIds is EqualUnmodifiableListView) return _campaignOwnedHomeBannerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_campaignOwnedHomeBannerIds);
}


/// Create a copy of ActivePromotionCampaignsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePromotionCampaignsModelCopyWith<_ActivePromotionCampaignsModel> get copyWith => __$ActivePromotionCampaignsModelCopyWithImpl<_ActivePromotionCampaignsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivePromotionCampaignsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePromotionCampaignsModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt)&&const DeepCollectionEquality().equals(other._campaignOwnedHomeBannerIds, _campaignOwnedHomeBannerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,nextCursor,snapshotAt,const DeepCollectionEquality().hash(_campaignOwnedHomeBannerIds));

@override
String toString() {
  return 'ActivePromotionCampaignsModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt, campaignOwnedHomeBannerIds: $campaignOwnedHomeBannerIds)';
}


}

/// @nodoc
abstract mixin class _$ActivePromotionCampaignsModelCopyWith<$Res> implements $ActivePromotionCampaignsModelCopyWith<$Res> {
  factory _$ActivePromotionCampaignsModelCopyWith(_ActivePromotionCampaignsModel value, $Res Function(_ActivePromotionCampaignsModel) _then) = __$ActivePromotionCampaignsModelCopyWithImpl;
@override @useResult
$Res call({
 List<ActivePromotionCampaignModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt,@JsonKey(name: 'campaign_owned_home_banner_ids') List<int> campaignOwnedHomeBannerIds
});




}
/// @nodoc
class __$ActivePromotionCampaignsModelCopyWithImpl<$Res>
    implements _$ActivePromotionCampaignsModelCopyWith<$Res> {
  __$ActivePromotionCampaignsModelCopyWithImpl(this._self, this._then);

  final _ActivePromotionCampaignsModel _self;
  final $Res Function(_ActivePromotionCampaignsModel) _then;

/// Create a copy of ActivePromotionCampaignsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,Object? campaignOwnedHomeBannerIds = null,}) {
  return _then(_ActivePromotionCampaignsModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ActivePromotionCampaignModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,campaignOwnedHomeBannerIds: null == campaignOwnedHomeBannerIds ? _self._campaignOwnedHomeBannerIds : campaignOwnedHomeBannerIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
