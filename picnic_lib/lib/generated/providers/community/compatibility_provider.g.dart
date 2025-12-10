// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/compatibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Compatibility)
const compatibilityProvider = CompatibilityProvider._();

final class CompatibilityProvider
    extends $NotifierProvider<Compatibility, AsyncValue<CompatibilityModel?>> {
  const CompatibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compatibilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compatibilityHash();

  @$internal
  @override
  Compatibility create() => Compatibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CompatibilityModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CompatibilityModel?>>(
        value,
      ),
    );
  }
}

String _$compatibilityHash() => r'9121b8d9db9e260b3894220491d297a1d70a3358';

abstract class _$Compatibility
    extends $Notifier<AsyncValue<CompatibilityModel?>> {
  AsyncValue<CompatibilityModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CompatibilityModel?>,
              AsyncValue<CompatibilityModel?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CompatibilityModel?>,
                AsyncValue<CompatibilityModel?>
              >,
              AsyncValue<CompatibilityModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
