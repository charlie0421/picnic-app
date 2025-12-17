// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VoteModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'title') Map<String, dynamic> get title;@JsonKey(name: 'vote_category') String? get voteCategory;@JsonKey(name: 'main_image') String? get mainImage;@JsonKey(name: 'wait_image') String? get waitImage;@JsonKey(name: 'result_image') String? get resultImage;@JsonKey(name: 'vote_content') String? get voteContent;@JsonKey(name: 'vote_item') List<VoteItemModel>? get voteItem;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'visible_at') DateTime? get visibleAt;@JsonKey(name: 'stop_at') DateTime? get stopAt;@JsonKey(name: 'start_at') DateTime? get startAt;@JsonKey(name: 'is_ended') bool? get isEnded;@JsonKey(name: 'is_upcoming') bool? get isUpcoming;@JsonKey(name: 'is_partnership') bool? get isPartnership;@JsonKey(name: 'partner') String? get partner;@JsonKey(name: 'reward') List<RewardModel>? get reward;
/// Create a copy of VoteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteModelCopyWith<VoteModel> get copyWith => _$VoteModelCopyWithImpl<VoteModel>(this as VoteModel, _$identity);

  /// Serializes this VoteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.title, title)&&(identical(other.voteCategory, voteCategory) || other.voteCategory == voteCategory)&&(identical(other.mainImage, mainImage) || other.mainImage == mainImage)&&(identical(other.waitImage, waitImage) || other.waitImage == waitImage)&&(identical(other.resultImage, resultImage) || other.resultImage == resultImage)&&(identical(other.voteContent, voteContent) || other.voteContent == voteContent)&&const DeepCollectionEquality().equals(other.voteItem, voteItem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.visibleAt, visibleAt) || other.visibleAt == visibleAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.isEnded, isEnded) || other.isEnded == isEnded)&&(identical(other.isUpcoming, isUpcoming) || other.isUpcoming == isUpcoming)&&(identical(other.isPartnership, isPartnership) || other.isPartnership == isPartnership)&&(identical(other.partner, partner) || other.partner == partner)&&const DeepCollectionEquality().equals(other.reward, reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(title),voteCategory,mainImage,waitImage,resultImage,voteContent,const DeepCollectionEquality().hash(voteItem),createdAt,visibleAt,stopAt,startAt,isEnded,isUpcoming,isPartnership,partner,const DeepCollectionEquality().hash(reward));

@override
String toString() {
  return 'VoteModel(id: $id, title: $title, voteCategory: $voteCategory, mainImage: $mainImage, waitImage: $waitImage, resultImage: $resultImage, voteContent: $voteContent, voteItem: $voteItem, createdAt: $createdAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt, isEnded: $isEnded, isUpcoming: $isUpcoming, isPartnership: $isPartnership, partner: $partner, reward: $reward)';
}


}

