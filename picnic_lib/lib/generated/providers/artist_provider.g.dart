// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/artist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getArtistHash() => r'e2f44b9268c2239e49ba6be52ed4aca2f1d6b132';

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

/// See also [getArtist].
@ProviderFor(getArtist)
const getArtistProvider = GetArtistFamily();

/// See also [getArtist].
class GetArtistFamily extends Family<AsyncValue<ArtistModel>> {
  /// See also [getArtist].
  const GetArtistFamily();

  /// See also [getArtist].
  GetArtistProvider call(
    int artistId,
  ) {
    return GetArtistProvider(
      artistId,
    );
  }

  @override
  GetArtistProvider getProviderOverride(
    covariant GetArtistProvider provider,
  ) {
    return call(
      provider.artistId,
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
  String? get name => r'getArtistProvider';
}

/// See also [getArtist].
class GetArtistProvider extends AutoDisposeFutureProvider<ArtistModel> {
  /// See also [getArtist].
  GetArtistProvider(
    int artistId,
  ) : this._internal(
          (ref) => getArtist(
            ref as GetArtistRef,
            artistId,
          ),
          from: getArtistProvider,
          name: r'getArtistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getArtistHash,
          dependencies: GetArtistFamily._dependencies,
          allTransitiveDependencies: GetArtistFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  GetArtistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
  }) : super.internal();

  final int artistId;

  @override
  Override overrideWith(
    FutureOr<ArtistModel> Function(GetArtistRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetArtistProvider._internal(
        (ref) => create(ref as GetArtistRef),
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
  AutoDisposeFutureProviderElement<ArtistModel> createElement() {
    return _GetArtistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetArtistProvider && other.artistId == artistId;
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
mixin GetArtistRef on AutoDisposeFutureProviderRef<ArtistModel> {
  /// The parameter `artistId` of this provider.
  int get artistId;
}

class _GetArtistProviderElement
    extends AutoDisposeFutureProviderElement<ArtistModel> with GetArtistRef {
  _GetArtistProviderElement(super.provider);

  @override
  int get artistId => (origin as GetArtistProvider).artistId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
