// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/purchase_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PurchaseProduct {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'title') String get title;@JsonKey(name: 'price') double get price;@JsonKey(name: 'star_candy') int get starCandy;@JsonKey(name: 'bonus_star_candy') int get bonusStarCandy;@ProductDetailsConverter() ProductDetails? get productDetails;
/// Create a copy of PurchaseProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseProductCopyWith<PurchaseProduct> get copyWith => _$PurchaseProductCopyWithImpl<PurchaseProduct>(this as PurchaseProduct, _$identity);

  /// Serializes this PurchaseProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy)&&(identical(other.bonusStarCandy, bonusStarCandy) || other.bonusStarCandy == bonusStarCandy)&&(identical(other.productDetails, productDetails) || other.productDetails == productDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,starCandy,bonusStarCandy,productDetails);

@override
String toString() {
  return 'PurchaseProduct(id: $id, title: $title, price: $price, starCandy: $starCandy, bonusStarCandy: $bonusStarCandy, productDetails: $productDetails)';
}


}

/// @nodoc
abstract mixin class $PurchaseProductCopyWith<$Res>  {
  factory $PurchaseProductCopyWith(PurchaseProduct value, $Res Function(PurchaseProduct) _then) = _$PurchaseProductCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'price') double price,@JsonKey(name: 'star_candy') int starCandy,@JsonKey(name: 'bonus_star_candy') int bonusStarCandy,@ProductDetailsConverter() ProductDetails? productDetails
});




}
/// @nodoc
class _$PurchaseProductCopyWithImpl<$Res>
    implements $PurchaseProductCopyWith<$Res> {
  _$PurchaseProductCopyWithImpl(this._self, this._then);

  final PurchaseProduct _self;
  final $Res Function(PurchaseProduct) _then;

/// Create a copy of PurchaseProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? price = null,Object? starCandy = null,Object? bonusStarCandy = null,Object? productDetails = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,starCandy: null == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as int,bonusStarCandy: null == bonusStarCandy ? _self.bonusStarCandy : bonusStarCandy // ignore: cast_nullable_to_non_nullable
as int,productDetails: freezed == productDetails ? _self.productDetails : productDetails // ignore: cast_nullable_to_non_nullable
as ProductDetails?,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseProduct].
extension PurchaseProductPatterns on PurchaseProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseProduct value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseProduct value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'price')  double price, @JsonKey(name: 'star_candy')  int starCandy, @JsonKey(name: 'bonus_star_candy')  int bonusStarCandy, @ProductDetailsConverter()  ProductDetails? productDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.starCandy,_that.bonusStarCandy,_that.productDetails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'price')  double price, @JsonKey(name: 'star_candy')  int starCandy, @JsonKey(name: 'bonus_star_candy')  int bonusStarCandy, @ProductDetailsConverter()  ProductDetails? productDetails)  $default,) {final _that = this;
switch (_that) {
case _PurchaseProduct():
return $default(_that.id,_that.title,_that.price,_that.starCandy,_that.bonusStarCandy,_that.productDetails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'price')  double price, @JsonKey(name: 'star_candy')  int starCandy, @JsonKey(name: 'bonus_star_candy')  int bonusStarCandy, @ProductDetailsConverter()  ProductDetails? productDetails)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.starCandy,_that.bonusStarCandy,_that.productDetails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseProduct extends PurchaseProduct {
  const _PurchaseProduct({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') required this.title, @JsonKey(name: 'price') required this.price, @JsonKey(name: 'star_candy') required this.starCandy, @JsonKey(name: 'bonus_star_candy') required this.bonusStarCandy, @ProductDetailsConverter() this.productDetails}): super._();
  factory _PurchaseProduct.fromJson(Map<String, dynamic> json) => _$PurchaseProductFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'title') final  String title;
@override@JsonKey(name: 'price') final  double price;
@override@JsonKey(name: 'star_candy') final  int starCandy;
@override@JsonKey(name: 'bonus_star_candy') final  int bonusStarCandy;
@override@ProductDetailsConverter() final  ProductDetails? productDetails;

/// Create a copy of PurchaseProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseProductCopyWith<_PurchaseProduct> get copyWith => __$PurchaseProductCopyWithImpl<_PurchaseProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.starCandy, starCandy) || other.starCandy == starCandy)&&(identical(other.bonusStarCandy, bonusStarCandy) || other.bonusStarCandy == bonusStarCandy)&&(identical(other.productDetails, productDetails) || other.productDetails == productDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,starCandy,bonusStarCandy,productDetails);

@override
String toString() {
  return 'PurchaseProduct(id: $id, title: $title, price: $price, starCandy: $starCandy, bonusStarCandy: $bonusStarCandy, productDetails: $productDetails)';
}


}

/// @nodoc
abstract mixin class _$PurchaseProductCopyWith<$Res> implements $PurchaseProductCopyWith<$Res> {
  factory _$PurchaseProductCopyWith(_PurchaseProduct value, $Res Function(_PurchaseProduct) _then) = __$PurchaseProductCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'price') double price,@JsonKey(name: 'star_candy') int starCandy,@JsonKey(name: 'bonus_star_candy') int bonusStarCandy,@ProductDetailsConverter() ProductDetails? productDetails
});




}
/// @nodoc
class __$PurchaseProductCopyWithImpl<$Res>
    implements _$PurchaseProductCopyWith<$Res> {
  __$PurchaseProductCopyWithImpl(this._self, this._then);

  final _PurchaseProduct _self;
  final $Res Function(_PurchaseProduct) _then;

/// Create a copy of PurchaseProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? price = null,Object? starCandy = null,Object? bonusStarCandy = null,Object? productDetails = freezed,}) {
  return _then(_PurchaseProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,starCandy: null == starCandy ? _self.starCandy : starCandy // ignore: cast_nullable_to_non_nullable
as int,bonusStarCandy: null == bonusStarCandy ? _self.bonusStarCandy : bonusStarCandy // ignore: cast_nullable_to_non_nullable
as int,productDetails: freezed == productDetails ? _self.productDetails : productDetails // ignore: cast_nullable_to_non_nullable
as ProductDetails?,
  ));
}


}

// dart format on
