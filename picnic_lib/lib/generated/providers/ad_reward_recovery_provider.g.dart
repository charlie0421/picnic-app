// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/ad_reward_recovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adRewardDelay)
const adRewardDelayProvider = AdRewardDelayProvider._();

final class AdRewardDelayProvider
    extends $FunctionalProvider<AdRewardDelay, AdRewardDelay, AdRewardDelay>
    with $Provider<AdRewardDelay> {
  const AdRewardDelayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adRewardDelayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adRewardDelayHash();

  @$internal
  @override
  $ProviderElement<AdRewardDelay> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdRewardDelay create(Ref ref) {
    return adRewardDelay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdRewardDelay value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdRewardDelay>(value),
    );
  }
}

String _$adRewardDelayHash() => r'f7851c620af0c9196580a28c2d49c9fe2418efc1';

@ProviderFor(adRewardOwnerReader)
const adRewardOwnerReaderProvider = AdRewardOwnerReaderProvider._();

final class AdRewardOwnerReaderProvider
    extends
        $FunctionalProvider<
          AdRewardOwnerReader,
          AdRewardOwnerReader,
          AdRewardOwnerReader
        >
    with $Provider<AdRewardOwnerReader> {
  const AdRewardOwnerReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adRewardOwnerReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adRewardOwnerReaderHash();

  @$internal
  @override
  $ProviderElement<AdRewardOwnerReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdRewardOwnerReader create(Ref ref) {
    return adRewardOwnerReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdRewardOwnerReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdRewardOwnerReader>(value),
    );
  }
}

String _$adRewardOwnerReaderHash() =>
    r'2466c2bb7dcbd1706a7d436205bb6da28043193a';

@ProviderFor(AdRewardRecovery)
const adRewardRecoveryProvider = AdRewardRecoveryProvider._();

final class AdRewardRecoveryProvider
    extends $NotifierProvider<AdRewardRecovery, AdRewardRecoveryState> {
  const AdRewardRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adRewardRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adRewardRecoveryHash();

  @$internal
  @override
  AdRewardRecovery create() => AdRewardRecovery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdRewardRecoveryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdRewardRecoveryState>(value),
    );
  }
}

String _$adRewardRecoveryHash() => r'7ff1aaa93b1e7e5c702e1234aea5b38b4b8d088f';

abstract class _$AdRewardRecovery extends $Notifier<AdRewardRecoveryState> {
  AdRewardRecoveryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AdRewardRecoveryState, AdRewardRecoveryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdRewardRecoveryState, AdRewardRecoveryState>,
              AdRewardRecoveryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
