// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchArticleListHash() => r'515ad2ff332335fb143d1486c092900fff1bdaf2';

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

/// See also [fetchArticleList].
@ProviderFor(fetchArticleList)
const fetchArticleListProvider = FetchArticleListFamily();

/// See also [fetchArticleList].
class FetchArticleListFamily extends Family<AsyncValue<List<ArticleModel>?>> {
  /// See also [fetchArticleList].
  const FetchArticleListFamily();

  /// See also [fetchArticleList].
  FetchArticleListProvider call({
    required int page,
    required int galleryId,
    required int limit,
    required String sort,
    required String order,
  }) {
    return FetchArticleListProvider(
      page: page,
      galleryId: galleryId,
      limit: limit,
      sort: sort,
      order: order,
    );
  }

  @override
  FetchArticleListProvider getProviderOverride(
    covariant FetchArticleListProvider provider,
  ) {
    return call(
      page: provider.page,
      galleryId: provider.galleryId,
      limit: provider.limit,
      sort: provider.sort,
      order: provider.order,
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
  String? get name => r'fetchArticleListProvider';
}

/// See also [fetchArticleList].
class FetchArticleListProvider
    extends AutoDisposeFutureProvider<List<ArticleModel>?> {
  /// See also [fetchArticleList].
  FetchArticleListProvider({
    required int page,
    required int galleryId,
    required int limit,
    required String sort,
    required String order,
  }) : this._internal(
          (ref) => fetchArticleList(
            ref as FetchArticleListRef,
            page: page,
            galleryId: galleryId,
            limit: limit,
            sort: sort,
            order: order,
          ),
          from: fetchArticleListProvider,
          name: r'fetchArticleListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchArticleListHash,
          dependencies: FetchArticleListFamily._dependencies,
          allTransitiveDependencies:
              FetchArticleListFamily._allTransitiveDependencies,
          page: page,
          galleryId: galleryId,
          limit: limit,
          sort: sort,
          order: order,
        );

  FetchArticleListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.page,
    required this.galleryId,
    required this.limit,
    required this.sort,
    required this.order,
  }) : super.internal();

  final int page;
  final int galleryId;
  final int limit;
  final String sort;
  final String order;

  @override
  Override overrideWith(
    FutureOr<List<ArticleModel>?> Function(FetchArticleListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchArticleListProvider._internal(
        (ref) => create(ref as FetchArticleListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
        galleryId: galleryId,
        limit: limit,
        sort: sort,
        order: order,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ArticleModel>?> createElement() {
    return _FetchArticleListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchArticleListProvider &&
        other.page == page &&
        other.galleryId == galleryId &&
        other.limit == limit &&
        other.sort == sort &&
        other.order == order;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, galleryId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);
    hash = _SystemHash.combine(hash, order.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchArticleListRef on AutoDisposeFutureProviderRef<List<ArticleModel>?> {
  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `galleryId` of this provider.
  int get galleryId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `sort` of this provider.
  String get sort;

  /// The parameter `order` of this provider.
  String get order;
}

class _FetchArticleListProviderElement
    extends AutoDisposeFutureProviderElement<List<ArticleModel>?>
    with FetchArticleListRef {
  _FetchArticleListProviderElement(super.provider);

  @override
  int get page => (origin as FetchArticleListProvider).page;
  @override
  int get galleryId => (origin as FetchArticleListProvider).galleryId;
  @override
  int get limit => (origin as FetchArticleListProvider).limit;
  @override
  String get sort => (origin as FetchArticleListProvider).sort;
  @override
  String get order => (origin as FetchArticleListProvider).order;
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
String _$commentCountHash() => r'5687d5fee456a37c642c76eefe393e1d11162b55';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
