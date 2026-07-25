// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/vote_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VoteTransactionRequest {

 int get voteId; int get voteItemId; BigInt get amount; String get requestId;
/// Create a copy of VoteTransactionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteTransactionRequestCopyWith<VoteTransactionRequest> get copyWith => _$VoteTransactionRequestCopyWithImpl<VoteTransactionRequest>(this as VoteTransactionRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteTransactionRequest&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.voteItemId, voteItemId) || other.voteItemId == voteItemId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,voteId,voteItemId,amount,requestId);

@override
String toString() {
  return 'VoteTransactionRequest(voteId: $voteId, voteItemId: $voteItemId, amount: $amount, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $VoteTransactionRequestCopyWith<$Res>  {
  factory $VoteTransactionRequestCopyWith(VoteTransactionRequest value, $Res Function(VoteTransactionRequest) _then) = _$VoteTransactionRequestCopyWithImpl;
@useResult
$Res call({
 int voteId, int voteItemId, BigInt amount, String requestId
});




}
/// @nodoc
class _$VoteTransactionRequestCopyWithImpl<$Res>
    implements $VoteTransactionRequestCopyWith<$Res> {
  _$VoteTransactionRequestCopyWithImpl(this._self, this._then);

  final VoteTransactionRequest _self;
  final $Res Function(VoteTransactionRequest) _then;

/// Create a copy of VoteTransactionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? voteId = null,Object? voteItemId = null,Object? amount = null,Object? requestId = null,}) {
  return _then(_self.copyWith(
voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,voteItemId: null == voteItemId ? _self.voteItemId : voteItemId // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VoteTransactionRequest].
extension VoteTransactionRequestPatterns on VoteTransactionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteTransactionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteTransactionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteTransactionRequest value)  $default,){
final _that = this;
switch (_that) {
case _VoteTransactionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteTransactionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VoteTransactionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int voteId,  int voteItemId,  BigInt amount,  String requestId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteTransactionRequest() when $default != null:
return $default(_that.voteId,_that.voteItemId,_that.amount,_that.requestId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int voteId,  int voteItemId,  BigInt amount,  String requestId)  $default,) {final _that = this;
switch (_that) {
case _VoteTransactionRequest():
return $default(_that.voteId,_that.voteItemId,_that.amount,_that.requestId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int voteId,  int voteItemId,  BigInt amount,  String requestId)?  $default,) {final _that = this;
switch (_that) {
case _VoteTransactionRequest() when $default != null:
return $default(_that.voteId,_that.voteItemId,_that.amount,_that.requestId);case _:
  return null;

}
}

}

/// @nodoc


class _VoteTransactionRequest implements VoteTransactionRequest {
  const _VoteTransactionRequest({required this.voteId, required this.voteItemId, required this.amount, required this.requestId});


@override final  int voteId;
@override final  int voteItemId;
@override final  BigInt amount;
@override final  String requestId;

/// Create a copy of VoteTransactionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteTransactionRequestCopyWith<_VoteTransactionRequest> get copyWith => __$VoteTransactionRequestCopyWithImpl<_VoteTransactionRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteTransactionRequest&&(identical(other.voteId, voteId) || other.voteId == voteId)&&(identical(other.voteItemId, voteItemId) || other.voteItemId == voteItemId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,voteId,voteItemId,amount,requestId);

@override
String toString() {
  return 'VoteTransactionRequest(voteId: $voteId, voteItemId: $voteItemId, amount: $amount, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class _$VoteTransactionRequestCopyWith<$Res> implements $VoteTransactionRequestCopyWith<$Res> {
  factory _$VoteTransactionRequestCopyWith(_VoteTransactionRequest value, $Res Function(_VoteTransactionRequest) _then) = __$VoteTransactionRequestCopyWithImpl;
@override @useResult
$Res call({
 int voteId, int voteItemId, BigInt amount, String requestId
});




}
/// @nodoc
class __$VoteTransactionRequestCopyWithImpl<$Res>
    implements _$VoteTransactionRequestCopyWith<$Res> {
  __$VoteTransactionRequestCopyWithImpl(this._self, this._then);

  final _VoteTransactionRequest _self;
  final $Res Function(_VoteTransactionRequest) _then;

/// Create a copy of VoteTransactionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? voteId = null,Object? voteItemId = null,Object? amount = null,Object? requestId = null,}) {
  return _then(_VoteTransactionRequest(
voteId: null == voteId ? _self.voteId : voteId // ignore: cast_nullable_to_non_nullable
as int,voteItemId: null == voteItemId ? _self.voteItemId : voteItemId // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VoteUsageModel {

@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter() BigInt get cottonCandy;@JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter() BigInt get bonusStarCandy;@JsonKey(name: 'star_candy_usage')@WalletAmountConverter() BigInt get starCandy;
/// Create a copy of VoteUsageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteUsageModelCopyWith<VoteUsageModel> get copyWith => _$VoteUsageModelCopyWithImpl<VoteUsageModel>(this as VoteUsageModel, _$identity);

  /// Serializes this VoteUsageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteUsageModel&&(identical(other.cottonCandy, cottonCandy) || other.cottonCandy == cottonCandy)&&(identical(other.bonusStarCandy, bonusStarCandy) || other.bonusStarCandy == bonusStarCandy)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cottonCandy,bonusStarCandy,starCandy);

@override
String toString() {
  return 'VoteUsageModel(cottonCandy: $cottonCandy, bonusStarCandy: $bonusStarCandy, starCandy: $starCandy)';
}


}

/// @nodoc
abstract mixin class $VoteUsageModelCopyWith<$Res>  {
  factory $VoteUsageModelCopyWith(VoteUsageModel value, $Res Function(VoteUsageModel) _then) = _$VoteUsageModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter() BigInt cottonCandy,@JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter() BigInt bonusStarCandy,@JsonKey(name: 'star_candy_usage')@WalletAmountConverter() BigInt starCandy
});




}
/// @nodoc
class _$VoteUsageModelCopyWithImpl<$Res>
    implements $VoteUsageModelCopyWith<$Res> {
  _$VoteUsageModelCopyWithImpl(this._self, this._then);

  final VoteUsageModel _self;
  final $Res Function(VoteUsageModel) _then;

/// Create a copy of VoteUsageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cottonCandy = null,Object? bonusStarCandy = null,Object? starCandy = null,}) {
  return _then(_self.copyWith(
cottonCandy: null == cottonCandy ? _self.cottonCandy : cottonCandy // ignore: cast_nullable_to_non_nullable
as BigInt,bonusStarCandy: null == bonusStarCandy ? _self.bonusStarCandy : bonusStarCandy // ignore: cast_nullable_to_non_nullable
as BigInt,starCandy: null == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}

}


/// Adds pattern-matching-related methods to [VoteUsageModel].
extension VoteUsageModelPatterns on VoteUsageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteUsageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteUsageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteUsageModel value)  $default,){
final _that = this;
switch (_that) {
case _VoteUsageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteUsageModel value)?  $default,){
final _that = this;
switch (_that) {
case _VoteUsageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter()  BigInt cottonCandy, @JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter()  BigInt bonusStarCandy, @JsonKey(name: 'star_candy_usage')@WalletAmountConverter()  BigInt starCandy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteUsageModel() when $default != null:
return $default(_that.cottonCandy,_that.bonusStarCandy,_that.starCandy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter()  BigInt cottonCandy, @JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter()  BigInt bonusStarCandy, @JsonKey(name: 'star_candy_usage')@WalletAmountConverter()  BigInt starCandy)  $default,) {final _that = this;
switch (_that) {
case _VoteUsageModel():
return $default(_that.cottonCandy,_that.bonusStarCandy,_that.starCandy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter()  BigInt cottonCandy, @JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter()  BigInt bonusStarCandy, @JsonKey(name: 'star_candy_usage')@WalletAmountConverter()  BigInt starCandy)?  $default,) {final _that = this;
switch (_that) {
case _VoteUsageModel() when $default != null:
return $default(_that.cottonCandy,_that.bonusStarCandy,_that.starCandy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteUsageModel implements VoteUsageModel {
  const _VoteUsageModel({@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter() required this.cottonCandy, @JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter() required this.bonusStarCandy, @JsonKey(name: 'star_candy_usage')@WalletAmountConverter() required this.starCandy});
  factory _VoteUsageModel.fromJson(Map<String, dynamic> json) => _$VoteUsageModelFromJson(json);

@override@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter() final  BigInt cottonCandy;
@override@JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter() final  BigInt bonusStarCandy;
@override@JsonKey(name: 'star_candy_usage')@WalletAmountConverter() final  BigInt starCandy;

/// Create a copy of VoteUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteUsageModelCopyWith<_VoteUsageModel> get copyWith => __$VoteUsageModelCopyWithImpl<_VoteUsageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteUsageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteUsageModel&&(identical(other.cottonCandy, cottonCandy) || other.cottonCandy == cottonCandy)&&(identical(other.bonusStarCandy, bonusStarCandy) || other.bonusStarCandy == bonusStarCandy)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cottonCandy,bonusStarCandy,starCandy);

@override
String toString() {
  return 'VoteUsageModel(cottonCandy: $cottonCandy, bonusStarCandy: $bonusStarCandy, starCandy: $starCandy)';
}


}

/// @nodoc
abstract mixin class _$VoteUsageModelCopyWith<$Res> implements $VoteUsageModelCopyWith<$Res> {
  factory _$VoteUsageModelCopyWith(_VoteUsageModel value, $Res Function(_VoteUsageModel) _then) = __$VoteUsageModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'cotton_candy_usage')@WalletAmountConverter() BigInt cottonCandy,@JsonKey(name: 'star_candy_bonus_usage')@WalletAmountConverter() BigInt bonusStarCandy,@JsonKey(name: 'star_candy_usage')@WalletAmountConverter() BigInt starCandy
});




}
/// @nodoc
class __$VoteUsageModelCopyWithImpl<$Res>
    implements _$VoteUsageModelCopyWith<$Res> {
  __$VoteUsageModelCopyWithImpl(this._self, this._then);

  final _VoteUsageModel _self;
  final $Res Function(_VoteUsageModel) _then;

/// Create a copy of VoteUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cottonCandy = null,Object? bonusStarCandy = null,Object? starCandy = null,}) {
  return _then(_VoteUsageModel(
cottonCandy: null == cottonCandy ? _self.cottonCandy : cottonCandy // ignore: cast_nullable_to_non_nullable
as BigInt,bonusStarCandy: null == bonusStarCandy ? _self.bonusStarCandy : bonusStarCandy // ignore: cast_nullable_to_non_nullable
as BigInt,starCandy: null == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}


/// @nodoc
mixin _$VoteTransactionResultModel {

@JsonKey(name: 'operation_id') String get operationId; bool get replayed;@JsonKey(name: 'votePickId') int get votePickId;@JsonKey(name: 'updatedVoteTotal') int get updatedVoteTotal;@JsonKey(name: 'addedVoteTotal') int get addedVoteTotal;@JsonKey(name: 'updatedAt') DateTime get updatedAt; VoteUsageModel get usage; WalletSummaryModel get wallet;
/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoteTransactionResultModelCopyWith<VoteTransactionResultModel> get copyWith => _$VoteTransactionResultModelCopyWithImpl<VoteTransactionResultModel>(this as VoteTransactionResultModel, _$identity);

  /// Serializes this VoteTransactionResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoteTransactionResultModel&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.replayed, replayed) || other.replayed == replayed)&&(identical(other.votePickId, votePickId) || other.votePickId == votePickId)&&(identical(other.updatedVoteTotal, updatedVoteTotal) || other.updatedVoteTotal == updatedVoteTotal)&&(identical(other.addedVoteTotal, addedVoteTotal) || other.addedVoteTotal == addedVoteTotal)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.wallet, wallet) || other.wallet == wallet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,replayed,votePickId,updatedVoteTotal,addedVoteTotal,updatedAt,usage,wallet);

@override
String toString() {
  return 'VoteTransactionResultModel(operationId: $operationId, replayed: $replayed, votePickId: $votePickId, updatedVoteTotal: $updatedVoteTotal, addedVoteTotal: $addedVoteTotal, updatedAt: $updatedAt, usage: $usage, wallet: $wallet)';
}


}

/// @nodoc
abstract mixin class $VoteTransactionResultModelCopyWith<$Res>  {
  factory $VoteTransactionResultModelCopyWith(VoteTransactionResultModel value, $Res Function(VoteTransactionResultModel) _then) = _$VoteTransactionResultModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'operation_id') String operationId, bool replayed,@JsonKey(name: 'votePickId') int votePickId,@JsonKey(name: 'updatedVoteTotal') int updatedVoteTotal,@JsonKey(name: 'addedVoteTotal') int addedVoteTotal,@JsonKey(name: 'updatedAt') DateTime updatedAt, VoteUsageModel usage, WalletSummaryModel wallet
});


$VoteUsageModelCopyWith<$Res> get usage;$WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class _$VoteTransactionResultModelCopyWithImpl<$Res>
    implements $VoteTransactionResultModelCopyWith<$Res> {
  _$VoteTransactionResultModelCopyWithImpl(this._self, this._then);

  final VoteTransactionResultModel _self;
  final $Res Function(VoteTransactionResultModel) _then;

/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? replayed = null,Object? votePickId = null,Object? updatedVoteTotal = null,Object? addedVoteTotal = null,Object? updatedAt = null,Object? usage = null,Object? wallet = null,}) {
  return _then(_self.copyWith(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,replayed: null == replayed ? _self.replayed : replayed // ignore: cast_nullable_to_non_nullable
as bool,votePickId: null == votePickId ? _self.votePickId : votePickId // ignore: cast_nullable_to_non_nullable
as int,updatedVoteTotal: null == updatedVoteTotal ? _self.updatedVoteTotal : updatedVoteTotal // ignore: cast_nullable_to_non_nullable
as int,addedVoteTotal: null == addedVoteTotal ? _self.addedVoteTotal : addedVoteTotal // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as VoteUsageModel,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,
  ));
}
/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteUsageModelCopyWith<$Res> get usage {

  return $VoteUsageModelCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<$Res> get wallet {

  return $WalletSummaryModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [VoteTransactionResultModel].
extension VoteTransactionResultModelPatterns on VoteTransactionResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoteTransactionResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoteTransactionResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoteTransactionResultModel value)  $default,){
final _that = this;
switch (_that) {
case _VoteTransactionResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoteTransactionResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _VoteTransactionResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'votePickId')  int votePickId, @JsonKey(name: 'updatedVoteTotal')  int updatedVoteTotal, @JsonKey(name: 'addedVoteTotal')  int addedVoteTotal, @JsonKey(name: 'updatedAt')  DateTime updatedAt,  VoteUsageModel usage,  WalletSummaryModel wallet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoteTransactionResultModel() when $default != null:
return $default(_that.operationId,_that.replayed,_that.votePickId,_that.updatedVoteTotal,_that.addedVoteTotal,_that.updatedAt,_that.usage,_that.wallet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'votePickId')  int votePickId, @JsonKey(name: 'updatedVoteTotal')  int updatedVoteTotal, @JsonKey(name: 'addedVoteTotal')  int addedVoteTotal, @JsonKey(name: 'updatedAt')  DateTime updatedAt,  VoteUsageModel usage,  WalletSummaryModel wallet)  $default,) {final _that = this;
switch (_that) {
case _VoteTransactionResultModel():
return $default(_that.operationId,_that.replayed,_that.votePickId,_that.updatedVoteTotal,_that.addedVoteTotal,_that.updatedAt,_that.usage,_that.wallet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'votePickId')  int votePickId, @JsonKey(name: 'updatedVoteTotal')  int updatedVoteTotal, @JsonKey(name: 'addedVoteTotal')  int addedVoteTotal, @JsonKey(name: 'updatedAt')  DateTime updatedAt,  VoteUsageModel usage,  WalletSummaryModel wallet)?  $default,) {final _that = this;
switch (_that) {
case _VoteTransactionResultModel() when $default != null:
return $default(_that.operationId,_that.replayed,_that.votePickId,_that.updatedVoteTotal,_that.addedVoteTotal,_that.updatedAt,_that.usage,_that.wallet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoteTransactionResultModel extends VoteTransactionResultModel {
  const _VoteTransactionResultModel({@JsonKey(name: 'operation_id') required this.operationId, required this.replayed, @JsonKey(name: 'votePickId') required this.votePickId, @JsonKey(name: 'updatedVoteTotal') required this.updatedVoteTotal, @JsonKey(name: 'addedVoteTotal') required this.addedVoteTotal, @JsonKey(name: 'updatedAt') required this.updatedAt, required this.usage, required this.wallet}): super._();
  factory _VoteTransactionResultModel.fromJson(Map<String, dynamic> json) => _$VoteTransactionResultModelFromJson(json);

@override@JsonKey(name: 'operation_id') final  String operationId;
@override final  bool replayed;
@override@JsonKey(name: 'votePickId') final  int votePickId;
@override@JsonKey(name: 'updatedVoteTotal') final  int updatedVoteTotal;
@override@JsonKey(name: 'addedVoteTotal') final  int addedVoteTotal;
@override@JsonKey(name: 'updatedAt') final  DateTime updatedAt;
@override final  VoteUsageModel usage;
@override final  WalletSummaryModel wallet;

/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoteTransactionResultModelCopyWith<_VoteTransactionResultModel> get copyWith => __$VoteTransactionResultModelCopyWithImpl<_VoteTransactionResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoteTransactionResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoteTransactionResultModel&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.replayed, replayed) || other.replayed == replayed)&&(identical(other.votePickId, votePickId) || other.votePickId == votePickId)&&(identical(other.updatedVoteTotal, updatedVoteTotal) || other.updatedVoteTotal == updatedVoteTotal)&&(identical(other.addedVoteTotal, addedVoteTotal) || other.addedVoteTotal == addedVoteTotal)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.wallet, wallet) || other.wallet == wallet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,replayed,votePickId,updatedVoteTotal,addedVoteTotal,updatedAt,usage,wallet);

@override
String toString() {
  return 'VoteTransactionResultModel(operationId: $operationId, replayed: $replayed, votePickId: $votePickId, updatedVoteTotal: $updatedVoteTotal, addedVoteTotal: $addedVoteTotal, updatedAt: $updatedAt, usage: $usage, wallet: $wallet)';
}


}

/// @nodoc
abstract mixin class _$VoteTransactionResultModelCopyWith<$Res> implements $VoteTransactionResultModelCopyWith<$Res> {
  factory _$VoteTransactionResultModelCopyWith(_VoteTransactionResultModel value, $Res Function(_VoteTransactionResultModel) _then) = __$VoteTransactionResultModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'operation_id') String operationId, bool replayed,@JsonKey(name: 'votePickId') int votePickId,@JsonKey(name: 'updatedVoteTotal') int updatedVoteTotal,@JsonKey(name: 'addedVoteTotal') int addedVoteTotal,@JsonKey(name: 'updatedAt') DateTime updatedAt, VoteUsageModel usage, WalletSummaryModel wallet
});