/// @nodoc
abstract mixin class $VoteModelCopyWith<$Res>  {
  factory $VoteModelCopyWith(VoteModel value, $Res Function(VoteModel) _then) = _$VoteModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'vote_category') String? voteCategory,@JsonKey(name: 'main_image') String? mainImage,@JsonKey(name: 'wait_image') String? waitImage,@JsonKey(name: 'result_image') String? resultImage,@JsonKey(name: 'vote_content') String? voteContent,@JsonKey(name: 'vote_item') List<VoteItemModel>? voteItem,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'visible_at') DateTime? visibleAt,@JsonKey(name: 'stop_at') DateTime? stopAt,@JsonKey(name: 'start_at') DateTime? startAt,@JsonKey(name: 'is_ended') bool? isEnded,@JsonKey(name: 'is_upcoming') bool? isUpcoming,@JsonKey(name: 'is_partnership') bool? isPartnership,@JsonKey(name: 'partner') String? partner,@JsonKey(name: 'reward') List<RewardModel>? reward
});




}
/// @nodoc
class _$VoteModelCopyWithImpl<$Res>
    implements $VoteModelCopyWith<$Res> {
  _$VoteModelCopyWithImpl(this._self, this._then);

  final VoteModel _self;
  final $Res Function(VoteModel) _then;

/// Create a copy of VoteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? voteCategory = freezed,Object? mainImage = freezed,Object? waitImage = freezed,Object? resultImage = freezed,Object? voteContent = freezed,Object? voteItem = freezed,Object? createdAt = freezed,Object? visibleAt = freezed,Object? stopAt = freezed,Object? startAt = freezed,Object? isEnded = freezed,Object? isUpcoming = freezed,Object? isPartnership = freezed,Object? partner = freezed,Object? reward = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,voteCategory: freezed == voteCategory ? _self.voteCategory : voteCategory // ignore: cast_nullable_to_non_nullable
as String?,mainImage: freezed == mainImage ? _self.mainImage : mainImage // ignore: cast_nullable_to_non_nullable
as String?,waitImage: freezed == waitImage ? _self.waitImage : waitImage // ignore: cast_nullable_to_non_nullable
as String?,resultImage: freezed == resultImage ? _self.resultImage : resultImage // ignore: cast_nullable_to_non_nullable
as String?,voteContent: freezed == voteContent ? _self.voteContent : voteContent // ignore: cast_nullable_to_non_nullable
as String?,voteItem: freezed == voteItem ? _self.voteItem : voteItem // ignore: cast_nullable_to_non_nullable
as List<VoteItemModel>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleAt: freezed == visibleAt ? _self.visibleAt : visibleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: freezed == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isEnded: freezed == isEnded ? _self.isEnded : isEnded // ignore: cast_nullable_to_non_nullable
as bool?,isUpcoming: freezed == isUpcoming ? _self.isUpcoming : isUpcoming // ignore: cast_nullable_to_non_nullable
as bool?,isPartnership: freezed == isPartnership ? _self.isPartnership : isPartnership // ignore: cast_nullable_to_non_nullable
as bool?,partner: freezed == partner ? _self.partner : partner // ignore: cast_nullable_to_non_nullable
as String?,reward: freezed == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as List<RewardModel>?,
  ));
}

}


