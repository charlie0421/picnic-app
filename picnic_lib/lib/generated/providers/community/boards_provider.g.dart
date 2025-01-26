// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/boards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardDetailHash() => r'0ca1e17d39c739838a4ebc18cc31e13cf860eb95';

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

abstract class _$BoardDetail
    extends BuildlessAutoDisposeAsyncNotifier<BoardModel?> {
  late final String boardId;

  FutureOr<BoardModel?> build(
    String boardId,
  );
}

/// See also [BoardDetail].
@ProviderFor(BoardDetail)
const boardDetailProvider = BoardDetailFamily();

/// See also [BoardDetail].
class BoardDetailFamily extends Family<AsyncValue<BoardModel?>> {
  /// See also [BoardDetail].
  const BoardDetailFamily();

  /// See also [BoardDetail].
  BoardDetailProvider call(
    String boardId,
  ) {
    return BoardDetailProvider(
      boardId,
    );
  }

  @override
  BoardDetailProvider getProviderOverride(
    covariant BoardDetailProvider provider,
  ) {
    return call(
      provider.boardId,
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
  String? get name => r'boardDetailProvider';
}

/// See also [BoardDetail].
class BoardDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BoardDetail, BoardModel?> {
  /// See also [BoardDetail].
  BoardDetailProvider(
    String boardId,
  ) : this._internal(
          () => BoardDetail()..boardId = boardId,
          from: boardDetailProvider,
          name: r'boardDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardDetailHash,
          dependencies: BoardDetailFamily._dependencies,
          allTransitiveDependencies:
              BoardDetailFamily._allTransitiveDependencies,
          boardId: boardId,
        );

  BoardDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.boardId,
  }) : super.internal();

  final String boardId;

  @override
  FutureOr<BoardModel?> runNotifierBuild(
    covariant BoardDetail notifier,
  ) {
    return notifier.build(
      boardId,
    );
  }