@override $VoteUsageModelCopyWith<$Res> get usage;@override $WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class __$VoteTransactionResultModelCopyWithImpl<$Res>
    implements _$VoteTransactionResultModelCopyWith<$Res> {
  __$VoteTransactionResultModelCopyWithImpl(this._self, this._then);

  final _VoteTransactionResultModel _self;
  final $Res Function(_VoteTransactionResultModel) _then;

/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? replayed = null,Object? votePickId = null,Object? updatedVoteTotal = null,Object? addedVoteTotal = null,Object? updatedAt = null,Object? usage = null,Object? wallet = null,}) {
  return _then(_VoteTransactionResultModel(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,replayed: null == replayed ? _self.replayed : replayed // ignore: cast_nullable_to_non_nullable
as bool,votePickId: null == votePickId ? _self.votePickId : votePickId // ignore: cast_nullable_to_non_nullable
as int,updatedVoteTotal: null == updatedVoteTotal ? _self.updatedVoteTotal : updatedVoteTotal // ignore: cast_nullable_to_non_nullable
as int,addedVoteTotal: null == addedVoteTotal ? _self.addedVoteTotal : addedVoteTotal // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as VoteUsageModel,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,
  ));
}

/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VoteUsageModelCopyWith<$Res> get usage {

  return $VoteUsageModelCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}/// Create a copy of VoteTransactionResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<$Res> get wallet {

  return $WalletSummaryModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}

// dart format on
