// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/wallet/wallet_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletSummaryModel {

@JsonKey(name: 'contract_version') String get contractVersion;@WalletAmountConverter() BigInt get star;@WalletAmountConverter() BigInt get bonus;@WalletAmountConverter() BigInt get cotton;@JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter() BigInt get cottonExpiringAmount;@JsonKey(name: 'cotton_next_expires_at') DateTime? get cottonNextExpiresAt;@JsonKey(name: 'snapshot_at') DateTime get snapshotAt;
/// Create a copy of WalletSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<WalletSummaryModel> get copyWith => _$WalletSummaryModelCopyWithImpl<WalletSummaryModel>(this as WalletSummaryModel, _$identity);

  /// Serializes this WalletSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletSummaryModel&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.star, star) || other.star == star)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.cotton, cotton) || other.cotton == cotton)&&(identical(other.cottonExpiringAmount, cottonExpiringAmount) || other.cottonExpiringAmount == cottonExpiringAmount)&&(identical(other.cottonNextExpiresAt, cottonNextExpiresAt) || other.cottonNextExpiresAt == cottonNextExpiresAt)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractVersion,star,bonus,cotton,cottonExpiringAmount,cottonNextExpiresAt,snapshotAt);

@override
String toString() {
  return 'WalletSummaryModel(contractVersion: $contractVersion, star: $star, bonus: $bonus, cotton: $cotton, cottonExpiringAmount: $cottonExpiringAmount, cottonNextExpiresAt: $cottonNextExpiresAt, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class $WalletSummaryModelCopyWith<$Res>  {
  factory $WalletSummaryModelCopyWith(WalletSummaryModel value, $Res Function(WalletSummaryModel) _then) = _$WalletSummaryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'contract_version') String contractVersion,@WalletAmountConverter() BigInt star,@WalletAmountConverter() BigInt bonus,@WalletAmountConverter() BigInt cotton,@JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter() BigInt cottonExpiringAmount,@JsonKey(name: 'cotton_next_expires_at') DateTime? cottonNextExpiresAt,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class _$WalletSummaryModelCopyWithImpl<$Res>
    implements $WalletSummaryModelCopyWith<$Res> {
  _$WalletSummaryModelCopyWithImpl(this._self, this._then);

  final WalletSummaryModel _self;
  final $Res Function(WalletSummaryModel) _then;

/// Create a copy of WalletSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractVersion = null,Object? star = null,Object? bonus = null,Object? cotton = null,Object? cottonExpiringAmount = null,Object? cottonNextExpiresAt = freezed,Object? snapshotAt = null,}) {
  return _then(_self.copyWith(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as String,star: null == star ? _self.star : star // ignore: cast_nullable_to_non_nullable
as BigInt,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as BigInt,cotton: null == cotton ? _self.cotton : cotton // ignore: cast_nullable_to_non_nullable
as BigInt,cottonExpiringAmount: null == cottonExpiringAmount ? _self.cottonExpiringAmount : cottonExpiringAmount // ignore: cast_nullable_to_non_nullable
as BigInt,cottonNextExpiresAt: freezed == cottonNextExpiresAt ? _self.cottonNextExpiresAt : cottonNextExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletSummaryModel].
extension WalletSummaryModelPatterns on WalletSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _WalletSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _WalletSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_version')  String contractVersion, @WalletAmountConverter()  BigInt star, @WalletAmountConverter()  BigInt bonus, @WalletAmountConverter()  BigInt cotton, @JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter()  BigInt cottonExpiringAmount, @JsonKey(name: 'cotton_next_expires_at')  DateTime? cottonNextExpiresAt, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletSummaryModel() when $default != null:
return $default(_that.contractVersion,_that.star,_that.bonus,_that.cotton,_that.cottonExpiringAmount,_that.cottonNextExpiresAt,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'contract_version')  String contractVersion, @WalletAmountConverter()  BigInt star, @WalletAmountConverter()  BigInt bonus, @WalletAmountConverter()  BigInt cotton, @JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter()  BigInt cottonExpiringAmount, @JsonKey(name: 'cotton_next_expires_at')  DateTime? cottonNextExpiresAt, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)  $default,) {final _that = this;
switch (_that) {
case _WalletSummaryModel():
return $default(_that.contractVersion,_that.star,_that.bonus,_that.cotton,_that.cottonExpiringAmount,_that.cottonNextExpiresAt,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'contract_version')  String contractVersion, @WalletAmountConverter()  BigInt star, @WalletAmountConverter()  BigInt bonus, @WalletAmountConverter()  BigInt cotton, @JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter()  BigInt cottonExpiringAmount, @JsonKey(name: 'cotton_next_expires_at')  DateTime? cottonNextExpiresAt, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletSummaryModel() when $default != null:
return $default(_that.contractVersion,_that.star,_that.bonus,_that.cotton,_that.cottonExpiringAmount,_that.cottonNextExpiresAt,_that.snapshotAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletSummaryModel implements WalletSummaryModel {
  const _WalletSummaryModel({@JsonKey(name: 'contract_version') required this.contractVersion, @WalletAmountConverter() required this.star, @WalletAmountConverter() required this.bonus, @WalletAmountConverter() required this.cotton, @JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter() required this.cottonExpiringAmount, @JsonKey(name: 'cotton_next_expires_at') required this.cottonNextExpiresAt, @JsonKey(name: 'snapshot_at') required this.snapshotAt});
  factory _WalletSummaryModel.fromJson(Map<String, dynamic> json) => _$WalletSummaryModelFromJson(json);

@override@JsonKey(name: 'contract_version') final  String contractVersion;
@override@WalletAmountConverter() final  BigInt star;
@override@WalletAmountConverter() final  BigInt bonus;
@override@WalletAmountConverter() final  BigInt cotton;
@override@JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter() final  BigInt cottonExpiringAmount;
@override@JsonKey(name: 'cotton_next_expires_at') final  DateTime? cottonNextExpiresAt;
@override@JsonKey(name: 'snapshot_at') final  DateTime snapshotAt;

/// Create a copy of WalletSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletSummaryModelCopyWith<_WalletSummaryModel> get copyWith => __$WalletSummaryModelCopyWithImpl<_WalletSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletSummaryModel&&(identical(other.contractVersion, contractVersion) || other.contractVersion == contractVersion)&&(identical(other.star, star) || other.star == star)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.cotton, cotton) || other.cotton == cotton)&&(identical(other.cottonExpiringAmount, cottonExpiringAmount) || other.cottonExpiringAmount == cottonExpiringAmount)&&(identical(other.cottonNextExpiresAt, cottonNextExpiresAt) || other.cottonNextExpiresAt == cottonNextExpiresAt)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contractVersion,star,bonus,cotton,cottonExpiringAmount,cottonNextExpiresAt,snapshotAt);

@override
String toString() {
  return 'WalletSummaryModel(contractVersion: $contractVersion, star: $star, bonus: $bonus, cotton: $cotton, cottonExpiringAmount: $cottonExpiringAmount, cottonNextExpiresAt: $cottonNextExpiresAt, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class _$WalletSummaryModelCopyWith<$Res> implements $WalletSummaryModelCopyWith<$Res> {
  factory _$WalletSummaryModelCopyWith(_WalletSummaryModel value, $Res Function(_WalletSummaryModel) _then) = __$WalletSummaryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'contract_version') String contractVersion,@WalletAmountConverter() BigInt star,@WalletAmountConverter() BigInt bonus,@WalletAmountConverter() BigInt cotton,@JsonKey(name: 'cotton_expiring_amount')@WalletAmountConverter() BigInt cottonExpiringAmount,@JsonKey(name: 'cotton_next_expires_at') DateTime? cottonNextExpiresAt,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class __$WalletSummaryModelCopyWithImpl<$Res>
    implements _$WalletSummaryModelCopyWith<$Res> {
  __$WalletSummaryModelCopyWithImpl(this._self, this._then);

  final _WalletSummaryModel _self;
  final $Res Function(_WalletSummaryModel) _then;

/// Create a copy of WalletSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractVersion = null,Object? star = null,Object? bonus = null,Object? cotton = null,Object? cottonExpiringAmount = null,Object? cottonNextExpiresAt = freezed,Object? snapshotAt = null,}) {
  return _then(_WalletSummaryModel(
contractVersion: null == contractVersion ? _self.contractVersion : contractVersion // ignore: cast_nullable_to_non_nullable
as String,star: null == star ? _self.star : star // ignore: cast_nullable_to_non_nullable
as BigInt,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as BigInt,cotton: null == cotton ? _self.cotton : cotton // ignore: cast_nullable_to_non_nullable
as BigInt,cottonExpiringAmount: null == cottonExpiringAmount ? _self.cottonExpiringAmount : cottonExpiringAmount // ignore: cast_nullable_to_non_nullable
as BigInt,cottonNextExpiresAt: freezed == cottonNextExpiresAt ? _self.cottonNextExpiresAt : cottonNextExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
