// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/purchase_product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PurchaseProductList)
const purchaseProductListProvider = PurchaseProductListProvider._();

final class PurchaseProductListProvider
    extends $NotifierProvider<PurchaseProductList, List<PurchaseProduct>> {
  const PurchaseProductListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseProductListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseProductListHash();

  @$internal
  @override
  PurchaseProductList create() => PurchaseProductList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PurchaseProduct> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PurchaseProduct>>(value),
    );
  }
}

String _$purchaseProductListHash() =>
    r'a971062ff5b42a812d648989ed98a480fa708f89';

abstract class _$PurchaseProductList extends $Notifier<List<PurchaseProduct>> {
  List<PurchaseProduct> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<PurchaseProduct>, List<PurchaseProduct>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PurchaseProduct>, List<PurchaseProduct>>,
              List<PurchaseProduct>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
