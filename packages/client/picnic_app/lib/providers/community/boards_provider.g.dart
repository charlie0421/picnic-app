// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardsHash() => r'24e64e89aae9f218670147e3c5cd0f72807d1254';

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

/// See also [boards].
@ProviderFor(boards)
const boardsProvider = BoardsFamily();

/// See also [boards].
class BoardsFamily extends Family<AsyncValue<List<BoardModel>?>> {
  /// See also [boards].
  const BoardsFamily();

  /// See also [boards].
  BoardsProvider call(
    int artistId,
  ) {
    return BoardsProvider(
      artistId,
    );
  }

  @override
  BoardsProvider getProviderOverride(
    covariant BoardsProvider provider,
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
  String? get name => r'boardsProvider';
}

/// See also [boards].
class BoardsProvider extends AutoDisposeFutureProvider<List<BoardModel>?> {
  /// See also [boards].
  BoardsProvider(
    int artistId,
  ) : this._internal(
          (ref) => boards(
            ref as BoardsRef,
            artistId,
          ),
          from: boardsProvider,
          name: r'boardsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardsHash,
          dependencies: BoardsFamily._dependencies,
          allTransitiveDependencies: BoardsFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  BoardsProvider._internal(
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
    FutureOr<List<BoardModel>?> Function(BoardsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BoardsProvider._internal(
        (ref) => create(ref as BoardsRef),
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
  AutoDisposeFutureProviderElement<List<BoardModel>?> createElement() {
    return _BoardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardsProvider && other.artistId == artistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BoardsRef on AutoDisposeFutureProviderRef<List<BoardModel>?> {
  /// The parameter `artistId` of this provider.
  int get artistId;
}

class _BoardsProviderElement
    extends AutoDisposeFutureProviderElement<List<BoardModel>?> with BoardsRef {
  _BoardsProviderElement(super.provider);

  @override
  int get artistId => (origin as BoardsProvider).artistId;
}

String _$boardsByArtistNameHash() =>
    r'2d4c8ee40619d503087283a14443fbfc53709a8a';

/// See also [boardsByArtistName].
@ProviderFor(boardsByArtistName)
const boardsByArtistNameProvider = BoardsByArtistNameFamily();

/// See also [boardsByArtistName].
class BoardsByArtistNameFamily extends Family<AsyncValue<List<BoardModel>?>> {
  /// See also [boardsByArtistName].
  const BoardsByArtistNameFamily();

  /// See also [boardsByArtistName].
  BoardsByArtistNameProvider call(
    String query,
    int page,
    int limit,
  ) {
    return BoardsByArtistNameProvider(
      query,
      page,
      limit,
    );
  }

  @override
  BoardsByArtistNameProvider getProviderOverride(
    covariant BoardsByArtistNameProvider provider,
  ) {
    return call(
      provider.query,
      provider.page,
      provider.limit,
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
  String? get name => r'boardsByArtistNameProvider';
}

/// See also [boardsByArtistName].
class BoardsByArtistNameProvider
    extends AutoDisposeFutureProvider<List<BoardModel>?> {
  /// See also [boardsByArtistName].
  BoardsByArtistNameProvider(
    String query,
    int page,
    int limit,
  ) : this._internal(
          (ref) => boardsByArtistName(
            ref as BoardsByArtistNameRef,
            query,
            page,
            limit,
          ),
          from: boardsByArtistNameProvider,
          name: r'boardsByArtistNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardsByArtistNameHash,
          dependencies: BoardsByArtistNameFamily._dependencies,
          allTransitiveDependencies:
              BoardsByArtistNameFamily._allTransitiveDependencies,
          query: query,
          page: page,
          limit: limit,
        );

  BoardsByArtistNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.page,
    required this.limit,
  }) : super.internal();

  final String query;
  final int page;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<BoardModel>?> Function(BoardsByArtistNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BoardsByArtistNameProvider._internal(
        (ref) => create(ref as BoardsByArtistNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BoardModel>?> createElement() {
    return _BoardsByArtistNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardsByArtistNameProvider &&
        other.query == query &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BoardsByArtistNameRef on AutoDisposeFutureProviderRef<List<BoardModel>?> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _BoardsByArtistNameProviderElement
    extends AutoDisposeFutureProviderElement<List<BoardModel>?>
    with BoardsByArtistNameRef {
  _BoardsByArtistNameProviderElement(super.provider);

  @override
  String get query => (origin as BoardsByArtistNameProvider).query;
  @override
  int get page => (origin as BoardsByArtistNameProvider).page;
  @override
  int get limit => (origin as BoardsByArtistNameProvider).limit;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
