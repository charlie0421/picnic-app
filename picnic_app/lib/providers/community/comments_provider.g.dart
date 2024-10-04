// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsHash() => r'f82ba61706ab4f0d623eb7135b524b083acf4753';

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
class CommentsFamily extends Family<AsyncValue<List<CommentModel>?>> {
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
class CommentsProvider extends AutoDisposeFutureProvider<List<CommentModel>?> {
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
    FutureOr<List<CommentModel>?> Function(CommentsRef provider) create,
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
  AutoDisposeFutureProviderElement<List<CommentModel>?> createElement() {
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

mixin CommentsRef on AutoDisposeFutureProviderRef<List<CommentModel>?> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _CommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<CommentModel>?>
    with CommentsRef {
  _CommentsProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsProvider).postId;
  @override
  int get page => (origin as CommentsProvider).page;
  @override
  int get limit => (origin as CommentsProvider).limit;
}

String _$postCommentHash() => r'beb4e1e431613ec0435e47d3fcacc8295755a575';

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
    String content,
  ) {
    return PostCommentProvider(
      postId,
      content,
    );
  }

  @override
  PostCommentProvider getProviderOverride(
    covariant PostCommentProvider provider,
  ) {
    return call(
      provider.postId,
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
    String content,
  ) : this._internal(
          (ref) => postComment(
            ref as PostCommentRef,
            postId,
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
    required this.content,
  }) : super.internal();

  final String postId;
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
        other.content == content;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, content.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `content` of this provider.
  String get content;
}

class _PostCommentProviderElement extends AutoDisposeFutureProviderElement<void>
    with PostCommentRef {
  _PostCommentProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentProvider).postId;
  @override
  String get content => (origin as PostCommentProvider).content;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
