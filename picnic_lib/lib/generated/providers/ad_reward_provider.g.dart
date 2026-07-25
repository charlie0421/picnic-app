// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/ad_reward_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adRewardRepository)
const adRewardRepositoryProvider = AdRewardRepositoryProvider._();

final class AdRewardRepositoryProvider
    extends $FunctionalProvider<AdRewardApi, AdRewardApi, AdRewardApi>
    with $Provider<AdRewardApi> {
  const AdRewardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adRewardRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adRewardRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdRewardApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdRewardApi create(Ref ref) {
    return adRewardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdRewardApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdRewardApi>(value),
    );
  }
}

String _$adRewardRepositoryHash() =>
    r'3111b5e7e72e235c7eb16de8645b9ee4f982ef0b';

@ProviderFor(pendingAdRewardStore)
const pendingAdRewardStoreProvider = PendingAdRewardStoreProvider._();

final class PendingAdRewardStoreProvider
    extends
        $FunctionalProvider<
          PendingAdRewardStore,
          PendingAdRewardStore,
          PendingAdRewardStore
        >
    with $Provider<PendingAdRewardStore> {
  const PendingAdRewardStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingAdRewardStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingAdRewardStoreHash();

  @$internal
  @override
  $ProviderElement<PendingAdRewardStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingAdRewardStore create(Ref ref) {
    return pendingAdRewardStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingAdRewardStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingAdRewardStore>(value),
    );
  }
}

String _$pendingAdRewardStoreHash() =>
    r'cf739a946c570e11457988e050a8553efd8b6708';
