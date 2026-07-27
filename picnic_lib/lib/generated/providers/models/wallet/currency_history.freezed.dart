// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/wallet/currency_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrencyHistoryItemModel {

 String get id;@WalletCurrencyConverter() WalletCurrency get currency;@JsonKey(name: 'event_type') String get eventType; String get origin;@WalletAmountConverter() BigInt get delta;@JsonKey(name: 'balance_effect')@WalletAmountConverter() BigInt get balanceEffect;@JsonKey(name: 'expires_at') DateTime? get expiresAt;@JsonKey(name: 'purchase_id') String? get purchaseId;@JsonKey(name: 'refund_id') String? get refundId;@JsonKey(name: 'grant_id') String? get grantId;@JsonKey(name: 'operation_id') String get operationId;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of CurrencyHistoryItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyHistoryItemModelCopyWith<CurrencyHistoryItemModel> get copyWith => _$CurrencyHistoryItemModelCopyWithImpl<CurrencyHistoryItemModel>(this as CurrencyHistoryItemModel, _$identity);

  /// Serializes this CurrencyHistoryItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrencyHistoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.balanceEffect, balanceEffect) || other.balanceEffect == balanceEffect)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.purchaseId, purchaseId) || other.purchaseId == purchaseId)&&(identical(other.refundId, refundId) || other.refundId == refundId)&&(identical(other.grantId, grantId) || other.grantId == grantId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,eventType,origin,delta,balanceEffect,expiresAt,purchaseId,refundId,grantId,operationId,createdAt);

