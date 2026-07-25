// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/purchase/purchase_settlement_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PurchasePromotionResultModel {

@JsonKey(name: 'resolution_id') String get resolutionId;@PurchasePromotionStateConverter() PurchasePromotionState get state;@JsonKey(name: 'campaign_version_id') String? get campaignVersionId;@JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter() BigInt get promoBonusAmount;@JsonKey(name: 'domain_code') String? get domainCode;
/// Create a copy of PurchasePromotionResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchasePromotionResultModelCopyWith<PurchasePromotionResultModel> get copyWith => _$PurchasePromotionResultModelCopyWithImpl<PurchasePromotionResultModel>(this as PurchasePromotionResultModel, _$identity);

  /// Serializes this PurchasePromotionResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchasePromotionResultModel&&(identical(other.resolutionId, resolutionId) || other.resolutionId == resolutionId)&&(identical(other.state, state) || other.state == state)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.promoBonusAmount, promoBonusAmount) || other.promoBonusAmount == promoBonusAmount)&&(identical(other.domainCode, domainCode) || other.domainCode == domainCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resolutionId,state,campaignVersionId,promoBonusAmount,domainCode);

@override
String toString() {
  return 'PurchasePromotionResultModel(resolutionId: $resolutionId, state: $state, campaignVersionId: $campaignVersionId, promoBonusAmount: $promoBonusAmount, domainCode: $domainCode)';
}


}