  @override
  Override overrideWith(BoardDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: BoardDetailProvider._internal(
        () => create()..boardId = boardId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        boardId: boardId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BoardDetail, BoardModel?>
      createElement() {
    return _BoardDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardDetailProvider && other.boardId == boardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, boardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BoardDetailRef on AutoDisposeAsyncNotifierProviderRef<BoardModel?> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _BoardDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BoardDetail, BoardModel?>
    with BoardDetailRef {
  _BoardDetailProviderElement(super.provider);

  @override
  String get boardId => (origin as BoardDetailProvider).boardId;
}

String _$boardsNotifierHash() => r'3bf2919f8c41eaf900af69990c5d73163e6cd7c2';

abstract class _$BoardsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<BoardModel>?> {
  late final int artistId;

  FutureOr<List<BoardModel>?> build(
    int artistId,
  );
}

/// See also [BoardsNotifier].
@ProviderFor(BoardsNotifier)
const boardsNotifierProvider = BoardsNotifierFamily();

/// See also [BoardsNotifier].
class BoardsNotifierFamily extends Family<AsyncValue<List<BoardModel>?>> {
  /// See also [BoardsNotifier].
  const BoardsNotifierFamily();

  /// See also [BoardsNotifier].
  BoardsNotifierProvider call(
    int artistId,
  ) {
    return BoardsNotifierProvider(
      artistId,
    );
  }

  @override
  BoardsNotifierProvider getProviderOverride(
    covariant BoardsNotifierProvider provider,
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
  String? get name => r'boardsNotifierProvider';
}

/// See also [BoardsNotifier].
class BoardsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    BoardsNotifier, List<BoardModel>?> {
  /// See also [BoardsNotifier].
  BoardsNotifierProvider(
    int artistId,
  ) : this._internal(
          () => BoardsNotifier()..artistId = artistId,
          from: boardsNotifierProvider,
          name: r'boardsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardsNotifierHash,
          dependencies: BoardsNotifierFamily._dependencies,
          allTransitiveDependencies:
              BoardsNotifierFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  BoardsNotifierProvider._internal(
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
  FutureOr<List<BoardModel>?> runNotifierBuild(
    covariant BoardsNotifier notifier,
  ) {
    return notifier.build(
      artistId,
    );
  }

  @override
  Override overrideWith(BoardsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BoardsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BoardsNotifier, List<BoardModel>?>
      createElement() {
    return _BoardsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardsNotifierProvider && other.artistId == artistId;
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
mixin BoardsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<BoardModel>?> {
  /// The parameter `artistId` of this provider.
  int get artistId;
}

class _BoardsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BoardsNotifier,
        List<BoardModel>?> with BoardsNotifierRef {
  _BoardsNotifierProviderElement(super.provider);

  @override
  int get artistId => (origin as BoardsNotifierProvider).artistId;
}

String _$boardsByArtistNameNotifierHash() =>
    r'667361a10baf59e260d77f712dd9593f4af5a919';

abstract class _$BoardsByArtistNameNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<BoardModel>?> {
  late final String query;
  late final int page;
  late final int limit;

  FutureOr<List<BoardModel>?> build(
    String query,
    int page,
    int limit,
  );
}

/// See also [BoardsByArtistNameNotifier].
@ProviderFor(BoardsByArtistNameNotifier)
const boardsByArtistNameNotifierProvider = BoardsByArtistNameNotifierFamily();

/// See also [BoardsByArtistNameNotifier].
class BoardsByArtistNameNotifierFamily
    extends Family<AsyncValue<List<BoardModel>?>> {
  /// See also [BoardsByArtistNameNotifier].
  const BoardsByArtistNameNotifierFamily();

  /// See also [BoardsByArtistNameNotifier].
  BoardsByArtistNameNotifierProvider call(
    String query,
    int page,
    int limit,
  ) {
    return BoardsByArtistNameNotifierProvider(
      query,
      page,
      limit,
    );
  }

  @override
  BoardsByArtistNameNotifierProvider getProviderOverride(
    covariant BoardsByArtistNameNotifierProvider provider,
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
  String? get name => r'boardsByArtistNameNotifierProvider';
}

/// See also [BoardsByArtistNameNotifier].
class BoardsByArtistNameNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BoardsByArtistNameNotifier,
        List<BoardModel>?> {
  /// See also [BoardsByArtistNameNotifier].
  BoardsByArtistNameNotifierProvider(
    String query,
    int page,
    int limit,
  ) : this._internal(
          () => BoardsByArtistNameNotifier()
            ..query = query
            ..page = page
            ..limit = limit,
          from: boardsByArtistNameNotifierProvider,
          name: r'boardsByArtistNameNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardsByArtistNameNotifierHash,
          dependencies: BoardsByArtistNameNotifierFamily._dependencies,
          allTransitiveDependencies:
              BoardsByArtistNameNotifierFamily._allTransitiveDependencies,
          query: query,
          page: page,
          limit: limit,
        );

  BoardsByArtistNameNotifierProvider._internal(
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
  FutureOr<List<BoardModel>?> runNotifierBuild(
    covariant BoardsByArtistNameNotifier notifier,
  ) {
    return notifier.build(
      query,
      page,
      limit,
    );
  }

  @override
  Override overrideWith(BoardsByArtistNameNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BoardsByArtistNameNotifierProvider._internal(
        () => create()
          ..query = query
          ..page = page
          ..limit = limit,
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
  AutoDisposeAsyncNotifierProviderElement<BoardsByArtistNameNotifier,
      List<BoardModel>?> createElement() {
    return _BoardsByArtistNameNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardsByArtistNameNotifierProvider &&
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BoardsByArtistNameNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<BoardModel>?> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _BoardsByArtistNameNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BoardsByArtistNameNotifier,
        List<BoardModel>?> with BoardsByArtistNameNotifierRef {
  _BoardsByArtistNameNotifierProviderElement(super.provider);

  @override
  String get query => (origin as BoardsByArtistNameNotifierProvider).query;
  @override
  int get page => (origin as BoardsByArtistNameNotifierProvider).page;
  @override
  int get limit => (origin as BoardsByArtistNameNotifierProvider).limit;
}

String _$boardRequestNotifierHash() =>
    r'282686a0efa594278b1473643a4ddf9bf0fb52bf';

/// See also [BoardRequestNotifier].
@ProviderFor(BoardRequestNotifier)
final boardRequestNotifierProvider = AutoDisposeAsyncNotifierProvider<
    BoardRequestNotifier, BoardModel?>.internal(
  BoardRequestNotifier.new,
  name: r'boardRequestNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardRequestNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BoardRequestNotifier = AutoDisposeAsyncNotifier<BoardModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
