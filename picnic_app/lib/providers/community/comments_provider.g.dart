// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsHash() => r'deb4f686e07c055310b25f68cb1cceeaa2fbac0b';

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
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) {
    return CommentsProvider(
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
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
      includeDeleted: provider.includeDeleted,
      includeReported: provider.includeReported,
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
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) : this._internal(
          (ref) => comments(
            ref as CommentsRef,
            postId,
            page,
            limit,
            includeDeleted: includeDeleted,
            includeReported: includeReported,
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
          includeDeleted: includeDeleted,
          includeReported: includeReported,
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
    required this.includeDeleted,
    required this.includeReported,
  }) : super.internal();

  final String postId;
  final int page;
  final int limit;
  final bool includeDeleted;
  final bool includeReported;

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
        includeDeleted: includeDeleted,
        includeReported: includeReported,
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
        other.limit == limit &&
        other.includeDeleted == includeDeleted &&
        other.includeReported == includeReported;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, includeDeleted.hashCode);
    hash = _SystemHash.combine(hash, includeReported.hashCode);

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

  /// The parameter `includeDeleted` of this provider.
  bool get includeDeleted;

  /// The parameter `includeReported` of this provider.
  bool get includeReported;
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
  @override
  bool get includeDeleted => (origin as CommentsProvider).includeDeleted;
  @override
  bool get includeReported => (origin as CommentsProvider).includeReported;
}

String _$commentsByUserHash() => r'91590c8d07c665a4115d1aabd2b99761e5baf08a';

/// See also [commentsByUser].
@ProviderFor(commentsByUser)
const commentsByUserProvider = CommentsByUserFamily();

