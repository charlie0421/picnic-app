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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
