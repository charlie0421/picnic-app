// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_image_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncGalleryImageListHash() =>
    r'349d5c9c90f359adaa7fd7a3bbda74fe4a17c0d1';

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

abstract class _$AsyncGalleryImageList
    extends BuildlessAutoDisposeAsyncNotifier<GalleryImageListModel> {
  late final int galleryId;

  FutureOr<GalleryImageListModel> build({
    required int galleryId,
  });
}

/// See also [AsyncGalleryImageList].
@ProviderFor(AsyncGalleryImageList)
const asyncGalleryImageListProvider = AsyncGalleryImageListFamily();

/// See also [AsyncGalleryImageList].
class AsyncGalleryImageListFamily
    extends Family<AsyncValue<GalleryImageListModel>> {
  /// See also [AsyncGalleryImageList].
  const AsyncGalleryImageListFamily();

  /// See also [AsyncGalleryImageList].
  AsyncGalleryImageListProvider call({
    required int galleryId,
  }) {
    return AsyncGalleryImageListProvider(
      galleryId: galleryId,
    );
  }

  @override
  AsyncGalleryImageListProvider getProviderOverride(
    covariant AsyncGalleryImageListProvider provider,
  ) {
    return call(
      galleryId: provider.galleryId,
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
  String? get name => r'asyncGalleryImageListProvider';
}

/// See also [AsyncGalleryImageList].
class AsyncGalleryImageListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncGalleryImageList,
        GalleryImageListModel> {
  /// See also [AsyncGalleryImageList].
  AsyncGalleryImageListProvider({
    required int galleryId,
  }) : this._internal(
          () => AsyncGalleryImageList()..galleryId = galleryId,
          from: asyncGalleryImageListProvider,
          name: r'asyncGalleryImageListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncGalleryImageListHash,
          dependencies: AsyncGalleryImageListFamily._dependencies,
          allTransitiveDependencies:
              AsyncGalleryImageListFamily._allTransitiveDependencies,
          galleryId: galleryId,
        );

  AsyncGalleryImageListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.galleryId,
  }) : super.internal();

  final int galleryId;

  @override
  FutureOr<GalleryImageListModel> runNotifierBuild(
    covariant AsyncGalleryImageList notifier,
  ) {
    return notifier.build(
      galleryId: galleryId,
    );
  }

  @override
  Override overrideWith(AsyncGalleryImageList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncGalleryImageListProvider._internal(
        () => create()..galleryId = galleryId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        galleryId: galleryId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncGalleryImageList,
      GalleryImageListModel> createElement() {
    return _AsyncGalleryImageListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncGalleryImageListProvider &&
        other.galleryId == galleryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, galleryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncGalleryImageListRef
    on AutoDisposeAsyncNotifierProviderRef<GalleryImageListModel> {
  /// The parameter `galleryId` of this provider.
  int get galleryId;
}

class _AsyncGalleryImageListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncGalleryImageList,
        GalleryImageListModel> with AsyncGalleryImageListRef {
  _AsyncGalleryImageListProviderElement(super.provider);

  @override
  int get galleryId => (origin as AsyncGalleryImageListProvider).galleryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
