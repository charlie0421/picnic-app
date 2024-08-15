// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_product.dart';

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
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get star_candy => throw _privateConstructorUsedError;
  int get bonus_star_candy => throw _privateConstructorUsedError;
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
      {String id,
      String title,
      double price,
      int star_candy,
      int bonus_star_candy,
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
    Object? star_candy = null,
    Object? bonus_star_candy = null,
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
      star_candy: null == star_candy
          ? _value.star_candy
          : star_candy // ignore: cast_nullable_to_non_nullable
              as int,
      bonus_star_candy: null == bonus_star_candy
          ? _value.bonus_star_candy
          : bonus_star_candy // ignore: cast_nullable_to_non_nullable
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
      {String id,
      String title,
      double price,
      int star_candy,
      int bonus_star_candy,
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
    Object? star_candy = null,
    Object? bonus_star_candy = null,
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
      star_candy: null == star_candy
          ? _value.star_candy
          : star_candy // ignore: cast_nullable_to_non_nullable
              as int,
      bonus_star_candy: null == bonus_star_candy
          ? _value.bonus_star_candy
          : bonus_star_candy // ignore: cast_nullable_to_non_nullable
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
      {required this.id,
      required this.title,
      required this.price,
      required this.star_candy,
      required this.bonus_star_candy,
      @ProductDetailsConverter() this.productDetails})
      : super._();

  factory _$PurchaseProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseProductImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final double price;
  @override
  final int star_candy;
  @override
  final int bonus_star_candy;
  @override
  @ProductDetailsConverter()
  final ProductDetails? productDetails;

  @override
  String toString() {
    return 'PurchaseProduct(id: $id, title: $title, price: $price, star_candy: $star_candy, bonus_star_candy: $bonus_star_candy, productDetails: $productDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.star_candy, star_candy) ||
                other.star_candy == star_candy) &&
            (identical(other.bonus_star_candy, bonus_star_candy) ||
                other.bonus_star_candy == bonus_star_candy) &&
            (identical(other.productDetails, productDetails) ||
                other.productDetails == productDetails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, price, star_candy,
      bonus_star_candy, productDetails);

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
          {required final String id,
          required final String title,
          required final double price,
          required final int star_candy,
          required final int bonus_star_candy,
          @ProductDetailsConverter() final ProductDetails? productDetails}) =
      _$PurchaseProductImpl;
  const _PurchaseProduct._() : super._();

  factory _PurchaseProduct.fromJson(Map<String, dynamic> json) =
      _$PurchaseProductImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  double get price;
  @override
  int get star_candy;
  @override
  int get bonus_star_candy;
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