/// Adds pattern-matching-related methods to [VoteModel].
extension VoteModelPatterns on VoteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteModel value)  $default,){
final _that = this;
switch (_that) {
case _VoteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteModel value)?  $default,){
final _that = this;
switch (_that) {
case _VoteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'vote_category')  String? voteCategory, @JsonKey(name: 'main_image')  String? mainImage, @JsonKey(name: 'wait_image')  String? waitImage, @JsonKey(name: 'result_image')  String? resultImage, @JsonKey(name: 'vote_content')  String? voteContent, @JsonKey(name: 'vote_item')  List<VoteItemModel>? voteItem, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime? stopAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'is_ended')  bool? isEnded, @JsonKey(name: 'is_upcoming')  bool? isUpcoming, @JsonKey(name: 'is_partnership')  bool? isPartnership, @JsonKey(name: 'partner')  String? partner, @JsonKey(name: 'reward')  List<RewardModel>? reward)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteModel() when $default != null:
return $default(_that.id,_that.title,_that.voteCategory,_that.mainImage,_that.waitImage,_that.resultImage,_that.voteContent,_that.voteItem,_that.createdAt,_that.visibleAt,_that.stopAt,_that.startAt,_that.isEnded,_that.isUpcoming,_that.isPartnership,_that.partner,_that.reward);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'vote_category')  String? voteCategory, @JsonKey(name: 'main_image')  String? mainImage, @JsonKey(name: 'wait_image')  String? waitImage, @JsonKey(name: 'result_image')  String? resultImage, @JsonKey(name: 'vote_content')  String? voteContent, @JsonKey(name: 'vote_item')  List<VoteItemModel>? voteItem, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime? stopAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'is_ended')  bool? isEnded, @JsonKey(name: 'is_upcoming')  bool? isUpcoming, @JsonKey(name: 'is_partnership')  bool? isPartnership, @JsonKey(name: 'partner')  String? partner, @JsonKey(name: 'reward')  List<RewardModel>? reward)  $default,) {final _that = this;
switch (_that) {
case _VoteModel():
return $default(_that.id,_that.title,_that.voteCategory,_that.mainImage,_that.waitImage,_that.resultImage,_that.voteContent,_that.voteItem,_that.createdAt,_that.visibleAt,_that.stopAt,_that.startAt,_that.isEnded,_that.isUpcoming,_that.isPartnership,_that.partner,_that.reward);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic> title, @JsonKey(name: 'vote_category')  String? voteCategory, @JsonKey(name: 'main_image')  String? mainImage, @JsonKey(name: 'wait_image')  String? waitImage, @JsonKey(name: 'result_image')  String? resultImage, @JsonKey(name: 'vote_content')  String? voteContent, @JsonKey(name: 'vote_item')  List<VoteItemModel>? voteItem, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'visible_at')  DateTime? visibleAt, @JsonKey(name: 'stop_at')  DateTime? stopAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'is_ended')  bool? isEnded, @JsonKey(name: 'is_upcoming')  bool? isUpcoming, @JsonKey(name: 'is_partnership')  bool? isPartnership, @JsonKey(name: 'partner')  String? partner, @JsonKey(name: 'reward')  List<RewardModel>? reward)?  $default,) {final _that = this;
switch (_that) {
case _VoteModel() when $default != null:
return $default(_that.id,_that.title,_that.voteCategory,_that.mainImage,_that.waitImage,_that.resultImage,_that.voteContent,_that.voteItem,_that.createdAt,_that.visibleAt,_that.stopAt,_that.startAt,_that.isEnded,_that.isUpcoming,_that.isPartnership,_that.partner,_that.reward);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteModel extends VoteModel {
  const _VoteModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') required final  Map<String, dynamic> title, @JsonKey(name: 'vote_category') required this.voteCategory, @JsonKey(name: 'main_image') required this.mainImage, @JsonKey(name: 'wait_image') required this.waitImage, @JsonKey(name: 'result_image') required this.resultImage, @JsonKey(name: 'vote_content') required this.voteContent, @JsonKey(name: 'vote_item') required final  List<VoteItemModel>? voteItem, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'visible_at') required this.visibleAt, @JsonKey(name: 'stop_at') required this.stopAt, @JsonKey(name: 'start_at') required this.startAt, @JsonKey(name: 'is_ended') required this.isEnded, @JsonKey(name: 'is_upcoming') required this.isUpcoming, @JsonKey(name: 'is_partnership') required this.isPartnership, @JsonKey(name: 'partner') required this.partner, @JsonKey(name: 'reward') required final  List<RewardModel>? reward}): _title = title,_voteItem = voteItem,_reward = reward,super._();
  factory _VoteModel.fromJson(Map<String, dynamic> json) => _$VoteModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic> _title;
@override@JsonKey(name: 'title') Map<String, dynamic> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

@override@JsonKey(name: 'vote_category') final  String? voteCategory;
@override@JsonKey(name: 'main_image') final  String? mainImage;
@override@JsonKey(name: 'wait_image') final  String? waitImage;
@override@JsonKey(name: 'result_image') final  String? resultImage;
@override@JsonKey(name: 'vote_content') final  String? voteContent;
 final  List<VoteItemModel>? _voteItem;
@override@JsonKey(name: 'vote_item') List<VoteItemModel>? get voteItem {
  final value = _voteItem;
  if (value == null) return null;
  if (_voteItem is EqualUnmodifiableListView) return _voteItem;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'visible_at') final  DateTime? visibleAt;
@override@JsonKey(name: 'stop_at') final  DateTime? stopAt;
@override@JsonKey(name: 'start_at') final  DateTime? startAt;
@override@JsonKey(name: 'is_ended') final  bool? isEnded;
@override@JsonKey(name: 'is_upcoming') final  bool? isUpcoming;
@override@JsonKey(name: 'is_partnership') final  bool? isPartnership;
@override@JsonKey(name: 'partner') final  String? partner;
 final  List<RewardModel>? _reward;
@override@JsonKey(name: 'reward') List<RewardModel>? get reward {
  final value = _reward;
  if (value == null) return null;
  if (_reward is EqualUnmodifiableListView) return _reward;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of VoteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteModelCopyWith<_VoteModel> get copyWith => __$VoteModelCopyWithImpl<_VoteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._title, _title)&&(identical(other.voteCategory, voteCategory) || other.voteCategory == voteCategory)&&(identical(other.mainImage, mainImage) || other.mainImage == mainImage)&&(identical(other.waitImage, waitImage) || other.waitImage == waitImage)&&(identical(other.resultImage, resultImage) || other.resultImage == resultImage)&&(identical(other.voteContent, voteContent) || other.voteContent == voteContent)&&const DeepCollectionEquality().equals(other._voteItem, _voteItem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.visibleAt, visibleAt) || other.visibleAt == visibleAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.isEnded, isEnded) || other.isEnded == isEnded)&&(identical(other.isUpcoming, isUpcoming) || other.isUpcoming == isUpcoming)&&(identical(other.isPartnership, isPartnership) || other.isPartnership == isPartnership)&&(identical(other.partner, partner) || other.partner == partner)&&const DeepCollectionEquality().equals(other._reward, _reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_title),voteCategory,mainImage,waitImage,resultImage,voteContent,const DeepCollectionEquality().hash(_voteItem),createdAt,visibleAt,stopAt,startAt,isEnded,isUpcoming,isPartnership,partner,const DeepCollectionEquality().hash(_reward));

