// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerProducts)
const serverProductsProvider = ServerProductsProvider._();

final class ServerProductsProvider
    extends $AsyncNotifierProvider<ServerProducts, List<Map<String, dynamic>>> {
  const ServerProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverProductsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverProductsHash();

  @$internal
  @override
  ServerProducts create() => ServerProducts();
}

String _$serverProductsHash() => r'0f4c60d3e8e126228ce91d2bee4a67dedbee35fe';

abstract class _$ServerProducts
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(StoreProducts)
const storeProductsProvider = StoreProductsProvider._();

final class StoreProductsProvider
    extends $AsyncNotifierProvider<StoreProducts, List<ProductDetails>> {
  const StoreProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeProductsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeProductsHash();

  @$internal
  @override
  StoreProducts create() => StoreProducts();
}

String _$storeProductsHash() => r'd92e89e57a4e73bc191e3e9536cf6d79685f8ca4';

abstract class _$StoreProducts extends $AsyncNotifier<List<ProductDetails>> {
  FutureOr<List<ProductDetails>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ProductDetails>>, List<ProductDetails>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ProductDetails>>,
                List<ProductDetails>
              >,
              AsyncValue<List<ProductDetails>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
