// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serverProductsHash() => r'8d41c76eb3f610dce9894fd72a838e6b5ea9d070';

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
String _$storeProductsHash() => r'f7bb22aecffb450707ce55a0bd7fb14adb0fd14d';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