@override
String toString() {
  return 'VoteModel(id: $id, title: $title, voteCategory: $voteCategory, mainImage: $mainImage, waitImage: $waitImage, resultImage: $resultImage, voteContent: $voteContent, voteItem: $voteItem, createdAt: $createdAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt, isEnded: $isEnded, isUpcoming: $isUpcoming, isPartnership: $isPartnership, partner: $partner, reward: $reward)';
}


}

/// @nodoc
abstract mixin class _$VoteModelCopyWith<$Res> implements $VoteModelCopyWith<$Res> {
  factory _$VoteModelCopyWith(_VoteModel value, $Res Function(_VoteModel) _then) = __$VoteModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic> title,@JsonKey(name: 'vote_category') String? voteCategory,@JsonKey(name: 'main_image') String? mainImage,@JsonKey(name: 'wait_image') String? waitImage,@JsonKey(name: 'result_image') String? resultImage,@JsonKey(name: 'vote_content') String? voteContent,@JsonKey(name: 'vote_item') List<VoteItemModel>? voteItem,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'visible_at') DateTime? visibleAt,@JsonKey(name: 'stop_at') DateTime? stopAt,@JsonKey(name: 'start_at') DateTime? startAt,@JsonKey(name: 'is_ended') bool? isEnded,@JsonKey(name: 'is_upcoming') bool? isUpcoming,@JsonKey(name: 'is_partnership') bool? isPartnership,@JsonKey(name: 'partner') String? partner,@JsonKey(name: 'reward') List<RewardModel>? reward
});




}
/// @nodoc
class __$VoteModelCopyWithImpl<$Res>
    implements _$VoteModelCopyWith<$Res> {
  __$VoteModelCopyWithImpl(this._self, this._then);

  final _VoteModel _self;
  final $Res Function(_VoteModel) _then;

/// Create a copy of VoteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? voteCategory = freezed,Object? mainImage = freezed,Object? waitImage = freezed,Object? resultImage = freezed,Object? voteContent = freezed,Object? voteItem = freezed,Object? createdAt = freezed,Object? visibleAt = freezed,Object? stopAt = freezed,Object? startAt = freezed,Object? isEnded = freezed,Object? isUpcoming = freezed,Object? isPartnership = freezed,Object? partner = freezed,Object? reward = freezed,}) {
  return _then(_VoteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,voteCategory: freezed == voteCategory ? _self.voteCategory : voteCategory // ignore: cast_nullable_to_non_nullable
as String?,mainImage: freezed == mainImage ? _self.mainImage : mainImage // ignore: cast_nullable_to_non_nullable
as String?,waitImage: freezed == waitImage ? _self.waitImage : waitImage // ignore: cast_nullable_to_non_nullable
as String?,resultImage: freezed == resultImage ? _self.resultImage : resultImage // ignore: cast_nullable_to_non_nullable
as String?,voteContent: freezed == voteContent ? _self.voteContent : voteContent // ignore: cast_nullable_to_non_nullable
as String?,voteItem: freezed == voteItem ? _self._voteItem : voteItem // ignore: cast_nullable_to_non_nullable
as List<VoteItemModel>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleAt: freezed == visibleAt ? _self.visibleAt : visibleAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: freezed == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isEnded: freezed == isEnded ? _self.isEnded : isEnded // ignore: cast_nullable_to_non_nullable
as bool?,isUpcoming: freezed == isUpcoming ? _self.isUpcoming : isUpcoming // ignore: cast_nullable_to_non_nullable
as bool?,isPartnership: freezed == isPartnership ? _self.isPartnership : isPartnership // ignore: cast_nullable_to_non_nullable
as bool?,partner: freezed == partner ? _self.partner : partner // ignore: cast_nullable_to_non_nullable
as String?,reward: freezed == reward ? _self._reward : reward // ignore: cast_nullable_to_non_nullable
as List<RewardModel>?,
  ));
}


}


