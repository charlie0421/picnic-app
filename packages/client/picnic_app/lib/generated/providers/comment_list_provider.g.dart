// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../providers/comment_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncCommentListHash() => r'8d28b6f19a0d48ab2ca89744db308593e2e1c4b8';

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

abstract class _$AsyncCommentList
    extends BuildlessAutoDisposeAsyncNotifier<CommentState> {
  late final int articleId;
  late final PagingController<int, CommentModel> pagingController;

  FutureOr<CommentState> build({
    required int articleId,
    required PagingController<int, CommentModel> pagingController,
  });
}

/// See also [AsyncCommentList].
@ProviderFor(AsyncCommentList)
const asyncCommentListProvider = AsyncCommentListFamily();

/// See also [AsyncCommentList].
class AsyncCommentListFamily extends Family<AsyncValue<CommentState>> {
  /// See also [AsyncCommentList].
  const AsyncCommentListFamily();

  /// See also [AsyncCommentList].
  AsyncCommentListProvider call({
    required int articleId,
    required PagingController<int, CommentModel> pagingController,
  }) {
    return AsyncCommentListProvider(
      articleId: articleId,
      pagingController: pagingController,
    );
  }

  @override
  AsyncCommentListProvider getProviderOverride(
    covariant AsyncCommentListProvider provider,
  ) {
    return call(
      articleId: provider.articleId,
      pagingController: provider.pagingController,
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
  String? get name => r'asyncCommentListProvider';
}

/// See also [AsyncCommentList].
class AsyncCommentListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AsyncCommentList, CommentState> {
  /// See also [AsyncCommentList].
  AsyncCommentListProvider({
    required int articleId,
    required PagingController<int, CommentModel> pagingController,
  }) : this._internal(
          () => AsyncCommentList()
            ..articleId = articleId
            ..pagingController = pagingController,
          from: asyncCommentListProvider,
          name: r'asyncCommentListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncCommentListHash,
          dependencies: AsyncCommentListFamily._dependencies,
          allTransitiveDependencies:
              AsyncCommentListFamily._allTransitiveDependencies,
          articleId: articleId,
          pagingController: pagingController,
        );

  AsyncCommentListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.articleId,
    required this.pagingController,
  }) : super.internal();

  final int articleId;
  final PagingController<int, CommentModel> pagingController;

  @override
  FutureOr<CommentState> runNotifierBuild(
    covariant AsyncCommentList notifier,
  ) {
    return notifier.build(
      articleId: articleId,
      pagingController: pagingController,
    );
  }

  @override
  Override overrideWith(AsyncCommentList Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncCommentListProvider._internal(
        () => create()
          ..articleId = articleId
          ..pagingController = pagingController,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        articleId: articleId,
        pagingController: pagingController,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncCommentList, CommentState>
      createElement() {
    return _AsyncCommentListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncCommentListProvider &&
        other.articleId == articleId &&
        other.pagingController == pagingController;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, articleId.hashCode);
    hash = _SystemHash.combine(hash, pagingController.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AsyncCommentListRef on AutoDisposeAsyncNotifierProviderRef<CommentState> {
  /// The parameter `articleId` of this provider.
  int get articleId;

  /// The parameter `pagingController` of this provider.
  PagingController<int, CommentModel> get pagingController;
}

class _AsyncCommentListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncCommentList,
        CommentState> with AsyncCommentListRef {
  _AsyncCommentListProviderElement(super.provider);

  @override
  int get articleId => (origin as AsyncCommentListProvider).articleId;
  @override
  PagingController<int, CommentModel> get pagingController =>
      (origin as AsyncCommentListProvider).pagingController;
}

String _$parentItemHash() => r'30d7e81bfa5563d77693ce2e504753acaddecca4';

/// See also [ParentItem].
@ProviderFor(ParentItem)
final parentItemProvider =
    AutoDisposeNotifierProvider<ParentItem, CommentModel?>.internal(
  ParentItem.new,
  name: r'parentItemProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$parentItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ParentItem = AutoDisposeNotifier<CommentModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