/// See also [commentsByUser].
class CommentsByUserFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [commentsByUser].
  const CommentsByUserFamily();

  /// See also [commentsByUser].
  CommentsByUserProvider call(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) {
    return CommentsByUserProvider(
      userId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  @override
  CommentsByUserProvider getProviderOverride(
    covariant CommentsByUserProvider provider,
  ) {
    return call(
      provider.userId,
      provider.page,
      provider.limit,
      includeDeleted: provider.includeDeleted,
      includeReported: provider.includeReported,
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
  String? get name => r'commentsByUserProvider';
}

/// See also [commentsByUser].
class CommentsByUserProvider
    extends AutoDisposeFutureProvider<List<CommentModel>> {
  /// See also [commentsByUser].
  CommentsByUserProvider(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) : this._internal(
          (ref) => commentsByUser(
            ref as CommentsByUserRef,
            userId,
            page,
            limit,
            includeDeleted: includeDeleted,
            includeReported: includeReported,
          ),
          from: commentsByUserProvider,
          name: r'commentsByUserProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsByUserHash,
          dependencies: CommentsByUserFamily._dependencies,
          allTransitiveDependencies:
              CommentsByUserFamily._allTransitiveDependencies,
          userId: userId,
          page: page,
          limit: limit,
          includeDeleted: includeDeleted,
          includeReported: includeReported,
        );

  CommentsByUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.page,
    required this.limit,
    required this.includeDeleted,
    required this.includeReported,
  }) : super.internal();

  final String userId;
  final int page;
  final int limit;
  final bool includeDeleted;
  final bool includeReported;

  @override
  Override overrideWith(
    FutureOr<List<CommentModel>> Function(CommentsByUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentsByUserProvider._internal(
        (ref) => create(ref as CommentsByUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        page: page,
        limit: limit,
        includeDeleted: includeDeleted,
        includeReported: includeReported,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CommentModel>> createElement() {
    return _CommentsByUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsByUserProvider &&
        other.userId == userId &&
        other.page == page &&
        other.limit == limit &&
        other.includeDeleted == includeDeleted &&
        other.includeReported == includeReported;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, includeDeleted.hashCode);
    hash = _SystemHash.combine(hash, includeReported.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommentsByUserRef on AutoDisposeFutureProviderRef<List<CommentModel>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `includeDeleted` of this provider.
  bool get includeDeleted;

  /// The parameter `includeReported` of this provider.
  bool get includeReported;
}

class _CommentsByUserProviderElement
    extends AutoDisposeFutureProviderElement<List<CommentModel>>
    with CommentsByUserRef {
  _CommentsByUserProviderElement(super.provider);

  @override
  String get userId => (origin as CommentsByUserProvider).userId;
  @override
  int get page => (origin as CommentsByUserProvider).page;
  @override
  int get limit => (origin as CommentsByUserProvider).limit;
  @override
  bool get includeDeleted => (origin as CommentsByUserProvider).includeDeleted;
  @override
  bool get includeReported =>
      (origin as CommentsByUserProvider).includeReported;
}

String _$postCommentHash() => r'fce885b65ecf81406935f48692e70dd565fdb18a';

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

String _$likeCommentHash() => r'2e9f18c42f87327090014dfd8b02dd497b3f6c52';

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

String _$unlikeCommentHash() => r'0e0407ed65881e8ce4007da831c758bc2d6e617d';

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

String _$reportCommentHash() => r'771073bb93768683788ea34f904a8590ca68292b';

/// See also [reportComment].
@ProviderFor(reportComment)
const reportCommentProvider = ReportCommentFamily();

/// See also [reportComment].
class ReportCommentFamily extends Family<AsyncValue<void>> {
  /// See also [reportComment].
  const ReportCommentFamily();

  /// See also [reportComment].
  ReportCommentProvider call(
    CommentModel comment,
    String reason,
    String text,
  ) {
    return ReportCommentProvider(
      comment,
      reason,
      text,
    );
  }

  @override
  ReportCommentProvider getProviderOverride(
    covariant ReportCommentProvider provider,
  ) {
    return call(
      provider.comment,
      provider.reason,
      provider.text,
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
  String? get name => r'reportCommentProvider';
}

/// See also [reportComment].
class ReportCommentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [reportComment].
  ReportCommentProvider(
    CommentModel comment,
    String reason,
    String text,
  ) : this._internal(
          (ref) => reportComment(
            ref as ReportCommentRef,
            comment,
            reason,
            text,
          ),
          from: reportCommentProvider,
          name: r'reportCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reportCommentHash,
          dependencies: ReportCommentFamily._dependencies,
          allTransitiveDependencies:
              ReportCommentFamily._allTransitiveDependencies,
          comment: comment,
          reason: reason,
          text: text,
        );

  ReportCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.comment,
    required this.reason,
    required this.text,
  }) : super.internal();

  final CommentModel comment;
  final String reason;
  final String text;

  @override
  Override overrideWith(
    FutureOr<void> Function(ReportCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportCommentProvider._internal(
        (ref) => create(ref as ReportCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        comment: comment,
        reason: reason,
        text: text,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _ReportCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportCommentProvider &&
        other.comment == comment &&
        other.reason == reason &&
        other.text == text;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, comment.hashCode);
    hash = _SystemHash.combine(hash, reason.hashCode);
    hash = _SystemHash.combine(hash, text.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReportCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `comment` of this provider.
  CommentModel get comment;

  /// The parameter `reason` of this provider.
  String get reason;

  /// The parameter `text` of this provider.
  String get text;
}

class _ReportCommentProviderElement
    extends AutoDisposeFutureProviderElement<void> with ReportCommentRef {
  _ReportCommentProviderElement(super.provider);

  @override
  CommentModel get comment => (origin as ReportCommentProvider).comment;
  @override
  String get reason => (origin as ReportCommentProvider).reason;
  @override
  String get text => (origin as ReportCommentProvider).text;
}

String _$deleteCommentHash() => r'86d9f8fbd1c7d62ac0463f2e93384deea3aa240c';

/// See also [deleteComment].
@ProviderFor(deleteComment)
const deleteCommentProvider = DeleteCommentFamily();

/// See also [deleteComment].
class DeleteCommentFamily extends Family<AsyncValue<void>> {
  /// See also [deleteComment].
  const DeleteCommentFamily();

  /// See also [deleteComment].
  DeleteCommentProvider call(
    String commentId,
  ) {
    return DeleteCommentProvider(
      commentId,
    );
  }

  @override
  DeleteCommentProvider getProviderOverride(
    covariant DeleteCommentProvider provider,
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
  String? get name => r'deleteCommentProvider';
}

/// See also [deleteComment].
class DeleteCommentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deleteComment].
  DeleteCommentProvider(
    String commentId,
  ) : this._internal(
          (ref) => deleteComment(
            ref as DeleteCommentRef,
            commentId,
          ),
          from: deleteCommentProvider,
          name: r'deleteCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deleteCommentHash,
          dependencies: DeleteCommentFamily._dependencies,
          allTransitiveDependencies:
              DeleteCommentFamily._allTransitiveDependencies,
          commentId: commentId,
        );

  DeleteCommentProvider._internal(
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
    FutureOr<void> Function(DeleteCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteCommentProvider._internal(
        (ref) => create(ref as DeleteCommentRef),
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
    return _DeleteCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteCommentProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeleteCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `commentId` of this provider.
  String get commentId;
}

class _DeleteCommentProviderElement
    extends AutoDisposeFutureProviderElement<void> with DeleteCommentRef {
  _DeleteCommentProviderElement(super.provider);

  @override
  String get commentId => (origin as DeleteCommentProvider).commentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
