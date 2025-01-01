// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/fortune_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getFortuneHash() => r'd7e2a2688d0201d54a36ba0f06b9e8aef4fe5389';

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
    String language = 'ko',
  }) {
    return GetFortuneProvider(
      artistId: artistId,
      year: year,
      language: language,
    );
  }

  @override
  GetFortuneProvider getProviderOverride(
    covariant GetFortuneProvider provider,
  ) {
    return call(
      artistId: provider.artistId,
      year: provider.year,
      language: provider.language,
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
    String language = 'ko',
  }) : this._internal(
          (ref) => getFortune(
            ref as GetFortuneRef,
            artistId: artistId,
            year: year,
            language: language,
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
          language: language,
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
    required this.language,
  }) : super.internal();

  final int artistId;
  final int year;
  final String language;

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
        language: language,
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
        other.year == year &&
        other.language == language;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, language.hashCode);

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

  /// The parameter `language` of this provider.
  String get language;
}

class _GetFortuneProviderElement
    extends AutoDisposeFutureProviderElement<FortuneModel> with GetFortuneRef {
  _GetFortuneProviderElement(super.provider);

  @override
  int get artistId => (origin as GetFortuneProvider).artistId;
  @override
  int get year => (origin as GetFortuneProvider).year;
  @override
  String get language => (origin as GetFortuneProvider).language;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