@override
String toString() {
  return 'CurrencyHistoryItemModel(id: $id, currency: $currency, eventType: $eventType, origin: $origin, delta: $delta, balanceEffect: $balanceEffect, expiresAt: $expiresAt, purchaseId: $purchaseId, refundId: $refundId, grantId: $grantId, operationId: $operationId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CurrencyHistoryItemModelCopyWith<$Res>  {
  factory $CurrencyHistoryItemModelCopyWith(CurrencyHistoryItemModel value, $Res Function(CurrencyHistoryItemModel) _then) = _$CurrencyHistoryItemModelCopyWithImpl;
@useResult
$Res call({
 String id,@WalletCurrencyConverter() WalletCurrency currency,@JsonKey(name: 'event_type') String eventType, String origin,@WalletAmountConverter() BigInt delta,@JsonKey(name: 'balance_effect')@WalletAmountConverter() BigInt balanceEffect,@JsonKey(name: 'expires_at') DateTime? expiresAt,@JsonKey(name: 'purchase_id') String? purchaseId,@JsonKey(name: 'refund_id') String? refundId,@JsonKey(name: 'grant_id') String? grantId,@JsonKey(name: 'operation_id') String operationId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$CurrencyHistoryItemModelCopyWithImpl<$Res>
    implements $CurrencyHistoryItemModelCopyWith<$Res> {
  _$CurrencyHistoryItemModelCopyWithImpl(this._self, this._then);

  final CurrencyHistoryItemModel _self;
  final $Res Function(CurrencyHistoryItemModel) _then;

/// Create a copy of CurrencyHistoryItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? currency = null,Object? eventType = null,Object? origin = null,Object? delta = null,Object? balanceEffect = null,Object? expiresAt = freezed,Object? purchaseId = freezed,Object? refundId = freezed,Object? grantId = freezed,Object? operationId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as WalletCurrency,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as BigInt,balanceEffect: null == balanceEffect ? _self.balanceEffect : balanceEffect // ignore: cast_nullable_to_non_nullable
as BigInt,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchaseId: freezed == purchaseId ? _self.purchaseId : purchaseId // ignore: cast_nullable_to_non_nullable
as String?,refundId: freezed == refundId ? _self.refundId : refundId // ignore: cast_nullable_to_non_nullable
as String?,grantId: freezed == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String?,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrencyHistoryItemModel].
extension CurrencyHistoryItemModelPatterns on CurrencyHistoryItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrencyHistoryItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrencyHistoryItemModel value)  $default,){
final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrencyHistoryItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @JsonKey(name: 'event_type')  String eventType,  String origin, @WalletAmountConverter()  BigInt delta, @JsonKey(name: 'balance_effect')@WalletAmountConverter()  BigInt balanceEffect, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'purchase_id')  String? purchaseId, @JsonKey(name: 'refund_id')  String? refundId, @JsonKey(name: 'grant_id')  String? grantId, @JsonKey(name: 'operation_id')  String operationId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel() when $default != null:
return $default(_that.id,_that.currency,_that.eventType,_that.origin,_that.delta,_that.balanceEffect,_that.expiresAt,_that.purchaseId,_that.refundId,_that.grantId,_that.operationId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @JsonKey(name: 'event_type')  String eventType,  String origin, @WalletAmountConverter()  BigInt delta, @JsonKey(name: 'balance_effect')@WalletAmountConverter()  BigInt balanceEffect, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'purchase_id')  String? purchaseId, @JsonKey(name: 'refund_id')  String? refundId, @JsonKey(name: 'grant_id')  String? grantId, @JsonKey(name: 'operation_id')  String operationId, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel():
return $default(_that.id,_that.currency,_that.eventType,_that.origin,_that.delta,_that.balanceEffect,_that.expiresAt,_that.purchaseId,_that.refundId,_that.grantId,_that.operationId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @JsonKey(name: 'event_type')  String eventType,  String origin, @WalletAmountConverter()  BigInt delta, @JsonKey(name: 'balance_effect')@WalletAmountConverter()  BigInt balanceEffect, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'purchase_id')  String? purchaseId, @JsonKey(name: 'refund_id')  String? refundId, @JsonKey(name: 'grant_id')  String? grantId, @JsonKey(name: 'operation_id')  String operationId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CurrencyHistoryItemModel() when $default != null:
return $default(_that.id,_that.currency,_that.eventType,_that.origin,_that.delta,_that.balanceEffect,_that.expiresAt,_that.purchaseId,_that.refundId,_that.grantId,_that.operationId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurrencyHistoryItemModel implements CurrencyHistoryItemModel {
  const _CurrencyHistoryItemModel({required this.id, @WalletCurrencyConverter() required this.currency, @JsonKey(name: 'event_type') required this.eventType, required this.origin, @WalletAmountConverter() required this.delta, @JsonKey(name: 'balance_effect')@WalletAmountConverter() required this.balanceEffect, @JsonKey(name: 'expires_at') this.expiresAt, @JsonKey(name: 'purchase_id') this.purchaseId, @JsonKey(name: 'refund_id') this.refundId, @JsonKey(name: 'grant_id') this.grantId, @JsonKey(name: 'operation_id') required this.operationId, @JsonKey(name: 'created_at') required this.createdAt});
  factory _CurrencyHistoryItemModel.fromJson(Map<String, dynamic> json) => _$CurrencyHistoryItemModelFromJson(json);

@override final  String id;
@override@WalletCurrencyConverter() final  WalletCurrency currency;
@override@JsonKey(name: 'event_type') final  String eventType;
@override final  String origin;
@override@WalletAmountConverter() final  BigInt delta;
@override@JsonKey(name: 'balance_effect')@WalletAmountConverter() final  BigInt balanceEffect;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;
@override@JsonKey(name: 'purchase_id') final  String? purchaseId;
@override@JsonKey(name: 'refund_id') final  String? refundId;
@override@JsonKey(name: 'grant_id') final  String? grantId;
@override@JsonKey(name: 'operation_id') final  String operationId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of CurrencyHistoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencyHistoryItemModelCopyWith<_CurrencyHistoryItemModel> get copyWith => __$CurrencyHistoryItemModelCopyWithImpl<_CurrencyHistoryItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurrencyHistoryItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrencyHistoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.balanceEffect, balanceEffect) || other.balanceEffect == balanceEffect)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.purchaseId, purchaseId) || other.purchaseId == purchaseId)&&(identical(other.refundId, refundId) || other.refundId == refundId)&&(identical(other.grantId, grantId) || other.grantId == grantId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,eventType,origin,delta,balanceEffect,expiresAt,purchaseId,refundId,grantId,operationId,createdAt);

