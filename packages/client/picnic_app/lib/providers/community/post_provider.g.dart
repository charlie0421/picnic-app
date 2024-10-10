// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postsByArtistHash() => r'eab6e33b24f57886cbe1b3e9794c4d04166d53a4';

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

/// See also [postsByArtist].
@ProviderFor(postsByArtist)
const postsByArtistProvider = PostsByArtistFamily();

/// See also [postsByArtist].
class PostsByArtistFamily extends Family<AsyncValue<List<PostModel>?>> {
  /// See also [postsByArtist].
  const PostsByArtistFamily();

  /// See also [postsByArtist].
  PostsByArtistProvider call(
    int artistId,
    int limit,
    int page,
  ) {
    return PostsByArtistProvider(
      artistId,
      limit,
      page,
    );
  }

  @override
  PostsByArtistProvider getProviderOverride(
    covariant PostsByArtistProvider provider,
  ) {
    return call(
      provider.artistId,
      provider.limit,
      provider.page,
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
  String? get name => r'postsByArtistProvider';
}

/// See also [postsByArtist].
class PostsByArtistProvider
    extends AutoDisposeFutureProvider<List<PostModel>?> {
  /// See also [postsByArtist].
  PostsByArtistProvider(
    int artistId,
    int limit,
    int page,
  ) : this._internal(
          (ref) => postsByArtist(
            ref as PostsByArtistRef,
            artistId,
            limit,
            page,
          ),
          from: postsByArtistProvider,
          name: r'postsByArtistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postsByArtistHash,
          dependencies: PostsByArtistFamily._dependencies,
          allTransitiveDependencies:
              PostsByArtistFamily._allTransitiveDependencies,
          artistId: artistId,
          limit: limit,
          page: page,
        );

  PostsByArtistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
    required this.limit,
    required this.page,
  }) : super.internal();