/// @nodoc
mixin _$VoteItemModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'vote_total') int? get voteTotal;@JsonKey(name: 'star_candy_total') int? get starCandyTotal;@JsonKey(name: 'star_candy_bonus_total') int? get starCandyBonusTotal;@JsonKey(name: 'vote_id') int get voteId;@JsonKey(name: 'artist') ArtistModel? get artist;@JsonKey(name: 'artist_group') ArtistGroupModel? get artistGroup;
/// Create a copy of VoteItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteItemModelCopyWith<VoteItemModel> get copyWith => _$VoteItemModelCopyWithImpl<VoteItemModel>(this as VoteItemModel, _$identity);

  /// Serializes this VoteItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.voteTotal, voteTotal) || other.voteTotal == voteTotal)&&(identical(other.starCandyTotal, starCandyTotal) || other.starCandyTotal == starCandyTotal)&&(identical(other.starCandyBonusTotal, starCandyBonusTotal) || other.starCandyBonusTotal == starCandyBonusTotal)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteTotal,starCandyTotal,starCandyBonusTotal,voteId,artist,artistGroup);

@override
String toString() {
  return 'VoteItemModel(id: $id, voteTotal: $voteTotal, starCandyTotal: $starCandyTotal, starCandyBonusTotal: $starCandyBonusTotal, voteId: $voteId, artist: $artist, artistGroup: $artistGroup)';
}


}

/// @nodoc
abstract mixin class $VoteItemModelCopyWith<$Res>  {
  factory $VoteItemModelCopyWith(VoteItemModel value, $Res Function(VoteItemModel) _then) = _$VoteItemModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_total') int? voteTotal,@JsonKey(name: 'star_candy_total') int? starCandyTotal,@JsonKey(name: 'star_candy_bonus_total') int? starCandyBonusTotal,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'artist') ArtistModel? artist,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup
});


$ArtistModelCopyWith<$Res>? get artist;$ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class _$VoteItemModelCopyWithImpl<$Res>
    implements $VoteItemModelCopyWith<$Res> {
  _$VoteItemModelCopyWithImpl(this._self, this._then);

  final VoteItemModel _self;
  final $Res Function(VoteItemModel) _then;

/// Create a copy of VoteItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? voteTotal = freezed,Object? starCandyTotal = freezed,Object? starCandyBonusTotal = freezed,Object? voteId = null,Object? artist = freezed,Object? artistGroup = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteTotal: freezed == voteTotal ? _self.voteTotal : voteTotal // ignore: cast_nullable_to_non_nullable
as int?,starCandyTotal: freezed == starCandyTotal ? _self.starCandyTotal : starCandyTotal // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonusTotal: freezed == starCandyBonusTotal ? _self.starCandyBonusTotal : starCandyBonusTotal // ignore: cast_nullable_to_non_nullable
as int?,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,
  ));
}
/// Create a copy of VoteItemModel
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
}/// Create a copy of VoteItemModel
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


