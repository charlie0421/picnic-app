// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardsHash() => r'f41387c824f984cbdf2a3d235a95118d68faa606';

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
    r'1908c37063960eb9bd167eb3ee09aae3af4c7f0e';

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

String _$checkPendingRequestHash() =>
    r'd0ee84f40e93e9f047a5ffb16b078c8995775943';

/// See also [checkPendingRequest].
@ProviderFor(checkPendingRequest)
final checkPendingRequestProvider =
    AutoDisposeFutureProvider<BoardModel?>.internal(
  checkPendingRequest,
  name: r'checkPendingRequestProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkPendingRequestHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CheckPendingRequestRef = AutoDisposeFutureProviderRef<BoardModel?>;
String _$checkDuplicateBoardHash() =>
    r'4972606a3d3fc7e3de594bea2969e69152e5cc61';

/// See also [checkDuplicateBoard].
@ProviderFor(checkDuplicateBoard)
const checkDuplicateBoardProvider = CheckDuplicateBoardFamily();

/// See also [checkDuplicateBoard].
class CheckDuplicateBoardFamily extends Family<AsyncValue<BoardModel?>> {
  /// See also [checkDuplicateBoard].
  const CheckDuplicateBoardFamily();

  /// See also [checkDuplicateBoard].
  CheckDuplicateBoardProvider call(
    String title,
  ) {
    return CheckDuplicateBoardProvider(
      title,
    );
  }

  @override
  CheckDuplicateBoardProvider getProviderOverride(
    covariant CheckDuplicateBoardProvider provider,
  ) {
    return call(
      provider.title,
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
  String? get name => r'checkDuplicateBoardProvider';
}

/// See also [checkDuplicateBoard].
class CheckDuplicateBoardProvider
    extends AutoDisposeFutureProvider<BoardModel?> {
  /// See also [checkDuplicateBoard].
  CheckDuplicateBoardProvider(
    String title,
  ) : this._internal(
          (ref) => checkDuplicateBoard(
            ref as CheckDuplicateBoardRef,
            title,
          ),
          from: checkDuplicateBoardProvider,
          name: r'checkDuplicateBoardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$checkDuplicateBoardHash,
          dependencies: CheckDuplicateBoardFamily._dependencies,
          allTransitiveDependencies:
              CheckDuplicateBoardFamily._allTransitiveDependencies,
          title: title,
        );

  CheckDuplicateBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.title,
  }) : super.internal();

  final String title;

  @override
  Override overrideWith(
    FutureOr<BoardModel?> Function(CheckDuplicateBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CheckDuplicateBoardProvider._internal(
        (ref) => create(ref as CheckDuplicateBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        title: title,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BoardModel?> createElement() {
    return _CheckDuplicateBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckDuplicateBoardProvider && other.title == title;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, title.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CheckDuplicateBoardRef on AutoDisposeFutureProviderRef<BoardModel?> {
  /// The parameter `title` of this provider.
  String get title;
}

class _CheckDuplicateBoardProviderElement
    extends AutoDisposeFutureProviderElement<BoardModel?>
    with CheckDuplicateBoardRef {
  _CheckDuplicateBoardProviderElement(super.provider);

  @override
  String get title => (origin as CheckDuplicateBoardProvider).title;
}

String _$createBoardHash() => r'74b7f1294ac096766413cfce97472675ce714a72';

/// See also [createBoard].
@ProviderFor(createBoard)
const createBoardProvider = CreateBoardFamily();

/// See also [createBoard].
class CreateBoardFamily extends Family<AsyncValue<BoardModel?>> {
  /// See also [createBoard].
  const CreateBoardFamily();

  /// See also [createBoard].
  CreateBoardProvider call(
    int artistId,
    String title,
    String description,
    dynamic requestMessage,
  ) {
    return CreateBoardProvider(
      artistId,
      title,
      description,
      requestMessage,
    );
  }

  @override
  CreateBoardProvider getProviderOverride(
    covariant CreateBoardProvider provider,
  ) {
    return call(
      provider.artistId,
      provider.title,
      provider.description,
      provider.requestMessage,
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
  String? get name => r'createBoardProvider';
}

/// See also [createBoard].
class CreateBoardProvider extends AutoDisposeFutureProvider<BoardModel?> {
  /// See also [createBoard].
  CreateBoardProvider(
    int artistId,
    String title,
    String description,
    dynamic requestMessage,
  ) : this._internal(
          (ref) => createBoard(
            ref as CreateBoardRef,
            artistId,
            title,
            description,
            requestMessage,
          ),
          from: createBoardProvider,
          name: r'createBoardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createBoardHash,
          dependencies: CreateBoardFamily._dependencies,
          allTransitiveDependencies:
              CreateBoardFamily._allTransitiveDependencies,
          artistId: artistId,
          title: title,
          description: description,
          requestMessage: requestMessage,
        );

  CreateBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
    required this.title,
    required this.description,
    required this.requestMessage,
  }) : super.internal();

  final int artistId;
  final String title;
  final String description;
  final dynamic requestMessage;

  @override
  Override overrideWith(
    FutureOr<BoardModel?> Function(CreateBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreateBoardProvider._internal(
        (ref) => create(ref as CreateBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
        title: title,
        description: description,
        requestMessage: requestMessage,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BoardModel?> createElement() {
    return _CreateBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateBoardProvider &&
        other.artistId == artistId &&
        other.title == title &&
        other.description == description &&
        other.requestMessage == requestMessage;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);
    hash = _SystemHash.combine(hash, title.hashCode);
    hash = _SystemHash.combine(hash, description.hashCode);
    hash = _SystemHash.combine(hash, requestMessage.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CreateBoardRef on AutoDisposeFutureProviderRef<BoardModel?> {
  /// The parameter `artistId` of this provider.
  int get artistId;

  /// The parameter `title` of this provider.
  String get title;

  /// The parameter `description` of this provider.
  String get description;

  /// The parameter `requestMessage` of this provider.
  dynamic get requestMessage;
}

class _CreateBoardProviderElement
    extends AutoDisposeFutureProviderElement<BoardModel?> with CreateBoardRef {
  _CreateBoardProviderElement(super.provider);

  @override
  int get artistId => (origin as CreateBoardProvider).artistId;
  @override
  String get title => (origin as CreateBoardProvider).title;
  @override
  String get description => (origin as CreateBoardProvider).description;
  @override
  dynamic get requestMessage => (origin as CreateBoardProvider).requestMessage;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
