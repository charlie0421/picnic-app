// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../providers/community/fortune_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getFortuneHash() => r'38d0564fd6c305d8050875c336ae0446628f29c1';

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

/// See also [getFortune].
@ProviderFor(getFortune)
const getFortuneProvider = GetFortuneFamily();

/// See also [getFortune].
class GetFortuneFamily extends Family<AsyncValue<FortuneModel>> {
  /// See also [getFortune].
  const GetFortuneFamily();

  /// See also [getFortune].
  GetFortuneProvider call({
    required int artistId,
    required int year,
  }) {
    return GetFortuneProvider(
      artistId: artistId,
      year: year,
    );
  }

  @override
  GetFortuneProvider getProviderOverride(
    covariant GetFortuneProvider provider,
  ) {
    return call(
      artistId: provider.artistId,
      year: provider.year,
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
  String? get name => r'getFortuneProvider';
}

/// See also [getFortune].
class GetFortuneProvider extends AutoDisposeFutureProvider<FortuneModel> {
  /// See also [getFortune].
  GetFortuneProvider({
    required int artistId,
    required int year,
  }) : this._internal(
          (ref) => getFortune(
            ref as GetFortuneRef,
            artistId: artistId,
            year: year,
          ),
          from: getFortuneProvider,
          name: r'getFortuneProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getFortuneHash,
          dependencies: GetFortuneFamily._dependencies,
          allTransitiveDependencies:
              GetFortuneFamily._allTransitiveDependencies,
          artistId: artistId,
          year: year,
        );

  GetFortuneProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
    required this.year,
  }) : super.internal();

  final int artistId;
  final int year;

  @override
  Override overrideWith(
    FutureOr<FortuneModel> Function(GetFortuneRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetFortuneProvider._internal(
        (ref) => create(ref as GetFortuneRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FortuneModel> createElement() {
    return _GetFortuneProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetFortuneProvider &&
        other.artistId == artistId &&
        other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetFortuneRef on AutoDisposeFutureProviderRef<FortuneModel> {
  /// The parameter `artistId` of this provider.
  int get artistId;

  /// The parameter `year` of this provider.
  int get year;
}

class _GetFortuneProviderElement
    extends AutoDisposeFutureProviderElement<FortuneModel> with GetFortuneRef {
  _GetFortuneProviderElement(super.provider);

  @override
  int get artistId => (origin as GetFortuneProvider).artistId;
  @override
  int get year => (origin as GetFortuneProvider).year;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
