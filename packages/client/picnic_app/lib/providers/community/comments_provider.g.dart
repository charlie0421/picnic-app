// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsHash() => r'f836cf32807960d68f2e072ef75463f6e39a1c79';

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

/// See also [comments].
@ProviderFor(comments)
const commentsProvider = CommentsFamily();

/// See also [comments].
class CommentsFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [comments].
  const CommentsFamily();

  /// See also [comments].
  CommentsProvider call(
    String postId,
    int page,
    int limit,
  ) {
    return CommentsProvider(
      postId,
      page,
      limit,
    );
  }

  @override
  CommentsProvider getProviderOverride(
    covariant CommentsProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'commentsProvider';
}

/// See also [comments].
class CommentsProvider extends AutoDisposeFutureProvider<List<CommentModel>> {
  /// See also [comments].
  CommentsProvider(
    String postId,
    int page,
    int limit,
  ) : this._internal(
          (ref) => comments(
            ref as CommentsRef,
            postId,
            page,
            limit,
          ),
          from: commentsProvider,
          name: r'commentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsHash,
          dependencies: CommentsFamily._dependencies,
          allTransitiveDependencies: CommentsFamily._allTransitiveDependencies,
          postId: postId,
          page: page,
          limit: limit,
        );

  CommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.page,
    required this.limit,
  }) : super.internal();

  final String postId;
  final int page;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<CommentModel>> Function(CommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentsProvider._internal(
        (ref) => create(ref as CommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CommentModel>> createElement() {
    return _CommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsProvider &&
        other.postId == postId &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommentsRef on AutoDisposeFutureProviderRef<List<CommentModel>> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _CommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<CommentModel>>
    with CommentsRef {
  _CommentsProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsProvider).postId;
  @override
  int get page => (origin as CommentsProvider).page;
  @override
  int get limit => (origin as CommentsProvider).limit;
}

String _$postCommentHash() => r'6aa12ccedf8e43f07a4c37aac3e84a1bbb9c9b86';

/// See also [postComment].
@ProviderFor(postComment)
const postCommentProvider = PostCommentFamily();

/// See also [postComment].
class PostCommentFamily extends Family<AsyncValue<void>> {
  /// See also [postComment].
  const PostCommentFamily();

  /// See also [postComment].
  PostCommentProvider call(
    String postId,
    String? parentId,
    String content,
  ) {
    return PostCommentProvider(
      postId,
      parentId,
      content,
    );
  }

  @override
  PostCommentProvider getProviderOverride(
    covariant PostCommentProvider provider,
  ) {
    return call(
      provider.postId,
      provider.parentId,
      provider.content,
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
  String? get name => r'postCommentProvider';
}

/// See also [postComment].
class PostCommentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [postComment].
  PostCommentProvider(
    String postId,
    String? parentId,
    String content,
  ) : this._internal(
          (ref) => postComment(
            ref as PostCommentRef,
            postId,
            parentId,
            content,
          ),
          from: postCommentProvider,
          name: r'postCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postCommentHash,
          dependencies: PostCommentFamily._dependencies,
          allTransitiveDependencies:
              PostCommentFamily._allTransitiveDependencies,
          postId: postId,
          parentId: parentId,
          content: content,
        );

  PostCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.parentId,
    required this.content,
  }) : super.internal();

  final String postId;
  final String? parentId;
  final String content;

  @override
  Override overrideWith(
    FutureOr<void> Function(PostCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostCommentProvider._internal(
        (ref) => create(ref as PostCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        parentId: parentId,
        content: content,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _PostCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentProvider &&
        other.postId == postId &&
        other.parentId == parentId &&
        other.content == content;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);
    hash = _SystemHash.combine(hash, content.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `parentId` of this provider.
  String? get parentId;

  /// The parameter `content` of this provider.
  String get content;
}

class _PostCommentProviderElement extends AutoDisposeFutureProviderElement<void>
    with PostCommentRef {
  _PostCommentProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentProvider).postId;
  @override
  String? get parentId => (origin as PostCommentProvider).parentId;
  @override
  String get content => (origin as PostCommentProvider).content;
}

String _$likeCommentHash() => r'ad0100a6ef69daa83c38501643d094080ba5531c';

/// See also [likeComment].
@ProviderFor(likeComment)
const likeCommentProvider = LikeCommentFamily();

/// See also [likeComment].
class LikeCommentFamily extends Family<AsyncValue<void>> {
  /// See also [likeComment].
  const LikeCommentFamily();

  /// See also [likeComment].
  LikeCommentProvider call(
    String commentId,
  ) {
    return LikeCommentProvider(
      commentId,
    );
  }

  @override
  LikeCommentProvider getProviderOverride(
    covariant LikeCommentProvider provider,
  ) {
    return call(
      provider.commentId,
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
  String? get name => r'likeCommentProvider';
}

/// See also [likeComment].
class LikeCommentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [likeComment].
  LikeCommentProvider(
    String commentId,
  ) : this._internal(
          (ref) => likeComment(
            ref as LikeCommentRef,
            commentId,
          ),
          from: likeCommentProvider,
          name: r'likeCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$likeCommentHash,
          dependencies: LikeCommentFamily._dependencies,
          allTransitiveDependencies:
              LikeCommentFamily._allTransitiveDependencies,
          commentId: commentId,
        );

  LikeCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
  }) : super.internal();

  final String commentId;

  @override
  Override overrideWith(
    FutureOr<void> Function(LikeCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LikeCommentProvider._internal(
        (ref) => create(ref as LikeCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _LikeCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LikeCommentProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LikeCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `commentId` of this provider.
  String get commentId;
}

class _LikeCommentProviderElement extends AutoDisposeFutureProviderElement<void>
    with LikeCommentRef {
  _LikeCommentProviderElement(super.provider);

  @override
  String get commentId => (origin as LikeCommentProvider).commentId;
}

String _$unlikeCommentHash() => r'dcf57e3dbd7494bc439968206f8af684b29139d2';

/// See also [unlikeComment].
@ProviderFor(unlikeComment)
const unlikeCommentProvider = UnlikeCommentFamily();

/// See also [unlikeComment].
class UnlikeCommentFamily extends Family<AsyncValue<void>> {
  /// See also [unlikeComment].
  const UnlikeCommentFamily();

  /// See also [unlikeComment].
  UnlikeCommentProvider call(
    String commentId,
  ) {
    return UnlikeCommentProvider(
      commentId,
    );
  }

  @override
  UnlikeCommentProvider getProviderOverride(
    covariant UnlikeCommentProvider provider,
  ) {
    return call(
      provider.commentId,
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
  String? get name => r'unlikeCommentProvider';
}

/// See also [unlikeComment].
class UnlikeCommentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [unlikeComment].
  UnlikeCommentProvider(
    String commentId,
  ) : this._internal(
          (ref) => unlikeComment(
            ref as UnlikeCommentRef,
            commentId,
          ),
          from: unlikeCommentProvider,
          name: r'unlikeCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unlikeCommentHash,
          dependencies: UnlikeCommentFamily._dependencies,
          allTransitiveDependencies:
              UnlikeCommentFamily._allTransitiveDependencies,
          commentId: commentId,
        );

  UnlikeCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
  }) : super.internal();

  final String commentId;

  @override
  Override overrideWith(
    FutureOr<void> Function(UnlikeCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnlikeCommentProvider._internal(
        (ref) => create(ref as UnlikeCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _UnlikeCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnlikeCommentProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UnlikeCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `commentId` of this provider.
  String get commentId;
}

class _UnlikeCommentProviderElement
    extends AutoDisposeFutureProviderElement<void> with UnlikeCommentRef {
  _UnlikeCommentProviderElement(super.provider);

  @override
  String get commentId => (origin as UnlikeCommentProvider).commentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
