// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../providers/community/post_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postsByArtistHash() => r'db9f947f35ad77b82513272683a3230de8f271c5';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

String _$postsByBoardHash() => r'51ed36a313a45e883dd7352b03aaa5c246352a4f';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

String _$postsByQueryHash() => r'2fbf0253087b4e3afff0720e256e64baab1141be';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

String _$postByIdHash() => r'3c8df580ec86ae68621d6754d1c8983efb1fdbe0';

/// See also [postById].
@ProviderFor(postById)
const postByIdProvider = PostByIdFamily();

/// See also [postById].
class PostByIdFamily extends Family<AsyncValue<PostModel?>> {
  /// See also [postById].
  const PostByIdFamily();

  /// See also [postById].
  PostByIdProvider call(
    String postId, {
    bool isIncrementViewCount = true,
  }) {
    return PostByIdProvider(
      postId,
      isIncrementViewCount: isIncrementViewCount,
    );
  }

  @override
  PostByIdProvider getProviderOverride(
    covariant PostByIdProvider provider,
  ) {
    return call(
      provider.postId,
      isIncrementViewCount: provider.isIncrementViewCount,
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
  String? get name => r'postByIdProvider';
}

/// See also [postById].
class PostByIdProvider extends AutoDisposeFutureProvider<PostModel?> {
  /// See also [postById].
  PostByIdProvider(
    String postId, {
    bool isIncrementViewCount = true,
  }) : this._internal(
          (ref) => postById(
            ref as PostByIdRef,
            postId,
            isIncrementViewCount: isIncrementViewCount,
          ),
          from: postByIdProvider,
          name: r'postByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postByIdHash,
          dependencies: PostByIdFamily._dependencies,
          allTransitiveDependencies: PostByIdFamily._allTransitiveDependencies,
          postId: postId,
          isIncrementViewCount: isIncrementViewCount,
        );

  PostByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.isIncrementViewCount,
  }) : super.internal();

  final String postId;
  final bool isIncrementViewCount;

