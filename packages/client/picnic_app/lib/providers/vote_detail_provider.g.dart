// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncVoteDetailHash() => r'4e1142ddaef1142936ae8003b6e93dfce93ada28';

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

abstract class _$AsyncVoteDetail
    extends BuildlessAutoDisposeAsyncNotifier<VoteModel?> {
  late final int voteId;

  FutureOr<VoteModel?> build({
    required int voteId,
  });
}

/// See also [AsyncVoteDetail].
@ProviderFor(AsyncVoteDetail)
const asyncVoteDetailProvider = AsyncVoteDetailFamily();

/// See also [AsyncVoteDetail].
class AsyncVoteDetailFamily extends Family<AsyncValue<VoteModel?>> {
  /// See also [AsyncVoteDetail].
  const AsyncVoteDetailFamily();

  /// See also [AsyncVoteDetail].
  AsyncVoteDetailProvider call({
    required int voteId,
  }) {
    return AsyncVoteDetailProvider(
      voteId: voteId,
    );
  }

  @override
  AsyncVoteDetailProvider getProviderOverride(
    covariant AsyncVoteDetailProvider provider,
  ) {
    return call(
      voteId: provider.voteId,
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
  String? get name => r'asyncVoteDetailProvider';
}

/// See also [AsyncVoteDetail].
class AsyncVoteDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncVoteDetail, VoteModel?> {
  /// See also [AsyncVoteDetail].
  AsyncVoteDetailProvider({
    required int voteId,
  }) : this._internal(
          () => AsyncVoteDetail()..voteId = voteId,
          from: asyncVoteDetailProvider,
          name: r'asyncVoteDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncVoteDetailHash,
          dependencies: AsyncVoteDetailFamily._dependencies,
          allTransitiveDependencies:
              AsyncVoteDetailFamily._allTransitiveDependencies,
          voteId: voteId,
        );

  AsyncVoteDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
  }) : super.internal();

  final int voteId;

  @override
  FutureOr<VoteModel?> runNotifierBuild(
    covariant AsyncVoteDetail notifier,
  ) {
    return notifier.build(
      voteId: voteId,
    );
  }

  @override
  Override overrideWith(AsyncVoteDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteDetailProvider._internal(
        () => create()..voteId = voteId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncVoteDetail, VoteModel?>
      createElement() {
    return _AsyncVoteDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteDetailProvider && other.voteId == voteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncVoteDetailRef on AutoDisposeAsyncNotifierProviderRef<VoteModel?> {
  /// The parameter `voteId` of this provider.
  int get voteId;
}

class _AsyncVoteDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteDetail, VoteModel?>
    with AsyncVoteDetailRef {
  _AsyncVoteDetailProviderElement(super.provider);

  @override
  int get voteId => (origin as AsyncVoteDetailProvider).voteId;
}

String _$asyncVoteItemListHash() => r'209f9157f1384a6840614a270f8d1410fc5e3a52';

abstract class _$AsyncVoteItemList
    extends BuildlessAutoDisposeAsyncNotifier<List<VoteItemModel?>> {
  late final int voteId;

  FutureOr<List<VoteItemModel?>> build({
    required int voteId,
  });
}

/// See also [AsyncVoteItemList].
@ProviderFor(AsyncVoteItemList)
const asyncVoteItemListProvider = AsyncVoteItemListFamily();

/// See also [AsyncVoteItemList].
class AsyncVoteItemListFamily extends Family<AsyncValue<List<VoteItemModel?>>> {
  /// See also [AsyncVoteItemList].
  const AsyncVoteItemListFamily();

  /// See also [AsyncVoteItemList].
  AsyncVoteItemListProvider call({
    required int voteId,
  }) {
    return AsyncVoteItemListProvider(
      voteId: voteId,
    );
  }

  @override
  AsyncVoteItemListProvider getProviderOverride(
    covariant AsyncVoteItemListProvider provider,
  ) {
    return call(
      voteId: provider.voteId,
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
  String? get name => r'asyncVoteItemListProvider';
}

/// See also [AsyncVoteItemList].
class AsyncVoteItemListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncVoteItemList, List<VoteItemModel?>> {
  /// See also [AsyncVoteItemList].
  AsyncVoteItemListProvider({
    required int voteId,
  }) : this._internal(
          () => AsyncVoteItemList()..voteId = voteId,
          from: asyncVoteItemListProvider,
          name: r'asyncVoteItemListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncVoteItemListHash,
          dependencies: AsyncVoteItemListFamily._dependencies,
          allTransitiveDependencies:
              AsyncVoteItemListFamily._allTransitiveDependencies,
          voteId: voteId,
        );

  AsyncVoteItemListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
  }) : super.internal();

  final int voteId;

  @override
  FutureOr<List<VoteItemModel?>> runNotifierBuild(
    covariant AsyncVoteItemList notifier,
  ) {
    return notifier.build(
      voteId: voteId,
    );
  }

  @override
  Override overrideWith(AsyncVoteItemList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteItemListProvider._internal(
        () => create()..voteId = voteId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncVoteItemList,
      List<VoteItemModel?>> createElement() {
    return _AsyncVoteItemListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteItemListProvider && other.voteId == voteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncVoteItemListRef
    on AutoDisposeAsyncNotifierProviderRef<List<VoteItemModel?>> {
  /// The parameter `voteId` of this provider.
  int get voteId;
}

class _AsyncVoteItemListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteItemList,
        List<VoteItemModel?>> with AsyncVoteItemListRef {
  _AsyncVoteItemListProviderElement(super.provider);

  @override
  int get voteId => (origin as AsyncVoteItemListProvider).voteId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
