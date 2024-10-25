// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsNotifierHash() => r'f369fe383aad66cdf9fda717522be2d13370eb32';

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

abstract class _$CommentsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String postId;
  late final int page;
  late final int limit;
  late final bool includeDeleted;
  late final bool includeReported;

  FutureOr<List<CommentModel>> build(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  });
}

/// See also [CommentsNotifier].
@ProviderFor(CommentsNotifier)
const commentsNotifierProvider = CommentsNotifierFamily();

/// See also [CommentsNotifier].
class CommentsNotifierFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [CommentsNotifier].
  const CommentsNotifierFamily();

  /// See also [CommentsNotifier].
  CommentsNotifierProvider call(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) {
    return CommentsNotifierProvider(
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  @override
  CommentsNotifierProvider getProviderOverride(
    covariant CommentsNotifierProvider provider,
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
  String? get name => r'commentsNotifierProvider';
}

/// See also [CommentsNotifier].
class CommentsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CommentsNotifier, List<CommentModel>> {
  /// See also [CommentsNotifier].
  CommentsNotifierProvider(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) : this._internal(
          () => CommentsNotifier()
            ..postId = postId
            ..page = page
            ..limit = limit
            ..includeDeleted = includeDeleted
            ..includeReported = includeReported,
          from: commentsNotifierProvider,
          name: r'commentsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsNotifierHash,
          dependencies: CommentsNotifierFamily._dependencies,
          allTransitiveDependencies:
              CommentsNotifierFamily._allTransitiveDependencies,
          postId: postId,
          page: page,
          limit: limit,
          includeDeleted: includeDeleted,
          includeReported: includeReported,
        );

  CommentsNotifierProvider._internal(
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
  FutureOr<List<CommentModel>> runNotifierBuild(
    covariant CommentsNotifier notifier,
  ) {
    return notifier.build(
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  @override
  Override overrideWith(CommentsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentsNotifierProvider._internal(
        () => create()
          ..postId = postId
          ..page = page
          ..limit = limit
          ..includeDeleted = includeDeleted
          ..includeReported = includeReported,
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
  AutoDisposeAsyncNotifierProviderElement<CommentsNotifier, List<CommentModel>>
      createElement() {
    return _CommentsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsNotifierProvider &&
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

mixin CommentsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
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

class _CommentsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CommentsNotifier,
        List<CommentModel>> with CommentsNotifierRef {
  _CommentsNotifierProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsNotifierProvider).postId;
  @override
  int get page => (origin as CommentsNotifierProvider).page;
  @override
  int get limit => (origin as CommentsNotifierProvider).limit;
  @override
  bool get includeDeleted =>
      (origin as CommentsNotifierProvider).includeDeleted;
  @override
  bool get includeReported =>
      (origin as CommentsNotifierProvider).includeReported;
}

String _$userCommentsNotifierHash() =>
    r'44a2fda4d93b0c0d1abd9bada7dae943e7516ca4';

abstract class _$UserCommentsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String userId;
  late final int page;
  late final int limit;
  late final bool includeDeleted;
  late final bool includeReported;

  FutureOr<List<CommentModel>> build(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  });
}

/// See also [UserCommentsNotifier].
@ProviderFor(UserCommentsNotifier)
const userCommentsNotifierProvider = UserCommentsNotifierFamily();

/// See also [UserCommentsNotifier].
class UserCommentsNotifierFamily
    extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [UserCommentsNotifier].
  const UserCommentsNotifierFamily();

  /// See also [UserCommentsNotifier].
  UserCommentsNotifierProvider call(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) {
    return UserCommentsNotifierProvider(
      userId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  @override
  UserCommentsNotifierProvider getProviderOverride(
    covariant UserCommentsNotifierProvider provider,
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
  String? get name => r'userCommentsNotifierProvider';
}

/// See also [UserCommentsNotifier].
class UserCommentsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    UserCommentsNotifier, List<CommentModel>> {
  /// See also [UserCommentsNotifier].
  UserCommentsNotifierProvider(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) : this._internal(
          () => UserCommentsNotifier()
            ..userId = userId
            ..page = page
            ..limit = limit
            ..includeDeleted = includeDeleted
            ..includeReported = includeReported,
          from: userCommentsNotifierProvider,
          name: r'userCommentsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userCommentsNotifierHash,
          dependencies: UserCommentsNotifierFamily._dependencies,
          allTransitiveDependencies:
              UserCommentsNotifierFamily._allTransitiveDependencies,
          userId: userId,
          page: page,
          limit: limit,
          includeDeleted: includeDeleted,
          includeReported: includeReported,
        );

  UserCommentsNotifierProvider._internal(
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
  FutureOr<List<CommentModel>> runNotifierBuild(
    covariant UserCommentsNotifier notifier,
  ) {
    return notifier.build(
      userId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    );
  }

  @override
  Override overrideWith(UserCommentsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserCommentsNotifierProvider._internal(
        () => create()
          ..userId = userId
          ..page = page
          ..limit = limit
          ..includeDeleted = includeDeleted
          ..includeReported = includeReported,
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
  AutoDisposeAsyncNotifierProviderElement<UserCommentsNotifier,
      List<CommentModel>> createElement() {
    return _UserCommentsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCommentsNotifierProvider &&
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

mixin UserCommentsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
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

class _UserCommentsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UserCommentsNotifier,
        List<CommentModel>> with UserCommentsNotifierRef {
  _UserCommentsNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as UserCommentsNotifierProvider).userId;
  @override
  int get page => (origin as UserCommentsNotifierProvider).page;
  @override
  int get limit => (origin as UserCommentsNotifierProvider).limit;
  @override
  bool get includeDeleted =>
      (origin as UserCommentsNotifierProvider).includeDeleted;
  @override
  bool get includeReported =>
      (origin as UserCommentsNotifierProvider).includeReported;
}

String _$commentTranslationNotifierHash() =>
    r'7d630ef180597a582b5965d8a833f030b5338da1';

/// See also [CommentTranslationNotifier].
@ProviderFor(CommentTranslationNotifier)
final commentTranslationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<CommentTranslationNotifier, void>.internal(
  CommentTranslationNotifier.new,
  name: r'commentTranslationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentTranslationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommentTranslationNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
