// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serverProductsHash() => r'0f4c60d3e8e126228ce91d2bee4a67dedbee35fe';

/// See also [ServerProducts].
@ProviderFor(ServerProducts)
final serverProductsProvider =
    AsyncNotifierProvider<ServerProducts, List<Map<String, dynamic>>>.internal(
  ServerProducts.new,
  name: r'serverProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$serverProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ServerProducts = AsyncNotifier<List<Map<String, dynamic>>>;
String _$storeProductsHash() => r'd92e89e57a4e73bc191e3e9536cf6d79685f8ca4';

/// See also [StoreProducts].
@ProviderFor(StoreProducts)
final storeProductsProvider =
    AsyncNotifierProvider<StoreProducts, List<ProductDetails>>.internal(
  StoreProducts.new,
  name: r'storeProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storeProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StoreProducts = AsyncNotifier<List<ProductDetails>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