@override
String toString() {
  return 'CurrencyHistoryItemModel(id: $id, currency: $currency, eventType: $eventType, origin: $origin, delta: $delta, balanceEffect: $balanceEffect, expiresAt: $expiresAt, purchaseId: $purchaseId, refundId: $refundId, grantId: $grantId, operationId: $operationId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CurrencyHistoryItemModelCopyWith<$Res> implements $CurrencyHistoryItemModelCopyWith<$Res> {
  factory _$CurrencyHistoryItemModelCopyWith(_CurrencyHistoryItemModel value, $Res Function(_CurrencyHistoryItemModel) _then) = __$CurrencyHistoryItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@WalletCurrencyConverter() WalletCurrency currency,@JsonKey(name: 'event_type') String eventType, String origin,@WalletAmountConverter() BigInt delta,@JsonKey(name: 'balance_effect')@WalletAmountConverter() BigInt balanceEffect,@JsonKey(name: 'expires_at') DateTime? expiresAt,@JsonKey(name: 'purchase_id') String? purchaseId,@JsonKey(name: 'refund_id') String? refundId,@JsonKey(name: 'grant_id') String? grantId,@JsonKey(name: 'operation_id') String operationId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$CurrencyHistoryItemModelCopyWithImpl<$Res>
    implements _$CurrencyHistoryItemModelCopyWith<$Res> {
  __$CurrencyHistoryItemModelCopyWithImpl(this._self, this._then);

  final _CurrencyHistoryItemModel _self;
  final $Res Function(_CurrencyHistoryItemModel) _then;

/// Create a copy of CurrencyHistoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? currency = null,Object? eventType = null,Object? origin = null,Object? delta = null,Object? balanceEffect = null,Object? expiresAt = freezed,Object? purchaseId = freezed,Object? refundId = freezed,Object? grantId = freezed,Object? operationId = null,Object? createdAt = null,}) {
  return _then(_CurrencyHistoryItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as WalletCurrency,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as BigInt,balanceEffect: null == balanceEffect ? _self.balanceEffect : balanceEffect // ignore: cast_nullable_to_non_nullable
as BigInt,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchaseId: freezed == purchaseId ? _self.purchaseId : purchaseId // ignore: cast_nullable_to_non_nullable
as String?,refundId: freezed == refundId ? _self.refundId : refundId // ignore: cast_nullable_to_non_nullable
as String?,grantId: freezed == grantId ? _self.grantId : grantId // ignore: cast_nullable_to_non_nullable
as String?,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CurrencyHistoryPageModel {

 List<CurrencyHistoryItemModel> get items;@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt get totalCount;@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'snapshot_at') DateTime get snapshotAt;
/// Create a copy of CurrencyHistoryPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyHistoryPageModelCopyWith<CurrencyHistoryPageModel> get copyWith => _$CurrencyHistoryPageModelCopyWithImpl<CurrencyHistoryPageModel>(this as CurrencyHistoryPageModel, _$identity);

  /// Serializes this CurrencyHistoryPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrencyHistoryPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,nextCursor,snapshotAt);

@override
String toString() {
  return 'CurrencyHistoryPageModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class $CurrencyHistoryPageModelCopyWith<$Res>  {
  factory $CurrencyHistoryPageModelCopyWith(CurrencyHistoryPageModel value, $Res Function(CurrencyHistoryPageModel) _then) = _$CurrencyHistoryPageModelCopyWithImpl;
@useResult
$Res call({
 List<CurrencyHistoryItemModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class _$CurrencyHistoryPageModelCopyWithImpl<$Res>
    implements $CurrencyHistoryPageModelCopyWith<$Res> {
  _$CurrencyHistoryPageModelCopyWithImpl(this._self, this._then);

  final CurrencyHistoryPageModel _self;
  final $Res Function(CurrencyHistoryPageModel) _then;

/// Create a copy of CurrencyHistoryPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CurrencyHistoryItemModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrencyHistoryPageModel].
extension CurrencyHistoryPageModelPatterns on CurrencyHistoryPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrencyHistoryPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrencyHistoryPageModel value)  $default,){
final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrencyHistoryPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CurrencyHistoryItemModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CurrencyHistoryItemModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)  $default,) {final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel():
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CurrencyHistoryItemModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,) {final _that = this;
switch (_that) {
case _CurrencyHistoryPageModel() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurrencyHistoryPageModel implements CurrencyHistoryPageModel {
  const _CurrencyHistoryPageModel({required final  List<CurrencyHistoryItemModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter() required this.totalCount, @JsonKey(name: 'next_cursor') this.nextCursor, @JsonKey(name: 'snapshot_at') required this.snapshotAt}): _items = items;
  factory _CurrencyHistoryPageModel.fromJson(Map<String, dynamic> json) => _$CurrencyHistoryPageModelFromJson(json);

 final  List<CurrencyHistoryItemModel> _items;
@override List<CurrencyHistoryItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count')@WalletAmountConverter() final  BigInt totalCount;
@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'snapshot_at') final  DateTime snapshotAt;

/// Create a copy of CurrencyHistoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencyHistoryPageModelCopyWith<_CurrencyHistoryPageModel> get copyWith => __$CurrencyHistoryPageModelCopyWithImpl<_CurrencyHistoryPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurrencyHistoryPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrencyHistoryPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,nextCursor,snapshotAt);

@override
String toString() {
  return 'CurrencyHistoryPageModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class _$CurrencyHistoryPageModelCopyWith<$Res> implements $CurrencyHistoryPageModelCopyWith<$Res> {
  factory _$CurrencyHistoryPageModelCopyWith(_CurrencyHistoryPageModel value, $Res Function(_CurrencyHistoryPageModel) _then) = __$CurrencyHistoryPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<CurrencyHistoryItemModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class __$CurrencyHistoryPageModelCopyWithImpl<$Res>
    implements _$CurrencyHistoryPageModelCopyWith<$Res> {
  __$CurrencyHistoryPageModelCopyWithImpl(this._self, this._then);

  final _CurrencyHistoryPageModel _self;
  final $Res Function(_CurrencyHistoryPageModel) _then;

/// Create a copy of CurrencyHistoryPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,}) {
  return _then(_CurrencyHistoryPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CurrencyHistoryItemModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
