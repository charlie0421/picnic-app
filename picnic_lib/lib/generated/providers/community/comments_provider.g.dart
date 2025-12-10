// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommentsNotifier)
const commentsProvider = CommentsNotifierFamily._();

final class CommentsNotifierProvider
    extends $AsyncNotifierProvider<CommentsNotifier, List<CommentModel>> {
  const CommentsNotifierProvider._({
    required CommentsNotifierFamily super.from,
    required (String, int, int, {bool includeDeleted, bool includeReported})
    super.argument,
  }) : super(
         retry: null,
         name: r'commentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentsNotifierHash();

  @override
  String toString() {
    return r'commentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CommentsNotifier create() => CommentsNotifier();

  @override
  bool operator ==(Object other) {
    return other is CommentsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentsNotifierHash() => r'7fafa42440c84535957ca35e1469e1e3c8095074';

final class CommentsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentsNotifier,
          AsyncValue<List<CommentModel>>,
          List<CommentModel>,
          FutureOr<List<CommentModel>>,
          (String, int, int, {bool includeDeleted, bool includeReported})
        > {
  const CommentsNotifierFamily._()
    : super(
        retry: null,
        name: r'commentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommentsNotifierProvider call(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) => CommentsNotifierProvider._(
    argument: (
      postId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    ),
    from: this,
  );

  @override
  String toString() => r'commentsProvider';
}

abstract class _$CommentsNotifier extends $AsyncNotifier<List<CommentModel>> {
  late final _$args =
      ref.$arg
          as (String, int, int, {bool includeDeleted, bool includeReported});
  String get postId => _$args.$1;
  int get page => _$args.$2;
  int get limit => _$args.$3;
  bool get includeDeleted => _$args.includeDeleted;
  bool get includeReported => _$args.includeReported;

  FutureOr<List<CommentModel>> build(
    String postId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args.$1,
      _$args.$2,
      _$args.$3,
      includeDeleted: _$args.includeDeleted,
      includeReported: _$args.includeReported,
    );
    final ref =
        this.ref as $Ref<AsyncValue<List<CommentModel>>, List<CommentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CommentModel>>, List<CommentModel>>,
              AsyncValue<List<CommentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(UserCommentsNotifier)
const userCommentsProvider = UserCommentsNotifierFamily._();

final class UserCommentsNotifierProvider
    extends $AsyncNotifierProvider<UserCommentsNotifier, List<CommentModel>> {
  const UserCommentsNotifierProvider._({
    required UserCommentsNotifierFamily super.from,
    required (String, int, int, {bool includeDeleted, bool includeReported})
    super.argument,
  }) : super(
         retry: null,
         name: r'userCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userCommentsNotifierHash();

  @override
  String toString() {
    return r'userCommentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  UserCommentsNotifier create() => UserCommentsNotifier();

  @override
  bool operator ==(Object other) {
    return other is UserCommentsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userCommentsNotifierHash() =>
    r'a1f0974c30c89db84dcfffba0f1d8bed85e89768';

final class UserCommentsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          UserCommentsNotifier,
          AsyncValue<List<CommentModel>>,
          List<CommentModel>,
          FutureOr<List<CommentModel>>,
          (String, int, int, {bool includeDeleted, bool includeReported})
        > {
  const UserCommentsNotifierFamily._()
    : super(
        retry: null,
        name: r'userCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserCommentsNotifierProvider call(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  }) => UserCommentsNotifierProvider._(
    argument: (
      userId,
      page,
      limit,
      includeDeleted: includeDeleted,
      includeReported: includeReported,
    ),
    from: this,
  );

  @override
  String toString() => r'userCommentsProvider';
}

abstract class _$UserCommentsNotifier
    extends $AsyncNotifier<List<CommentModel>> {
  late final _$args =
      ref.$arg
          as (String, int, int, {bool includeDeleted, bool includeReported});
  String get userId => _$args.$1;
  int get page => _$args.$2;
  int get limit => _$args.$3;
  bool get includeDeleted => _$args.includeDeleted;
  bool get includeReported => _$args.includeReported;

  FutureOr<List<CommentModel>> build(
    String userId,
    int page,
    int limit, {
    bool includeDeleted = true,
    bool includeReported = true,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args.$1,
      _$args.$2,
      _$args.$3,
      includeDeleted: _$args.includeDeleted,
      includeReported: _$args.includeReported,
    );
    final ref =
        this.ref as $Ref<AsyncValue<List<CommentModel>>, List<CommentModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CommentModel>>, List<CommentModel>>,
              AsyncValue<List<CommentModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(CommentTranslationNotifier)
const commentTranslationProvider = CommentTranslationNotifierProvider._();

final class CommentTranslationNotifierProvider
    extends $AsyncNotifierProvider<CommentTranslationNotifier, void> {
  const CommentTranslationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentTranslationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentTranslationNotifierHash();

  @$internal
  @override
  CommentTranslationNotifier create() => CommentTranslationNotifier();
}

String _$commentTranslationNotifierHash() =>
    r'7d630ef180597a582b5965d8a833f030b5338da1';

abstract class _$CommentTranslationNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
