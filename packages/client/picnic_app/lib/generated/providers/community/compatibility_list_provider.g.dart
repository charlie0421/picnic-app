// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../providers/community/compatibility_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$compatibilityListHash() => r'443105867dfd827e865e3b1969dac63d94a46357';

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

abstract class _$CompatibilityList
    extends BuildlessAutoDisposeNotifier<CompatibilityHistoryModel> {
  late final int? artistId;

  CompatibilityHistoryModel build({
    int? artistId,
  });
}

/// See also [CompatibilityList].
@ProviderFor(CompatibilityList)
const compatibilityListProvider = CompatibilityListFamily();

/// See also [CompatibilityList].
class CompatibilityListFamily extends Family<CompatibilityHistoryModel> {
  /// See also [CompatibilityList].
  const CompatibilityListFamily();

  /// See also [CompatibilityList].
  CompatibilityListProvider call({
    int? artistId,
  }) {
    return CompatibilityListProvider(
      artistId: artistId,
    );
  }

  @override
  CompatibilityListProvider getProviderOverride(
    covariant CompatibilityListProvider provider,
  ) {
    return call(
      artistId: provider.artistId,
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
  String? get name => r'compatibilityListProvider';
}

/// See also [CompatibilityList].
class CompatibilityListProvider extends AutoDisposeNotifierProviderImpl<
    CompatibilityList, CompatibilityHistoryModel> {
  /// See also [CompatibilityList].
  CompatibilityListProvider({
    int? artistId,
  }) : this._internal(
          () => CompatibilityList()..artistId = artistId,
          from: compatibilityListProvider,
          name: r'compatibilityListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$compatibilityListHash,
          dependencies: CompatibilityListFamily._dependencies,
          allTransitiveDependencies:
              CompatibilityListFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  CompatibilityListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
  }) : super.internal();

  final int? artistId;

  @override
  CompatibilityHistoryModel runNotifierBuild(
    covariant CompatibilityList notifier,
  ) {
    return notifier.build(
      artistId: artistId,
    );
  }

  @override
  Override overrideWith(CompatibilityList Function() create) {
    return ProviderOverride(
      origin: this,
      override: CompatibilityListProvider._internal(
        () => create()..artistId = artistId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CompatibilityList,
      CompatibilityHistoryModel> createElement() {
    return _CompatibilityListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CompatibilityListProvider && other.artistId == artistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CompatibilityListRef
    on AutoDisposeNotifierProviderRef<CompatibilityHistoryModel> {
  /// The parameter `artistId` of this provider.
  int? get artistId;
}

class _CompatibilityListProviderElement
    extends AutoDisposeNotifierProviderElement<CompatibilityList,
        CompatibilityHistoryModel> with CompatibilityListRef {
  _CompatibilityListProviderElement(super.provider);

  @override
  int? get artistId => (origin as CompatibilityListProvider).artistId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