/// Adds pattern-matching-related methods to [VoteItemModel].
extension VoteItemModelPatterns on VoteItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteItemModel value)  $default,){
final _that = this;
switch (_that) {
case _VoteItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _VoteItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int? voteTotal, @JsonKey(name: 'star_candy_total')  int? starCandyTotal, @JsonKey(name: 'star_candy_bonus_total')  int? starCandyBonusTotal, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'artist')  ArtistModel? artist, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteItemModel() when $default != null:
return $default(_that.id,_that.voteTotal,_that.starCandyTotal,_that.starCandyBonusTotal,_that.voteId,_that.artist,_that.artistGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int? voteTotal, @JsonKey(name: 'star_candy_total')  int? starCandyTotal, @JsonKey(name: 'star_candy_bonus_total')  int? starCandyBonusTotal, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'artist')  ArtistModel? artist, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)  $default,) {final _that = this;
switch (_that) {
case _VoteItemModel():
return $default(_that.id,_that.voteTotal,_that.starCandyTotal,_that.starCandyBonusTotal,_that.voteId,_that.artist,_that.artistGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_total')  int? voteTotal, @JsonKey(name: 'star_candy_total')  int? starCandyTotal, @JsonKey(name: 'star_candy_bonus_total')  int? starCandyBonusTotal, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'artist')  ArtistModel? artist, @JsonKey(name: 'artist_group')  ArtistGroupModel? artistGroup)?  $default,) {final _that = this;
switch (_that) {
case _VoteItemModel() when $default != null:
return $default(_that.id,_that.voteTotal,_that.starCandyTotal,_that.starCandyBonusTotal,_that.voteId,_that.artist,_that.artistGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteItemModel extends VoteItemModel {
  const _VoteItemModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote_total') required this.voteTotal, @JsonKey(name: 'star_candy_total') this.starCandyTotal, @JsonKey(name: 'star_candy_bonus_total') this.starCandyBonusTotal, @JsonKey(name: 'vote_id') required this.voteId, @JsonKey(name: 'artist') required this.artist, @JsonKey(name: 'artist_group') required this.artistGroup}): super._();
  factory _VoteItemModel.fromJson(Map<String, dynamic> json) => _$VoteItemModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'vote_total') final  int? voteTotal;
@override@JsonKey(name: 'star_candy_total') final  int? starCandyTotal;
@override@JsonKey(name: 'star_candy_bonus_total') final  int? starCandyBonusTotal;
@override@JsonKey(name: 'vote_id') final  int voteId;
@override@JsonKey(name: 'artist') final  ArtistModel? artist;
@override@JsonKey(name: 'artist_group') final  ArtistGroupModel? artistGroup;

/// Create a copy of VoteItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteItemModelCopyWith<_VoteItemModel> get copyWith => __$VoteItemModelCopyWithImpl<_VoteItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.voteTotal, voteTotal) || other.voteTotal == voteTotal)&&(identical(other.starCandyTotal, starCandyTotal) || other.starCandyTotal == starCandyTotal)&&(identical(other.starCandyBonusTotal, starCandyBonusTotal) || other.starCandyBonusTotal == starCandyBonusTotal)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.artistGroup, artistGroup) || other.artistGroup == artistGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteTotal,starCandyTotal,starCandyBonusTotal,voteId,artist,artistGroup);

@override
String toString() {
  return 'VoteItemModel(id: $id, voteTotal: $voteTotal, starCandyTotal: $starCandyTotal, starCandyBonusTotal: $starCandyBonusTotal, voteId: $voteId, artist: $artist, artistGroup: $artistGroup)';
}


}

/// @nodoc
abstract mixin class _$VoteItemModelCopyWith<$Res> implements $VoteItemModelCopyWith<$Res> {
  factory _$VoteItemModelCopyWith(_VoteItemModel value, $Res Function(_VoteItemModel) _then) = __$VoteItemModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_total') int? voteTotal,@JsonKey(name: 'star_candy_total') int? starCandyTotal,@JsonKey(name: 'star_candy_bonus_total') int? starCandyBonusTotal,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'artist') ArtistModel? artist,@JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup
});


@override $ArtistModelCopyWith<$Res>? get artist;@override $ArtistGroupModelCopyWith<$Res>? get artistGroup;

}
/// @nodoc
class __$VoteItemModelCopyWithImpl<$Res>
    implements _$VoteItemModelCopyWith<$Res> {
  __$VoteItemModelCopyWithImpl(this._self, this._then);

  final _VoteItemModel _self;
  final $Res Function(_VoteItemModel) _then;

/// Create a copy of VoteItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? voteTotal = freezed,Object? starCandyTotal = freezed,Object? starCandyBonusTotal = freezed,Object? voteId = null,Object? artist = freezed,Object? artistGroup = freezed,}) {
  return _then(_VoteItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteTotal: freezed == voteTotal ? _self.voteTotal : voteTotal // ignore: cast_nullable_to_non_nullable
as int?,starCandyTotal: freezed == starCandyTotal ? _self.starCandyTotal : starCandyTotal // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonusTotal: freezed == starCandyBonusTotal ? _self.starCandyBonusTotal : starCandyBonusTotal // ignore: cast_nullable_to_non_nullable
as int?,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistModel?,artistGroup: freezed == artistGroup ? _self.artistGroup : artistGroup // ignore: cast_nullable_to_non_nullable
as ArtistGroupModel?,
  ));
}

/// Create a copy of VoteItemModel
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
}/// Create a copy of VoteItemModel
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
mixin _$VoteAchieve {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'vote_id') int get voteId;@JsonKey(name: 'reward_id') int get rewardId;@JsonKey(name: 'order') int get order;@JsonKey(name: 'amount') int get amount;@JsonKey(name: 'reward') RewardModel get reward;@JsonKey(name: 'vote') VoteModel get vote;
/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteAchieveCopyWith<VoteAchieve> get copyWith => _$VoteAchieveCopyWithImpl<VoteAchieve>(this as VoteAchieve, _$identity);

  /// Serializes this VoteAchieve to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteAchieve&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.rewardId, rewardId) || other.rewardId == rewardId)&&(identical(other.order, order) || other.order == order)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reward, reward) || other.reward == reward)&&(identical(other.vote, vote) || other.vote == vote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,rewardId,order,amount,reward,vote);