  final int artistId;
  final int limit;
  final int page;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>?> Function(PostsByArtistRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsByArtistProvider._internal(
        (ref) => create(ref as PostsByArtistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
        limit: limit,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>?> createElement() {
    return _PostsByArtistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByArtistProvider &&
        other.artistId == artistId &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostsByArtistRef on AutoDisposeFutureProviderRef<List<PostModel>?> {
  /// The parameter `artistId` of this provider.
  int get artistId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `page` of this provider.
  int get page;
}

class _PostsByArtistProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>?>
    with PostsByArtistRef {
  _PostsByArtistProviderElement(super.provider);

  @override
  int get artistId => (origin as PostsByArtistProvider).artistId;
  @override
  int get limit => (origin as PostsByArtistProvider).limit;
  @override
  int get page => (origin as PostsByArtistProvider).page;
}

String _$postsByBoardHash() => r'c02605c116825ce11e27c0f3365fea880faf3bf3';

/// See also [postsByBoard].
@ProviderFor(postsByBoard)
const postsByBoardProvider = PostsByBoardFamily();

/// See also [postsByBoard].
class PostsByBoardFamily extends Family<AsyncValue<List<PostModel>?>> {
  /// See also [postsByBoard].
  const PostsByBoardFamily();

  /// See also [postsByBoard].
  PostsByBoardProvider call(
    String boardId,
    int limit,
    int page,
  ) {
    return PostsByBoardProvider(
      boardId,
      limit,
      page,
    );
  }

  @override
  PostsByBoardProvider getProviderOverride(
    covariant PostsByBoardProvider provider,
  ) {
    return call(
      provider.boardId,
      provider.limit,
      provider.page,
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
  String? get name => r'postsByBoardProvider';
}

/// See also [postsByBoard].
class PostsByBoardProvider extends AutoDisposeFutureProvider<List<PostModel>?> {
  /// See also [postsByBoard].
  PostsByBoardProvider(
    String boardId,
    int limit,
    int page,
  ) : this._internal(
          (ref) => postsByBoard(
            ref as PostsByBoardRef,
            boardId,
            limit,
            page,
          ),
          from: postsByBoardProvider,
          name: r'postsByBoardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postsByBoardHash,
          dependencies: PostsByBoardFamily._dependencies,
          allTransitiveDependencies:
              PostsByBoardFamily._allTransitiveDependencies,
          boardId: boardId,
          limit: limit,
          page: page,
        );

  PostsByBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.boardId,
    required this.limit,
    required this.page,
  }) : super.internal();

  final String boardId;
  final int limit;
  final int page;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>?> Function(PostsByBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsByBoardProvider._internal(
        (ref) => create(ref as PostsByBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        boardId: boardId,
        limit: limit,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>?> createElement() {
    return _PostsByBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByBoardProvider &&
        other.boardId == boardId &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, boardId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostsByBoardRef on AutoDisposeFutureProviderRef<List<PostModel>?> {
  /// The parameter `boardId` of this provider.
  String get boardId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `page` of this provider.
  int get page;
}

class _PostsByBoardProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>?>
    with PostsByBoardRef {
  _PostsByBoardProviderElement(super.provider);

  @override
  String get boardId => (origin as PostsByBoardProvider).boardId;
  @override
  int get limit => (origin as PostsByBoardProvider).limit;
  @override
  int get page => (origin as PostsByBoardProvider).page;
}

String _$postsByQueryHash() => r'992d3709e8644eb620a0aa9304661081dd639f89';

/// See also [postsByQuery].
@ProviderFor(postsByQuery)
const postsByQueryProvider = PostsByQueryFamily();

/// See also [postsByQuery].
class PostsByQueryFamily extends Family<AsyncValue<List<PostModel>?>> {
  /// See also [postsByQuery].
  const PostsByQueryFamily();

  /// See also [postsByQuery].
  PostsByQueryProvider call(
    int artistId,
    String query,
    int page,
    int limit,
  ) {
    return PostsByQueryProvider(
      artistId,
      query,
      page,
      limit,
    );
  }

  @override
  PostsByQueryProvider getProviderOverride(
    covariant PostsByQueryProvider provider,
  ) {
    return call(
      provider.artistId,
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
  String? get name => r'postsByQueryProvider';
}

/// See also [postsByQuery].
class PostsByQueryProvider extends AutoDisposeFutureProvider<List<PostModel>?> {
  /// See also [postsByQuery].
  PostsByQueryProvider(
    int artistId,
    String query,
    int page,
    int limit,
  ) : this._internal(
          (ref) => postsByQuery(
            ref as PostsByQueryRef,
            artistId,
            query,
            page,
            limit,
          ),
          from: postsByQueryProvider,
          name: r'postsByQueryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postsByQueryHash,
          dependencies: PostsByQueryFamily._dependencies,
          allTransitiveDependencies:
              PostsByQueryFamily._allTransitiveDependencies,
          artistId: artistId,
          query: query,
          page: page,
          limit: limit,
        );

  PostsByQueryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
    required this.query,
    required this.page,
    required this.limit,
  }) : super.internal();

  final int artistId;
  final String query;
  final int page;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>?> Function(PostsByQueryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsByQueryProvider._internal(
        (ref) => create(ref as PostsByQueryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
        query: query,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>?> createElement() {
    return _PostsByQueryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByQueryProvider &&
        other.artistId == artistId &&
        other.query == query &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostsByQueryRef on AutoDisposeFutureProviderRef<List<PostModel>?> {
  /// The parameter `artistId` of this provider.
  int get artistId;

  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _PostsByQueryProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>?>
    with PostsByQueryRef {
  _PostsByQueryProviderElement(super.provider);

  @override
  int get artistId => (origin as PostsByQueryProvider).artistId;
  @override
  String get query => (origin as PostsByQueryProvider).query;
  @override
  int get page => (origin as PostsByQueryProvider).page;
  @override
  int get limit => (origin as PostsByQueryProvider).limit;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
