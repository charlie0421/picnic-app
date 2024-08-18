// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncBannerListHash() => r'ffb58903d43b68c4509060f1199c8930fdc28580';

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

abstract class _$AsyncBannerList
    extends BuildlessAutoDisposeAsyncNotifier<List<BannerModel>> {
  late final String location;

  FutureOr<List<BannerModel>> build({
    required String location,
  });
}

/// See also [AsyncBannerList].
@ProviderFor(AsyncBannerList)
const asyncBannerListProvider = AsyncBannerListFamily();

/// See also [AsyncBannerList].
class AsyncBannerListFamily extends Family<AsyncValue<List<BannerModel>>> {
  /// See also [AsyncBannerList].
  const AsyncBannerListFamily();

  /// See also [AsyncBannerList].
  AsyncBannerListProvider call({
    required String location,
  }) {
    return AsyncBannerListProvider(
      location: location,
    );
  }

  @override
  AsyncBannerListProvider getProviderOverride(
    covariant AsyncBannerListProvider provider,
  ) {
    return call(
      location: provider.location,
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
  String? get name => r'asyncBannerListProvider';
}

/// See also [AsyncBannerList].
class AsyncBannerListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncBannerList, List<BannerModel>> {
  /// See also [AsyncBannerList].
  AsyncBannerListProvider({
    required String location,
  }) : this._internal(
          () => AsyncBannerList()..location = location,
          from: asyncBannerListProvider,
          name: r'asyncBannerListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncBannerListHash,
          dependencies: AsyncBannerListFamily._dependencies,
          allTransitiveDependencies:
              AsyncBannerListFamily._allTransitiveDependencies,
          location: location,
        );

  AsyncBannerListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.location,
  }) : super.internal();

  final String location;

  @override
  FutureOr<List<BannerModel>> runNotifierBuild(
    covariant AsyncBannerList notifier,
  ) {
    return notifier.build(
      location: location,
    );
  }

  @override
  Override overrideWith(AsyncBannerList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncBannerListProvider._internal(
        () => create()..location = location,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        location: location,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncBannerList, List<BannerModel>>
      createElement() {
    return _AsyncBannerListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncBannerListProvider && other.location == location;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, location.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncBannerListRef
    on AutoDisposeAsyncNotifierProviderRef<List<BannerModel>> {
  /// The parameter `location` of this provider.
  String get location;
}

class _AsyncBannerListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncBannerList,
        List<BannerModel>> with AsyncBannerListRef {
  _AsyncBannerListProviderElement(super.provider);

  @override
  String get location => (origin as AsyncBannerListProvider).location;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
