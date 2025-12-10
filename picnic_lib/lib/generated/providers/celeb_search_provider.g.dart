// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/celeb_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncCelebSearch)
const asyncCelebSearchProvider = AsyncCelebSearchProvider._();

final class AsyncCelebSearchProvider
    extends $AsyncNotifierProvider<AsyncCelebSearch, List<CelebModel>?> {
  const AsyncCelebSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncCelebSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncCelebSearchHash();

  @$internal
  @override
  AsyncCelebSearch create() => AsyncCelebSearch();
}

String _$asyncCelebSearchHash() => r'aec1963ccd57f29a914fc4003ab08bdcb28c730c';

abstract class _$AsyncCelebSearch extends $AsyncNotifier<List<CelebModel>?> {
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
