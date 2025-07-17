// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/vote_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchVoteAchieveHash() => r'd0378f9f5df39f5b8471c41903aa83b9a114cff7';

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

/// See also [fetchVoteAchieve].
@ProviderFor(fetchVoteAchieve)
const fetchVoteAchieveProvider = FetchVoteAchieveFamily();

/// See also [fetchVoteAchieve].
class FetchVoteAchieveFamily extends Family<AsyncValue<List<VoteAchieve>?>> {
  /// See also [fetchVoteAchieve].
  const FetchVoteAchieveFamily();

  /// See also [fetchVoteAchieve].
  FetchVoteAchieveProvider call({
    required int voteId,
  }) {
    return FetchVoteAchieveProvider(
      voteId: voteId,
    );
  }

  @override
  FetchVoteAchieveProvider getProviderOverride(
    covariant FetchVoteAchieveProvider provider,
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
  String? get name => r'fetchVoteAchieveProvider';
}

/// See also [fetchVoteAchieve].
class FetchVoteAchieveProvider
    extends AutoDisposeFutureProvider<List<VoteAchieve>?> {
  /// See also [fetchVoteAchieve].
  FetchVoteAchieveProvider({
    required int voteId,
  }) : this._internal(
          (ref) => fetchVoteAchieve(
            ref as FetchVoteAchieveRef,
            voteId: voteId,
          ),
          from: fetchVoteAchieveProvider,
          name: r'fetchVoteAchieveProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchVoteAchieveHash,
          dependencies: FetchVoteAchieveFamily._dependencies,
          allTransitiveDependencies:
              FetchVoteAchieveFamily._allTransitiveDependencies,
          voteId: voteId,
        );

  FetchVoteAchieveProvider._internal(
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
  Override overrideWith(
    FutureOr<List<VoteAchieve>?> Function(FetchVoteAchieveRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchVoteAchieveProvider._internal(
        (ref) => create(ref as FetchVoteAchieveRef),
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
  AutoDisposeFutureProviderElement<List<VoteAchieve>?> createElement() {
    return _FetchVoteAchieveProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchVoteAchieveProvider && other.voteId == voteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchVoteAchieveRef on AutoDisposeFutureProviderRef<List<VoteAchieve>?> {
  /// The parameter `voteId` of this provider.
  int get voteId;
}

class _FetchVoteAchieveProviderElement
    extends AutoDisposeFutureProviderElement<List<VoteAchieve>?>
    with FetchVoteAchieveRef {
  _FetchVoteAchieveProviderElement(super.provider);

  @override
  int get voteId => (origin as FetchVoteAchieveProvider).voteId;
}

String _$asyncVoteDetailHash() => r'dd83a1b07ecb1d931f075a9806561344b2431ad7';

abstract class _$AsyncVoteDetail
    extends BuildlessAutoDisposeAsyncNotifier<VoteModel?> {
  late final int voteId;
  late final VotePortal votePortal;

  FutureOr<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
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
    VotePortal votePortal = VotePortal.vote,
  }) {
    return AsyncVoteDetailProvider(
      voteId: voteId,
      votePortal: votePortal,
    );
  }

  @override
  AsyncVoteDetailProvider getProviderOverride(
    covariant AsyncVoteDetailProvider provider,
  ) {
    return call(
      voteId: provider.voteId,
      votePortal: provider.votePortal,
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
    VotePortal votePortal = VotePortal.vote,
  }) : this._internal(
          () => AsyncVoteDetail()
            ..voteId = voteId
            ..votePortal = votePortal,
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
          votePortal: votePortal,
        );

  AsyncVoteDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
    required this.votePortal,
  }) : super.internal();

  final int voteId;
  final VotePortal votePortal;

  @override
  FutureOr<VoteModel?> runNotifierBuild(
    covariant AsyncVoteDetail notifier,
  ) {
    return notifier.build(
      voteId: voteId,
      votePortal: votePortal,
    );
  }

  @override
  Override overrideWith(AsyncVoteDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteDetailProvider._internal(
        () => create()
          ..voteId = voteId
          ..votePortal = votePortal,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
        votePortal: votePortal,
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
    return other is AsyncVoteDetailProvider &&
        other.voteId == voteId &&
        other.votePortal == votePortal;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);
    hash = _SystemHash.combine(hash, votePortal.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AsyncVoteDetailRef on AutoDisposeAsyncNotifierProviderRef<VoteModel?> {
  /// The parameter `voteId` of this provider.
  int get voteId;

  /// The parameter `votePortal` of this provider.
  VotePortal get votePortal;
}

class _AsyncVoteDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteDetail, VoteModel?>
    with AsyncVoteDetailRef {
  _AsyncVoteDetailProviderElement(super.provider);

  @override
  int get voteId => (origin as AsyncVoteDetailProvider).voteId;
  @override
  VotePortal get votePortal => (origin as AsyncVoteDetailProvider).votePortal;
}

String _$asyncVoteItemListHash() => r'e83a599a864da32a61b3f423cee07b16c46e4e70';

abstract class _$AsyncVoteItemList
    extends BuildlessAutoDisposeAsyncNotifier<List<VoteItemModel?>> {
  late final int voteId;
  late final VotePortal votePortal;

  FutureOr<List<VoteItemModel?>> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
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
    VotePortal votePortal = VotePortal.vote,
  }) {
    return AsyncVoteItemListProvider(
      voteId: voteId,
      votePortal: votePortal,
    );
  }

  @override
  AsyncVoteItemListProvider getProviderOverride(
    covariant AsyncVoteItemListProvider provider,
  ) {
    return call(
      voteId: provider.voteId,
      votePortal: provider.votePortal,
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
    VotePortal votePortal = VotePortal.vote,
  }) : this._internal(
          () => AsyncVoteItemList()
            ..voteId = voteId
            ..votePortal = votePortal,
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
          votePortal: votePortal,
        );

  AsyncVoteItemListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
    required this.votePortal,
  }) : super.internal();

  final int voteId;
  final VotePortal votePortal;

  @override
  FutureOr<List<VoteItemModel?>> runNotifierBuild(
    covariant AsyncVoteItemList notifier,
  ) {
    return notifier.build(
      voteId: voteId,
      votePortal: votePortal,
    );
  }

  @override
  Override overrideWith(AsyncVoteItemList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncVoteItemListProvider._internal(
        () => create()
          ..voteId = voteId
          ..votePortal = votePortal,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
        votePortal: votePortal,
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
    return other is AsyncVoteItemListProvider &&
        other.voteId == voteId &&
        other.votePortal == votePortal;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);
    hash = _SystemHash.combine(hash, votePortal.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AsyncVoteItemListRef
    on AutoDisposeAsyncNotifierProviderRef<List<VoteItemModel?>> {
  /// The parameter `voteId` of this provider.
  int get voteId;

  /// The parameter `votePortal` of this provider.
  VotePortal get votePortal;
}

class _AsyncVoteItemListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncVoteItemList,
        List<VoteItemModel?>> with AsyncVoteItemListRef {
  _AsyncVoteItemListProviderElement(super.provider);

  @override
  int get voteId => (origin as AsyncVoteItemListProvider).voteId;
  @override
  VotePortal get votePortal => (origin as AsyncVoteItemListProvider).votePortal;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
