// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_image_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncArticleImageListHash() =>
    r'18d1e0979f591a5bcaf2d791cf172fc981492a7e';

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

abstract class _$AsyncArticleImageList
    extends BuildlessAutoDisposeAsyncNotifier<ArticleImageListModel> {
  late final int galleryId;

  FutureOr<ArticleImageListModel> build({
    required int galleryId,
  });
}

/// See also [AsyncArticleImageList].
@ProviderFor(AsyncArticleImageList)
const asyncArticleImageListProvider = AsyncArticleImageListFamily();

/// See also [AsyncArticleImageList].
class AsyncArticleImageListFamily
    extends Family<AsyncValue<ArticleImageListModel>> {
  /// See also [AsyncArticleImageList].
  const AsyncArticleImageListFamily();

  /// See also [AsyncArticleImageList].
  AsyncArticleImageListProvider call({
    required int galleryId,
  }) {
    return AsyncArticleImageListProvider(
      galleryId: galleryId,
    );
  }

  @override
  AsyncArticleImageListProvider getProviderOverride(
    covariant AsyncArticleImageListProvider provider,
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
  String? get name => r'asyncArticleImageListProvider';
}

/// See also [AsyncArticleImageList].
class AsyncArticleImageListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncArticleImageList,
        ArticleImageListModel> {
  /// See also [AsyncArticleImageList].
  AsyncArticleImageListProvider({
    required int galleryId,
  }) : this._internal(
          () => AsyncArticleImageList()..galleryId = galleryId,
          from: asyncArticleImageListProvider,
          name: r'asyncArticleImageListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncArticleImageListHash,
          dependencies: AsyncArticleImageListFamily._dependencies,
          allTransitiveDependencies:
              AsyncArticleImageListFamily._allTransitiveDependencies,
          galleryId: galleryId,
        );

  AsyncArticleImageListProvider._internal(
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
  FutureOr<ArticleImageListModel> runNotifierBuild(
    covariant AsyncArticleImageList notifier,
  ) {
    return notifier.build(
      galleryId: galleryId,
    );
  }

  @override
  Override overrideWith(AsyncArticleImageList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncArticleImageListProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<AsyncArticleImageList,
      ArticleImageListModel> createElement() {
    return _AsyncArticleImageListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncArticleImageListProvider &&
        other.galleryId == galleryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, galleryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncArticleImageListRef
    on AutoDisposeAsyncNotifierProviderRef<ArticleImageListModel> {
  /// The parameter `galleryId` of this provider.
  int get galleryId;
}

class _AsyncArticleImageListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncArticleImageList,
        ArticleImageListModel> with AsyncArticleImageListRef {
  _AsyncArticleImageListProviderElement(super.provider);

  @override
  int get galleryId => (origin as AsyncArticleImageListProvider).galleryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
