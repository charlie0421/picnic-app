// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncVoteListHash() => r'4f4cec321ae68d6a3493e12dfe5ce2c2db46d0c1';

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

abstract class _$AsyncVoteList
    extends BuildlessAutoDisposeAsyncNotifier<VoteListModel> {
  late final int page;
  late final int limit;
  late final String sort;
  late final String order;
  late final VoteStatus status;
  late final VoteCategory category;

  FutureOr<VoteListModel> build(
    int page,
    int limit,
    String sort,
    String order, {
    required VoteStatus status,
    required VoteCategory category,
  });
}

/// See also [AsyncVoteList].
@ProviderFor(AsyncVoteList)
const asyncVoteListProvider = AsyncVoteListFamily();

/// See also [AsyncVoteList].
class AsyncVoteListFamily extends Family<AsyncValue<VoteListModel>> {
  /// See also [AsyncVoteList].
  const AsyncVoteListFamily();

  /// See also [AsyncVoteList].
  AsyncVoteListProvider call(
    int page,
    int limit,
    String sort,
    String order, {
    required VoteStatus status,
    required VoteCategory category,
  }) {
    return AsyncVoteListProvider(
      page,
      limit,
      sort,
      order,
      status: status,
      category: category,
    );
  }

  @override
  AsyncVoteListProvider getProviderOverride(
    covariant AsyncVoteListProvider provider,
  ) {
    return call(
      provider.page,
      provider.limit,
      provider.sort,
      provider.order,
      status: provider.status,
      category: provider.category,
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
  String? get name => r'asyncVoteListProvider';
}

/// See also [AsyncVoteList].
class AsyncVoteListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncVoteList, VoteListModel> {
  /// See also [AsyncVoteList].
  AsyncVoteListProvider(
    int page,
    int limit,
    String sort,
    String order, {
    required VoteStatus status,
    required VoteCategory category,
  }) : this._internal(
          () => AsyncVoteList()
            ..page = page
            ..limit = limit
            ..sort = sort
            ..order = order
            ..status = status
            ..category = category,
          from: asyncVoteListProvider,
          name: r'asyncVoteListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncVoteListHash,
          dependencies: AsyncVoteListFamily._dependencies,
          allTransitiveDependencies:
              AsyncVoteListFamily._allTransitiveDependencies,
          page: page,
          limit: limit,
          sort: sort,
          order: order,
          status: status,
          category: category,
        );

  AsyncVoteListProvider._internal(
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
    required this.status,
    required this.category,
  }) : super.internal();

  final int page;
  final int limit;
  final String sort;
  final String order;
  final VoteStatus status;
  final VoteCategory category;

  @override
  FutureOr<VoteListModel> runNotifierBuild(
    covariant AsyncVoteList notifier,
  ) {
    return notifier.build(
      page,
      limit,
      sort,
      order,
      status: status,
      category: category,
    );
  }

  @override
  Override overrideWith(AsyncVoteList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteListProvider._internal(
        () => create()
          ..page = page
          ..limit = limit
          ..sort = sort
          ..order = order
          ..status = status
          ..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
        limit: limit,
        sort: sort,
        order: order,
        status: status,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncVoteList, VoteListModel>
      createElement() {
    return _AsyncVoteListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteListProvider &&
        other.page == page &&
        other.limit == limit &&
        other.sort == sort &&
        other.order == order &&
        other.status == status &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);
    hash = _SystemHash.combine(hash, order.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncVoteListRef on AutoDisposeAsyncNotifierProviderRef<VoteListModel> {
  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `sort` of this provider.
  String get sort;

  /// The parameter `order` of this provider.
  String get order;

  /// The parameter `status` of this provider.
  VoteStatus get status;

  /// The parameter `category` of this provider.
  VoteCategory get category;
}

class _AsyncVoteListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteList,
        VoteListModel> with AsyncVoteListRef {
  _AsyncVoteListProviderElement(super.provider);

  @override
  int get page => (origin as AsyncVoteListProvider).page;
  @override
  int get limit => (origin as AsyncVoteListProvider).limit;
  @override
  String get sort => (origin as AsyncVoteListProvider).sort;
  @override
  String get order => (origin as AsyncVoteListProvider).order;
  @override
  VoteStatus get status => (origin as AsyncVoteListProvider).status;
  @override
  VoteCategory get category => (origin as AsyncVoteListProvider).category;
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
