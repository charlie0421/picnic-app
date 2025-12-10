// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/celeb_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncCelebList)
const asyncCelebListProvider = AsyncCelebListProvider._();

final class AsyncCelebListProvider
    extends $AsyncNotifierProvider<AsyncCelebList, List<CelebModel>?> {
  const AsyncCelebListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncCelebListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncCelebListHash();

  @$internal
  @override
  AsyncCelebList create() => AsyncCelebList();
}

String _$asyncCelebListHash() => r'333e25f7b5309d5b363d27379691467f7b598d23';

abstract class _$AsyncCelebList extends $AsyncNotifier<List<CelebModel>?> {
  FutureOr<List<CelebModel>?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<CelebModel>?>, List<CelebModel>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CelebModel>?>, List<CelebModel>?>,
              AsyncValue<List<CelebModel>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AsyncMyCelebList)
const asyncMyCelebListProvider = AsyncMyCelebListProvider._();

final class AsyncMyCelebListProvider
    extends $AsyncNotifierProvider<AsyncMyCelebList, List<CelebModel>?> {
  const AsyncMyCelebListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncMyCelebListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncMyCelebListHash();

  @$internal
  @override
  AsyncMyCelebList create() => AsyncMyCelebList();
}

String _$asyncMyCelebListHash() => r'd3e28b9a1676105913900557550e8bd06c8f173c';

abstract class _$AsyncMyCelebList extends $AsyncNotifier<List<CelebModel>?> {
  FutureOr<List<CelebModel>?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<CelebModel>?>, List<CelebModel>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CelebModel>?>, List<CelebModel>?>,
              AsyncValue<List<CelebModel>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedCeleb)
const selectedCelebProvider = SelectedCelebProvider._();

final class SelectedCelebProvider
    extends $NotifierProvider<SelectedCeleb, CelebModel?> {
  const SelectedCelebProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCelebProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCelebHash();

  @$internal
  @override
  SelectedCeleb create() => SelectedCeleb();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CelebModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CelebModel?>(value),
    );
  }
}

String _$selectedCelebHash() => r'de544f79c7d80643ac5feb419ca90c23afd6bf78';

abstract class _$SelectedCeleb extends $Notifier<CelebModel?> {
  CelebModel? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CelebModel?, CelebModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CelebModel?, CelebModel?>,
              CelebModel?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
