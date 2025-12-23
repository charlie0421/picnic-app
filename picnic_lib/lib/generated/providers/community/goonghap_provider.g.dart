// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/goonghap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Goonghap)
const goonghapProvider = GoonghapProvider._();

final class GoonghapProvider
    extends $NotifierProvider<Goonghap, AsyncValue<GoonghapModel?>> {
  const GoonghapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goonghapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goonghapHash();

  @$internal
  @override
  Goonghap create() => Goonghap();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<GoonghapModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<GoonghapModel?>>(value),
    );
  }
}

String _$goonghapHash() => r'04c98177d1aa11c2c6a185813803742e540bd51e';

abstract class _$Goonghap extends $Notifier<AsyncValue<GoonghapModel?>> {
  AsyncValue<GoonghapModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<GoonghapModel?>, AsyncValue<GoonghapModel?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<GoonghapModel?>,
                AsyncValue<GoonghapModel?>
              >,
              AsyncValue<GoonghapModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
