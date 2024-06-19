// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchage_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchageProduct _$PurchageProductFromJson(Map<String, dynamic> json) {
  return _PurchageProduct.fromJson(json);
}

/// @nodoc
mixin _$PurchageProduct {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get star_candy => throw _privateConstructorUsedError;
  int get bonus_star_candy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchageProductCopyWith<PurchageProduct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchageProductCopyWith<$Res> {
  factory $PurchageProductCopyWith(
          PurchageProduct value, $Res Function(PurchageProduct) then) =
      _$PurchageProductCopyWithImpl<$Res, PurchageProduct>;
  @useResult
  $Res call(
      {int id,
      String title,
      double price,
      int star_candy,
      int bonus_star_candy});
}

/// @nodoc
class _$PurchageProductCopyWithImpl<$Res, $Val extends PurchageProduct>
    implements $PurchageProductCopyWith<$Res> {
  _$PurchageProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? price = null,
    Object? star_candy = null,
    Object? bonus_star_candy = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchageProductImplCopyWith<$Res>
    implements $PurchageProductCopyWith<$Res> {
  factory _$$PurchageProductImplCopyWith(_$PurchageProductImpl value,
          $Res Function(_$PurchageProductImpl) then) =
      __$$PurchageProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      double price,
      int star_candy,
      int bonus_star_candy});
}

/// @nodoc
class __$$PurchageProductImplCopyWithImpl<$Res>
    extends _$PurchageProductCopyWithImpl<$Res, _$PurchageProductImpl>
    implements _$$PurchageProductImplCopyWith<$Res> {
  __$$PurchageProductImplCopyWithImpl(
      _$PurchageProductImpl _value, $Res Function(_$PurchageProductImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? price = null,
    Object? star_candy = null,
    Object? bonus_star_candy = null,
  }) {
    return _then(_$PurchageProductImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchageProductImpl extends _PurchageProduct {
  const _$PurchageProductImpl(
      {required this.id,
      required this.title,
      required this.price,
      required this.star_candy,
      required this.bonus_star_candy})
      : super._();

  factory _$PurchageProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchageProductImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final double price;
  @override
  final int star_candy;
  @override
  final int bonus_star_candy;

  @override
  String toString() {
    return 'PurchageProduct(id: $id, title: $title, price: $price, star_candy: $star_candy, bonus_star_candy: $bonus_star_candy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchageProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.star_candy, star_candy) ||
                other.star_candy == star_candy) &&
            (identical(other.bonus_star_candy, bonus_star_candy) ||
                other.bonus_star_candy == bonus_star_candy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, price, star_candy, bonus_star_candy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchageProductImplCopyWith<_$PurchageProductImpl> get copyWith =>
      __$$PurchageProductImplCopyWithImpl<_$PurchageProductImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchageProductImplToJson(
      this,
    );
  }
}

abstract class _PurchageProduct extends PurchageProduct {
  const factory _PurchageProduct(
      {required final int id,
      required final String title,
      required final double price,
      required final int star_candy,
      required final int bonus_star_candy}) = _$PurchageProductImpl;
  const _PurchageProduct._() : super._();

  factory _PurchageProduct.fromJson(Map<String, dynamic> json) =
      _$PurchageProductImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  double get price;
  @override
  int get star_candy;
  @override
  int get bonus_star_candy;
  @override
  @JsonKey(ignore: true)
  _$$PurchageProductImplCopyWith<_$PurchageProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
