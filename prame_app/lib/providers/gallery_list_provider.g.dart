// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncGalleryListHash() => r'10cff53bb93afff3ddc0be1c7f9c312036da9ee2';

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

abstract class _$AsyncGalleryList
    extends BuildlessAutoDisposeAsyncNotifier<GalleryListModel> {
  late final int celebId;

  FutureOr<GalleryListModel> build({
    required int celebId,
  });
}

/// See also [AsyncGalleryList].
@ProviderFor(AsyncGalleryList)
const asyncGalleryListProvider = AsyncGalleryListFamily();

/// See also [AsyncGalleryList].
class AsyncGalleryListFamily extends Family<AsyncValue<GalleryListModel>> {
  /// See also [AsyncGalleryList].
  const AsyncGalleryListFamily();

  /// See also [AsyncGalleryList].
  AsyncGalleryListProvider call({
    required int celebId,
  }) {
    return AsyncGalleryListProvider(
      celebId: celebId,
    );
  }

  @override
  AsyncGalleryListProvider getProviderOverride(
    covariant AsyncGalleryListProvider provider,
  ) {
    return call(
      celebId: provider.celebId,
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
  String? get name => r'asyncGalleryListProvider';
}

/// See also [AsyncGalleryList].
class AsyncGalleryListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncGalleryList, GalleryListModel> {
  /// See also [AsyncGalleryList].
  AsyncGalleryListProvider({
    required int celebId,
  }) : this._internal(
          () => AsyncGalleryList()..celebId = celebId,
          from: asyncGalleryListProvider,
          name: r'asyncGalleryListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncGalleryListHash,
          dependencies: AsyncGalleryListFamily._dependencies,
          allTransitiveDependencies:
              AsyncGalleryListFamily._allTransitiveDependencies,
          celebId: celebId,
        );

  AsyncGalleryListProvider._internal(
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
  FutureOr<GalleryListModel> runNotifierBuild(
    covariant AsyncGalleryList notifier,
  ) {
    return notifier.build(
      celebId: celebId,
    );
  }

  @override
  Override overrideWith(AsyncGalleryList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncGalleryListProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<AsyncGalleryList, GalleryListModel>
      createElement() {
    return _AsyncGalleryListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncGalleryListProvider && other.celebId == celebId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, celebId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncGalleryListRef
    on AutoDisposeAsyncNotifierProviderRef<GalleryListModel> {
  /// The parameter `celebId` of this provider.
  int get celebId;
}

class _AsyncGalleryListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncGalleryList,
        GalleryListModel> with AsyncGalleryListRef {
  _AsyncGalleryListProviderElement(super.provider);

  @override
  int get celebId => (origin as AsyncGalleryListProvider).celebId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
