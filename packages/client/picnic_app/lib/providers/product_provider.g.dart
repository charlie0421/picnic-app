// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serverProductsHash() => r'54663d984d2b2592d06581a82e9b24133ae7d7b5';

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
String _$storeProductsHash() => r'6f2cd478749c17ebd5bb639a787234fb4024b46a';

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
