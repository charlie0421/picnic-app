// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_pick_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncVotePickListHash() => r'09735062f07e9ca09c1297a5a38d1841dbc2e4ee';

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

abstract class _$AsyncVotePickList
    extends BuildlessAutoDisposeAsyncNotifier<VotePickListModel> {
  late final int page;
  late final int limit;
  late final String sort;
  late final String order;

  FutureOr<VotePickListModel> build(
    int page,
    int limit,
    String sort,
    String order,
  );
}

/// See also [AsyncVotePickList].
@ProviderFor(AsyncVotePickList)
const asyncVotePickListProvider = AsyncVotePickListFamily();

/// See also [AsyncVotePickList].
class AsyncVotePickListFamily extends Family<AsyncValue<VotePickListModel>> {
  /// See also [AsyncVotePickList].
  const AsyncVotePickListFamily();

  /// See also [AsyncVotePickList].
  AsyncVotePickListProvider call(
    int page,
    int limit,
    String sort,
    String order,
  ) {
    return AsyncVotePickListProvider(
      page,
      limit,
      sort,
      order,
    );
  }

  @override
  AsyncVotePickListProvider getProviderOverride(
    covariant AsyncVotePickListProvider provider,
  ) {
    return call(
      provider.page,
      provider.limit,
      provider.sort,
      provider.order,
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
  String? get name => r'asyncVotePickListProvider';
}

/// See also [AsyncVotePickList].
class AsyncVotePickListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncVotePickList, VotePickListModel> {
  /// See also [AsyncVotePickList].
  AsyncVotePickListProvider(
    int page,
    int limit,
    String sort,
    String order,
  ) : this._internal(
          () => AsyncVotePickList()
            ..page = page
            ..limit = limit
            ..sort = sort
            ..order = order,
          from: asyncVotePickListProvider,
          name: r'asyncVotePickListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncVotePickListHash,
          dependencies: AsyncVotePickListFamily._dependencies,
          allTransitiveDependencies:
              AsyncVotePickListFamily._allTransitiveDependencies,
          page: page,
          limit: limit,
          sort: sort,
          order: order,
        );

  AsyncVotePickListProvider._internal(
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
  }) : super.internal();

  final int page;
  final int limit;
  final String sort;
  final String order;

  @override
  FutureOr<VotePickListModel> runNotifierBuild(
    covariant AsyncVotePickList notifier,
  ) {
    return notifier.build(
      page,
      limit,
      sort,
      order,
    );
  }

  @override
  Override overrideWith(AsyncVotePickList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVotePickListProvider._internal(
        () => create()
          ..page = page
          ..limit = limit
          ..sort = sort
          ..order = order,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
        limit: limit,
        sort: sort,
        order: order,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncVotePickList, VotePickListModel>
      createElement() {
    return _AsyncVotePickListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncVotePickListProvider &&
        other.page == page &&
        other.limit == limit &&
        other.sort == sort &&
        other.order == order;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);
    hash = _SystemHash.combine(hash, order.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncVotePickListRef
    on AutoDisposeAsyncNotifierProviderRef<VotePickListModel> {
  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `sort` of this provider.
  String get sort;

  /// The parameter `order` of this provider.
  String get order;
}

class _AsyncVotePickListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVotePickList,
        VotePickListModel> with AsyncVotePickListRef {
  _AsyncVotePickListProviderElement(super.provider);

  @override
  int get page => (origin as AsyncVotePickListProvider).page;
  @override
  int get limit => (origin as AsyncVotePickListProvider).limit;
  @override
  String get sort => (origin as AsyncVotePickListProvider).sort;
  @override
  String get order => (origin as AsyncVotePickListProvider).order;
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