@override
String toString() {
  return 'VoteAchieve(id: $id, voteId: $voteId, rewardId: $rewardId, order: $order, amount: $amount, reward: $reward, vote: $vote)';
}


}

/// @nodoc
abstract mixin class $VoteAchieveCopyWith<$Res>  {
  factory $VoteAchieveCopyWith(VoteAchieve value, $Res Function(VoteAchieve) _then) = _$VoteAchieveCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'reward_id') int rewardId,@JsonKey(name: 'order') int order,@JsonKey(name: 'amount') int amount,@JsonKey(name: 'reward') RewardModel reward,@JsonKey(name: 'vote') VoteModel vote
});


$RewardModelCopyWith<$Res> get reward;$VoteModelCopyWith<$Res> get vote;

}
/// @nodoc
class _$VoteAchieveCopyWithImpl<$Res>
    implements $VoteAchieveCopyWith<$Res> {
  _$VoteAchieveCopyWithImpl(this._self, this._then);

  final VoteAchieve _self;
  final $Res Function(VoteAchieve) _then;

/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? voteId = null,Object? rewardId = null,Object? order = null,Object? amount = null,Object? reward = null,Object? vote = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,rewardId: null == rewardId ? _self.rewardId : rewardId // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as RewardModel,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as VoteModel,
  ));
}
/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardModelCopyWith<$Res> get reward {
  
  return $RewardModelCopyWith<$Res>(_self.reward, (value) {
    return _then(_self.copyWith(reward: value));
  });
}/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteModelCopyWith<$Res> get vote {
  
  return $VoteModelCopyWith<$Res>(_self.vote, (value) {
    return _then(_self.copyWith(vote: value));
  });
}
}


