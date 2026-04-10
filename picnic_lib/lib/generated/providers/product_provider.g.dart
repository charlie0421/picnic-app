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

String _$serverProductsHash() => r'61d31a3cceffe19792cf12e92e975cac54dd7cef';

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

String _$storeProductsHash() => r'bcce69d89b463dd232b73092dd900459cca69664';

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