/// @nodoc
abstract mixin class $PurchasePromotionResultModelCopyWith<$Res>  {
  factory $PurchasePromotionResultModelCopyWith(PurchasePromotionResultModel value, $Res Function(PurchasePromotionResultModel) _then) = _$PurchasePromotionResultModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'resolution_id') String resolutionId,@PurchasePromotionStateConverter() PurchasePromotionState state,@JsonKey(name: 'campaign_version_id') String? campaignVersionId,@JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter() BigInt promoBonusAmount,@JsonKey(name: 'domain_code') String? domainCode
});




}
/// @nodoc
class _$PurchasePromotionResultModelCopyWithImpl<$Res>
    implements $PurchasePromotionResultModelCopyWith<$Res> {
  _$PurchasePromotionResultModelCopyWithImpl(this._self, this._then);

  final PurchasePromotionResultModel _self;
  final $Res Function(PurchasePromotionResultModel) _then;

/// Create a copy of PurchasePromotionResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resolutionId = null,Object? state = null,Object? campaignVersionId = freezed,Object? promoBonusAmount = null,Object? domainCode = freezed,}) {
  return _then(_self.copyWith(
resolutionId: null == resolutionId ? _self.resolutionId : resolutionId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PurchasePromotionState,campaignVersionId: freezed == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String?,promoBonusAmount: null == promoBonusAmount ? _self.promoBonusAmount : promoBonusAmount // ignore: cast_nullable_to_non_nullable
as BigInt,domainCode: freezed == domainCode ? _self.domainCode : domainCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchasePromotionResultModel].
extension PurchasePromotionResultModelPatterns on PurchasePromotionResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchasePromotionResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchasePromotionResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchasePromotionResultModel value)  $default,){
final _that = this;
switch (_that) {
case _PurchasePromotionResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchasePromotionResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _PurchasePromotionResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'resolution_id')  String resolutionId, @PurchasePromotionStateConverter()  PurchasePromotionState state, @JsonKey(name: 'campaign_version_id')  String? campaignVersionId, @JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter()  BigInt promoBonusAmount, @JsonKey(name: 'domain_code')  String? domainCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchasePromotionResultModel() when $default != null:
return $default(_that.resolutionId,_that.state,_that.campaignVersionId,_that.promoBonusAmount,_that.domainCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'resolution_id')  String resolutionId, @PurchasePromotionStateConverter()  PurchasePromotionState state, @JsonKey(name: 'campaign_version_id')  String? campaignVersionId, @JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter()  BigInt promoBonusAmount, @JsonKey(name: 'domain_code')  String? domainCode)  $default,) {final _that = this;
switch (_that) {
case _PurchasePromotionResultModel():
return $default(_that.resolutionId,_that.state,_that.campaignVersionId,_that.promoBonusAmount,_that.domainCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'resolution_id')  String resolutionId, @PurchasePromotionStateConverter()  PurchasePromotionState state, @JsonKey(name: 'campaign_version_id')  String? campaignVersionId, @JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter()  BigInt promoBonusAmount, @JsonKey(name: 'domain_code')  String? domainCode)?  $default,) {final _that = this;
switch (_that) {
case _PurchasePromotionResultModel() when $default != null:
return $default(_that.resolutionId,_that.state,_that.campaignVersionId,_that.promoBonusAmount,_that.domainCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchasePromotionResultModel implements PurchasePromotionResultModel {
  const _PurchasePromotionResultModel({@JsonKey(name: 'resolution_id') required this.resolutionId, @PurchasePromotionStateConverter() required this.state, @JsonKey(name: 'campaign_version_id') required this.campaignVersionId, @JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter() required this.promoBonusAmount, @JsonKey(name: 'domain_code') required this.domainCode});
  factory _PurchasePromotionResultModel.fromJson(Map<String, dynamic> json) => _$PurchasePromotionResultModelFromJson(json);

@override@JsonKey(name: 'resolution_id') final  String resolutionId;
@override@PurchasePromotionStateConverter() final  PurchasePromotionState state;
@override@JsonKey(name: 'campaign_version_id') final  String? campaignVersionId;
@override@JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter() final  BigInt promoBonusAmount;
@override@JsonKey(name: 'domain_code') final  String? domainCode;

/// Create a copy of PurchasePromotionResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchasePromotionResultModelCopyWith<_PurchasePromotionResultModel> get copyWith => __$PurchasePromotionResultModelCopyWithImpl<_PurchasePromotionResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchasePromotionResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchasePromotionResultModel&&(identical(other.resolutionId, resolutionId) || other.resolutionId == resolutionId)&&(identical(other.state, state) || other.state == state)&&(identical(other.campaignVersionId, campaignVersionId) || other.campaignVersionId == campaignVersionId)&&(identical(other.promoBonusAmount, promoBonusAmount) || other.promoBonusAmount == promoBonusAmount)&&(identical(other.domainCode, domainCode) || other.domainCode == domainCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resolutionId,state,campaignVersionId,promoBonusAmount,domainCode);

@override
String toString() {
  return 'PurchasePromotionResultModel(resolutionId: $resolutionId, state: $state, campaignVersionId: $campaignVersionId, promoBonusAmount: $promoBonusAmount, domainCode: $domainCode)';
}


}

/// @nodoc
abstract mixin class _$PurchasePromotionResultModelCopyWith<$Res> implements $PurchasePromotionResultModelCopyWith<$Res> {
  factory _$PurchasePromotionResultModelCopyWith(_PurchasePromotionResultModel value, $Res Function(_PurchasePromotionResultModel) _then) = __$PurchasePromotionResultModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'resolution_id') String resolutionId,@PurchasePromotionStateConverter() PurchasePromotionState state,@JsonKey(name: 'campaign_version_id') String? campaignVersionId,@JsonKey(name: 'promo_bonus_amount')@WalletAmountConverter() BigInt promoBonusAmount,@JsonKey(name: 'domain_code') String? domainCode
});




}
/// @nodoc
class __$PurchasePromotionResultModelCopyWithImpl<$Res>
    implements _$PurchasePromotionResultModelCopyWith<$Res> {
  __$PurchasePromotionResultModelCopyWithImpl(this._self, this._then);

  final _PurchasePromotionResultModel _self;
  final $Res Function(_PurchasePromotionResultModel) _then;

/// Create a copy of PurchasePromotionResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resolutionId = null,Object? state = null,Object? campaignVersionId = freezed,Object? promoBonusAmount = null,Object? domainCode = freezed,}) {
  return _then(_PurchasePromotionResultModel(
resolutionId: null == resolutionId ? _self.resolutionId : resolutionId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PurchasePromotionState,campaignVersionId: freezed == campaignVersionId ? _self.campaignVersionId : campaignVersionId // ignore: cast_nullable_to_non_nullable
as String?,promoBonusAmount: null == promoBonusAmount ? _self.promoBonusAmount : promoBonusAmount // ignore: cast_nullable_to_non_nullable
as BigInt,domainCode: freezed == domainCode ? _self.domainCode : domainCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PurchaseSettlementResultModel {

@JsonKey(name: 'contract_version') String get contractVersion;@JsonKey(name: 'operation_id') String get operationId; bool get replayed;@JsonKey(name: 'base_star_amount')@WalletAmountConverter() BigInt get baseStarAmount;@JsonKey(name: 'base_bonus_amount')@WalletAmountConverter() BigInt get baseBonusAmount; PurchasePromotionResultModel? get promotion; WalletSummaryModel get wallet;/// How *this* client came to see a `replayed` settlement. Never part of the
/// wire contract: the server cannot know whose retry it is answering.
///
/// `ReceiptVerificationService` sets it when a `replayed` settlement comes
/// back to a request it sent *after* an earlier request for the same
/// receipt. That earlier request settled on the server and then failed in
/// transport, so the replay is one we caused ourselves and nothing has been
/// shown to the user yet. Absent that, a `replayed` settlement was put
/// there by an earlier delivery or session.
@JsonKey(includeFromJson: false, includeToJson: false) bool get replayCausedByRetry;
/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseSettlementResultModelCopyWith<PurchaseSettlementResultModel> get copyWith => _$PurchaseSettlementResultModelCopyWithImpl<PurchaseSettlementResultModel>(this as PurchaseSettlementResultModel, _$identity);

  /// Serializes this PurchaseSettlementResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseSettlementResultModel&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.replayed, replayed) || other.replayed == replayed)&&(identical(other.baseStarAmount, baseStarAmount) || other.baseStarAmount == baseStarAmount)&&(identical(other.baseBonusAmount, baseBonusAmount) || other.baseBonusAmount == baseBonusAmount)&&(identical(other.promotion, promotion) || other.promotion == promotion)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.replayCausedByRetry, replayCausedByRetry) || other.replayCausedByRetry == replayCausedByRetry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractVersion,operationId,replayed,baseStarAmount,baseBonusAmount,promotion,wallet,replayCausedByRetry);

@override
String toString() {
  return 'PurchaseSettlementResultModel(contractVersion: $contractVersion, operationId: $operationId, replayed: $replayed, baseStarAmount: $baseStarAmount, baseBonusAmount: $baseBonusAmount, promotion: $promotion, wallet: $wallet, replayCausedByRetry: $replayCausedByRetry)';
}


}

/// @nodoc
abstract mixin class $PurchaseSettlementResultModelCopyWith<$Res>  {
  factory $PurchaseSettlementResultModelCopyWith(PurchaseSettlementResultModel value, $Res Function(PurchaseSettlementResultModel) _then) = _$PurchaseSettlementResultModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_version') String contractVersion,@JsonKey(name: 'operation_id') String operationId, bool replayed,@JsonKey(name: 'base_star_amount')@WalletAmountConverter() BigInt baseStarAmount,@JsonKey(name: 'base_bonus_amount')@WalletAmountConverter() BigInt baseBonusAmount, PurchasePromotionResultModel? promotion, WalletSummaryModel wallet,@JsonKey(includeFromJson: false, includeToJson: false) bool replayCausedByRetry
});


$PurchasePromotionResultModelCopyWith<$Res>? get promotion;$WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class _$PurchaseSettlementResultModelCopyWithImpl<$Res>
    implements $PurchaseSettlementResultModelCopyWith<$Res> {
  _$PurchaseSettlementResultModelCopyWithImpl(this._self, this._then);

  final PurchaseSettlementResultModel _self;
  final $Res Function(PurchaseSettlementResultModel) _then;

/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractVersion = null,Object? operationId = null,Object? replayed = null,Object? baseStarAmount = null,Object? baseBonusAmount = null,Object? promotion = freezed,Object? wallet = null,Object? replayCausedByRetry = null,}) {
  return _then(_self.copyWith(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as String,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,replayed: null == replayed ? _self.replayed : replayed // ignore: cast_nullable_to_non_nullable
as bool,baseStarAmount: null == baseStarAmount ? _self.baseStarAmount : baseStarAmount // ignore: cast_nullable_to_non_nullable
as BigInt,baseBonusAmount: null == baseBonusAmount ? _self.baseBonusAmount : baseBonusAmount // ignore: cast_nullable_to_non_nullable
as BigInt,promotion: freezed == promotion ? _self.promotion : promotion // ignore: cast_nullable_to_non_nullable
as PurchasePromotionResultModel?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,replayCausedByRetry: null == replayCausedByRetry ? _self.replayCausedByRetry : replayCausedByRetry // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchasePromotionResultModelCopyWith<$Res>? get promotion {
    if (_self.promotion == null) {
    return null;
  }

  return $PurchasePromotionResultModelCopyWith<$Res>(_self.promotion!, (value) {
    return _then(_self.copyWith(promotion: value));
  });
}/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<$Res> get wallet {
  
  return $WalletSummaryModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [PurchaseSettlementResultModel].
extension PurchaseSettlementResultModelPatterns on PurchaseSettlementResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseSettlementResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseSettlementResultModel value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseSettlementResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_version')  String contractVersion, @JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'base_star_amount')@WalletAmountConverter()  BigInt baseStarAmount, @JsonKey(name: 'base_bonus_amount')@WalletAmountConverter()  BigInt baseBonusAmount,  PurchasePromotionResultModel? promotion,  WalletSummaryModel wallet, @JsonKey(includeFromJson: false, includeToJson: false)  bool replayCausedByRetry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel() when $default != null:
return $default(_that.contractVersion,_that.operationId,_that.replayed,_that.baseStarAmount,_that.baseBonusAmount,_that.promotion,_that.wallet,_that.replayCausedByRetry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_version')  String contractVersion, @JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'base_star_amount')@WalletAmountConverter()  BigInt baseStarAmount, @JsonKey(name: 'base_bonus_amount')@WalletAmountConverter()  BigInt baseBonusAmount,  PurchasePromotionResultModel? promotion,  WalletSummaryModel wallet, @JsonKey(includeFromJson: false, includeToJson: false)  bool replayCausedByRetry)  $default,) {final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel():
return $default(_that.contractVersion,_that.operationId,_that.replayed,_that.baseStarAmount,_that.baseBonusAmount,_that.promotion,_that.wallet,_that.replayCausedByRetry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_version')  String contractVersion, @JsonKey(name: 'operation_id')  String operationId,  bool replayed, @JsonKey(name: 'base_star_amount')@WalletAmountConverter()  BigInt baseStarAmount, @JsonKey(name: 'base_bonus_amount')@WalletAmountConverter()  BigInt baseBonusAmount,  PurchasePromotionResultModel? promotion,  WalletSummaryModel wallet, @JsonKey(includeFromJson: false, includeToJson: false)  bool replayCausedByRetry)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseSettlementResultModel() when $default != null:
return $default(_that.contractVersion,_that.operationId,_that.replayed,_that.baseStarAmount,_that.baseBonusAmount,_that.promotion,_that.wallet,_that.replayCausedByRetry);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseSettlementResultModel implements PurchaseSettlementResultModel {
  const _PurchaseSettlementResultModel({@JsonKey(name: 'contract_version') required this.contractVersion, @JsonKey(name: 'operation_id') required this.operationId, required this.replayed, @JsonKey(name: 'base_star_amount')@WalletAmountConverter() required this.baseStarAmount, @JsonKey(name: 'base_bonus_amount')@WalletAmountConverter() required this.baseBonusAmount, required this.promotion, required this.wallet, @JsonKey(includeFromJson: false, includeToJson: false) this.replayCausedByRetry = false});
  factory _PurchaseSettlementResultModel.fromJson(Map<String, dynamic> json) => _$PurchaseSettlementResultModelFromJson(json);

@override@JsonKey(name: 'contract_version') final  String contractVersion;
@override@JsonKey(name: 'operation_id') final  String operationId;
@override final  bool replayed;
@override@JsonKey(name: 'base_star_amount')@WalletAmountConverter() final  BigInt baseStarAmount;
@override@JsonKey(name: 'base_bonus_amount')@WalletAmountConverter() final  BigInt baseBonusAmount;
@override final  PurchasePromotionResultModel? promotion;
@override final  WalletSummaryModel wallet;
/// How *this* client came to see a `replayed` settlement. Never part of the
/// wire contract: the server cannot know whose retry it is answering.
///
/// `ReceiptVerificationService` sets it when a `replayed` settlement comes
/// back to a request it sent *after* an earlier request for the same
/// receipt. That earlier request settled on the server and then failed in
/// transport, so the replay is one we caused ourselves and nothing has been
/// shown to the user yet. Absent that, a `replayed` settlement was put
/// there by an earlier delivery or session.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool replayCausedByRetry;

/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseSettlementResultModelCopyWith<_PurchaseSettlementResultModel> get copyWith => __$PurchaseSettlementResultModelCopyWithImpl<_PurchaseSettlementResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseSettlementResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseSettlementResultModel&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.replayed, replayed) || other.replayed == replayed)&&(identical(other.baseStarAmount, baseStarAmount) || other.baseStarAmount == baseStarAmount)&&(identical(other.baseBonusAmount, baseBonusAmount) || other.baseBonusAmount == baseBonusAmount)&&(identical(other.promotion, promotion) || other.promotion == promotion)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.replayCausedByRetry, replayCausedByRetry) || other.replayCausedByRetry == replayCausedByRetry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractVersion,operationId,replayed,baseStarAmount,baseBonusAmount,promotion,wallet,replayCausedByRetry);

@override
String toString() {
  return 'PurchaseSettlementResultModel(contractVersion: $contractVersion, operationId: $operationId, replayed: $replayed, baseStarAmount: $baseStarAmount, baseBonusAmount: $baseBonusAmount, promotion: $promotion, wallet: $wallet, replayCausedByRetry: $replayCausedByRetry)';
}


}

/// @nodoc
abstract mixin class _$PurchaseSettlementResultModelCopyWith<$Res> implements $PurchaseSettlementResultModelCopyWith<$Res> {
  factory _$PurchaseSettlementResultModelCopyWith(_PurchaseSettlementResultModel value, $Res Function(_PurchaseSettlementResultModel) _then) = __$PurchaseSettlementResultModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_version') String contractVersion,@JsonKey(name: 'operation_id') String operationId, bool replayed,@JsonKey(name: 'base_star_amount')@WalletAmountConverter() BigInt baseStarAmount,@JsonKey(name: 'base_bonus_amount')@WalletAmountConverter() BigInt baseBonusAmount, PurchasePromotionResultModel? promotion, WalletSummaryModel wallet,@JsonKey(includeFromJson: false, includeToJson: false) bool replayCausedByRetry
});


@override $PurchasePromotionResultModelCopyWith<$Res>? get promotion;@override $WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class __$PurchaseSettlementResultModelCopyWithImpl<$Res>
    implements _$PurchaseSettlementResultModelCopyWith<$Res> {
  __$PurchaseSettlementResultModelCopyWithImpl(this._self, this._then);

  final _PurchaseSettlementResultModel _self;
  final $Res Function(_PurchaseSettlementResultModel) _then;

/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractVersion = null,Object? operationId = null,Object? replayed = null,Object? baseStarAmount = null,Object? baseBonusAmount = null,Object? promotion = freezed,Object? wallet = null,Object? replayCausedByRetry = null,}) {
  return _then(_PurchaseSettlementResultModel(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as String,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,replayed: null == replayed ? _self.replayed : replayed // ignore: cast_nullable_to_non_nullable
as bool,baseStarAmount: null == baseStarAmount ? _self.baseStarAmount : baseStarAmount // ignore: cast_nullable_to_non_nullable
as BigInt,baseBonusAmount: null == baseBonusAmount ? _self.baseBonusAmount : baseBonusAmount // ignore: cast_nullable_to_non_nullable
as BigInt,promotion: freezed == promotion ? _self.promotion : promotion // ignore: cast_nullable_to_non_nullable
as PurchasePromotionResultModel?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,replayCausedByRetry: null == replayCausedByRetry ? _self.replayCausedByRetry : replayCausedByRetry // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PurchaseSettlementResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchasePromotionResultModelCopyWith<$Res>? get promotion {
    if (_self.promotion == null) {
    return null;
  }

  return $PurchasePromotionResultModelCopyWith<$Res>(_self.promotion!, (value) {
    return _then(_self.copyWith(promotion: value));
  });
}/// Create a copy of PurchaseSettlementResultModel
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