/// Adds pattern-matching-related methods to [VoteAchieve].
extension VoteAchievePatterns on VoteAchieve {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteAchieve value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteAchieve() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteAchieve value)  $default,){
final _that = this;
switch (_that) {
case _VoteAchieve():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteAchieve value)?  $default,){
final _that = this;
switch (_that) {
case _VoteAchieve() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'reward_id')  int rewardId, @JsonKey(name: 'order')  int order, @JsonKey(name: 'amount')  int amount, @JsonKey(name: 'reward')  RewardModel reward, @JsonKey(name: 'vote')  VoteModel vote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteAchieve() when $default != null:
return $default(_that.id,_that.voteId,_that.rewardId,_that.order,_that.amount,_that.reward,_that.vote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'reward_id')  int rewardId, @JsonKey(name: 'order')  int order, @JsonKey(name: 'amount')  int amount, @JsonKey(name: 'reward')  RewardModel reward, @JsonKey(name: 'vote')  VoteModel vote)  $default,) {final _that = this;
switch (_that) {
case _VoteAchieve():
return $default(_that.id,_that.voteId,_that.rewardId,_that.order,_that.amount,_that.reward,_that.vote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote_id')  int voteId, @JsonKey(name: 'reward_id')  int rewardId, @JsonKey(name: 'order')  int order, @JsonKey(name: 'amount')  int amount, @JsonKey(name: 'reward')  RewardModel reward, @JsonKey(name: 'vote')  VoteModel vote)?  $default,) {final _that = this;
switch (_that) {
case _VoteAchieve() when $default != null:
return $default(_that.id,_that.voteId,_that.rewardId,_that.order,_that.amount,_that.reward,_that.vote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteAchieve extends VoteAchieve {
  const _VoteAchieve({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote_id') required this.voteId, @JsonKey(name: 'reward_id') required this.rewardId, @JsonKey(name: 'order') required this.order, @JsonKey(name: 'amount') required this.amount, @JsonKey(name: 'reward') required this.reward, @JsonKey(name: 'vote') required this.vote}): super._();
  factory _VoteAchieve.fromJson(Map<String, dynamic> json) => _$VoteAchieveFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'vote_id') final  int voteId;
@override@JsonKey(name: 'reward_id') final  int rewardId;
@override@JsonKey(name: 'order') final  int order;
@override@JsonKey(name: 'amount') final  int amount;
@override@JsonKey(name: 'reward') final  RewardModel reward;
@override@JsonKey(name: 'vote') final  VoteModel vote;

/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteAchieveCopyWith<_VoteAchieve> get copyWith => __$VoteAchieveCopyWithImpl<_VoteAchieve>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteAchieveToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteAchieve&&(identical(other.id, id) || other.id == id)&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.rewardId, rewardId) || other.rewardId == rewardId)&&(identical(other.order, order) || other.order == order)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reward, reward) || other.reward == reward)&&(identical(other.vote, vote) || other.vote == vote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,voteId,rewardId,order,amount,reward,vote);

@override
String toString() {
  return 'VoteAchieve(id: $id, voteId: $voteId, rewardId: $rewardId, order: $order, amount: $amount, reward: $reward, vote: $vote)';
}


}

/// @nodoc
abstract mixin class _$VoteAchieveCopyWith<$Res> implements $VoteAchieveCopyWith<$Res> {
  factory _$VoteAchieveCopyWith(_VoteAchieve value, $Res Function(_VoteAchieve) _then) = __$VoteAchieveCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote_id') int voteId,@JsonKey(name: 'reward_id') int rewardId,@JsonKey(name: 'order') int order,@JsonKey(name: 'amount') int amount,@JsonKey(name: 'reward') RewardModel reward,@JsonKey(name: 'vote') VoteModel vote
});


@override $RewardModelCopyWith<$Res> get reward;@override $VoteModelCopyWith<$Res> get vote;

}
/// @nodoc
class __$VoteAchieveCopyWithImpl<$Res>
    implements _$VoteAchieveCopyWith<$Res> {
  __$VoteAchieveCopyWithImpl(this._self, this._then);

  final _VoteAchieve _self;
  final $Res Function(_VoteAchieve) _then;

/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? voteId = null,Object? rewardId = null,Object? order = null,Object? amount = null,Object? reward = null,Object? vote = null,}) {
  return _then(_VoteAchieve(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,rewardId: null == rewardId ? _self.rewardId : rewardId // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as RewardModel,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as VoteModel,
  ));
}

/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardModelCopyWith<$Res> get reward {
  
  return $RewardModelCopyWith<$Res>(_self.reward, (value) {
    return _then(_self.copyWith(reward: value));
  });
}/// Create a copy of VoteAchieve
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteModelCopyWith<$Res> get vote {
  
  return $VoteModelCopyWith<$Res>(_self.vote, (value) {
    return _then(_self.copyWith(vote: value));
  });
}
}

// dart format on
