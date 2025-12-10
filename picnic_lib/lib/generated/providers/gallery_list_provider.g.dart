// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/gallery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncGalleryList)
const asyncGalleryListProvider = AsyncGalleryListProvider._();

final class AsyncGalleryListProvider
    extends $AsyncNotifierProvider<AsyncGalleryList, List<GalleryModel>> {
  const AsyncGalleryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncGalleryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncGalleryListHash();

  @$internal
  @override
  AsyncGalleryList create() => AsyncGalleryList();
}

String _$asyncGalleryListHash() => r'fcf8a83c0433cd5d535b625b543f3f8b643c9d4b';

abstract class _$AsyncGalleryList extends $AsyncNotifier<List<GalleryModel>> {
  FutureOr<List<GalleryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<GalleryModel>>, List<GalleryModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GalleryModel>>, List<GalleryModel>>,
              AsyncValue<List<GalleryModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedGalleryId)
const selectedGalleryIdProvider = SelectedGalleryIdProvider._();

final class SelectedGalleryIdProvider
    extends $NotifierProvider<SelectedGalleryId, int> {
  const SelectedGalleryIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGalleryIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGalleryIdHash();

  @$internal
  @override
  SelectedGalleryId create() => SelectedGalleryId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedGalleryIdHash() => r'f9c59fefd740c43c42e7777b3634ca015bfb2573';

abstract class _$SelectedGalleryId extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AsyncCelebGalleryList)
const asyncCelebGalleryListProvider = AsyncCelebGalleryListFamily._();

final class AsyncCelebGalleryListProvider
    extends $AsyncNotifierProvider<AsyncCelebGalleryList, List<GalleryModel>> {
  const AsyncCelebGalleryListProvider._({
    required AsyncCelebGalleryListFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'asyncCelebGalleryListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncCelebGalleryListHash();

  @override
  String toString() {
    return r'asyncCelebGalleryListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AsyncCelebGalleryList create() => AsyncCelebGalleryList();

  @override
  bool operator ==(Object other) {
    return other is AsyncCelebGalleryListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncCelebGalleryListHash() =>
    r'5ceae2fcade1280cb3a9981420beb0dab33fcd63';

final class AsyncCelebGalleryListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncCelebGalleryList,
          AsyncValue<List<GalleryModel>>,
          List<GalleryModel>,
          FutureOr<List<GalleryModel>>,
          int
        > {
  const AsyncCelebGalleryListFamily._()
    : super(
        retry: null,
        name: r'asyncCelebGalleryListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncCelebGalleryListProvider call(int celebId) =>
      AsyncCelebGalleryListProvider._(argument: celebId, from: this);

  @override
  String toString() => r'asyncCelebGalleryListProvider';
}

abstract class _$AsyncCelebGalleryList
    extends $AsyncNotifier<List<GalleryModel>> {
  late final _$args = ref.$arg as int;
  int get celebId => _$args;

  FutureOr<List<GalleryModel>> build(int celebId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<GalleryModel>>, List<GalleryModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GalleryModel>>, List<GalleryModel>>,
              AsyncValue<List<GalleryModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
