// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncArticleListHash() => r'6d50c131ca4a0c0b38017943c365fc5de807c0f8';

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

String _$sortOptionHash() => r'8d0e51b1242be85e0437cebf8d5053fbce6dd7fe';

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
String _$commentCountHash() => r'1521c9af9aeb5ffa1bd95002f50392867e7179fc';

abstract class _$CommentCount extends BuildlessAutoDisposeAsyncNotifier<int> {
  late final int articleId;

  FutureOr<int> build(
    int articleId,
  );
}

/// See also [CommentCount].
@ProviderFor(CommentCount)
const commentCountProvider = CommentCountFamily();

/// See also [CommentCount].
class CommentCountFamily extends Family<AsyncValue<int>> {
  /// See also [CommentCount].
  const CommentCountFamily();

  /// See also [CommentCount].
  CommentCountProvider call(
    int articleId,
  ) {
    return CommentCountProvider(
      articleId,
    );
  }

  @override
  CommentCountProvider getProviderOverride(
    covariant CommentCountProvider provider,
  ) {
    return call(
      provider.articleId,
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
  String? get name => r'commentCountProvider';
}

/// See also [CommentCount].
class CommentCountProvider
    extends AutoDisposeAsyncNotifierProviderImpl<CommentCount, int> {
  /// See also [CommentCount].
  CommentCountProvider(
    int articleId,
  ) : this._internal(
          () => CommentCount()..articleId = articleId,
          from: commentCountProvider,
          name: r'commentCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentCountHash,
          dependencies: CommentCountFamily._dependencies,
          allTransitiveDependencies:
              CommentCountFamily._allTransitiveDependencies,
          articleId: articleId,
        );

  CommentCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.articleId,
  }) : super.internal();

  final int articleId;

  @override
  FutureOr<int> runNotifierBuild(
    covariant CommentCount notifier,
  ) {
    return notifier.build(
      articleId,
    );
  }

  @override
  Override overrideWith(CommentCount Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentCountProvider._internal(
        () => create()..articleId = articleId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        articleId: articleId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CommentCount, int> createElement() {
    return _CommentCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentCountProvider && other.articleId == articleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, articleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommentCountRef on AutoDisposeAsyncNotifierProviderRef<int> {
  /// The parameter `articleId` of this provider.
  int get articleId;
}

class _CommentCountProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CommentCount, int>
    with CommentCountRef {
  _CommentCountProviderElement(super.provider);

  @override
  int get articleId => (origin as CommentCountProvider).articleId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
