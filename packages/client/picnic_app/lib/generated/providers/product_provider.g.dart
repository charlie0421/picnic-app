// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../providers/product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serverProductsHash() => r'16bcf29b3fac2d18adc57d32e7687363fd42a095';

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
String _$storeProductsHash() => r'1b8834d1509d3988bb7dc4387f7b68ed827da1cb';

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
