// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncVoteListHash() => r'eadbff1194e0ccdd3db472d96653394820d7de85';

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

abstract class _$AsyncVoteList extends BuildlessAutoDisposeAsyncNotifier<
    PagingController<int, VoteModel>> {
  late final String category;

  FutureOr<PagingController<int, VoteModel>> build({
    required String category,
  });
}

/// See also [AsyncVoteList].
@ProviderFor(AsyncVoteList)
const asyncVoteListProvider = AsyncVoteListFamily();

/// See also [AsyncVoteList].
class AsyncVoteListFamily
    extends Family<AsyncValue<PagingController<int, VoteModel>>> {
  /// See also [AsyncVoteList].
  const AsyncVoteListFamily();

  /// See also [AsyncVoteList].
  AsyncVoteListProvider call({
    required String category,
  }) {
    return AsyncVoteListProvider(
      category: category,
    );
  }

  @override
  AsyncVoteListProvider getProviderOverride(
    covariant AsyncVoteListProvider provider,
  ) {
    return call(
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
class AsyncVoteListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncVoteList, PagingController<int, VoteModel>> {
  /// See also [AsyncVoteList].
  AsyncVoteListProvider({
    required String category,
  }) : this._internal(
          () => AsyncVoteList()..category = category,
          from: asyncVoteListProvider,
          name: r'asyncVoteListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncVoteListHash,
          dependencies: AsyncVoteListFamily._dependencies,
          allTransitiveDependencies:
              AsyncVoteListFamily._allTransitiveDependencies,
          category: category,
        );

  AsyncVoteListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String category;

  @override
  FutureOr<PagingController<int, VoteModel>> runNotifierBuild(
    covariant AsyncVoteList notifier,
  ) {
    return notifier.build(
      category: category,
    );
  }

  @override
  Override overrideWith(AsyncVoteList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteListProvider._internal(
        () => create()..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncVoteList,
      PagingController<int, VoteModel>> createElement() {
    return _AsyncVoteListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteListProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncVoteListRef
    on AutoDisposeAsyncNotifierProviderRef<PagingController<int, VoteModel>> {
  /// The parameter `category` of this provider.
  String get category;
}

class _AsyncVoteListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteList,
        PagingController<int, VoteModel>> with AsyncVoteListRef {
  _AsyncVoteListProviderElement(super.provider);

  @override
  String get category => (origin as AsyncVoteListProvider).category;
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