  @override
  Override overrideWith(
    FutureOr<PostModel?> Function(PostByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostByIdProvider._internal(
        (ref) => create(ref as PostByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        isIncrementViewCount: isIncrementViewCount,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PostModel?> createElement() {
    return _PostByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostByIdProvider &&
        other.postId == postId &&
        other.isIncrementViewCount == isIncrementViewCount;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, isIncrementViewCount.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostByIdRef on AutoDisposeFutureProviderRef<PostModel?> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `isIncrementViewCount` of this provider.
  bool get isIncrementViewCount;
}

class _PostByIdProviderElement
    extends AutoDisposeFutureProviderElement<PostModel?> with PostByIdRef {
  _PostByIdProviderElement(super.provider);

  @override
  String get postId => (origin as PostByIdProvider).postId;
  @override
  bool get isIncrementViewCount =>
      (origin as PostByIdProvider).isIncrementViewCount;
}

String _$postsByUserHash() => r'4bc94bb145ba4bcee1d781b76255029e3f99f67f';

/// See also [postsByUser].
@ProviderFor(postsByUser)
const postsByUserProvider = PostsByUserFamily();

/// See also [postsByUser].
class PostsByUserFamily extends Family<AsyncValue<List<PostModel>>> {
  /// See also [postsByUser].
  const PostsByUserFamily();

  /// See also [postsByUser].
  PostsByUserProvider call(
    String userId,
    int limit,
    int page,
  ) {
    return PostsByUserProvider(
      userId,
      limit,
      page,
    );
  }

  @override
  PostsByUserProvider getProviderOverride(
    covariant PostsByUserProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'postsByUserProvider';
}

/// See also [postsByUser].
class PostsByUserProvider extends AutoDisposeFutureProvider<List<PostModel>> {
  /// See also [postsByUser].
  PostsByUserProvider(
    String userId,
    int limit,
    int page,
  ) : this._internal(
          (ref) => postsByUser(
            ref as PostsByUserRef,
            userId,
            limit,
            page,
          ),
          from: postsByUserProvider,
          name: r'postsByUserProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postsByUserHash,
          dependencies: PostsByUserFamily._dependencies,
          allTransitiveDependencies:
              PostsByUserFamily._allTransitiveDependencies,
          userId: userId,
          limit: limit,
          page: page,
        );

  PostsByUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.limit,
    required this.page,
  }) : super.internal();

  final String userId;
  final int limit;
  final int page;

  @override
  Override overrideWith(
    FutureOr<List<PostModel>> Function(PostsByUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsByUserProvider._internal(
        (ref) => create(ref as PostsByUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        limit: limit,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostModel>> createElement() {
    return _PostsByUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByUserProvider &&
        other.userId == userId &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostsByUserRef on AutoDisposeFutureProviderRef<List<PostModel>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `page` of this provider.
  int get page;
}

class _PostsByUserProviderElement
    extends AutoDisposeFutureProviderElement<List<PostModel>>
    with PostsByUserRef {
  _PostsByUserProviderElement(super.provider);

  @override
  String get userId => (origin as PostsByUserProvider).userId;
  @override
  int get limit => (origin as PostsByUserProvider).limit;
  @override
  int get page => (origin as PostsByUserProvider).page;
}

String _$postsScrapedByUserHash() =>
    r'98580f047febbbfd4a4ddd2caafb2a51e9aa926a';

/// See also [postsScrapedByUser].
@ProviderFor(postsScrapedByUser)
const postsScrapedByUserProvider = PostsScrapedByUserFamily();

/// See also [postsScrapedByUser].
class PostsScrapedByUserFamily
    extends Family<AsyncValue<List<PostScrapModel>>> {
  /// See also [postsScrapedByUser].
  const PostsScrapedByUserFamily();

  /// See also [postsScrapedByUser].
  PostsScrapedByUserProvider call(
    String userId,
    int limit,
    int page,
  ) {
    return PostsScrapedByUserProvider(
      userId,
      limit,
      page,
    );
  }

  @override
  PostsScrapedByUserProvider getProviderOverride(
    covariant PostsScrapedByUserProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'postsScrapedByUserProvider';
}

/// See also [postsScrapedByUser].
class PostsScrapedByUserProvider
    extends AutoDisposeFutureProvider<List<PostScrapModel>> {
  /// See also [postsScrapedByUser].
  PostsScrapedByUserProvider(
    String userId,
    int limit,
    int page,
  ) : this._internal(
          (ref) => postsScrapedByUser(
            ref as PostsScrapedByUserRef,
            userId,
            limit,
            page,
          ),
          from: postsScrapedByUserProvider,
          name: r'postsScrapedByUserProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postsScrapedByUserHash,
          dependencies: PostsScrapedByUserFamily._dependencies,
          allTransitiveDependencies:
              PostsScrapedByUserFamily._allTransitiveDependencies,
          userId: userId,
          limit: limit,
          page: page,
        );

  PostsScrapedByUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.limit,
    required this.page,
  }) : super.internal();

  final String userId;
  final int limit;
  final int page;

  @override
  Override overrideWith(
    FutureOr<List<PostScrapModel>> Function(PostsScrapedByUserRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsScrapedByUserProvider._internal(
        (ref) => create(ref as PostsScrapedByUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        limit: limit,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostScrapModel>> createElement() {
    return _PostsScrapedByUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsScrapedByUserProvider &&
        other.userId == userId &&
        other.limit == limit &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostsScrapedByUserRef
    on AutoDisposeFutureProviderRef<List<PostScrapModel>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `page` of this provider.
  int get page;
}

class _PostsScrapedByUserProviderElement
    extends AutoDisposeFutureProviderElement<List<PostScrapModel>>
    with PostsScrapedByUserRef {
  _PostsScrapedByUserProviderElement(super.provider);

  @override
  String get userId => (origin as PostsScrapedByUserProvider).userId;
  @override
  int get limit => (origin as PostsScrapedByUserProvider).limit;
  @override
  int get page => (origin as PostsScrapedByUserProvider).page;
}

String _$reportPostHash() => r'0a8f3188a618917e44fa2edc45dbb7aa9f347699';

/// See also [reportPost].
@ProviderFor(reportPost)
const reportPostProvider = ReportPostFamily();

/// See also [reportPost].
class ReportPostFamily extends Family<AsyncValue<void>> {
  /// See also [reportPost].
  const ReportPostFamily();

  /// See also [reportPost].
  ReportPostProvider call(
    PostModel post,
    String reason,
    String text, {
    bool blockUser = false,
  }) {
    return ReportPostProvider(
      post,
      reason,
      text,
      blockUser: blockUser,
    );
  }

  @override
  ReportPostProvider getProviderOverride(
    covariant ReportPostProvider provider,
  ) {
    return call(
      provider.post,
      provider.reason,
      provider.text,
      blockUser: provider.blockUser,
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
  String? get name => r'reportPostProvider';
}

/// See also [reportPost].
class ReportPostProvider extends AutoDisposeFutureProvider<void> {
  /// See also [reportPost].
  ReportPostProvider(
    PostModel post,
    String reason,
    String text, {
    bool blockUser = false,
  }) : this._internal(
          (ref) => reportPost(
            ref as ReportPostRef,
            post,
            reason,
            text,
            blockUser: blockUser,
          ),
          from: reportPostProvider,
          name: r'reportPostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reportPostHash,
          dependencies: ReportPostFamily._dependencies,
          allTransitiveDependencies:
              ReportPostFamily._allTransitiveDependencies,
          post: post,
          reason: reason,
          text: text,
          blockUser: blockUser,
        );

  ReportPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.post,
    required this.reason,
    required this.text,
    required this.blockUser,
  }) : super.internal();

  final PostModel post;
  final String reason;
  final String text;
  final bool blockUser;

  @override
  Override overrideWith(
    FutureOr<void> Function(ReportPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportPostProvider._internal(
        (ref) => create(ref as ReportPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        post: post,
        reason: reason,
        text: text,
        blockUser: blockUser,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _ReportPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportPostProvider &&
        other.post == post &&
        other.reason == reason &&
        other.text == text &&
        other.blockUser == blockUser;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, post.hashCode);
    hash = _SystemHash.combine(hash, reason.hashCode);
    hash = _SystemHash.combine(hash, text.hashCode);
    hash = _SystemHash.combine(hash, blockUser.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReportPostRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `post` of this provider.
  PostModel get post;

  /// The parameter `reason` of this provider.
  String get reason;

  /// The parameter `text` of this provider.
  String get text;

  /// The parameter `blockUser` of this provider.
  bool get blockUser;
}

class _ReportPostProviderElement extends AutoDisposeFutureProviderElement<void>
    with ReportPostRef {
  _ReportPostProviderElement(super.provider);

  @override
  PostModel get post => (origin as ReportPostProvider).post;
  @override
  String get reason => (origin as ReportPostProvider).reason;
  @override
  String get text => (origin as ReportPostProvider).text;
  @override
  bool get blockUser => (origin as ReportPostProvider).blockUser;
}

String _$deletePostHash() => r'14edd1b452c2311c8e788e36bcd75d3fd51a91b7';

/// See also [deletePost].
@ProviderFor(deletePost)
const deletePostProvider = DeletePostFamily();

/// See also [deletePost].
class DeletePostFamily extends Family<AsyncValue<void>> {
  /// See also [deletePost].
  const DeletePostFamily();

  /// See also [deletePost].
  DeletePostProvider call(
    String postId,
  ) {
    return DeletePostProvider(
      postId,
    );
  }

  @override
  DeletePostProvider getProviderOverride(
    covariant DeletePostProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'deletePostProvider';
}

/// See also [deletePost].
class DeletePostProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deletePost].
  DeletePostProvider(
    String postId,
  ) : this._internal(
          (ref) => deletePost(
            ref as DeletePostRef,
            postId,
          ),
          from: deletePostProvider,
          name: r'deletePostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deletePostHash,
          dependencies: DeletePostFamily._dependencies,
          allTransitiveDependencies:
              DeletePostFamily._allTransitiveDependencies,
          postId: postId,
        );

  DeletePostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeletePostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeletePostProvider._internal(
        (ref) => create(ref as DeletePostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeletePostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeletePostProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeletePostRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _DeletePostProviderElement extends AutoDisposeFutureProviderElement<void>
    with DeletePostRef {
  _DeletePostProviderElement(super.provider);

  @override
  String get postId => (origin as DeletePostProvider).postId;
}

String _$scrapPostHash() => r'92ea67c79075d4dac5997c6706a61137a1a95af5';

/// See also [scrapPost].
@ProviderFor(scrapPost)
const scrapPostProvider = ScrapPostFamily();

/// See also [scrapPost].
class ScrapPostFamily extends Family<AsyncValue<void>> {
  /// See also [scrapPost].
  const ScrapPostFamily();

  /// See also [scrapPost].
  ScrapPostProvider call(
    String postId,
  ) {
    return ScrapPostProvider(
      postId,
    );
  }

  @override
  ScrapPostProvider getProviderOverride(
    covariant ScrapPostProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'scrapPostProvider';
}

/// See also [scrapPost].
class ScrapPostProvider extends AutoDisposeFutureProvider<void> {
  /// See also [scrapPost].
  ScrapPostProvider(
    String postId,
  ) : this._internal(
          (ref) => scrapPost(
            ref as ScrapPostRef,
            postId,
          ),
          from: scrapPostProvider,
          name: r'scrapPostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scrapPostHash,
          dependencies: ScrapPostFamily._dependencies,
          allTransitiveDependencies: ScrapPostFamily._allTransitiveDependencies,
          postId: postId,
        );

  ScrapPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<void> Function(ScrapPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScrapPostProvider._internal(
        (ref) => create(ref as ScrapPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _ScrapPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScrapPostProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScrapPostRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _ScrapPostProviderElement extends AutoDisposeFutureProviderElement<void>
    with ScrapPostRef {
  _ScrapPostProviderElement(super.provider);

  @override
  String get postId => (origin as ScrapPostProvider).postId;
}

String _$unscrapPostHash() => r'a5f031214c35bf97124f41695a0a9a6787472b71';

/// See also [unscrapPost].
@ProviderFor(unscrapPost)
const unscrapPostProvider = UnscrapPostFamily();

/// See also [unscrapPost].
class UnscrapPostFamily extends Family<AsyncValue<void>> {
  /// See also [unscrapPost].
  const UnscrapPostFamily();

  /// See also [unscrapPost].
  UnscrapPostProvider call(
    String postId,
    String userId,
  ) {
    return UnscrapPostProvider(
      postId,
      userId,
    );
  }

  @override
  UnscrapPostProvider getProviderOverride(
    covariant UnscrapPostProvider provider,
  ) {
    return call(
      provider.postId,
      provider.userId,
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
  String? get name => r'unscrapPostProvider';
}

/// See also [unscrapPost].
class UnscrapPostProvider extends AutoDisposeFutureProvider<void> {
  /// See also [unscrapPost].
  UnscrapPostProvider(
    String postId,
    String userId,
  ) : this._internal(
          (ref) => unscrapPost(
            ref as UnscrapPostRef,
            postId,
            userId,
          ),
          from: unscrapPostProvider,
          name: r'unscrapPostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unscrapPostHash,
          dependencies: UnscrapPostFamily._dependencies,
          allTransitiveDependencies:
              UnscrapPostFamily._allTransitiveDependencies,
          postId: postId,
          userId: userId,
        );

  UnscrapPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.userId,
  }) : super.internal();

  final String postId;
  final String userId;

  @override
  Override overrideWith(
    FutureOr<void> Function(UnscrapPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnscrapPostProvider._internal(
        (ref) => create(ref as UnscrapPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _UnscrapPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnscrapPostProvider &&
        other.postId == postId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnscrapPostRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _UnscrapPostProviderElement extends AutoDisposeFutureProviderElement<void>
    with UnscrapPostRef {
  _UnscrapPostProviderElement(super.provider);

  @override
  String get postId => (origin as UnscrapPostProvider).postId;
  @override
  String get userId => (origin as UnscrapPostProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
