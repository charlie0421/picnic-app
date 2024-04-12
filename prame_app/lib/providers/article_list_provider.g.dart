// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncArticleListHash() => r'b99ee8376fa296152ec8b02e40b902f710d7b445';

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

abstract class _$AsyncArticleList
    extends BuildlessAutoDisposeAsyncNotifier<ArticleListModel> {
  late final int? page;
  late final int? limit;
  late final String? sort;
  late final String? order;
  late final int galleryId;

  FutureOr<ArticleListModel> build(
    int? page,
    int? limit,
    String? sort,
    String? order, {
    required int galleryId,
  });
}

/// See also [AsyncArticleList].
@ProviderFor(AsyncArticleList)
const asyncArticleListProvider = AsyncArticleListFamily();

/// See also [AsyncArticleList].
class AsyncArticleListFamily extends Family<AsyncValue<ArticleListModel>> {
  /// See also [AsyncArticleList].
  const AsyncArticleListFamily();

  /// See also [AsyncArticleList].
  AsyncArticleListProvider call(
    int? page,
    int? limit,
    String? sort,
    String? order, {
    required int galleryId,
  }) {
    return AsyncArticleListProvider(
      page,
      limit,
      sort,
      order,
      galleryId: galleryId,
    );
  }

  @override
  AsyncArticleListProvider getProviderOverride(
    covariant AsyncArticleListProvider provider,
  ) {
    return call(
      provider.page,
      provider.limit,
      provider.sort,
      provider.order,
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
  String? get name => r'asyncArticleListProvider';
}

/// See also [AsyncArticleList].
class AsyncArticleListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncArticleList, ArticleListModel> {
  /// See also [AsyncArticleList].
  AsyncArticleListProvider(
    int? page,
    int? limit,
    String? sort,
    String? order, {
    required int galleryId,
  }) : this._internal(
          () => AsyncArticleList()
            ..page = page
            ..limit = limit
            ..sort = sort
            ..order = order
            ..galleryId = galleryId,
          from: asyncArticleListProvider,
          name: r'asyncArticleListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncArticleListHash,
          dependencies: AsyncArticleListFamily._dependencies,
          allTransitiveDependencies:
              AsyncArticleListFamily._allTransitiveDependencies,
          page: page,
          limit: limit,
          sort: sort,
          order: order,
          galleryId: galleryId,
        );

  AsyncArticleListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.page,
    required this.limit,
    required this.sort,
    required this.order,
    required this.galleryId,
  }) : super.internal();

  final int? page;
  final int? limit;
  final String? sort;
  final String? order;
  final int galleryId;

  @override
  FutureOr<ArticleListModel> runNotifierBuild(
    covariant AsyncArticleList notifier,
  ) {
    return notifier.build(
      page,
      limit,
      sort,
      order,
      galleryId: galleryId,
    );
  }

  @override
  Override overrideWith(AsyncArticleList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncArticleListProvider._internal(
        () => create()
          ..page = page
          ..limit = limit
          ..sort = sort
          ..order = order
          ..galleryId = galleryId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        galleryId: galleryId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncArticleList, ArticleListModel>
      createElement() {
    return _AsyncArticleListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncArticleListProvider &&
        other.page == page &&
        other.limit == limit &&
        other.sort == sort &&
        other.order == order &&
        other.galleryId == galleryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);
    hash = _SystemHash.combine(hash, order.hashCode);
    hash = _SystemHash.combine(hash, galleryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncArticleListRef
    on AutoDisposeAsyncNotifierProviderRef<ArticleListModel> {
  /// The parameter `page` of this provider.
  int? get page;

  /// The parameter `limit` of this provider.
  int? get limit;

  /// The parameter `sort` of this provider.
  String? get sort;

  /// The parameter `order` of this provider.
  String? get order;

  /// The parameter `galleryId` of this provider.
  int get galleryId;
}

class _AsyncArticleListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncArticleList,
        ArticleListModel> with AsyncArticleListRef {
  _AsyncArticleListProviderElement(super.provider);

  @override
  int? get page => (origin as AsyncArticleListProvider).page;
  @override
  int? get limit => (origin as AsyncArticleListProvider).limit;
  @override
  String? get sort => (origin as AsyncArticleListProvider).sort;
  @override
  String? get order => (origin as AsyncArticleListProvider).order;
  @override
  int get galleryId => (origin as AsyncArticleListProvider).galleryId;
}

String _$sortOptionHash() => r'10ad3d53ec66fe9204026499c9ff8640f8046e04';

/// See also [SortOption].
@ProviderFor(SortOption)
final sortOptionProvider =
    AutoDisposeNotifierProvider<SortOption, String>.internal(
  SortOption.new,
  name: r'sortOptionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sortOptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SortOption = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
