// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/vote/purchase_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchaseProduct _$PurchaseProductFromJson(Map<String, dynamic> json) {
  return _PurchaseProduct.fromJson(json);
}

/// @nodoc
mixin _$PurchaseProduct {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'price')
  double get price => throw _privateConstructorUsedError;
  @JsonKey(name: 'star_candy')
  int get starCandy => throw _privateConstructorUsedError;
  @JsonKey(name: 'bonus_star_candy')
  int get bonusStarCandy => throw _privateConstructorUsedError;
  @ProductDetailsConverter()
  ProductDetails? get productDetails => throw _privateConstructorUsedError;

  /// Serializes this PurchaseProduct to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseProductCopyWith<PurchaseProduct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseProductCopyWith<$Res> {
  factory $PurchaseProductCopyWith(
          PurchaseProduct value, $Res Function(PurchaseProduct) then) =
      _$PurchaseProductCopyWithImpl<$Res, PurchaseProduct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'title') String title,
      @JsonKey(name: 'price') double price,
      @JsonKey(name: 'star_candy') int starCandy,
      @JsonKey(name: 'bonus_star_candy') int bonusStarCandy,
      @ProductDetailsConverter() ProductDetails? productDetails});
}

/// @nodoc
class _$PurchaseProductCopyWithImpl<$Res, $Val extends PurchaseProduct>
    implements $PurchaseProductCopyWith<$Res> {
  _$PurchaseProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? price = null,
    Object? starCandy = null,
    Object? bonusStarCandy = null,
    Object? productDetails = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      starCandy: null == starCandy
          ? _value.starCandy
          : starCandy // ignore: cast_nullable_to_non_nullable
              as int,
      bonusStarCandy: null == bonusStarCandy
          ? _value.bonusStarCandy
          : bonusStarCandy // ignore: cast_nullable_to_non_nullable
              as int,
      productDetails: freezed == productDetails
          ? _value.productDetails
          : productDetails // ignore: cast_nullable_to_non_nullable
              as ProductDetails?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseProductImplCopyWith<$Res>
    implements $PurchaseProductCopyWith<$Res> {
  factory _$$PurchaseProductImplCopyWith(_$PurchaseProductImpl value,
          $Res Function(_$PurchaseProductImpl) then) =
      __$$PurchaseProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'title') String title,
      @JsonKey(name: 'price') double price,
      @JsonKey(name: 'star_candy') int starCandy,
      @JsonKey(name: 'bonus_star_candy') int bonusStarCandy,
      @ProductDetailsConverter() ProductDetails? productDetails});
}

/// @nodoc
class __$$PurchaseProductImplCopyWithImpl<$Res>
    extends _$PurchaseProductCopyWithImpl<$Res, _$PurchaseProductImpl>
    implements _$$PurchaseProductImplCopyWith<$Res> {
  __$$PurchaseProductImplCopyWithImpl(
      _$PurchaseProductImpl _value, $Res Function(_$PurchaseProductImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? price = null,
    Object? starCandy = null,
    Object? bonusStarCandy = null,
    Object? productDetails = freezed,
  }) {
    return _then(_$PurchaseProductImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      starCandy: null == starCandy
          ? _value.starCandy
          : starCandy // ignore: cast_nullable_to_non_nullable
              as int,
      bonusStarCandy: null == bonusStarCandy
          ? _value.bonusStarCandy
          : bonusStarCandy // ignore: cast_nullable_to_non_nullable
              as int,
      productDetails: freezed == productDetails
          ? _value.productDetails
          : productDetails // ignore: cast_nullable_to_non_nullable
              as ProductDetails?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseProductImpl extends _PurchaseProduct {
  const _$PurchaseProductImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title') required this.title,
      @JsonKey(name: 'price') required this.price,
      @JsonKey(name: 'star_candy') required this.starCandy,
      @JsonKey(name: 'bonus_star_candy') required this.bonusStarCandy,
      @ProductDetailsConverter() this.productDetails})
      : super._();

  factory _$PurchaseProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseProductImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'title')
  final String title;
  @override
  @JsonKey(name: 'price')
  final double price;
  @override
  @JsonKey(name: 'star_candy')
  final int starCandy;
  @override
  @JsonKey(name: 'bonus_star_candy')
  final int bonusStarCandy;
  @override
  @ProductDetailsConverter()
  final ProductDetails? productDetails;

  @override
  String toString() {
    return 'PurchaseProduct(id: $id, title: $title, price: $price, starCandy: $starCandy, bonusStarCandy: $bonusStarCandy, productDetails: $productDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.starCandy, starCandy) ||
                other.starCandy == starCandy) &&
            (identical(other.bonusStarCandy, bonusStarCandy) ||
                other.bonusStarCandy == bonusStarCandy) &&
            (identical(other.productDetails, productDetails) ||
                other.productDetails == productDetails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, price, starCandy, bonusStarCandy, productDetails);

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseProductImplCopyWith<_$PurchaseProductImpl> get copyWith =>
      __$$PurchaseProductImplCopyWithImpl<_$PurchaseProductImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseProductImplToJson(
      this,
    );
  }
}

abstract class _PurchaseProduct extends PurchaseProduct {
  const factory _PurchaseProduct(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'title') required final String title,
          @JsonKey(name: 'price') required final double price,
          @JsonKey(name: 'star_candy') required final int starCandy,
          @JsonKey(name: 'bonus_star_candy') required final int bonusStarCandy,
          @ProductDetailsConverter() final ProductDetails? productDetails}) =
      _$PurchaseProductImpl;
  const _PurchaseProduct._() : super._();

  factory _PurchaseProduct.fromJson(Map<String, dynamic> json) =
      _$PurchaseProductImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'title')
  String get title;
  @override
  @JsonKey(name: 'price')
  double get price;
  @override
  @JsonKey(name: 'star_candy')
  int get starCandy;
  @override
  @JsonKey(name: 'bonus_star_candy')
  int get bonusStarCandy;
  @override
  @ProductDetailsConverter()
  ProductDetails? get productDetails;

  /// Create a copy of PurchaseProduct
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseProductImplCopyWith<_$PurchaseProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
