// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/vote_pick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VotePickModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'vote') VoteModel get vote;@JsonKey(name: 'vote_item') VoteItemModel get voteItem;@JsonKey(name: 'amount') int? get amount;@JsonKey(name: 'star_candy_usage') int? get starCandyUsage;@JsonKey(name: 'star_candy_bonus_usage') int? get starCandyBonusUsage;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VotePickModelCopyWith<VotePickModel> get copyWith => _$VotePickModelCopyWithImpl<VotePickModel>(this as VotePickModel, _$identity);

  /// Serializes this VotePickModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VotePickModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vote, vote) || other.vote == vote)&&(identical(other.voteItem, voteItem) || other.voteItem == voteItem)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.starCandyUsage, starCandyUsage) || other.starCandyUsage == starCandyUsage)&&(identical(other.starCandyBonusUsage, starCandyBonusUsage) || other.starCandyBonusUsage == starCandyBonusUsage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vote,voteItem,amount,starCandyUsage,starCandyBonusUsage,createdAt,updatedAt);

@override
String toString() {
  return 'VotePickModel(id: $id, vote: $vote, voteItem: $voteItem, amount: $amount, starCandyUsage: $starCandyUsage, starCandyBonusUsage: $starCandyBonusUsage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $VotePickModelCopyWith<$Res>  {
  factory $VotePickModelCopyWith(VotePickModel value, $Res Function(VotePickModel) _then) = _$VotePickModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote') VoteModel vote,@JsonKey(name: 'vote_item') VoteItemModel voteItem,@JsonKey(name: 'amount') int? amount,@JsonKey(name: 'star_candy_usage') int? starCandyUsage,@JsonKey(name: 'star_candy_bonus_usage') int? starCandyBonusUsage,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$VoteModelCopyWith<$Res> get vote;$VoteItemModelCopyWith<$Res> get voteItem;

}
/// @nodoc
class _$VotePickModelCopyWithImpl<$Res>
    implements $VotePickModelCopyWith<$Res> {
  _$VotePickModelCopyWithImpl(this._self, this._then);

  final VotePickModel _self;
  final $Res Function(VotePickModel) _then;

/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vote = null,Object? voteItem = null,Object? amount = freezed,Object? starCandyUsage = freezed,Object? starCandyBonusUsage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as VoteModel,voteItem: null == voteItem ? _self.voteItem : voteItem // ignore: cast_nullable_to_non_nullable
as VoteItemModel,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,starCandyUsage: freezed == starCandyUsage ? _self.starCandyUsage : starCandyUsage // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonusUsage: freezed == starCandyBonusUsage ? _self.starCandyBonusUsage : starCandyBonusUsage // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteModelCopyWith<$Res> get vote {
  
  return $VoteModelCopyWith<$Res>(_self.vote, (value) {
    return _then(_self.copyWith(vote: value));
  });
}/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteItemModelCopyWith<$Res> get voteItem {
  
  return $VoteItemModelCopyWith<$Res>(_self.voteItem, (value) {
    return _then(_self.copyWith(voteItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [VotePickModel].
extension VotePickModelPatterns on VotePickModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VotePickModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VotePickModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VotePickModel value)  $default,){
final _that = this;
switch (_that) {
case _VotePickModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VotePickModel value)?  $default,){
final _that = this;
switch (_that) {
case _VotePickModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote')  VoteModel vote, @JsonKey(name: 'vote_item')  VoteItemModel voteItem, @JsonKey(name: 'amount')  int? amount, @JsonKey(name: 'star_candy_usage')  int? starCandyUsage, @JsonKey(name: 'star_candy_bonus_usage')  int? starCandyBonusUsage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VotePickModel() when $default != null:
return $default(_that.id,_that.vote,_that.voteItem,_that.amount,_that.starCandyUsage,_that.starCandyBonusUsage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote')  VoteModel vote, @JsonKey(name: 'vote_item')  VoteItemModel voteItem, @JsonKey(name: 'amount')  int? amount, @JsonKey(name: 'star_candy_usage')  int? starCandyUsage, @JsonKey(name: 'star_candy_bonus_usage')  int? starCandyBonusUsage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _VotePickModel():
return $default(_that.id,_that.vote,_that.voteItem,_that.amount,_that.starCandyUsage,_that.starCandyBonusUsage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'vote')  VoteModel vote, @JsonKey(name: 'vote_item')  VoteItemModel voteItem, @JsonKey(name: 'amount')  int? amount, @JsonKey(name: 'star_candy_usage')  int? starCandyUsage, @JsonKey(name: 'star_candy_bonus_usage')  int? starCandyBonusUsage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _VotePickModel() when $default != null:
return $default(_that.id,_that.vote,_that.voteItem,_that.amount,_that.starCandyUsage,_that.starCandyBonusUsage,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VotePickModel extends VotePickModel {
  const _VotePickModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'vote') required this.vote, @JsonKey(name: 'vote_item') required this.voteItem, @JsonKey(name: 'amount') required this.amount, @JsonKey(name: 'star_candy_usage') this.starCandyUsage, @JsonKey(name: 'star_candy_bonus_usage') this.starCandyBonusUsage, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): super._();
  factory _VotePickModel.fromJson(Map<String, dynamic> json) => _$VotePickModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'vote') final  VoteModel vote;
@override@JsonKey(name: 'vote_item') final  VoteItemModel voteItem;
@override@JsonKey(name: 'amount') final  int? amount;
@override@JsonKey(name: 'star_candy_usage') final  int? starCandyUsage;
@override@JsonKey(name: 'star_candy_bonus_usage') final  int? starCandyBonusUsage;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VotePickModelCopyWith<_VotePickModel> get copyWith => __$VotePickModelCopyWithImpl<_VotePickModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VotePickModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VotePickModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vote, vote) || other.vote == vote)&&(identical(other.voteItem, voteItem) || other.voteItem == voteItem)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.starCandyUsage, starCandyUsage) || other.starCandyUsage == starCandyUsage)&&(identical(other.starCandyBonusUsage, starCandyBonusUsage) || other.starCandyBonusUsage == starCandyBonusUsage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vote,voteItem,amount,starCandyUsage,starCandyBonusUsage,createdAt,updatedAt);

@override
String toString() {
  return 'VotePickModel(id: $id, vote: $vote, voteItem: $voteItem, amount: $amount, starCandyUsage: $starCandyUsage, starCandyBonusUsage: $starCandyBonusUsage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$VotePickModelCopyWith<$Res> implements $VotePickModelCopyWith<$Res> {
  factory _$VotePickModelCopyWith(_VotePickModel value, $Res Function(_VotePickModel) _then) = __$VotePickModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'vote') VoteModel vote,@JsonKey(name: 'vote_item') VoteItemModel voteItem,@JsonKey(name: 'amount') int? amount,@JsonKey(name: 'star_candy_usage') int? starCandyUsage,@JsonKey(name: 'star_candy_bonus_usage') int? starCandyBonusUsage,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $VoteModelCopyWith<$Res> get vote;@override $VoteItemModelCopyWith<$Res> get voteItem;

}
/// @nodoc
class __$VotePickModelCopyWithImpl<$Res>
    implements _$VotePickModelCopyWith<$Res> {
  __$VotePickModelCopyWithImpl(this._self, this._then);

  final _VotePickModel _self;
  final $Res Function(_VotePickModel) _then;

/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vote = null,Object? voteItem = null,Object? amount = freezed,Object? starCandyUsage = freezed,Object? starCandyBonusUsage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_VotePickModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vote: null == vote ? _self.vote : vote // ignore: cast_nullable_to_non_nullable
as VoteModel,voteItem: null == voteItem ? _self.voteItem : voteItem // ignore: cast_nullable_to_non_nullable
as VoteItemModel,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,starCandyUsage: freezed == starCandyUsage ? _self.starCandyUsage : starCandyUsage // ignore: cast_nullable_to_non_nullable
as int?,starCandyBonusUsage: freezed == starCandyBonusUsage ? _self.starCandyBonusUsage : starCandyBonusUsage // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteModelCopyWith<$Res> get vote {
  
  return $VoteModelCopyWith<$Res>(_self.vote, (value) {
    return _then(_self.copyWith(vote: value));
  });
}/// Create a copy of VotePickModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteItemModelCopyWith<$Res> get voteItem {
  
  return $VoteItemModelCopyWith<$Res>(_self.voteItem, (value) {
    return _then(_self.copyWith(voteItem: value));
  });
}
}

// dart format on
