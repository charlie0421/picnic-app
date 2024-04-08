// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celeb_banner_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncCelebBannerListHash() =>
    r'17baa66d9eba250d1a526b27462d0364508996d5';

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

abstract class _$AsyncCelebBannerList
    extends BuildlessAutoDisposeAsyncNotifier<CelebBannerListModel> {
  late final int celebId;

  FutureOr<CelebBannerListModel> build({
    required int celebId,
  });
}

/// See also [AsyncCelebBannerList].
@ProviderFor(AsyncCelebBannerList)
const asyncCelebBannerListProvider = AsyncCelebBannerListFamily();

/// See also [AsyncCelebBannerList].
class AsyncCelebBannerListFamily
    extends Family<AsyncValue<CelebBannerListModel>> {
  /// See also [AsyncCelebBannerList].
  const AsyncCelebBannerListFamily();

  /// See also [AsyncCelebBannerList].
  AsyncCelebBannerListProvider call({
    required int celebId,
  }) {
    return AsyncCelebBannerListProvider(
      celebId: celebId,
    );
  }

  @override
  AsyncCelebBannerListProvider getProviderOverride(
    covariant AsyncCelebBannerListProvider provider,
  ) {
    return call(
      celebId: provider.celebId,
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
  String? get name => r'asyncCelebBannerListProvider';
}

/// See also [AsyncCelebBannerList].
class AsyncCelebBannerListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncCelebBannerList, CelebBannerListModel> {
  /// See also [AsyncCelebBannerList].
  AsyncCelebBannerListProvider({
    required int celebId,
  }) : this._internal(
          () => AsyncCelebBannerList()..celebId = celebId,
          from: asyncCelebBannerListProvider,
          name: r'asyncCelebBannerListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncCelebBannerListHash,
          dependencies: AsyncCelebBannerListFamily._dependencies,
          allTransitiveDependencies:
              AsyncCelebBannerListFamily._allTransitiveDependencies,
          celebId: celebId,
        );

  AsyncCelebBannerListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.celebId,
  }) : super.internal();

  final int celebId;

  @override
  FutureOr<CelebBannerListModel> runNotifierBuild(
    covariant AsyncCelebBannerList notifier,
  ) {
    return notifier.build(
      celebId: celebId,
    );
  }

  @override
  Override overrideWith(AsyncCelebBannerList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncCelebBannerListProvider._internal(
        () => create()..celebId = celebId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        celebId: celebId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncCelebBannerList,
      CelebBannerListModel> createElement() {
    return _AsyncCelebBannerListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncCelebBannerListProvider && other.celebId == celebId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, celebId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncCelebBannerListRef
    on AutoDisposeAsyncNotifierProviderRef<CelebBannerListModel> {
  /// The parameter `celebId` of this provider.
  int get celebId;
}

class _AsyncCelebBannerListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncCelebBannerList,
        CelebBannerListModel> with AsyncCelebBannerListRef {
  _AsyncCelebBannerListProviderElement(super.provider);

  @override
  int get celebId => (origin as AsyncCelebBannerListProvider).celebId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
