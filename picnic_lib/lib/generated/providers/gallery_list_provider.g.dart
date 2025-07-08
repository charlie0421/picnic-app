// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/gallery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncGalleryListHash() => r'fcf8a83c0433cd5d535b625b543f3f8b643c9d4b';

/// See also [AsyncGalleryList].
@ProviderFor(AsyncGalleryList)
final asyncGalleryListProvider = AutoDisposeAsyncNotifierProvider<
    AsyncGalleryList, List<GalleryModel>>.internal(
  AsyncGalleryList.new,
  name: r'asyncGalleryListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncGalleryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncGalleryList = AutoDisposeAsyncNotifier<List<GalleryModel>>;
String _$selectedGalleryIdHash() => r'f9c59fefd740c43c42e7777b3634ca015bfb2573';

/// See also [SelectedGalleryId].
@ProviderFor(SelectedGalleryId)
final selectedGalleryIdProvider =
    AutoDisposeNotifierProvider<SelectedGalleryId, int>.internal(
  SelectedGalleryId.new,
  name: r'selectedGalleryIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGalleryIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGalleryId = AutoDisposeNotifier<int>;
String _$asyncCelebGalleryListHash() =>
    r'5ceae2fcade1280cb3a9981420beb0dab33fcd63';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AsyncCelebGalleryList
    extends BuildlessAutoDisposeAsyncNotifier<List<GalleryModel>> {
  late final int celebId;

  FutureOr<List<GalleryModel>> build(
    int celebId,
  );
}

/// See also [AsyncCelebGalleryList].
@ProviderFor(AsyncCelebGalleryList)
const asyncCelebGalleryListProvider = AsyncCelebGalleryListFamily();

/// See also [AsyncCelebGalleryList].
class AsyncCelebGalleryListFamily
    extends Family<AsyncValue<List<GalleryModel>>> {
  /// See also [AsyncCelebGalleryList].
  const AsyncCelebGalleryListFamily();

  /// See also [AsyncCelebGalleryList].
  AsyncCelebGalleryListProvider call(
    int celebId,
  ) {
    return AsyncCelebGalleryListProvider(
      celebId,
    );
  }

  @override
  AsyncCelebGalleryListProvider getProviderOverride(
    covariant AsyncCelebGalleryListProvider provider,
  ) {
    return call(
      provider.celebId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'asyncCelebGalleryListProvider';
}

/// See also [AsyncCelebGalleryList].
class AsyncCelebGalleryListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncCelebGalleryList,
        List<GalleryModel>> {
  /// See also [AsyncCelebGalleryList].
  AsyncCelebGalleryListProvider(
    int celebId,
  ) : this._internal(
          () => AsyncCelebGalleryList()..celebId = celebId,
          from: asyncCelebGalleryListProvider,
          name: r'asyncCelebGalleryListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncCelebGalleryListHash,
          dependencies: AsyncCelebGalleryListFamily._dependencies,
          allTransitiveDependencies:
              AsyncCelebGalleryListFamily._allTransitiveDependencies,
          celebId: celebId,
        );

  AsyncCelebGalleryListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.celebId,
  }) : super.internal();

  final int celebId;

  @override
  FutureOr<List<GalleryModel>> runNotifierBuild(
    covariant AsyncCelebGalleryList notifier,
  ) {
    return notifier.build(
      celebId,
    );
  }

  @override
  Override overrideWith(AsyncCelebGalleryList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncCelebGalleryListProvider._internal(
        () => create()..celebId = celebId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        celebId: celebId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncCelebGalleryList,
      List<GalleryModel>> createElement() {
    return _AsyncCelebGalleryListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncCelebGalleryListProvider && other.celebId == celebId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, celebId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AsyncCelebGalleryListRef
    on AutoDisposeAsyncNotifierProviderRef<List<GalleryModel>> {
  /// The parameter `celebId` of this provider.
  int get celebId;
}

class _AsyncCelebGalleryListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncCelebGalleryList,
        List<GalleryModel>> with AsyncCelebGalleryListRef {
  _AsyncCelebGalleryListProviderElement(super.provider);

  @override
  int get celebId => (origin as AsyncCelebGalleryListProvider).celebId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
