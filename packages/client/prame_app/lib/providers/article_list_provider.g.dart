// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncArticleListHash() => r'602f09842c41849ff85ea6af05df294b1c2c4233';

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

abstract class _$AsyncArticleList extends BuildlessAutoDisposeAsyncNotifier<
    PagingController<int, ArticleModel>> {
  late final dynamic galleyId;

  FutureOr<PagingController<int, ArticleModel>> build(
    dynamic galleyId,
  );
}

/// See also [AsyncArticleList].
@ProviderFor(AsyncArticleList)
const asyncArticleListProvider = AsyncArticleListFamily();

/// See also [AsyncArticleList].
class AsyncArticleListFamily
    extends Family<AsyncValue<PagingController<int, ArticleModel>>> {
  /// See also [AsyncArticleList].
  const AsyncArticleListFamily();

  /// See also [AsyncArticleList].
  AsyncArticleListProvider call(
    dynamic galleyId,
  ) {
    return AsyncArticleListProvider(
      galleyId,
    );
  }

  @override
  AsyncArticleListProvider getProviderOverride(
    covariant AsyncArticleListProvider provider,
  ) {
    return call(
      provider.galleyId,
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
  String? get name => r'asyncArticleListProvider';
}

/// See also [AsyncArticleList].
class AsyncArticleListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncArticleList, PagingController<int, ArticleModel>> {
  /// See also [AsyncArticleList].
  AsyncArticleListProvider(
    dynamic galleyId,
  ) : this._internal(
          () => AsyncArticleList()..galleyId = galleyId,
          from: asyncArticleListProvider,
          name: r'asyncArticleListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncArticleListHash,
          dependencies: AsyncArticleListFamily._dependencies,
          allTransitiveDependencies:
              AsyncArticleListFamily._allTransitiveDependencies,
          galleyId: galleyId,
        );

  AsyncArticleListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.galleyId,
  }) : super.internal();

  final dynamic galleyId;

  @override
  FutureOr<PagingController<int, ArticleModel>> runNotifierBuild(
    covariant AsyncArticleList notifier,
  ) {
    return notifier.build(
      galleyId,
    );
  }

  @override
  Override overrideWith(AsyncArticleList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncArticleListProvider._internal(
        () => create()..galleyId = galleyId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        galleyId: galleyId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncArticleList,
      PagingController<int, ArticleModel>> createElement() {
    return _AsyncArticleListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncArticleListProvider && other.galleyId == galleyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, galleyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncArticleListRef on AutoDisposeAsyncNotifierProviderRef<
    PagingController<int, ArticleModel>> {
  /// The parameter `galleyId` of this provider.
  dynamic get galleyId;
}

class _AsyncArticleListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncArticleList,
        PagingController<int, ArticleModel>> with AsyncArticleListRef {
  _AsyncArticleListProviderElement(super.provider);

  @override
  dynamic get galleyId => (origin as AsyncArticleListProvider).galleyId;
}

String _$sortOptionHash() => r'84f57d3c7e068d752206dff682cf60e67c1d6767';

/// See also [SortOption].
@ProviderFor(SortOption)
final sortOptionProvider =
    AutoDisposeNotifierProvider<SortOption, SortOptionType>.internal(
  SortOption.new,
  name: r'sortOptionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sortOptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SortOption = AutoDisposeNotifier<SortOptionType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
