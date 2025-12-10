// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/library_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncLibraryList)
const asyncLibraryListProvider = AsyncLibraryListProvider._();

final class AsyncLibraryListProvider
    extends $AsyncNotifierProvider<AsyncLibraryList, List<LibraryModel>?> {
  const AsyncLibraryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncLibraryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncLibraryListHash();

  @$internal
  @override
  AsyncLibraryList create() => AsyncLibraryList();
}

String _$asyncLibraryListHash() => r'5501bb3a9e0c19dd29b34eea22490f1fb20e24cd';

abstract class _$AsyncLibraryList extends $AsyncNotifier<List<LibraryModel>?> {
  FutureOr<List<LibraryModel>?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<LibraryModel>?>, List<LibraryModel>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LibraryModel>?>, List<LibraryModel>?>,
              AsyncValue<List<LibraryModel>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
